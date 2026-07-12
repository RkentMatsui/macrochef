import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/program_generator_service.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../widgets/glass_panel.dart';
import '../widgets/primary_button.dart';

/// AI training-program generator. Mirrors `generate_recipe_screen.dart`: a form
/// (goal / experience / equipment / days / minutes) → generate via the LLM →
/// preview & edit → save (persists templates + weekly schedule via the repo).
class ProgramGeneratorScreen extends ConsumerStatefulWidget {
  const ProgramGeneratorScreen({super.key});

  @override
  ConsumerState<ProgramGeneratorScreen> createState() =>
      _ProgramGeneratorScreenState();
}

const _experienceLevels = ['beginner', 'intermediate', 'advanced'];
const _equipmentOptions = [
  'Full gym',
  'Dumbbells only',
  'Home gym',
  'Bodyweight',
  'Bands & dumbbells',
];

class _ProgramGeneratorScreenState
    extends ConsumerState<ProgramGeneratorScreen> {
  final _goalCtrl = TextEditingController();

  String _experience = 'intermediate';
  String _equipment = 'Full gym';
  int _days = 3;
  int _minutes = 60;

  bool _loading = false;
  bool _saving = false;

  /// Mutable preview model once generated.
  List<_EditableTemplate>? _templates;
  Map<int, int> _schedule = {};
  String _programName = 'Generated Program';

  @override
  void dispose() {
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await checkAiReady(ref)) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Set up an AI provider in Settings to generate a plan')));
      return;
    }
    final goal = _goalCtrl.text.trim();
    setState(() {
      _loading = true;
      _templates = null;
    });
    try {
      final svc = await ref.read(programGeneratorServiceProvider.future);
      final program = await svc.generate(ProgramRequest(
        goal: goal.isEmpty ? 'general fitness' : goal,
        experience: _experience,
        equipment: _equipment,
        daysPerWeek: _days,
        sessionMinutes: _minutes,
      ));
      if (!mounted) return;
      setState(() {
        _programName = program.name;
        _templates =
            program.templates.map(_EditableTemplate.from).toList();
        _schedule = Map<int, int>.from(program.schedule);
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
    final templates = _templates;
    if (templates == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final svc = await ref.read(programGeneratorServiceProvider.future);
      final repo = ref.read(trainingRepositoryProvider);
      final program = GeneratedProgram(
        name: _programName,
        templates: templates.map((t) => t.toGenerated()).toList(),
        schedule: _schedule,
      );
      await svc.persist(program, repo);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
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
          'AI Program',
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
                  Text('Building your program…',
                      style: TextStyle(color: AppColors.textMid)),
                ],
              ),
            )
          : _templates != null
              ? _buildPreview(tt)
              : _buildInput(tt),
    );
  }

  // ── Input ────────────────────────────────────────────────────────────────

  Widget _buildInput(TextTheme tt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassPanel(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle('What is your goal?'),
                const SizedBox(height: 10),
                TextField(
                  controller: _goalCtrl,
                  style: tt.bodyMedium?.copyWith(color: AppColors.textHi),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText:
                        'Build muscle and get stronger, train chest and back',
                    hintStyle:
                        tt.bodyMedium?.copyWith(color: AppColors.textLow),
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassPanel(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle('Experience'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: _experienceLevels
                      .map((lvl) => _choiceChip(
                            label: _capitalize(lvl),
                            selected: _experience == lvl,
                            onTap: () => setState(() => _experience = lvl),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 18),
                _sectionTitle('Equipment'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _equipmentOptions
                      .map((eq) => _choiceChip(
                            label: eq,
                            selected: _equipment == eq,
                            onTap: () => setState(() => _equipment = eq),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassPanel(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _stepper(
                  label: 'Days per week',
                  value: _days,
                  min: 1,
                  max: 7,
                  onChanged: (v) => setState(() => _days = v),
                ),
                const SizedBox(height: 16),
                _stepper(
                  label: 'Minutes per session',
                  value: _minutes,
                  min: 20,
                  max: 120,
                  step: 5,
                  onChanged: (v) => setState(() => _minutes = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Generate program',
            icon: PhosphorIconsBold.sparkle,
            onPressed: _generate,
          ),
        ],
      ),
    );
  }

  // ── Preview & edit ─────────────────────────────────────────────────────────

  Widget _buildPreview(TextTheme tt) {
    final templates = _templates!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your program',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textHi,
              )),
          const SizedBox(height: 4),
          Text('${templates.length} templates · review and edit before saving',
              style: tt.bodySmall?.copyWith(color: AppColors.textMid)),
          const SizedBox(height: 20),
          for (var i = 0; i < templates.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _templateCard(tt, i, templates[i]),
            ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Save program',
            icon: PhosphorIconsBold.check,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _saving
                ? null
                : () => setState(() {
                      _templates = null;
                      _schedule = {};
                    }),
            icon: const Icon(PhosphorIconsBold.sparkle,
                color: AppColors.ember, size: 18),
            label: const Text('Start over',
                style: TextStyle(
                    color: AppColors.ember, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.ember, width: 1.5),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _templateCard(TextTheme tt, int index, _EditableTemplate t) {
    final days = _schedule.entries
        .where((e) => e.value == index)
        .map((e) => _dayLabel(e.key))
        .toList()
      ..sort();
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.ember.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${index + 1}',
                    style: const TextStyle(
                        color: AppColors.ember,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: t.nameCtrl,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHi,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          if (days.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Scheduled: ${days.join(', ')}',
                style: tt.bodySmall?.copyWith(color: AppColors.textMid)),
          ],
          const SizedBox(height: 10),
          for (var i = 0; i < t.exercises.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _exerciseRow(t, t.exercises[i]),
            ),
        ],
      ),
    );
  }

  Widget _exerciseRow(_EditableTemplate t, _EditableExercise e) {
    final detail = _exerciseDetail(e);
    return Row(
      children: [
        const Icon(PhosphorIconsBold.dot, size: 10, color: AppColors.ember),
        const SizedBox(width: 8),
        Expanded(
          child: Text(e.name,
              style: const TextStyle(
                  color: AppColors.textHi,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ),
        if (detail.isNotEmpty)
          Text(detail,
              style: const TextStyle(color: AppColors.textMid, fontSize: 13)),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(PhosphorIconsRegular.trash,
              size: 16, color: AppColors.textLow),
          onPressed: () => setState(() => t.exercises.remove(e)),
        ),
      ],
    );
  }

  static String _exerciseDetail(_EditableExercise e) {
    if (e.sets != null && e.reps != null) return '${e.sets} × ${e.reps}';
    if (e.sets != null) return '${e.sets} sets';
    if (e.durationSec != null) {
      return '${(e.durationSec! / 60).round()} min';
    }
    if (e.distanceM != null) {
      return '${(e.distanceM! / 1000).toStringAsFixed(1)} km';
    }
    return '';
  }

  // ── Small UI helpers ───────────────────────────────────────────────────────

  Widget _sectionTitle(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textHi,
        ),
      );

  Widget _choiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.ember
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.ember : AppColors.line,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? AppColors.canvas : AppColors.textMid,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }

  Widget _stepper({
    required String label,
    required int value,
    required int min,
    required int max,
    int step = 1,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                color: AppColors.textHi,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              )),
        ),
        _stepBtn(PhosphorIconsBold.minus,
            value > min ? () => onChanged(value - step) : null),
        SizedBox(
          width: 48,
          child: Text('$value',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textHi,
              )),
        ),
        _stepBtn(PhosphorIconsBold.plus,
            value < max ? () => onChanged(value + step) : null),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(icon,
            size: 16,
            color: enabled ? AppColors.ember : AppColors.textLow),
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _dayLabel(int dayOfWeek) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return (dayOfWeek >= 0 && dayOfWeek < labels.length)
        ? labels[dayOfWeek]
        : '?';
  }
}

