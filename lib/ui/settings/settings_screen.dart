import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_links.dart';

import '../../services/backup_service.dart';
import '../../services/auto_backup.dart';
import '../../services/shared_storage.dart';
import '../../services/recovery/backup_candidate_validator.dart';
import '../../services/recovery/recovery_bootstrap_store.dart';

import '../../models/chat.dart';
import '../../models/daily.dart';
import 'custom_foods_screen.dart';
import '../../providers/llm/llm_provider.dart';
import '../../providers/llm/llm_provider_factory.dart';
import '../../providers/llm/local/local_models.dart';
import '../../providers/llm/local/local_download_controller.dart';
import '../../providers/speech/voice_model_files.dart' show VoiceState;
import '../../services/adaptive_macro_service.dart';
import '../../services/nutrition/nutrition_pack_manager.dart';
import '../../services/training_service.dart'
    show kTrainingRestSecKey, kDefaultRestSec;
import '../../services/weight_service.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../widgets/cards.dart';
import '../widgets/glass_panel.dart';
import '../widgets/primary_button.dart';

// Default model ids per provider live in llm_provider_factory.dart
// (`defaultModels` / `defaultModelFor`) — single source of truth shared with
// the llmProvider fallback.

// ---------------------------------------------------------------------------
// SettingsScreen
// ---------------------------------------------------------------------------

const kPayPalDonationUrl = 'https://www.paypal.me/RMatsui';

typedef ExternalUrlLauncher = Future<bool> Function(Uri url);

Future<bool> _launchExternalUrl(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);

abstract interface class SettingsRecoveryService {
  Future<SettingsRecoveryResult> recoverLatest();
}

class SettingsRecoveryResult {
  final bool staged;
  final String? message;

  const SettingsRecoveryResult.staged(String backupId, String backupName)
    : staged = true,
      message = null;

  const SettingsRecoveryResult.error(this.message) : staged = false;
}

class DefaultSettingsRecoveryService implements SettingsRecoveryService {
  final SharedStorage shared;
  final Future<bool> Function(File file) stageRestore;
  final RecoveryBootstrapStore bootstrapStore;
  final Directory workingDirectory;
  final Future<File?> Function() pickBackupFile;
  final BackupCandidateValidator validator = const BackupCandidateValidator();

  DefaultSettingsRecoveryService({
    required this.shared,
    required this.stageRestore,
    required this.bootstrapStore,
    required this.workingDirectory,
    Future<File?> Function()? pickBackupFile,
  }) : pickBackupFile = pickBackupFile ?? _pickBackupFile;

  static Future<File?> _pickBackupFile() async {
    final picked = await FilePicker.platform.pickFiles(withData: false);
    final files = picked?.files ?? const [];
    final path = files.isEmpty ? null : files.first.path;
    return path == null ? null : File(path);
  }

