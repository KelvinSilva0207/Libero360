import 'package:flutter/material.dart';

import '../../data/local_db/database_service.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../../../core/utils/name_formatter.dart';

/// Widget para registrar estadísticas en tiempo real durante un partido
///
/// Muestra 6 jugadores en formación de voleibol, permite seleccionar uno
/// y registrar acciones como ataques, saques, bloqueos, defensas y errores.
///
/// Diseño: Fondo oscuro con acentos azul (#002B5B, #0081CF) y naranja (#FF8C00)
class StatRecorderWidget extends StatefulWidget {
  /// Lista de jugadores a mostrar (máximo 6)
  final List<Player> jugadores;
  
  /// ID del partido actual
  final int matchId;
  
  /// Indica si el equipo es local (para registrar correctamente los puntos)
  final bool esEquipoLocal;
  
  /// Callback cuando se registra una acción exitosamente
  final Function(StatEvent)? onEventRegistered;
  
  /// Callback cuando hay un error
  final Function(String)? onError;

  const StatRecorderWidget({
    super.key,
    required this.jugadores,
    required this.matchId,
    this.esEquipoLocal = true,
    this.onEventRegistered,
    this.onError,
  });

  @override
  State<StatRecorderWidget> createState() => _StatRecorderWidgetState();
}

class _StatRecorderWidgetState extends State<StatRecorderWidget> {
  final StatEventRepository _repository = StatEventRepository();
  
  Player? _jugadorSeleccionado;
  bool _isLoading = false;

  // Colores del tema
  static const Color _primaryDark = Color(0xFF002B5B);
  static const Color _primaryLight = Color(0xFF0081CF);
  static const Color _accentOrange = Color(0xFFFF8C00);
  static const Color _backgroundDark = Color(0xFF1A1A2E);
  static const Color _surfaceDark = Color(0xFF16213E);
  static const Color _cardDark = Color(0xFF0F3460);

