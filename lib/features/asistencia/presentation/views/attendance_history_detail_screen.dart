import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/attendance_record.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../../estadisticas/data/models/models.dart';
import '../widgets/attendance_pdf_export.dart';

class AttendanceHistoryDetailScreen extends StatefulWidget {
  final List<AttendanceRecord> records;
  final DateTime date;

  const AttendanceHistoryDetailScreen({
    super.key,
    required this.records,
    required this.date,
  });

  @override
  State<AttendanceHistoryDetailScreen> createState() => _AttendanceHistoryDetailScreenState();
}

class _AttendanceHistoryDetailScreenState extends State<AttendanceHistoryDetailScreen> {
  List<Player> _players = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    try {
      await DatabaseService.instance.initialize();
      final allPlayers = await DatabaseService.instance.getPlayers();
      final playerIds = widget.records.map((r) => r.playerId).toSet();
      _players = allPlayers.where((p) => playerIds.contains(p.id)).toList();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final present = widget.records.where((r) => r.asistio).length;
    final absent = widget.records.where((r) => !r.asistio).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('${widget.date.day}/${widget.date.month}/${widget.date.year}',
          style: const TextStyle(color: Colors.white, fontSize: 15)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.accent),
            tooltip: 'Exportar PDF',
            onPressed: () => AttendancePdfExport.exportMonthly(
              context,
              DateTime(widget.date.year, widget.date.month),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statColumn('Presentes', '$present', Colors.green),
                      Container(width: 1, height: 40, color: Colors.white10),
                      _statColumn('Ausentes', '$absent', Colors.redAccent),
                      Container(width: 1, height: 40, color: Colors.white10),
                      _statColumn('Total', '${widget.records.length}', Colors.white70),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('PRESENTES',
                  style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                ...widget.records.where((r) => r.asistio).map(_buildPlayerRow),
                const SizedBox(height: 16),
                const Text('AUSENTES',
                  style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                ...widget.records.where((r) => !r.asistio).map(_buildPlayerRow),
              ],
            ),
    );
  }

  Widget _statColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildPlayerRow(AttendanceRecord r) {
    final p = _players.where((pl) => pl.id == r.playerId).firstOrNull;
    final name = p?.nombre ?? 'Atleta #${r.playerId}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            r.asistio ? Icons.check_circle : Icons.cancel,
            color: r.asistio ? Colors.green : Colors.redAccent,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)),
          const Spacer(),
          Text(r.observaciones.isNotEmpty ? r.observaciones : '',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}
