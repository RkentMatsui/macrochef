import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/database.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../widgets/glass_panel.dart';
import '../widgets/primary_button.dart';
import 'exercise_picker_screen.dart';

/// Mutable working copy of one planned exercise inside the editor.
class _PlannedExercise {
  final Exercise exercise;
  int? targetSets;
  String? targetReps; // text, allows "8-12"
  double? targetWeightKg;
  int? targetDurationSec;
  double? targetDistanceM;

  _PlannedExercise(this.exercise, {
    this.targetSets,
    this.targetReps,
    this.targetWeightKg,
    this.targetDurationSec,
    this.targetDistanceM,
  });
}

/// Mutable working copy of one day inside a program.
class _DayDraft {
  int? id; // existing day id, null = new (unsaved) day
  final TextEditingController nameCtrl;
  final List<_PlannedExercise> exercises;
  _DayDraft({this.id, required String name, List<_PlannedExercise>? exercises})
      : nameCtrl = TextEditingController(text: name),
        exercises = exercises ?? [];
}

/// Create or edit a program ([WorkoutTemplate]): name + notes + an ordered list
/// of named days, each with its own ordered list of exercises (reusing
/// [ExercisePickerScreen]) with per-exercise targets. Pops with `true` on save
/// so the caller can refresh.
class TemplateEditorScreen extends ConsumerStatefulWidget {
  final int? programId; // null = create new program
  const TemplateEditorScreen({super.key, this.programId});

  @override
  ConsumerState<TemplateEditorScreen> createState() =>
      _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final List<_DayDraft> _days = [];
  final Set<int> _removedDayIds = {};
  bool _loading = true;
  bool _saving = false;

