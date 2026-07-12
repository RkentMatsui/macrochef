import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/database.dart';
import '../../services/grocery_combiner.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../widgets/glass_panel.dart';
import '../widgets/primary_button.dart';

class GroceryListScreen extends ConsumerStatefulWidget {
  const GroceryListScreen({super.key});

  @override
  ConsumerState<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends ConsumerState<GroceryListScreen> {
  List<GroceryItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await ref.read(groceryRepositoryProvider).all();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _clearAll() async {
    await ref.read(groceryRepositoryProvider).clear();
    if (!mounted) return;
    setState(() => _items = []);
  }

  Future<void> _chooseRecipes() async {
    final recipes = await ref.read(recipeRepositoryProvider).all();
    if (!mounted) return;

    final selected = await showDialog<Set<int>>(
      context: context,
      builder: (ctx) => _RecipePickerDialog(recipes: recipes),
    );
    if (selected == null || selected.isEmpty) return;

    // Gather all ingredients from selected recipes
    final allIngredients = <RecipeIngredient>[];
    for (final id in selected) {
      final ings = await ref.read(recipeRepositoryProvider).ingredientsFor(id);
      allIngredients.addAll(ings);
    }

    final drafts = combineIngredients(allIngredients);
    await ref.read(groceryRepositoryProvider).replaceAll(drafts);
    if (!mounted) return;

    final items = await ref.read(groceryRepositoryProvider).all();
    if (!mounted) return;
    setState(() => _items = items);
  }

  Future<void> _toggleChecked(GroceryItem item, bool value) async {
    await ref.read(groceryRepositoryProvider).setChecked(item.id, value);
    if (!mounted) return;
    setState(() {
      final idx = _items.indexWhere((i) => i.id == item.id);
      if (idx != -1) {
        _items = List.of(_items)..[idx] = GroceryItem(
          id: item.id,
          name: item.name,
          detail: item.detail,
          checked: value,
          createdAt: item.createdAt,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          'Grocery list',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.textHi,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.ember),
        actions: [
          IconButton(
            tooltip: 'Clear list',
            icon: const Icon(PhosphorIconsBold.trash, color: AppColors.ember),
            onPressed: _items.isEmpty ? null : _clearAll,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.line),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.ember))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: PrimaryButton(
                    label: 'Choose recipes',
                    icon: PhosphorIconsBold.listChecks,
                    onPressed: _chooseRecipes,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _items.isEmpty
                      ? _buildEmptyState(tt)
                      : _buildList(tt),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(TextTheme tt) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            PhosphorIconsDuotone.shoppingCart,
            size: 64,
            color: AppColors.textLow,
          ),
          const SizedBox(height: 16),
          Text(
            'No grocery list yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textHi,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose recipes to build one.',
            style: tt.bodyMedium?.copyWith(color: AppColors.textMid),
          ),
        ],
      ),
    );
  }

  Widget _buildList(TextTheme tt) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _items[index];
        final checked = item.checked;
        return GlassPanel(
          frosted: false,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: CheckboxListTile(
            value: checked,
            onChanged: (v) => _toggleChecked(item, v ?? false),
            activeColor: AppColors.ember,
            checkColor: AppColors.canvas,
            title: Text(
              item.name,
              style: tt.bodyMedium?.copyWith(
                color: checked ? AppColors.textLow : AppColors.textHi,
                decoration:
                    checked ? TextDecoration.lineThrough : TextDecoration.none,
                decorationColor: AppColors.textLow,
              ),
            ),
            subtitle: item.detail != null
                ? Text(
                    item.detail!,
                    style: tt.bodySmall?.copyWith(
                      color: checked ? AppColors.textLow : AppColors.textMid,
                      decoration: checked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: AppColors.textLow,
                    ),
                  )
                : null,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Recipe picker dialog
// ---------------------------------------------------------------------------

class _RecipePickerDialog extends StatefulWidget {
  final List<Recipe> recipes;
  const _RecipePickerDialog({required this.recipes});

  @override
  State<_RecipePickerDialog> createState() => _RecipePickerDialogState();
}

class _RecipePickerDialogState extends State<_RecipePickerDialog> {
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        'Choose recipes',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textHi,
        ),
      ),
      content: widget.recipes.isEmpty
          ? Text(
              'No recipes yet. Add some recipes first.',
              style: tt.bodyMedium?.copyWith(color: AppColors.textMid),
            )
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.recipes.length,
                itemBuilder: (context, index) {
                  final recipe = widget.recipes[index];
                  return CheckboxListTile(
                    value: _selected.contains(recipe.id),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selected.add(recipe.id);
                        } else {
                          _selected.remove(recipe.id);
                        }
                      });
                    },
                    activeColor: AppColors.ember,
                    checkColor: AppColors.canvas,
                    title: Text(
                      recipe.title,
                      style: tt.bodyMedium?.copyWith(color: AppColors.textHi),
                    ),
                  );
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textMid),
          ),
        ),
        TextButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selected),
          child: Text(
            'Add to list',
            style: TextStyle(
              color: _selected.isEmpty ? AppColors.textLow : AppColors.ember,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
