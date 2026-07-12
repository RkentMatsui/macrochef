import 'package:drift/drift.dart' show Value;

import '../data/database.dart';
import '../data/repositories/training_repository.dart';

/// A built-in exercise definition. Lives in code (not the DB) so the catalog can
/// be re-seeded idempotently and used as a stable slug anchor for matching.
class SeedExercise {
  final String slug;
  final String name;
  final String category; // strength|cardio|class|mobility
  final String? primaryMuscle;
  final String? equipment;

  /// Short how-to / form cue shown on the exercise detail + picker.
  final String? description;
  final bool tracksWeight;
  final bool tracksReps;
  final bool tracksDuration;
  final bool tracksDistance;

  const SeedExercise({
    required this.slug,
    required this.name,
    required this.category,
    this.primaryMuscle,
    this.equipment,
    this.description,
    this.tracksWeight = false,
    this.tracksReps = false,
    this.tracksDuration = false,
    this.tracksDistance = false,
  });

  ExercisesCompanion toCompanion() => ExercisesCompanion.insert(
        slug: Value(slug),
        name: name,
        category: category,
        primaryMuscle: Value(primaryMuscle),
        secondaryMuscles: Value(secondaryMusclesFor(slug)),
        equipment: Value(equipment),
        description: Value(description),
        tracksWeight: Value(tracksWeight),
        tracksReps: Value(tracksReps),
        tracksDuration: Value(tracksDuration),
        tracksDistance: Value(tracksDistance),
        isCustom: const Value(false),
      );
}

/// Secondary (synergist/stabilizer) muscles per exercise slug, keyed to the
/// `Exercise.primaryMuscle` vocabulary. Credited 0.5 sets each in the weekly
/// hypertrophy heatmap (see `ProgressionService.kSecondarySetCredit`) so
/// indirect volume counts toward a muscle's weekly target. Isolation moves with
/// no meaningful synergist are omitted.
const Map<String, List<String>> kSecondaryMuscles = {
  // ---- Existing strength exercises ----
  'back-squat': ['glutes', 'hamstrings', 'core'],
  'front-squat': ['glutes', 'core'],
  'deadlift': ['glutes', 'back', 'forearms'],
  'romanian-deadlift': ['glutes', 'back'],
  'leg-press': ['glutes', 'hamstrings'],
  'walking-lunge': ['glutes', 'hamstrings'],
  'leg-curl': ['calves'],
  'hip-thrust': ['hamstrings', 'quads'],
  'bulgarian-split-squat': ['glutes', 'hamstrings', 'core'],
  'hack-squat': ['glutes'],
  'goblet-squat': ['glutes', 'core'],
  'seated-leg-curl': ['calves'],
  'good-morning': ['glutes', 'back'],
  'nordic-curl': ['glutes', 'calves'],
  'cable-kickback': ['hamstrings'],
  'glute-bridge': ['hamstrings'],
  'bench-press': ['triceps', 'shoulders'],
  'incline-bench-press': ['shoulders', 'triceps'],
  'dumbbell-bench-press': ['triceps', 'shoulders'],
  'push-up': ['triceps', 'shoulders', 'core'],
  'incline-dumbbell-press': ['shoulders', 'triceps'],
  'cable-fly': ['shoulders'],
  'machine-chest-press': ['triceps', 'shoulders'],
  'decline-bench-press': ['triceps', 'shoulders'],
  'pec-deck': ['shoulders'],
  'cable-crossover': ['shoulders'],
  'overhead-press': ['triceps', 'core'],
  'dumbbell-shoulder-press': ['triceps'],
  'arnold-press': ['triceps'],
  'upright-row': ['back', 'biceps'],
  'reverse-pec-deck': ['back'],
  'bent-over-reverse-fly': ['back'],
  'dips': ['chest', 'shoulders'],
  'close-grip-bench-press': ['chest', 'shoulders'],
  'barbell-curl': ['forearms'],
  'dumbbell-curl': ['forearms'],
  'hammer-curl': ['forearms'],
  'preacher-curl': ['forearms'],
  'incline-dumbbell-curl': ['forearms'],
  'cable-curl': ['forearms'],
  'concentration-curl': ['forearms'],
  'pull-up': ['biceps', 'rear-delts'],
  'lat-pulldown': ['biceps', 'rear-delts'],
  'barbell-row': ['biceps', 'rear-delts', 'forearms'],
  'seated-cable-row': ['biceps', 'rear-delts'],
  't-bar-row': ['biceps', 'rear-delts'],
  'pendlay-row': ['biceps', 'rear-delts'],
  'chin-up': ['biceps', 'forearms'],
  'chest-supported-row': ['biceps', 'rear-delts'],
  'straight-arm-pulldown': ['triceps'],
  'shrug': ['forearms'],
  'single-arm-dumbbell-row': ['biceps', 'rear-delts'],
  'face-pull': ['back'],
  'hanging-leg-raise': ['forearms'],
  'hanging-knee-raise': ['forearms'],
  'ab-wheel-rollout': ['shoulders'],
  'reverse-curl': ['biceps'],
  'farmers-carry': ['core', 'back'],
  // ---- New exercises ----
  'power-clean': ['glutes', 'back', 'shoulders'],
  'push-press': ['triceps', 'quads', 'core'],
  'clean-and-press': ['triceps', 'glutes', 'back'],
  'thruster': ['shoulders', 'glutes', 'core'],
  'kettlebell-swing': ['hamstrings', 'back', 'core'],
  'power-snatch': ['back', 'glutes', 'shoulders'],
  'snatch-grip-deadlift': ['glutes', 'back', 'forearms'],
  'hang-clean': ['glutes', 'back', 'shoulders'],
  'sumo-deadlift': ['glutes', 'quads', 'forearms'],
  'trap-bar-deadlift': ['glutes', 'hamstrings', 'forearms'],
  'rack-pull': ['glutes', 'hamstrings', 'forearms'],
  'deficit-deadlift': ['glutes', 'back', 'forearms'],
  'box-squat': ['glutes', 'hamstrings', 'core'],
  'pause-squat': ['glutes', 'hamstrings', 'core'],
  'pistol-squat': ['glutes', 'core'],
  'step-up': ['glutes', 'hamstrings'],
  'smith-machine-squat': ['glutes', 'core'],
  'belt-squat': ['glutes'],
  'single-leg-rdl': ['glutes', 'back', 'core'],
  'pendulum-squat': ['glutes'],
  'dumbbell-pullover': ['back', 'triceps'],
  'jm-press': ['chest', 'shoulders'],
  'spider-curl': ['forearms'],
  'zottman-curl': ['forearms'],
  'drag-curl': ['forearms'],
  'seal-row': ['biceps', 'rear-delts'],
  'meadows-row': ['biceps', 'rear-delts', 'forearms'],
  'kroc-row': ['biceps', 'rear-delts', 'forearms'],
  'inverted-row': ['biceps', 'rear-delts', 'core'],
  'cable-rear-delt-fly': ['back'],
  'y-raise': ['back'],
  'back-extension': ['glutes'],
  'reverse-hyper': ['hamstrings'],
  'sit-up': ['quads'],
  'toes-to-bar': ['forearms', 'back'],
  'mountain-climber': ['shoulders', 'quads'],
  'cable-woodchopper': ['shoulders'],
  'bird-dog': ['glutes', 'shoulders'],
  'glute-kickback-machine': ['hamstrings'],
  // ---- Adductor/abductor compounds ----
  'sumo-squat': ['glutes', 'quads', 'core'],
  'banded-lateral-walk': ['glutes'],
  'copenhagen-plank': ['core'],
};

