import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../data/medical_leave_model.dart';
import '../../../../core/utils/name_formatter.dart';
import '../viewmodels/medical_leave_viewmodel.dart';

class MedicalLeaveFormScreen extends StatefulWidget {
  final Player player;
  const MedicalLeaveFormScreen({super.key, required this.player});

  @override
  State<MedicalLeaveFormScreen> createState() => _MedicalLeaveFormScreenState();
}

class _MedicalLeaveFormScreenState extends State<MedicalLeaveFormScreen> {
  final _reasonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _saving = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? _startDate.add(const Duration(days: 7))),
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (_reasonCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final leave = MedicalLeave(
        playerId: widget.player.id,
        reason: _reasonCtrl.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        notes: _notesCtrl.text.trim(),
        createdBy: 'Staff',
        status: MedicalLeaveStatus.active,
      );
      await context.read<MedicalLeaveViewModel>().registerLeave(leave);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: const Text('Registrar Reposo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Atleta: ${NameFormatter.playerDisplayName(widget.player)}',
                style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonCtrl,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                labelText: 'Motivo del reposo',
                hintText: 'Ej: Lesión en el tobillo',
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _dateField(cs, 'Fecha de inicio', _startDate, () => _pickDate(true)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dateField(cs, 'Fecha de fin (opcional)', _endDate, () => _pickDate(false)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              style: TextStyle(color: cs.onSurface),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notas (opcional)',
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_saving ? 'Guardando...' : 'Guardar reposo'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(ColorScheme cs, String label, DateTime? date, VoidCallback onTap) {
    final text = date != null
        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
        : 'Seleccionar';
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: cs.surfaceContainerHighest,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        child: Text(text, style: TextStyle(color: cs.onSurface, fontSize: 14)),
      ),
    );
  }
}
