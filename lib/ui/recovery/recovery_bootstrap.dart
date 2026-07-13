import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../services/backup_service.dart';
import '../../services/recovery/backup_candidate_validator.dart';
import '../../services/recovery/local_data_classifier.dart';
import '../../services/recovery/recovery_bootstrap_store.dart';
import '../../services/recovery/recovery_coordinator.dart';
import '../../services/shared_storage.dart';

typedef BackupFileSelector = Future<File?> Function();

class RecoveryBootstrapDependencies {
  final RecoveryCoordinator coordinator;
  const RecoveryBootstrapDependencies({required this.coordinator});

  static Future<RecoveryBootstrapDependencies> create({
    required bool pendingRestoreApplied,
  }) async {
    final documents = await getApplicationDocumentsDirectory();
    final support = await getApplicationSupportDirectory();
    final store = RecoveryBootstrapStore(
      File(p.join(support.path, 'recovery-bootstrap-v1.json')),
    );
    if (pendingRestoreApplied) {
      final current = await store.read();
      if (current.status != RecoveryBootstrapStatus.recoveryApplied) {
        await store.write(
          const RecoveryBootstrapRecord(
            status: RecoveryBootstrapStatus.initialized,
          ),
        );
      }
    }
    final candidateDirectory = Directory(
      p.join(support.path, 'recovery-candidates'),
    );
    final sharedStorage = !kIsWeb && Platform.isAndroid
        ? const MediaStoreSharedStorage()
        : const NoopSharedStorage();
    return RecoveryBootstrapDependencies(
      coordinator: RecoveryCoordinator(
        bootstrapStore: store,
        sharedStorage: sharedStorage,
        validator: const BackupCandidateValidator(),
        classifier: const LocalDataClassifier(),
        liveDatabase: await BackupService.databaseFile(),
        pendingRestore: File(p.join(documents.path, 'macrochef.import.sqlite')),
        privateCandidate: (backup) => File(
          p.join(candidateDirectory.path, '${backup.id.hashCode}.sqlite'),
        ),
      ),
    );
  }
}

class RecoveryBootstrap extends StatefulWidget {
  final WidgetBuilder appBuilder;
  final RecoveryCoordinator coordinator;
  final BackupFileSelector? selectBackupFile;
  const RecoveryBootstrap({
    super.key,
    required this.appBuilder,
    required this.coordinator,
    this.selectBackupFile,
  });
  @override
  State<RecoveryBootstrap> createState() => _RecoveryBootstrapState();
}

class _RecoveryBootstrapState extends State<RecoveryBootstrap> {
  RecoveryPreparation? _preparation;
  bool _showApp = false;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    if (mounted) setState(() => _busy = true);
    await _handle(await widget.coordinator.prepare());
  }

  Future<void> _handle(RecoveryPreparation preparation) async {
    if (preparation is RecoverySkip) return _finish();
    if (preparation is RecoveryAutoRestore &&
        preparation is! RecoveryConfirmRestore) {
      return _restore(preparation);
    }
    if (mounted) {
      setState(() {
        _preparation = preparation;
        _busy = false;
      });
    }
  }

  Future<void> _restore(RecoveryAutoRestore preparation) async {
    if (mounted) setState(() => _busy = true);
    if (await widget.coordinator.restore(preparation)) return _finish();
    if (mounted) {
      setState(() {
        _preparation = const RecoveryPrepareError(
          'The backup could not be restored.',
        );
        _busy = false;
      });
    }
  }

  Future<void> _decline() async {
    setState(() => _busy = true);
    await widget.coordinator.decline();
    _finish();
  }

  Future<void> _select(RecoveryNeedsFileAccess access) async {
    final picked = widget.selectBackupFile != null
        ? await widget.selectBackupFile!()
        : await _pickFile();
    if (picked == null) return;
    setState(() => _busy = true);
    await _handle(
      await widget.coordinator.prepareSelectedFile(access.backup, picked),
    );
  }

  Future<File?> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: false);
    final path = result?.files.single.path;
    return path == null ? null : File(path);
  }

  void _finish() {
    if (mounted) {
      setState(() {
        _showApp = true;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showApp) return widget.appBuilder(context);
    if (_busy) {
      return const _RecoveryPage(child: Text('Checking for a backup…'));
    }
    final preparation = _preparation;
    if (preparation is RecoveryConfirmRestore) {
      return _RecoveryPage(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Restore backup?', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 12),
            Text(
              _backupDetails(preparation.backup),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Restoring will replace the data currently on this device.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => _restore(preparation),
              child: const Text('Restore backup'),
            ),
            TextButton(
              onPressed: _decline,
              child: const Text('Keep current data'),
            ),
          ],
        ),
      );
    }
    if (preparation is RecoveryNeedsFileAccess) {
      final manual = preparation.backup.id.isEmpty;
      return _RecoveryPage(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              manual ? 'Restore a backup?' : 'Backup access needed',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 12),
            Text(
              manual
                  ? 'No MacroChef backup was found on this device. If you '
                        'have a backup file, you can restore it — otherwise '
                        'start fresh.'
                  : preparation.backup.name,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => _select(preparation),
              child: const Text('Select backup file'),
            ),
            TextButton(onPressed: _decline, child: const Text('Start fresh')),
          ],
        ),
      );
    }
    final message = preparation is RecoveryPrepareError
        ? preparation.message
        : 'Backup recovery failed.';
    return _RecoveryPage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton(onPressed: _prepare, child: const Text('Retry')),
          TextButton(
            onPressed: _decline,
            child: const Text('Continue without restoring'),
          ),
        ],
      ),
    );
  }
}

class _RecoveryPage extends StatelessWidget {
  final Widget child;
  const _RecoveryPage({required this.child});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    ),
  );
}

String _backupDetails(SharedBackup backup) {
  final date = backup.addedAt;
  final size = backup.sizeBytes == null
      ? 'Unknown size'
      : '${(backup.sizeBytes! / 1024).toStringAsFixed(1)} KB';
  return '${backup.name}\n${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}  $size';
}
