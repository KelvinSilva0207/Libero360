import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:libero360/core/themes/app_colors.dart';
import 'package:libero360/features/asistencia/data/attendance_history_model.dart';
import 'package:libero360/features/asistencia/presentation/viewmodels/attendance_history_viewmodel.dart';
import 'package:libero360/features/asistencia/presentation/views/attendance_history_detail_screen.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceHistoryViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Historial de Asistencia'),
      ),
      body: Consumer<AttendanceHistoryViewModel>(
        builder: (_, vm, __) => Column(
          children: [
            _buildFilterBar(cs, vm),
            _buildSearchBar(cs, vm),
            Expanded(
              child: vm.loading
                  ? Center(child: CircularProgressIndicator(color: cs.primary))
                  : _buildContent(cs, vm),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(ColorScheme cs, AttendanceHistoryViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cs.surfaceContainerHighest,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: cs.onSurface),
            onPressed: vm.previousMonth,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _showMonthYearPicker(context, vm),
              child: Text(
                vm.currentMonthLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: cs.onSurface),
            onPressed: vm.nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme cs, AttendanceHistoryViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        onChanged: vm.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Buscar atleta...',
          hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
          filled: true,
          fillColor: cs.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme cs, AttendanceHistoryViewModel vm) {
    final summaries = vm.summaries;
    if (summaries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 48, color: cs.onSurface.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text('Sin registros en este mes',
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.4), fontSize: 14)),
            const SizedBox(height: 8),
            Text('Selecciona otro mes o registra asistencia',
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.2), fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: summaries.length,
      itemBuilder: (_, i) => _buildSummaryCard(summaries[i], cs, vm),
    );
  }

  Widget _buildSummaryCard(DailyAttendanceSummary summary, ColorScheme cs, AttendanceHistoryViewModel vm) {
    final day = summary.date.day;
    final dayName = _dayName(summary.date.weekday);

    return Card(
      color: cs.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceHistoryDetailScreen(
              date: summary.date,
              searchQuery: vm.searchQuery,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$day',
                        style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text(dayName.toUpperCase(),
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontSize: 8)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${summary.presentCount} asistentes',
                        style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _statChip(cs, '${summary.absentCount} ausentes', cs.error.withValues(alpha: 0.2), cs.error),
                        const SizedBox(width: 6),
                        if (summary.medicalRestCount > 0)
                          _statChip(cs, '${summary.medicalRestCount} reposo', cs.primary.withValues(alpha: 0.2), cs.primary),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(ColorScheme cs, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  void _showMonthYearPicker(BuildContext context, AttendanceHistoryViewModel vm) {
    final now = DateTime.now();
    showDialog(
      context: context,
      builder: (ctx) {
        int selectedMonth = vm.filterMonth ?? now.month;
        int selectedYear = vm.filterYear ?? now.year;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Seleccionar mes'),
            content: SizedBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setDialogState(() => selectedYear--),
                      ),
                      Text('$selectedYear',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setDialogState(() => selectedYear++),
                      ),
                    ],
                    mainAxisAlignment: MainAxisAlignment.center,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(12, (i) {
                      final m = i + 1;
                      final isSelected = m == selectedMonth;
                      return GestureDetector(
                        onTap: () {
                          selectedMonth = m;
                          Navigator.pop(ctx);
                          vm.setFilterYear(selectedYear);
                          vm.setFilterMonth(selectedMonth);
                        },
                        child: Container(
                          width: 72,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant),
                          ),
                          child: Text(
                            ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                             'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'][i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Theme.of(context).colorScheme.onPrimary : null,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _dayName(int d) {
    const names = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return names[d - 1];
  }
}