  // Posiciones de los 6 jugadores en la cancha (formación 4-2)
  // [2]     [3]     [4]
  //    [1]  [5]
  //       [6]
  final List<Offset> _posicionesCancha = [
    const Offset(0.5, 0.85),   // Posición 1 - Receptor/Defensa
    const Offset(0.25, 0.65),  // Posición 2 - Atacante izquierdo
    const Offset(0.75, 0.65),  // Posición 3 - Opuesto
    const Offset(0.15, 0.40),  // Posición 4 - Central
    const Offset(0.85, 0.40),  // Posición 5 - Central
    const Offset(0.5, 0.20),   // Posición 6 - Colocador
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _backgroundDark,
            _surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildCancha()),
          _buildBotonesAccion(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryDark.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_volleyball,
            color: _accentOrange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REGISTRO DE ESTADÍSTICAS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  widget.esEquipoLocal ? 'Equipo Local' : 'Equipo Visitante',
                  style: TextStyle(
                    color: _primaryLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_jugadorSeleccionado != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _accentOrange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _jugadorSeleccionado?.numero?.toString() ?? '—',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCancha() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Líneas de la cancha
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _StatsCourtPainter(),
            ),
            // Jugadores
            ...List.generate(
              widget.jugadores.length > 6 ? 6 : widget.jugadores.length,
              (index) {
                final jugador = widget.jugadores[index];
                final posicion = _posicionesCancha[index];
                final isSelected = _jugadorSeleccionado?.id == jugador.id;

                return Positioned(
                  left: posicion.dx * constraints.maxWidth - 35,
                  top: posicion.dy * constraints.maxHeight - 35,
                  child: GestureDetector(
                    onTap: () => _seleccionarJugador(jugador),
                    child: _buildJugadorWidget(jugador, isSelected),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildJugadorWidget(Player jugador, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? _accentOrange : _cardDark,
        border: Border.all(
          color: isSelected ? _accentOrange : _primaryLight,
          width: isSelected ? 3 : 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: _accentOrange.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${jugador.numero}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _getPosicionCorta(jugador.posicion),
            style: TextStyle(
              color: isSelected ? Colors.white70 : _primaryLight,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _getPosicionCorta(Posicion posicion) {
    switch (posicion) {
      case Posicion.colocador: return 'COL';
      case Posicion.opuesto: return 'OPP';
      case Posicion.central: return 'CEN';
      case Posicion.receptor: return 'REC';
      case Posicion.libre: return 'LIB';
      case Posicion.sinDefinir: return '—';
    }
  }

  Widget _buildBotonesAccion() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Jugador seleccionado info
          if (_jugadorSeleccionado != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _accentOrange,
                    radius: 20,
                    child: Text(
                      _jugadorSeleccionado?.numero?.toString() ?? '—',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          NameFormatter.playerDisplayName(_jugadorSeleccionado!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _getPosicionCompleta(_jugadorSeleccionado!.posicion),
                          style: TextStyle(
                            color: _primaryLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Botones de acción con 3 estados (+/−/≈)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              // ATAQUE +/−/≈
              _buildBotonAccion(
                icon: Icons.sports_volleyball,
                label: 'ATAQUE +',
                color: Colors.green,
                onTap: _jugadorSeleccionado != null
                    ? () => _registrarAccion(TipoAccion.ataque, ResultadoAccion.positivo)
                    : null,
              ),
              _buildBotonAccion(
                icon: Icons.sports_volleyball,
                label: 'ATAQUE ≈',
                color: Colors.grey,
                onTap: _jugadorSeleccionado != null
                    ? () => _registrarAccion(TipoAccion.ataque, ResultadoAccion.neutral)
                    : null,
              ),
              _buildBotonAccion(
                icon: Icons.sports_volleyball,
                label: 'ATAQUE -',
                color: Colors.red.shade400,
                onTap: _jugadorSeleccionado != null
                    ? () => _registrarAccion(TipoAccion.ataque, ResultadoAccion.negativo)
                    : null,
              ),
              // SAQUE +/−/≈
              _buildBotonAccion(
                icon: Icons.wifi_tethering,
                label: 'SAQUE +',
                color: Colors.green,
                onTap: _jugadorSeleccionado != null
                    ? () => _registrarAccion(TipoAccion.saque, ResultadoAccion.positivo)
                    : null,
              ),
              _buildBotonAccion(
                icon: Icons.wifi_tethering,
                label: 'SAQUE ≈',
                color: Colors.grey,
                onTap: _jugadorSeleccionado != null
                    ? () => _registrarAccion(TipoAccion.saque, ResultadoAccion.neutral)
                    : null,
              ),
              _buildBotonAccion(
                icon: Icons.wifi_tethering,
                label: 'SAQUE -',
                color: Colors.red.shade400,
                onTap: _jugadorSeleccionado != null
                    ? () => _registrarAccion(TipoAccion.saque, ResultadoAccion.negativo)
                    : null,
              ),
              // BLOQUEO +/−/≈
              _buildBotonAccion(
                icon: Icons.block,
                label: 'BLOQUEO +',
                color: _accentOrange,
                onTap: _jugadorSeleccionado != null
                    ? () => _registrarAccion(TipoAccion.bloqueo, ResultadoAccion.positivo)
                    : null,
              ),
              _buildBotonAccion(
                icon: Icons.block,
                label: 'BLOQUEO ≈',
                color: Colors.grey,
                onTap: _jugadorSeleccionado != null
                    ? () => _registrarAccion(TipoAccion.bloqueo, ResultadoAccion.neutral)
                    : null,
              ),
              _buildBotonAccion(
                icon: Icons.pan_tool,
                label: 'DEFENSA',
                color: _primaryLight,
                onTap: _jugadorSeleccionado != null
                    ? () => _registrarAccion(TipoAccion.defensa, ResultadoAccion.neutral)
                    : null,
              ),
              _buildBotonAccion(
                icon: Icons.error_outline,
                label: 'ERROR',
                color: Colors.grey,
                onTap: () => _registrarError(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotonAccion({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isEnabled 
                ? color.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled 
                  ? color.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isEnabled 
                    ? color
                    : Colors.grey,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isEnabled 
                      ? Colors.white
                      : Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPosicionCompleta(Posicion posicion) {
    switch (posicion) {
      case Posicion.colocador: return 'Colocador';
      case Posicion.opuesto: return 'Opuesto';
      case Posicion.central: return 'Central';
      case Posicion.receptor: return 'Receptor';
      case Posicion.libre: return 'Líbero';
      case Posicion.sinDefinir: return 'Sin definir';
    }
  }

  void _seleccionarJugador(Player jugador) {
    setState(() {
      _jugadorSeleccionado = jugador;
    });
  }

  Future<void> _registrarAccion(TipoAccion tipo, ResultadoAccion resultado) async {
    if (_jugadorSeleccionado == null) return;

    setState(() => _isLoading = true);

    try {
      final match = await DatabaseService.instance.getMatchById(widget.matchId);
      if (match == null) throw Exception('Partido no encontrado');

      final evento = StatEvent.create(
        tipoAccion: tipo,
        resultado: resultado,
        setNumero: match.setActual,
        puntoLocal: match.puntosLocal,
        puntoVisitante: match.puntosVisitante,
        esEquipoLocal: widget.esEquipoLocal,
        zona: tipo == TipoAccion.ataque ? ZonaCancha.ataque
            : tipo == TipoAccion.saque ? ZonaCancha.saque
            : tipo == TipoAccion.bloqueo ? ZonaCancha.central
            : ZonaCancha.defensa,
        playerId: _jugadorSeleccionado!.id,
        matchId: widget.matchId,
      );

      await DatabaseService.instance.saveStatEvent(evento);

      _mostrarFeedback(resultado != ResultadoAccion.negativo);

      widget.onEventRegistered?.call(evento);
    } catch (e) {
      widget.onError?.call('Error al registrar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registrarError() async {
    setState(() => _isLoading = true);

    try {
      final evento = await _repository.registrarErrorContrario(
        matchId: widget.matchId,
        esEquipoLocal: widget.esEquipoLocal,
      );

      _mostrarFeedback(true, esError: true);
      
      widget.onEventRegistered?.call(evento);
    } catch (e) {
      widget.onError?.call('Error al registrar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarFeedback(bool esPositivo, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              esError 
                  ? Icons.error_outline 
                  : (esPositivo ? Icons.check_circle : Icons.cancel),
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              esError 
                  ? 'Error registrado'
                  : (esPositivo ? '¡Punto! +1' : 'Punto perdido'),
            ),
          ],
        ),
        backgroundColor: esError 
            ? Colors.grey 
            : (esPositivo ? Colors.green : Colors.red),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _StatsCourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final redPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    canvas.drawRect(rect, paint);

    final ataqueY = size.height * 0.3;
    canvas.drawLine(Offset(10, ataqueY), Offset(size.width - 10, ataqueY), paint);

    canvas.drawLine(
      Offset(10, size.height / 2),
      Offset(size.width - 10, size.height / 2),
      redPaint,
    );

    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (double x = 20; x < size.width - 20; x += 20) {
      canvas.drawLine(
        Offset(x, size.height / 2 - 5),
        Offset(x + 10, size.height / 2 - 5),
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

