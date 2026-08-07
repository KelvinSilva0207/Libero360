import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../teams/presentation/viewmodels/club_viewmodel.dart';
import '../../data/attendance_pdf_export.dart';

enum _ExportMode { month, week, day }

class PdfExportScreen extends StatefulWidget {
  const PdfExportScreen({super.key, this.initialMonth, this.initialYear, this.initialDate});

  final int? initialMonth;
  final int? initialYear;
  final DateTime? initialDate;

  @override
  State<PdfExportScreen> createState() => _PdfExportScreenState();
}

class _PdfExportScreenState extends State<PdfExportScreen> {
  late int _year;
  late int _month;
  late DateTime _weekAnchor;
  late DateTime _dayAnchor;
  _ExportMode _mode = _ExportMode.month;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = widget.initialYear ?? now.year;
    _month = widget.initialMonth ?? now.month;
    _weekAnchor = widget.initialDate ?? now;
    _dayAnchor = widget.initialDate ?? now;
  }

  DateTime get _weekStart {
    final d = DateTime(_weekAnchor.year, _weekAnchor.month, _weekAnchor.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 6));

  String get _monthName => ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'][_month - 1];

  String get _periodLabel {
    if (_mode == _ExportMode.day) {
      return _shortDate(_dayAnchor);
    }
    if (_mode == _ExportMode.week) {
      return '${_shortDate(_weekStart)} al ${_shortDate(_weekEnd)}';
    }
    return '$_monthName $_year';
  }

  String _shortDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Exportar Reporte PDF'),
        actions: [
          TextButton(
            onPressed: _exporting ? null : _export,
            child: _exporting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Exportar', style: TextStyle(color: cs.primary)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selecciona el período', style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SegmentedButton<_ExportMode>(
              segments: const [
                ButtonSegment(value: _ExportMode.month, label: Text('Mes'), icon: Icon(Icons.calendar_month, size: 18)),
                ButtonSegment(value: _ExportMode.week, label: Text('Semana'), icon: Icon(Icons.date_range, size: 18)),
                ButtonSegment(value: _ExportMode.day, label: Text('Día'), icon: Icon(Icons.today, size: 18)),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _mode == _ExportMode.month
                  ? Column(
                      children: [
                        _periodRow(cs, 'Mes', _monthName, () => _pickMonth(cs)),
                        const SizedBox(height: 12),
                        _periodRow(cs, 'Año', _year.toString(), () => _pickYear(cs)),
                      ],
                    )
                  : _mode == _ExportMode.week
                      ? Column(
                          children: [
                            _periodRow(cs, 'Semana', _periodLabel, () => _pickWeekDate(cs)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => setState(() => _weekAnchor = DateTime.now()),
                                    icon: const Icon(Icons.today, size: 16),
                                    label: const Text('Esta semana'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: cs.primary,
                                      side: BorderSide(color: cs.primary.withValues(alpha: 0.5)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => setState(() => _weekAnchor = DateTime.now().subtract(const Duration(days: 7))),
                                    icon: const Icon(Icons.history, size: 16),
                                    label: const Text('Semana pasada'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: cs.primary,
                                      side: BorderSide(color: cs.primary.withValues(alpha: 0.5)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _periodRow(cs, 'Día', _periodLabel, () => _pickDay(cs)),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => setState(() => _dayAnchor = DateTime.now()),
                              icon: const Icon(Icons.today, size: 16),
                              label: const Text('Hoy'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: cs.primary,
                                side: BorderSide(color: cs.primary.withValues(alpha: 0.5)),
                              ),
                            ),
                          ],
                        ),
            ),
            const SizedBox(height: 32),
            Text('Vista previa', style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.picture_as_pdf, size: 80, color: cs.onSurface.withValues(alpha: 0.1)),
                    const SizedBox(height: 16),
                    Text('Reporte de Asistencia', style: TextStyle(color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(_periodLabel, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 13)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, color: AppColors.primaryLight, size: 16),
                          SizedBox(width: 8),
                          Text('El PDF se compartirá automáticamente', style: TextStyle(color: AppColors.primaryLight, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodRow(ColorScheme cs, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13))),
          Expanded(child: Text(value, style: TextStyle(color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w500))),
          Icon(Icons.chevron_right, color: cs.onSurface.withValues(alpha: 0.3), size: 20),
        ],
      ),
    );
  }

  Future<void> _pickMonth(ColorScheme cs) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Seleccionar mes'),
        children: List.generate(12, (i) {
          final name = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'][i];
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, i + 1),
            child: Text(name, style: TextStyle(color: i + 1 == _month ? cs.primary : null)),
          );
        }),
      ),
    );
    if (picked != null) setState(() => _month = picked);
  }

  Future<void> _pickYear(ColorScheme cs) async {
    final now = DateTime.now();
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Seleccionar año'),
        children: List.generate(5, (i) {
          final year = now.year - 2 + i;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, year),
            child: Text(year.toString(), style: TextStyle(color: year == _year ? cs.primary : null)),
          );
        }),
      ),
    );
    if (picked != null) setState(() => _year = picked);
  }

  Future<void> _pickWeekDate(ColorScheme cs) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weekAnchor,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Elige un día de la semana',
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: cs.primary,
            onPrimary: cs.onPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _weekAnchor = picked);
  }

  Future<void> _pickDay(ColorScheme cs) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dayAnchor,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Elige el día',
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: cs.primary,
            onPrimary: cs.onPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dayAnchor = picked);
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final vm = context.read<ClubViewModel>();
      final clubName = vm.currentClub?.name ?? 'Club';
      final clubLogoUrl = vm.currentClub?.photoUrl;
      if (_mode == _ExportMode.day) {
        await AttendancePdfExport().saveAndShare(
          day: _dayAnchor,
          clubName: clubName,
          clubLogoUrl: clubLogoUrl,
        );
      } else if (_mode == _ExportMode.week) {
        await AttendancePdfExport().saveAndShare(
          start: _weekStart,
          end: _weekEnd,
          clubName: clubName,
          clubLogoUrl: clubLogoUrl,
        );
      } else {
        await AttendancePdfExport().saveAndShare(
          year: _year,
          month: _month,
          clubName: clubName,
          clubLogoUrl: clubLogoUrl,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _exporting = false);
  }
}
