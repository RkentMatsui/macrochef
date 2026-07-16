import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/log_repository.dart';
import 'package:macrochef/data/repositories/settings_repository.dart';
import 'package:macrochef/data/repositories/target_repository.dart';
import 'package:macrochef/data/repositories/weight_repository.dart';
import 'package:macrochef/models/daily.dart';
import 'package:macrochef/services/adaptive_macro_service.dart';
import 'package:macrochef/services/adaptive_target_coordinator.dart';
import 'package:macrochef/services/weight_service.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository settings;
  late AdaptiveMacroService adaptive;
  late AdaptiveTargetCoordinator coordinator;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    adaptive = AdaptiveMacroService(
      logs: LogRepository(db),
      targets: TargetRepository(db),
      settings: settings,
      weightService: WeightService(
        weights: WeightRepository(db),
        settings: settings,
      ),
    );
    coordinator = AdaptiveTargetCoordinator(
      adaptive: adaptive,
      settings: settings,
    );
  });

  tearDown(() => db.close());

  test('disabled checks do not write scheduling state', () async {
    final result = await coordinator.runIfDue(DateTime(2026, 7, 15));
    expect(result, isA<AdaptiveDisabled>());
    expect(await settings.get(kAdaptiveLastAttemptedDate), isNull);
  });

  test(
    'records an attempt then throttles the next seven calendar days',
    () async {
      await adaptive.setEnabled(true);
      final first = await coordinator.runIfDue(DateTime(2026, 7, 15));
      expect(first, isA<AdaptiveInsufficientData>());
      expect(await settings.get(kAdaptiveLastAttemptedDate), '2026-07-15');
      expect(
        await settings.get(kAdaptiveLastOutcome),
        contains('Qualified days:'),
      );

      final second = await coordinator.runIfDue(DateTime(2026, 7, 21));
      expect(second, isA<AdaptiveNotDue>());
      expect((second as AdaptiveNotDue).nextEligibleDate, '2026-07-22');
    },
  );

  test(
    'force bypasses throttle but still uses caller supplied local date',
    () async {
      await adaptive.setEnabled(true);
      await settings.set(kAdaptiveLastAttemptedDate, '2026-07-15');
      final result = await coordinator.runIfDue(
        DateTime(2026, 7, 16),
        force: true,
        effectiveToday: true,
      );
      expect(result, isA<AdaptiveInsufficientData>());
      expect(await settings.get(kAdaptiveLastAttemptedDate), '2026-07-16');
    },
  );
}
