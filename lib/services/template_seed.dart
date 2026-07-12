import 'package:drift/drift.dart' show Value;

import '../data/database.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/training_repository.dart';

/// One prescribed exercise inside a starter template. [slug] must match an
/// exercise in [kBuiltInExercises]; if a slug is missing from the library the
/// exercise is skipped so a partial catalog never crashes seeding.
class SeedTemplateExercise {
  final String slug;
  final int sets;
  final String? reps; // rep target, allows ranges like '6-8'
  final int? durationSec; // for duration-tracked moves (e.g. plank)

  const SeedTemplateExercise(
    this.slug,
    this.sets, {
    this.reps,
    this.durationSec,
  });
}

class SeedDay {
  final String name;
  final List<SeedTemplateExercise> exercises;
  const SeedDay(this.name, this.exercises);
}

class SeedProgram {
  /// Stable identity for idempotent seeding. Once a program with this key has
  /// been seeded it is never re-seeded (so a user's deletion sticks), and any
  /// program with a new key ships automatically on the next launch.
  final String key;
  final String name;
  final String notes;
  final List<SeedDay> days;
  const SeedProgram(this.key, this.name, this.notes, this.days);
}

/// Science-based starter programs in the style popularised by Jeff Nippard
/// (compound-led, RPE/hypertrophy rep ranges). These are general training
/// splits — not copies of any proprietary paid program. Three programs, each a
/// named collection of days: a 6-day Push/Pull/Legs, a 4-day Upper/Lower, and a
/// 3-day Full Body.
const List<SeedProgram> kStarterPrograms = [
  SeedProgram('ppl-6', 'Push/Pull/Legs (6-day)',
      'Compound-led PPL — hypertrophy rep ranges.', [
    SeedDay('Push A', [
      SeedTemplateExercise('bench-press', 4, reps: '6-8'),
      SeedTemplateExercise('overhead-press', 3, reps: '8-10'),
      SeedTemplateExercise('incline-dumbbell-press', 3, reps: '10-12'),
      SeedTemplateExercise('lateral-raise', 3, reps: '12-15'),
      SeedTemplateExercise('triceps-pushdown', 3, reps: '10-12'),
      SeedTemplateExercise('dips', 2, reps: '10-12'),
    ]),
    SeedDay('Pull A', [
      SeedTemplateExercise('deadlift', 3, reps: '5'),
      SeedTemplateExercise('pull-up', 3, reps: '6-10'),
      SeedTemplateExercise('barbell-row', 3, reps: '8-10'),
      SeedTemplateExercise('lat-pulldown', 3, reps: '10-12'),
      SeedTemplateExercise('face-pull', 3, reps: '15-20'),
      SeedTemplateExercise('barbell-curl', 3, reps: '10-12'),
    ]),
    SeedDay('Legs A', [
      SeedTemplateExercise('back-squat', 4, reps: '6-8'),
      SeedTemplateExercise('romanian-deadlift', 3, reps: '8-10'),
      SeedTemplateExercise('leg-press', 3, reps: '10-12'),
      SeedTemplateExercise('leg-curl', 3, reps: '10-12'),
      SeedTemplateExercise('calf-raise', 4, reps: '12-15'),
    ]),
    SeedDay('Push B', [
      SeedTemplateExercise('incline-bench-press', 4, reps: '8-10'),
      SeedTemplateExercise('dumbbell-shoulder-press', 3, reps: '10-12'),
      SeedTemplateExercise('cable-fly', 3, reps: '12-15'),
      SeedTemplateExercise('lateral-raise', 3, reps: '15-20'),
      SeedTemplateExercise('skullcrusher', 3, reps: '10-12'),
      SeedTemplateExercise('triceps-pushdown', 2, reps: '12-15'),
    ]),
    SeedDay('Pull B', [
      SeedTemplateExercise('barbell-row', 4, reps: '8-10'),
      SeedTemplateExercise('lat-pulldown', 3, reps: '10-12'),
      SeedTemplateExercise('seated-cable-row', 3, reps: '10-12'),
      SeedTemplateExercise('face-pull', 3, reps: '15-20'),
      SeedTemplateExercise('hammer-curl', 3, reps: '10-12'),
      SeedTemplateExercise('preacher-curl', 3, reps: '12-15'),
    ]),
    SeedDay('Legs B', [
      SeedTemplateExercise('front-squat', 3, reps: '8-10'),
      SeedTemplateExercise('hip-thrust', 3, reps: '8-10'),
      SeedTemplateExercise('walking-lunge', 3, reps: '10-12'),
      SeedTemplateExercise('leg-extension', 3, reps: '12-15'),
      SeedTemplateExercise('leg-curl', 3, reps: '12-15'),
      SeedTemplateExercise('calf-raise', 4, reps: '15-20'),
    ]),
  ]),
  SeedProgram('upper-lower-4', 'Upper/Lower (4-day)',
      'Strength + hypertrophy upper/lower split.', [
    SeedDay('Upper A (Strength)', [
      SeedTemplateExercise('bench-press', 4, reps: '5-6'),
      SeedTemplateExercise('barbell-row', 4, reps: '6-8'),
      SeedTemplateExercise('overhead-press', 3, reps: '8-10'),
      SeedTemplateExercise('lat-pulldown', 3, reps: '10-12'),
      SeedTemplateExercise('barbell-curl', 3, reps: '10-12'),
      SeedTemplateExercise('triceps-pushdown', 3, reps: '10-12'),
    ]),
    SeedDay('Lower A (Strength)', [
      SeedTemplateExercise('back-squat', 4, reps: '5-6'),
      SeedTemplateExercise('romanian-deadlift', 3, reps: '8-10'),
      SeedTemplateExercise('leg-press', 3, reps: '10-12'),
      SeedTemplateExercise('leg-curl', 3, reps: '10-12'),
      SeedTemplateExercise('calf-raise', 4, reps: '12-15'),
    ]),
    SeedDay('Upper B (Hypertrophy)', [
      SeedTemplateExercise('incline-dumbbell-press', 4, reps: '8-10'),
      SeedTemplateExercise('seated-cable-row', 4, reps: '10-12'),
      SeedTemplateExercise('dumbbell-shoulder-press', 3, reps: '10-12'),
      SeedTemplateExercise('pull-up', 3, reps: '8-10'),
      SeedTemplateExercise('lateral-raise', 3, reps: '15-20'),
      SeedTemplateExercise('hammer-curl', 3, reps: '12-15'),
      SeedTemplateExercise('skullcrusher', 3, reps: '12-15'),
    ]),
    SeedDay('Lower B (Hypertrophy)', [
      SeedTemplateExercise('deadlift', 3, reps: '5'),
      SeedTemplateExercise('hip-thrust', 3, reps: '8-10'),
      SeedTemplateExercise('bulgarian-split-squat', 3, reps: '10-12'),
      SeedTemplateExercise('leg-extension', 3, reps: '15-20'),
      SeedTemplateExercise('leg-curl', 3, reps: '15-20'),
      SeedTemplateExercise('calf-raise', 4, reps: '15-20'),
    ]),
  ]),
  SeedProgram('full-body-3', 'Full Body (3-day)', 'Balanced 3-day full-body.', [
    SeedDay('Day A', [
      SeedTemplateExercise('back-squat', 3, reps: '6-8'),
      SeedTemplateExercise('bench-press', 3, reps: '6-8'),
      SeedTemplateExercise('barbell-row', 3, reps: '8-10'),
      SeedTemplateExercise('lateral-raise', 3, reps: '12-15'),
      SeedTemplateExercise('triceps-pushdown', 3, reps: '12-15'),
      SeedTemplateExercise('cable-crunch', 3, reps: '12-15'),
    ]),
    SeedDay('Day B', [
      SeedTemplateExercise('deadlift', 3, reps: '5'),
      SeedTemplateExercise('overhead-press', 3, reps: '8-10'),
      SeedTemplateExercise('lat-pulldown', 3, reps: '10-12'),
      SeedTemplateExercise('leg-press', 3, reps: '12-15'),
      SeedTemplateExercise('barbell-curl', 3, reps: '12-15'),
      SeedTemplateExercise('plank', 3, durationSec: 45),
    ]),
    SeedDay('Day C', [
      SeedTemplateExercise('front-squat', 3, reps: '8-10'),
      SeedTemplateExercise('incline-bench-press', 3, reps: '8-10'),
      SeedTemplateExercise('seated-cable-row', 3, reps: '10-12'),
      SeedTemplateExercise('leg-curl', 3, reps: '12-15'),
      SeedTemplateExercise('hammer-curl', 3, reps: '12-15'),
      SeedTemplateExercise('calf-raise', 4, reps: '15-20'),
    ]),
  ]),

  // ===== Jeff Nippard-inspired bundle =====
  SeedProgram(
      'jn-fundamentals-3',
      'Jeff Nippard — Fundamentals (Full Body 3-day)',
      'Beginner-friendly full-body plan inspired by Jeff Nippard — big compounds, simple progression.',
      [
        SeedDay('Day 1', [
          SeedTemplateExercise('back-squat', 3, reps: '6-8'),
          SeedTemplateExercise('bench-press', 3, reps: '6-8'),
          SeedTemplateExercise('lat-pulldown', 3, reps: '8-10'),
          SeedTemplateExercise('dumbbell-shoulder-press', 2, reps: '10-12'),
          SeedTemplateExercise('dumbbell-curl', 2, reps: '10-12'),
          SeedTemplateExercise('plank', 3, durationSec: 45),
        ]),
        SeedDay('Day 2', [
          SeedTemplateExercise('romanian-deadlift', 3, reps: '8-10'),
          SeedTemplateExercise('incline-dumbbell-press', 3, reps: '8-10'),
          SeedTemplateExercise('seated-cable-row', 3, reps: '10-12'),
          SeedTemplateExercise('lateral-raise', 3, reps: '12-15'),
          SeedTemplateExercise('triceps-pushdown', 2, reps: '10-12'),
          SeedTemplateExercise('hanging-knee-raise', 3, reps: '12-15'),
        ]),
        SeedDay('Day 3', [
          SeedTemplateExercise('leg-press', 3, reps: '10-12'),
          SeedTemplateExercise('machine-chest-press', 3, reps: '10-12'),
          SeedTemplateExercise('chin-up', 3, reps: '6-10'),
          SeedTemplateExercise('face-pull', 3, reps: '15-20'),
          SeedTemplateExercise('hammer-curl', 2, reps: '12-15'),
          SeedTemplateExercise('calf-raise', 3, reps: '12-15'),
        ]),
      ]),
  SeedProgram(
      'jn-upper-lower-4',
      'Jeff Nippard — Upper/Lower (4-day)',
      'Hypertrophy-focused upper/lower split inspired by Jeff Nippard with cable and machine isolation work.',
      [
        SeedDay('Upper 1', [
          SeedTemplateExercise('incline-bench-press', 4, reps: '6-8'),
          SeedTemplateExercise('chest-supported-row', 4, reps: '8-10'),
          SeedTemplateExercise('arnold-press', 3, reps: '10-12'),
          SeedTemplateExercise('cable-lateral-raise', 3, reps: '12-15'),
          SeedTemplateExercise('overhead-cable-extension', 3, reps: '10-12'),
          SeedTemplateExercise('incline-dumbbell-curl', 3, reps: '10-12'),
        ]),
        SeedDay('Lower 1', [
          SeedTemplateExercise('back-squat', 4, reps: '6-8'),
          SeedTemplateExercise('romanian-deadlift', 3, reps: '8-10'),
          SeedTemplateExercise('leg-press', 3, reps: '12-15'),
          SeedTemplateExercise('seated-leg-curl', 3, reps: '12-15'),
          SeedTemplateExercise('seated-calf-raise', 4, reps: '12-15'),
        ]),
        SeedDay('Upper 2', [
          SeedTemplateExercise('dumbbell-bench-press', 4, reps: '8-10'),
          SeedTemplateExercise('lat-pulldown', 4, reps: '10-12'),
          SeedTemplateExercise('cable-crossover', 3, reps: '12-15'),
          SeedTemplateExercise('reverse-pec-deck', 3, reps: '15-20'),
          SeedTemplateExercise('close-grip-bench-press', 3, reps: '8-10'),
          SeedTemplateExercise('cable-curl', 3, reps: '12-15'),
        ]),
        SeedDay('Lower 2', [
          SeedTemplateExercise('hack-squat', 4, reps: '8-10'),
          SeedTemplateExercise('hip-thrust', 3, reps: '8-10'),
          SeedTemplateExercise('walking-lunge', 3, reps: '10-12'),
          SeedTemplateExercise('leg-extension', 3, reps: '15-20'),
          SeedTemplateExercise('seated-leg-curl', 3, reps: '15-20'),
          SeedTemplateExercise('seated-calf-raise', 4, reps: '15-20'),
        ]),
      ]),
  SeedProgram(
      'jn-ppl-6',
      'Jeff Nippard — Pure Bodybuilding PPL (6-day)',
      'High-volume push/pull/legs inspired by Jeff Nippard — lots of isolation and intensity techniques.',
      [
        SeedDay('Push 1', [
          SeedTemplateExercise('bench-press', 4, reps: '6-8'),
          SeedTemplateExercise('overhead-press', 3, reps: '8-10'),
          SeedTemplateExercise('incline-dumbbell-press', 3, reps: '10-12'),
          SeedTemplateExercise('cable-lateral-raise', 4, reps: '12-15'),
          SeedTemplateExercise('overhead-triceps-extension', 3, reps: '10-12'),
          SeedTemplateExercise('triceps-pushdown', 3, reps: '12-15'),
        ]),
        SeedDay('Pull 1', [
          SeedTemplateExercise('deadlift', 3, reps: '5'),
          SeedTemplateExercise('pull-up', 3, reps: '6-10'),
          SeedTemplateExercise('pendlay-row', 3, reps: '8-10'),
          SeedTemplateExercise('straight-arm-pulldown', 3, reps: '12-15'),
          SeedTemplateExercise('face-pull', 3, reps: '15-20'),
          SeedTemplateExercise('incline-dumbbell-curl', 3, reps: '10-12'),
        ]),
        SeedDay('Legs 1', [
          SeedTemplateExercise('back-squat', 4, reps: '6-8'),
          SeedTemplateExercise('romanian-deadlift', 3, reps: '8-10'),
          SeedTemplateExercise('leg-press', 3, reps: '12-15'),
          SeedTemplateExercise('seated-leg-curl', 3, reps: '12-15'),
          SeedTemplateExercise('seated-calf-raise', 4, reps: '12-15'),
        ]),
        SeedDay('Push 2', [
          SeedTemplateExercise('incline-bench-press', 4, reps: '8-10'),
          SeedTemplateExercise('machine-chest-press', 3, reps: '10-12'),
          SeedTemplateExercise('arnold-press', 3, reps: '10-12'),
          SeedTemplateExercise('cable-crossover', 3, reps: '12-15'),
          SeedTemplateExercise('close-grip-bench-press', 3, reps: '8-10'),
          SeedTemplateExercise('triceps-kickback', 3, reps: '12-15'),
        ]),
        SeedDay('Pull 2', [
          SeedTemplateExercise('chest-supported-row', 4, reps: '8-10'),
          SeedTemplateExercise('lat-pulldown', 3, reps: '10-12'),
          SeedTemplateExercise('single-arm-dumbbell-row', 3, reps: '10-12'),
          SeedTemplateExercise('reverse-pec-deck', 3, reps: '15-20'),
          SeedTemplateExercise('shrug', 3, reps: '12-15'),
          SeedTemplateExercise('cable-curl', 3, reps: '12-15'),
        ]),
        SeedDay('Legs 2', [
          SeedTemplateExercise('front-squat', 3, reps: '8-10'),
          SeedTemplateExercise('hip-thrust', 3, reps: '8-10'),
          SeedTemplateExercise('bulgarian-split-squat', 3, reps: '10-12'),
          SeedTemplateExercise('leg-extension', 3, reps: '15-20'),
          SeedTemplateExercise('seated-leg-curl', 3, reps: '15-20'),
          SeedTemplateExercise('calf-raise', 4, reps: '15-20'),
        ]),
      ]),

  // ===== Strength classics =====
  SeedProgram(
      'sl-5x5',
      'StrongLifts 5×5 (3-day)',
      'Beginner 5×5 linear-progression strength program alternating workouts A and B, inspired by StrongLifts.',
      [
        SeedDay('Workout A', [
          SeedTemplateExercise('back-squat', 5, reps: '5'),
          SeedTemplateExercise('bench-press', 5, reps: '5'),
          SeedTemplateExercise('barbell-row', 5, reps: '5'),
        ]),
        SeedDay('Workout B', [
          SeedTemplateExercise('back-squat', 5, reps: '5'),
          SeedTemplateExercise('overhead-press', 5, reps: '5'),
          SeedTemplateExercise('deadlift', 1, reps: '5'),
        ]),
      ]),
  SeedProgram(
      'wendler-531-4',
      'Wendler 5/3/1 (4-day)',
      'Four-day strength template built on the main lifts with submaximal percentages, inspired by Jim Wendler 5/3/1.',
      [
        SeedDay('Overhead Press Day', [
          SeedTemplateExercise('overhead-press', 3, reps: '5/3/1'),
          SeedTemplateExercise('dumbbell-shoulder-press', 5, reps: '10'),
          SeedTemplateExercise('chin-up', 5, reps: '8-10'),
          SeedTemplateExercise('triceps-pushdown', 3, reps: '12-15'),
        ]),
        SeedDay('Deadlift Day', [
          SeedTemplateExercise('deadlift', 3, reps: '5/3/1'),
          SeedTemplateExercise('good-morning', 5, reps: '10'),
          SeedTemplateExercise('hanging-leg-raise', 5, reps: '12-15'),
          SeedTemplateExercise('leg-curl', 3, reps: '12-15'),
        ]),
        SeedDay('Bench Press Day', [
          SeedTemplateExercise('bench-press', 3, reps: '5/3/1'),
          SeedTemplateExercise('incline-dumbbell-press', 5, reps: '10'),
          SeedTemplateExercise('seated-cable-row', 5, reps: '10-12'),
          SeedTemplateExercise('dumbbell-curl', 3, reps: '12-15'),
        ]),
        SeedDay('Squat Day', [
          SeedTemplateExercise('back-squat', 3, reps: '5/3/1'),
          SeedTemplateExercise('leg-press', 5, reps: '10'),
          SeedTemplateExercise('leg-curl', 5, reps: '10-12'),
          SeedTemplateExercise('calf-raise', 4, reps: '12-15'),
        ]),
      ]),
  SeedProgram(
      'gzclp-3',
      'GZCLP (3-day)',
      'Linear-progression tier system (T1 main, T2 secondary, T3 accessory) inspired by Cody Lefever\'s GZCLP.',
      [
        SeedDay('Day 1', [
          SeedTemplateExercise('back-squat', 5, reps: '3+'),
          SeedTemplateExercise('bench-press', 3, reps: '10'),
          SeedTemplateExercise('lat-pulldown', 3, reps: '15'),
        ]),
        SeedDay('Day 2', [
          SeedTemplateExercise('overhead-press', 5, reps: '3+'),
          SeedTemplateExercise('deadlift', 3, reps: '10'),
          SeedTemplateExercise('seated-cable-row', 3, reps: '15'),
        ]),
        SeedDay('Day 3', [
          SeedTemplateExercise('bench-press', 5, reps: '3+'),
          SeedTemplateExercise('back-squat', 3, reps: '10'),
          SeedTemplateExercise('lat-pulldown', 3, reps: '15'),
        ]),
      ]),

  // ===== Hypertrophy splits =====
  SeedProgram(
      'phul-4',
      'PHUL — Power Hypertrophy Upper Lower (4-day)',
      'Four-day split pairing heavy power days with higher-rep hypertrophy days, inspired by the PHUL routine.',
      [
        SeedDay('Upper Power', [
          SeedTemplateExercise('bench-press', 4, reps: '3-5'),
          SeedTemplateExercise('barbell-row', 4, reps: '5-8'),
          SeedTemplateExercise('overhead-press', 3, reps: '5-8'),
          SeedTemplateExercise('pull-up', 3, reps: '6-10'),
          SeedTemplateExercise('close-grip-bench-press', 3, reps: '6-10'),
          SeedTemplateExercise('barbell-curl', 3, reps: '6-10'),
        ]),
        SeedDay('Lower Power', [
          SeedTemplateExercise('back-squat', 4, reps: '3-5'),
          SeedTemplateExercise('deadlift', 3, reps: '3-5'),
          SeedTemplateExercise('leg-press', 3, reps: '8-10'),
          SeedTemplateExercise('leg-curl', 3, reps: '8-10'),
          SeedTemplateExercise('calf-raise', 4, reps: '8-10'),
        ]),
        SeedDay('Upper Hypertrophy', [
          SeedTemplateExercise('incline-dumbbell-press', 4, reps: '10-12'),
          SeedTemplateExercise('seated-cable-row', 4, reps: '10-12'),
          SeedTemplateExercise('cable-crossover', 3, reps: '12-15'),
          SeedTemplateExercise('lateral-raise', 3, reps: '12-15'),
          SeedTemplateExercise('overhead-triceps-extension', 3, reps: '12-15'),
          SeedTemplateExercise('incline-dumbbell-curl', 3, reps: '12-15'),
        ]),
        SeedDay('Lower Hypertrophy', [
          SeedTemplateExercise('front-squat', 4, reps: '10-12'),
          SeedTemplateExercise('romanian-deadlift', 3, reps: '10-12'),
          SeedTemplateExercise('walking-lunge', 3, reps: '12-15'),
          SeedTemplateExercise('seated-leg-curl', 3, reps: '12-15'),
          SeedTemplateExercise('seated-calf-raise', 4, reps: '15-20'),
        ]),
      ]),
  SeedProgram(
      'phat-5',
      'PHAT — Power Hypertrophy Adaptive Training (5-day)',
      'Five-day power + hypertrophy hybrid inspired by Layne Norton\'s PHAT — two heavy days plus three body-part hypertrophy days.',
      [
        SeedDay('Upper Power', [
          SeedTemplateExercise('barbell-row', 4, reps: '3-5'),
          SeedTemplateExercise('bench-press', 4, reps: '3-5'),
          SeedTemplateExercise('overhead-press', 3, reps: '6-8'),
          SeedTemplateExercise('pull-up', 3, reps: '6-8'),
          SeedTemplateExercise('close-grip-bench-press', 3, reps: '6-10'),
          SeedTemplateExercise('barbell-curl', 3, reps: '6-10'),
        ]),
        SeedDay('Lower Power', [
          SeedTemplateExercise('back-squat', 4, reps: '3-5'),
          SeedTemplateExercise('deadlift', 3, reps: '3-5'),
          SeedTemplateExercise('leg-press', 3, reps: '8-10'),
          SeedTemplateExercise('leg-curl', 3, reps: '8-10'),
          SeedTemplateExercise('seated-calf-raise', 4, reps: '8-10'),
        ]),
        SeedDay('Back & Shoulders Hypertrophy', [
          SeedTemplateExercise('lat-pulldown', 4, reps: '10-12'),
          SeedTemplateExercise('seated-cable-row', 4, reps: '10-12'),
          SeedTemplateExercise('straight-arm-pulldown', 3, reps: '12-15'),
          SeedTemplateExercise('cable-lateral-raise', 4, reps: '12-15'),
          SeedTemplateExercise('reverse-pec-deck', 3, reps: '15-20'),
          SeedTemplateExercise('shrug', 3, reps: '12-15'),
        ]),
        SeedDay('Chest & Arms Hypertrophy', [
          SeedTemplateExercise('incline-dumbbell-press', 4, reps: '10-12'),
          SeedTemplateExercise('pec-deck', 3, reps: '12-15'),
          SeedTemplateExercise('cable-crossover', 3, reps: '12-15'),
          SeedTemplateExercise('overhead-cable-extension', 3, reps: '12-15'),
          SeedTemplateExercise('cable-curl', 3, reps: '12-15'),
          SeedTemplateExercise('hammer-curl', 3, reps: '12-15'),
        ]),
        SeedDay('Legs Hypertrophy', [
          SeedTemplateExercise('hack-squat', 4, reps: '10-12'),
          SeedTemplateExercise('romanian-deadlift', 3, reps: '10-12'),
          SeedTemplateExercise('leg-extension', 3, reps: '15-20'),
          SeedTemplateExercise('seated-leg-curl', 3, reps: '15-20'),
          SeedTemplateExercise('seated-calf-raise', 4, reps: '15-20'),
        ]),
      ]),
  SeedProgram(
      'arnold-6',
      'Arnold Split (6-day)',
      'High-frequency six-day chest/back, shoulders/arms, legs split inspired by Arnold Schwarzenegger\'s classic routine.',
      [
        SeedDay('Chest & Back A', [
          SeedTemplateExercise('bench-press', 4, reps: '6-8'),
          SeedTemplateExercise('incline-dumbbell-press', 3, reps: '8-10'),
          SeedTemplateExercise('barbell-row', 4, reps: '6-8'),
          SeedTemplateExercise('pull-up', 3, reps: '8-10'),
          SeedTemplateExercise('cable-crossover', 3, reps: '12-15'),
          SeedTemplateExercise('straight-arm-pulldown', 3, reps: '12-15'),
        ]),
        SeedDay('Shoulders & Arms A', [
          SeedTemplateExercise('overhead-press', 4, reps: '6-8'),
          SeedTemplateExercise('lateral-raise', 4, reps: '12-15'),
          SeedTemplateExercise('bent-over-reverse-fly', 3, reps: '15-20'),
          SeedTemplateExercise('barbell-curl', 3, reps: '8-10'),
          SeedTemplateExercise('skullcrusher', 3, reps: '10-12'),
          SeedTemplateExercise('preacher-curl', 3, reps: '12-15'),
        ]),
        SeedDay('Legs A', [
          SeedTemplateExercise('back-squat', 4, reps: '6-8'),
          SeedTemplateExercise('romanian-deadlift', 3, reps: '8-10'),
          SeedTemplateExercise('leg-press', 3, reps: '10-12'),
          SeedTemplateExercise('leg-curl', 3, reps: '12-15'),
          SeedTemplateExercise('seated-calf-raise', 4, reps: '15-20'),
        ]),
        SeedDay('Chest & Back B', [
          SeedTemplateExercise('incline-bench-press', 4, reps: '6-8'),
          SeedTemplateExercise('dumbbell-bench-press', 3, reps: '8-10'),
          SeedTemplateExercise('t-bar-row', 4, reps: '8-10'),
          SeedTemplateExercise('lat-pulldown', 3, reps: '10-12'),
          SeedTemplateExercise('pec-deck', 3, reps: '12-15'),
          SeedTemplateExercise('single-arm-dumbbell-row', 3, reps: '10-12'),
        ]),
        SeedDay('Shoulders & Arms B', [
          SeedTemplateExercise('arnold-press', 4, reps: '8-10'),
          SeedTemplateExercise('cable-lateral-raise', 4, reps: '12-15'),
          SeedTemplateExercise('face-pull', 3, reps: '15-20'),
          SeedTemplateExercise('hammer-curl', 3, reps: '10-12'),
          SeedTemplateExercise('overhead-triceps-extension', 3, reps: '10-12'),
          SeedTemplateExercise('concentration-curl', 3, reps: '12-15'),
        ]),
        SeedDay('Legs B', [
          SeedTemplateExercise('front-squat', 4, reps: '8-10'),
          SeedTemplateExercise('hip-thrust', 3, reps: '8-10'),
          SeedTemplateExercise('bulgarian-split-squat', 3, reps: '10-12'),
          SeedTemplateExercise('leg-extension', 3, reps: '15-20'),
          SeedTemplateExercise('seated-leg-curl', 3, reps: '15-20'),
          SeedTemplateExercise('calf-raise', 4, reps: '15-20'),
        ]),
      ]),
  SeedProgram(
      'bro-5',
      'Bro Split (5-day)',
      'Classic one-muscle-group-per-day bodybuilding split: chest, back, shoulders, legs, arms.',
      [
        SeedDay('Chest', [
          SeedTemplateExercise('bench-press', 4, reps: '6-8'),
          SeedTemplateExercise('incline-dumbbell-press', 3, reps: '8-10'),
          SeedTemplateExercise('machine-chest-press', 3, reps: '10-12'),
          SeedTemplateExercise('pec-deck', 3, reps: '12-15'),
          SeedTemplateExercise('cable-crossover', 3, reps: '12-15'),
        ]),
        SeedDay('Back', [
          SeedTemplateExercise('deadlift', 3, reps: '5'),
          SeedTemplateExercise('pull-up', 3, reps: '8-10'),
          SeedTemplateExercise('barbell-row', 3, reps: '8-10'),
          SeedTemplateExercise('lat-pulldown', 3, reps: '10-12'),
          SeedTemplateExercise('seated-cable-row', 3, reps: '10-12'),
          SeedTemplateExercise('shrug', 3, reps: '12-15'),
        ]),
        SeedDay('Shoulders', [
          SeedTemplateExercise('overhead-press', 4, reps: '6-8'),
          SeedTemplateExercise('arnold-press', 3, reps: '10-12'),
          SeedTemplateExercise('lateral-raise', 4, reps: '12-15'),
          SeedTemplateExercise('front-raise', 3, reps: '12-15'),
          SeedTemplateExercise('reverse-pec-deck', 3, reps: '15-20'),
        ]),
        SeedDay('Legs', [
          SeedTemplateExercise('back-squat', 4, reps: '6-8'),
          SeedTemplateExercise('leg-press', 3, reps: '10-12'),
          SeedTemplateExercise('romanian-deadlift', 3, reps: '8-10'),
          SeedTemplateExercise('leg-extension', 3, reps: '15-20'),
          SeedTemplateExercise('seated-leg-curl', 3, reps: '12-15'),
          SeedTemplateExercise('seated-calf-raise', 4, reps: '15-20'),
        ]),
        SeedDay('Arms', [
          SeedTemplateExercise('barbell-curl', 3, reps: '8-10'),
          SeedTemplateExercise('close-grip-bench-press', 3, reps: '8-10'),
          SeedTemplateExercise('incline-dumbbell-curl', 3, reps: '10-12'),
          SeedTemplateExercise('overhead-triceps-extension', 3, reps: '10-12'),
          SeedTemplateExercise('hammer-curl', 3, reps: '12-15'),
          SeedTemplateExercise('triceps-pushdown', 3, reps: '12-15'),
          SeedTemplateExercise('wrist-curl', 3, reps: '15-20'),
        ]),
      ]),

  // ===== Athlean-X style =====
  SeedProgram(
      'athlean-fb-3',
      'Athlean-X Style Full Body (3-day)',
      'Athletic, full-body training inspired by Athlean-X — compound lifts plus core and carries for total-body strength.',
      [
        SeedDay('Day 1', [
          SeedTemplateExercise('back-squat', 4, reps: '6-8'),
          SeedTemplateExercise('bench-press', 4, reps: '6-8'),
          SeedTemplateExercise('single-arm-dumbbell-row', 3, reps: '10-12'),
          SeedTemplateExercise('face-pull', 3, reps: '15-20'),
          SeedTemplateExercise('farmers-carry', 3, durationSec: 40),
          SeedTemplateExercise('ab-wheel-rollout', 3, reps: '8-12'),
        ]),
        SeedDay('Day 2', [
          SeedTemplateExercise('deadlift', 3, reps: '5'),
          SeedTemplateExercise('overhead-press', 4, reps: '6-8'),
          SeedTemplateExercise('pull-up', 4, reps: '6-10'),
          SeedTemplateExercise('bulgarian-split-squat', 3, reps: '10-12'),
          SeedTemplateExercise('hanging-leg-raise', 3, reps: '12-15'),
          SeedTemplateExercise('plank', 3, durationSec: 45),
        ]),
        SeedDay('Day 3', [
          SeedTemplateExercise('front-squat', 3, reps: '8-10'),
          SeedTemplateExercise('incline-dumbbell-press', 3, reps: '8-10'),
          SeedTemplateExercise('t-bar-row', 3, reps: '8-10'),
          SeedTemplateExercise('lateral-raise', 3, reps: '12-15'),
          SeedTemplateExercise('russian-twist', 3, reps: '20'),
          SeedTemplateExercise('dead-bug', 3, reps: '10'),
        ]),
      ]),
];