  @override
  Future<SettingsRecoveryResult> recoverLatest() async {
    File? candidate;
    try {
      final backups = await shared.listDownloads(kBackupPrefix)
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
      if (backups.isEmpty) {
        return const SettingsRecoveryResult.error(
          'No automatic backup was found in Downloads/MacroChef.',
        );
      }
      await workingDirectory.create(recursive: true);
      candidate = File(
        p.join(workingDirectory.path, 'settings-recovery.sqlite'),
      );
      for (final backup in backups) {
        if (await candidate.exists()) await candidate.delete();
        var source = backup;
        try {
          await shared.copyToPrivate(backup, candidate);
        } on SharedStorageAccessException {
          final picked = await pickBackupFile();
          if (picked == null) {
            return const SettingsRecoveryResult.error(
              'Backup access was cancelled.',
            );
          }
          final pickedName = p.basename(picked.path);
          final matches = backups.where((item) => item.name == pickedName);
          if (matches.isEmpty) {
            return const SettingsRecoveryResult.error(
              'Select a MacroChef backup listed in Downloads/MacroChef.',
            );
          }
          source = matches.first;
          await picked.copy(candidate.path);
        }
        if (!(await validator.validate(candidate)).isValid) continue;
        if (!await stageRestore(candidate)) continue;

        await bootstrapStore.write(
          RecoveryBootstrapRecord(
            status: RecoveryBootstrapStatus.recoveryApplied,
            consumedBackupId: source.id,
            consumedBackupName: source.name,
          ),
        );
        return SettingsRecoveryResult.staged(source.id, source.name);
      }
      return const SettingsRecoveryResult.error(
        'No valid automatic backup was found in Downloads/MacroChef.',
      );
    } catch (error) {
      return SettingsRecoveryResult.error('Recovery failed: $error');
    } finally {
      if (candidate != null && await candidate.exists()) {
        await candidate.delete();
      }
    }
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
    this.recoveryService,
    this.urlLauncher = _launchExternalUrl,
  });

  final SettingsRecoveryService? recoveryService;
  final ExternalUrlLauncher urlLauncher;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // ---- provider / model ----
  LlmKind _selectedKind = LlmKind.claude;
  final TextEditingController _modelCtrl = TextEditingController();

  // ---- api key ----
  final TextEditingController _apiKeyCtrl = TextEditingController();
  bool _apiKeyExists = false;
  bool _savingApiKey = false; // secure-storage write in flight → show spinner

  // ---- backup / restore ----
  bool _backupBusy = false; // export/import in flight

  // ---- modal-sheet feedback ----
  // Settings sections open in a bottom sheet, so a SnackBar shown on the
  // screen's messenger renders *behind* the sheet and the user never sees it.
  // Instead we surface save confirmations inside the open sheet: _refreshSheet
  // rebuilds it, _sheetMsg is the transient banner text.
  StateSetter? _refreshSheet;
  String? _sheetMsg;
  Timer? _sheetMsgTimer;

  // ---- usda key ----
  final TextEditingController _usdaKeyCtrl = TextEditingController();
  bool _localNutritionEnabled = false;
  NutritionPackState _nutritionPackState = NutritionPackState.notDownloaded;
  bool _nutritionPackBusy = false;
  double? _nutritionPackProgress;
  String? _nutritionPackError;

  // ---- daily targets ----
  final TextEditingController _kcalCtrl = TextEditingController();
  final TextEditingController _proteinCtrl = TextEditingController();
  final TextEditingController _carbCtrl = TextEditingController();
  final TextEditingController _fatCtrl = TextEditingController();

  // ---- fibre target ----
  final TextEditingController _fibreTargetCtrl = TextEditingController();

  // ---- ingredient blacklist ----
  final TextEditingController _blacklistCtrl = TextEditingController();
  List<String> _blacklist = [];

  // ---- weight unit ----
  String _weightUnit = 'kg';

  // ---- training defaults ----
  final TextEditingController _restSecCtrl = TextEditingController();

  // ---- adaptive targets ----
  bool _adaptiveEnabled = false;
  String _adaptiveGoal = 'maintain';
  final TextEditingController _goalRateCtrl = TextEditingController();
  final TextEditingController _goalWeightCtrl = TextEditingController();
  double? _currentTrendKg; // latest trend weight (kg) — the adaptive anchor
  DailyTarget? _adaptiveResult;
  bool _adaptiveRunning = false;
  bool _adaptiveComputed = false; // true once recompute() has actually run

  // ---- voice pack ----
  double? _voiceProgress; // aggregate download progress 0..1, null when idle
  Future<VoiceState>? _voiceStateFuture; // cached so FutureBuilder is stable

  // ---- test connection state ----
  bool _testing = false;
  String? _testResult; // null = not tested yet
  bool _testSuccess = false;

  bool _loaded = false;

  String get _apiKeyStorageKey => 'llm_api_key_${_selectedKind.name}';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _modelCtrl.dispose();
    _apiKeyCtrl.dispose();
    _usdaKeyCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    _fibreTargetCtrl.dispose();
    _restSecCtrl.dispose();
    _goalRateCtrl.dispose();
    _goalWeightCtrl.dispose();
    _blacklistCtrl.dispose();
    _sheetMsgTimer?.cancel();
    super.dispose();
  }

  /// Settings sections live in a bottom sheet whose element tree is separate
  /// from this screen's, so a normal setState rebuilds the screen *behind* the
  /// sheet but not the sheet itself. Forwarding to the sheet's own setter keeps
  /// in-sheet controls (spinners, toggles, results) live. No-op when no sheet
  /// is open (_refreshSheet is null).
  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _refreshSheet?.call(() {});
  }

  /// Shows a save confirmation where the user can actually see it: a transient
  /// banner inside the open settings sheet, or a SnackBar if no sheet is open.
  void _notifySaved(String msg) {
    if (_refreshSheet != null) {
      _sheetMsgTimer?.cancel();
      _refreshSheet!(() => _sheetMsg = msg);
      _sheetMsgTimer = Timer(const Duration(milliseconds: 2200), () {
        _refreshSheet?.call(() => _sheetMsg = null);
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ---- load from storage ----

  Future<void> _loadSettings() async {
    final settings = ref.read(settingsRepositoryProvider);
    final secure = ref.read(secureStorageProvider);
    final targets = ref.read(targetRepositoryProvider);

    final kindStr = await settings.get('llm_kind');
    final model = await settings.get('llm_model');
    final usdaKey = await settings.get('usda_api_key');
    final localNutritionEnabled =
        await settings.get('local_nutrition_enabled') == 'true';
    NutritionPackState nutritionPackState;
    try {
      nutritionPackState = await ref
          .read(nutritionPackManagerProvider)
          .resolveState();
    } on Object {
      // Resolving the on-disk pack state must never break the whole Settings
      // load (e.g. storage unavailable) — fall back to "not downloaded".
      nutritionPackState = NutritionPackState.notDownloaded;
    }
    final dailyTarget = await targets.get(todayDate());
    final fibreTarget = await settings.get('fibre_target_g');
    final weightUnit = await settings.get(kWeightUnitKey);
    final restSec = await settings.get(kTrainingRestSecKey);
    final adaptiveEnabled = await settings.get(kAdaptiveEnabled);
    final adaptiveGoal = await settings.get(kGoalType);
    final adaptiveRate = await settings.get(kGoalRateKgPerWeek);

    final kind = LlmKind.values.firstWhere(
      (e) => e.name == kindStr,
      orElse: () => LlmKind.claude,
    );

    final apiKeyExists =
        (await secure.read(key: 'llm_api_key_${kind.name}')) != null ||
        (await secure.read(key: 'llm_api_key')) != null;

    final blacklist = await ref.read(generationPrefsStoreProvider).blacklist();
    final goalWeightKg = await ref
        .read(adaptiveMacroServiceProvider)
        .getGoalWeight();
    final currentTrendKg = await ref.read(weightServiceProvider).latestTrend();
    final lbs = (weightUnit ?? 'kg') == 'lb';

    if (mounted) {
      setState(() {
        _selectedKind = kind;
        _localNutritionEnabled = localNutritionEnabled;
        _nutritionPackState = nutritionPackState;
        _modelCtrl.text = model ?? defaultModels[kind]!;
        _usdaKeyCtrl.text = usdaKey ?? '';
        _apiKeyExists = apiKeyExists;
        if (dailyTarget != null) {
          _kcalCtrl.text = dailyTarget.kcal > 0
              ? dailyTarget.kcal.toStringAsFixed(0)
              : '';
          _proteinCtrl.text = dailyTarget.protein > 0
              ? dailyTarget.protein.toStringAsFixed(0)
              : '';
          _carbCtrl.text = dailyTarget.carb > 0
              ? dailyTarget.carb.toStringAsFixed(0)
              : '';
          _fatCtrl.text = dailyTarget.fat > 0
              ? dailyTarget.fat.toStringAsFixed(0)
              : '';
        }
        _fibreTargetCtrl.text = fibreTarget ?? '';
        _weightUnit = weightUnit ?? 'kg';
        _restSecCtrl.text = restSec ?? '$kDefaultRestSec';
        _adaptiveEnabled = adaptiveEnabled == 'true';
        _adaptiveGoal = adaptiveGoal ?? 'maintain';
        _goalRateCtrl.text = adaptiveRate ?? '0.25';
        _currentTrendKg = currentTrendKg;
        _goalWeightCtrl.text = goalWeightKg == null
            ? ''
            : (lbs ? WeightService.kgToLb(goalWeightKg) : goalWeightKg)
                  .toStringAsFixed(1);
        _blacklist = blacklist;
        _loaded = true;
      });
      // If Local was the persisted provider, reflect the real on-disk model
      // state so the card doesn't show a stale "Not downloaded" on first open.
      if (kind == LlmKind.local) {
        await _refreshLocalState();
      }
    }
  }

  // ---- save helpers ----

  Future<void> _saveKind(LlmKind kind) async {
    final settings = ref.read(settingsRepositoryProvider);
    await settings.set('llm_kind', kind.name);
    ref.invalidate(llmProvider);
  }

  Future<void> _saveModel() async {
    final settings = ref.read(settingsRepositoryProvider);
    final model = _modelCtrl.text.trim();
    if (model.isEmpty) return;
    await settings.set('llm_model', model);
    ref.invalidate(llmProvider);
    _notifySaved('Model saved ✓');
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyCtrl.text.trim();
    if (key.isEmpty) {
      _notifySaved('Enter a key first');
      return;
    }
    // Keystore-backed writes can take a beat — show a spinner so the tap
    // doesn't feel ignored.
    setState(() => _savingApiKey = true);
    final secure = ref.read(secureStorageProvider);
    await secure.write(key: _apiKeyStorageKey, value: key);
    await secure.delete(key: 'llm_api_key'); // retire legacy shared key
    _apiKeyCtrl.clear();
    ref.invalidate(llmProvider);
    if (!mounted) return;
    setState(() {
      _apiKeyExists = true;
      _savingApiKey = false;
    });
    _notifySaved('API key saved ✓');
  }

  Future<void> _clearApiKey() async {
    final secure = ref.read(secureStorageProvider);
    await secure.delete(key: _apiKeyStorageKey);
    _apiKeyCtrl.clear();
    ref.invalidate(llmProvider);
    if (!mounted) return;
    setState(() => _apiKeyExists = false);
    _notifySaved('API key cleared');
  }

  Future<void> _saveUsdaKey() async {
    final settings = ref.read(settingsRepositoryProvider);
    await settings.set('usda_api_key', _usdaKeyCtrl.text.trim());
    _notifySaved('USDA key saved ✓');
  }

  Future<void> _saveDailyTargets() async {
    final targets = ref.read(targetRepositoryProvider);
    final settings = ref.read(settingsRepositoryProvider);
    double parse(String s) => double.tryParse(s.trim()) ?? 0;
    final t = DailyTarget(
      kcal: parse(_kcalCtrl.text),
      protein: parse(_proteinCtrl.text),
      carb: parse(_carbCtrl.text),
      fat: parse(_fatCtrl.text),
    );
    await targets.setDefault(t);
    final fibreRaw = _fibreTargetCtrl.text.trim();
    if (fibreRaw.isNotEmpty) {
      await settings.set('fibre_target_g', fibreRaw);
    } else {
      // Empty field → clear the target so the fibre bar disappears again.
      await settings.delete('fibre_target_g');
    }
    _notifySaved('Daily targets saved ✓');
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final llm = await ref.read(llmProvider.future);
      await llm.chat([const ChatMessage('user', 'ping')]);
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testSuccess = true;
        _testResult = 'Connected';
      });
    } on LlmException catch (e) {
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testSuccess = false;
        _testResult = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testing = false;
        _testSuccess = false;
        _testResult = e.toString();
      });
    }
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: HeroCard(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          PhosphorIconsDuotone.gearSix,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Settings',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _settingsSummary(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_loaded)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverToBoxAdapter(child: _settingsGrid(tt)),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Category-tile dashboard
  // ---------------------------------------------------------------------------

  Widget _settingsGrid(TextTheme tt) {
    final kcal = _kcalCtrl.text.trim();
    final name = _selectedKind.name;
    final provider = name.isEmpty
        ? '—'
        : name[0].toUpperCase() + name.substring(1);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _settingsTile(
                icon: PhosphorIconsDuotone.target,
                title: 'Targets & Body',
                subtitle: kcal.isEmpty
                    ? 'Set your goals'
                    : '$kcal kcal · $_weightUnit',
                color: AppColors.protein,
                onTap: () => _openSettingsSheet(
                  'Targets & Body',
                  () => [
                    _buildDailyTargetsSection(tt),
                    const SizedBox(height: 12),
                    _buildAdaptiveTargetsSection(tt),
                    const SizedBox(height: 12),
                    _buildWeightUnitSection(tt),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _settingsTile(
                icon: PhosphorIconsDuotone.sparkle,
                title: 'AI Provider',
                subtitle: _apiKeyExists
                    ? '$provider · key set'
                    : '$provider · no key',
                color: AppColors.accent,
                onTap: () => _openSettingsSheet(
                  'AI Provider',
                  () => [
                    _buildProviderSection(tt),
                    const SizedBox(height: 12),
                    _buildModelSection(tt),
                    const SizedBox(height: 12),
                    if (_selectedKind == LlmKind.local)
                      _buildLocalModelCard(tt)
                    else
                      _buildApiKeySection(tt),
                    const SizedBox(height: 12),
                    _buildTestConnectionSection(tt),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _settingsTile(
                icon: PhosphorIconsDuotone.database,
                title: 'Food Data',
                subtitle: 'USDA · custom foods',
                color: AppColors.carb,
                onTap: () => _openSettingsSheet(
                  'Food Data',
                  () => [
                    _buildNutritionPackSection(tt),
                    const SizedBox(height: 12),
                    _buildUsdaSection(tt),
                    const SizedBox(height: 12),
                    _buildCustomFoodsSection(tt),
                    const SizedBox(height: 12),
                    _buildRefreshFoodDataSection(tt),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _settingsTile(
                icon: PhosphorIconsDuotone.prohibit,
                title: 'Excluded Foods',
                subtitle: _blacklist.isEmpty
                    ? 'None'
                    : '${_blacklist.length} ingredient${_blacklist.length == 1 ? '' : 's'}',
                color: AppColors.fat,
                onTap: () => _openSettingsSheet(
                  'Excluded Foods',
                  () => [_buildBlacklistSection(tt)],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _settingsTile(
          icon: PhosphorIconsDuotone.microphone,
          title: 'Voice',
          subtitle: 'On-device speech',
          color: AppColors.ember,
          wide: true,
          onTap: () => _openSettingsSheet(
            'Voice',
            () => [
              _buildVoicePackSection(tt),
              const SizedBox(height: 12),
              _buildVoiceSection(tt),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _settingsTile(
          icon: PhosphorIconsDuotone.barbell,
          title: 'Training',
          subtitle:
              'Unit · rest timer ${_restSecCtrl.text.isEmpty ? '' : '${_restSecCtrl.text}s'}',
          color: AppColors.protein,
          wide: true,
          onTap: () =>
              _openSettingsSheet('Training', () => [_buildTrainingSection(tt)]),
        ),
        const SizedBox(height: 12),
        _settingsTile(
          icon: PhosphorIconsDuotone.floppyDisk,
          title: 'Backup & Restore',
          subtitle: 'Export or import your data',
          color: AppColors.accent,
          wide: true,
          onTap: () => _openSettingsSheet(
            'Backup & Restore',
            () => [_buildBackupSection(tt)],
          ),
        ),
        const SizedBox(height: 12),
        _settingsTile(
          icon: PhosphorIconsDuotone.heart,
          title: 'Support MacroChef',
          subtitle: 'Optional donation',
          color: AppColors.ember,
          wide: true,
          onTap: () => _openSettingsSheet(
            'Support MacroChef',
            () => [_buildSupportSection(tt)],
          ),
        ),
        const SizedBox(height: 12),
        _settingsTile(
          icon: PhosphorIconsDuotone.info,
          title: 'About',
          subtitle: 'Licenses · privacy policy · credits',
          color: AppColors.carb,
          wide: true,
          onTap: () =>
              _openSettingsSheet('About', () => [_buildAboutSection(tt)]),
        ),
      ],
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool wide = false,
  }) {
    final chip = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
    final titleText = Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        color: AppColors.textHi,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
    final subtitleText = Text(
      subtitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.textMid,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: wide ? 84 : 138,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(24),
        ),
        // Wide tile: icon beside text (horizontal). Square tile: stacked.
        child: wide
            ? Row(
                children: [
                  chip,
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        titleText,
                        const SizedBox(height: 2),
                        subtitleText,
                      ],
                    ),
                  ),
                  const Icon(
                    PhosphorIconsRegular.caretRight,
                    color: AppColors.textLow,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  chip,
                  const Spacer(),
                  titleText,
                  const SizedBox(height: 2),
                  subtitleText,
                ],
              ),
      ),
    );
  }

  /// Opens a category's editor(s) in a scrollable bottom sheet, reusing the
  /// existing section cards (and their controllers/handlers) unchanged.
  /// Opens a settings section in a bottom sheet. [sections] is a *builder* (not
  /// a pre-built list) so the sheet can rebuild itself after a save — that's how
  /// inline statuses (e.g. "Key saved ✓") and the confirmation banner update
  /// while the sheet stays open.
  void _openSettingsSheet(String title, List<Widget> Function() sections) {
    _sheetMsg = null;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          _refreshSheet = setSheet;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.9,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.line,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 14),
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textHi,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (_sheetMsg != null) _sheetBanner(_sheetMsg!),
                    ...sections(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).whenComplete(() => _refreshSheet = null);
  }

  /// Inline green confirmation shown at the top of an open settings sheet.
  Widget _sheetBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.protein.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.protein.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            PhosphorIconsRegular.checkCircle,
            size: 16,
            color: AppColors.protein,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                color: AppColors.textHi,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section builders
  // ---------------------------------------------------------------------------

  /// One-line status shown under the hero title.
  String _settingsSummary() {
    final name = _selectedKind.name;
    final provider = name.isEmpty
        ? 'No AI'
        : name[0].toUpperCase() + name.substring(1);
    final kcal = _kcalCtrl.text.trim();
    final kcalPart = kcal.isEmpty ? 'no calorie target' : '$kcal kcal/day';
    return '$provider · $kcalPart · $_weightUnit';
  }

  /// A consistent section header: a small rounded pastel icon chip followed by
  /// the section title in Plus Jakarta Sans. [accent] rotates across sections
  /// (mint / lavender / peach / coral / navy) for visual variety.
  Widget _sectionHeader(IconData icon, String title, Color accent) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textHi,
            ),
          ),
        ),
      ],
    );
  }

  /// A small rounded pastel icon chip, used as the leading widget for the
  /// ListTile-style sections so they match the section-header chips.
  Widget _leadingChip(IconData icon, Color accent) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: accent),
    );
  }

  Future<void> _openPayPalDonation() async {
    var opened = false;
    try {
      opened = await widget.urlLauncher(Uri.parse(kPayPalDonationUrl));
    } catch (_) {
      // A platform may reject an external launch instead of returning false.
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open PayPal. Please try again later.'),
        ),
      );
    }
  }

  Widget _buildSupportSection(TextTheme tt) {
    return GlassPanel(
      frosted: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            PhosphorIconsDuotone.heart,
            'Support MacroChef',
            AppColors.ember,
          ),
          const SizedBox(height: 12),
          const Text(
            'If MacroChef helps your routine, an optional donation keeps the app growing.',
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Column(
              children: [
                Text(
                  'Scan to donate with InstaPay',
                  style: TextStyle(
                    color: AppColors.textHi,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  child: Image(
                    image: AssetImage('assets/images/seabank-instapay-qr.png'),
                    width: 240,
                    height: 240,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openPayPalDonation,
              icon: const Icon(PhosphorIconsBold.paypalLogo),
              label: const Text('PayPal'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSection(TextTheme tt) {
    return GlassPanel(
      frosted:
          false, // section card in a scrolling list — flat fill avoids jank
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            PhosphorIconsRegular.sparkle,
            'AI Provider',
            AppColors.ember,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<LlmKind>(
            value: _selectedKind,
            dropdownColor: AppColors.surfaceHigh,
            style: const TextStyle(color: AppColors.textHi),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.ember),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: LlmKind.claude,
                child: Text(
                  'Claude',
                  style: TextStyle(color: AppColors.textHi),
                ),
              ),
              DropdownMenuItem(
                value: LlmKind.openai,
                child: Text(
                  'OpenAI',
                  style: TextStyle(color: AppColors.textHi),
                ),
              ),
              DropdownMenuItem(
                value: LlmKind.gemini,
                child: Text(
                  'Gemini',
                  style: TextStyle(color: AppColors.textHi),
                ),
              ),
              DropdownMenuItem(
                value: LlmKind.groq,
                child: Text('Groq', style: TextStyle(color: AppColors.textHi)),
              ),
              DropdownMenuItem(
                value: LlmKind.local,
                child: Text(
                  'Local (on-device)',
                  style: TextStyle(color: AppColors.textHi),
                ),
              ),
            ],
            onChanged: (kind) async {
              if (kind == null) return;
              setState(() {
                _selectedKind = kind;
                // Only update model if empty or was a default
                if (_modelCtrl.text.isEmpty ||
                    defaultModels.values.contains(_modelCtrl.text)) {
                  _modelCtrl.text = defaultModels[kind]!;
                }
              });
              // Persist the model for the new provider so llm_model is never
              // stale/empty (which built a provider with another kind's model).
              final settings = ref.read(settingsRepositoryProvider);
              final secure = ref.read(secureStorageProvider);
              await settings.set('llm_model', _modelCtrl.text.trim());
              await _saveKind(kind);
              if (kind == LlmKind.local) {
                await _refreshLocalState();
              }
              _apiKeyCtrl.clear();
              final hasKey =
                  (await secure.read(key: _apiKeyStorageKey)) != null ||
                  (await secure.read(key: 'llm_api_key')) != null;
              if (mounted) setState(() => _apiKeyExists = hasKey);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModelSection(TextTheme tt) {
    final knownModels = modelsFor(_selectedKind);
    final currentModel = _modelCtrl.text.isEmpty
        ? defaultModelFor(_selectedKind)
        : _modelCtrl.text;
    // Include the current value even if it isn't in the standard list (e.g. a
    // previously saved custom id) so the DropdownButton value is always valid.
    final items = [
      ...knownModels,
      if (!knownModels.contains(currentModel)) currentModel,
    ];
    return GlassPanel(
      frosted:
          false, // section card in a scrolling list — flat fill avoids jank
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(PhosphorIconsRegular.cpu, 'Model', AppColors.carb),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: currentModel,
            dropdownColor: AppColors.surfaceHigh,
            style: const TextStyle(color: AppColors.textHi),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.ember),
              ),
            ),
            items: items
                .map(
                  (m) => DropdownMenuItem<String>(
                    value: m,
                    child: Text(
                      m,
                      style: const TextStyle(color: AppColors.textHi),
                    ),
                  ),
                )
                .toList(),
            onChanged: (newValue) {
              if (newValue == null) return;
              setState(() => _modelCtrl.text = newValue);
              _saveModel();
              if (_selectedKind == LlmKind.local) {
                _refreshLocalState();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeySection(TextTheme tt) {
    return GlassPanel(
      frosted:
          false, // section card in a scrolling list — flat fill avoids jank
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            PhosphorIconsRegular.key,
            'API Key',
            AppColors.protein,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                _apiKeyExists
                    ? PhosphorIconsRegular.checkCircle
                    : PhosphorIconsRegular.info,
                size: 14,
                color: _apiKeyExists ? AppColors.protein : AppColors.textLow,
              ),
              const SizedBox(width: 4),
              Text(
                _apiKeyExists ? 'Key saved ✓' : 'No key set',
                style: TextStyle(
                  color: _apiKeyExists ? AppColors.textMid : AppColors.textLow,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyCtrl,
            obscureText: true,
            style: const TextStyle(color: AppColors.textHi),
            decoration: InputDecoration(
              hintText: 'Enter new API key…',
              hintStyle: const TextStyle(color: AppColors.textLow),
              filled: true,
              fillColor: AppColors.surfaceHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.ember),
              ),
            ),
            onSubmitted: (_) => _saveApiKey(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              PrimaryButton(
                label: _savingApiKey ? 'Saving…' : 'Save key',
                loading: _savingApiKey,
                onPressed: _saveApiKey,
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _apiKeyExists ? _clearApiKey : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocalModelCard(TextTheme tt) {
    final model = localModelById(_modelCtrl.text) ?? localModels.first;
    final controller = LocalDownloadController.instance;
    // Observe the app-lifetime controller directly so progress keeps updating
    // even if this sheet is closed and reopened — the download runs outside the
    // widget tree, so it survives.
    return GlassPanel(
      frosted: false,
      child: ValueListenableBuilder<LocalDownloadState>(
        valueListenable: controller.state,
        builder: (context, ds, _) {
          final sizeGb = (model.sizeBytes / 1e9).toStringAsFixed(1);
          final label = ds.error != null
              ? 'Download failed — tap to retry'
              : switch (ds.status) {
                  LocalModelState.downloaded => 'Downloaded ✓',
                  LocalModelState.partial => 'Incomplete — re-download',
                  LocalModelState.notDownloaded =>
                    'Not downloaded · $sizeGb GB',
                };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                PhosphorIconsRegular.downloadSimple,
                'On-device Model',
                AppColors.carb,
              ),
              const SizedBox(height: 10),
              Text(
                '${model.displayName} · $label',
                style: const TextStyle(color: AppColors.textMid),
              ),
              const SizedBox(height: 10),
              if (ds.downloading)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: ds.progress),
                    const SizedBox(height: 6),
                    Text(
                      '${((ds.progress ?? 0) * 100).toStringAsFixed(0)}%'
                      ' · keeps downloading if you close this',
                      style: const TextStyle(
                        color: AppColors.textMid,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    FilledButton(
                      onPressed: ds.status == LocalModelState.downloaded
                          ? null
                          : () => controller.download(model),
                      child: const Text('Download'),
                    ),
                    const SizedBox(width: 12),
                    if (ds.status != LocalModelState.notDownloaded)
                      OutlinedButton(
                        onPressed: () => controller.delete(model),
                        child: const Text('Delete'),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _refreshLocalState() async {
    final model = localModelById(_modelCtrl.text) ?? localModels.first;
    await LocalDownloadController.instance.refresh(model);
  }

  void _invalidateNutritionLookup() {
    ref.invalidate(nutritionPackStateProvider);
    ref.invalidate(nutritionRetrieverProvider);
    ref.invalidate(foodLookupProvider);
  }

  Future<void> _setLocalNutritionEnabled(bool enabled) async {
    await ref
        .read(settingsRepositoryProvider)
        .set('local_nutrition_enabled', enabled.toString());
    if (!mounted) return;
    setState(() => _localNutritionEnabled = enabled);
    _invalidateNutritionLookup();
    _notifySaved(
      enabled ? 'Local nutrition enabled' : 'Local nutrition disabled',
    );
  }

  Future<void> _downloadNutritionPack() async {
    final manager = ref.read(nutritionPackManagerProvider);
    setState(() {
      _nutritionPackBusy = true;
      _nutritionPackProgress = 0;
      _nutritionPackError = null;
    });
    try {
      await manager.download(
        onProgress: (value) {
          if (mounted) setState(() => _nutritionPackProgress = value);
        },
      );
      final state = await manager.resolveState();
      if (!mounted) return;
      setState(() => _nutritionPackState = state);
      _invalidateNutritionLookup();
      _notifySaved('Nutrition Pack downloaded');
    } on Object catch (error) {
      final state = await manager.resolveState();
      if (!mounted) return;
      setState(() {
        _nutritionPackState = state;
        _nutritionPackError = error is NutritionPackUnavailableException
            ? 'The Nutrition Pack is not published yet. Update MacroChef after '
                  'the pack release, then download it here.'
            : 'Download stopped. Check your connection, then tap Download to '
                  'restart the three-file download. Staged files stay isolated '
                  'from the installed pack.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _nutritionPackBusy = false;
          _nutritionPackProgress = null;
        });
      }
    }
  }

  Future<void> _deleteNutritionPack() async {
    try {
      await ref.read(nutritionPackManagerProvider).delete();
      await ref
          .read(settingsRepositoryProvider)
          .set('local_nutrition_enabled', 'false');
      if (!mounted) return;
      setState(() {
        _nutritionPackState = NutritionPackState.notDownloaded;
        _localNutritionEnabled = false;
        _nutritionPackError = null;
      });
      _invalidateNutritionLookup();
      _notifySaved('Nutrition Pack deleted');
    } on Object {
      if (mounted) {
        setState(
          () => _nutritionPackError =
              'Could not delete the pack. Close active food searches and try again.',
        );
      }
    }
  }

  Widget _buildNutritionPackSection(TextTheme tt) {
    final manager = ref.read(nutritionPackManagerProvider);
    final downloaded = _nutritionPackState == NutritionPackState.downloaded;
    final status = switch (_nutritionPackState) {
      NutritionPackState.downloaded => 'Ready offline',
      NutritionPackState.partial => 'Download incomplete',
      NutritionPackState.notDownloaded => 'Not downloaded',
    };
    final detail = switch (_nutritionPackState) {
      NutritionPackState.downloaded =>
        'Generic USDA foods and MiniLM search are stored on this device.',
      NutritionPackState.partial =>
        'Tap Download to safely replace the incomplete files.',
      NutritionPackState.notDownloaded =>
        manager.canDownload
            ? 'Download generic USDA foods and MiniLM search for on-device lookup.'
            : 'Pack publishing is pending. Online USDA, OpenFoodFacts, and your AI provider still work.',
    };
    return GlassPanel(
      frosted: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            PhosphorIconsRegular.database,
            'Nutrition Pack',
            AppColors.carb,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: downloaded ? AppColors.carb : AppColors.line,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: tt.titleSmall?.copyWith(
                    color: downloaded ? AppColors.carb : AppColors.textHi,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: tt.bodySmall?.copyWith(color: AppColors.textMid),
                ),
              ],
            ),
          ),
          if (_nutritionPackBusy) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _nutritionPackProgress),
            const SizedBox(height: 6),
            Text(
              '${((_nutritionPackProgress ?? 0) * 100).toStringAsFixed(0)}% · '
              'Keep MacroChef open until all three files finish.',
              style: tt.bodySmall?.copyWith(color: AppColors.textMid),
            ),
          ],
          if (_nutritionPackError != null) ...[
            const SizedBox(height: 10),
            Text(
              _nutritionPackError!,
              style: tt.bodySmall?.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton(
                onPressed:
                    _nutritionPackBusy || downloaded || !manager.canDownload
                    ? null
                    : _downloadNutritionPack,
                child: Text(
                  _nutritionPackState == NutritionPackState.partial
                      ? 'Download again'
                      : 'Download',
                ),
              ),
              const SizedBox(width: 10),
              if (_nutritionPackState != NutritionPackState.notDownloaded)
                OutlinedButton(
                  onPressed: _nutritionPackBusy ? null : _deleteNutritionPack,
                  child: const Text('Delete pack'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Use local nutrition first'),
            subtitle: const Text(
              'When ready, food searches use this device before online services.',
            ),
            value: _localNutritionEnabled,
            onChanged: downloaded ? _setLocalNutritionEnabled : null,
          ),
          Text(
            'Data source: USDA FoodData Central · Foundation and SR Legacy.',
            style: tt.bodySmall?.copyWith(color: AppColors.textLow),
          ),
        ],
      ),
    );
  }

  Widget _buildUsdaSection(TextTheme tt) {
    return GlassPanel(
      frosted:
          false, // section card in a scrolling list — flat fill avoids jank
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            PhosphorIconsRegular.database,
            'USDA API Key',
            AppColors.fat,
          ),
          const SizedBox(height: 10),
          Text(
            'Optional — enables USDA food database.',
            style: tt.bodySmall?.copyWith(color: AppColors.textLow),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _usdaKeyCtrl,
            obscureText: true,
            style: const TextStyle(color: AppColors.textHi),
            decoration: InputDecoration(
              hintText: 'Enter USDA API key…',
              hintStyle: const TextStyle(color: AppColors.textLow),
              filled: true,
              fillColor: AppColors.surfaceHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.ember),
              ),
            ),
            onSubmitted: (_) => _saveUsdaKey(),
          ),
          const SizedBox(height: 12),
          PrimaryButton(label: 'Save USDA key', onPressed: _saveUsdaKey),
        ],
      ),
    );
  }

  Widget _buildCustomFoodsSection(TextTheme tt) {
    return GlassPanel(
      frosted: false,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: _leadingChip(PhosphorIconsRegular.carrot, AppColors.fat),
        title: Text(
          'Custom foods',
          style: tt.bodyMedium?.copyWith(
            color: AppColors.textHi,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Your saved custom foods',
          style: tt.bodySmall?.copyWith(color: AppColors.textMid),
        ),
        trailing: const Icon(
          PhosphorIconsRegular.caretRight,
          color: AppColors.textLow,
          size: 18,
        ),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CustomFoodsScreen())),
      ),
    );
  }

  Future<void> _refreshFoodData() async {
    final removed = await ref
        .read(foodCacheRepositoryProvider)
        .clearNonOverrides();
    if (!mounted) return;
    _notifySaved(
      removed == 0
          ? 'No cached foods to refresh.'
          : 'Cleared $removed cached food${removed == 1 ? '' : 's'} — they\'ll '
                're-resolve (USDA first) next time. Overrides kept.',
    );
  }

  Widget _buildRefreshFoodDataSection(TextTheme tt) {
    return GlassPanel(
      frosted: false,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: _leadingChip(
          PhosphorIconsRegular.arrowsClockwise,
          AppColors.accent,
        ),
        title: Text(
          'Refresh food data',
          style: tt.bodyMedium?.copyWith(
            color: AppColors.textHi,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Clear auto-looked-up values so they re-fetch (USDA first). '
          'Keeps your custom overrides.',
          style: tt.bodySmall?.copyWith(color: AppColors.textMid),
        ),
        trailing: const Icon(
          PhosphorIconsRegular.arrowClockwise,
          color: AppColors.textLow,
          size: 18,
        ),
        onTap: _refreshFoodData,
      ),
    );
  }

  /// Best-effort external link; silently no-ops if no browser/mail app.
  Future<void> _openLink(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Widget _aboutLinkTile(
    TextTheme tt, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _leadingChip(icon, color),
      title: Text(
        title,
        style: tt.bodyMedium?.copyWith(
          color: AppColors.textHi,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: tt.bodySmall?.copyWith(color: AppColors.textMid),
      ),
      trailing: const Icon(
        PhosphorIconsRegular.caretRight,
        color: AppColors.textLow,
        size: 18,
      ),
      onTap: onTap,
    );
  }

  /// About: privacy policy, package licenses, and the attributions the app's
  /// data/artwork licenses require (Open Food Facts is ODbL, the anatomy SVGs
  /// are CC BY 4.0 — both need user-visible credit, not just a repo file).
  Widget _buildAboutSection(TextTheme tt) {
    return GlassPanel(
      frosted: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            PhosphorIconsRegular.info,
            'About MacroChef',
            AppColors.carb,
          ),
          const SizedBox(height: 6),
          Text(
            'Voice-driven macro tracking and hands-free cooking.',
            style: tt.bodySmall?.copyWith(color: AppColors.textMid),
          ),
          const SizedBox(height: 8),
          _aboutLinkTile(
            tt,
            icon: PhosphorIconsRegular.shieldCheck,
            color: AppColors.protein,
            title: 'Privacy policy',
            subtitle: 'How your data is handled (spoiler: it stays with you)',
            onTap: () => _openLink(kPrivacyPolicyUrl),
          ),
          _aboutLinkTile(
            tt,
            icon: PhosphorIconsRegular.scroll,
            color: AppColors.accent,
            title: 'Open-source licenses',
            subtitle: 'Licenses of the packages this app is built on',
            onTap: () =>
                showLicensePage(context: context, applicationName: 'MacroChef'),
          ),
          _aboutLinkTile(
            tt,
            icon: PhosphorIconsRegular.database,
            color: AppColors.carb,
            title: 'Open Food Facts',
            subtitle: 'Some food data © Open Food Facts contributors (ODbL)',
            onTap: () => _openLink(kOpenFoodFactsUrl),
          ),
          _aboutLinkTile(
            tt,
            icon: PhosphorIconsRegular.envelopeSimple,
            color: AppColors.ember,
            title: 'Contact & feedback',
            subtitle: kSupportEmail,
            onTap: () => _openLink('mailto:$kSupportEmail?subject=MacroChef'),
          ),
          const SizedBox(height: 8),
          Text(
            'Credits\n'
            '• Food data: USDA FoodData Central (public domain) and Open Food '
            'Facts, licensed under the Open Database License (ODbL).\n'
            '• Anatomy artwork: flutter-body-atlas by Kit G — artwork CC BY 4.0, '
            'code BSD-3-Clause. Used unmodified.\n'
            '• On-device speech: sherpa-onnx (Apache 2.0) running Whisper '
            'base.en, Silero VAD and VITS-LJSpeech models.\n'
            '• Recipes and food estimates can be AI-generated — always verify '
            'nutrition-critical values.',
            style: tt.bodySmall?.copyWith(
              color: AppColors.textMid,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSection(TextTheme tt) {
    return GlassPanel(
      frosted: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            PhosphorIconsRegular.floppyDisk,
            'Backup & Restore',
            AppColors.accent,
          ),
          const SizedBox(height: 8),
          Text(
            'Your data lives only on this phone. Export a backup to Drive or '
            'Files so it survives a reinstall or a new device, and import it to '
            'restore.',
            style: tt.bodySmall?.copyWith(
              color: AppColors.textMid,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<String?>(
            future: ref
                .read(settingsRepositoryProvider)
                .get(kLastDriveBackupMsKey),
            builder: (context, snap) {
              final ms = int.tryParse(snap.data ?? '');
              final last = ms == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(ms);
              if (!isDriveBackupStale(lastDrive: last, now: DateTime.now())) {
                return const SizedBox.shrink();
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.ember.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.ember.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.ember,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        last == null
                            ? 'No offsite backup yet — export one to Drive so your data survives a reinstall.'
                            : 'Your last Drive backup is over a week old. Export a fresh one.',
                        style: tt.bodySmall?.copyWith(color: AppColors.textHi),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _leadingChip(
              PhosphorIconsRegular.export,
              AppColors.protein,
            ),
            title: Text(
              'Export backup',
              style: tt.bodyMedium?.copyWith(
                color: AppColors.textHi,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Save a snapshot of all your data.',
              style: tt.bodySmall?.copyWith(color: AppColors.textMid),
            ),
            trailing: _backupBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  )
                : const Icon(
                    PhosphorIconsRegular.caretRight,
                    color: AppColors.textLow,
                    size: 18,
                  ),
            onTap: _backupBusy ? null : _exportBackup,
          ),
          const Divider(color: AppColors.line, height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _leadingChip(
              PhosphorIconsRegular.downloadSimple,
              AppColors.fat,
            ),
            title: Text(
              'Import backup',
              style: tt.bodyMedium?.copyWith(
                color: AppColors.textHi,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Replace current data with a backup file.',
              style: tt.bodySmall?.copyWith(color: AppColors.textMid),
            ),
            trailing: const Icon(
              PhosphorIconsRegular.caretRight,
              color: AppColors.textLow,
              size: 18,
            ),
            onTap: _backupBusy ? null : _importBackup,
          ),
          const Divider(color: AppColors.line, height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _leadingChip(
              PhosphorIconsRegular.clockCounterClockwise,
              AppColors.carb,
            ),
            title: Text(
              'Recover latest automatic backup',
              style: tt.bodyMedium?.copyWith(
                color: AppColors.textHi,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Find the newest backup in Downloads/MacroChef and stage it for restart.',
              style: tt.bodySmall?.copyWith(color: AppColors.textMid),
            ),
            trailing: const Icon(
              PhosphorIconsRegular.caretRight,
              color: AppColors.textLow,
              size: 18,
            ),
            onTap: _backupBusy ? null : _recoverLatestAutomaticBackup,
          ),
        ],
      ),
    );
  }

  Future<void> _recoverLatestAutomaticBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Restore latest automatic backup?',
          style: TextStyle(color: AppColors.textHi),
        ),
        content: const Text(
          'This replaces the current MacroChef data with the newest valid backup '
          'from Downloads/MacroChef after you restart the app.',
          style: TextStyle(color: AppColors.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restore backup'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _backupBusy = true);
    try {
      final service = widget.recoveryService ?? await _defaultRecoveryService();
      final result = await service.recoverLatest();
      if (!mounted) return;
      if (!result.staged) {
        _notifySaved(result.message ?? 'Recovery could not be staged.');
        return;
      }
      await _showRestoreReadyDialog();
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<SettingsRecoveryService> _defaultRecoveryService() async {
    final support = await getApplicationSupportDirectory();
    final temporary = await getTemporaryDirectory();
    return DefaultSettingsRecoveryService(
      shared: ref.read(sharedStorageProvider),
      stageRestore: ref.read(backupServiceProvider).stageRestore,
      bootstrapStore: RecoveryBootstrapStore(
        File(p.join(support.path, 'recovery-bootstrap-v1.json')),
      ),
      workingDirectory: Directory(p.join(temporary.path, 'recovery')),
    );
  }

  Future<void> _showRestoreReadyDialog() => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Restore ready',
        style: TextStyle(color: AppColors.textHi),
      ),
      content: const Text(
        'Your backup is staged. Close MacroChef completely (swipe it away) '
        'and reopen it to finish restoring your data.',
        style: TextStyle(color: AppColors.textMid),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Later'),
        ),
        TextButton(
          onPressed: () => SystemNavigator.pop(),
          child: const Text(
            'Close app now',
            style: TextStyle(color: AppColors.ember),
          ),
        ),
      ],
    ),
  );

  /// Export the whole database as a shareable `.sqlite` snapshot.
  Future<void> _exportBackup() async {
    setState(() => _backupBusy = true);
    try {
      final backup = ref.read(backupServiceProvider);
      final tmp = await getTemporaryDirectory();
      final dest = File(
        p.join(tmp.path, BackupService.suggestedFileName(DateTime.now())),
      );
      await backup.exportTo(dest);
      await Share.shareXFiles(
        [XFile(dest.path, mimeType: 'application/x-sqlite3')],
        subject: 'MacroChef backup',
        text: 'MacroChef data backup — keep this file to restore your data.',
      );
      // Record the offsite backup so the "backup is stale" reminder resets.
      await ref
          .read(settingsRepositoryProvider)
          .set(
            kLastDriveBackupMsKey,
            DateTime.now().millisecondsSinceEpoch.toString(),
          );
      if (mounted) setState(() {}); // refresh the reminder banner
    } catch (e) {
      _notifySaved('Export failed: $e');
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  /// Pick a backup file, validate it, and stage it to be swapped in on the next
  /// launch (the live DB can't be replaced while it's open).
  Future<void> _importBackup() async {
    final picked = await FilePicker.platform.pickFiles(withData: false);
    final files = picked?.files ?? const [];
    final path = files.isEmpty ? null : files.first.path;
    if (path == null) return;
    setState(() => _backupBusy = true);
    try {
      final ok = await ref.read(backupServiceProvider).stageRestore(File(path));
      if (!mounted) return;
      if (!ok) {
        _notifySaved("That file isn't a MacroChef backup.");
        return;
      }
      await _showRestoreReadyDialog();
    } catch (e) {
      if (mounted) _notifySaved('Import failed: $e');
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Widget _buildDailyTargetsSection(TextTheme tt) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.ember),
      ),
    );

    return GlassPanel(
      frosted:
          false, // section card in a scrolling list — flat fill avoids jank
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            PhosphorIconsRegular.target,
            'Daily Targets',
            AppColors.ember,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TargetField(
                  controller: _kcalCtrl,
                  label: 'kcal',
                  color: AppColors.ember,
                  decoration: inputDecoration,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TargetField(
                  controller: _proteinCtrl,
                  label: 'Protein',
                  color: AppColors.protein,
                  decoration: inputDecoration,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TargetField(
                  controller: _carbCtrl,
                  label: 'Carbs',
                  color: AppColors.carb,
                  decoration: inputDecoration,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TargetField(
                  controller: _fatCtrl,
                  label: 'Fat',
                  color: AppColors.fat,
                  decoration: inputDecoration,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _TargetField(
            controller: _fibreTargetCtrl,
            label: 'Fibre (g) · optional',
            color: AppColors.protein.withValues(alpha: 0.8),
            decoration: inputDecoration,
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Save targets', onPressed: _saveDailyTargets),
        ],
      ),
    );
  }

  Widget _buildWeightUnitSection(TextTheme tt) {
    return GlassPanel(
      frosted: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            PhosphorIconsRegular.scales,
            'Weight Unit',
            AppColors.carb,
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'kg', label: Text('kg')),
              ButtonSegment(value: 'lb', label: Text('lb')),
            ],
            selected: {_weightUnit},
            onSelectionChanged: (sel) async {
              final unit = sel.first;
              setState(() => _weightUnit = unit);
              await ref.read(weightServiceProvider).setUnit(unit);
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.surfaceHigh,
              selectedBackgroundColor: AppColors.ember,
              selectedForegroundColor: AppColors.canvas,
              foregroundColor: AppColors.textMid,
              side: const BorderSide(color: AppColors.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTrainingRest() async {
    final settings = ref.read(settingsRepositoryProvider);
    var secs = int.tryParse(_restSecCtrl.text.trim()) ?? kDefaultRestSec;
    if (secs < 5) secs = 5;
    if (secs > 600) secs = 600;
    _restSecCtrl.text = '$secs';
    await settings.set(kTrainingRestSecKey, '$secs');
    _notifySaved('Rest timer set to ${secs}s ✓');
  }

  Widget _buildTrainingSection(TextTheme tt) {
    const labelStyle = TextStyle(
      color: AppColors.ember,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    return GlassPanel(
      frosted: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            PhosphorIconsRegular.barbell,
            'Training',
            AppColors.protein,
          ),
          const SizedBox(height: 14),
          const Text('Default weight unit', style: labelStyle),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'kg', label: Text('kg')),
              ButtonSegment(value: 'lb', label: Text('lb')),
            ],
            selected: {_weightUnit},
            onSelectionChanged: (sel) async {
              final unit = sel.first;
              setState(() => _weightUnit = unit);
              await ref.read(weightServiceProvider).setUnit(unit);
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.surfaceHigh,
              selectedBackgroundColor: AppColors.ember,
              selectedForegroundColor: AppColors.canvas,
              foregroundColor: AppColors.textMid,
              side: const BorderSide(color: AppColors.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pre-fills new set rows and voice logging. (Also the unit for '
            'the body-weight card.)',
            style: tt.bodySmall?.copyWith(color: AppColors.textLow),
          ),
          const SizedBox(height: 16),
          const Text('Default rest timer', style: labelStyle),
          const SizedBox(height: 6),
          TextField(
            controller: _restSecCtrl,
            keyboardType: const TextInputType.numberWithOptions(),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            ],
            style: tabularFigures.copyWith(color: AppColors.textHi),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceHigh,
              suffixText: 'sec',
              suffixStyle: const TextStyle(
                color: AppColors.textMid,
                fontSize: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.ember),
              ),
            ),
            onSubmitted: (_) => _saveTrainingRest(),
          ),
          const SizedBox(height: 4),
          Text(
            'Default rest between sets in the logger, and when you say '
            '"rest" with no number in a voice workout. A tone + vibration '
            'fires when it ends, even with the app in the background.',
            style: tt.bodySmall?.copyWith(color: AppColors.textLow),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Save rest length',
            onPressed: _saveTrainingRest,
          ),
        ],
      ),
    );
  }

  /// Persists the goal weight (converting display unit → kg) and, when the
  /// current trend weight is known, auto-derives the lose/maintain/gain goal.
  Future<void> _saveGoalWeight(String v) async {
    final svc = ref.read(adaptiveMacroServiceProvider);
    final entered = double.tryParse(v.trim());
    if (entered == null || entered <= 0) {
      await svc.setGoalWeight(null);
      return;
    }
    final kg = _weightUnit == 'lb' ? WeightService.lbToKg(entered) : entered;
    await svc.setGoalWeight(kg);
    final cur = _currentTrendKg;
    if (cur != null) {
      final goal = AdaptiveMacroService.goalFromWeights(cur, kg);
      await svc.setGoal(goal);
      if (mounted) setState(() => _adaptiveGoal = goal);
    }
  }

  /// Shows the current trend weight (the adaptive anchor), a goal-weight field,
  /// and a derived "lose/gain · N to go" hint.
  Widget _adaptiveWeightAnchor(TextTheme tt, InputDecoration inputDecoration) {
    final unit = _weightUnit;
    final lbs = unit == 'lb';
    final cur = _currentTrendKg;
    final curDisp = cur == null
        ? null
        : (lbs ? WeightService.kgToLb(cur) : cur);

    final goalEntered = double.tryParse(_goalWeightCtrl.text.trim());
    String? progress;
    if (cur != null && goalEntered != null && goalEntered > 0) {
      final goalKg = lbs ? WeightService.lbToKg(goalEntered) : goalEntered;
      final dir = AdaptiveMacroService.goalFromWeights(cur, goalKg);
      final remainingKg = (goalKg - cur).abs();
      final remainingDisp = lbs
          ? WeightService.kgToLb(remainingKg)
          : remainingKg;
      progress = dir == 'maintain'
          ? 'At your goal weight'
          : '${dir == 'lose' ? 'Lose' : 'Gain'} · '
                '${remainingDisp.toStringAsFixed(1)} $unit to go';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              PhosphorIconsDuotone.scales,
              size: 16,
              color: AppColors.textMid,
            ),
            const SizedBox(width: 8),
            Text(
              curDisp != null
                  ? 'Current ${curDisp.toStringAsFixed(1)} $unit (trend)'
                  : 'No weight logged yet',
              style: TextStyle(
                color: curDisp != null ? AppColors.textMid : AppColors.textLow,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (curDisp == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Log your weight on the Today tab so adaptive can track your trend.',
              style: tt.bodySmall?.copyWith(color: AppColors.textLow),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Goal weight',
          style: const TextStyle(
            color: AppColors.ember,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _goalWeightCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          style: tabularFigures.copyWith(color: AppColors.textHi),
          decoration: inputDecoration.copyWith(
            hintText: 'e.g. 75',
            hintStyle: const TextStyle(color: AppColors.textLow),
            suffixText: unit,
            suffixStyle: const TextStyle(
              color: AppColors.textMid,
              fontSize: 12,
            ),
          ),
          onChanged: (v) {
            _saveGoalWeight(v);
            setState(() {}); // refresh the derived hint live
          },
        ),
        if (progress != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(
                  PhosphorIconsRegular.flagBanner,
                  size: 14,
                  color: AppColors.ember,
                ),
                const SizedBox(width: 6),
                Text(
                  progress,
                  style: const TextStyle(
                    color: AppColors.ember,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAdaptiveTargetsSection(TextTheme tt) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.ember),
      ),
    );

    return GlassPanel(
      frosted: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            PhosphorIconsRegular.chartLineUp,
            'Adaptive Targets',
            AppColors.protein,
          ),
          const SizedBox(height: 10),
          Text(
            'Recalculates your daily calorie/macro targets weekly from '
            'trend-weight change vs. your goal.',
            style: tt.bodySmall?.copyWith(color: AppColors.textLow),
          ),
          const SizedBox(height: 12),
          // Enable switch
          SwitchListTile(
            value: _adaptiveEnabled,
            onChanged: (v) async {
              setState(() => _adaptiveEnabled = v);
              await ref.read(adaptiveMacroServiceProvider).setEnabled(v);
            },
            activeColor: AppColors.ember,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Enable adaptive recalculation',
              style: tt.bodyMedium?.copyWith(color: AppColors.textHi),
            ),
          ),
          const SizedBox(height: 14),
          // Current-weight anchor + goal weight
          _adaptiveWeightAnchor(tt, inputDecoration),
          const SizedBox(height: 14),
          // Goal selector
          Text(
            'Goal',
            style: TextStyle(
              color: AppColors.ember,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'lose', label: Text('Lose')),
              ButtonSegment(value: 'maintain', label: Text('Maintain')),
              ButtonSegment(value: 'gain', label: Text('Gain')),
            ],
            selected: {_adaptiveGoal},
            onSelectionChanged: (sel) async {
              final goal = sel.first;
              setState(() => _adaptiveGoal = goal);
              await ref.read(adaptiveMacroServiceProvider).setGoal(goal);
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.surfaceHigh,
              selectedBackgroundColor: AppColors.ember,
              selectedForegroundColor: AppColors.canvas,
              foregroundColor: AppColors.textMid,
              side: const BorderSide(color: AppColors.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Rate field
          Text(
            'Rate (kg/week)',
            style: TextStyle(
              color: AppColors.ember,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _goalRateCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: tabularFigures.copyWith(color: AppColors.textHi),
            decoration: inputDecoration.copyWith(
              hintText: '0.25',
              hintStyle: const TextStyle(color: AppColors.textLow),
              suffixText: 'kg/wk',
              suffixStyle: const TextStyle(
                color: AppColors.textMid,
                fontSize: 12,
              ),
            ),
            onSubmitted: (v) async {
              final rate = double.tryParse(v);
              if (rate != null && rate > 0) {
                await ref.read(adaptiveMacroServiceProvider).setGoalRate(rate);
              }
            },
          ),
          const SizedBox(height: 16),
          // Recalculate button
          PrimaryButton(
            label: 'Recalculate now',
            onPressed: _adaptiveRunning
                ? null
                : () async {
                    // Persist rate before computing
                    final rate =
                        double.tryParse(_goalRateCtrl.text.trim()) ?? 0.25;
                    await ref
                        .read(adaptiveMacroServiceProvider)
                        .setGoalRate(rate);
                    setState(() {
                      _adaptiveRunning = true;
                      _adaptiveResult = null;
                    });
                    try {
                      final result = await ref
                          .read(adaptiveMacroServiceProvider)
                          .recompute();
                      if (mounted) {
                        setState(() {
                          _adaptiveRunning = false;
                          _adaptiveResult = result;
                          _adaptiveComputed = true;
                        });
                        if (result != null) {
                          // Refresh displayed targets
                          _kcalCtrl.text = result.kcal.toStringAsFixed(0);
                          _proteinCtrl.text = result.protein.toStringAsFixed(0);
                          _carbCtrl.text = result.carb.toStringAsFixed(0);
                          _fatCtrl.text = result.fat.toStringAsFixed(0);
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() => _adaptiveRunning = false);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
          ),
          if (_adaptiveRunning) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.ember,
                  ),
                ),
                SizedBox(width: 8),
                Text('Computing…', style: TextStyle(color: AppColors.textMid)),
              ],
            ),
          ],
          if (!_adaptiveRunning && _adaptiveResult != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  PhosphorIconsRegular.checkCircle,
                  size: 16,
                  color: AppColors.protein,
                ),
                const SizedBox(width: 6),
                Text(
                  'New target: ${_adaptiveResult!.kcal.toStringAsFixed(0)} kcal',
                  style: const TextStyle(color: AppColors.textHi),
                ),
              ],
            ),
          ],
          // Only after an actual recompute that returned null — not on first
          // load before the user has ever pressed "Recalculate now".
          if (!_adaptiveRunning &&
              _adaptiveComputed &&
              _adaptiveResult == null &&
              _adaptiveEnabled) ...[
            const SizedBox(height: 8),
            Text(
              'Not enough data yet (need 7+ weight entries and food logs).',
              style: tt.bodySmall?.copyWith(color: AppColors.textLow),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addBlacklistItem() async {
    final item = _blacklistCtrl.text.trim();
    if (item.isEmpty) return;
    if (_blacklist.any((e) => e.toLowerCase() == item.toLowerCase())) {
      _blacklistCtrl.clear();
      return;
    }
    final next = [..._blacklist, item];
    await ref.read(generationPrefsStoreProvider).setBlacklist(next);
    setState(() {
      _blacklist = next;
      _blacklistCtrl.clear();
    });
  }

  Future<void> _removeBlacklistItem(String item) async {
    final next = _blacklist.where((e) => e != item).toList();
    await ref.read(generationPrefsStoreProvider).setBlacklist(next);
    setState(() => _blacklist = next);
  }

  Widget _buildBlacklistSection(TextTheme tt) {
    return GlassPanel(
      frosted: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            PhosphorIconsRegular.prohibit,
            'Excluded ingredients',
            AppColors.accent,
          ),
          const SizedBox(height: 10),
          Text(
            'The recipe generator will never use these.',
            style: tt.bodySmall?.copyWith(color: AppColors.textLow),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _blacklistCtrl,
                  style: const TextStyle(color: AppColors.textHi),
                  decoration: InputDecoration(
                    hintText: 'e.g. cilantro',
                    hintStyle: const TextStyle(color: AppColors.textLow),
                    filled: true,
                    fillColor: AppColors.surfaceHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.ember),
                    ),
                  ),
                  onSubmitted: (_) => _addBlacklistItem(),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(
                  PhosphorIconsBold.plus,
                  color: AppColors.ember,
                ),
                onPressed: _addBlacklistItem,
              ),
            ],
          ),
          if (_blacklist.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _blacklist
                  .map(
                    (item) => Chip(
                      label: Text(
                        item,
                        style: const TextStyle(color: AppColors.textHi),
                      ),
                      backgroundColor: AppColors.surfaceHigh,
                      side: const BorderSide(color: AppColors.line),
                      deleteIconColor: AppColors.textMid,
                      onDeleted: () => _removeBlacklistItem(item),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceSection(TextTheme tt) {
    return GlassPanel(
      frosted:
          false, // section card in a scrolling list — flat fill avoids jank
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            PhosphorIconsRegular.microphone,
            'Voice',
            AppColors.fat,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                PhosphorIconsRegular.checkCircle,
                size: 14,
                color: AppColors.protein,
              ),
              const SizedBox(width: 4),
              Text(
                'On-device voice ready',
                style: TextStyle(color: AppColors.textMid, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Test voice',
            onPressed: () async {
              final speech = ref.read(speechProvider);
              try {
                await speech.init();
                await speech.speak('Voice is ready.');
              } catch (e) {
                // init() throws when the Voice Pack isn't downloaded.
                _notifySaved('Download the Voice Pack first.');
              }
            },
          ),
        ],
      ),
    );
  }

  void _refreshVoiceState() =>
      _voiceStateFuture = ref.read(voiceModelManagerProvider).state();

  Future<void> _downloadVoicePack() async {
    final mgr = ref.read(voiceModelManagerProvider);
    setState(() => _voiceProgress = 0);
    try {
      var lastPct = -1;
      await mgr.download(
        onProgress: (prog) {
          if (!mounted) return;
          // A 266 MB stream fires thousands of chunk callbacks — rebuild only when
          // the whole-percent figure actually changes.
          final pct = (prog * 100).floor();
          if (pct == lastPct) return;
          lastPct = pct;
          setState(() => _voiceProgress = prog);
        },
      );
      _notifySaved('Voice pack downloaded ✓');
    } catch (e) {
      // Leave any partial files so a retry resumes via the size check.
      _notifySaved('Voice pack download failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _voiceProgress = null;
          _refreshVoiceState();
        });
      }
    }
  }

  Future<void> _deleteVoicePack() async {
    await ref.read(voiceModelManagerProvider).delete();
    if (!mounted) return;
    setState(_refreshVoiceState);
    _notifySaved('Voice pack deleted');
  }

  /// Download/state/delete card for the optional Voice Pack, modeled on the
  /// on-device model card. Reports aggregate progress while downloading.
  Widget _buildVoicePackSection(TextTheme tt) {
    _voiceStateFuture ??= ref.read(voiceModelManagerProvider).state();
    final downloading = _voiceProgress != null;
    return GlassPanel(
      frosted: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            PhosphorIconsRegular.downloadSimple,
            'Voice Pack',
            AppColors.ember,
          ),
          const SizedBox(height: 6),
          Text(
            '~266 MB · required for hands-free cooking',
            style: tt.bodySmall?.copyWith(color: AppColors.textLow),
          ),
          const SizedBox(height: 12),
          FutureBuilder<VoiceState>(
            future: _voiceStateFuture,
            builder: (context, snap) {
              final state = snap.data;
              final label = switch (state) {
                VoiceState.ready => 'Downloaded ✓',
                VoiceState.partial => 'Incomplete — re-download to finish',
                VoiceState.notDownloaded => 'Not downloaded',
                null => 'Checking…',
              };
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        state == VoiceState.ready
                            ? PhosphorIconsRegular.checkCircle
                            : PhosphorIconsRegular.info,
                        size: 14,
                        color: state == VoiceState.ready
                            ? AppColors.protein
                            : AppColors.textLow,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.textMid,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (downloading)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(value: _voiceProgress),
                        const SizedBox(height: 6),
                        Text(
                          '${((_voiceProgress ?? 0) * 100).toStringAsFixed(0)}%'
                          ' · keep this screen open',
                          style: const TextStyle(
                            color: AppColors.textMid,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        PrimaryButton(
                          label: state == VoiceState.ready
                              ? 'Downloaded'
                              : 'Download',
                          onPressed: state == VoiceState.ready
                              ? null
                              : _downloadVoicePack,
                        ),
                        const SizedBox(width: 12),
                        if (state != null && state != VoiceState.notDownloaded)
                          OutlinedButton(
                            onPressed: _deleteVoicePack,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTestConnectionSection(TextTheme tt) {
    return GlassPanel(
      frosted:
          false, // section card in a scrolling list — flat fill avoids jank
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            PhosphorIconsRegular.plugs,
            'Connection',
            AppColors.accent,
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: _testing ? 'Testing…' : 'Test connection',
            loading: _testing,
            onPressed: _testing ? null : _testConnection,
          ),
          if (_testing) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.ember,
                  ),
                ),
                SizedBox(width: 8),
                Text('Testing…', style: TextStyle(color: AppColors.textMid)),
              ],
            ),
          ],
          if (!_testing && _testResult != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _testSuccess
                      ? PhosphorIconsRegular.checkCircle
                      : PhosphorIconsRegular.xCircle,
                  size: 18,
                  color: _testSuccess ? AppColors.protein : AppColors.danger,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _testResult!,
                    style: const TextStyle(color: AppColors.textHi),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TargetField — labelled numeric input using tabularFigures
// ---------------------------------------------------------------------------

class _TargetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color color;
  final InputDecoration decoration;

  const _TargetField({
    required this.controller,
    required this.label,
    required this.color,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: tabularFigures.copyWith(color: AppColors.textHi),
          decoration: decoration.copyWith(
            hintText: '0',
            hintStyle: const TextStyle(color: AppColors.textLow),
          ),
        ),
      ],
    );
  }
}
