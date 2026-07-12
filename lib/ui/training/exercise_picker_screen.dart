import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/database.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../widgets/primary_button.dart';

/// The coarse muscle keys the app tracks for weekly volume/heatmap (matching
/// `muscleKeyForId` in the atlas). Offered as a picker so a custom exercise's
/// muscle always maps to a tracked group rather than a free-text typo that
/// silently falls into "other" and never shows on the muscle map.
const List<String> kTrackedMuscleKeys = [
  'chest',
  'back',
  'shoulders',
  'rear-delts',
  'biceps',
  'triceps',
  'forearms',
  'core',
  'quads',
  'hamstrings',
  'glutes',
  'calves',
  'adductors',
  'abductors',
  'tibialis',
];

/// "rear-delts" → "Rear delts", "core" → "Core".
String muscleLabel(String key) {
  final spaced = key.replaceAll('-', ' ');
  return spaced.isEmpty
      ? spaced
      : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

/// Result of the exercise editor sheet: the [saved] exercise (create or edit),
/// or [deleted] == true when the exercise was removed.
class _EditorResult {
  final Exercise? saved;
  final bool deleted;
  const _EditorResult({this.saved, this.deleted = false});
}

/// Searchable exercise library with category filter chips and a "+ Custom
/// exercise" creator. Custom exercises can be edited or deleted in place.
/// Pops with the chosen [Exercise].
class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  ConsumerState<ExercisePickerScreen> createState() =>
      _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  static const _categories = ['strength', 'cardio', 'class', 'mobility'];

  late Future<List<Exercise>> _future;
  String _query = '';
  String? _category;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref.read(trainingRepositoryProvider).allExercises();
  }

  Future<_EditorResult?> _openEditor({Exercise? existing}) {
    return showModalBottomSheet<_EditorResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ExerciseEditorSheet(existing: existing),
    );
  }

  /// "+ Custom exercise": create then select it for logging (pops the picker).
  Future<void> _createCustom() async {
    final result = await _openEditor();
    if (result?.saved != null && mounted) {
      Navigator.of(context).pop(result!.saved);
    }
  }

  /// Edit/delete an existing custom exercise, then refresh the list in place.
  Future<void> _manageExercise(Exercise e) async {
    final result = await _openEditor(existing: e);
    if (result == null || !mounted) return;
    setState(_load);
    if (result.deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted "${e.name}".')),
      );
    }
  }

  /// Make an editable custom copy of a built-in [e] and open it in the editor so
  /// the user can adjust muscles/metrics on their own copy (built-ins are
  /// re-seeded on launch, so they can't be edited in place).
  Future<void> _duplicateAsCustom(Exercise e) async {
    final repo = ref.read(trainingRepositoryProvider);
    final id = await repo.duplicateAsCustom(e);
    final copy = await repo.exerciseById(id);
    if (!mounted) return;
    setState(_load); // show the new copy immediately
    if (copy != null) {
      await _openEditor(existing: copy);
      if (mounted) setState(_load);
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
          'Add exercise',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              autofocus: true,
              onChanged: (s) => setState(() => _query = s.trim().toLowerCase()),
              style: const TextStyle(color: AppColors.textHi),
              decoration: InputDecoration(
                hintText: 'Search exercises',
                hintStyle: const TextStyle(color: AppColors.textLow),
                prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass,
                    color: AppColors.textMid),
                filled: true,
                fillColor: AppColors.surfaceHigh,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip('All', _category == null,
                    () => setState(() => _category = null)),
                for (final c in _categories)
                  _chip(_label(c), _category == c,
                      () => setState(() => _category = c)),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Exercise>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.ember),
                  );
                }
                final all = snap.data ?? [];
                final filtered = all.where((e) {
                  if (_category != null && e.category != _category) return false;
                  if (_query.isEmpty) return true;
                  return e.name.toLowerCase().contains(_query) ||
                      (e.primaryMuscle?.toLowerCase().contains(_query) ??
                          false) ||
                      (e.equipment?.toLowerCase().contains(_query) ?? false) ||
                      (e.description?.toLowerCase().contains(_query) ?? false);
                }).toList();

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: filtered.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == filtered.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: PrimaryButton(
                          label: 'Custom exercise',
                          icon: PhosphorIconsBold.plus,
                          onPressed: _createCustom,
                        ),
                      );
                    }
                    final e = filtered[index];
                    return _exerciseTile(tt, e);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseTile(TextTheme tt, Exercise e) {
    final subtitle = [
      _label(e.category),
      if (e.primaryMuscle != null) muscleLabel(e.primaryMuscle!),
      if (e.equipment != null) e.equipment!,
    ].join(' · ');
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).pop(e),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Icon(_categoryIcon(e.category), color: AppColors.ember, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(e.name,
                            style: tt.bodyMedium?.copyWith(
                              color: AppColors.textHi,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                      if (e.isCustom) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.ember.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Custom',
                              style: TextStyle(
                                  color: AppColors.ember,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: tt.bodySmall?.copyWith(color: AppColors.textMid)),
                ],
              ),
            ),
            // Custom exercises can be edited/deleted in place; built-ins are
            // catalog-managed (their muscle/how-to are re-seeded on launch), so
            // instead they offer a "duplicate as custom" editable copy.
            if (e.isCustom)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(PhosphorIconsRegular.pencilSimple,
                    color: AppColors.textMid, size: 20),
                tooltip: 'Edit',
                onPressed: () => _manageExercise(e),
              )
            else
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                color: AppColors.surfaceHigh,
                icon: const Icon(PhosphorIconsRegular.dotsThreeVertical,
                    color: AppColors.textMid, size: 20),
                tooltip: 'More',
                onSelected: (v) {
                  if (v == 'howto') {
                    _showHowTo(tt, e);
                  } else if (v == 'duplicate') {
                    _duplicateAsCustom(e);
                  }
                },
                itemBuilder: (_) => [
                  if (e.description != null && e.description!.trim().isNotEmpty)
                    const PopupMenuItem(
                      value: 'howto',
                      child: Text('How to',
                          style: TextStyle(color: AppColors.textHi)),
                    ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Text('Duplicate as custom',
                        style: TextStyle(color: AppColors.textHi)),
                  ),
                ],
              ),
            const SizedBox(width: 8),
            const Icon(PhosphorIconsRegular.plusCircle,
                color: AppColors.ember, size: 22),
          ],
        ),
      ),
    );
  }

  void _showHowTo(TextTheme tt, Exercise e) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(e.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHi,
                )),
            const SizedBox(height: 4),
            Text(
              [
                _label(e.category),
                if (e.primaryMuscle != null) muscleLabel(e.primaryMuscle!),
                if (e.equipment != null) e.equipment!,
              ].join(' · '),
              style: tt.bodySmall?.copyWith(color: AppColors.textMid),
            ),
            const SizedBox(height: 14),
            Text(e.description ?? '',
                style: tt.bodyMedium
                    ?.copyWith(color: AppColors.textHi, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        backgroundColor: AppColors.surfaceHigh,
        selectedColor: AppColors.ember.withValues(alpha: 0.16),
        labelStyle: TextStyle(
          color: selected ? AppColors.ember : AppColors.textMid,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        side: BorderSide(color: selected ? AppColors.ember : AppColors.line),
      ),
    );
  }

  static String _label(String category) => switch (category) {
        'strength' => 'Strength',
        'cardio' => 'Cardio',
        'class' => 'Class',
        'mobility' => 'Mobility',
        _ => category,
      };

  static IconData _categoryIcon(String category) => switch (category) {
        'strength' => PhosphorIconsDuotone.barbell,
        'cardio' => PhosphorIconsDuotone.personSimpleRun,
        'class' => PhosphorIconsDuotone.users,
        'mobility' => PhosphorIconsDuotone.personSimpleTaiChi,
        _ => PhosphorIconsDuotone.barbell,
      };
}