/// Legacy boolean flag: '1' meant all (then-existing) starter programs were
/// seeded. Migrated into [kSeededProgramKeysKey] on first run of the new logic.
const String kStarterTemplatesSeededKey = 'starter_templates_seeded';

/// Settings key holding the comma-separated set of [SeedProgram.key]s that have
/// already been seeded.
const String kSeededProgramKeysKey = 'seeded_program_keys';

/// Program keys that existed when the seeder used the legacy boolean flag — used
/// to migrate so they are not re-seeded for users who already had them.
const List<String> kLegacyStarterKeys = [
  'ppl-6',
  'upper-lower-4',
  'full-body-3',
];

/// Seed any [kStarterPrograms] whose key hasn't been seeded before, recording
/// each seeded key so a user's later deletions stick and newly-added programs
/// ship automatically on the next launch. For each program, creates its days
/// and maps each day's exercises onto a library exercise id by slug; unknown
/// slugs are skipped. Call AFTER [seedExercises] so the library ids exist.
Future<void> seedStarterPrograms(
  TrainingRepository repo,
  SettingsRepository settings,
) async {
  // Resolve the already-seeded key set, migrating the legacy boolean flag.
  final seeded = <String>{};
  final raw = await settings.get(kSeededProgramKeysKey);
  if (raw != null && raw.isNotEmpty) {
    seeded.addAll(raw.split(',').where((s) => s.isNotEmpty));
  } else if (await settings.get(kStarterTemplatesSeededKey) == '1') {
    seeded.addAll(kLegacyStarterKeys);
  }

  final pending =
      kStarterPrograms.where((p) => !seeded.contains(p.key)).toList();
  if (pending.isEmpty) {
    // Persist the migrated set even when there's nothing new to seed.
    await settings.set(kSeededProgramKeysKey, seeded.join(','));
    return;
  }

  final exercises = await repo.allExercises();
  final idBySlug = <String, int>{
    for (final e in exercises)
      if (e.slug != null) e.slug!: e.id,
  };

  // Append new programs after whatever the user already has.
  var position = (await repo.allPrograms()).length;

  for (final program in pending) {
    final programId = await repo.createProgram(
      name: program.name,
      notes: program.notes,
      position: position++,
    );
    for (var d = 0; d < program.days.length; d++) {
      final day = program.days[d];
      final dayId = await repo.createDay(
        programId: programId,
        name: day.name,
        position: d,
      );
      final companions = <TemplateExercisesCompanion>[];
      var pos = 0;
      for (final ex in day.exercises) {
        final exerciseId = idBySlug[ex.slug];
        if (exerciseId == null) continue; // slug not in library — skip safely
        companions.add(TemplateExercisesCompanion.insert(
          dayId: dayId,
          exerciseId: exerciseId,
          position: pos++,
          targetSets: Value(ex.sets),
          targetReps: Value(ex.reps),
          targetDurationSec: Value(ex.durationSec),
        ));
      }
      await repo.setDayExercises(dayId, companions);
    }
    seeded.add(program.key);
  }

  await settings.set(kSeededProgramKeysKey, seeded.join(','));
}
