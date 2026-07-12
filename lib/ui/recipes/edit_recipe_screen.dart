import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/database.dart';
import '../../models/macros.dart';
import '../../models/recipe.dart';
import '../../services/food_units.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../widgets/primary_button.dart';

// ---------------------------------------------------------------------------
// Per-ingredient row model
// ---------------------------------------------------------------------------

class _IngredientRow {
  final TextEditingController nameCtrl;
  final TextEditingController quantityCtrl;
  final TextEditingController unitCtrl;
  final FocusNode nameFocus;
  FoodMacros? resolved;

  _IngredientRow({
    String name = '',
    String quantity = '',
    String unit = '',
  })  : nameCtrl = TextEditingController(text: name),
        quantityCtrl = TextEditingController(text: quantity),
        unitCtrl = TextEditingController(text: unit),
        nameFocus = FocusNode();

  void dispose() {
    nameCtrl.dispose();
    quantityCtrl.dispose();
    unitCtrl.dispose();
    nameFocus.dispose();
  }
}

// ---------------------------------------------------------------------------
// EditRecipeScreen
// ---------------------------------------------------------------------------

class EditRecipeScreen extends ConsumerStatefulWidget {
  final Recipe recipe;

  const EditRecipeScreen({super.key, required this.recipe});

  @override
  ConsumerState<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends ConsumerState<EditRecipeScreen> {
  final _titleCtrl = TextEditingController();
  int _servings = 1;
  List<_IngredientRow> _ingredients = [];
  List<TextEditingController> _stepCtrls = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.recipe.title;
    _servings = widget.recipe.servings;
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = ref.read(recipeRepositoryProvider);
    final ings = await repo.ingredientsFor(widget.recipe.id);
    final steps = await repo.stepsFor(widget.recipe.id);
    // Read servings from the DB (live value), not widget.recipe which is a
    // stale snapshot from the recipes list — otherwise saving clobbers it to 1.
    final servings = await repo.servingsFor(widget.recipe.id);
    if (!mounted) return;
    setState(() {
      _servings = servings;
      _ingredients = ings
          .map((i) => _IngredientRow(
                name: i.name,
                quantity: i.quantity ?? '',
                unit: i.unit ?? '',
              ))
          .toList();
      _stepCtrls =
          steps.map((s) => TextEditingController(text: s)).toList();
      if (_stepCtrls.isEmpty) {
        _stepCtrls.add(TextEditingController());
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final row in _ingredients) {
      row.dispose();
    }
    for (final c in _stepCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Ingredient helpers ───────────────────────────────────────────────────

  void _addIngredient() {
    setState(() => _ingredients.add(_IngredientRow()));
  }

  void _removeIngredient(int index) {
    final row = _ingredients[index];
    setState(() => _ingredients.removeAt(index));
    row.dispose();
  }

  Future<void> _resolve(int index) async {
    final row = _ingredients[index];
    final name = row.nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an ingredient name first.')),
      );
      return;
    }
    final lookup = await ref.read(foodLookupProvider.future);
    if (!mounted) return;
    final fm = await lookup.resolve(name);
    if (!mounted) return;
    if (fm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No macros found for $name')),
      );
      return;
    }
    setState(() => row.resolved = fm);
  }

  Future<void> _openFixDialog(int index) async {
    final row = _ingredients[index];
    final name = row.nameCtrl.text.trim().isEmpty
        ? 'Ingredient'
        : row.nameCtrl.text.trim();

    // The dialog owns its own controllers and disposes them in its State so
    // they can't be touched after disposal (which previously crashed the
    // edit screen). It returns the entered PerHundred, or null on cancel.
    final ph = await showDialog<PerHundred>(
      context: context,
      builder: (_) =>
          _FixMacrosDialog(name: name, existing: row.resolved?.perHundred),
    );

    if (ph == null || !mounted) return;

    final newMacros = FoodMacros(
      name: name,
      perHundred: ph,
      source: MacroSource.manual,
      isEstimate: false,
    );

    await ref.read(foodCacheRepositoryProvider).upsertOverride(newMacros);
    if (!mounted) return;
    setState(() => row.resolved = newMacros);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved macros for $name')),
    );
  }

