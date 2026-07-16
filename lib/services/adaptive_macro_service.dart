import '../data/repositories/log_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/target_repository.dart';
import '../models/daily.dart';
import 'weight_service.dart';

const kAdaptiveEnabled = 'adaptive_enabled';
const kGoalType = 'adaptive_goal';
const kGoalRateKgPerWeek = 'adaptive_rate_kg_wk';
const kGoalWeightKg = 'adaptive_goal_weight_kg';

const double _kcalPerKg = 7700;
const double _maxAdjustKcal = 150;
const int kAdaptiveWindowDays = 28;
const int kAdaptiveMinimumQualifiedDays = 7;
const int kAdaptiveMinimumWeightObservations = 7;
const int kAdaptiveMinimumSpanDays = 14;

/// Calculates date-stable adaptive targets.  Scheduling belongs to
/// [AdaptiveTargetCoordinator]; this class never reads the clock when callers
/// use [calculate].
class AdaptiveMacroService {
  final LogRepository logs;
  final TargetRepository targets;
  final SettingsRepository settings;
  final WeightService weightService;

  AdaptiveMacroService({
    required this.logs,
    required this.targets,
    required this.settings,
    required this.weightService,
  });

  Future<bool> get isEnabled async =>
      (await settings.get(kAdaptiveEnabled)) == 'true';
  Future<void> setEnabled(bool value) =>
      settings.set(kAdaptiveEnabled, value ? 'true' : 'false');
  Future<String> getGoal() async =>
      (await settings.get(kGoalType)) ?? 'maintain';
  Future<void> setGoal(String goal) => settings.set(kGoalType, goal);
  Future<double> getGoalRate() async =>
      double.tryParse(await settings.get(kGoalRateKgPerWeek) ?? '') ?? 0.25;
  Future<void> setGoalRate(double rate) =>
      settings.set(kGoalRateKgPerWeek, rate.toString());
  Future<double?> getGoalWeight() async =>
      double.tryParse(await settings.get(kGoalWeightKg) ?? '');
  Future<void> setGoalWeight(double? kg) => kg == null
      ? settings.delete(kGoalWeightKg)
      : settings.set(kGoalWeightKg, kg.toString());

  static String goalFromWeights(
    double currentKg,
    double goalKg, {
    double deadbandKg = 0.5,
  }) {
    final difference = goalKg - currentKg;
    if (difference.abs() <= deadbandKg) return 'maintain';
    return difference < 0 ? 'lose' : 'gain';
  }

