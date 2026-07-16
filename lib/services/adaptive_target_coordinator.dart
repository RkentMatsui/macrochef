import 'dart:developer' as developer;

import '../data/repositories/settings_repository.dart';
import '../models/daily.dart';
import 'adaptive_macro_service.dart';

const kAdaptiveLastAttemptedDate = 'adaptive_last_attempted_date';
const kAdaptiveLastSuccessfulDate = 'adaptive_last_successful_date';
const kAdaptiveLastOutcome = 'adaptive_last_outcome';
const int kAdaptiveRecalculationIntervalDays = 7;

/// Serializes automatic adaptive checks and applies the once-per-week policy.
/// App/UI lifecycle code can safely call this repeatedly.
class AdaptiveTargetCoordinator {
  final AdaptiveMacroService adaptive;
  final SettingsRepository settings;
  Future<AdaptiveResult>? _inFlight;

  AdaptiveTargetCoordinator({required this.adaptive, required this.settings});

  Future<AdaptiveResult> runIfDue(
    DateTime now, {
    bool force = false,
    bool effectiveToday = false,
  }) {
    return _inFlight ??= _run(
      now,
      force: force,
      effectiveToday: effectiveToday,
    ).whenComplete(() => _inFlight = null);
  }

  Future<AdaptiveResult> _run(
    DateTime now, {
    required bool force,
    required bool effectiveToday,
  }) async {
    if (!await adaptive.isEnabled) return const AdaptiveDisabled();

    final today = _localDate(now);
    final lastAttempted = await settings.get(kAdaptiveLastAttemptedDate);
    if (!force && lastAttempted != null) {
      final next = _parseDate(
        lastAttempted,
      ).add(const Duration(days: kAdaptiveRecalculationIntervalDays));
      if (_parseDate(today).isBefore(next)) {
        return AdaptiveNotDue(
          nextEligibleDate: _localDate(next),
          lastAttemptedDate: lastAttempted,
        );
      }
    }

    // Write this first: a repeated lifecycle event after an unsuccessful
    // attempt must not continuously repeat remote/database work.
    await settings.set(kAdaptiveLastAttemptedDate, today);
    try {
      final effective = effectiveToday
          ? DateTime(now.year, now.month, now.day)
          : DateTime(now.year, now.month, now.day + 1);
      final result = await adaptive.calculate(
        calculatedThrough: now,
        effectiveFrom: effective,
      );
      if (result is AdaptiveApplied) {
        await settings.set(kAdaptiveLastSuccessfulDate, today);
      }
      await settings.set(kAdaptiveLastOutcome, _outcomeSummary(result));
      developer.log(
        'date=$today outcome=${result.runtimeType}',
        name: 'macrochef.adaptive_targets',
      );
      return result;
    } catch (error) {
      final result = AdaptiveFailed(error.toString());
      await settings.set(kAdaptiveLastOutcome, _outcomeSummary(result));
      developer.log(
        'date=$today outcome=failed',
        name: 'macrochef.adaptive_targets',
      );
      return result;
    }
  }

  static String _outcomeSummary(AdaptiveResult result) => switch (result) {
    AdaptiveApplied(:final record) =>
      'Applied ${record.target.kcal.toStringAsFixed(0)} kcal; effective ${record.effectiveFrom}.',
    AdaptiveInsufficientData(
      :final reason,
      :final qualifiedIntakeDays,
      :final weightObservationCount,
    ) =>
      '$reason Qualified days: $qualifiedIntakeDays; weigh-ins: $weightObservationCount.',
    AdaptiveFailed(:final reason) => 'Failed: $reason',
    AdaptiveNotDue(:final nextEligibleDate) =>
      'Not due; next eligible $nextEligibleDate.',
    AdaptiveDisabled() => 'Adaptive targets are disabled.',
  };

  static String _localDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static DateTime _parseDate(String value) {
    final parts = value.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
