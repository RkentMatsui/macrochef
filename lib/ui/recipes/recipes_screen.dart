import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/database.dart';
import '../../providers/speech/voice_assets.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../cooking/cooking_screen.dart';
import 'cook_gate.dart';
import '../widgets/cards.dart';
import '../widgets/glass_panel.dart';
import '../widgets/primary_button.dart';
import '../grocery/grocery_list_screen.dart';
import 'add_recipe_screen.dart';
import 'edit_recipe_screen.dart';
import 'generate_recipe_screen.dart';
import '../../models/macros.dart';
import '../../models/recipe_breakdown.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

// ---------------------------------------------------------------------------
// RecipesScreen
// ---------------------------------------------------------------------------

class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _RecipesView();
  }
}

// Using ConsumerStatefulWidget so we can hold a key/trigger to refresh the list.
class _RecipesView extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RecipesView> createState() => _RecipesViewState();
}

class _RecipesViewState extends ConsumerState<_RecipesView> {
  late Future<List<Recipe>> _recipesFuture;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  void _loadRecipes() {
    _recipesFuture = ref.read(recipeRepositoryProvider).all();
  }

  void _refresh() {
    setState(() => _loadRecipes());
  }

  Future<void> _openAddRecipe(BuildContext context) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddRecipeScreen()),
    );
    if (added == true) _refresh();
  }

  /// Hands-free cook entry, relocated from the old Cook tab. Loads the recipe's
  /// steps then pushes the voice CookingScreen.
  Future<void> _cookRecipe(Recipe recipe) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(recipeRepositoryProvider);
    final steps = await repo.stepsFor(recipe.id);
    final ingredients = await repo.ingredientsFor(recipe.id);
    final voiceReady = await VoiceAssets.isReady();
    final aiReady = await checkAiReady(ref);
    if (!mounted) return;
    if (steps.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('This recipe has no steps to cook.')),
      );
      return;
    }
    if (!voiceReady) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Download the voice pack in Settings to cook')),
      );
      return;
    }
    if (!aiReady) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Set up an AI provider in Settings to cook')),
      );
      return;
    }
    navigator.push(
      MaterialPageRoute(
        builder: (_) => CookingScreen(
          steps: steps,
          recipeTitle: recipe.title,
          recipeId: recipe.id,
          ingredientNames: ingredients.map((i) => i.name).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: false,
        title: Text(
          'Recipes',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.textHi,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Grocery list',
            icon: const Icon(PhosphorIconsBold.shoppingCart, color: AppColors.ember),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GroceryListScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Generate recipe',
            icon: const Icon(PhosphorIconsBold.sparkle, color: AppColors.ember),
            onPressed: () async {
              final created = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const GenerateRecipeScreen()),
              );
              if (created == true) _refresh();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _openAddRecipe(context),
              icon: const Icon(PhosphorIconsBold.plus, color: AppColors.ember),
              label: const Text(
                'Add',
                style: TextStyle(
                  color: AppColors.ember,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.line),
        ),
      ),
      body: FutureBuilder<List<Recipe>>(
        future: _recipesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.ember),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load recipes.',
                style: tt.bodyMedium?.copyWith(color: AppColors.textMid),
              ),
            );
          }
          final recipes = snapshot.data ?? [];
          if (recipes.isEmpty) {
            return _buildEmptyState(context, tt);
          }
          return _buildList(context, tt, recipes);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, TextTheme tt) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            PhosphorIconsDuotone.bookOpen,
            size: 64,
            color: AppColors.textLow,
          ),
          const SizedBox(height: 16),
          Text(
            'Your recipe book is empty',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textHi,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a recipe by pasting, dictating, or generating one.',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: AppColors.textMid),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Add Recipe',
            icon: PhosphorIconsBold.plus,
            onPressed: () => _openAddRecipe(context),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildList(BuildContext context, TextTheme tt, List<Recipe> recipes) {
    return ListView.separated(
      // Clear the floating bottom nav (overlays the body via extendBody) so the
      // last recipe isn't hidden behind it when the list is long.
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).padding.bottom + 96),
      itemCount: recipes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _RecipeDetailScreen(recipe: recipe),
              ),
            );
          },
          child: GlassPanel(
            frosted: false, // per-row in a ListView — flat fill avoids scroll jank
            child: Row(
              children: [
                _recipeIconChip(index),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHi,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(recipe.createdAt),
                        style: tt.bodySmall?.copyWith(color: AppColors.textMid),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cook hands-free',
                  icon: const Icon(
                    PhosphorIconsDuotone.microphone,
                    color: AppColors.ember,
                  ),
                  onPressed: () => _cookRecipe(recipe),
                ),
                const Icon(
                  PhosphorIconsRegular.caretRight,
                  color: AppColors.textLow,
                ),
              ],
            ),
          ),
        )
            .animate(delay: Duration(milliseconds: index * 60))
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.06, end: 0);
      },
    );
  }

  /// A rounded pastel chip with a bowl icon. Colors rotate per row so the list
  /// reads as varied soft tiles (echoing the design references).
  Widget _recipeIconChip(int index) {
    const palette = [
      AppColors.protein,
      AppColors.carb,
      AppColors.fat,
      AppColors.accent,
      AppColors.ember,
    ];
    final color = palette[index % palette.length];
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(PhosphorIconsDuotone.bowlFood, color: color, size: 24),
    );
  }
}

