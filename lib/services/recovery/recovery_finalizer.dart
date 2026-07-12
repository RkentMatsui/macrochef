import '../auto_backup.dart';
import '../shared_storage.dart';
import 'recovery_bootstrap_store.dart';

class RecoveryFinalizer {
  final RecoveryBootstrapStore store;
  final AutoBackupService autoBackup;
  final SharedStorage shared;

  const RecoveryFinalizer({
    required this.store,
    required this.autoBackup,
    required this.shared,
  });

  /// Returns true when recovery finalization was attempted, preventing a
  /// second ordinary launch backup from running during the same launch.
  Future<bool> run(DateTime now) async {
    final record = await store.read();
    if (record.status != RecoveryBootstrapStatus.recoveryApplied) return false;

    final backupResult = await autoBackup.runOnLaunch(now, force: true);
    if (backupResult.status != AutoBackupRunStatus.saved) return true;

    final consumedBackupId = record.consumedBackupId;
    if (consumedBackupId != null) {
      try {
        final deleteResult = await shared.deleteDownload(consumedBackupId);
        switch (deleteResult) {
          case SharedDeleteResult.deleted:
          case SharedDeleteResult.declined:
          case SharedDeleteResult.notFound:
            break;
        }
      } catch (_) {
        // The fresh backup is durable; source cleanup is best-effort and must
        // not keep recovery pending indefinitely.
      }
    }

    await store.write(
      const RecoveryBootstrapRecord(
        status: RecoveryBootstrapStatus.initialized,
      ),
    );
    return true;
  }
}
