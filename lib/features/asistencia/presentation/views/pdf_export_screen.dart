import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../teams/presentation/viewmodels/club_viewmodel.dart';
import '../../data/attendance_pdf_export.dart';

class PdfExportScreen extends StatefulWidget {
  const PdfExportScreen({super.key});

  @override
  State<PdfExportScreen> createState() => _PdfExportScreenState();
}

class _PdfExportScreenState extends State<PdfExportScreen> {
  late int _year;
  late int _month;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

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
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _periodRow(cs, 'Mes', _monthName, () => _pickMonth(cs)),
                  const SizedBox(height: 12),
                  _periodRow(cs, 'Año', _year.toString(), () => _pickYear(cs)),
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
                    Text('$_monthName $_year', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 13)),
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

  String get _monthName => ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'][_month - 1];

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

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final clubName = context.read<ClubViewModel>().currentClub?.name ?? 'Club';
      await AttendancePdfExport().saveAndShare(
        year: _year,
        month: _month,
        clubName: clubName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _exporting = false);
  }
}
