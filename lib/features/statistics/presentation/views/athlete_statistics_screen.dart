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
    final cs = Theme.of(context).colorScheme;

    final p = athleteStats.player;
    final s = athleteStats;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerHighest,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(NameFormatter.playerDisplayName(p), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _AthleteHeader(player: p, cs: cs),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'PARTIDOS',
            icon: Icons.sports_volleyball,
            iconColor: cs.primary,
            cs: cs,
            children: [
              _InfoRow(label: 'Total', value: '${s.totalMatches}', color: cs.onSurface),
              _InfoRow(label: 'Ligas', value: '${s.ligas}', color: cs.onSurface),
              _InfoRow(label: 'Torneos', value: '${s.torneos}', color: cs.onSurface),
              _InfoRow(label: 'Amistosos', value: '${s.amistosos}', color: cs.onSurface),
              _InfoRow(label: 'Prácticas', value: '${s.practicas}', color: cs.onSurface),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'PUNTOS',
            icon: Icons.track_changes,
            iconColor: cs.primary,
            cs: cs,
            children: [
              _InfoRow(label: '🔥 Puntos ganadores', value: '${s.puntosGanadores}', color: cs.primary),
              _InfoRow(label: '✔ Puntos regulares', value: '${s.puntosRegulares}', color: const Color(0xFF22C55E)),
              _InfoRow(label: '✖ Errores', value: '${s.errores}', color: const Color(0xFFEF4444)),
              const Divider(height: 20),
              _InfoRow(label: 'Eficiencia', value: '${s.eficiencia.toStringAsFixed(0)}%', color: cs.onSurface),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'MVP',
            icon: Icons.star,
            iconColor: cs.primary,
            cs: cs,
            children: [
              _InfoRow(label: '⭐ MVP', value: '${s.mvpCount}', color: cs.primary),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'ASISTENCIA',
            icon: Icons.calendar_today,
            iconColor: const Color(0xFF22C55E),
            cs: cs,
            children: [
              _InfoRow(label: 'Asistencia', value: '${s.attendancePct.toStringAsFixed(0)}%', color: const Color(0xFF22C55E)),
              _InfoRow(label: 'Faltas', value: '${s.faltas}', color: const Color(0xFFEF4444)),
              _InfoRow(label: 'Justificadas', value: '${s.justificadas}', color: cs.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 16),
          _StatusCard(player: p, cs: cs),
        ],
      ),
    );
  }
}

class _AthleteHeader extends StatelessWidget {
  final Player player;
  final ColorScheme cs;

  const _AthleteHeader({required this.player, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: cs.primary.withValues(alpha: 0.15),
            child: Text(
              NameFormatter.avatarInitial(player),
              style: TextStyle(color: cs.primary, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(NameFormatter.playerDisplayName(player), style: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (player.numero != null) ...[
                      Text('#${player.numero}', style: TextStyle(color: cs.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                    ],
                    Text(_posicionLabel(player.posicion), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
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
  final ColorScheme cs;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.iconColor,
    required this.cs, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
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
  final ColorScheme cs;

  const _StatusCard({required this.player, required this.cs});

  @override
  Widget build(BuildContext context) {
    final isActive = player.atletaStatus != AthleteStatus.inactive;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 12),
          Text('Estado: ', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
          Text(isActive ? 'Activo' : 'Inactivo', style: TextStyle(color: isActive ? const Color(0xFF22C55E) : const Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.bold)),
          if (player.atletaStatus == AthleteStatus.resting) ...[
            const SizedBox(width: 8),
            Text('(Reposo)', style: TextStyle(color: cs.primary, fontSize: 12)),
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
