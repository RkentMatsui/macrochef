import 'dart:io' show Directory, File, Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/database.dart';
import '../services/auto_backup.dart';
import '../services/shared_storage.dart';
import '../data/repositories/grocery_repository.dart';
import '../data/repositories/recipe_repository.dart';
import '../data/repositories/food_cache_repository.dart';
import '../data/repositories/log_repository.dart';
import '../data/repositories/target_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/weight_repository.dart';
import '../data/repositories/training_repository.dart';
import '../data/repositories/daily_activity_repository.dart';
import '../providers/llm/llm_provider.dart';
import '../providers/llm/llm_provider_factory.dart';
import '../providers/speech/sherpa_speech_provider.dart';
import '../providers/speech/speech_provider.dart';
import '../providers/speech/stub_speech_provider.dart';
import '../providers/speech/voice_model_manager.dart';
import '../services/food_db/open_food_facts_client.dart';
import '../services/food_db/usda_client.dart';
import '../services/food_lookup.dart';
import '../services/nutrition/local_nutrition_db.dart';
import '../services/nutrition/nutrition_pack_manager.dart';
import '../services/nutrition/nutrition_retriever.dart';
import '../services/nutrition/onnx_minilm_embedder.dart';
import '../services/generation_prefs_store.dart';
import '../services/intent_parser.dart';
import '../services/workout_intent_parser.dart';
import '../services/recipe_generator_service.dart';
import '../services/recipe_service.dart';
import '../services/daily_log_service.dart';
import '../services/recipe_nutrition_service.dart';
import '../services/weight_service.dart';
import '../services/adaptive_macro_service.dart';
import '../services/training_service.dart';
import '../services/schedule_service.dart';
import '../services/progression_service.dart';
import '../services/program_generator_service.dart';
import '../services/rest_alert_service.dart';
import '../services/backup_service.dart';
import '../services/recovery/recovery_bootstrap_store.dart';
import '../services/recovery/recovery_finalizer.dart';

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Export/import of the on-device database (Settings → Data).
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(appDatabaseProvider));
});

/// Shared (uninstall-surviving) storage for auto-backups. Android writes to
/// public Downloads via MediaStore; other platforms no-op.
final sharedStorageProvider = Provider<SharedStorage>((ref) {
  return Platform.isAndroid
      ? const MediaStoreSharedStorage()
      : const NoopSharedStorage();
});

/// Launch-time safety-net backup: a throttled silent snapshot mirrored to an
/// on-device rotating folder AND public Downloads (survives a reinstall).
final autoBackupServiceProvider = Provider<AutoBackupService>((ref) {
  final backup = ref.watch(backupServiceProvider);
  final settings = ref.watch(settingsRepositoryProvider);
  return AutoBackupService(
    exportSnapshot: (dest) => backup.exportTo(dest),
    shared: ref.watch(sharedStorageProvider),
    getSetting: settings.get,
    setSetting: settings.set,
    localBackupDir: () async {
      final base =
          await getExternalStorageDirectory() ??
          await getApplicationSupportDirectory();
      return Directory(p.join(base.path, 'backups'));
    },
  );
});

/// Completes a pending restore by first creating a fresh uninstall-surviving
/// backup, then retiring the backup that was consumed by the restore.
final recoveryFinalizerProvider = FutureProvider<RecoveryFinalizer>((
  ref,
) async {
  final support = await getApplicationSupportDirectory();
  return RecoveryFinalizer(
    store: RecoveryBootstrapStore(
      File(p.join(support.path, 'recovery-bootstrap-v1.json')),
    ),
    autoBackup: ref.watch(autoBackupServiceProvider),
    shared: ref.watch(sharedStorageProvider),
  );
});

// ---------------------------------------------------------------------------
// Repositories
// ---------------------------------------------------------------------------

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository(ref.watch(appDatabaseProvider));
});

final foodCacheRepositoryProvider = Provider<FoodCacheRepository>((ref) {
  return FoodCacheRepository(ref.watch(appDatabaseProvider));
});

