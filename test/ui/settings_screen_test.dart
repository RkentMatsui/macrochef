import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/state/providers.dart';
import 'package:macrochef/services/nutrition/nutrition_pack_manager.dart';
import 'package:macrochef/ui/settings/settings_screen.dart';

class _FakeNutritionPackManager extends NutritionPackManager {
  NutritionPackState state = NutritionPackState.downloaded;

  @override
  Future<NutritionPackState> resolveState() async => state;

  @override
  Future<void> delete() async {
    state = NutritionPackState.notDownloaded;
  }
}

class _FakeRecoveryService implements SettingsRecoveryService {
  _FakeRecoveryService(this.result);

  final SettingsRecoveryResult result;
  var calls = 0;

  @override
  Future<SettingsRecoveryResult> recoverLatest() async {
    calls++;
    return result;
  }
}

void main() {
  // Always override the nutrition pack manager with a fake so resolveState never
  // touches path_provider in host tests (the shipped manifest is configured).
  Future<void> pumpSettings(
    WidgetTester tester, {
    SettingsRecoveryService? recoveryService,
    NutritionPackState packState = NutritionPackState.notDownloaded,
  }) async {
    FlutterSecureStorage.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          nutritionPackManagerProvider.overrideWithValue(
            _FakeNutritionPackManager()..state = packState,
          ),
        ],
        child: MaterialApp(
          home: SettingsScreen(recoveryService: recoveryService),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openBackupSheet(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Backup & Restore'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Backup & Restore'));
    await tester.pumpAndSettle();
  }

  testWidgets('SettingsScreen renders the hero + category tiles', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Targets & Body'), findsOneWidget);
    expect(find.text('AI Provider'), findsOneWidget);
    expect(find.text('Voice'), findsOneWidget);
  });

  testWidgets('Food Data shows truthful Nutrition Pack readiness controls', (
    tester,
  ) async {
    // The pack is published (sizes configured) but not yet downloaded.
    await pumpSettings(tester);
    await tester.tap(find.text('Food Data'));
    await tester.pumpAndSettle();
    expect(find.text('Nutrition Pack'), findsOneWidget);
    expect(find.text('Not downloaded'), findsOneWidget);
    expect(find.text('Use local nutrition first'), findsOneWidget);
    expect(find.textContaining('USDA FoodData Central'), findsOneWidget);
    // Configured pack → Download is enabled (was disabled while unpublished).
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Download'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('deleting Nutrition Pack disables local nutrition persistently', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final manager = _FakeNutritionPackManager();
    await db
        .into(db.settings)
        .insert(
          SettingsCompanion.insert(
            key: 'local_nutrition_enabled',
            value: 'true',
          ),
        );

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        nutritionPackManagerProvider.overrideWithValue(manager),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food Data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete pack'));
    await tester.pumpAndSettle();

    expect(
      await container
          .read(settingsRepositoryProvider)
          .get('local_nutrition_enabled'),
      'false',
    );
    expect(await manager.resolveState(), NutritionPackState.notDownloaded);
    expect(find.text('Not downloaded'), findsOneWidget);
  });

  testWidgets(
    'Backup & Restore explains and offers automatic backup recovery',
    (tester) async {
      await pumpSettings(tester);
      await openBackupSheet(tester);

      expect(find.text('Recover latest automatic backup'), findsOneWidget);
      expect(find.textContaining('Downloads/MacroChef'), findsOneWidget);
    },
  );

  testWidgets('cancelling automatic recovery leaves state unchanged', (
    tester,
  ) async {
    final recovery = _FakeRecoveryService(
      const SettingsRecoveryResult.staged('content://latest', 'latest.sqlite'),
    );
    await pumpSettings(tester, recoveryService: recovery);
    await openBackupSheet(tester);

    await tester.tap(find.text('Recover latest automatic backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(recovery.calls, 0);
    expect(find.text('Restore ready'), findsNothing);
  });

  testWidgets('invalid automatic backup shows an error', (tester) async {
    final recovery = _FakeRecoveryService(
      const SettingsRecoveryResult.error('The newest backup is invalid.'),
    );
    await pumpSettings(tester, recoveryService: recovery);
    await openBackupSheet(tester);

    await tester.tap(find.text('Recover latest automatic backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore backup'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(recovery.calls, 1);
    expect(
      find.textContaining('The newest backup is invalid.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'successful automatic recovery staging shows restart instruction',
    (tester) async {
      final recovery = _FakeRecoveryService(
        const SettingsRecoveryResult.staged(
          'content://latest',
          'macrochef-backup-20260712-1200.sqlite',
        ),
      );
      await pumpSettings(tester, recoveryService: recovery);
      await openBackupSheet(tester);

      await tester.tap(find.text('Recover latest automatic backup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore backup'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(recovery.calls, 1);
      expect(find.text('Restore ready'), findsOneWidget);
      expect(find.textContaining('swipe it away'), findsOneWidget);
    },
  );
}
