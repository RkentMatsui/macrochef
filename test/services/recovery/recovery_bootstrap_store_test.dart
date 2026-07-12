import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/recovery/recovery_bootstrap_store.dart';

void main() {
  late Directory temporaryDirectory;
  late File marker;
  late RecoveryBootstrapStore store;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'macrochef-recovery-bootstrap-',
    );
    marker = File(
      '${temporaryDirectory.path}${Platform.pathSeparator}'
      'recovery-bootstrap-v1.json',
    );
    store = RecoveryBootstrapStore(marker);
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  test('missing marker reads as newInstall', () async {
    expect((await store.read()).status, RecoveryBootstrapStatus.newInstall);
  });

  test('recoveryApplied round-trips consumed identity', () async {
    await store.write(
      const RecoveryBootstrapRecord(
        status: RecoveryBootstrapStatus.recoveryApplied,
        consumedBackupId: 'content://7',
        consumedBackupName: 'macrochef-backup-20260711-1200.sqlite',
      ),
    );

    final record = await store.read();

    expect(record.status, RecoveryBootstrapStatus.recoveryApplied);
    expect(record.consumedBackupId, 'content://7');
    expect(record.consumedBackupName, 'macrochef-backup-20260711-1200.sqlite');
  });

  test('corrupt marker fails closed as initialized', () async {
    await marker.writeAsString('{broken');

    expect((await store.read()).status, RecoveryBootstrapStatus.initialized);
  });

  test('write atomically replaces an existing marker', () async {
    await store.write(
      const RecoveryBootstrapRecord(
        status: RecoveryBootstrapStatus.initialized,
      ),
    );

    await store.write(
      const RecoveryBootstrapRecord(
        status: RecoveryBootstrapStatus.recoveryDeclined,
      ),
    );

    expect(
      (await store.read()).status,
      RecoveryBootstrapStatus.recoveryDeclined,
    );
    expect(await File('${marker.path}.tmp').exists(), isFalse);
  });

  test('clear removes the marker', () async {
    await store.write(
      const RecoveryBootstrapRecord(
        status: RecoveryBootstrapStatus.initialized,
      ),
    );

    await store.clear();

    expect(await marker.exists(), isFalse);
    expect((await store.read()).status, RecoveryBootstrapStatus.newInstall);
  });
}