/// Editable working copy of a generated template (name is a live controller).
class _EditableTemplate {
  final TextEditingController nameCtrl;
  final List<_EditableExercise> exercises;

  _EditableTemplate({required this.nameCtrl, required this.exercises});

  factory _EditableTemplate.from(GeneratedTemplate t) => _EditableTemplate(
        nameCtrl: TextEditingController(text: t.name),
        exercises: t.exercises.map(_EditableExercise.from).toList(),
      );

  GeneratedTemplate toGenerated() => GeneratedTemplate(
        name: nameCtrl.text.trim().isEmpty ? 'Workout' : nameCtrl.text.trim(),
        exercises: exercises.map((e) => e.toGenerated()).toList(),
      );
}

/// Editable working copy of a generated exercise prescription.
class _EditableExercise {
  final String name;
  final int? sets;
  final String? reps;
  final double? weightKg;
  final int? durationSec;
  final double? distanceM;

  _EditableExercise({
    required this.name,
    this.sets,
    this.reps,
    this.weightKg,
    this.durationSec,
    this.distanceM,
  });

  factory _EditableExercise.from(GeneratedExercise e) => _EditableExercise(
        name: e.nameOrSlug,
        sets: e.sets,
        reps: e.reps,
        weightKg: e.weightKg,
        durationSec: e.durationSec,
        distanceM: e.distanceM,
      );

  GeneratedExercise toGenerated() => GeneratedExercise(
        nameOrSlug: name,
        sets: sets,
        reps: reps,
        weightKg: weightKg,
        durationSec: durationSec,
        distanceM: distanceM,
      );
}
