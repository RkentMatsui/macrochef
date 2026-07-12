import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/database.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../widgets/glass_panel.dart';
import '../widgets/primary_button.dart';
import 'session_logger_screen.dart';
import 'template_editor_screen.dart';

/// A program plus its ordered days, loaded together for the programs list.
typedef _ProgramWithDays = ({WorkoutTemplate program, List<TemplateDay> days});

/// Browse, create, edit, delete workout programs, and start a session from any
/// of a program's days.
class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  late Future<List<_ProgramWithDays>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _loadPrograms();
  }

  Future<List<_ProgramWithDays>> _loadPrograms() async {
    final repo = ref.read(trainingRepositoryProvider);
    final programs = await repo.allPrograms();
    final result = <_ProgramWithDays>[];
    for (final program in programs) {
      final days = await repo.daysForProgram(program.id);
      result.add((program: program, days: days));
    }
    return result;
  }

  Future<void> _openEditor({int? programId}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TemplateEditorScreen(programId: programId),
      ),
    );
    if (saved == true && mounted) setState(_load);
  }

  Future<void> _startFromDay(TemplateDay day) async {
    final navigator = Navigator.of(context);
    final svc = ref.read(trainingServiceProvider);
    final sessionId = await svc.startFromDay(day.id, todayDate());
    if (!mounted) return;
    await navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => SessionLoggerScreen(sessionId: sessionId),
      ),
    );
    if (mounted) setState(_load);
  }

  Future<void> _confirmDelete(WorkoutTemplate program) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete program?',
            style: TextStyle(color: AppColors.textHi)),
        content: Text('“${program.name}” will be removed permanently.',
            style: const TextStyle(color: AppColors.textMid)),
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
    await ref.read(trainingRepositoryProvider).deleteProgram(program.id);
    if (mounted) setState(_load);
  }

  Future<void> _reorderPrograms(
      List<_ProgramWithDays> programs, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    if (newIndex == oldIndex) return;
    setState(() {
      final moved = programs.removeAt(oldIndex);
      programs.insert(newIndex, moved);
    });
    final orderedIds = programs.map((p) => p.program.id).toList();
    await ref.read(trainingRepositoryProvider).reorderPrograms(orderedIds);
    if (mounted) setState(_load);
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
          'Programs',
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
      body: FutureBuilder<List<_ProgramWithDays>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.ember));
          }
          final programs = snap.data ?? [];
          if (programs.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(PhosphorIconsDuotone.listChecks,
                          size: 56, color: AppColors.textLow),
                      const SizedBox(height: 12),
                      Text('No programs yet',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHi,
                          )),
                      const SizedBox(height: 4),
                      const Text('Build a reusable program to start faster.',
                          style: TextStyle(color: AppColors.textMid)),
                    ],
                  ),
                ),
              ],
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            buildDefaultDragHandles: false,
            itemCount: programs.length,
            onReorder: (oldIndex, newIndex) =>
                _reorderPrograms(programs, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final p = programs[index];
              return Padding(
                key: ValueKey(p.program.id),
                padding: const EdgeInsets.only(bottom: 10),
                child: _programCard(tt, p.program, p.days, index),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: PrimaryButton(
          label: 'New program',
          icon: PhosphorIconsBold.plus,
          onPressed: () => _openEditor(),
        ),
      ),
    );
  }

  Widget _programCard(
      TextTheme tt, WorkoutTemplate program, List<TemplateDay> days, int index) {
    return GlassPanel(
      frosted: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openEditor(programId: program.id),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(PhosphorIconsRegular.dotsSixVertical,
                        color: AppColors.textLow, size: 20),
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.ember.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(PhosphorIconsDuotone.listChecks,
                      color: AppColors.ember, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(program.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHi,
                          )),
                      if (program.notes != null &&
                          program.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(program.notes!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall
                                ?.copyWith(color: AppColors.textMid)),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Delete',
                  icon: const Icon(PhosphorIconsRegular.trash,
                      color: AppColors.textLow, size: 18),
                  onPressed: () => _confirmDelete(program),
                ),
              ],
            ),
          ),
          if (days.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final day in days) _dayRow(day),
          ],
        ],
      ),
    );
  }

  Widget _dayRow(TemplateDay day) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const SizedBox(width: 4),
          const Icon(PhosphorIconsBold.dot, size: 10, color: AppColors.ember),
          const SizedBox(width: 10),
          Expanded(
            child: Text(day.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textHi,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Start workout',
            icon: const Icon(PhosphorIconsBold.play,
                color: AppColors.ember, size: 20),
            onPressed: () => _startFromDay(day),
          ),
        ],
      ),
    );
  }
}
