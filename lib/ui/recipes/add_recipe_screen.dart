import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/recipe.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../widgets/primary_button.dart';

class AddRecipeScreen extends ConsumerStatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  ConsumerState<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends ConsumerState<AddRecipeScreen> {
  final TextEditingController _rawTextCtrl = TextEditingController();
  bool _isListening = false;
  bool _isParsing = false;

  // Parsed / editable state
  ParsedRecipe? _parsed;
  final TextEditingController _titleCtrl = TextEditingController();
  List<TextEditingController> _stepCtrlList = [];
  // Ingredients are shown read-only from parse (task scope)
  List<Ingredient> _ingredients = [];

  @override
  void dispose() {
    if (_isListening) {
      ref.read(speechProvider).stopListening();
    }
    _rawTextCtrl.dispose();
    _titleCtrl.dispose();
    for (final c in _stepCtrlList) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Dictate ──────────────────────────────────────────────────────────────

  Future<void> _toggleDictate() async {
    final speech = ref.read(speechProvider);
    if (_isListening) {
      await speech.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await speech.startListening(
        (partial) {
          // Partial: no-op with stub; real impl would show live caption
        },
        (finalText) {
          if (mounted) {
            setState(() {
              final current = _rawTextCtrl.text;
              _rawTextCtrl.text =
                  current.isEmpty ? finalText : '$current $finalText';
              _rawTextCtrl.selection = TextSelection.fromPosition(
                TextPosition(offset: _rawTextCtrl.text.length),
              );
            });
          }
        },
      );
    }
  }

  // ── Parse ─────────────────────────────────────────────────────────────────

  Future<void> _parse() async {
    final raw = _rawTextCtrl.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or dictate a recipe first.')),
      );
      return;
    }

    setState(() => _isParsing = true);

    try {
      final llm = await ref.read(llmProvider.future);
      final recipeService = ref.read(recipeServiceProvider);
      final parsed = await recipeService.parse(raw, llm);

      // Dispose old controllers before replacing
      for (final c in _stepCtrlList) {
        c.dispose();
      }

      setState(() {
        _parsed = parsed;
        _titleCtrl.text = parsed.title;
        _ingredients = List<Ingredient>.from(parsed.ingredients);
        _stepCtrlList =
            parsed.steps.map((s) => TextEditingController(text: s)).toList();
        _isParsing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isParsing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Could not parse recipe. Check your API key in Settings.',
          ),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_parsed == null) return;

    final editedTitle = _titleCtrl.text.trim();
    final editedSteps =
        _stepCtrlList.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

    final editedRecipe = ParsedRecipe(
      title: editedTitle.isEmpty ? 'Untitled Recipe' : editedTitle,
      ingredients: _ingredients,
      steps: editedSteps,
    );

    try {
      final recipeService = ref.read(recipeServiceProvider);
      final repo = ref.read(recipeRepositoryProvider);
      await recipeService.save(editedRecipe, repo);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe saved!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save recipe: $e')),
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
          'Add Recipe',
          style: tt.titleMedium?.copyWith(color: AppColors.textHi),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.ember),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.line),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputSection(tt),
            const SizedBox(height: 24),
            if (_isParsing) _buildParsingSpinner(),
            if (!_isParsing && _parsed == null) ...[
              PrimaryButton(
                label: 'Parse Recipe',
                icon: PhosphorIconsDuotone.sparkle,
                onPressed: _parse,
              ),
            ],
            if (!_isParsing && _parsed != null) ...[
              _buildReviewSection(tt),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Save Recipe',
                icon: PhosphorIconsRegular.bookmarkSimple,
                onPressed: _save,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _parse,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMid,
                  side: const BorderSide(color: AppColors.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                child: const Text('Re-parse'),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Paste or type your recipe',
          style: tt.bodySmall?.copyWith(color: AppColors.textLow),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _rawTextCtrl,
          maxLines: 8,
          style: const TextStyle(
            color: AppColors.textHi,
            fontSize: 14,
            height: 1.5,
          ),
          decoration: const InputDecoration(
            hintText: 'E.g. "Chicken Stir-Fry\n\n200g chicken breast, 1 cup broccoli…\n\n1. Heat oil…"',
            hintStyle: TextStyle(color: AppColors.textLow, fontSize: 13),
            filled: true,
            fillColor: AppColors.surfaceHigh,
            contentPadding: EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: AppColors.ember),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _toggleDictate,
              icon: Icon(
                _isListening ? PhosphorIconsFill.stop : PhosphorIconsDuotone.microphone,
                size: 18,
              ),
              label: Text(_isListening ? 'Stop' : 'Dictate'),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    _isListening ? AppColors.fat : AppColors.emberSoft,
                side: BorderSide(
                  color: _isListening ? AppColors.fat : AppColors.ember,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildParsingSpinner() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.ember),
          const SizedBox(height: 16),
          Text(
            'Parsing recipe…',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textMid),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildReviewSection(TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Review & edit',
          style: tt.bodySmall?.copyWith(color: AppColors.textLow),
        ),
        const SizedBox(height: 12),

        // Title
        TextField(
          controller: _titleCtrl,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: AppColors.textHi,
          ),
          decoration: const InputDecoration(
            hintText: 'Recipe title',
            hintStyle: TextStyle(color: AppColors.textLow),
            filled: true,
            fillColor: AppColors.surfaceHigh,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

        const SizedBox(height: 20),

        // Ingredients (read-only chips)
        if (_ingredients.isNotEmpty) ...[
          Text(
            'Ingredients',
            style: tt.labelLarge?.copyWith(color: AppColors.textMid),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ingredients.map((ing) {
              final label = [
                if (ing.quantity != null) ing.quantity!,
                if (ing.unit != null) ing.unit!,
                ing.name,
              ].join(' ');
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.line),
                ),
                child: Text(
                  label,
                  style: tt.bodySmall?.copyWith(color: AppColors.textHi),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Steps (editable)
        Text(
          'Steps',
          style: tt.labelLarge?.copyWith(color: AppColors.textMid),
        ),
        const SizedBox(height: 8),
        ..._stepCtrlList.asMap().entries.map((entry) {
          final idx = entry.key;
          final ctrl = entry.value;
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
                      color: AppColors.textHi,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceHigh,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
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
              ],
            ),
          );
        }),
      ],
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
  }
}
