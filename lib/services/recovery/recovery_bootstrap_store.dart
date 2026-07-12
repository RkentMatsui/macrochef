import 'dart:convert';
import 'dart:io';

enum RecoveryBootstrapStatus {
  newInstall,
  recoveryApplied,
  initialized,
  recoveryDeclined,
}

class RecoveryBootstrapRecord {
  final RecoveryBootstrapStatus status;
  final String? consumedBackupId;
  final String? consumedBackupName;

  const RecoveryBootstrapRecord({
    required this.status,
    this.consumedBackupId,
    this.consumedBackupName,
  });
}

class RecoveryBootstrapStore {
  final File marker;

  const RecoveryBootstrapStore(this.marker);

  Future<RecoveryBootstrapRecord> read() async {
    if (!await marker.exists()) {
      return const RecoveryBootstrapRecord(
        status: RecoveryBootstrapStatus.newInstall,
      );
    }

    try {
      final decoded = jsonDecode(await marker.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return _initializedRecord;
      }

      final statusName = decoded['status'];
      final status = RecoveryBootstrapStatus.values
          .where((value) => value.name == statusName)
          .firstOrNull;
      if (status == null) {
        return _initializedRecord;
      }

      final consumedBackupId = decoded['consumedBackupId'];
      final consumedBackupName = decoded['consumedBackupName'];
      if (consumedBackupId is! String? || consumedBackupName is! String?) {
        return _initializedRecord;
      }

      return RecoveryBootstrapRecord(
        status: status,
        consumedBackupId: consumedBackupId,
        consumedBackupName: consumedBackupName,
      );
    } on FormatException {
      return _initializedRecord;
    }
  }

  Future<void> write(RecoveryBootstrapRecord record) async {
    await marker.parent.create(recursive: true);
    final temporaryMarker = File('${marker.path}.tmp');
    await temporaryMarker.writeAsString(
      jsonEncode({
        'status': record.status.name,
        'consumedBackupId': record.consumedBackupId,
        'consumedBackupName': record.consumedBackupName,
      }),
      flush: true,
    );
    await temporaryMarker.rename(marker.path);
  }

  Future<void> clear() async {
    if (await marker.exists()) {
      await marker.delete();
    }
  }

  static const _initializedRecord = RecoveryBootstrapRecord(
    status: RecoveryBootstrapStatus.initialized,
  );
}