final logRepositoryProvider = Provider<LogRepository>((ref) {
  return LogRepository(ref.watch(appDatabaseProvider));
});

final targetRepositoryProvider = Provider<TargetRepository>((ref) {
  return TargetRepository(ref.watch(appDatabaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
});

final generationPrefsStoreProvider = Provider<GenerationPrefsStore>((ref) {
  return GenerationPrefsStore(ref.watch(settingsRepositoryProvider));
});

final groceryRepositoryProvider = Provider<GroceryRepository>(
  (ref) => GroceryRepository(ref.watch(appDatabaseProvider)),
);

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  return WeightRepository(ref.watch(appDatabaseProvider));
});

final trainingRepositoryProvider = Provider<TrainingRepository>((ref) {
  return TrainingRepository(ref.watch(appDatabaseProvider));
});

final dailyActivityRepositoryProvider = Provider<DailyActivityRepository>((
  ref,
) {
  return DailyActivityRepository(ref.watch(appDatabaseProvider));
});

// ---------------------------------------------------------------------------
// Infrastructure
// ---------------------------------------------------------------------------

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final speechProvider = Provider<SpeechProvider>((ref) {
  // Native on-device voice on mobile; no-op stub elsewhere (desktop/tests).
  if (Platform.isAndroid || Platform.isIOS) {
    return SherpaSpeechProvider();
  }
  return StubSpeechProvider();
});

/// Manages the optional, downloadable Voice Pack (sherpa models) — download /
/// state / delete. See [VoiceModelManager].
final voiceModelManagerProvider = Provider<VoiceModelManager>((ref) {
  return VoiceModelManager();
});

// ---------------------------------------------------------------------------
// LLM
// ---------------------------------------------------------------------------

/// Reads llm_kind, llm_model, and llm_api_key then constructs an [LLMProvider].
/// If the API key is missing the provider is still built with an empty string —
/// the UI is responsible for surfacing config errors.
final llmProvider = FutureProvider<LLMProvider>((ref) async {
  final settings = ref.watch(settingsRepositoryProvider);
  final secure = ref.watch(secureStorageProvider);

  final kindStr = await settings.get('llm_kind') ?? 'claude';
  final kind = LlmKind.values.firstWhere(
    (e) => e.name == kindStr,
    orElse: () => LlmKind.claude,
  );

  // Fall back to THIS provider's default model (not a hardcoded Claude id) so a
  // Gemini/OpenAI client is never built with a Claude model id (that caused 404s).
  final savedModel = await settings.get('llm_model');
  final model = (savedModel == null || savedModel.trim().isEmpty)
      ? defaultModelFor(kind)
      : savedModel.trim();
  final apiKey = kind == LlmKind.local
      ? ''
      : (await secure.read(key: 'llm_api_key_${kind.name}') ??
            await secure.read(key: 'llm_api_key') ??
            '');

  return buildLlm(kind, apiKey, model);
});

// ---------------------------------------------------------------------------
// Services
// ---------------------------------------------------------------------------

final nutritionPackManagerProvider = Provider<NutritionPackManager>((ref) {
  return NutritionPackManager();
});

final nutritionPackStateProvider = FutureProvider<NutritionPackState>((ref) {
  return ref.watch(nutritionPackManagerProvider).resolveState();
});

/// Null means local nutrition is unavailable, invalid, or disabled. Every pack
/// setup failure degrades to the existing USDA/OFF/AI lookup path.
final nutritionRetrieverProvider =
    FutureProvider<NutritionRetriever?>((ref) async {
  SqliteNutritionDb? db;
  OnnxMiniLmEmbedder? embedder;
  try {
    final settings = ref.watch(settingsRepositoryProvider);
    if (await settings.get('local_nutrition_enabled') != 'true') return null;
    final manager = ref.watch(nutritionPackManagerProvider);
    if (!await manager.isDownloaded()) return null;
    db = SqliteNutritionDb.open(await manager.dbPath());
    embedder = OnnxMiniLmEmbedder(
      modelPath: await manager.modelPath(),
      vocabPath: await manager.vocabPath(),
    );
    if (db.embedderId != embedder.id || db.dim != embedder.dim) {
      await db.close();
      embedder.dispose();
      return null;
    }
    final ownedDb = db;
    final ownedEmbedder = embedder;
    ref.onDispose(() {
      ownedDb.close();
      ownedEmbedder.dispose();
    });
    return NutritionRetriever(db: db, embedder: embedder);
  } on Object {
    await db?.close();
    embedder?.dispose();
    return null;
  }
});

