import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../widgets/glass_panel.dart';

const List<String> _kDayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// A program day selectable in the schedule, carrying its id and a display
/// label of the form "program name · day name".
typedef _DayChoice = ({int id, String label});

/// Assign program days to each weekday (0=Mon..6=Sun). A day with no program
/// days is a rest day. Edits save immediately via the repository.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  bool _loading = true;
  List<_DayChoice> _days = [];
  final Map<int, String> _labelById = {};
  // day index (0..6) → ordered program-day ids planned for that day
  final Map<int, List<int>> _schedule = {for (var d = 0; d < 7; d++) d: <int>[]};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(trainingRepositoryProvider);
    final programs = await repo.allPrograms();
    final days = <_DayChoice>[];
    final labelById = <int, String>{};
    for (final program in programs) {
      final programDays = await repo.daysForProgram(program.id);
      for (final d in programDays) {
        final label = '${program.name} · ${d.name}';
        days.add((id: d.id, label: label));
        labelById[d.id] = label;
      }
    }
    final entries = await repo.fullSchedule();
    final map = {for (var d = 0; d < 7; d++) d: <int>[]};
    for (final e in entries) {
      map[e.dayOfWeek]!.add(e.dayId);
    }
    if (!mounted) return;
    setState(() {
      _days = days;
      _labelById
        ..clear()
        ..addAll(labelById);
      _schedule
        ..clear()
        ..addAll(map);
      _loading = false;
    });
  }

  Future<void> _editDay(int day) async {
    final selected = List<int>.from(_schedule[day]!);
    final result = await showModalBottomSheet<List<int>>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _DayPickerSheet(
        dayName: _kDayNames[day],
        days: _days,
        initiallySelected: selected,
      ),
    );
    if (result == null) return;
    await ref.read(trainingRepositoryProvider).setScheduleForDay(day, result);
    if (mounted) {
      setState(() => _schedule[day] = result);
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
          'Weekly schedule',
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.ember))
          : _days.isEmpty
              ? _emptyState()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    for (var day = 0; day < 7; day++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _dayRow(tt, day),
                      ),
                  ],
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(PhosphorIconsDuotone.calendarDots,
                size: 56, color: AppColors.textLow),
            const SizedBox(height: 12),
            Text('No program days yet',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHi,
                )),
            const SizedBox(height: 4),
            const Text(
              'Create a program with days first, then assign them to weekdays here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMid),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayRow(TextTheme tt, int day) {
    final ids = _schedule[day]!;
    final names = ids
        .map((id) => _labelById[id])
        .whereType<String>()
        .toList();
    final isRest = names.isEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _editDay(day),
      child: GlassPanel(
        frosted: false,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isRest ? AppColors.textLow : AppColors.ember)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isRest
                    ? PhosphorIconsDuotone.moon
                    : PhosphorIconsDuotone.barbell,
                color: isRest ? AppColors.textLow : AppColors.ember,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_kDayNames[day],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHi,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    isRest ? 'Rest day' : names.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(
                      color: isRest ? AppColors.textLow : AppColors.textMid,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(PhosphorIconsRegular.caretRight,
                color: AppColors.textLow),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet to pick which program days are planned for a single weekday.
/// Returns the ordered list of selected program-day ids (empty = rest day) or
/// null on cancel.
class _DayPickerSheet extends StatefulWidget {
  final String dayName;
  final List<_DayChoice> days;
  final List<int> initiallySelected;

  const _DayPickerSheet({
    required this.dayName,
    required this.days,
    required this.initiallySelected,
  });

  @override
  State<_DayPickerSheet> createState() => _DayPickerSheetState();
}

class _DayPickerSheetState extends State<_DayPickerSheet> {
  late final List<int> _selected = List<int>.from(widget.initiallySelected);

  void _toggle(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.dayName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHi,
                )),
            const SizedBox(height: 4),
            const Text('Tap program days to plan them. None = rest day.',
                style: TextStyle(color: AppColors.textMid, fontSize: 13)),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final d in widget.days)
                    _dayTile(d),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.textMid)),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.ember,
                      foregroundColor: AppColors.canvas,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayTile(_DayChoice d) {
    final on = _selected.contains(d.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _toggle(d.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: on
                ? AppColors.ember.withValues(alpha: 0.10)
                : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: on ? AppColors.ember : AppColors.line,
            ),
          ),
          child: Row(
            children: [
              Icon(
                on
                    ? PhosphorIconsBold.checkCircle
                    : PhosphorIconsRegular.circle,
                color: on ? AppColors.ember : AppColors.textLow,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(d.label,
                    style: const TextStyle(
                      color: AppColors.textHi,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
