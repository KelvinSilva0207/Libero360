import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/widgets_globales/route_transitions.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../../estadisticas/domain/services/stats_calculator.dart';
import '../../../../core/utils/name_formatter.dart';
import '../widgets/medical_leave_section.dart';
import 'athlete_edit_screen.dart';

class PlayerDetailScreen extends StatefulWidget {
  final Player player;
  const PlayerDetailScreen({super.key, required this.player});

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  PlayerStats? _stats;
  bool _loading = true;
  double _attendancePercentage = 0;
  int _attendancePresent = 0;
  int _attendanceTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    try {
      final records = await DatabaseService.instance.getAttendanceByPlayer(widget.player.id);
      _attendanceTotal = records.length;
      _attendancePresent = records.where((r) => r.asistio).length;
      _attendancePercentage = _attendanceTotal > 0 ? (_attendancePresent / _attendanceTotal * 100) : 0;
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _loadStats() async {
    try {
      await DatabaseService.instance.initialize();
      final events = await DatabaseService.instance.getEventsByPlayer(widget.player.id);
      _stats = StatsCalculator.calcularStats(events, widget.player.id);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.player;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(NameFormatter.playerFullName(p), style: const TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white54, size: 16),
            onPressed: () async {
              final result = await context.pushSlide<bool>(AthleteEditScreen(player: p));
              if (result == true) {
                setState(() {}); // Refresh stats after edit
                _loadStats();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _headerCard(p),
            const SizedBox(height: 16),
            _infoGrid(p),
            const SizedBox(height: 16),
            _attendanceCard(),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.accent),
              )
            else if (_stats != null)
              _statsCard(_stats!),
            const SizedBox(height: 16),
            _positionBadges(p),
            const SizedBox(height: 16),
            MedicalLeaveSection(player: p),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(Player p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Hero(
            tag: 'player-${p.id}',
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: p.esCapitan
                    ? const LinearGradient(colors: [AppColors.accent, Color(0xFFFFA940)])
                    : LinearGradient(
                        colors: [AppColors.primary.withValues(alpha: 0.8), AppColors.primary],
                      ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  '${p.numero ?? '-'}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(NameFormatter.playerFullName(p), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    if (p.esCapitan) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star, color: AppColors.accent, size: 18),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  p.posicionLabel,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.estadoSalud == EstadoSalud.disponible
                        ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                        : p.estadoSalud == EstadoSalud.lesionado
                            ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p.estadoSaludLabel,
                    style: TextStyle(
                      color: p.estadoSalud == EstadoSalud.disponible
                          ? const Color(0xFF22C55E)
                          : p.estadoSalud == EstadoSalud.lesionado
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFF59E0B),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoGrid(Player p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _infoItem(Icons.badge_rounded, 'Cédula', p.cedula),
              _infoItem(Icons.cake_rounded, 'Edad', '${p.edad} años'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoItem(Icons.fitness_center_rounded, 'Condición', p.condicionFisica),
              _infoItem(Icons.directions_run_rounded, 'Posición', p.posicionLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _attendanceCard() {
    final pctColor = _attendancePercentage >= 80
        ? const Color(0xFF22C55E)
        : _attendancePercentage >= 50
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: pctColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text('${_attendancePercentage.toStringAsFixed(0)}%', style: TextStyle(color: pctColor, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Asistencia', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('$_attendancePresent de $_attendanceTotal entrenos', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _attendancePercentage / 100,
                    backgroundColor: pctColor.withValues(alpha: 0.1),
                    color: pctColor,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsCard(PlayerStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: AppColors.accent, size: 16),
              SizedBox(width: 8),
              Text('Estadísticas', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statItem('Ataque', '${stats.ataquesExitosos}/${stats.ataquesTotales}', AppColors.accent),
              _statItem('Bloqueo', '${stats.bloqueosExitosos}', AppColors.primary),
              _statItem('Defensa', '${stats.defensasPerfectas}', const Color(0xFF22C55E)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statItem('Saque', '${stats.saquesDirectos}', const Color(0xFF3B82F6)),
              _statItem('Errores', '${stats.errores}', const Color(0xFFEF4444)),
              _statItem('Efect.', '${stats.porcentajeEfectividad.toStringAsFixed(0)}%', Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _positionBadges(Player p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.sports_volleyball_rounded, color: AppColors.textTertiary, size: 14),
          const SizedBox(width: 8),
          Text('Roles:', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              p.posicionLabel,
              style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          if (p.esCapitan) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Capitán',
                style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
