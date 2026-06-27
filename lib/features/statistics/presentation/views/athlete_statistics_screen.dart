import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme_provider/theme_notifier.dart';
import '../../../../core/utils/name_formatter.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../data/statistics_models.dart';

class AthleteStatisticsScreen extends StatelessWidget {
  final AthleteStats athleteStats;

  const AthleteStatisticsScreen({super.key, required this.athleteStats});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    final bg = isDark ? const Color(0xFF071126) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF101B3A) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFFA6B1D0) : const Color(0xFF64748B);
    const accent = Color(0xFFFF8C00);
    const success = Color(0xFF22C55E);
    const error = Color(0xFFEF4444);
    final border = isDark ? const Color(0xFF1E2D5A) : const Color(0xFFE2E8F0);

    final p = athleteStats.player;
    final s = athleteStats;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(NameFormatter.playerDisplayName(p), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _AthleteHeader(player: p, cardBg: cardBg, border: border, textPrimary: textPrimary, textSecondary: textSecondary),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'PARTIDOS',
            icon: Icons.sports_volleyball,
            iconColor: const Color(0xFF0081CF),
            cardBg: cardBg,
            border: border,
            textSecondary: textSecondary,
            children: [
              _InfoRow(label: 'Total', value: '${s.totalMatches}', color: textPrimary),
              _InfoRow(label: 'Ligas', value: '${s.ligas}', color: textPrimary),
              _InfoRow(label: 'Torneos', value: '${s.torneos}', color: textPrimary),
              _InfoRow(label: 'Amistosos', value: '${s.amistosos}', color: textPrimary),
              _InfoRow(label: 'Prácticas', value: '${s.practicas}', color: textPrimary),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'PUNTOS',
            icon: Icons.track_changes,
            iconColor: accent,
            cardBg: cardBg,
            border: border,
            textSecondary: textSecondary,
            children: [
              _InfoRow(label: '🔥 Puntos ganadores', value: '${s.puntosGanadores}', color: accent),
              _InfoRow(label: '✔ Puntos regulares', value: '${s.puntosRegulares}', color: success),
              _InfoRow(label: '✖ Errores', value: '${s.errores}', color: error),
              const Divider(height: 20),
              _InfoRow(label: 'Eficiencia', value: '${s.eficiencia.toStringAsFixed(0)}%', color: textPrimary),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'MVP',
            icon: Icons.star,
            iconColor: accent,
            cardBg: cardBg,
            border: border,
            textSecondary: textSecondary,
            children: [
              _InfoRow(label: '⭐ MVP', value: '${s.mvpCount}', color: accent),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'ASISTENCIA',
            icon: Icons.calendar_today,
            iconColor: success,
            cardBg: cardBg,
            border: border,
            textSecondary: textSecondary,
            children: [
              _InfoRow(label: 'Asistencia', value: '${s.attendancePct.toStringAsFixed(0)}%', color: success),
              _InfoRow(label: 'Faltas', value: '${s.faltas}', color: error),
              _InfoRow(label: 'Justificadas', value: '${s.justificadas}', color: textSecondary),
            ],
          ),
          const SizedBox(height: 16),
          _StatusCard(player: p, cardBg: cardBg, border: border, textPrimary: textPrimary, textSecondary: textSecondary, success: success, accent: accent),
        ],
      ),
    );
  }
}

class _AthleteHeader extends StatelessWidget {
  final Player player;
  final Color cardBg, border, textPrimary, textSecondary;

  const _AthleteHeader({required this.player, required this.cardBg, required this.border,
    required this.textPrimary, required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFFF8C00).withValues(alpha: 0.15),
            child: Text(
              NameFormatter.avatarInitial(player),
              style: const TextStyle(color: Color(0xFFFF8C00), fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(NameFormatter.playerDisplayName(player), style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (player.numero != null) ...[
                      Text('#${player.numero}', style: TextStyle(color: const Color(0xFFFF8C00), fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                    ],
                    Text(_posicionLabel(player.posicion), style: TextStyle(color: textSecondary, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _posicionLabel(Posicion pos) {
    switch (pos) {
      case Posicion.central: return 'Central';
      case Posicion.opuesto: return 'Opuesto';
      case Posicion.receptor: return 'Punta';
      case Posicion.colocador: return 'Levantador';
      case Posicion.libre: return 'Líbero';
      case Posicion.sinDefinir: return 'Sin posición';
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color cardBg, border, textSecondary;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.iconColor,
    required this.cardBg, required this.border, required this.textSecondary, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 14)),
          Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Player player;
  final Color cardBg, border, textPrimary, textSecondary, success, accent;

  const _StatusCard({required this.player, required this.cardBg, required this.border,
    required this.textPrimary, required this.textSecondary, required this.success, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isActive = player.atletaStatus != AthleteStatus.inactive;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? success : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 12),
          Text('Estado: ', style: TextStyle(color: textSecondary, fontSize: 14)),
          Text(isActive ? 'Activo' : 'Inactivo', style: TextStyle(color: isActive ? success : const Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.bold)),
          if (player.atletaStatus == AthleteStatus.resting) ...[
            const SizedBox(width: 8),
            Text('(Reposo)', style: TextStyle(color: accent, fontSize: 12)),
          ],
          if (player.atletaStatus == AthleteStatus.injured) ...[
            const SizedBox(width: 8),
            Text('(Lesión)', style: TextStyle(color: const Color(0xFFEF4444), fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
