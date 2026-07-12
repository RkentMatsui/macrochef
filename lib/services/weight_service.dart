import '../data/database.dart';
import '../data/repositories/weight_repository.dart';
import '../data/repositories/settings_repository.dart';

const kWeightUnitKey = 'weight_unit'; // 'kg' | 'lb'

const double _kgPerLb = 0.45359237;

class WeightService {
  final WeightRepository weights;
  final SettingsRepository settings;
  static const double _alpha = 0.1; // EWMA, ~10-day smoothing of daily weigh-ins

  WeightService({required this.weights, required this.settings});

  // Weight is always stored in kg internally; the unit setting only controls
  // how values are displayed and entered in the UI. These helpers are the
  // single conversion point so display/input paths stay consistent.
  static double kgToLb(double kg) => kg / _kgPerLb;
  static double lbToKg(double lb) => lb * _kgPerLb;

  Future<bool> get isLbs async => (await settings.get(kWeightUnitKey)) == 'lb';
  Future<String> get unitLabel async => (await isLbs) ? 'lb' : 'kg';
  Future<void> setUnit(String unit) => settings.set(kWeightUnitKey, unit);

  Future<void> logWeight(String date, double kg) => weights.upsert(date, kg);
  Future<void> deleteWeight(String date) => weights.delete(date);
  Future<List<WeightEntry>> history() => weights.all();
  Future<WeightEntry?> forDate(String date) => weights.forDate(date);

  /// EWMA trend series over all entries (ascending). trend[0] seeds with the
  /// first observation; trend[i] = alpha*raw[i] + (1-alpha)*trend[i-1].
  Future<List<({String date, double raw, double trend})>> trendSeries() async {
    final entries = await weights.all();
    if (entries.isEmpty) return [];
    final out = <({String date, double raw, double trend})>[];
    double trend = entries.first.kg;
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      trend = i == 0 ? e.kg : _alpha * e.kg + (1 - _alpha) * trend;
      out.add((date: e.date, raw: e.kg, trend: trend));
    }
    return out;
  }

  Future<WeightEntry?> latestEntry() async {
    final e = await weights.all();
    return e.isEmpty ? null : e.last;
  }

  Future<double?> latestTrend() async {
    final s = await trendSeries();
    return s.isEmpty ? null : s.last.trend;
  }
}
