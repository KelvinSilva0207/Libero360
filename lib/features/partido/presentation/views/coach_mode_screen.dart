import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../viewmodels/partido_viewmodel.dart';
import '../../data/match_event.dart';
import '../../../estadisticas/data/local_db/database_service.dart';

class CoachModeScreen extends StatelessWidget {
  const CoachModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PartidoViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            title: const Text('Modo Entrenador', style: TextStyle(color: Colors.white, fontSize: 15)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: vm.isPartidoActivo ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      vm.isPartidoActivo ? Icons.play_arrow : Icons.pause,
                      size: 14,
                      color: vm.isPartidoActivo ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      vm.isPartidoActivo ? 'En vivo' : 'Pausado',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: vm.isPartidoActivo ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildScoreBar(vm),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _buildCurrentRotation(vm),
                    const SizedBox(height: 12),
                    _buildErrorsSection(vm),
                    const SizedBox(height: 12),
                    _buildSubstitutionSuggestions(vm),
                    const SizedBox(height: 12),
                    _buildSetHistory(vm),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScoreBar(PartidoViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(vm.nombreLocal.toUpperCase(),
            style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${vm.puntosLocal} - ${vm.puntosVisitante}',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Text(vm.nombreVisitante.toUpperCase(),
            style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Set ${vm.setActual}',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentRotation(PartidoViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: vm.isLocalServing ? Colors.green.withValues(alpha: 0.2) : Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      vm.isLocalServing ? Icons.volunteer_activism : Icons.sports_volleyball,
                      size: 14,
                      color: vm.isLocalServing ? Colors.green : Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Saca: ${vm.isLocalServing ? vm.nombreLocal : vm.nombreVisitante}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: vm.isLocalServing ? Colors.green : Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text('Rotación #${vm.rotacionLocal + 1}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(vm.jugadores.length.clamp(0, 6), (i) {
              final p = i < vm.jugadores.length ? vm.jugadores[i] : null;
              final isServer = vm.isLocalServing && i == 0;
              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isServer ? Colors.green.withValues(alpha: 0.2) : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isServer ? Colors.green : Colors.white12,
                        width: isServer ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${p?.numero ?? "-"}',
                        style: TextStyle(
                          color: isServer ? Colors.green : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p != null ? (p.nombre.split(' ').first) : '',
                    style: const TextStyle(color: Colors.white54, fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorsSection(PartidoViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
              const SizedBox(width: 8),
              const Text('Errores por atleta',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('Set ${vm.setActual}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          ...vm.jugadores.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text('${p.numero ?? "?"}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(p.nombre, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                Text('0', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSubstitutionSuggestions(PartidoViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, color: AppColors.accent, size: 16),
              const SizedBox(width: 8),
              const Text('Sugerencias',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Monitoreando rendimiento en tiempo real...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildSetHistory(PartidoViewModel vm) {
    return FutureBuilder<List<MatchEvent>>(
      future: DatabaseService.instance.getMatchEvents(vm.match?.id ?? 0),
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_rounded, color: AppColors.accent, size: 16),
                  const SizedBox(width: 8),
                  const Text('Historial del Set',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('${events.length} eventos',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 10),
              if (events.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('Sin eventos registrados en este set',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic)),
                  ),
                )
              else
                ...events.take(20).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(e.eventType.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Atleta #$e.athleteId - ${e.eventType.label}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                      Text('Set ${e.setNumero}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 9)),
                    ],
                  ),
                )),
              if (events.length > 20)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text('+${events.length - 20} más',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