  /// Computes and persists a target only after all eligibility checks pass.
  /// Dates are local YYYY-MM-DD values derived from supplied calendar dates.
  Future<AdaptiveResult> calculate({
    required DateTime calculatedThrough,
    required DateTime effectiveFrom,
  }) async {
    final cutoff = _date(calculatedThrough);
    final effective = _date(effectiveFrom);
    final windowStart = _date(
      DateTime(
        calculatedThrough.year,
        calculatedThrough.month,
        calculatedThrough.day,
      ).subtract(const Duration(days: kAdaptiveWindowDays - 1)),
    );

    final entries = await logs.forDateRange(windowStart, cutoff);
    final grouped = <String, List<dynamic>>{};
    for (final entry in entries) {
      (grouped[entry.date] ??= []).add(entry);
    }

    var qualifiedDays = 0;
    var totalKcal = 0.0;
    for (final day in grouped.entries) {
      final target = await targets.get(day.key);
      final calories = day.value.fold<double>(
        0,
        (sum, entry) => sum + entry.kcal,
      );
      // A two-entry day is enough evidence even when it is below target. A
      // one-entry day needs to reach 60% of that day's effective target.
      final qualifies =
          day.value.length >= 2 ||
          (target != null && calories >= target.kcal * 0.60);
      if (qualifies) {
        qualifiedDays++;
        totalKcal += calories;
      }
    }

    final trend = (await weightService.trendSeries())
        .where(
          (point) =>
              point.date.compareTo(windowStart) >= 0 &&
              point.date.compareTo(cutoff) <= 0,
        )
        .toList();
    final spanDays = trend.length < 2
        ? 0
        : _daysBetween(trend.first.date, trend.last.date);
    if (qualifiedDays < kAdaptiveMinimumQualifiedDays ||
        trend.length < kAdaptiveMinimumWeightObservations ||
        // A range from day 1 through day 14 spans 13 midnight boundaries but
        // contains 14 calendar days, which is the required minimum window.
        spanDays + 1 < kAdaptiveMinimumSpanDays) {
      final missing = qualifiedDays < kAdaptiveMinimumQualifiedDays
          ? 'Need at least $kAdaptiveMinimumQualifiedDays qualified intake days.'
          : trend.length < kAdaptiveMinimumWeightObservations
          ? 'Need at least $kAdaptiveMinimumWeightObservations weight observations.'
          : 'Need at least $kAdaptiveMinimumSpanDays calendar days of data.';
      return AdaptiveInsufficientData(
        reason: missing,
        qualifiedIntakeDays: qualifiedDays,
        weightObservationCount: trend.length,
      );
    }

    final averageIntake = totalKcal / qualifiedDays;
    final weightKcalPerDay =
        (trend.last.trend - trend.first.trend) * _kcalPerKg / spanDays;
    final maintenance = averageIntake - weightKcalPerDay;
    final current = await targets.get(cutoff);
    if (current == null) {
      return AdaptiveInsufficientData(
        reason: 'Set a daily target before calculating an adaptive target.',
        qualifiedIntakeDays: qualifiedDays,
        weightObservationCount: trend.length,
      );
    }

    var goal = await getGoal();
    final goalWeight = await getGoalWeight();
    if (goalWeight != null) {
      goal = goalFromWeights(trend.last.trend, goalWeight);
    }
    final rate = await getGoalRate();
    final goalOffset = switch (goal) {
      'lose' => -(rate * _kcalPerKg / 7),
      'gain' => rate * _kcalPerKg / 7,
      _ => 0.0,
    };
    final desired = maintenance + goalOffset;
    final adjustment = (desired - current.kcal)
        .clamp(-_maxAdjustKcal, _maxAdjustKcal)
        .toDouble();
    final newKcal = (current.kcal + adjustment)
        .clamp(1200.0, 6000.0)
        .toDouble();
    final target = _withKcalKeepingProtein(current, newKcal);
    final record = AdaptiveTargetRecord(
      target: target,
      calculatedThrough: cutoff,
      effectiveFrom: effective,
      windowStart: windowStart,
      qualifiedIntakeDays: qualifiedDays,
      weightObservationCount: trend.length,
      estimatedMaintenanceKcal: maintenance,
      appliedAdjustmentKcal: newKcal - current.kcal,
      reason: goal,
      // The supplied cutoff is also the deterministic audit timestamp. The
      // persistence layer may add its own database creation time separately.
      createdAt: calculatedThrough,
    );
    await targets.insertAdaptive(record);
    return AdaptiveApplied(record);
  }

  /// Compatibility entry point for existing callers. New code should inject a
  /// date through [calculate] or use [AdaptiveTargetCoordinator].
  Future<DailyTarget?> recompute({DateTime? now}) async {
    final date = now ?? DateTime.now();
    final result = await calculate(
      calculatedThrough: date,
      effectiveFrom: date.add(const Duration(days: 1)),
    );
    return result is AdaptiveApplied ? result.target : null;
  }

  static DailyTarget _withKcalKeepingProtein(DailyTarget current, double kcal) {
    final deltaKcal = kcal - current.kcal;
    // Preserve the current non-protein calorie split. If both are zero, use an
    // even calorie split as the only neutral fallback.
    final carbCalories = current.carb * 4;
    final fatCalories = current.fat * 9;
    final nonProteinCalories = carbCalories + fatCalories;
    final carbShare = nonProteinCalories > 0
        ? carbCalories / nonProteinCalories
        : 0.5;
    final fatShare = 1 - carbShare;
    var carb = current.carb + deltaKcal * carbShare / 4;
    var fat = current.fat + deltaKcal * fatShare / 9;
    if (carb < 0) {
      fat += carb * 4 / 9;
      carb = 0;
    }
    if (fat < 0) {
      carb += fat * 9 / 4;
      fat = 0;
    }
    return DailyTarget(
      kcal: kcal,
      protein: current.protein,
      carb: carb < 0 ? 0 : carb,
      fat: fat < 0 ? 0 : fat,
    );
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static int _daysBetween(String first, String last) {
    DateTime parse(String value) {
      final parts = value.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }

    final days = parse(last).difference(parse(first)).inDays.abs();
    return days < 1 ? 1 : days;
  }
}
