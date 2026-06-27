import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/widgets_globales/route_transitions.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../../estadisticas/domain/services/stats_calculator.dart';
import '../../data/athlete_repository.dart';
import '../../data/athlete_stats_model.dart';
import '../../data/athlete_stats_service.dart';
import '../viewmodels/athlete_viewmodel.dart';
import '../widgets/athlete_stats_widget.dart';
import 'athlete_form_screen.dart';
import '../../../../core/utils/name_formatter.dart';

class AthleteDetailScreen extends StatefulWidget {
  final Player player;
  const AthleteDetailScreen({super.key, required this.player});

  @override
  State<AthleteDetailScreen> createState() => _AthleteDetailScreenState();
}

class _AthleteDetailScreenState extends State<AthleteDetailScreen> {
  final AthleteStatsService _statsService = AthleteStatsService();
  final AthleteRepository _repo = AthleteRepository();
  late Player _player;
  PlayerStats? _stats;
  AthleteStatsData? _athleteStats;
  TeamRankings? _teamRankings;
  bool _loadingStats = true;
  bool _loadingRendimiento = true;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadStats(), _loadRendimiento()]);
  }

  Future<void> _loadStats() async {
    try {
      await DatabaseService.instance.initialize();
      final events = await DatabaseService.instance.getEventsByPlayer(_player.id);
      _stats = StatsCalculator.calcularStats(events, _player.id);
    } catch (_) {}
    if (mounted) setState(() => _loadingStats = false);
  }

  Future<void> _loadRendimiento() async {
    try {
      _athleteStats = await _statsService.calculate(_player.id);
      _teamRankings = await _statsService.calculateTeamRankings();
    } catch (_) {}
    if (mounted) setState(() => _loadingRendimiento = false);
  }

  Future<void> _edit() async {
    final result = await context.pushSlide<bool>(AthleteFormScreen(existing: _player));
    if (result == true && mounted) {
      final updated = await _repo.getById(_player.id);
      if (updated != null && mounted) {
        setState(() => _player = updated);
      }
      _loadStats();
    }
  }

  Future<void> _delete() async {
    final reasonCtrl = TextEditingController();
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 32, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.center,
            ),
            const SizedBox(height: 20),
            const Text('Eliminar atleta',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('El atleta será enviado a la papelera.\nPodrá restaurarse posteriormente.',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 20),
            TextField(
              controller: reasonCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Motivo de eliminación (opcional)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Mover a papelera'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    reasonCtrl.dispose();
    if (result != true) return;
    final vm = context.read<AthleteViewModel>();
    final reason = reasonCtrl.text.trim();
    final ok = await vm.softDelete(_player.id, reason: reason.isNotEmpty ? reason : null);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = _player;

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
            icon: const Icon(Icons.edit_rounded, color: Colors.white54, size: 18),
            onPressed: _edit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 18),
            onPressed: _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _headerCard(p),
            const SizedBox(height: 16),
            _categoryBadge(p),
            const SizedBox(height: 16),
            _infoGrid(p),
            const SizedBox(height: 16),
            _physicalInfo(p),
            const SizedBox(height: 16),
            _positionInfo(p),
            const SizedBox(height: 24),
            _rendimientoSection(),
            const SizedBox(height: 16),
            if (_loadingStats)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.accent),
              )
            else if (_stats != null)
              _statsCard(_stats!),
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
                    Flexible(
                      child: Text(NameFormatter.playerFullName(p), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    if (p.esCapitan) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star, color: AppColors.accent, size: 18),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(p.posicionLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _healthBgColor(p.estadoSalud),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p.estadoSaludLabel,
                        style: TextStyle(
                          color: _healthColor(p.estadoSalud),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryBadge(Player p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent.withValues(alpha: 0.15), AppColors.primary.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_graph_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: 10),
          Text(
            'Categoría ${p.categoria}',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: p.sexo == Sexo.masculino
                  ? Colors.blue.withValues(alpha: 0.2)
                  : Colors.pink.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              p.sexoLabel,
              style: TextStyle(
                color: p.sexo == Sexo.masculino ? Colors.blue : Colors.pink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
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
              _infoItem(Icons.badge_rounded, 'Cédula', p.cedula.isEmpty ? '—' : p.cedula),
              _infoItem(Icons.cake_rounded, 'Edad', '${p.edad} años'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoItem(Icons.fitness_center_rounded, 'Condición', p.condicionFisica),
              _infoItem(Icons.calendar_today_rounded, 'Ingreso', _formatDate(p.fechaIngreso)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _physicalInfo(Player p) {
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
              Icon(Icons.accessibility_new_rounded, color: AppColors.accent, size: 16),
              SizedBox(width: 8),
              Text('Datos Físicos', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoItem(Icons.height_rounded, 'Altura', p.altura > 0 ? '${p.altura.toStringAsFixed(1)} cm' : '—'),
              _infoItem(Icons.bloodtype_rounded, 'Tipo Sangre', p.tipoSangreLabel),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoItem(Icons.wc_rounded, 'Sexo', p.sexoLabel),
              _infoItem(Icons.pan_tool_rounded, 'Mano', p.manoDominanteLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _positionInfo(Player p) {
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
              Icon(Icons.sports_volleyball_rounded, color: AppColors.accent, size: 16),
              SizedBox(width: 8),
              Text('Posiciones', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge(p.posicionLabel, AppColors.primaryLight, AppColors.primary.withValues(alpha: 0.15)),
              if (p.posicionSecundaria != Posicion.sinDefinir)
                _badge(p.posicionSecundariaLabel, AppColors.accent, AppColors.accent.withValues(alpha: 0.12)),
              if (p.esCapitan)
                _badge('Capitán', const Color(0xFFFFA940), const Color(0xFFFFA940).withValues(alpha: 0.15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _rendimientoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_graph_rounded, color: AppColors.accent, size: 18),
            SizedBox(width: 8),
            Text('RENDIMIENTO',
              style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ],
        ),
        const SizedBox(height: 12),
        if (_loadingRendimiento)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          )
        else if (_athleteStats != null) ...[
          RadarChartCard(skills: _athleteStats!.radarSkills),
          const SizedBox(height: 12),
          BarChartCard(data: _athleteStats!.barData),
          const SizedBox(height: 12),
          PieChartCard(data: _athleteStats!.pieData),
          const SizedBox(height: 12),
          LineChartCard(points: _athleteStats!.lineData),
          const SizedBox(height: 12),
          MatchHistoryCard(history: _athleteStats!.matchHistory),
          if (_teamRankings != null) ...[
            const SizedBox(height: 12),
            RankingSection(rankings: _teamRankings!),
          ],
        ],
      ],
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

  Color _healthColor(EstadoSalud e) {
    switch (e) {
      case EstadoSalud.disponible: return const Color(0xFF22C55E);
      case EstadoSalud.lesionado: return const Color(0xFFEF4444);
      case EstadoSalud.enDuda: return const Color(0xFFF59E0B);
    }
  }

  Color _healthBgColor(EstadoSalud e) {
    return _healthColor(e).withValues(alpha: 0.15);
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

extension on Player {
  String get posicionSecundariaLabel {
    switch (posicionSecundaria) {
      case Posicion.colocador: return 'Armador';
      case Posicion.opuesto: return 'Opuesto';
      case Posicion.central: return 'Central';
      case Posicion.receptor: return 'Punta';
      case Posicion.libre: return 'Líbero';
      case Posicion.sinDefinir: return 'Sin definir';
    }
  }
}