  // ── Steps helpers ────────────────────────────────────────────────────────

  void _addStep() {
    setState(() => _stepCtrls.add(TextEditingController()));
  }

  void _removeStep(int index) {
    final c = _stepCtrls[index];
    setState(() => _stepCtrls.removeAt(index));
    c.dispose();
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final titleText = _titleCtrl.text.trim();
      final parsedIngredients = _ingredients
          .where((r) => r.nameCtrl.text.trim().isNotEmpty)
          .map((r) {
        final q = r.quantityCtrl.text.trim();
        final u = r.unitCtrl.text.trim();
        return Ingredient(
          r.nameCtrl.text.trim(),
          quantity: q.isEmpty ? null : q,
          unit: u.isEmpty ? null : u,
        );
      }).toList();

      final parsedSteps = _stepCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final parsed = ParsedRecipe(
        title: titleText.isEmpty ? 'Untitled Recipe' : titleText,
        ingredients: parsedIngredients,
        steps: parsedSteps,
        servings: _servings,
      );

      await ref.read(recipeRepositoryProvider).updateFull(widget.recipe.id, parsed);

      final svc = await ref.read(recipeNutritionServiceProvider.future);
      svc.invalidate(widget.recipe.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe updated')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          'Edit recipe',
          style: tt.titleMedium?.copyWith(color: AppColors.textHi),
        ),
        iconTheme: const IconThemeData(color: AppColors.ember),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.line),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.ember))
          : _buildForm(context, tt),
    );
  }

  Widget _buildForm(BuildContext context, TextTheme tt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            'Title',
            style: tt.labelLarge?.copyWith(color: AppColors.textMid),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textHi,
            ),
            decoration: const InputDecoration(
              hintText: 'Recipe title',
              hintStyle: TextStyle(color: AppColors.textLow),
              filled: true,
              fillColor: AppColors.surfaceHigh,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.ember),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Servings stepper
          Text(
            'Servings',
            style: tt.labelLarge?.copyWith(color: AppColors.textMid),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon:
                    const Icon(PhosphorIconsBold.minus, color: AppColors.ember),
                onPressed: () =>
                    setState(() => _servings = (_servings - 1).clamp(1, 99)),
              ),
              Text(
                '$_servings',
                style:
                    tt.titleMedium?.copyWith(color: AppColors.textHi),
              ),
              IconButton(
                icon:
                    const Icon(PhosphorIconsBold.plus, color: AppColors.ember),
                onPressed: () =>
                    setState(() => _servings = (_servings + 1).clamp(1, 99)),
              ),
              Text(
                'serving${_servings == 1 ? '' : 's'}',
                style: tt.bodyMedium?.copyWith(color: AppColors.textMid),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Ingredients section
          Text(
            'Ingredients',
            style: tt.labelLarge?.copyWith(color: AppColors.textMid),
          ),
          const SizedBox(height: 8),

          ..._ingredients.asMap().entries.map((entry) {
            final idx = entry.key;
            final row = entry.value;
            return _buildIngredientRow(idx, row, tt);
          }),

          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addIngredient,
            icon: const Icon(PhosphorIconsBold.plus,
                size: 16, color: AppColors.ember),
            label: const Text('Add ingredient',
                style: TextStyle(color: AppColors.ember)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.line),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),

          const SizedBox(height: 28),

          // Steps section
          Text(
            'Steps',
            style: tt.labelLarge?.copyWith(color: AppColors.textMid),
          ),
          const SizedBox(height: 8),

          ..._stepCtrls.asMap().entries.map((entry) {
            final idx = entry.key;
            final ctrl = entry.value;
            return _buildStepRow(idx, ctrl);
          }),

          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addStep,
            icon: const Icon(PhosphorIconsBold.plus,
                size: 16, color: AppColors.ember),
            label: const Text('Add step',
                style: TextStyle(color: AppColors.ember)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.line),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),

          const SizedBox(height: 32),

          // Save button
          PrimaryButton(
            label: _saving ? 'Saving…' : 'Save Recipe',
            icon: PhosphorIconsRegular.floppyDisk,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }

  static const _nameDecoration = InputDecoration(
    hintText: 'Ingredient',
    hintStyle: TextStyle(color: AppColors.textLow, fontSize: 13),
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: AppColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: AppColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: AppColors.ember),
    ),
  );

  /// Ingredient name field with saved/custom-food autocomplete. Reuses the
  /// row's own [nameCtrl]/[nameFocus] so existing resolve/save logic is
  /// unchanged; selecting a saved food fills the name (and a piece unit when
  /// the food has a per-piece weight and no unit is set yet).
  Widget _ingredientNameField(int idx, _IngredientRow row) {
    return RawAutocomplete<FoodMacros>(
      textEditingController: row.nameCtrl,
      focusNode: row.nameFocus,
      displayStringForOption: (f) => f.name,
      optionsBuilder: (TextEditingValue value) async {
        final q = value.text.trim();
        if (q.isEmpty) return const Iterable<FoodMacros>.empty();
        return ref.read(foodCacheRepositoryProvider).search(q);
      },
      onSelected: (f) {
        row.nameCtrl.text = f.name;
        if (row.unitCtrl.text.trim().isEmpty && f.gramsPerPiece != null) {
          row.unitCtrl.text = 'piece';
        }
        setState(() => row.resolved = f);
      },
      fieldViewBuilder:
          (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: (_) => onFieldSubmitted(),
          style: const TextStyle(color: AppColors.textHi, fontSize: 14),
          decoration: _nameDecoration,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: AppColors.surfaceHigh,
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 280),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  for (final f in options)
                    ListTile(
                      dense: true,
                      title: Text(f.name,
                          style: const TextStyle(
                              color: AppColors.textHi, fontSize: 13)),
                      subtitle: Text(
                        '${f.perHundred.kcal.toStringAsFixed(0)} kcal/100g',
                        style: const TextStyle(
                            color: AppColors.textMid, fontSize: 11),
                      ),
                      onTap: () => onSelected(f),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Returns the row's unit if it matches a known kFoodUnits label, else ''.
  String _unitValueFor(_IngredientRow row) {
    final raw = row.unitCtrl.text.trim().toLowerCase();
    if (raw.isEmpty) return '';
    final match = kFoodUnits.where((u) => u.label.toLowerCase() == raw);
    return match.isEmpty ? '' : match.first.label;
  }

  Widget _unitDropdown(_IngredientRow row) {
    return DropdownButtonFormField<String>(
      value: _unitValueFor(row),
      isExpanded: true,
      isDense: true,
      dropdownColor: AppColors.surfaceHigh,
      style: const TextStyle(color: AppColors.textHi, fontSize: 13),
      icon: const Icon(PhosphorIconsRegular.caretDown,
          size: 12, color: AppColors.textLow),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.ember),
        ),
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('—')),
        for (final u in kFoodUnits)
          DropdownMenuItem(value: u.label, child: Text(u.label)),
      ],
      onChanged: (v) => setState(() => row.unitCtrl.text = v ?? ''),
    );
  }

  Widget _buildIngredientRow(int idx, _IngredientRow row, TextTheme tt) {
    final resolved = row.resolved;
    final ph = resolved?.perHundred;
    final summaryText = ph != null
        ? '${ph.kcal.toStringAsFixed(0)} kcal · '
            '${ph.protein.toStringAsFixed(1)}P '
            '${ph.carb.toStringAsFixed(1)}C '
            '${ph.fat.toStringAsFixed(1)}F /100g · ${resolved!.source.name}'
        : 'Tap to find macros';
    final summaryColor = ph != null ? AppColors.textMid : AppColors.textLow;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Name field — autocomplete from saved/custom foods so a food
                // entered once can be reused as an ingredient without retyping.
                Expanded(
                  flex: 3,
                  child: _ingredientNameField(idx, row),
                ),
                const SizedBox(width: 6),
                // Quantity field
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: row.quantityCtrl,
                    style: const TextStyle(
                        color: AppColors.textHi, fontSize: 14),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9./]'))
                    ],
                    decoration: const InputDecoration(
                      hintText: 'Qty',
                      hintStyle: TextStyle(
                          color: AppColors.textLow, fontSize: 12),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: AppColors.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: AppColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: AppColors.ember),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Unit dropdown (shared kFoodUnits) — replaces free-text so
                // piece/slice/cup/oz convert correctly toward nutrition.
                SizedBox(
                  width: 76,
                  child: _unitDropdown(row),
                ),
                // Remove button
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.x,
                      size: 16, color: AppColors.textLow),
                  onPressed: () => _removeIngredient(idx),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _resolve(idx),
                    child: Text(
                      summaryText,
                      style: TextStyle(
                        color: summaryColor,
                        fontSize: 11,
                        fontWeight: ph != null
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                // Fix / Edit macros button
                GestureDetector(
                  onTap: () => _openFixDialog(idx),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsRegular.pencilSimple,
                            size: 12, color: AppColors.ember),
                        SizedBox(width: 3),
                        Text(
                          'Fix',
                          style: TextStyle(
                            color: AppColors.ember,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(int idx, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14, right: 12),
            child: Text(
              '${idx + 1}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.ember,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              maxLines: null,
              style: const TextStyle(
                  color: AppColors.textHi, fontSize: 14, height: 1.5),
              decoration: const InputDecoration(
                hintText: 'Step description',
                hintStyle:
                    TextStyle(color: AppColors.textLow, fontSize: 13),
                filled: true,
                fillColor: AppColors.surfaceHigh,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: AppColors.ember),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.x,
                size: 16, color: AppColors.textLow),
            onPressed: _stepCtrls.length > 1 ? () => _removeStep(idx) : null,
            padding: const EdgeInsets.only(left: 8),
            constraints:
                const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

}

// ---------------------------------------------------------------------------
// _FixMacrosDialog — owns its TextEditingControllers (disposes them in its own
// State, after the route is torn down) so they're never touched post-dispose.
// Pops a PerHundred with the entered per-100g values, or null on cancel.
// ---------------------------------------------------------------------------

class _FixMacrosDialog extends StatefulWidget {
  final String name;
  final PerHundred? existing;
  const _FixMacrosDialog({required this.name, this.existing});

  @override
  State<_FixMacrosDialog> createState() => _FixMacrosDialogState();
}

class _FixMacrosDialogState extends State<_FixMacrosDialog> {
  late final TextEditingController _kcal;
  late final TextEditingController _protein;
  late final TextEditingController _carb;
  late final TextEditingController _fat;

  @override
  void initState() {
    super.initState();
    String f(double? v) => v?.toStringAsFixed(1) ?? '';
    _kcal = TextEditingController(text: f(widget.existing?.kcal));
    _protein = TextEditingController(text: f(widget.existing?.protein));
    _carb = TextEditingController(text: f(widget.existing?.carb));
    _fat = TextEditingController(text: f(widget.existing?.fat));
  }

  @override
  void dispose() {
    _kcal.dispose();
    _protein.dispose();
    _carb.dispose();
    _fat.dispose();
    super.dispose();
  }

  void _save() {
    double p(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;
    Navigator.pop(
      context,
      PerHundred(
        kcal: p(_kcal),
        protein: p(_protein),
        carb: p(_carb),
        fat: p(_fat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        'Macros for ${widget.name}',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textHi,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Per 100 g',
                style: TextStyle(color: AppColors.textMid, fontSize: 12)),
            const SizedBox(height: 12),
            _field(_kcal, 'Calories (kcal)', AppColors.ember),
            const SizedBox(height: 8),
            _field(_protein, 'Protein (g)', AppColors.protein),
            const SizedBox(height: 8),
            _field(_carb, 'Carbs (g)', AppColors.carb),
            const SizedBox(height: 8),
            _field(_fat, 'Fat (g)', AppColors.fat),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child:
              const Text('Cancel', style: TextStyle(color: AppColors.textMid)),
        ),
        TextButton(
          onPressed: _save,
          child: const Text('Save', style: TextStyle(color: AppColors.ember)),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: AppColors.textHi, fontSize: 14),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
          ],
          decoration: InputDecoration(
            hintText: '0',
            hintStyle:
                const TextStyle(color: AppColors.textLow, fontSize: 13),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: AppColors.surfaceHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