// ---------------------------------------------------------------------------
// Exercise editor sheet (create + edit + delete)
// ---------------------------------------------------------------------------

class _ExerciseEditorSheet extends ConsumerStatefulWidget {
  /// When non-null, the sheet edits this exercise; otherwise it creates a new
  /// custom one.
  final Exercise? existing;
  const _ExerciseEditorSheet({this.existing});

  @override
  ConsumerState<_ExerciseEditorSheet> createState() =>
      _ExerciseEditorSheetState();
}

class _ExerciseEditorSheetState extends ConsumerState<_ExerciseEditorSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _equipmentCtrl;
  late final TextEditingController _descCtrl;
  late String _category;
  String? _primaryMuscle;
  late Set<String> _secondary;
  late bool _tracksWeight;
  late bool _tracksReps;
  late bool _tracksDuration;
  late bool _tracksDistance;
  bool _saving = false;
  bool _deleting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _equipmentCtrl = TextEditingController(text: e?.equipment ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _category = e?.category ?? 'strength';
    _primaryMuscle =
        (e?.primaryMuscle != null && kTrackedMuscleKeys.contains(e!.primaryMuscle))
            ? e.primaryMuscle
            : null;
    _secondary = (e?.secondaryMuscles ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && kTrackedMuscleKeys.contains(s))
        .toSet();
    _tracksWeight = e?.tracksWeight ?? true;
    _tracksReps = e?.tracksReps ?? true;
    _tracksDuration = e?.tracksDuration ?? false;
    _tracksDistance = e?.tracksDistance ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _equipmentCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _toast('Enter an exercise name.');
      return;
    }
    if (!_tracksWeight && !_tracksReps && !_tracksDuration && !_tracksDistance) {
      _toast('Pick at least one tracked metric.');
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(trainingRepositoryProvider);
    final equip = _equipmentCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    // Secondary muscles never include the primary; store as a comma-list.
    final secondary =
        (_secondary.where((m) => m != _primaryMuscle).toList()..sort())
            .join(',');

    if (_isEdit) {
      await repo.updateExercise(
        widget.existing!.id,
        ExercisesCompanion(
          name: Value(name),
          category: Value(_category),
          primaryMuscle: Value(_primaryMuscle),
          secondaryMuscles: Value(secondary.isEmpty ? null : secondary),
          equipment: Value(equip.isEmpty ? null : equip),
          description: Value(desc.isEmpty ? null : desc),
          tracksWeight: Value(_tracksWeight),
          tracksReps: Value(_tracksReps),
          tracksDuration: Value(_tracksDuration),
          tracksDistance: Value(_tracksDistance),
        ),
      );
      final updated = await repo.exerciseById(widget.existing!.id);
      if (mounted) Navigator.of(context).pop(_EditorResult(saved: updated));
      return;
    }

    final id = await repo.insertExercise(ExercisesCompanion.insert(
      name: name,
      category: _category,
      primaryMuscle: Value(_primaryMuscle),
      secondaryMuscles: Value(secondary.isEmpty ? null : secondary),
      equipment: Value(equip.isEmpty ? null : equip),
      description: Value(desc.isEmpty ? null : desc),
      tracksWeight: Value(_tracksWeight),
      tracksReps: Value(_tracksReps),
      tracksDuration: Value(_tracksDuration),
      tracksDistance: Value(_tracksDistance),
      isCustom: const Value(true),
    ));
    final created = await repo.exerciseById(id);
    if (mounted) Navigator.of(context).pop(_EditorResult(saved: created));
  }

  Future<void> _delete() async {
    final e = widget.existing!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete exercise?',
            style: TextStyle(color: AppColors.textHi)),
        content: Text('This permanently removes "${e.name}".',
            style: const TextStyle(color: AppColors.textMid)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.fat)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    final ok = await ref.read(trainingRepositoryProvider).deleteExercise(e.id);
    if (!mounted) return;
    if (!ok) {
      setState(() => _deleting = false);
      _toast("Can't delete — it's used in logged sets or a program.");
      return;
    }
    Navigator.of(context).pop(const _EditorResult(deleted: true));
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, viewInsets + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(_isEdit ? 'Edit exercise' : 'Custom exercise',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHi,
                )),
            const SizedBox(height: 16),
            _field(_nameCtrl, 'Name'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final c in ['strength', 'cardio', 'class', 'mobility'])
                  ChoiceChip(
                    label: Text(_ExercisePickerScreenState._label(c)),
                    selected: _category == c,
                    showCheckmark: false,
                    backgroundColor: AppColors.surfaceHigh,
                    selectedColor: AppColors.ember.withValues(alpha: 0.16),
                    labelStyle: TextStyle(
                      color:
                          _category == c ? AppColors.ember : AppColors.textMid,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionLabel('Primary muscle'),
            const SizedBox(height: 8),
            _muscleDropdown(),
            const SizedBox(height: 16),
            _sectionLabel('Secondary muscles (optional)'),
            const SizedBox(height: 8),
            _secondaryChips(),
            const SizedBox(height: 14),
            _field(_equipmentCtrl, 'Equipment (optional)'),
            const SizedBox(height: 12),
            _field(_descCtrl, 'How-to / form cues (optional)', maxLines: 3),
            const SizedBox(height: 8),
            _flag('Tracks weight', _tracksWeight,
                (v) => setState(() => _tracksWeight = v)),
            _flag('Tracks reps', _tracksReps,
                (v) => setState(() => _tracksReps = v)),
            _flag('Tracks duration', _tracksDuration,
                (v) => setState(() => _tracksDuration = v)),
            _flag('Tracks distance', _tracksDistance,
                (v) => setState(() => _tracksDistance = v)),
            const SizedBox(height: 16),
            PrimaryButton(
              label: _isEdit ? 'Save changes' : 'Save exercise',
              icon: PhosphorIconsBold.check,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
            if (_isEdit) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _deleting ? null : _delete,
                icon: const Icon(PhosphorIconsRegular.trash,
                    color: AppColors.fat, size: 18),
                label: Text(_deleting ? 'Deleting…' : 'Delete exercise',
                    style: const TextStyle(
                        color: AppColors.fat, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textMid,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      );

  Widget _muscleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _primaryMuscle,
          isExpanded: true,
          dropdownColor: AppColors.surfaceHigh,
          hint: const Text('None / other',
              style: TextStyle(color: AppColors.textLow)),
          style: const TextStyle(color: AppColors.textHi, fontSize: 15),
          icon: const Icon(PhosphorIconsRegular.caretDown,
              color: AppColors.textMid, size: 18),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('None / other',
                  style: TextStyle(color: AppColors.textLow)),
            ),
            for (final m in kTrackedMuscleKeys)
              DropdownMenuItem<String?>(
                value: m,
                child: Text(muscleLabel(m)),
              ),
          ],
          onChanged: (v) => setState(() {
            _primaryMuscle = v;
            _secondary.remove(v); // primary can't also be secondary
          }),
        ),
      ),
    );
  }

  Widget _secondaryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in kTrackedMuscleKeys)
          if (m != _primaryMuscle)
            FilterChip(
              label: Text(muscleLabel(m)),
              selected: _secondary.contains(m),
              showCheckmark: false,
              backgroundColor: AppColors.surfaceHigh,
              selectedColor: AppColors.ember.withValues(alpha: 0.16),
              labelStyle: TextStyle(
                color:
                    _secondary.contains(m) ? AppColors.ember : AppColors.textMid,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              side: BorderSide(
                  color:
                      _secondary.contains(m) ? AppColors.ember : AppColors.line),
              onSelected: (on) => setState(() {
                if (on) {
                  _secondary.add(m);
                } else {
                  _secondary.remove(m);
                }
              }),
            ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textHi),
      decoration: InputDecoration(
        hintText: hint,
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
    );
  }

  Widget _flag(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeColor: AppColors.ember,
      title: Text(label,
          style: const TextStyle(color: AppColors.textHi, fontSize: 14)),
      value: value,
      onChanged: onChanged,
    );
  }
}