final foodLookupProvider = FutureProvider<FoodLookup>((ref) async {
  final llm = await ref.watch(llmProvider.future);
  final cache = ref.watch(foodCacheRepositoryProvider);
  final settings = ref.watch(settingsRepositoryProvider);
  final usdaKey = await settings.get('usda_api_key');
  final retriever = await ref.watch(nutritionRetrieverProvider.future);

  return FoodLookup(
    cache: cache,
    off: OpenFoodFactsClient(),
    usda: UsdaClient(apiKey: usdaKey ?? ''),
    llm: llm,
    usdaKey: usdaKey,
    nutritionRetriever: retriever,
  );
});

final intentParserProvider = FutureProvider<IntentParser>((ref) async {
  final llm = await ref.watch(llmProvider.future);
  return IntentParser(llm: llm);
});

final workoutIntentParserProvider = FutureProvider<WorkoutIntentParser>((
  ref,
) async {
  final llm = await ref.watch(llmProvider.future);
  return WorkoutIntentParser(llm: llm);
});

final recipeServiceProvider = Provider<RecipeService>((ref) {
  return const RecipeService();
});

final dailyLogServiceProvider = Provider<DailyLogService>((ref) {
  return DailyLogService(
    logs: ref.watch(logRepositoryProvider),
    targets: ref.watch(targetRepositoryProvider),
  );
});

final weightServiceProvider = Provider<WeightService>((ref) {
  return WeightService(
    weights: ref.watch(weightRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
  );
});

final adaptiveMacroServiceProvider = Provider<AdaptiveMacroService>((ref) {
  return AdaptiveMacroService(
    logs: ref.watch(logRepositoryProvider),
    targets: ref.watch(targetRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    weightService: ref.watch(weightServiceProvider),
  );
});

final recipeNutritionServiceProvider = FutureProvider<RecipeNutritionService>((
  ref,
) async {
  final lookup = await ref.watch(foodLookupProvider.future);
  final repo = ref.watch(recipeRepositoryProvider);
  final logs = ref.watch(dailyLogServiceProvider);
  return RecipeNutritionService(lookup: lookup, repo: repo, logs: logs);
});

final recipeGeneratorServiceProvider = FutureProvider<RecipeGeneratorService>((
  ref,
) async {
  final llm = await ref.watch(llmProvider.future);
  return RecipeGeneratorService(llm);
});

final trainingServiceProvider = Provider<TrainingService>((ref) {
  return TrainingService(ref.watch(trainingRepositoryProvider));
});

final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return ScheduleService(ref.watch(trainingRepositoryProvider));
});

final progressionServiceProvider = Provider<ProgressionService>((ref) {
  return ProgressionService(ref.watch(trainingRepositoryProvider));
});

/// Fires the rest-timer completion alert (in-app tone foreground; scheduled
/// notification with sound for background/screen-off). Kept alive for the
/// session so the underlying audio player + plugin are reused.
final restAlertServiceProvider = Provider<RestAlertService>((ref) {
  final svc = RestAlertService();
  ref.onDispose(svc.dispose);
  return svc;
});

final programGeneratorServiceProvider = FutureProvider<ProgramGeneratorService>(
  (ref) async {
    final llm = await ref.watch(llmProvider.future);
    return ProgramGeneratorService(llm);
  },
);

// ---------------------------------------------------------------------------
// Utility
// ---------------------------------------------------------------------------

/// Returns today's date as YYYY-MM-DD.
String todayDate() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
