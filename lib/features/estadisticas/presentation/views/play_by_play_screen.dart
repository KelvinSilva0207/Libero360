import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/models/models.dart';
import '../../../partido/presentation/controllers/match_controller.dart';
import '../../../../core/utils/name_formatter.dart';
import '../viewmodels/play_by_play_viewmodel.dart';

class PlayByPlayScreen extends StatelessWidget {
  const PlayByPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => PlayByPlayViewModel(ctx.read<MatchController>()),
      child: const _PlayByPlayContent(),
    );
  }
}

class _PlayByPlayContent extends StatelessWidget {
  const _PlayByPlayContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayByPlayViewModel>(
      builder: (context, vm, _) {
        if (vm.partidoActual == null) {
          return _buildNuevoPartido(context, vm);
        }
        return Column(
          children: [
            _buildHeader(context, vm),
            _buildMarcador(context, vm),
            _buildSelectorEquipo(context, vm),
            Expanded(child: _buildJugadores(context, vm)),
            _buildAcciones(context, vm),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, PlayByPlayViewModel vm) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: cs.onSurface, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.bar_chart_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Play-by-Play',
              style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          if (vm.hayPartidoActivo) ...[
            IconButton(
              icon: Icon(
                vm.estadoPartido == EstadoPartido.pausado
                    ? Icons.play_arrow
                    : Icons.pause,
                color: cs.onSurface,
              ),
              tooltip: vm.estadoPartido == EstadoPartido.pausado ? 'Reanudar' : 'Pausar',
              onPressed: () {
                if (vm.estadoPartido == EstadoPartido.pausado) {
                  vm.reanudarPartido();
                } else {
                  vm.pausarPartido();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.redAccent),
              tooltip: 'Finalizar partido',
              onPressed: () => _mostrarDialogoFinalizar(context, vm),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNuevoPartido(BuildContext context, PlayByPlayViewModel vm) {
    final cs = Theme.of(context).colorScheme;
    final controllerLocal = TextEditingController();
    final controllerVisitante = TextEditingController();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_volleyball, size: 80, color: AppColors.accent),
              const SizedBox(height: 24),
              Text(
                'Nuevo Partido',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cs.onSurface),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: controllerLocal,
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                  labelText: 'Equipo Local',
                  labelStyle: TextStyle(color: cs.onSurfaceVariant),
                  prefixIcon: const Icon(Icons.home, color: AppColors.primary, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controllerVisitante,
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                  labelText: 'Equipo Visitante',
                  labelStyle: TextStyle(color: cs.onSurfaceVariant),
                  prefixIcon: const Icon(Icons.sports_score, color: AppColors.primary, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    if (controllerLocal.text.isNotEmpty && controllerVisitante.text.isNotEmpty) {
                      vm.iniciarNuevoPartido(
                        equipoLocal: controllerLocal.text,
                        equipoVisitante: controllerVisitante.text,
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('INICIAR PARTIDO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              if (vm.error != null) ...[
                const SizedBox(height: 16),
                Text(vm.error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarcador(BuildContext context, PlayByPlayViewModel vm) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'SET ${vm.setActual}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      vm.partidoActual?.equipoLocal ?? 'Local',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold,
                        color: vm.esEquipoLocal ? AppColors.accent : cs.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vm.partidoActual?.puntosLocal.toString() ?? '0',
                      style: TextStyle(
                        fontSize: 48, fontWeight: FontWeight.bold,
                        color: vm.esEquipoLocal ? AppColors.accent : cs.onSurface,
                      ),
                    ),
                    Text(
                      '${vm.partidoActual?.setsLocal ?? 0} sets',
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('-', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: cs.onSurface.withValues(alpha: 0.3))),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      vm.partidoActual?.equipoVisitante ?? 'Visitante',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold,
                        color: !vm.esEquipoLocal ? AppColors.accent : cs.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vm.partidoActual?.puntosVisitante.toString() ?? '0',
                      style: TextStyle(
                        fontSize: 48, fontWeight: FontWeight.bold,
                        color: !vm.esEquipoLocal ? AppColors.accent : cs.onSurface,
                      ),
                    ),
                    Text(
                      '${vm.partidoActual?.setsVisitante ?? 0} sets',
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_right, color: vm.esEquipoLocal ? AppColors.accent : AppColors.primary, size: 20),
                const SizedBox(width: 4),
                Text(
                  'Turno: ${vm.esEquipoLocal ? vm.partidoActual?.equipoLocal : vm.partidoActual?.equipoVisitante}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: vm.esEquipoLocal ? AppColors.accent : AppColors.primary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorEquipo(BuildContext context, PlayByPlayViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(child: _buildEquipoTab(context, vm, esLocal: true, nombre: vm.partidoActual?.equipoLocal ?? 'Local')),
          const SizedBox(width: 8),
          Expanded(child: _buildEquipoTab(context, vm, esLocal: false, nombre: vm.partidoActual?.equipoVisitante ?? 'Visitante')),
        ],
      ),
    );
  }

  Widget _buildEquipoTab(BuildContext context, PlayByPlayViewModel vm, {required bool esLocal, required String nombre}) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = vm.esEquipoLocal == esLocal;
    return GestureDetector(
      onTap: () => vm.cambiarEquipo(esLocal),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          nombre,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? cs.onPrimary : cs.onSurfaceVariant, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildJugadores(BuildContext context, PlayByPlayViewModel vm) {
    final cs = Theme.of(context).colorScheme;
    final jugadores = vm.esEquipoLocal ? vm.jugadoresLocal : vm.jugadoresVisitante;

    if (jugadores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: cs.onSurface.withValues(alpha: 0.38)),
            const SizedBox(height: 16),
            Text('No hay jugadores configurados', style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _agregarJugadorDemo(vm),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar jugadores demo'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: jugadores.length,
      itemBuilder: (context, index) {
        final jugador = jugadores[index];
        final isSelected = vm.jugadorSeleccionado?.id == jugador.id;

        return GestureDetector(
          onTap: () => vm.seleccionarJugador(jugador),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppColors.accent : cs.outlineVariant, width: isSelected ? 2 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  jugador.numero.toString(),
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isSelected ? cs.onPrimary : AppColors.accent),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    NameFormatter.playerDisplayName(jugador),
                    style: TextStyle(fontSize: 10, color: isSelected ? cs.onSurface.withValues(alpha: 0.7) : cs.onSurface.withValues(alpha: 0.6)),
                    maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAcciones(BuildContext context, PlayByPlayViewModel vm) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (vm.jugadorSeleccionado != null)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.accent,
                    child: Text(vm.jugadorSeleccionado?.numero?.toString() ?? '—', style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(NameFormatter.playerDisplayName(vm.jugadorSeleccionado!), style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface, fontSize: 13)),
                        Text(_posicionToString(vm.jugadorSeleccionado!.posicion), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _accionBtn(icon: Icons.sports_volleyball, label: 'Ataque +', color: Colors.green, onPressed: vm.jugadorSeleccionado != null ? () => vm.registrarAtaque(esPositivo: true) : null),
              _accionBtn(icon: Icons.sports_volleyball, label: 'Ataque -', color: Colors.red, onPressed: vm.jugadorSeleccionado != null ? () => vm.registrarAtaque(esPositivo: false) : null),
              _accionBtn(icon: Icons.wifi_tethering, label: 'Saque +', color: Colors.green, onPressed: vm.jugadorSeleccionado != null ? () => vm.registrarSaque(esPositivo: true) : null),
              _accionBtn(icon: Icons.wifi_tethering, label: 'Saque -', color: Colors.red, onPressed: vm.jugadorSeleccionado != null ? () => vm.registrarSaque(esPositivo: false) : null),
              _accionBtn(icon: Icons.block, label: 'Bloqueo', color: Colors.orange, onPressed: vm.jugadorSeleccionado != null ? () => vm.registrarBloqueo(esPositivo: true) : null),
              _accionBtn(icon: Icons.pan_tool, label: 'Defensa', color: AppColors.primary, onPressed: vm.jugadorSeleccionado != null ? () => vm.registrarDefensa() : null),
              _accionBtn(icon: Icons.error_outline, label: 'Error Rival', color: cs.onSurfaceVariant, onPressed: () => vm.registrarErrorContrario()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _accionBtn({required IconData icon, required String label, required Color color, required VoidCallback? onPressed}) {
    return SizedBox(
      width: 96,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.withValues(alpha: 0.4)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoFinalizar(BuildContext context, PlayByPlayViewModel vm) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surfaceContainerHighest,
        title: Text('Finalizar Partido', style: TextStyle(color: cs.onSurface)),
        content: Text('¿Estás seguro de que quieres finalizar el partido? Esta acción no se puede deshacer.', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: cs.onSurfaceVariant))),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              vm.finalizarPartido();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  void _agregarJugadorDemo(PlayByPlayViewModel vm) {
    final jugadoresDemo = [
      Player.create(nombre: 'Juan Pérez', cedula: '001-0000001-1', fechaNacimiento: DateTime(2000, 5, 15), numero: 1, posicion: Posicion.receptor),
      Player.create(nombre: 'Carlos López', cedula: '001-0000002-2', fechaNacimiento: DateTime(1999, 8, 22), numero: 2, posicion: Posicion.colocador),
      Player.create(nombre: 'María García', cedula: '001-0000003-3', fechaNacimiento: DateTime(2001, 3, 10), numero: 3, posicion: Posicion.central),
      Player.create(nombre: 'Ana Martínez', cedula: '001-0000004-4', fechaNacimiento: DateTime(2002, 11, 5), numero: 4, posicion: Posicion.opuesto),
      Player.create(nombre: 'Pedro Sánchez', cedula: '001-0000005-5', fechaNacimiento: DateTime(2000, 7, 30), numero: 5, posicion: Posicion.receptor),
      Player.create(nombre: 'Luis Rodríguez', cedula: '001-0000006-6', fechaNacimiento: DateTime(1998, 12, 18), numero: 6, posicion: Posicion.central),
      Player.create(nombre: 'Sofia Díaz', cedula: '001-0000007-7', fechaNacimiento: DateTime(2001, 9, 25), numero: 7, posicion: Posicion.libre),
    ];
    vm.setJugadoresLocal(jugadoresDemo);
    vm.setJugadoresVisitante(jugadoresDemo);
  }

  String _posicionToString(Posicion posicion) {
    switch (posicion) {
      case Posicion.colocador: return 'Armador';
      case Posicion.opuesto: return 'Opuesto';
      case Posicion.central: return 'Central';
      case Posicion.receptor: return 'Punta (Receptor)';
      case Posicion.libre: return 'Líbero';
      case Posicion.sinDefinir: return 'Sin definir';
    }
  }
}
