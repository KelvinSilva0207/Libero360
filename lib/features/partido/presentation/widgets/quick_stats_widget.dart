import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../../estadisticas/data/stat_event_bus.dart';

class QuickStatsWidget extends StatefulWidget {
  final int matchId;

  const QuickStatsWidget({super.key, required this.matchId});

  @override
  State<QuickStatsWidget> createState() => _QuickStatsWidgetState();
}

class _QuickStatsWidgetState extends State<QuickStatsWidget> {
  late Future<List<StatEvent>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = DatabaseService.instance.getEventsByMatch(widget.matchId);
    StatEventBus.instance.addListener(_onStatEvent);
  }

  @override
  void dispose() {
    StatEventBus.instance.removeListener(_onStatEvent);
    super.dispose();
  }

  void _onStatEvent() {
    setState(() {
      _eventsFuture = DatabaseService.instance.getEventsByMatch(widget.matchId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, size: 14, color: Colors.white38),
              SizedBox(width: 6),
              Text(
                'Estadísticas rápidas',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          _StatsBody(future: _eventsFuture),
        ],
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  final Future<List<StatEvent>> future;

  const _StatsBody({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StatEvent>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white38,
              ),
            ),
          );
        }

        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return Center(
            child: Text(
              'Sin datos',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          );
        }

        final counts = <TipoAccion, int>{};
        for (final e in events) {
          counts[e.tipoAccion] = (counts[e.tipoAccion] ?? 0) + 1;
        }

        final colorMapping = {
          TipoAccion.ataque: Colors.orangeAccent,
          TipoAccion.saque: Colors.blueAccent,
          TipoAccion.bloqueo: Colors.greenAccent,
          TipoAccion.defensa: Colors.purpleAccent,
          TipoAccion.recepcion: Colors.tealAccent,
          TipoAccion.colocacion: Colors.amberAccent,
          TipoAccion.errorContrario: Colors.redAccent,
        };

        return Wrap(
          spacing: 6,
          runSpacing: 4,
          children: counts.entries.map((e) {
            final color = colorMapping[e.key] ?? Colors.white54;
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${e.key.name.toUpperCase()} ${e.value}',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