/// Comma-separated secondary muscles for a slug (for the DB column), or null
/// when the exercise has none.
String? secondaryMusclesFor(String slug) {
  final list = kSecondaryMuscles[slug];
  return (list == null || list.isEmpty) ? null : list.join(',');
}

/// ~144 common movements across strength / cardio / class / mobility with
/// correct capability flags. Slugs are stable keys for idempotent re-seeding.
const List<SeedExercise> kBuiltInExercises = [
  // ---- Strength: legs ----
  SeedExercise(
      slug: 'back-squat',
      name: 'Back Squat',
      category: 'strength',
      primaryMuscle: 'quads',
      equipment: 'barbell',
      description:
          'Rest the bar across your upper back, brace your core, and squat to at least parallel keeping knees tracking over your toes, then drive up through mid-foot.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'front-squat',
      name: 'Front Squat',
      category: 'strength',
      primaryMuscle: 'quads',
      equipment: 'barbell',
      description:
          'Hold the bar across your front delts with elbows high, keep your torso upright, and squat down then stand tall without letting the elbows drop.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'deadlift',
      name: 'Deadlift',
      category: 'strength',
      primaryMuscle: 'hamstrings',
      equipment: 'barbell',
      description:
          'With a flat back and the bar over mid-foot, hinge and grip, then drive the floor away and stand tall by squeezing glutes; control the bar back down.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'romanian-deadlift',
      name: 'Romanian Deadlift',
      category: 'strength',
      primaryMuscle: 'hamstrings',
      equipment: 'barbell',
      description:
          'Keeping legs nearly straight and the bar close to your shins, push your hips back until you feel a deep hamstring stretch, then drive hips forward to stand.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'leg-press',
      name: 'Leg Press',
      category: 'strength',
      primaryMuscle: 'quads',
      equipment: 'machine',
      description:
          'Place feet shoulder-width on the platform, lower until knees reach about 90 degrees, then press back up without locking the knees hard.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'walking-lunge',
      name: 'Walking Lunge',
      category: 'strength',
      primaryMuscle: 'quads',
      equipment: 'dumbbell',
      description:
          'Step forward and lower until both knees are about 90 degrees, then push off the front foot to step the back leg through into the next lunge.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'leg-curl',
      name: 'Leg Curl',
      category: 'strength',
      primaryMuscle: 'hamstrings',
      equipment: 'machine',
      description:
          'Set the pad above your heels and curl your legs toward your glutes by contracting the hamstrings, then lower under control.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'leg-extension',
      name: 'Leg Extension',
      category: 'strength',
      primaryMuscle: 'quads',
      equipment: 'machine',
      description:
          'With the pad on your lower shins, straighten your knees to lift the weight and squeeze the quads at the top, then lower slowly.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'calf-raise',
      name: 'Calf Raise',
      category: 'strength',
      primaryMuscle: 'calves',
      equipment: 'machine',
      description:
          'Press through the balls of your feet to rise as high as possible, pause at the top, then lower your heels for a full stretch.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'hip-thrust',
      name: 'Hip Thrust',
      category: 'strength',
      primaryMuscle: 'glutes',
      equipment: 'barbell',
      description:
          'With upper back on a bench and the bar over your hips, drive through your heels to lift until your torso is parallel to the floor, squeezing glutes hard.',
      tracksWeight: true,
      tracksReps: true),

  // ---- Strength: push ----
  SeedExercise(
      slug: 'bench-press',
      name: 'Bench Press',
      category: 'strength',
      primaryMuscle: 'chest',
      equipment: 'barbell',
      description:
          'Lie flat, grip just outside shoulder-width, lower the bar to mid-chest with elbows tucked slightly, then press up to lockout.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'incline-bench-press',
      name: 'Incline Bench Press',
      category: 'strength',
      primaryMuscle: 'chest',
      equipment: 'barbell',
      description:
          'On a 30-45 degree bench, lower the bar to your upper chest and press up to emphasise the clavicular (upper) chest.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'dumbbell-bench-press',
      name: 'Dumbbell Bench Press',
      category: 'strength',
      primaryMuscle: 'chest',
      equipment: 'dumbbell',
      description:
          'Press two dumbbells from chest level to over your shoulders, allowing a deeper stretch at the bottom than a barbell, then control them down.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'overhead-press',
      name: 'Overhead Press',
      category: 'strength',
      primaryMuscle: 'shoulders',
      equipment: 'barbell',
      description:
          'From racked at shoulder height, brace your core and press the bar straight overhead to lockout, then lower under control.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'dumbbell-shoulder-press',
      name: 'Dumbbell Shoulder Press',
      category: 'strength',
      primaryMuscle: 'shoulders',
      equipment: 'dumbbell',
      description:
          'Press two dumbbells from shoulder height to overhead, keeping your core tight and ribs down, then lower to ear level.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'lateral-raise',
      name: 'Lateral Raise',
      category: 'strength',
      primaryMuscle: 'shoulders',
      equipment: 'dumbbell',
      description:
          'With a slight bend in the elbows, raise the dumbbells out to your sides to shoulder height leading with the elbows, then lower slowly.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'triceps-pushdown',
      name: 'Triceps Pushdown',
      category: 'strength',
      primaryMuscle: 'triceps',
      equipment: 'cable',
      description:
          'Keeping elbows pinned to your sides, push the bar or rope down until arms are fully straight, squeeze the triceps, then return under control.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'dips',
      name: 'Dips',
      category: 'strength',
      primaryMuscle: 'triceps',
      equipment: 'bodyweight',
      description:
          'On parallel bars, lower until your elbows reach about 90 degrees, then press back up; lean forward to bias chest, stay upright to bias triceps.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'push-up',
      name: 'Push-up',
      category: 'strength',
      primaryMuscle: 'chest',
      equipment: 'bodyweight',
      description:
          'Keep a straight line from head to heels, lower your chest to just above the floor with elbows at about 45 degrees, then press back up.',
      tracksReps: true),

  // ---- Strength: pull ----
  SeedExercise(
      slug: 'pull-up',
      name: 'Pull-up',
      category: 'strength',
      primaryMuscle: 'back',
      equipment: 'bodyweight',
      description:
          'Hang with an overhand grip, pull your chest toward the bar by driving your elbows down, then lower under control to a full hang.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'lat-pulldown',
      name: 'Lat Pulldown',
      category: 'strength',
      primaryMuscle: 'back',
      equipment: 'cable',
      description:
          'Pull the bar to your upper chest by driving your elbows down and back, squeeze the lats, then let the bar rise under control.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'barbell-row',
      name: 'Barbell Row',
      category: 'strength',
      primaryMuscle: 'back',
      equipment: 'barbell',
      description:
          'Hinge to about 45 degrees with a flat back and row the bar to your lower ribs, squeezing your shoulder blades, then lower under control.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'seated-cable-row',
      name: 'Seated Cable Row',
      category: 'strength',
      primaryMuscle: 'back',
      equipment: 'cable',
      description:
          'Sit tall with a slight forward lean, pull the handle to your stomach by driving elbows back and squeezing your back, then extend under control.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'face-pull',
      name: 'Face Pull',
      category: 'strength',
      primaryMuscle: 'rear-delts',
      equipment: 'cable',
      description:
          'Set the cable at head height and pull the rope toward your face, flaring your elbows out and rotating hands back to hit the rear delts.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'barbell-curl',
      name: 'Barbell Curl',
      category: 'strength',
      primaryMuscle: 'biceps',
      equipment: 'barbell',
      description:
          'Keep elbows at your sides and curl the bar up by contracting the biceps without swinging, then lower slowly to full extension.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'dumbbell-curl',
      name: 'Dumbbell Curl',
      category: 'strength',
      primaryMuscle: 'biceps',
      equipment: 'dumbbell',
      description:
          'Curl the dumbbells up while keeping your elbows pinned, supinating the wrists at the top, then lower under control.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'hammer-curl',
      name: 'Hammer Curl',
      category: 'strength',
      primaryMuscle: 'biceps',
      equipment: 'dumbbell',
      description:
          'Curl the dumbbells with a neutral (palms-facing) grip to target the brachialis and forearms, then lower slowly.',
      tracksWeight: true,
      tracksReps: true),

  // ---- Strength: accessories (used by starter templates) ----
  SeedExercise(
      slug: 'incline-dumbbell-press',
      name: 'Incline Dumbbell Press',
      category: 'strength',
      primaryMuscle: 'chest',
      equipment: 'dumbbell',
      description:
          'On an inclined bench, press two dumbbells from upper-chest level to overhead, then lower for a deep stretch on the upper chest.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'cable-fly',
      name: 'Cable Fly',
      category: 'strength',
      primaryMuscle: 'chest',
      equipment: 'cable',
      description:
          'With a slight elbow bend, bring the handles together in front of your chest in a hugging arc, squeeze, then open back up under control.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'bulgarian-split-squat',
      name: 'Bulgarian Split Squat',
      category: 'strength',
      primaryMuscle: 'quads',
      equipment: 'dumbbell',
      description:
          'With your rear foot elevated on a bench, lower straight down until the front thigh is parallel, then drive up through the front heel.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'skullcrusher',
      name: 'Skullcrusher',
      category: 'strength',
      primaryMuscle: 'triceps',
      equipment: 'barbell',
      description:
          'Lying down with arms vertical, bend at the elbows to lower the bar toward your forehead, then extend back up using only the triceps.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'preacher-curl',
      name: 'Preacher Curl',
      category: 'strength',
      primaryMuscle: 'biceps',
      equipment: 'barbell',
      description:
          'With upper arms on the preacher pad, curl the bar up, then lower slowly to a near-full stretch without bouncing at the bottom.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'cable-crunch',
      name: 'Cable Crunch',
      category: 'strength',
      primaryMuscle: 'core',
      equipment: 'cable',
      description:
          'Kneel holding a rope behind your head and crunch down by flexing your spine, contracting the abs, then return under control.',
      tracksWeight: true,
      tracksReps: true),

  // ---- Cardio ----
  SeedExercise(
      slug: 'running',
      name: 'Running',
      category: 'cardio',
      equipment: 'bodyweight',
      description:
          'Run at a steady or interval pace, landing under your hips with a relaxed upright posture and a consistent breathing rhythm.',
      tracksDuration: true,
      tracksDistance: true),
  SeedExercise(
      slug: 'treadmill',
      name: 'Treadmill',
      category: 'cardio',
      equipment: 'machine',
      description:
          'Run or walk at a set speed and incline; keep an upright posture and avoid gripping the handrails so your effort matches the pace.',
      tracksDuration: true,
      tracksDistance: true),
  SeedExercise(
      slug: 'cycling',
      name: 'Cycling',
      category: 'cardio',
      equipment: 'bodyweight',
      description:
          'Pedal at a steady cadence with a slight knee bend at the bottom of each stroke; adjust resistance or terrain to control effort.',
      tracksDuration: true,
      tracksDistance: true),
  SeedExercise(
      slug: 'stationary-bike',
      name: 'Stationary Bike',
      category: 'cardio',
      equipment: 'machine',
      description:
          'Set the seat so your knee is slightly bent at the bottom, then pedal at a steady cadence, raising resistance to increase intensity.',
      tracksDuration: true,
      tracksDistance: true),
  SeedExercise(
      slug: 'rowing-machine',
      name: 'Rowing Machine',
      category: 'cardio',
      equipment: 'machine',
      description:
          'Drive with your legs first, then lean back and pull the handle to your ribs; reverse the order on the recovery and keep a smooth rhythm.',
      tracksDuration: true,
      tracksDistance: true),
  SeedExercise(
      slug: 'elliptical',
      name: 'Elliptical',
      category: 'cardio',
      equipment: 'machine',
      description:
          'Stride smoothly while pushing and pulling the handles, keeping an upright torso; raise resistance or incline to increase effort.',
      tracksDuration: true,
      tracksDistance: true),
  SeedExercise(
      slug: 'swimming',
      name: 'Swimming',
      category: 'cardio',
      description:
          'Swim continuous laps with controlled breathing; keep a streamlined body position and a steady stroke rhythm throughout.',
      tracksDuration: true,
      tracksDistance: true),
  SeedExercise(
      slug: 'jump-rope',
      name: 'Jump Rope',
      category: 'cardio',
      description:
          'Turn the rope with your wrists and bounce on the balls of your feet just high enough to clear it, keeping a relaxed steady rhythm.',
      tracksDuration: true),
  SeedExercise(
      slug: 'stair-climber',
      name: 'Stair Climber',
      category: 'cardio',
      equipment: 'machine',
      description:
          'Step up at a steady pace standing tall without leaning on the rails, driving through your whole foot on each step.',
      tracksDuration: true),

  // ---- Class / sports ----
  SeedExercise(
      slug: 'yoga',
      name: 'Yoga',
      category: 'class',
      description:
          'Flow through poses linking breath to movement, holding each position with control to build mobility, balance, and stability.',
      tracksDuration: true),
  SeedExercise(
      slug: 'pilates',
      name: 'Pilates',
      category: 'class',
      description:
          'Perform controlled, low-impact movements emphasising core engagement, alignment, and steady breathing throughout each exercise.',
      tracksDuration: true),
  SeedExercise(
      slug: 'spin-class',
      name: 'Spin Class',
      category: 'class',
      description:
          'Follow the instructor through seated and standing intervals on a stationary bike, adjusting resistance to match the cued effort.',
      tracksDuration: true),
  SeedExercise(
      slug: 'hiit-class',
      name: 'HIIT Class',
      category: 'class',
      description:
          'Alternate short bursts of near-maximal effort with brief recoveries across a circuit of full-body movements.',
      tracksDuration: true),
  SeedExercise(
      slug: 'boxing',
      name: 'Boxing',
      category: 'class',
      description:
          'Throw combinations on pads or a bag with proper guard and footwork, rotating through the hips for power while staying light on your feet.',
      tracksDuration: true),

  // ---- Mobility / core ----
  SeedExercise(
      slug: 'plank',
      name: 'Plank',
      category: 'mobility',
      primaryMuscle: 'core',
      equipment: 'bodyweight',
      description:
          'Hold a straight line from head to heels on your forearms, bracing the core and squeezing the glutes without letting the hips sag.',
      tracksDuration: true),
  SeedExercise(
      slug: 'stretching',
      name: 'Stretching',
      category: 'mobility',
      description:
          'Ease into each stretch to a mild tension and hold steadily while breathing slowly, never bouncing or forcing the range.',
      tracksDuration: true),
  SeedExercise(
      slug: 'foam-rolling',
      name: 'Foam Rolling',
      category: 'mobility',
      description:
          'Roll slowly over a muscle group, pausing on tender spots for a few breaths to release tension before moving on.',
      tracksDuration: true),
  SeedExercise(
      slug: 'hanging-leg-raise',
      name: 'Hanging Leg Raise',
      category: 'mobility',
      primaryMuscle: 'core',
      equipment: 'bodyweight',
      description:
          'Hang from a bar and raise your legs by curling your pelvis up, controlling the descent without swinging.',
      tracksReps: true),

  // ---- Forearms ----
  SeedExercise(
      slug: 'wrist-curl',
      name: 'Wrist Curl',
      category: 'strength',
      primaryMuscle: 'forearms',
      equipment: 'dumbbell',
      description:
          'Rest your forearms on a bench with palms up, let the weight roll to your fingertips, then curl your wrists up to contract the forearm flexors.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'reverse-wrist-curl',
      name: 'Reverse Wrist Curl',
      category: 'strength',
      primaryMuscle: 'forearms',
      equipment: 'dumbbell',
      description:
          'With forearms on a bench and palms down, raise the back of your hands toward the ceiling to work the forearm extensors, then lower slowly.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'reverse-curl',
      name: 'Reverse Curl',
      category: 'strength',
      primaryMuscle: 'forearms',
      equipment: 'barbell',
      description:
          'Hold the bar with an overhand grip and curl it up keeping elbows pinned, emphasising the brachioradialis and forearm extensors.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'farmers-carry',
      name: "Farmer's Carry",
      category: 'strength',
      primaryMuscle: 'forearms',
      equipment: 'dumbbell',
      description:
          'Hold a heavy weight in each hand and walk with tall posture and a tight grip, keeping shoulders back for the set distance or time.',
      tracksWeight: true,
      tracksDuration: true),
  SeedExercise(
      slug: 'wrist-roller',
      name: 'Wrist Roller',
      category: 'strength',
      primaryMuscle: 'forearms',
      equipment: 'other',
      description:
          'Hold the roller at arm height and wind the weighted cord up by alternating wrist flexion of each hand, then slowly unwind it.',
      tracksWeight: true,
      tracksReps: true),

  // ---- Triceps ----
  SeedExercise(
      slug: 'overhead-triceps-extension',
      name: 'Overhead Triceps Extension',
      category: 'strength',
      primaryMuscle: 'triceps',
      equipment: 'dumbbell',
      description:
          'Hold a dumbbell overhead with both hands, keep elbows pointing forward, lower behind your head for a stretch, then extend back up.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'overhead-cable-extension',
      name: 'Overhead Cable Extension',
      category: 'strength',
      primaryMuscle: 'triceps',
      equipment: 'cable',
      description:
          'Facing away from a low pulley with a rope overhead, extend your arms forward and up keeping elbows high, then return under control.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'close-grip-bench-press',
      name: 'Close-Grip Bench Press',
      category: 'strength',
      primaryMuscle: 'triceps',
      equipment: 'barbell',
      description:
          'Bench with hands about shoulder-width and elbows tucked, lower to the lower chest and press up to bias the triceps.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'triceps-kickback',
      name: 'Triceps Kickback',
      category: 'strength',
      primaryMuscle: 'triceps',
      equipment: 'dumbbell',
      description:
          'Hinge forward with your upper arm parallel to the floor, then straighten your elbow to extend the dumbbell back and squeeze the triceps.',
      tracksWeight: true,
      tracksReps: true),

  // ---- Shoulders ----
  SeedExercise(
      slug: 'arnold-press',
      name: 'Arnold Press',
      category: 'strength',
      primaryMuscle: 'shoulders',
      equipment: 'dumbbell',
      description:
          'Start with palms facing you, rotate the dumbbells out as you press overhead, then reverse the rotation on the way down.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'cable-lateral-raise',
      name: 'Cable Lateral Raise',
      category: 'strength',
      primaryMuscle: 'shoulders',
      equipment: 'cable',
      description:
          'Stand side-on to a low pulley and raise the handle out to shoulder height with a slight elbow bend for constant tension on the side delt.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'upright-row',
      name: 'Upright Row',
      category: 'strength',
      primaryMuscle: 'shoulders',
      equipment: 'barbell',
      description:
          'Pull the bar up the front of your body leading with the elbows to about chest height, then lower under control.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'front-raise',
      name: 'Front Raise',
      category: 'strength',
      primaryMuscle: 'shoulders',
      equipment: 'dumbbell',
      description:
          'With a slight elbow bend, raise the dumbbells straight in front of you to shoulder height, then lower slowly to target the front delts.',
      tracksWeight: true,
      tracksReps: true),

  // ---- Rear delts ----
  SeedExercise(
      slug: 'reverse-pec-deck',
      name: 'Reverse Pec Deck',
      category: 'strength',
      primaryMuscle: 'rear-delts',
      equipment: 'machine',
      description:
          'Facing the pad, push the handles back and out in a wide arc by squeezing your rear delts and shoulder blades, then return under control.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'bent-over-reverse-fly',
      name: 'Bent-Over Reverse Fly',
      category: 'strength',
      primaryMuscle: 'rear-delts',
      equipment: 'dumbbell',
      description:
          'Hinge forward with a flat back and raise the dumbbells out to your sides leading with the elbows, squeezing the rear delts at the top.',
      tracksWeight: true,
      tracksReps: true),

  // ---- Back ----
  SeedExercise(
      slug: 't-bar-row',
      name: 'T-Bar Row',
      category: 'strength',
      primaryMuscle: 'back',
      equipment: 'barbell',
      description:
          'Straddle the bar, hinge with a flat back, and row the handles to your torso by driving the elbows back, then lower under control.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'pendlay-row',
      name: 'Pendlay Row',
      category: 'strength',
      primaryMuscle: 'back',
      equipment: 'barbell',
      description:
          'From a flat-back position parallel to the floor, explosively row the bar from the floor to your lower chest, then return it to the floor each rep.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'chin-up',
      name: 'Chin-up',
      category: 'strength',
      primaryMuscle: 'back',
      equipment: 'bodyweight',
      description:
          'Hang with an underhand shoulder-width grip and pull your chest to the bar, then lower under control; biases the biceps more than a pull-up.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'chest-supported-row',
      name: 'Chest-Supported Row',
      category: 'strength',
      primaryMuscle: 'back',
      equipment: 'dumbbell',
      description:
          'Lie chest-down on an incline bench and row the dumbbells to your sides, squeezing your shoulder blades without using momentum.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'straight-arm-pulldown',
      name: 'Straight-Arm Pulldown',
      category: 'strength',
      primaryMuscle: 'back',
      equipment: 'cable',
      description:
          'With arms nearly straight, pull the bar from overhead down to your thighs in an arc, focusing on the lats, then return under control.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'shrug',
      name: 'Shrug',
      category: 'strength',
      primaryMuscle: 'back',
      equipment: 'dumbbell',
      description:
          'Hold the weights at your sides and lift your shoulders straight up toward your ears, squeeze the traps, then lower slowly.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'single-arm-dumbbell-row',
      name: 'Single-Arm Dumbbell Row',
      category: 'strength',
      primaryMuscle: 'back',
      equipment: 'dumbbell',
      description:
          'Brace one hand and knee on a bench, row the dumbbell to your hip by driving the elbow back, then lower for a full stretch.',
      tracksWeight: true,
      tracksReps: true),

  // ---- Chest ----
  SeedExercise(
      slug: 'machine-chest-press',
      name: 'Machine Chest Press',
      category: 'strength',
      primaryMuscle: 'chest',
      equipment: 'machine',
      description:
          'Set the seat so the handles align with mid-chest, press out until arms are nearly straight, then return under control.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'decline-bench-press',
      name: 'Decline Bench Press',
      category: 'strength',
      primaryMuscle: 'chest',
      equipment: 'barbell',
      description:
          'On a declined bench, lower the bar to your lower chest and press up to emphasise the lower pecs.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'pec-deck',
      name: 'Pec Deck',
      category: 'strength',
      primaryMuscle: 'chest',
      equipment: 'machine',
      description:
          'With elbows on the pads, bring the arms together in front of your chest, squeeze the pecs, then open slowly for a stretch.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'cable-crossover',
      name: 'Cable Crossover',
      category: 'strength',
      primaryMuscle: 'chest',
      equipment: 'cable',
      description:
          'From high pulleys, sweep the handles down and together in front of you, crossing slightly, then control them back out.',
      tracksWeight: true,
      tracksReps: true),

  // ---- Biceps ----
  SeedExercise(
      slug: 'incline-dumbbell-curl',
      name: 'Incline Dumbbell Curl',
      category: 'strength',
      primaryMuscle: 'biceps',
      equipment: 'dumbbell',
      description:
          'Sit back on an incline bench and let your arms hang behind you, then curl the dumbbells up for a strong stretch on the long head of the biceps.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'cable-curl',
      name: 'Cable Curl',
      category: 'strength',
      primaryMuscle: 'biceps',
      equipment: 'cable',
      description:
          'Curl the bar or handle up with elbows pinned for constant cable tension, squeeze at the top, then lower under control.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'concentration-curl',
      name: 'Concentration Curl',
      category: 'strength',
      primaryMuscle: 'biceps',
      equipment: 'dumbbell',
      description:
          'Seated with your elbow braced against your inner thigh, curl the dumbbell up with a peak squeeze, then lower slowly.',
      tracksWeight: true,
      tracksReps: true),

  // ---- Quads ----
  SeedExercise(
      slug: 'hack-squat',
      name: 'Hack Squat',
      category: 'strength',
      primaryMuscle: 'quads',
      equipment: 'machine',
      description:
          'With your back against the pad and feet on the platform, lower until knees are about 90 degrees, then press up to bias the quads.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'goblet-squat',
      name: 'Goblet Squat',
      category: 'strength',
      primaryMuscle: 'quads',
      equipment: 'dumbbell',
      description:
          'Hold a dumbbell or kettlebell at your chest and squat down between your knees keeping your torso upright, then drive up.',
      tracksWeight: true,
      tracksReps: true),

  // ---- Hamstrings ----
  SeedExercise(
      slug: 'seated-leg-curl',
      name: 'Seated Leg Curl',
      category: 'strength',
      primaryMuscle: 'hamstrings',
      equipment: 'machine',
      description:
          'Seated with the pad on your lower legs, curl your heels down and under by contracting the hamstrings, then return under control.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'good-morning',
      name: 'Good Morning',
      category: 'strength',
      primaryMuscle: 'hamstrings',
      equipment: 'barbell',
      description:
          'With the bar on your back and knees soft, hinge at the hips with a flat back until you feel a hamstring stretch, then drive hips forward to stand.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'nordic-curl',
      name: 'Nordic Curl',
      category: 'strength',
      primaryMuscle: 'hamstrings',
      equipment: 'bodyweight',
      description:
          'Kneel with your ankles anchored and lower your torso forward as slowly as possible using the hamstrings, then pull back up or push off lightly.',
      tracksWeight: true,
      tracksReps: true),

  // ---- Glutes ----
  SeedExercise(
      slug: 'cable-kickback',
      name: 'Cable Kickback',
      category: 'strength',
      primaryMuscle: 'glutes',
      equipment: 'cable',
      description:
          'With an ankle strap on a low pulley, kick one leg straight back and up by squeezing the glute, then return under control.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'glute-bridge',
      name: 'Glute Bridge',
      category: 'strength',
      primaryMuscle: 'glutes',
      equipment: 'bodyweight',
      description:
          'Lie on your back with knees bent, drive through your heels to lift your hips until your body forms a straight line, squeezing the glutes at the top.',
      tracksWeight: true,
      tracksReps: true),

  // ---- Calves ----
  SeedExercise(
      slug: 'seated-calf-raise',
      name: 'Seated Calf Raise',
      category: 'strength',
      primaryMuscle: 'calves',
      equipment: 'machine',
      description:
          'With the pad on your knees and balls of feet on the platform, press up onto your toes, pause, then lower your heels for a full stretch.',
      tracksWeight: true,
      tracksReps: true),

  // ---- Core ----
  SeedExercise(
      slug: 'hanging-knee-raise',
      name: 'Hanging Knee Raise',
      category: 'strength',
      primaryMuscle: 'core',
      equipment: 'bodyweight',
      description:
          'Hang from a bar and raise your knees toward your chest by curling your pelvis up, then lower under control without swinging.',
      tracksReps: true),
  SeedExercise(
      slug: 'russian-twist',
      name: 'Russian Twist',
      category: 'strength',
      primaryMuscle: 'core',
      equipment: 'bodyweight',
      description:
          'Sit leaning back with feet up, then rotate your torso side to side, touching the floor or weight beside each hip to work the obliques.',
      tracksReps: true),
  SeedExercise(
      slug: 'ab-wheel-rollout',
      name: 'Ab Wheel Rollout',
      category: 'strength',
      primaryMuscle: 'core',
      equipment: 'bodyweight',
      description:
          'From your knees, roll the wheel forward keeping a braced, neutral spine, extend as far as you can control, then pull back in with your abs.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'dead-bug',
      name: 'Dead Bug',
      category: 'strength',
      primaryMuscle: 'core',
      equipment: 'bodyweight',
      description:
          'Lie on your back with arms and knees up, then lower an opposite arm and leg while keeping your lower back pressed to the floor, and alternate.',
      tracksReps: true),

  // ---- Olympic / power lifts ----
  SeedExercise(
      slug: 'power-clean',
      name: 'Power Clean',
      category: 'strength',
      primaryMuscle: 'hamstrings',
      equipment: 'barbell',
      description:
          'Explosively extend the hips to pull the bar from the floor and catch '
          'it on the front of the shoulders in a quarter-squat. Keep the bar '
          'close to the body and finish tall before racking.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'push-press',
      name: 'Push Press',
      category: 'strength',
      primaryMuscle: 'shoulders',
      equipment: 'barbell',
      description:
          'Dip slightly at the knees, then drive the bar overhead using leg '
          'drive to start the press. Lock out with the bar over the mid-foot '
          'and head through the window.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'clean-and-press',
      name: 'Clean and Press',
      category: 'strength',
      primaryMuscle: 'shoulders',
      equipment: 'barbell',
      description:
          'Pull the bar from the floor to the shoulders, then press it overhead '
          'to lockout. Reset the torso tall before each press and keep the core '
          'braced throughout.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'thruster',
      name: 'Thruster',
      category: 'strength',
      primaryMuscle: 'quads',
      equipment: 'barbell',
      description:
          'From a front-rack squat, drive out of the bottom and ride the '
          'momentum into an overhead press in one fluid motion. Keep elbows up '
          'in the squat and finish with the bar locked over the heels.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'kettlebell-swing',
      name: 'Kettlebell Swing',
      category: 'strength',
      primaryMuscle: 'glutes',
      equipment: 'kettlebell',
      description:
          'Hinge at the hips to hike the bell back, then snap the hips forward '
          'to float it to chest height. Power comes from the hips, not the '
          'arms; keep the spine neutral throughout.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'power-snatch',
      name: 'Power Snatch',
      category: 'strength',
      primaryMuscle: 'hamstrings',
      equipment: 'barbell',
      description:
          'Pull the bar explosively from the floor with a wide grip and punch '
          'it overhead in one motion, catching in a partial squat. Keep the bar '
          'close and finish with arms locked overhead.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'snatch-grip-deadlift',
      name: 'Snatch-Grip Deadlift',
      category: 'strength',
      primaryMuscle: 'hamstrings',
      equipment: 'barbell',
      description:
          'Take a wide snatch grip and deadlift the bar with a flat back and '
          'high hips to increase posterior-chain range. Drive through the floor '
          'and stand tall, keeping the bar close to the legs.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'hang-clean',
      name: 'Hang Clean',
      category: 'strength',
      primaryMuscle: 'hamstrings',
      equipment: 'barbell',
      description:
          'Start with the bar at mid-thigh, dip and explosively extend the hips '
          'to pull it to the shoulders, catching in a quarter-squat. Keep the '
          'bar close and the chest up throughout.',
      tracksWeight: true,
      tracksReps: true),

  // ---- Squat / hinge variants ----
  SeedExercise(
      slug: 'sumo-deadlift',
      name: 'Sumo Deadlift',
      category: 'strength',
      primaryMuscle: 'hamstrings',
      equipment: 'barbell',
      description:
          'Take a wide stance with toes turned out and grip inside the knees, '
          'then drive the floor apart and stand tall. Keep the chest up and the '
          'bar tracking close to the shins.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'trap-bar-deadlift',
      name: 'Trap-Bar Deadlift',
      category: 'strength',
      primaryMuscle: 'quads',
      equipment: 'barbell',
      description:
          'Stand inside the hex bar, grip the neutral handles, and drive up '
          'through mid-foot with a flat back. The centered load lets you stay '
          'more upright than a straight-bar pull.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'rack-pull',
      name: 'Rack Pull',
      category: 'strength',
      primaryMuscle: 'back',
      equipment: 'barbell',
      description:
          'Set the bar on pins around knee height and deadlift from there to '
          'overload the top of the pull. Keep the back flat and finish by '
          'squeezing the glutes and locking out tall.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'deficit-deadlift',
      name: 'Deficit Deadlift',
      category: 'strength',
      primaryMuscle: 'hamstrings',
      equipment: 'barbell',
      description:
          'Stand on a low platform so the bar starts below normal, increasing '
          'range and bottom-end strength. Maintain a flat back through the '
          'longer pull and stand tall to finish.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'box-squat',
      name: 'Box Squat',
      category: 'strength',
      primaryMuscle: 'quads',
      equipment: 'barbell',
      description:
          'Squat back to lightly touch a box at or below parallel, pause, then '
          'drive up explosively. Sit back onto the box without relaxing and '
          'keep the shins vertical.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'pause-squat',
      name: 'Pause Squat',
      category: 'strength',
      primaryMuscle: 'quads',
      equipment: 'barbell',
      description:
          'Squat to the bottom and hold a deliberate two-second pause before '
          'driving up. Stay tight and braced in the hole to build strength out '
          'of the bottom position.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'pistol-squat',
      name: 'Pistol Squat',
      category: 'strength',
      primaryMuscle: 'quads',
      equipment: 'bodyweight',
      description:
          'Balance on one leg with the other extended in front and squat all '
          'the way down, then stand back up. Keep the heel down and the chest '
          'up to control the descent.',
      tracksReps: true),
  SeedExercise(
      slug: 'sissy-squat',
      name: 'Sissy Squat',
      category: 'strength',
      primaryMuscle: 'quads',
      equipment: 'bodyweight',
      description:
          'Rise onto the balls of your feet and lean back, bending only at the '
          'knees to lower the torso while keeping hips extended. Drive through '
          'the quads to return upright.',
      tracksReps: true),
  SeedExercise(
      slug: 'step-up',
      name: 'Step-Up',
      category: 'strength',
      primaryMuscle: 'quads',
      equipment: 'dumbbell',
      description:
          'Plant one foot on a knee-height box and drive through that heel to '
          'stand tall on top. Control the descent and avoid pushing off the '
          'trailing leg.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'smith-machine-squat',
      name: 'Smith Machine Squat',
      category: 'strength',
      primaryMuscle: 'quads',
      equipment: 'machine',
      description:
          'Position the bar on your upper back in the Smith machine and squat '
          'with feet set slightly forward. The fixed bar path lets you focus on '
          'driving up through the quads.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'belt-squat',
      name: 'Belt Squat',
      category: 'strength',
      primaryMuscle: 'quads',
      equipment: 'machine',
      description:
          'Load the weight from a hip belt and squat without any spinal '
          'loading. Keep the torso upright and drive through mid-foot to spare '
          'the lower back.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'single-leg-rdl',
      name: 'Single-Leg Romanian Deadlift',
      category: 'strength',
      primaryMuscle: 'hamstrings',
      equipment: 'dumbbell',
      description:
          'Balance on one leg and hinge forward, reaching the weight toward the '
          'floor while the rear leg extends behind you. Keep a flat back and '
          'return by squeezing the glute.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'pendulum-squat',
      name: 'Pendulum Squat',
      category: 'strength',
      primaryMuscle: 'quads',
      equipment: 'machine',
      description:
          'Set your back against the pad and feet on the platform, then squat '
          'along the machine arc. The guided path keeps constant tension on the '
          'quads through a deep range.',
      tracksWeight: true,
      tracksReps: true),

  // ---- Bodybuilding classics ----
  SeedExercise(
      slug: 'dumbbell-pullover',
      name: 'Dumbbell Pullover',
      category: 'strength',
      primaryMuscle: 'chest',
      equipment: 'dumbbell',
      description:
          'Lie across a bench and lower a single dumbbell back over your head '
          'with a slight elbow bend, feeling a deep stretch. Pull it back over '
          'the chest using the pecs and lats.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'jm-press',
      name: 'JM Press',
      category: 'strength',
      primaryMuscle: 'triceps',
      equipment: 'barbell',
      description:
          'A hybrid of a close-grip press and skullcrusher: lower the bar '
          'toward the upper chest by tucking the elbows, then press back up. '
          'Keep the forearms vertical to load the triceps.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'spider-curl',
      name: 'Spider Curl',
      category: 'strength',
      primaryMuscle: 'biceps',
      equipment: 'dumbbell',
      description:
          'Lie chest-down on an incline bench with arms hanging straight, then '
          'curl the weights up while keeping the upper arms vertical. The '
          'strict position removes momentum from the biceps.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'zottman-curl',
      name: 'Zottman Curl',
      category: 'strength',
      primaryMuscle: 'biceps',
      equipment: 'dumbbell',
      description:
          'Curl up with palms facing the ceiling, rotate to a palms-down grip '
          'at the top, and lower under control. The supinated lift hits the '
          'biceps and the pronated descent loads the forearms.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'drag-curl',
      name: 'Drag Curl',
      category: 'strength',
      primaryMuscle: 'biceps',
      equipment: 'barbell',
      description:
          'Curl the bar while dragging it up along the torso, driving the '
          'elbows back behind the body. The path keeps tension on the biceps '
          'and minimizes front-delt involvement.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'seal-row',
      name: 'Seal Row',
      category: 'strength',
      primaryMuscle: 'back',
      equipment: 'barbell',
      description:
          'Lie chest-down on an elevated bench and row the bar straight up to '
          'the underside of the bench. The supported position eliminates body '
          'english and isolates the back.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'meadows-row',
      name: 'Meadows Row',
      category: 'strength',
      primaryMuscle: 'back',
      equipment: 'barbell',
      description:
          'Stand perpendicular to a landmine bar and row the loaded end with a '
          'pronated grip, driving the elbow up and back. Keep the hips hinged '
          'and the back flat throughout.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'kroc-row',
      name: 'Kroc Row',
      category: 'strength',
      primaryMuscle: 'back',
      equipment: 'dumbbell',
      description:
          'Perform a heavy, high-rep one-arm dumbbell row using a touch of '
          'controlled body english to move big weight. Brace on a bench or rack '
          'and drive the elbow high each rep.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'inverted-row',
      name: 'Inverted Row',
      category: 'strength',
      primaryMuscle: 'back',
      equipment: 'bodyweight',
      description:
          'Hang under a fixed bar with the body straight and pull the chest up '
          'to the bar. Keep the core tight and the body rigid like a moving '
          'plank throughout.',
      tracksReps: true),
  SeedExercise(
      slug: 'machine-lateral-raise',
      name: 'Machine Lateral Raise',
      category: 'strength',
      primaryMuscle: 'shoulders',
      equipment: 'machine',
      description:
          'Sit with the pads against your outer arms and raise the elbows out '
          'to shoulder height. Lead with the elbows and pause briefly at the '
          'top to load the side delts.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'cable-rear-delt-fly',
      name: 'Cable Rear-Delt Fly',
      category: 'strength',
      primaryMuscle: 'rear-delts',
      equipment: 'cable',
      description:
          'Cross the cables in front and pull them apart in a wide reverse-fly '
          'arc, leading with the pinkies. Keep a slight elbow bend and squeeze '
          'the rear delts at the back.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'y-raise',
      name: 'Y-Raise',
      category: 'strength',
      primaryMuscle: 'shoulders',
      equipment: 'dumbbell',
      description:
          'Lean over an incline bench and raise light dumbbells up and out into '
          'a Y overhead with thumbs up. Lead with the lower traps and rear '
          'delts to build shoulder stability.',
      tracksWeight: true,
      tracksReps: true),

  // ---- Core / posterior chain ----
  SeedExercise(
      slug: 'back-extension',
      name: 'Back Extension',
      category: 'strength',
      primaryMuscle: 'hamstrings',
      equipment: 'bodyweight',
      description:
          'Anchor your thighs on a 45-degree or horizontal pad and hinge down, '
          'then raise your torso until in line with the legs. Squeeze the '
          'glutes at the top without hyperextending the spine.',
      tracksReps: true),
  SeedExercise(
      slug: 'reverse-hyper',
      name: 'Reverse Hyperextension',
      category: 'strength',
      primaryMuscle: 'glutes',
      equipment: 'machine',
      description:
          'Lie face-down with hips at the edge of the pad and swing the legs '
          'from hanging to in line with the torso. Drive with the glutes and '
          'control the swing back down.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'sit-up',
      name: 'Sit-Up',
      category: 'strength',
      primaryMuscle: 'core',
      equipment: 'bodyweight',
      description:
          'With knees bent and feet anchored, curl the torso all the way up '
          'toward the thighs, then lower under control. Lead with the abs '
          'rather than yanking with the neck.',
      tracksReps: true),
  SeedExercise(
      slug: 'bicycle-crunch',
      name: 'Bicycle Crunch',
      category: 'strength',
      primaryMuscle: 'core',
      equipment: 'bodyweight',
      description:
          'Lie on your back and alternate bringing each elbow to the opposite '
          'knee while extending the other leg. Rotate through the obliques and '
          'keep the lower back pressed down.',
      tracksReps: true),
  SeedExercise(
      slug: 'toes-to-bar',
      name: 'Toes-to-Bar',
      category: 'strength',
      primaryMuscle: 'core',
      equipment: 'bodyweight',
      description:
          'Hang from a pull-up bar and raise your toes to touch it, hinging at '
          'the hips with controlled legs. Use a slight kip if needed but keep '
          'the abs driving the movement.',
      tracksReps: true),
  SeedExercise(
      slug: 'side-plank',
      name: 'Side Plank',
      category: 'strength',
      primaryMuscle: 'core',
      equipment: 'bodyweight',
      description:
          'Stack your feet and prop up on one forearm, lifting the hips so the '
          'body forms a straight line. Brace the obliques and avoid letting the '
          'hips sag toward the floor.',
      tracksDuration: true),
  SeedExercise(
      slug: 'mountain-climber',
      name: 'Mountain Climber',
      category: 'strength',
      primaryMuscle: 'core',
      equipment: 'bodyweight',
      description:
          'From a high plank, rapidly drive the knees toward the chest one at a '
          'time. Keep the hips low and the shoulders stacked over the hands '
          'throughout.',
      tracksReps: true),
  SeedExercise(
      slug: 'v-up',
      name: 'V-Up',
      category: 'strength',
      primaryMuscle: 'core',
      equipment: 'bodyweight',
      description:
          'Lie flat and simultaneously raise the legs and torso to meet in a V, '
          'reaching the hands toward the toes. Lower under control without '
          'letting the heels touch the floor.',
      tracksReps: true),
  SeedExercise(
      slug: 'cable-woodchopper',
      name: 'Cable Woodchopper',
      category: 'strength',
      primaryMuscle: 'core',
      equipment: 'cable',
      description:
          'Set the pulley high and pull the handle diagonally across the body '
          'to the opposite hip, rotating through the trunk. Pivot the back foot '
          'and drive the motion with the obliques.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'bird-dog',
      name: 'Bird Dog',
      category: 'strength',
      primaryMuscle: 'core',
      equipment: 'bodyweight',
      description:
          'On all fours, extend the opposite arm and leg until level with the '
          'torso, then return without rotating the hips. Move slowly and keep '
          'the spine neutral to train anti-rotation.',
      tracksReps: true),

  // ---- Machine accessories ----
  SeedExercise(
      slug: 'hip-abduction',
      name: 'Hip Abduction',
      category: 'strength',
      primaryMuscle: 'abductors',
      equipment: 'machine',
      description:
          'Sit in the machine with pads against the outer thighs and press the '
          'knees apart against resistance. Pause briefly at full abduction to '
          'load the glute medius.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'hip-adduction',
      name: 'Hip Adduction',
      category: 'strength',
      primaryMuscle: 'adductors',
      equipment: 'machine',
      description:
          'Sit with the pads against your inner thighs and squeeze the knees '
          'together against resistance. Control the return and keep the torso '
          'upright throughout.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'glute-kickback-machine',
      name: 'Glute Kickback Machine',
      category: 'strength',
      primaryMuscle: 'glutes',
      equipment: 'machine',
      description:
          'Brace against the pad and press one foot back against the platform '
          'until the hip is fully extended. Squeeze the glute at the top and '
          'control the return.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'donkey-calf-raise',
      name: 'Donkey Calf Raise',
      category: 'strength',
      primaryMuscle: 'calves',
      equipment: 'machine',
      description:
          'Hinge at the hips with the pad across your lower back and rise onto '
          'the balls of your feet through a full range. Pause at the top stretch '
          'and lower slowly for a deep calf stretch.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'tibialis-raise',
      name: 'Tibialis Raise',
      category: 'strength',
      primaryMuscle: 'tibialis',
      equipment: 'bodyweight',
      description:
          'With heels planted and back against a wall, pull the toes up toward '
          'the shins against resistance, then lower under control. Trains the '
          'front-of-shin tibialis for ankle health.',
      tracksWeight: true,
      tracksReps: true),

  // ---- Adductors (inner thigh) ----
  SeedExercise(
      slug: 'cable-hip-adduction',
      name: 'Cable Hip Adduction',
      category: 'strength',
      primaryMuscle: 'adductors',
      equipment: 'cable',
      description:
          'With an ankle strap on the working leg, stand side-on to the stack '
          'and pull the leg across your midline against resistance. Control the '
          'return and keep the torso still to isolate the inner thigh.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'copenhagen-plank',
      name: 'Copenhagen Plank',
      category: 'strength',
      primaryMuscle: 'adductors',
      equipment: 'bodyweight',
      description:
          'Side plank with the top leg on a bench; lift the bottom leg to meet '
          'it so the inner thighs hold you up. Hold with hips high — a strong '
          'adductor and groin-resilience builder.',
      tracksDuration: true),
  SeedExercise(
      slug: 'sumo-squat',
      name: 'Sumo Squat',
      category: 'strength',
      primaryMuscle: 'adductors',
      equipment: 'barbell',
      description:
          'Take a wide stance with toes turned out and squat down keeping the '
          'knees tracking over the toes. The wide stance shifts emphasis to the '
          'adductors and glutes.',
      tracksWeight: true,
      tracksReps: true),

  // ---- Abductors (outer hip / glute medius) ----
  SeedExercise(
      slug: 'cable-hip-abduction',
      name: 'Cable Hip Abduction',
      category: 'strength',
      primaryMuscle: 'abductors',
      equipment: 'cable',
      description:
          'Ankle strap on the working leg, stand side-on to the stack and lift '
          'the leg out to the side against resistance. Keep the torso upright '
          'and avoid leaning to load the glute medius.',
      tracksWeight: true,
      tracksReps: true),
  SeedExercise(
      slug: 'banded-lateral-walk',
      name: 'Banded Lateral Walk',
      category: 'strength',
      primaryMuscle: 'abductors',
      equipment: 'band',
      description:
          'Loop a band around the legs, sink into a half-squat and step '
          'sideways keeping tension on the band. Great glute-medius activation '
          'and warm-up for heavy lower-body work.',
      tracksReps: true),
  SeedExercise(
      slug: 'side-lying-leg-raise',
      name: 'Side-Lying Leg Raise',
      category: 'strength',
      primaryMuscle: 'abductors',
      equipment: 'bodyweight',
      description:
          'Lie on your side and raise the top leg toward the ceiling with the '
          'foot slightly forward. Lift under control and avoid rolling the hips '
          'back to keep the outer hip working.',
      tracksReps: true),

  // ---- Tibialis (anterior shin) ----
  SeedExercise(
      slug: 'banded-tibialis-raise',
      name: 'Banded Tibialis Raise',
      category: 'strength',
      primaryMuscle: 'tibialis',
      equipment: 'band',
      description:
          'Anchor a band around the toes, sit or stand with heels down and pull '
          'the toes up toward the shins against the band. Builds the front-shin '
          'tibialis for knee/ankle health and stronger sprinting.',
      tracksReps: true),
  SeedExercise(
      slug: 'dumbbell-tibialis-raise',
      name: 'Dumbbell Tibialis Raise',
      category: 'strength',
      primaryMuscle: 'tibialis',
      equipment: 'dumbbell',
      description:
          'Sit with a dumbbell held vertically on your toes, heels planted, and '
          'raise the toes through a full range. Lower slowly for a deep stretch '
          'at the front of the shin.',
      tracksWeight: true,
      tracksReps: true),
];

