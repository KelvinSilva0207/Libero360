import 'package:flutter/material.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../../estadisticas/data/models/models.dart';
import 'attendance_history_detail_screen.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month);
  List<Map<String, dynamic>> _trainings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrainings();
  }

  Future<void> _loadTrainings() async {
    setState(() => _loading = true);
    try {
      await DatabaseService.instance.initialize();
      final records = await DatabaseService.instance.getAttendanceRecords();
      final playerIds = records.map((r) => r.playerId).toSet();
      final players = <int, String>{};
      for (final id in playerIds) {
        try {
          final p = await DatabaseService.instance.getPlayer(id);
          if (p != null) players[id] = p.nombre;
        } catch (_) {}
      }

      final monthStart =
          DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final monthEnd =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

      final monthRecords = records.where((r) =>
          r.fecha.isAfter(monthStart.subtract(const Duration(days: 1))) &&
          r.fecha.isBefore(monthEnd.add(const Duration(days: 1))));

      final grouped = <String, List<AttendanceRecord>>{};
      for (final r in monthRecords) {
        final key =
            '${r.fecha.year}-${r.fecha.month.toString().padLeft(2, '0')}-${r.fecha.day.toString().padLeft(2, '0')}';
        grouped.putIfAbsent(key, () => []);
        grouped[key]!.add(r);
      }

      final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
      _trainings = sortedKeys.map((key) {
        final records = grouped[key]!;
        final present = records.where((r) => r.asistio).length;
        return {
          'date': key,
          'total': records.length,
          'present': present,
          'records': records,
        };
      }).toList();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Historial de Asistencia'),
      ),
      body: Column(
        children: [
          _buildMonthSelector(cs),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : _trainings.isEmpty
                    ? _buildEmptyState(cs)
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _trainings.length,
                        itemBuilder: (_, i) =>
                            _buildTrainingCard(_trainings[i], cs),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: cs.surfaceContainerHighest,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: cs.onSurface),
            onPressed: () {
              setState(() {
                _selectedMonth =
                    DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              });
              _loadTrainings();
            },
          ),
          Expanded(
            child: Text(
              '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: cs.onSurface),
            onPressed: () {
              setState(() {
                _selectedMonth =
                    DateTime(_selectedMonth.year, _selectedMonth.month + 1);
              });
              _loadTrainings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded,
              size: 48, color: cs.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text('Sin entrenamientos registrados',
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

  Widget _buildTrainingCard(Map<String, dynamic> training, ColorScheme cs) {
    final date = training['date'] as String;
    final total = training['total'] as int;
    final present = training['present'] as int;
    final records = training['records'] as List<AttendanceRecord>;
    final parts = date.split('-');
    final day = int.parse(parts[2]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[0]);
    final dateObj = DateTime(year, month, day);
    final dayName = _dayName(dateObj.weekday);

    return Card(
      color: cs.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Text(dayName.toUpperCase(),
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6), fontSize: 8)),
            ],
          ),
        ),
        title: Text('Asistieron: $present de $total',
            style: TextStyle(color: cs.onSurface, fontSize: 14)),
        subtitle: Text('Entrenamiento - $present/$total',
            style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.6), fontSize: 11)),
        trailing: Icon(Icons.chevron_right,
            color: cs.onSurface.withValues(alpha: 0.4)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AttendanceHistoryDetailScreen(
                  records: records, date: dateObj),
            ),
          );
        },
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return names[m - 1];
  }

  String _dayName(int d) {
    const names = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return names[d - 1];
  }
}
