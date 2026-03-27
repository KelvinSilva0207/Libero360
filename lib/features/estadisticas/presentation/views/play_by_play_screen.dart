import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/models.dart';
import '../viewmodels/play_by_play_viewmodel.dart';

/// Pantalla principal de Play-by-Play
///
/// Muestra el marcador en tiempo real, permite registrar acciones
/// y visualizar el timeline de eventos del partido.
class PlayByPlayScreen extends StatelessWidget {
  const PlayByPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlayByPlayViewModel(),
      child: const _PlayByPlayContent(),
    );
  }
}

class _PlayByPlayContent extends StatelessWidget {
  const _PlayByPlayContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Play-by-Play'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          Consumer<PlayByPlayViewModel>(
            builder: (context, vm, _) {
              if (!vm.hayPartidoActivo) return const SizedBox();
              return IconButton(
                icon: Icon(
                  vm.estadoPartido == EstadoPartido.pausado
                      ? Icons.play_arrow
                      : Icons.pause,
                ),
                onPressed: () {
                  if (vm.estadoPartido == EstadoPartido.pausado) {
                    vm.reanudarPartido();
                  } else {
                    vm.pausarPartido();
                  }
                },
              );
            },
          ),
          Consumer<PlayByPlayViewModel>(
            builder: (context, vm, _) {
              if (vm.partidoActual == null) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.stop),
                onPressed: () => _mostrarDialogoFinalizar(context, vm),
              );
            },
          ),
        ],
      ),
      body: Consumer<PlayByPlayViewModel>(
        builder: (context, vm, _) {
          if (vm.partidoActual == null) {
            return _buildNuevoPartido(context, vm);
          }
          return _buildPartidoEnProgreso(context, vm);
        },
      ),
    );
  }

  Widget _buildNuevoPartido(BuildContext context, PlayByPlayViewModel vm) {
    final controllerLocal = TextEditingController();
    final controllerVisitante = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sports_volleyball,
            size: 80,
            color: Colors.deepOrange,
          ),
          const SizedBox(height: 24),
          const Text(
            'Nuevo Partido',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: controllerLocal,
            decoration: const InputDecoration(
              labelText: 'Equipo Local',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.home),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controllerVisitante,
            decoration: const InputDecoration(
              labelText: 'Equipo Visitante',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.sports_score),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (controllerLocal.text.isNotEmpty &&
                    controllerVisitante.text.isNotEmpty) {
                  vm.iniciarNuevoPartido(
                    equipoLocal: controllerLocal.text,
                    equipoVisitante: controllerVisitante.text,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'INICIAR PARTIDO',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          if (vm.error != null) ...[
            const SizedBox(height: 16),
            Text(
              vm.error!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartidoEnProgreso(BuildContext context, PlayByPlayViewModel vm) {
    return Column(
      children: [
        // Marcador
        _buildMarcador(context, vm),
        // Selector de equipo
        _buildSelectorEquipo(context, vm),
        // Jugadores
        Expanded(
          child: _buildJugadores(context, vm),
        ),
        // Acciones rápidas
        _buildAcciones(context, vm),
      ],
    );
  }

  Widget _buildMarcador(BuildContext context, PlayByPlayViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // Set actual
          Text(
            'SET ${vm.setActual}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          // Equipos y puntos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Equipo Local
              Expanded(
                child: Column(
                  children: [
                    Text(
                      vm.partidoActual?.equipoLocal ?? 'Local',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: vm.esEquipoLocal ? Colors.deepOrange : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      vm.partidoActual?.puntosLocal.toString() ?? '0',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: vm.esEquipoLocal ? Colors.deepOrange : Colors.black,
                      ),
                    ),
                    Text(
                      '${vm.partidoActual?.setsLocal ?? 0} sets',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Separador
              const Text(
                '-',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              // Equipo Visitante
              Expanded(
                child: Column(
                  children: [
                    Text(
                      vm.partidoActual?.equipoVisitante ?? 'Visitante',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: !vm.esEquipoLocal ? Colors.deepOrange : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      vm.partidoActual?.puntosVisitante.toString() ?? '0',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: !vm.esEquipoLocal ? Colors.deepOrange : Colors.black,
                      ),
                    ),
                    Text(
                      '${vm.partidoActual?.setsVisitante ?? 0} sets',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Indicador de turno
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_right,
                  color: vm.esEquipoLocal ? Colors.deepOrange : Colors.blue,
                ),
                Text(
                  'Turno: ${vm.esEquipoLocal ? vm.partidoActual?.equipoLocal : vm.partidoActual?.equipoVisitante}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: vm.esEquipoLocal ? Colors.deepOrange : Colors.blue,
                  ),
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
          Expanded(
            child: _buildEquipoTab(
              context,
              vm,
              esLocal: true,
              nombre: vm.partidoActual?.equipoLocal ?? 'Local',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildEquipoTab(
              context,
              vm,
              esLocal: false,
              nombre: vm.partidoActual?.equipoVisitante ?? 'Visitante',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipoTab(
    BuildContext context,
    PlayByPlayViewModel vm, {
    required bool esLocal,
    required String nombre,
  }) {
    final isSelected = vm.esEquipoLocal == esLocal;
    return GestureDetector(
      onTap: () => vm.cambiarEquipo(esLocal),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          nombre,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildJugadores(BuildContext context, PlayByPlayViewModel vm) {
    final jugadores = vm.esEquipoLocal
        ? vm.jugadoresLocal
        : vm.jugadoresVisitante;

    if (jugadores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No hay jugadores configurados',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _agregarJugadorDemo(vm),
              icon: const Icon(Icons.add),
              label: const Text('Agregar jugadores demo'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
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
              color: isSelected ? Colors.deepOrange : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.deepOrange : Colors.grey[300]!,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.deepOrange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  jugador.numero.toString(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  jugador.nombre,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.white70 : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAcciones(BuildContext context, PlayByPlayViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Jugador seleccionado
          if (vm.jugadorSeleccionado != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.deepOrange,
                    child: Text(
                      vm.jugadorSeleccionado!.numero.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vm.jugadorSeleccionado!.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _posicionToString(vm.jugadorSeleccionado!.posicion),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Botones de acciones
          Row(
            children: [
              Expanded(
                child: _buildAccionButton(
                  context,
                  vm,
                  icon: Icons.sports_volleyball,
                  label: 'Ataque +',
                  color: Colors.green,
                  onPressed: vm.jugadorSeleccionado != null
                      ? () => vm.registrarAtaque(esPositivo: true)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAccionButton(
                  context,
                  vm,
                  icon: Icons.sports_volleyball,
                  label: 'Ataque -',
                  color: Colors.red,
                  onPressed: vm.jugadorSeleccionado != null
                      ? () => vm.registrarAtaque(esPositivo: false)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildAccionButton(
                  context,
                  vm,
                  icon: Icons.wifi_tethering,
                  label: 'Saque +',
                  color: Colors.green,
                  onPressed: vm.jugadorSeleccionado != null
                      ? () => vm.registrarSaque(esPositivo: true)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAccionButton(
                  context,
                  vm,
                  icon: Icons.wifi_tethering,
                  label: 'Saque -',
                  color: Colors.red,
                  onPressed: vm.jugadorSeleccionado != null
                      ? () => vm.registrarSaque(esPositivo: false)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildAccionButton(
                  context,
                  vm,
                  icon: Icons.block,
                  label: 'Bloqueo',
                  color: Colors.orange,
                  onPressed: vm.jugadorSeleccionado != null
                      ? () => vm.registrarBloqueo(esPositivo: true)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAccionButton(
                  context,
                  vm,
                  icon: Icons.pan_tool,
                  label: 'Defensa',
                  color: Colors.blue,
                  onPressed: vm.jugadorSeleccionado != null
                      ? () => vm.registrarDefensa()
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAccionButton(
                  context,
                  vm,
                  icon: Icons.error_outline,
                  label: 'Error Rival',
                  color: Colors.grey,
                  onPressed: () => vm.registrarErrorContrario(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccionButton(
    BuildContext context,
    PlayByPlayViewModel vm, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoFinalizar(
    BuildContext context,
    PlayByPlayViewModel vm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Partido'),
        content: const Text(
          '¿Estás seguro de que quieres finalizar el partido? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              vm.finalizarPartido();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  void _agregarJugadorDemo(PlayByPlayViewModel vm) {
    // Jugadores demo para pruebas
    final jugadoresDemo = [
      Player.create(
        nombre: 'Juan Pérez',
        numero: 1,
        posicion: Posicion.receptor,
      ),
      Player.create(
        nombre: 'Carlos López',
        numero: 2,
        posicion: Posicion.colocador,
      ),
      Player.create(
        nombre: 'María García',
        numero: 3,
        posicion: Posicion.central,
      ),
      Player.create(
        nombre: 'Ana Martínez',
        numero: 4,
        posicion: Posicion.opuesto,
      ),
      Player.create(
        nombre: 'Pedro Sánchez',
        numero: 5,
        posicion: Posicion.receptor,
      ),
      Player.create(
        nombre: 'Luis Rodríguez',
        numero: 6,
        posicion: Posicion.central,
      ),
      Player.create(
        nombre: 'Sofia Díaz',
        numero: 7,
        posicion: Posicion.libre,
      ),
    ];

    vm.setJugadoresLocal(jugadoresDemo);
    vm.setJugadoresVisitante(jugadoresDemo);
  }

  String _posicionToString(Posicion posicion) {
    switch (posicion) {
      case Posicion.colocador:
        return 'Colocador';
      case Posicion.opuesto:
        return 'Opuesto';
      case Posicion.central:
        return 'Central';
      case Posicion.receptor:
        return 'Receptor';
      case Posicion.libre:
        return 'Líbero';
    }
  }
}
