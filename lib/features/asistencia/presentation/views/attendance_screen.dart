import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../../estadisticas/data/local_db/database_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Player> _players = [];
  Map<int, AttendanceRecord> _records = {};
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      await DatabaseService.instance.initialize();
      _players = await DatabaseService.instance.getAllPlayers();
      final existing = await DatabaseService.instance.getAttendanceByDate(_selectedDate);
      _records = {for (final r in existing) r.playerId: r};
      for (final p in _players) {
        _records.putIfAbsent(p.id, () => AttendanceRecord.create(
          playerId: p.id,
          fecha: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
          asistio: true,
        ));
      }
    } catch (e) {
      _error = 'Error al cargar: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _load();
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      for (final record in _records.values) {
        if (record.id == 0) {
          await DatabaseService.instance.saveAttendanceRecord(record);
        } else {
          await DatabaseService.instance.saveAttendanceRecord(record);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asistencia guardada'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  void _togglePlayer(int playerId, bool asistio) {
    final record = _records[playerId];
    if (record != null) {
      record.asistio = asistio;
      setState(() {});
    }
  }

  Color _saludColor(EstadoSalud e) {
    switch (e) {
      case EstadoSalud.disponible: return Colors.green;
      case EstadoSalud.lesionado: return Colors.red;
      case EstadoSalud.enDuda: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${_selectedDate.day.toString().padLeft(2, '0')}/'
        '${_selectedDate.month.toString().padLeft(2, '0')}/'
        '${_selectedDate.year}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Asistencia', style: TextStyle(color: Colors.white)),
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.save, color: AppColors.accent),
              onPressed: _saving ? null : _save,
              tooltip: 'Guardar',
            ),
        ],
      ),
      body: _buildBody(dateStr),
    );
  }

  Widget _buildBody(String dateStr) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        _dateHeader(dateStr),
        Expanded(
          child: _players.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: _players.length,
                  itemBuilder: (context, index) => _athleteTile(_players[index]),
                ),
        ),
        if (_players.isNotEmpty) _saveBar(),
      ],
    );
  }

  Widget _dateHeader(String dateStr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: AppColors.accent, size: 18),
          const SizedBox(width: 12),
          const Text('Fecha:', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dateStr,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            '${_players.length} atletas',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          const Text('No hay atletas registrados', style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Agrega atletas desde la sección Atletas', style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.surface),
          ),
        ],
      ),
    );
  }

  Widget _athleteTile(Player p) {
    final record = _records[p.id];
    final asistio = record?.asistio ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: asistio ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: p.esCapitan ? AppColors.accent : AppColors.primary,
          child: Text(
            '${p.numero}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
          ),
        ),
        title: Row(
          children: [
            Text(p.nombre, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            if (p.esCapitan) ...[
              const SizedBox(width: 4),
              const Icon(Icons.star, color: AppColors.accent, size: 14),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            Text(p.posicionLabel, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(width: 8),
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _saludColor(p.estadoSalud),
              ),
            ),
            const SizedBox(width: 4),
            Text(p.estadoSaludLabel, style: TextStyle(color: _saludColor(p.estadoSalud), fontSize: 10)),
          ],
        ),
        trailing: GestureDetector(
          onTap: () => _togglePlayer(p.id, !asistio),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: asistio ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  asistio ? Icons.check_circle : Icons.cancel,
                  color: asistio ? Colors.green : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  asistio ? 'Presente' : 'Ausente',
                  style: TextStyle(
                    color: asistio ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _saveBar() {
    final presentes = _records.values.where((r) => r.asistio).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Text(
            '$presentes/${_players.length} presentes',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save, size: 18),
            label: Text(_saving ? 'Guardando...' : 'Guardar'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
