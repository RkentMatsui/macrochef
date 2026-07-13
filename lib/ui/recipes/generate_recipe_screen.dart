import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_links.dart';
import '../../models/macros.dart';
import '../../models/recipe_preset.dart';
import '../../services/recipe_generator_service.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../widgets/cards.dart';
import '../widgets/glass_panel.dart';
import '../widgets/primary_button.dart';

// ---------------------------------------------------------------------------
// GenerateRecipeScreen
// ---------------------------------------------------------------------------

class GenerateRecipeScreen extends ConsumerStatefulWidget {
  const GenerateRecipeScreen({super.key});

  @override
  ConsumerState<GenerateRecipeScreen> createState() =>
      _GenerateRecipeScreenState();
}

enum _TargetMode { remaining, full }

class _GenerateRecipeScreenState extends ConsumerState<GenerateRecipeScreen> {
  final _promptCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController(text: '0');
  final _proteinCtrl = TextEditingController(text: '0');
  final _carbCtrl = TextEditingController(text: '0');
  final _fatCtrl = TextEditingController(text: '0');
  final _servingsCtrl = TextEditingController(text: '1');
  final _daysCtrl = TextEditingController(text: '1');

  _TargetMode _mode = _TargetMode.remaining;
  bool _loading = false;
  GeneratedRecipe? _result;
  List<RecipePreset> _presets = [];
  String? _pinnedIngredient; // armed from a tapped preset

  // Cached totals for the two modes
  MacroValues _remainingTarget = MacroValues.zero;
  MacroValues _fullTarget = MacroValues.zero;

  @override
  void initState() {
    super.initState();
    _fetchTotals();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final presets = await ref.read(generationPrefsStoreProvider).presets();
    if (mounted) setState(() => _presets = presets);
  }

  void _applyPreset(RecipePreset p) {
    setState(() {
      _promptCtrl.text = p.prompt;
      _pinnedIngredient = p.pinnedIngredient;
    });
  }