// ---------------------------------------------------------------------------
// _RecipeDetailScreen
// ---------------------------------------------------------------------------

class _RecipeDetailScreen extends ConsumerStatefulWidget {
  final Recipe recipe;
  const _RecipeDetailScreen({required this.recipe});

  @override
  ConsumerState<_RecipeDetailScreen> createState() =>
      _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<_RecipeDetailScreen> {
  List<String>? _steps;
  bool _loading = true;
  String? _error;
  RecipeMacros? _nutrition;
  bool _nutritionLoading = true;
  String? _nutritionError;
  bool _logging = false;
  int _servings = 1;
  RecipeBreakdown? _breakdown;
  bool _breakdownLoading = true;
  bool _voiceReady = false;
  bool _aiReady = false;

  @override
  void initState() {
    super.initState();
    _loadSteps();
    _loadNutrition();
    _loadBreakdown();
    _loadServings();
    VoiceAssets.isReady().then((r) {
      if (mounted) setState(() => _voiceReady = r);
    });
    checkAiReady(ref).then((r) {
      if (mounted) setState(() => _aiReady = r);
    });
  }

  Future<void> _loadServings() async {
    final s = await ref.read(recipeRepositoryProvider).servingsFor(widget.recipe.id);
    if (mounted) setState(() => _servings = s);
  }

  Future<void> _loadSteps() async {
    try {
      final steps = await ref
          .read(recipeRepositoryProvider)
          .stepsFor(widget.recipe.id);
      if (mounted) {
        setState(() {
          _steps = steps;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadBreakdown() async {
    try {
      final svc = await ref.read(recipeNutritionServiceProvider.future);
      final b = await svc.breakdownFor(widget.recipe.id);
      if (mounted) {
        setState(() {
          _breakdown = b;
          _breakdownLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _breakdownLoading = false);
    }
  }

  Future<void> _loadNutrition() async {
    try {
      final svc = await ref.read(recipeNutritionServiceProvider.future);
      final macros = await svc.nutritionFor(widget.recipe.id);
      if (mounted) {
        setState(() {
          _nutrition = macros;
          _nutritionLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nutritionError = e.toString();
          _nutritionLoading = false;
        });
      }
    }
  }

  Future<void> _logMeal() async {
    final macros = _nutrition;
    if (macros == null) {
      _openManualLog();
      return;
    }
    final eaten = await _askServingsEaten();
    if (eaten == null) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _logging = true);
    try {
      final svc = await ref.read(recipeNutritionServiceProvider.future);
      await svc.logMealServings(
        recipeId: widget.recipe.id,
        recipeTitle: widget.recipe.title,
        recipeMacros: macros,
        servingsEaten: eaten,
      );
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Logged $eaten serving(s).')));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  Future<double?> _askServingsEaten() async {
    final ctrl = TextEditingController(text: '1');
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('How many servings?', style: TextStyle(color: AppColors.textHi)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          style: const TextStyle(color: AppColors.textHi),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text.trim()) ?? 1),
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }

  Future<void> _setServings(int n) async {
    final v = n < 1 ? 1 : n;
    await ref.read(recipeRepositoryProvider).updateServings(widget.recipe.id, v);
    final svc = await ref.read(recipeNutritionServiceProvider.future);
    svc.invalidate(widget.recipe.id);
    setState(() {
      _servings = v;
      _nutritionLoading = true;
      _breakdownLoading = true;
    });
    await _loadNutrition();
    await _loadBreakdown();
  }

  /// Opens a sheet to hand-enter macros for this recipe, then logs it against
  /// today's log (tagged with this recipe). Used when auto-nutrition fails.
  void _openManualLog() {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.glassFillHigh,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppColors.glassStroke, width: 1),
            ),
            child: _ManualMealSheet(
              recipeId: widget.recipe.id,
              recipeTitle: widget.recipe.title,
              onLogged: () => messenger.showSnackBar(
                const SnackBar(content: Text('Meal logged to today\'s log.')),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startCooking() async {
    final navigator = Navigator.of(context);
    final ingredients = await ref
        .read(recipeRepositoryProvider)
        .ingredientsFor(widget.recipe.id);
    if (!mounted) return;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => CookingScreen(
          steps: _steps ?? [],
          recipeTitle: widget.recipe.title,
          recipeId: widget.recipe.id,
          ingredientNames: ingredients.map((i) => i.name).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          widget.recipe.title,
          style: tt.titleMedium?.copyWith(color: AppColors.textHi),
        ),
        iconTheme: const IconThemeData(color: AppColors.ember),
        actions: [
          IconButton(
            tooltip: 'Edit recipe',
            icon: const Icon(PhosphorIconsRegular.pencilSimple,
                color: AppColors.ember),
            onPressed: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                    builder: (_) =>
                        EditRecipeScreen(recipe: widget.recipe)),
              );
              if (changed == true && mounted) {
                final svc =
                    await ref.read(recipeNutritionServiceProvider.future);
                svc.invalidate(widget.recipe.id);
                if (!mounted) return;
                setState(() {
                  _nutritionLoading = true;
                  _breakdownLoading = true;
                });
                await _loadSteps();
                await _loadServings();
                await _loadNutrition();
                await _loadBreakdown();
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.line),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.ember),
            )
          : _error != null
              ? Center(
                  child: Text(
                    'Failed to load steps.',
                    style: tt.bodyMedium?.copyWith(color: AppColors.textMid),
                  ),
                )
              : _buildDetail(context, tt),
    );
  }

  Widget _buildDetail(BuildContext context, TextTheme tt) {
    final steps = _steps ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            widget.recipe.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: AppColors.textHi,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatDate(widget.recipe.createdAt),
            style: tt.bodySmall?.copyWith(color: AppColors.textMid),
          ),
          const SizedBox(height: 28),

          // Steps
          if (steps.isEmpty)
            GlassPanel(
              child: Text(
                'No steps recorded for this recipe.',
                style: tt.bodyMedium?.copyWith(color: AppColors.textMid),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 14),
              child: Text(
                'Steps',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHi,
                ),
              ),
            ),
            GlassPanel(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...steps.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final step = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            margin: const EdgeInsets.only(right: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.ember.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ember,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                step,
                                style: tt.bodyMedium?.copyWith(
                                  color: AppColors.textHi,
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate(
                          delay: Duration(milliseconds: 80 + idx * 60),
                        )
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.05, end: 0);
                  }),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Servings stepper
          GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(PhosphorIconsDuotone.usersThree,
                    color: AppColors.ember, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Servings',
                    style: tt.bodyMedium?.copyWith(
                      color: AppColors.textHi,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _stepperButton(
                    PhosphorIconsBold.minus, () => _setServings(_servings - 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '$_servings',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHi,
                    ),
                  ),
                ),
                _stepperButton(
                    PhosphorIconsBold.plus, () => _setServings(_servings + 1)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Estimated nutrition
          _buildNutritionPanel(context, tt),

          const SizedBox(height: 16),

          _buildBreakdownPanel(context, tt),
          const SizedBox(height: 16),

          // Log this meal — falls back to manual macro entry when auto-
          // nutrition couldn't be resolved.
          PrimaryButton(
            label: _logging
                ? 'Logging…'
                : (_nutrition != null
                    ? 'Log this meal'
                    : 'Log this meal manually'),
            icon: PhosphorIconsRegular.chartLineUp,
            onPressed: (!_logging && !_nutritionLoading) ? _logMeal : null,
          ).animate(delay: 260.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 12),

          // Start Cooking button (gated on steps + downloaded voice pack)
          PrimaryButton(
            label: 'Start Cooking',
            icon: PhosphorIconsRegular.play,
            onPressed: canStartCooking(
                    hasSteps: steps.isNotEmpty,
                    voiceReady: _voiceReady,
                    aiReady: _aiReady)
                ? _startCooking
                : null,
          ).animate(delay: 200.ms).fadeIn(duration: 300.ms),
          if (cookDisabledHint(
                  hasSteps: steps.isNotEmpty,
                  voiceReady: _voiceReady,
                  aiReady: _aiReady) !=
              null) ...[
            const SizedBox(height: 6),
            Text(
              cookDisabledHint(
                  hasSteps: steps.isNotEmpty,
                  voiceReady: _voiceReady,
                  aiReady: _aiReady)!,
              style: const TextStyle(color: AppColors.textLow, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// A small navy-tinted circular +/- button for the servings stepper.
  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.ember.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.ember, size: 18),
      ),
    );
  }

  Widget _buildNutritionPanel(BuildContext context, TextTheme tt) {
    if (_nutritionLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(color: AppColors.ember, strokeWidth: 2),
        ),
      ).animate(delay: 180.ms).fadeIn(duration: 300.ms);
    }

    if (_nutritionError != null || _nutrition == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Could not estimate nutrition for this recipe.',
          style: tt.bodySmall?.copyWith(color: AppColors.textLow),
        ),
      ).animate(delay: 180.ms).fadeIn(duration: 300.ms);
    }

    final m = _nutrition!.perServing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estimated nutrition',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHi,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Per serving · makes $_servings',
                style: tt.bodySmall?.copyWith(color: AppColors.textMid),
              ),
            ],
          ),
        ),
        // Calories hero
        HeroCard(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          m.kcal.toStringAsFixed(0),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'kcal',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  PhosphorIconsDuotone.fire,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Macro stat tiles
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Protein',
                value: m.protein,
                color: AppColors.protein,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: 'Carbs',
                value: m.carb,
                color: AppColors.carb,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: 'Fat',
                value: m.fat,
                color: AppColors.fat,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Based on ${_nutrition!.totalGrams.toStringAsFixed(0)} g of resolved ingredients',
            style: tt.bodySmall?.copyWith(color: AppColors.textLow),
          ),
        ),
      ],
    ).animate(delay: 180.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildBreakdownPanel(BuildContext context, TextTheme tt) {
    if (_breakdownLoading) return const SizedBox.shrink();
    final b = _breakdown;
    if (b == null || b.ingredients.isEmpty) return const SizedBox.shrink();

    final maxKcal = b.ingredients
        .map((i) => i.macros?.kcal ?? 0)
        .fold<double>(0, (a, c) => c > a ? c : a);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Where it comes from',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHi,
                ),
              ),
              const SizedBox(height: 2),
              Text('${b.countedCount} of ${b.totalCount} ingredients counted',
                  style: tt.bodySmall?.copyWith(color: AppColors.textMid)),
            ],
          ),
        ),
        GlassPanel(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...b.ingredients.map((i) => _breakdownRow(context, tt, i, maxKcal)),
            ],
          ),
        ),
      ],
    ).animate(delay: 200.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _breakdownRow(
      BuildContext context, TextTheme tt, IngredientContribution i, double maxKcal) {
    final counted = i.status == ContributionStatus.counted;
    final kcal = i.macros?.kcal ?? 0;
    final share = (counted && maxKcal > 0) ? (kcal / maxKcal).clamp(0.0, 1.0) : 0.0;

    final flagText = switch (i.status) {
      ContributionStatus.unknownUnit => 'not counted — unknown unit',
      ContributionStatus.noMatch => 'not counted — no match',
      ContributionStatus.counted => '',
    };

    final row = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  i.name,
                  style: tt.bodyMedium?.copyWith(
                    color: counted ? AppColors.textHi : AppColors.textLow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (counted)
                Text('${kcal.toStringAsFixed(0)} kcal',
                    style: tt.bodySmall?.copyWith(color: AppColors.textMid)),
            ],
          ),
          const SizedBox(height: 4),
          if (counted) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: share,
                minHeight: 5,
                backgroundColor: AppColors.glassStroke,
                valueColor: const AlwaysStoppedAnimation(AppColors.ember),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${i.grams!.toStringAsFixed(0)} g · '
              'P ${i.macros!.protein.toStringAsFixed(0)} · '
              'C ${i.macros!.carb.toStringAsFixed(0)} · '
              'F ${i.macros!.fat.toStringAsFixed(0)}',
              style: tt.bodySmall?.copyWith(color: AppColors.textLow),
            ),
            // Piece/count ingredients: show the per-piece basis + adjust hint.
            if (i.gramsPerPiece != null) ...[
              const SizedBox(height: 2),
              Text(
                '≈ ${i.gramsPerPiece!.toStringAsFixed(0)} g per '
                '${(i.unit == null || i.unit!.trim().isEmpty) ? 'piece' : i.unit!.trim()}'
                ' · tap to adjust',
                style: tt.bodySmall?.copyWith(color: AppColors.ember),
              ),
            ],
          ] else
            Row(
              children: [
                Icon(PhosphorIconsRegular.warningCircle,
                    size: 14, color: AppColors.textLow),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(flagText,
                      style: tt.bodySmall?.copyWith(color: AppColors.textLow)),
                ),
                Text('Tap to fix',
                    style: tt.bodySmall?.copyWith(color: AppColors.ember)),
              ],
            ),
        ],
      ),
    );

    // Piece-counted rows → tap to adjust the per-piece weight.
    if (counted && i.gramsPerPiece != null) {
      return InkWell(onTap: () => _adjustPieceWeight(i), child: row);
    }
    if (counted) return row;
    return InkWell(onTap: _openEditToFix, child: row);
  }

  Future<void> _adjustPieceWeight(IngredientContribution i) async {
    final unit = (i.unit == null || i.unit!.trim().isEmpty)
        ? 'piece'
        : i.unit!.trim();
    final ctrl = TextEditingController(
        text: i.gramsPerPiece!.toStringAsFixed(0));
    final grams = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Weight of 1 $unit',
            style: const TextStyle(color: AppColors.textHi)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          style: const TextStyle(color: AppColors.textHi),
          decoration: const InputDecoration(
            suffixText: 'g',
            suffixStyle: TextStyle(color: AppColors.textMid),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(ctrl.text.trim())),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (grams == null || grams <= 0 || !mounted) return;
    await ref.read(foodCacheRepositoryProvider).setGramsPerPiece(i.name, grams);
    final svc = await ref.read(recipeNutritionServiceProvider.future);
    svc.invalidate(widget.recipe.id);
    if (!mounted) return;
    setState(() {
      _nutritionLoading = true;
      _breakdownLoading = true;
    });
    await _loadNutrition();
    await _loadBreakdown();
  }

  Future<void> _openEditToFix() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditRecipeScreen(recipe: widget.recipe)),
    );
    if (changed == true && mounted) {
      final svc = await ref.read(recipeNutritionServiceProvider.future);
      svc.invalidate(widget.recipe.id);
      if (!mounted) return;
      setState(() {
        _nutritionLoading = true;
        _breakdownLoading = true;
      });
      await _loadServings();
      await _loadNutrition();
      await _loadBreakdown();
    }
  }
}

