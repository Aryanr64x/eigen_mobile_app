import 'package:eigen_flutter/models/day_status.dart';
import 'package:eigen_flutter/providers/auth_provider.dart';
import 'package:eigen_flutter/repositories/api_result.dart';
import 'package:eigen_flutter/repositories/dailyquestions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _repo = QuestionsRepository();

final _monthStatusProvider =
    FutureProvider.family<List<DayStatus>, String>((ref, monthKey) async {
  final token = ref.read(authProvider).value?.accessToken;
  if (token == null) throw Exception('Not authenticated');
  final result = await _repo.getMonthStatus(token: token, month: monthKey);
  return switch (result) {
    ApiSuccess(:final data) => data,
    ApiFailure(:final exception) => throw exception,
  };
});

// ── Public helper ─────────────────────────────────────────────────────────────

Future<void> showCalendarDialog(BuildContext context, WidgetRef ref) async {
  final token = ref.read(authProvider).value?.accessToken;
  if (token == null) {
    Navigator.pushNamed(context, '/auth');
    return;
  }
  await showDialog(
    context: context,
    builder: (_) => const _CalendarDialog(),
  );
}
// ── Dialog ────────────────────────────────────────────────────────────────────

class _CalendarDialog extends ConsumerStatefulWidget {
  const _CalendarDialog();

  @override
  ConsumerState<_CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends ConsumerState<_CalendarDialog> {
  static const _brand = Color(0xFF36093D);

  late DateTime _focusedMonth;
  final DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(_today.year, _today.month);
  }

  String get _monthKey =>
      '${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}';

  bool get _canGoNext {
    final now = DateTime.now();
    return _focusedMonth.year < now.year ||
        (_focusedMonth.year == now.year && _focusedMonth.month < now.month);
  }

  void _prevMonth() =>
      setState(() => _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month - 1));

  void _nextMonth() {
    if (_canGoNext) {
      setState(() => _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month + 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(_monthStatusProvider(_monthKey));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              children: [
                IconButton(
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: _brand,
                  splashRadius: 20,
                ),
                Expanded(
                  child: Text(
                    _monthLabel(_focusedMonth),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _brand,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _canGoNext ? _nextMonth : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: _canGoNext ? _brand : Colors.grey.shade300,
                  splashRadius: 20,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Day labels ───────────────────────────────────────────
            Row(
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _brand.withOpacity(0.4),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 6),

            // ── Calendar grid ────────────────────────────────────────
            statusAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                      color: _brand, strokeWidth: 2),
                ),
              ),
              error: (e, _) => SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'Could not load calendar.',
                    style: TextStyle(color: Colors.red.shade400, fontSize: 13),
                  ),
                ),
              ),
              data: (statuses) => _CalendarGrid(
                focusedMonth: _focusedMonth,
                today: _today,
                statuses: statuses,
              ),
            ),

            const SizedBox(height: 16),

            // ── Legend ───────────────────────────────────────────────
            Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: const [
                _LegendItem(color: Color(0xFF2ECC71), label: 'Solved'),
                _LegendItem(color: Color(0xFFF39C12), label: 'Partial'),
                _LegendItem(color: Color(0xFFE74C3C), label: 'Unsolved'),
                _LegendItem(color: Color(0xFFDDDDDD), label: 'Future'),
              ],
            ),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  String _monthLabel(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

// ── Calendar Grid ─────────────────────────────────────────────────────────────
class _CalendarGrid extends ConsumerWidget {
  final DateTime focusedMonth;
  final DateTime today;
  final List<DayStatus> statuses;

  const _CalendarGrid({
    required this.focusedMonth,
    required this.today,
    required this.statuses,
  });

  Future<void> _onDayTap(BuildContext context, WidgetRef ref, String dateString) async {
    final token = ref.read(authProvider).value?.accessToken;
    if (token == null) {
      Navigator.pushNamed(context, '/auth');
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF36093D)),
      ),
    );

    final result = await _repo.getQuestionIdByDate(
      token: token,
      dateString: dateString,
    );

    if (!context.mounted) return;
    Navigator.pop(context); // dismiss loader

    switch (result) {
      case ApiSuccess(:final data):
        Navigator.pop(context); // dismiss calendar dialog
        Navigator.pushNamed(context, '/question', arguments: data);
      case ApiFailure(:final exception):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exception.message),
            backgroundColor: const Color(0xFFE74C3C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusMap = {for (final s in statuses) s.day: s.status};

    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth =
        DateUtils.getDaysInMonth(focusedMonth.year, focusedMonth.month);
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final dayNum = cellIndex - startOffset + 1;

            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 40));
            }

            final dayStr = dayNum.toString().padLeft(2, '0');
            final monthStr = focusedMonth.month.toString().padLeft(2, '0');
            final dateString = '${focusedMonth.year}-$monthStr-$dayStr';

            final cellDate =
                DateTime(focusedMonth.year, focusedMonth.month, dayNum);
            final isFuture = cellDate.isAfter(today);
            final isToday = DateUtils.isSameDay(cellDate, today);
            final status = statusMap[dayStr] ?? 'unsolved';

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: _DayCell(
                  day: dayNum,
                  status: status,
                  isFuture: isFuture,
                  isToday: isToday,
                  onTap: () => _onDayTap(context, ref, dateString),
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}
// ── Day Cell ──────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final int day;
  final String status;
  final bool isFuture;
  final bool isToday;
   final VoidCallback? onTap;   // add this

  const _DayCell({
    required this.day,
    required this.status,
    required this.isFuture,
    required this.isToday,
     this.onTap,  
  });

  Color get _bg {
    if (isFuture) return const Color(0xFFF0F0F0);
    return switch (status) {
      'solved'           => const Color(0xFF2ECC71),
      'partially_solved' => const Color(0xFFF39C12),
      _                  => const Color(0xFFE74C3C), // unsolved
    };
  }

  Color get _fg {
    if (isFuture) return const Color(0xFFBBBBBB);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isFuture ? null : onTap,   // future dates not tappable
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(10),
          border: isToday
              ? Border.all(color: const Color(0xFF36093D), width: 2)
              : null,
          boxShadow: isFuture
              ? null
              : [
                  BoxShadow(
                    color: _bg.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 13,
            fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
            color: _fg,
          ),
        ),
      ),
    );
  }
}

// ── Legend item ───────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600)),
      ],
    );
  }
}