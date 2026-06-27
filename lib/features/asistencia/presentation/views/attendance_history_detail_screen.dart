import 'package:flutter/material.dart';
import 'package:libero360/features/estadisticas/data/local_db/database_service.dart';
import 'package:libero360/features/estadisticas/data/models/models.dart';
import 'package:libero360/core/utils/name_formatter.dart';

class AttendanceHistoryDetailScreen extends StatefulWidget {
  final DateTime date;
  final String searchQuery;

  const AttendanceHistoryDetailScreen({
    super.key,
    required this.date,
    this.searchQuery = '',
  });

  @override
  State<AttendanceHistoryDetailScreen> createState() => _AttendanceHistoryDetailScreenState();
}

class _AttendanceHistoryDetailScreenState extends State<AttendanceHistoryDetailScreen> {
  final DatabaseService _db = DatabaseService.instance;
  List<AttendanceRecord> _records = [];
  Map<int, Player> _players = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _db.initialize();
      _records = await _db.getAttendanceByDate(widget.date);
      final allPlayers = await _db.getAllPlayers();
      for (final p in allPlayers) {
        _players[p.id] = p;
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final present = _records.where((r) => r.asistio).toList();
    final absent = _records.where((r) => !r.asistio).toList();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('${widget.date.day}/${widget.date.month}/${widget.date.year}',
            style: const TextStyle(fontSize: 15)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _records.isEmpty
              ? _emptyState(cs)
              : _buildContent(cs, present, absent),
    );
  }

  Widget _emptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline_rounded, size: 48, color: cs.onSurface.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Text('Sin registros para esta fecha',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme cs, List<AttendanceRecord> present, List<AttendanceRecord> absent) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryBar(cs, present.length, absent.length),
        const SizedBox(height: 20),
        _buildSection(cs, 'ASISTIERON', present, Colors.green, Icons.check_circle_rounded),
        const SizedBox(height: 16),
        _buildSection(cs, 'AUSENTES', absent, Colors.redAccent, Icons.cancel_rounded),
      ],
    );
  }

  Widget _buildSummaryBar(ColorScheme cs, int presentCount, int absentCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statColumn(cs, 'Asistieron', '$presentCount', Colors.green),
          Container(width: 1, height: 40, color: cs.outlineVariant),
          _statColumn(cs, 'Ausentes', '$absentCount', Colors.redAccent),
          Container(width: 1, height: 40, color: cs.outlineVariant),
          _statColumn(cs, 'Total', '${_records.length}', cs.onSurface.withValues(alpha: 0.7)),
        ],
      ),
    );
  }

  Widget _statColumn(ColorScheme cs, String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 11)),
      ],
    );
  }

  Widget _buildSection(ColorScheme cs, String title, List<AttendanceRecord> records, Color color, IconData icon) {
    final filtered = records.where((r) {
      if (widget.searchQuery.isEmpty) return true;
      final p = _players[r.playerId];
      if (p == null) return false;
      return NameFormatter.playerDisplayName(p).toLowerCase().contains(widget.searchQuery.toLowerCase());
    }).toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(title,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const SizedBox(width: 6),
            Text('(${filtered.length})',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11)),
          ],
        ),
        const SizedBox(height: 8),
        ...filtered.map((r) => _buildPlayerCard(r, cs)),
      ],
    );
  }

  Widget _buildPlayerCard(AttendanceRecord record, ColorScheme cs) {
    final player = _players[record.playerId];
    final name = player != null ? NameFormatter.playerDisplayName(player) : 'Atleta #${record.playerId}';
    final position = player?.posicionLabel ?? '';
    final category = player?.categoria ?? '';
    final photoUrl = player?.fotoUrl;
    final isMedical = player != null &&
        (player.estadoSalud == EstadoSalud.lesionado || player.atletaStatus == AthleteStatus.injured);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: cs.primaryContainer,
          backgroundImage: photoUrl != null && photoUrl.isNotEmpty
              ? NetworkImage(photoUrl)
              : null,
          child: photoUrl == null || photoUrl.isEmpty
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
                )
              : null,
        ),
        title: Text(name, style: TextStyle(color: cs.onSurface, fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: Row(
          children: [
            if (position.isNotEmpty) ...[
              Text(position, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 11)),
              if (category.isNotEmpty) ...[
                Text(' · ', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.3), fontSize: 11)),
                Text(category, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 11)),
              ],
            ],
            if (isMedical) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('REPOSO', style: TextStyle(color: Colors.orange, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        trailing: Icon(
          record.asistio ? Icons.check_circle : Icons.cancel,
          color: record.asistio ? Colors.green : Colors.redAccent,
          size: 20,
        ),
      ),
    );
  }
}