  bool get _isEditing => widget.programId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    for (final d in _days) {
      d.nameCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(trainingRepositoryProvider);
    if (widget.programId != null) {
      final program = await repo.programById(widget.programId!);
      if (program != null) {
        _nameCtrl.text = program.name;
        _notesCtrl.text = program.notes ?? '';
      }
      final days = await repo.daysForProgram(widget.programId!);
      for (final day in days) {
        final planned = await repo.dayExercises(day.id);
        final exercises = <_PlannedExercise>[];
        for (final te in planned) {
          final ex = await repo.exerciseById(te.exerciseId);
          if (ex == null) continue;
          exercises.add(_PlannedExercise(
            ex,
            targetSets: te.targetSets,
            targetReps: te.targetReps,
            targetWeightKg: te.targetWeightKg,
            targetDurationSec: te.targetDurationSec,
            targetDistanceM: te.targetDistanceM,
          ));
        }
        _days.add(_DayDraft(id: day.id, name: day.name, exercises: exercises));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addExercise(_DayDraft day) async {
    final picked = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
    if (picked == null) return;
    setState(() {
      day.exercises.add(_PlannedExercise(picked, targetSets: 3));
    });
  }

  void _removeExercise(_DayDraft day, _PlannedExercise p) {
    setState(() => day.exercises.remove(p));
  }

  void _addDay() {
    setState(() {
      _days.add(_DayDraft(name: 'Day ${_days.length + 1}'));
    });
  }

  void _removeDay(_DayDraft day) {
    setState(() {
      _days.remove(day);
      if (day.id != null) _removedDayIds.add(day.id!);
      day.nameCtrl.dispose();
    });
  }

  void _reorderDays(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final moved = _days.removeAt(oldIndex);
      _days.insert(newIndex, moved);
    });
  }

  void _reorderExercises(_DayDraft day, int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final moved = day.exercises.removeAt(oldIndex);
      day.exercises.insert(newIndex, moved);
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a program name.')),
      );
      return;
    }
    if (_days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one day.')),
      );
      return;
    }
    for (final day in _days) {
      if (day.nameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Each day needs a name.')),
        );
        return;
      }
      if (day.exercises.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Add at least one exercise to "${day.nameCtrl.text.trim()}".')),
        );
        return;
      }
    }
    setState(() => _saving = true);
    final repo = ref.read(trainingRepositoryProvider);
    final notes = _notesCtrl.text.trim();

    int programId;
    if (_isEditing) {
      programId = widget.programId!;
      await repo.updateProgram(programId,
          name: name, notes: notes.isEmpty ? null : notes);
    } else {
      programId = await repo.createProgram(
          name: name, notes: notes.isEmpty ? null : notes);
    }

    for (final id in _removedDayIds) {
      await repo.deleteDay(id);
    }

    for (var d = 0; d < _days.length; d++) {
      final day = _days[d];
      final dayName = day.nameCtrl.text.trim();
      int dayId;
      if (day.id != null) {
        dayId = day.id!;
        await repo.updateDay(dayId, name: dayName, position: d);
      } else {
        dayId = await repo.createDay(
            programId: programId, name: dayName, position: d);
        day.id = dayId;
      }

      final companions = <TemplateExercisesCompanion>[];
      for (var i = 0; i < day.exercises.length; i++) {
        final p = day.exercises[i];
        companions.add(TemplateExercisesCompanion.insert(
          dayId: dayId,
          exerciseId: p.exercise.id,
          position: i,
          targetSets: Value(p.targetSets),
          targetReps: Value(p.targetReps),
          targetWeightKg: Value(p.targetWeightKg),
          targetDurationSec: Value(p.targetDurationSec),
          targetDistanceM: Value(p.targetDistanceM),
        ));
      }
      await repo.setDayExercises(dayId, companions);
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.ember),
        title: Text(
          _isEditing ? 'Edit program' : 'New program',
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
              child: CircularProgressIndicator(color: AppColors.ember))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                _field(_nameCtrl, 'Program name'),
                const SizedBox(height: 12),
                _field(_notesCtrl, 'Notes (optional)', maxLines: 2),
                const SizedBox(height: 20),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: _days.length,
                  onReorder: _reorderDays,
                  itemBuilder: (context, index) {
                    final day = _days[index];
                    return Padding(
                      key: ObjectKey(day),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _dayCard(day, index),
                    );
                  },
                ),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: _addDay,
                  icon: const Icon(PhosphorIconsBold.plus,
                      color: AppColors.ember, size: 18),
                  label: const Text('Add day',
                      style: TextStyle(
                          color: AppColors.ember, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.ember),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _loading
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: PrimaryButton(
                label: 'Save program',
                icon: PhosphorIconsBold.check,
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ),
    );
  }

  Widget _dayCard(_DayDraft day, int index) {
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(PhosphorIconsRegular.dotsSixVertical,
                      color: AppColors.textLow, size: 20),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: day.nameCtrl,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHi,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Day name',
                    hintStyle: TextStyle(color: AppColors.textLow),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(PhosphorIconsRegular.trash,
                    size: 18, color: AppColors.textLow),
                onPressed: () => _removeDay(day),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: day.exercises.length,
            onReorder: (oldIndex, newIndex) =>
                _reorderExercises(day, oldIndex, newIndex),
            itemBuilder: (context, i) {
              final p = day.exercises[i];
              return Padding(
                key: ObjectKey(p),
                padding: const EdgeInsets.only(bottom: 12),
                child: _exerciseCard(day, p, i),
              );
            },
          ),
          const SizedBox(height: 2),
          OutlinedButton.icon(
            onPressed: () => _addExercise(day),
            icon: const Icon(PhosphorIconsBold.plus,
                color: AppColors.ember, size: 16),
            label: const Text('Add exercise',
                style: TextStyle(
                    color: AppColors.ember, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.ember),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseCard(_DayDraft day, _PlannedExercise p, int index) {
    final e = p.exercise;
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(PhosphorIconsRegular.dotsSixVertical,
                      color: AppColors.textLow, size: 18),
                ),
              ),
              Expanded(
                child: Text(e.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHi,
                    )),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(PhosphorIconsRegular.trash,
                    size: 18, color: AppColors.textLow),
                onPressed: () => _removeExercise(day, p),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _targetField(
                  label: 'Sets',
                  initial: p.targetSets?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  digitsOnly: true,
                  onChanged: (v) => p.targetSets = int.tryParse(v),
                ),
                if (e.tracksReps)
                  _targetField(
                    label: 'Reps',
                    initial: p.targetReps ?? '',
                    width: 96,
                    onChanged: (v) =>
                        p.targetReps = v.trim().isEmpty ? null : v.trim(),
                  ),
                if (e.tracksWeight)
                  _targetField(
                    label: 'Weight (kg)',
                    initial: _fmt(p.targetWeightKg),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    onChanged: (v) => p.targetWeightKg = double.tryParse(v),
                  ),
                if (e.tracksDuration)
                  _targetField(
                    label: 'Duration (min)',
                    initial: p.targetDurationSec == null
                        ? ''
                        : (p.targetDurationSec! / 60).toString(),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    onChanged: (v) {
                      final mins = double.tryParse(v);
                      p.targetDurationSec =
                          mins == null ? null : (mins * 60).round();
                    },
                  ),
                if (e.tracksDistance)
                  _targetField(
                    label: 'Distance (km)',
                    initial: p.targetDistanceM == null
                        ? ''
                        : (p.targetDistanceM! / 1000).toString(),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    onChanged: (v) {
                      final km = double.tryParse(v);
                      p.targetDistanceM = km == null ? null : km * 1000;
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double? v) {
    if (v == null) return '';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  Widget _targetField({
    required String label,
    required String initial,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    bool digitsOnly = false,
    double width = 108,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMid,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: initial,
            keyboardType: keyboardType,
            inputFormatters:
                digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
            onChanged: onChanged,
            style: const TextStyle(color: AppColors.textHi, fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.surfaceHigh,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
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
}
