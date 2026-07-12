import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/recovery/backup_candidate_validator.dart';
import 'package:macrochef/services/recovery/local_data_classifier.dart';
import 'package:macrochef/services/recovery/recovery_bootstrap_store.dart';
import 'package:macrochef/services/recovery/recovery_coordinator.dart';
import 'package:macrochef/services/shared_storage.dart';
import 'package:macrochef/ui/recovery/recovery_bootstrap.dart';

void main() {
  late Directory temp;

  setUp(() => temp = Directory.systemTemp.createTempSync('recovery-ui-'));
  tearDown(() => temp.deleteSync(recursive: true));

  SharedBackup backup() => SharedBackup(
    id: 'backup-1',
    name: 'macrochef-backup-20260712.sqlite',
    addedAt: DateTime(2026, 7, 12, 9, 30),
    sizeBytes: 1536,
  );

  Future<_FakeCoordinator> pump(
    WidgetTester tester,
    RecoveryPreparation preparation, {
    bool restoreResult = true,
    Future<File?> Function()? picker,
  }) async {
    final fake = _FakeCoordinator(temp, preparation, restoreResult);
    var builds = 0;
    await tester.pumpWidget(
      RecoveryBootstrap(
        coordinator: fake,
        selectBackupFile: picker,
        appBuilder: (_) {
          builds++;
          return MaterialApp(
            home: KeyedSubtree(
              key: const Key('normal-app'),
              child: Text('$builds'),
            ),
          );
        },
      ),
    );
    expect(find.text('Checking for a backup…'), findsOneWidget);
    expect(builds, 0);
    await tester.pumpAndSettle();
    fake.appBuildCount = () => builds;
    return fake;
  }

  testWidgets('asks before replacing meaningful local data', (tester) async {
    final item = backup();
    final fake = await pump(
      tester,
      RecoveryConfirmRestore(item, File('${temp.path}/candidate')),
    );
    expect(find.text('Restore backup?'), findsOneWidget);
    expect(find.text('Restore backup'), findsOneWidget);
    expect(find.text('Keep current data'), findsOneWidget);
    expect(find.textContaining(item.name), findsOneWidget);
    expect(find.textContaining('1.5 KB'), findsOneWidget);
    expect(fake.appBuildCount(), 0);
  });

  testWidgets('automatically restores into an empty database', (tester) async {
    final fake = await pump(
      tester,
      RecoveryAutoRestore(backup(), File('${temp.path}/candidate')),
    );
    expect(fake.restoreCalls, 1);
    expect(find.byKey(const Key('normal-app')), findsOneWidget);
    expect(fake.appBuildCount(), 1);
  });

  testWidgets('decline keeps current data and builds app once', (tester) async {
    final fake = await pump(
      tester,
      RecoveryConfirmRestore(backup(), File('${temp.path}/candidate')),
    );
    await tester.tap(find.text('Keep current data'));
    await tester.pumpAndSettle();
    expect(fake.declineCalls, 1);
    expect(fake.appBuildCount(), 1);
  });

  testWidgets('file picker cancellation stays at access request', (
    tester,
  ) async {
    final fake = await pump(
      tester,
      RecoveryNeedsFileAccess(backup()),
      picker: () async => null,
    );
    await tester.tap(find.text('Select backup file'));
    await tester.pumpAndSettle();
    expect(find.text('Select backup file'), findsOneWidget);
    expect(fake.selectedCalls, 0);
    expect(fake.appBuildCount(), 0);
  });

  testWidgets('restore failure offers retry and continue actions', (
    tester,
  ) async {
    final fake = await pump(
      tester,
      RecoveryAutoRestore(backup(), File('${temp.path}/candidate')),
      restoreResult: false,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Continue without restoring'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(fake.prepareCalls, 2);
    await tester.tap(find.text('Continue without restoring'));
    await tester.pumpAndSettle();
    expect(fake.declineCalls, 1);
    expect(fake.appBuildCount(), 1);
  });

  testWidgets('selected backup is prepared and restored', (tester) async {
    final selected = File('${temp.path}/selected.sqlite')
      ..writeAsStringSync('x');
    final fake = await pump(
      tester,
      RecoveryNeedsFileAccess(backup()),
      picker: () async => selected,
    );
    fake.selectedPreparation = RecoveryAutoRestore(
      backup(),
      File('${temp.path}/candidate'),
    );
    await tester.tap(find.text('Select backup file'));
    await tester.pumpAndSettle();
    expect(fake.selectedCalls, 1);
    expect(fake.restoreCalls, 1);
    expect(fake.appBuildCount(), 1);
  });
}

class _FakeCoordinator extends RecoveryCoordinator {
  RecoveryPreparation preparation;
  final bool restoreResult;
  int prepareCalls = 0;
  int restoreCalls = 0;
  int declineCalls = 0;
  int selectedCalls = 0;
  late int Function() appBuildCount;
  RecoveryPreparation? selectedPreparation;

  _FakeCoordinator(Directory temp, this.preparation, this.restoreResult)
    : super(
        bootstrapStore: RecoveryBootstrapStore(File('${temp.path}/marker')),
        sharedStorage: const NoopSharedStorage(),
        validator: const BackupCandidateValidator(),
        classifier: const LocalDataClassifier(),
        liveDatabase: File('${temp.path}/db'),
        pendingRestore: File('${temp.path}/pending'),
        privateCandidate: (_) => File('${temp.path}/candidate'),
      );

  @override
  Future<RecoveryPreparation> prepare() async {
    prepareCalls++;
    return preparation;
  }

  @override
  Future<RecoveryPreparation> prepareSelectedFile(
    SharedBackup backup,
    File picked,
  ) async {
    selectedCalls++;
    return selectedPreparation ?? preparation;
  }

  @override
  Future<bool> restore(RecoveryAutoRestore prepared) async {
    restoreCalls++;
    return restoreResult;
  }

  @override
  Future<void> decline() async => declineCalls++;
}
