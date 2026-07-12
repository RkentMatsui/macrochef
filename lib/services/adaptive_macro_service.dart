import '../data/repositories/log_repository.dart';
import '../data/repositories/target_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../models/daily.dart';
import 'weight_service.dart';

const kAdaptiveEnabled = 'adaptive_enabled';      // 'true' | 'false'
const kGoalType = 'adaptive_goal';                // 'lose' | 'maintain' | 'gain'
const kGoalRateKgPerWeek = 'adaptive_rate_kg_wk'; // stringified double
const kGoalWeightKg = 'adaptive_goal_weight_kg';  // stringified double (kg), optional

const double _kcalPerKg = 7700;
const double _maxAdjustKcal = 150;

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
  Future<void> setEnabled(bool v) =>
      settings.set(kAdaptiveEnabled, v ? 'true' : 'false');
  Future<String> getGoal() async => (await settings.get(kGoalType)) ?? 'maintain';
  Future<void> setGoal(String g) => settings.set(kGoalType, g);
  Future<double> getGoalRate() async =>
      double.tryParse(await settings.get(kGoalRateKgPerWeek) ?? '') ?? 0.25;
  Future<void> setGoalRate(double r) =>
      settings.set(kGoalRateKgPerWeek, r.toString());

  /// Goal body weight in kg, or null if unset. Used (with current trend weight)
  /// to anchor the adaptive goal — see [goalFromWeights].
  Future<double?> getGoalWeight() async =>
      double.tryParse(await settings.get(kGoalWeightKg) ?? '');
  Future<void> setGoalWeight(double? kg) async {
    if (kg == null) {
      await settings.delete(kGoalWeightKg);
    } else {
      await settings.set(kGoalWeightKg, kg.toString());
    }
  }

  /// Derives the goal direction from current vs goal weight. Being within
  /// [deadbandKg] of the goal counts as 'maintain'.
  static String goalFromWeights(double currentKg, double goalKg,
      {double deadbandKg = 0.5}) {
    final diff = goalKg - currentKg;
    if (diff.abs() <= deadbandKg) return 'maintain';
    return diff < 0 ? 'lose' : 'gain';
  }

  /// Recomputes the default target from the last 14 days. Returns the new
  /// target, or null if data is insufficient (<7 weight entries, no logs, or
  /// no baseline target).
  Future<DailyTarget?> recompute() async {
    final today = _today();
    final start = _daysAgo(today, 13);

    final entries = await logs.forDateRange(start, today);
    if (entries.isEmpty) return null;

    final series = (await weightService.trendSeries())
        .where((s) => s.date.compareTo(start) >= 0 && s.date.compareTo(today) <= 0)
        .toList();
    if (series.length < 7) return null;

    final totalKcal = entries.fold<double>(0, (a, e) => a + e.kcal);
    final daysLogged = entries.map((e) => e.date).toSet().length;
    final avgIntake = totalKcal / daysLogged;

    final trendDelta = series.last.trend - series.first.trend;
    // Spread the weight change over the calendar days the series spans, NOT the
    // number of weigh-ins — sparse weigh-ins (e.g. 7 entries over 14 days) would
    // otherwise divide by 7 and double the per-day surplus.
    final spanDays = _daysBetween(series.first.date, series.last.date);
    final kcalSurplusPerDay = trendDelta * _kcalPerKg / spanDays;
    final tdee = avgIntake - kcalSurplusPerDay;

    final goal = await getGoal();
    final rate = await getGoalRate();
    final double offset;
    switch (goal) {
      case 'lose':
        offset = -(rate * _kcalPerKg / 7);
      case 'gain':
        offset = rate * _kcalPerKg / 7;
      default:
        offset = 0;
    }
    final ideal = tdee + offset;

    final current = await targets.get(today);
    if (current == null) return null;

    final diff = (ideal - current.kcal).clamp(-_maxAdjustKcal, _maxAdjustKcal);
    final newKcal = (current.kcal + diff).clamp(1200.0, 6000.0);
    final scale = current.kcal > 0 ? newKcal / current.kcal : 1.0;
    final t = DailyTarget(
      kcal: newKcal,
      protein: (current.protein * scale).roundToDouble(),
      carb: (current.carb * scale).roundToDouble(),
      fat: (current.fat * scale).roundToDouble(),
    );
    await targets.setDefault(t);
    return t;
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  /// Calendar days between two YYYY-MM-DD dates (>=1, so it never divides by 0).
  int _daysBetween(String a, String b) {
    final pa = a.split('-'), pb = b.split('-');
    final da = DateTime(int.parse(pa[0]), int.parse(pa[1]), int.parse(pa[2]));
    final db = DateTime(int.parse(pb[0]), int.parse(pb[1]), int.parse(pb[2]));
    final diff = db.difference(da).inDays.abs();
    return diff < 1 ? 1 : diff;
  }

  String _daysAgo(String today, int days) {
    final p = today.split('-');
    final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]))
        .subtract(Duration(days: days));
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