/// Idempotently seed the built-in exercise catalog: insert slugs that are not
/// present yet, and backfill the how-to [description] onto built-ins that were
/// seeded before descriptions existed. Calling this repeatedly never
/// duplicates rows and never clobbers a user's custom exercises.
Future<void> seedExercises(TrainingRepository repo) async {
  final existing = await repo.allExercises();
  final bySlug = {
    for (final e in existing)
      if (e.slug != null) e.slug!: e,
  };
  for (final seed in kBuiltInExercises) {
    final current = bySlug[seed.slug];
    if (current == null) {
      // A user may have a custom exercise with the same name as this built-in.
      // Adopt it (attach the slug + built-in metadata) rather than duplicating.
      final sameName = await repo.exerciseByName(seed.name);
      if (sameName != null && sameName.slug == null) {
        await repo.adoptCustomAsBuiltIn(sameName.id, seed.toCompanion());
      } else {
        await repo.insertExercise(seed.toCompanion());
      }
      continue;
    }
    // Backfill / refresh the how-to text on an already-seeded built-in.
    if (seed.description != null && current.description != seed.description) {
      await repo.updateExerciseDescription(current.id, seed.description);
    }
    // Re-point primaryMuscle if the catalog moved it (e.g. hip-adduction
    // quads→adductors on an install seeded before the re-point).
    if (current.primaryMuscle != seed.primaryMuscle) {
      await repo.updateExercisePrimaryMuscle(current.id, seed.primaryMuscle);
    }
    // Backfill secondary muscles onto exercises seeded before they existed.
    final sec = secondaryMusclesFor(seed.slug);
    if (current.secondaryMuscles != sec) {
      await repo.updateExerciseSecondaryMuscles(current.id, sec);
    }
  }
  // Collapse any duplicate exercises accumulated on existing devices (custom
  // rows matching a built-in, or stale re-slugged rows). Idempotent: a no-op
  // when there are no duplicates, so it's safe to run on every startup.
  await repo.dedupeExercisesByName();
}