// ---------------------------------------------------------------------------
// _ManualMealSheet — hand-enter macros for a recipe when auto-nutrition fails
// ---------------------------------------------------------------------------

class _ManualMealSheet extends ConsumerStatefulWidget {
  final int recipeId;
  final String recipeTitle;
  final VoidCallback onLogged;

  const _ManualMealSheet({
    required this.recipeId,
    required this.recipeTitle,
    required this.onLogged,
  });

  @override
  ConsumerState<_ManualMealSheet> createState() => _ManualMealSheetState();
}

class _ManualMealSheetState extends ConsumerState<_ManualMealSheet> {
  final _gramsCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _gramsCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  Future<void> _submit() async {
    final macros = MacroValues(
      kcal: _num(_kcalCtrl),
      protein: _num(_proteinCtrl),
      carb: _num(_carbCtrl),
      fat: _num(_fatCtrl),
    );
    if (macros.kcal == 0 &&
        macros.protein == 0 &&
        macros.carb == 0 &&
        macros.fat == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one macro value.')),
      );
      return;
    }
    final grams = double.tryParse(_gramsCtrl.text.trim()) ?? 0;

    setState(() => _loading = true);
    try {
      await ref.read(dailyLogServiceProvider).log(
            todayDate(),
            name: widget.recipeTitle,
            grams: grams,
            macros: macros,
            source: MacroSource.manual,
            recipeId: widget.recipeId,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onLogged();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: mediaQuery.viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Log meal',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textHi,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.recipeTitle,
            style: tt.bodySmall?.copyWith(color: AppColors.textMid),
          ),
          const SizedBox(height: 16),
          _macroField(_kcalCtrl, 'Calories', AppColors.ember),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child:
                    _macroField(_proteinCtrl, 'Protein (g)', AppColors.protein),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _macroField(_carbCtrl, 'Carbs (g)', AppColors.carb),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _macroField(_fatCtrl, 'Fat (g)', AppColors.fat),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _macroField(_gramsCtrl, 'Weight (g) · optional', AppColors.textMid),
          const SizedBox(height: 24),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.ember),
            )
          else
            PrimaryButton(
              label: 'Log meal',
              icon: PhosphorIconsBold.check,
              onPressed: _submit,
            ),
        ],
      ),
    );
  }

  Widget _macroField(
      TextEditingController controller, String label, Color accent) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 5),
          child: Text(
            label,
            style: TextStyle(
              color: accent,
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
          enabled: !_loading,
        ),
      ],
    );
  }
}
