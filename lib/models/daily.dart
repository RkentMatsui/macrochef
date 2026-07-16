import 'macros.dart';

class DailyTarget {
  final double kcal, protein, carb, fat;
  const DailyTarget({
    required this.kcal,
    required this.protein,
    required this.carb,
    required this.fat,
  });
}

class DailyTotals {
  final MacroValues consumed;
  final DailyTarget? target;
  const DailyTotals(this.consumed, this.target);
}

/// Immutable audit record for an effective-dated adaptive target.
///
/// This is a domain model; Task 2 persists it separately from manual targets.
class AdaptiveTargetRecord {
  final DailyTarget target;
  final String calculatedThrough;
  final String effectiveFrom;
  final String windowStart;
  final int qualifiedIntakeDays;
  final int weightObservationCount;
  final double estimatedMaintenanceKcal;
  final double appliedAdjustmentKcal;
  final String reason;
  final DateTime createdAt;

  const AdaptiveTargetRecord({
    required this.target,
    required this.calculatedThrough,
    required this.effectiveFrom,
    required this.windowStart,
    required this.qualifiedIntakeDays,
    required this.weightObservationCount,
    required this.estimatedMaintenanceKcal,
    required this.appliedAdjustmentKcal,
    required this.reason,
    required this.createdAt,
  });
}

/// Typed outcome of an adaptive target check/calculation.
sealed class AdaptiveResult {
  const AdaptiveResult();
}

class AdaptiveApplied extends AdaptiveResult {
  final AdaptiveTargetRecord record;
  const AdaptiveApplied(this.record);

  DailyTarget get target => record.target;
}

class AdaptiveNotDue extends AdaptiveResult {
  final String nextEligibleDate;
  final String? lastAttemptedDate;
  const AdaptiveNotDue({
    required this.nextEligibleDate,
    this.lastAttemptedDate,
  });
}

class AdaptiveInsufficientData extends AdaptiveResult {
  final String reason;
  final int qualifiedIntakeDays;
  final int weightObservationCount;
  const AdaptiveInsufficientData({
    required this.reason,
    required this.qualifiedIntakeDays,
    required this.weightObservationCount,
  });
}

class AdaptiveDisabled extends AdaptiveResult {
  const AdaptiveDisabled();
}

class AdaptiveFailed extends AdaptiveResult {
  final String reason;
  const AdaptiveFailed(this.reason);
}