  Future<void> _savePresetDialog() async {
    final labelCtrl = TextEditingController(
        text: _promptCtrl.text.trim().isEmpty ? '' : _promptCtrl.text.trim());
    final pinCtrl = TextEditingController(text: _pinnedIngredient ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Save preset',
            style: TextStyle(color: AppColors.textHi)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textHi),
              decoration: const InputDecoration(
                labelText: 'Preset name',
                labelStyle: TextStyle(color: AppColors.textMid),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              style: const TextStyle(color: AppColors.textHi),
              decoration: const InputDecoration(
                labelText: 'Always include (optional)',
                labelStyle: TextStyle(color: AppColors.textMid),
                hintText: 'e.g. tortilla',
                hintStyle: TextStyle(color: AppColors.textLow),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (saved != true) return;
    final label = labelCtrl.text.trim();
    if (label.isEmpty) return;
    final pin = pinCtrl.text.trim();
    await ref.read(generationPrefsStoreProvider).savePreset(RecipePreset(
          label: label,
          prompt: _promptCtrl.text.trim(),
          pinnedIngredient: pin.isEmpty ? null : pin,
        ));
    await _loadPresets();
  }

  Future<void> _deletePresetDialog(RecipePreset p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete "${p.label}"?',
            style: const TextStyle(color: AppColors.textHi)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(generationPrefsStoreProvider).deletePreset(p.label);
    await _loadPresets();
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    _servingsCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  // Servings the user wants per day, and how many days they're batch-cooking
  // for. The generated batch is servings/day × days (same per-serving macros).
  int get _servingsPerDay {
    final n = int.tryParse(_servingsCtrl.text.trim()) ?? 1;
    return n < 1 ? 1 : n;
  }

  int get _days {
    final n = int.tryParse(_daysCtrl.text.trim()) ?? 1;
    return n < 1 ? 1 : n;
  }

  int get _batchServings => _servingsPerDay * _days;

  Future<void> _fetchTotals() async {
    try {
      final totals =
          await ref.read(dailyLogServiceProvider).totals(todayDate());
      final t = totals.target;
      final full = t != null
          ? MacroValues(kcal: t.kcal, protein: t.protein, carb: t.carb, fat: t.fat)
          : MacroValues.zero;
      final consumed = totals.consumed;
      final remaining = MacroValues(
        kcal: (full.kcal - consumed.kcal).clamp(0, double.infinity),
        protein: (full.protein - consumed.protein).clamp(0, double.infinity),
        carb: (full.carb - consumed.carb).clamp(0, double.infinity),
        fat: (full.fat - consumed.fat).clamp(0, double.infinity),
      );
      if (!mounted) return;
      setState(() {
        _fullTarget = full;
        _remainingTarget = remaining;
      });
      _applyMode(_mode);
    } catch (_) {
      // tolerate — fields keep their default '0'
    }
  }

  void _applyMode(_TargetMode mode) {
    final src = mode == _TargetMode.remaining ? _remainingTarget : _fullTarget;
    _kcalCtrl.text = src.kcal.toStringAsFixed(0);
    _proteinCtrl.text = src.protein.toStringAsFixed(0);
    _carbCtrl.text = src.carb.toStringAsFixed(0);
    _fatCtrl.text = src.fat.toStringAsFixed(0);
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0;

  Future<void> _generate() async {
    final prompt = _promptCtrl.text.trim();
    final target = MacroValues(
      kcal: _num(_kcalCtrl),
      protein: _num(_proteinCtrl),
      carb: _num(_carbCtrl),
      fat: _num(_fatCtrl),
    );
    final servings = _batchServings;

    final messenger = ScaffoldMessenger.of(context);
    if (!await checkAiReady(ref)) {
      messenger.showSnackBar(const SnackBar(
          content:
              Text('Set up an AI provider in Settings to generate recipes')));
      return;
    }
    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      final prefs = ref.read(generationPrefsStoreProvider);
      final saved = await ref.read(recipeRepositoryProvider).allTitles();
      final recent = await prefs.recentGeneratedTitles();
      final avoid = <String>{...saved, ...recent}.toList();
      final blacklist = await prefs.blacklist();

      final svc = await ref.read(recipeGeneratorServiceProvider.future);
      final result = await svc.generate(
        prompt: prompt.isEmpty ? 'healthy meal' : prompt,
        target: target,
        servings: servings,
        avoidTitles: avoid,
        blacklist: blacklist,
        pinnedIngredient: _pinnedIngredient,
      );
      await prefs.addRecentGeneratedTitle(result.recipe.title);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e.toString();
      final snackMsg = (msg.contains('key') || msg.contains('401'))
          ? 'No AI key — set one in Settings.'
          : 'Generation failed: ${e.toString()}';
      messenger.showSnackBar(SnackBar(content: Text(snackMsg)));
    }
  }

  Future<void> _save() async {
    final result = _result;
    if (result == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(recipeRepositoryProvider).save(result.recipe);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.ember),
        title: Text(
          'Generate Recipe',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textHi,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.line),
        ),
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.ember),
                  SizedBox(height: 16),
                  Text(
                    'Cooking up your recipe…',
                    style: TextStyle(color: AppColors.textMid),
                  ),
                ],
              ),
            )
          : _result != null
              ? _buildPreview(context, tt)
              : _buildInput(context, tt),
    );
  }

  // ---------------------------------------------------------------------------
  // Input state
  // ---------------------------------------------------------------------------

  Widget _buildInput(BuildContext context, TextTheme tt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Prompt card ────────────────────────────────────────────────
          GlassPanel(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'What would you like to cook?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHi,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Save as preset',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(PhosphorIconsRegular.bookmarkSimple,
                          color: AppColors.ember),
                      onPressed: _savePresetDialog,
                    ),
                  ],
                ),
                if (_presets.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _presets
                          .map((p) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onLongPress: () => _deletePresetDialog(p),
                                  child: ActionChip(
                                    label: Text(p.label),
                                    labelStyle:
                                        const TextStyle(color: AppColors.ember),
                                    backgroundColor:
                                        AppColors.ember.withValues(alpha: 0.08),
                                    side: BorderSide(
                                        color: AppColors.ember
                                            .withValues(alpha: 0.25)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    onPressed: () => _applyPreset(p),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: _promptCtrl,
                  style: tt.bodyMedium?.copyWith(color: AppColors.textHi),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'A high-protein dinner with chicken, no dairy',
                    hintStyle: tt.bodyMedium?.copyWith(color: AppColors.textLow),
                    filled: true,
                    fillColor: AppColors.surfaceHigh,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (_pinnedIngredient != null &&
                    _pinnedIngredient!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                      decoration: BoxDecoration(
                        color: AppColors.ember.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(PhosphorIconsBold.pushPin,
                              size: 14, color: AppColors.ember),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Always include: ${_pinnedIngredient!.trim()}',
                              style: tt.bodySmall?.copyWith(
                                color: AppColors.ember,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _pinnedIngredient = null),
                            child: const Icon(PhosphorIconsRegular.x,
                                size: 14, color: AppColors.textMid),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Macro target card ──────────────────────────────────────────
          GlassPanel(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Macro target',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHi,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _modeTab(
                          'Remaining today', _mode == _TargetMode.remaining, () {
                        setState(() => _mode = _TargetMode.remaining);
                        _applyMode(_TargetMode.remaining);
                      }),
                      _modeTab('Full daily', _mode == _TargetMode.full, () {
                        setState(() => _mode = _TargetMode.full);
                        _applyMode(_TargetMode.full);
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _macroField(_kcalCtrl, 'Calories'),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _macroField(_proteinCtrl, 'Protein (g)')),
                    const SizedBox(width: 10),
                    Expanded(child: _macroField(_carbCtrl, 'Carbs (g)')),
                    const SizedBox(width: 10),
                    Expanded(child: _macroField(_fatCtrl, 'Fat (g)')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Batch card ─────────────────────────────────────────────────
          GlassPanel(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Batch',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHi,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _macroField(_servingsCtrl, 'Servings / day')),
                    const SizedBox(width: 10),
                    Expanded(child: _macroField(_daysCtrl, 'Days')),
                  ],
                ),
                ListenableBuilder(
                  listenable: Listenable.merge([_servingsCtrl, _daysCtrl]),
                  builder: (_, __) {
                    if (_days <= 1) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(left: 4, top: 10),
                      child: Text(
                        '= $_batchServings servings '
                        '($_servingsPerDay/day × $_days days)',
                        style: const TextStyle(
                          color: AppColors.textMid,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          PrimaryButton(
            label: 'Generate',
            icon: PhosphorIconsBold.sparkle,
            onPressed: _generate,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Preview state
  // ---------------------------------------------------------------------------

  Widget _buildPreview(BuildContext context, TextTheme tt) {
    final result = _result!;
    final recipe = result.recipe;
    final perServing = result.perServing;
    final target = MacroValues(
      kcal: _num(_kcalCtrl),
      protein: _num(_proteinCtrl),
      carb: _num(_carbCtrl),
      fat: _num(_fatCtrl),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            recipe.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textHi,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${recipe.servings} serving${recipe.servings == 1 ? '' : 's'}',
            style: tt.bodySmall?.copyWith(color: AppColors.textMid),
          ),
          const SizedBox(height: 24),

          // Ingredients
          Text(
            'Ingredients',
            style: tt.labelLarge?.copyWith(color: AppColors.textMid),
          ),
          const SizedBox(height: 10),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: recipe.ingredients.map((ing) {
                final qty = ing.quantity != null && ing.unit != null
                    ? '${ing.quantity} ${ing.unit}'
                    : ing.quantity ?? ing.unit ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(PhosphorIconsBold.dot,
                          size: 10, color: AppColors.ember),
                      const SizedBox(width: 8),
                      if (qty.isNotEmpty) ...[
                        Text(
                          qty,
                          style: tt.bodySmall?.copyWith(
                              color: AppColors.textMid,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          ing.name,
                          style:
                              tt.bodyMedium?.copyWith(color: AppColors.textHi),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Steps
          Text(
            'Steps',
            style: tt.labelLarge?.copyWith(color: AppColors.textMid),
          ),
          const SizedBox(height: 10),
          ...recipe.steps.asMap().entries.map((entry) {
            final idx = entry.key;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 14),
                    child: Text(
                      '${idx + 1}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ember,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step,
                      style:
                          tt.bodyMedium?.copyWith(color: AppColors.textHi, height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),

          // Per-serving macros
          Text(
            'Per serving',
            style: tt.labelLarge?.copyWith(color: AppColors.textMid),
          ),
          const SizedBox(height: 10),

          // Calories — the dominant figure, on a solid-navy hero.
          HeroCard(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CALORIES',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            perServing.kcal.toStringAsFixed(0),
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'kcal',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (target.kcal > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          'target ${target.kcal.toStringAsFixed(0)} kcal',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  PhosphorIconsBold.fire,
                  color: AppColors.accent.withValues(alpha: 0.9),
                  size: 36,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Protein / Carbs / Fat — pastel stat tiles.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: StatTile(
                  label: 'Protein',
                  value: perServing.protein,
                  target: target.protein > 0 ? target.protein : null,
                  color: AppColors.protein,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: 'Carbs',
                  value: perServing.carb,
                  target: target.carb > 0 ? target.carb : null,
                  color: AppColors.carb,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: 'Fat',
                  value: perServing.fat,
                  target: target.fat > 0 ? target.fat : null,
                  color: AppColors.fat,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Action buttons
          PrimaryButton(
            label: 'Save Recipe',
            icon: PhosphorIconsBold.check,
            onPressed: _save,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _result = null),
            icon: const Icon(PhosphorIconsBold.sparkle,
                color: AppColors.ember, size: 18),
            label: const Text(
              'Regenerate',
              style: TextStyle(color: AppColors.ember, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.ember, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 4),
          // Play GenAI policy: users must be able to report AI-generated
          // content they find inappropriate. No backend, so route via email.
          TextButton.icon(
            onPressed: () => _reportRecipe(recipe.title),
            icon: const Icon(PhosphorIconsRegular.flag,
                color: AppColors.textLow, size: 16),
            label: const Text(
              'Report this AI-generated recipe',
              style: TextStyle(color: AppColors.textLow, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the mail app with a pre-filled report. Best-effort: silently no-ops
  /// if the device has no mail handler.
  Future<void> _reportRecipe(String title) async {
    final uri = Uri(
      scheme: 'mailto',
      path: kSupportEmail,
      query: Uri(queryParameters: {
        'subject': 'MacroChef: report AI-generated recipe',
        'body': 'Recipe: $title\n\nWhat is wrong with it?\n',
      }).query,
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _modeTab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.ember : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.canvas : AppColors.textMid,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _macroField(TextEditingController controller, String label) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 5),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMid,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        TextField(
          controller: controller,
          style: tt.bodyMedium?.copyWith(color: AppColors.textHi),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: tt.bodyMedium?.copyWith(color: AppColors.textLow),
            filled: true,
            fillColor: AppColors.surfaceHigh,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }
}
