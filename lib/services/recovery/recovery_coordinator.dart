import 'dart:io';

import 'package:path/path.dart' as p;

import '../auto_backup.dart';
import '../backup_service.dart';
import '../shared_storage.dart';
import 'backup_candidate_validator.dart';
import 'local_data_classifier.dart';
import 'recovery_bootstrap_store.dart';

sealed class RecoveryPreparation {
  const RecoveryPreparation();
}

class RecoverySkip extends RecoveryPreparation {
  const RecoverySkip();
}

class RecoveryNeedsFileAccess extends RecoveryPreparation {
  final SharedBackup backup;
  const RecoveryNeedsFileAccess(this.backup);
}

class RecoveryAutoRestore extends RecoveryPreparation {
  final SharedBackup backup;
  final File candidate;
  const RecoveryAutoRestore(this.backup, this.candidate);
}

class RecoveryConfirmRestore extends RecoveryAutoRestore {
  const RecoveryConfirmRestore(super.backup, super.candidate);
}

class RecoveryPrepareError extends RecoveryPreparation {
  final String message;
  const RecoveryPrepareError(this.message);
}

class RecoveryCoordinator {
  final RecoveryBootstrapStore bootstrapStore;
  final SharedStorage sharedStorage;
  final BackupCandidateValidator validator;
  final LocalDataClassifier classifier;
  final File liveDatabase;
  final File pendingRestore;
  final File Function(SharedBackup backup) privateCandidate;

  const RecoveryCoordinator({
    required this.bootstrapStore,
    required this.sharedStorage,
    required this.validator,
    required this.classifier,
    required this.liveDatabase,
    required this.pendingRestore,
    required this.privateCandidate,
  });

  Future<RecoveryPreparation> prepare() async {
    try {
      final bootstrap = await bootstrapStore.read();
      if (bootstrap.status != RecoveryBootstrapStatus.newInstall) {
        return const RecoverySkip();
      }

      if (await pendingRestore.exists()) {
        final pending = SharedBackup(
          id: 'pending-restore',
          name: 'macrochef.import.sqlite',
          addedAt: DateTime.fromMillisecondsSinceEpoch(0),
          ownedByApp: true,
        );
        return _classify(pending, pendingRestore);
      }

      final backups = [...await sharedStorage.listDownloads(kBackupPrefix)]
        ..sort((left, right) => right.addedAt.compareTo(left.addedAt));
      if (backups.isEmpty) {
        return RecoveryNeedsFileAccess(_manualSelectionBackup());
      }

      for (final backup in backups) {
        final candidate = privateCandidate(backup);
        try {
          if (await candidate.exists()) await candidate.delete();
          await candidate.parent.create(recursive: true);
          await sharedStorage.copyToPrivate(backup, candidate);
        } on SharedStorageAccessException {
          return RecoveryNeedsFileAccess(backup);
        }
        if ((await validator.validate(candidate)).isValid) {
          return _classify(backup, candidate);
        }
        if (await candidate.exists()) await candidate.delete();
      }

      return RecoveryNeedsFileAccess(_manualSelectionBackup());
    } catch (error) {
      return RecoveryPrepareError(error.toString());
    }
  }

  Future<RecoveryPreparation> prepareSelectedFile(
    SharedBackup backup,
    File picked,
  ) async {
    try {
      final selectedBackup = backup.id.isEmpty
          ? SharedBackup(
              id: '',
              name: p.basename(picked.path),
              addedAt: DateTime.now(),
            )
          : backup;
      final candidate = privateCandidate(selectedBackup);
      if (await candidate.exists()) await candidate.delete();
      await candidate.parent.create(recursive: true);
      await picked.copy(candidate.path);
      if (!(await validator.validate(candidate)).isValid) {
        await candidate.delete();
        return const RecoveryPrepareError('The selected backup is invalid.');
      }
      return _classify(selectedBackup, candidate);
    } catch (error) {
      return RecoveryPrepareError(error.toString());
    }
  }

  Future<bool> restore(RecoveryAutoRestore prepared) async {
    try {
      if (!(await validator.validate(prepared.candidate)).isValid) return false;
      final result = await BackupIO.replaceWithRollback(
        source: prepared.candidate,
        dbFile: liveDatabase,
        verify: (file) async => (await validator.validate(file)).isValid,
      );
      if (result != RestoreReplacementResult.applied) return false;
      await bootstrapStore.write(
        RecoveryBootstrapRecord(
          status: RecoveryBootstrapStatus.recoveryApplied,
          consumedBackupId: prepared.backup.id.isEmpty
              ? null
              : prepared.backup.id,
          consumedBackupName: prepared.backup.name,
        ),
      );
      return true;
    } finally {
      if (await prepared.candidate.exists()) await prepared.candidate.delete();
    }
  }

  Future<void> decline() =>
      _writeStatus(RecoveryBootstrapStatus.recoveryDeclined);

  Future<RecoveryPreparation> _classify(
    SharedBackup backup,
    File candidate,
  ) async {
    if (!(await validator.validate(candidate)).isValid) {
      return const RecoveryPrepareError('The backup candidate is invalid.');
    }
    final state = await classifier.classify(liveDatabase);
    return switch (state) {
      LocalDataState.absent ||
      LocalDataState.empty ||
      LocalDataState.seededOnly => RecoveryAutoRestore(backup, candidate),
      LocalDataState.meaningful ||
      LocalDataState.ambiguous => RecoveryConfirmRestore(backup, candidate),
    };
  }

  Future<void> _writeStatus(RecoveryBootstrapStatus status) =>
      bootstrapStore.write(RecoveryBootstrapRecord(status: status));

  SharedBackup _manualSelectionBackup() => SharedBackup(
    id: '',
    name: 'Select a MacroChef backup from Downloads/MacroChef',
    addedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
}
