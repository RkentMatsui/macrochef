import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/macros.dart';
import '../../services/custom_food_basis.dart';
import '../../services/food_units.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../widgets/glass_panel.dart';
import '../widgets/primary_button.dart';

// ---------------------------------------------------------------------------
// CustomFoodsScreen
// ---------------------------------------------------------------------------

class CustomFoodsScreen extends ConsumerStatefulWidget {
  const CustomFoodsScreen({super.key});

  @override
  ConsumerState<CustomFoodsScreen> createState() => _CustomFoodsScreenState();
}

class _CustomFoodsScreenState extends ConsumerState<CustomFoodsScreen> {
  List<FoodMacros>? _foods;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final list = await ref.read(foodCacheRepositoryProvider).listOverrides();
    if (mounted) setState(() => _foods = list);
  }

  Future<void> _delete(String name) async {
    await ref.read(foodCacheRepositoryProvider).deleteByName(name);
    await _refresh();
  }

  void _openSheet({FoodMacros? existing}) {
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
            child: _CustomFoodSheet(
              existing: existing,
              onSaved: () async {
                Navigator.of(ctx).pop();
                await _refresh();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foods = _foods;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.textHi,
        elevation: 0,
        title: Text(
          'Custom foods',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textHi,
          ),
        ),
      ),
      body: foods == null
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.ember,
                strokeWidth: 2,
              ),
            )
          : foods.isEmpty
              ? _buildEmpty()
              : _buildList(foods),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
        child: PrimaryButton(
          label: 'Add custom food',
          icon: PhosphorIconsBold.plus,
          onPressed: () => _openSheet(),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              PhosphorIconsDuotone.bowlFood,
              size: 52,
              color: AppColors.textLow,
            ),
            const SizedBox(height: 16),
            Text(
              'No custom foods yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textHi,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap "Add custom food" to save your own foods — by weight or by the piece.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMid,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<FoodMacros> foods) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: foods.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final f = foods[i];
        final p = f.perHundred;
        return GlassPanel(
          frosted: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          radius: 18,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _openSheet(existing: f),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.name,
                        style: const TextStyle(
                          color: AppColors.textHi,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Builder(builder: (_) {
                        // Piece/serving foods show per-serving macros; weighed
                        // foods show per-100g.
                        final gpp = f.gramsPerPiece;
                        final factor = gpp != null ? gpp / 100.0 : 1.0;
                        final suffix = gpp != null ? 'per serving' : 'per 100g';
                        return Text(
                          '${(p.kcal * factor).toStringAsFixed(0)} kcal  ·  '
                          'P ${(p.protein * factor).toStringAsFixed(1)}g  '
                          'C ${(p.carb * factor).toStringAsFixed(1)}g  '
                          'F ${(p.fat * factor).toStringAsFixed(1)}g  $suffix',
                          style: const TextStyle(
                            color: AppColors.textMid,
                            fontSize: 12,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(PhosphorIconsRegular.trash,
                    color: AppColors.fat, size: 20),
                onPressed: () => _delete(f.name),
                tooltip: 'Delete',
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _CustomFoodSheet — add / edit a custom food
// ---------------------------------------------------------------------------

class _CustomFoodSheet extends ConsumerStatefulWidget {
  final FoodMacros? existing;
  final Future<void> Function() onSaved;

  const _CustomFoodSheet({this.existing, required this.onSaved});

  @override
  ConsumerState<_CustomFoodSheet> createState() => _CustomFoodSheetState();
}

class _CustomFoodSheetState extends ConsumerState<_CustomFoodSheet> {
  final _nameCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _basisQtyCtrl = TextEditingController(text: '100');
  bool _loading = false;
  String? _originalName;

  /// The serving the entered macros are for — a quantity ([_basisQtyCtrl]) of
  /// this unit. Same unit set as the food logger ([kFoodUnits]); defaults to
  /// "per 100 g".
  FoodUnit _basisUnit = kFoodUnits.first;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _originalName = e.name;
      _nameCtrl.text = e.name;
      final gpp = e.gramsPerPiece;
      if (gpp != null) {
        // Count/volume food: show macros for one serving (back-converted from
        // the stored per-100g values), basis = 1 <unit>. The exact unit is
        // refined from the remembered unit; default 'piece'.
        final factor = gpp / 100.0; // per-100g -> per-serving
        _kcalCtrl.text = _fmt(e.perHundred.kcal * factor);
        _proteinCtrl.text = _fmt(e.perHundred.protein * factor);
        _carbCtrl.text = _fmt(e.perHundred.carb * factor);
        _fatCtrl.text = _fmt(e.perHundred.fat * factor);
        _basisQtyCtrl.text = '1';
        _basisUnit = kFoodUnits.firstWhere((u) => u.label == 'piece',
            orElse: () => kFoodUnits.first);
        _loadRememberedBasisUnit(e.name);
      } else {
        _kcalCtrl.text = _fmt(e.perHundred.kcal);
        _proteinCtrl.text = _fmt(e.perHundred.protein);
        _carbCtrl.text = _fmt(e.perHundred.carb);
        _fatCtrl.text = _fmt(e.perHundred.fat);
        _basisQtyCtrl.text = '100';
      }
    }
  }

  /// Refines the basis unit on edit from the unit this food was last logged
  /// with (only adopts non-mass units, since a stored piece weight implies one).
  Future<void> _loadRememberedBasisUnit(String name) async {
    final saved = await ref
        .read(settingsRepositoryProvider)
        .get('foodunit:${name.toLowerCase()}');
    if (!mounted || saved == null || saved.isEmpty) return;
    final label = saved.split('|')[0];
    final matches =
        kFoodUnits.where((u) => u.label == label && u.gramsPerUnit == null);
    if (matches.isNotEmpty) setState(() => _basisUnit = matches.first);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    _basisQtyCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a food name.')),
      );
      return;
    }
    final kcal = _num(_kcalCtrl);
    final protein = _num(_proteinCtrl);
    final carb = _num(_carbCtrl);
    final fat = _num(_fatCtrl);
    if (kcal == 0 && protein == 0 && carb == 0 && fat == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one macro value.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = ref.read(foodCacheRepositoryProvider);
      // If editing and the name changed, delete the old row first so it
      // doesn't linger as a duplicate under the original name.
      final orig = _originalName;
      if (orig != null && orig.toLowerCase() != name.toLowerCase()) {
        await repo.deleteByName(orig);
      }
      if (!mounted) return;

      // Reduce "macros per <qty> <unit>" to the stored per-100g model.
      final qty = double.tryParse(_basisQtyCtrl.text.trim()) ?? 1;
      final basis = customFoodBasis(
        qty: qty,
        unit: _basisUnit,
        kcal: kcal,
        protein: protein,
        carb: carb,
        fat: fat,
      );
      await repo.upsertOverride(
        FoodMacros(
          name: name,
          perHundred: basis.perHundred,
          source: MacroSource.manual,
          isEstimate: false,
          gramsPerPiece: basis.gramsPerPiece,
        ),
      );
      // Remember the unit so this food defaults to it when logged.
      await ref.read(settingsRepositoryProvider).set(
          'foodunit:${name.toLowerCase()}', '${_basisUnit.label}|');
      if (!mounted) return;
      await widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: mq.viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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
            _isEdit ? 'Edit custom food' : 'Add custom food',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textHi,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter the macros for one serving — pick the unit you log it by.',
            style: TextStyle(color: AppColors.textMid, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Food name
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppColors.textHi),
            decoration: InputDecoration(
              hintText: 'Food name (e.g. My Protein Bread)',
              hintStyle: const TextStyle(color: AppColors.textLow),
              filled: true,
              fillColor: AppColors.surfaceHigh,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            textInputAction: TextInputAction.next,
            enabled: !_loading,
          ),
          const SizedBox(height: 12),

          // "Macros are per [qty] [unit]" — the unit picker mirrors the food
          // logger so you define a food by piece/cup/serving/etc, no weighing.
          _basisRow(),
          const SizedBox(height: 16),

          // Calories
          _macroField(_kcalCtrl, 'Calories (kcal)', AppColors.ember),
          const SizedBox(height: 12),

          // P / C / F row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _macroField(
                      _proteinCtrl, 'Protein (g)', AppColors.protein)),
              const SizedBox(width: 10),
              Expanded(
                  child:
                      _macroField(_carbCtrl, 'Carbs (g)', AppColors.carb)),
              const SizedBox(width: 10),
              Expanded(
                  child: _macroField(_fatCtrl, 'Fat (g)', AppColors.fat)),
            ],
          ),
          const SizedBox(height: 20),

          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.ember),
            )
          else
            PrimaryButton(
              label: _isEdit ? 'Save' : 'Add food',
              icon: PhosphorIconsBold.check,
              onPressed: _save,
            ),
        ],
      ),
    );
  }

  /// "Macros are per [qty] [unit]" — a quantity field + the shared kFoodUnits
  /// dropdown, matching the food logger's portion picker.
  Widget _basisRow() {
    return Row(
      children: [
        const Text('Macros are per',
            style: TextStyle(color: AppColors.textMid, fontSize: 13)),
        const SizedBox(width: 10),
        SizedBox(
          width: 60,
          child: TextField(
            controller: _basisQtyCtrl,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textHi),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.surfaceHigh,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            enabled: !_loading,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _basisUnit.label,
            isExpanded: true,
            isDense: true,
            dropdownColor: AppColors.surfaceHigh,
            style: const TextStyle(color: AppColors.textHi, fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.surfaceHigh,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              for (final u in kFoodUnits)
                DropdownMenuItem(value: u.label, child: Text(u.label)),
            ],
            onChanged: _loading
                ? null
                : (v) {
                    if (v == null) return;
                    setState(() => _basisUnit =
                        kFoodUnits.firstWhere((u) => u.label == v));
                  },
          ),
        ),
      ],
    );
  }

  /// Labelled numeric field with a colour-coded label.
  Widget _macroField(
      TextEditingController controller, String label, Color accent) {
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
          style: const TextStyle(color: AppColors.textHi),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: const TextStyle(color: AppColors.textLow),
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
