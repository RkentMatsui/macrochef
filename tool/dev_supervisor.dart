// Dev supervisor: owns a `flutter run --machine` daemon and triggers a proper
// hot reload (recompile + reload + reassemble) whenever a trigger file is
// touched. This works around Windows not being able to feed `r` to the
// flutter batch process's stdin across separate shell invocations.
//
// Usage:
//   dart run tool/dev_supervisor.dart <deviceId> <triggerFilePath>
// Then, from anywhere, "touch" the trigger file to force a hot reload:
//   (bash)  : touch <triggerFilePath>
//
// The daemon recompiles changed Dart via its resident frontend compiler, so
// edits are actually picked up (unlike a raw VM-service reloadSources call).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final deviceId = args.isNotEmpty ? args[0] : '4fa7a9a6';
  final triggerPath = args.length > 1
      ? args[1]
      : '${Directory.systemTemp.path}\\mc_reload_trigger';

  final trigger = File(triggerPath);
  if (!trigger.existsSync()) {
    trigger.createSync(recursive: true);
  }
  var lastStamp = trigger.lastModifiedSync();

  stdout.writeln('[supervisor] device=$deviceId trigger=$triggerPath');
  stdout.writeln('[supervisor] starting flutter daemon...');

  final proc = await Process.start(
    'flutter',
    ['run', '--machine', '-d', deviceId],
    runInShell: true, // resolve flutter.bat on Windows
  );

  String? appId;
  var nextId = 1;
  var reloading = false;

  proc.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
    if (line.startsWith('[{')) {
      dynamic decoded;
      try {
        decoded = jsonDecode(line);
      } catch (_) {
        return;
      }
      if (decoded is List && decoded.isNotEmpty) {
        final msg = decoded.first;
        if (msg is Map) {
          if (msg['event'] == 'app.started') {
            appId = (msg['params'] as Map)['appId'] as String?;
            stdout.writeln('[supervisor] READY appId=$appId — touch the '
                'trigger file to hot reload');
          } else if (msg.containsKey('id') && msg.containsKey('result')) {
            final res = msg['result'];
            final ok = res is Map && res['code'] == 0;
            stdout.writeln('[supervisor] reload ${ok ? 'OK' : 'result'}: $res');
            reloading = false;
          } else if (msg['event'] == 'app.progress') {
            // compile/reload progress — keep quiet
          }
        }
      }
      return;
    }
    // Non-JSON lines (build output, app logs) — surface them.
    stdout.writeln('[flutter] $line');
  });

  proc.stderr.transform(utf8.decoder).listen(stderr.write);

  Timer.periodic(const Duration(milliseconds: 400), (_) {
    if (appId == null || reloading) return;
    DateTime st;
    try {
      st = trigger.lastModifiedSync();
    } catch (_) {
      return;
    }
    if (st != lastStamp) {
      lastStamp = st;
      reloading = true;
      final id = nextId++;
      stdout.writeln('[supervisor] trigger changed → hot reload (#$id)');
      proc.stdin.writeln(jsonEncode([
        {
          'id': id,
          'method': 'app.restart',
          'params': {'appId': appId, 'fullRestart': false, 'pause': false},
        }
      ]));
    }
  });

  final code = await proc.exitCode;
  stdout.writeln('[supervisor] flutter exited with $code');
  exit(code);
}
