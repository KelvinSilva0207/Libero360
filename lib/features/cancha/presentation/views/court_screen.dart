import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/player.dart';
import '../../data/court_models.dart';
import '../viewmodels/court_viewmodel.dart';
import '../widgets/court_painter.dart';
import '../widgets/position_slot.dart';
import '../widgets/rotation_timeline.dart';
import '../../../../core/utils/name_formatter.dart';
import 'court_setup_dialog.dart';

class CourtScreen extends StatefulWidget {
  const CourtScreen({super.key});

  @override
  State<CourtScreen> createState() => _CourtScreenState();
}

class _CourtScreenState extends State<CourtScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rotationAnimCtrl;
  bool _isRotating = false;
  int? _eventPlayerId;

  @override
  void initState() {
    super.initState();
    _rotationAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _rotationAnimCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isRotating = false);
      }
    });
  }

  @override
  void dispose() {
    _rotationAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CourtViewModel()..init(),
      child: Consumer<CourtViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: _buildAppBar(context, vm),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: _buildAppBar(context, vm),
            body: vm.allPlayers.isEmpty
                ? _buildEmptyState(context)
                : (vm.isLineupSet ? _buildCourtContent(context, vm) : _buildSetupPrompt(context, vm)),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, CourtViewModel vm) {
    final colors = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: colors.surface,
      title: Row(
        children: [
          Image.asset('assets/images/logo_libero.png', width: 20, height: 20),
          const SizedBox(width: 8),
          const Text('Cancha', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        if (vm.isLineupSet)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: colors.surface,
            onSelected: (v) {
              if (v == 'reset') {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: colors.surface,
                    title: const Text('¿Reiniciar cancha?', style: TextStyle(color: Colors.white)),
                    content: const Text('Se perderá la formación actual.', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                      TextButton(
                        onPressed: () { Navigator.pop(ctx); vm.resetLineup(); },
                        child: const Text('Reiniciar', style: TextStyle(color: AppColors.accent)),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'reset', child: Text('Reiniciar formación')),
            ],
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_add_rounded, size: 48, color: colors.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('No hay jugadoras registradas', style: TextStyle(color: colors.onSurface, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Agrega atletas desde la sección Atletas primero',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSetupPrompt(BuildContext context, CourtViewModel vm) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.sports_volleyball_rounded, size: 40, color: AppColors.accent),
          ),
          const SizedBox(height: 20),
          Text('Cancha de práctica', style: TextStyle(color: colors.onSurface, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Visualiza rotaciones y registra puntos', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => CourtSetupDialog(
                onComplete: (players) {
                  for (int i = 0; i < players.length && i < 6; i++) {
                    vm.assignPlayerDirect(players[i], i);
                  }
                },
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Configurar formación'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtContent(BuildContext context, CourtViewModel vm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCourtWithSlots(context, vm),
          const SizedBox(height: 16),
          _buildServerInfo(context, vm),
          const SizedBox(height: 16),
          _buildActionRow(context, vm),
          const SizedBox(height: 20),
          RotationTimeline(
            history: vm.history,
            currentRotation: vm.rotationCount,
            currentLineup: vm.positions,
          ),
        ],
      ),
    );
  }

  Widget _buildCourtWithSlots(BuildContext context, CourtViewModel vm) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final courtWidth = maxWidth.clamp(280.0, 400.0);
        final courtHeight = courtWidth * 1.3;

        return Center(
          child: SizedBox(
            width: courtWidth,
            height: courtHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(courtWidth, courtHeight),
                    painter: CourtPainter(
                      lineColor: colors.onSurfaceVariant.withValues(alpha: 0.2),
                      courtColor: colors.surface,
                      netColor: colors.onSurface.withValues(alpha: 0.15),
                    ),
                  ),
                  _buildSlots(vm, courtWidth, courtHeight),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlots(CourtViewModel vm, double w, double h) {
    const positions = [
      _SlotPos(0.5, 0.03),  // Pos 4
      _SlotPos(0.15, 0.30), // Pos 3
      _SlotPos(0.85, 0.30), // Pos 5
      _SlotPos(0.50, 0.53), // Pos 6
      _SlotPos(0.15, 0.76), // Pos 2
      _SlotPos(0.85, 0.76), // Pos 1
    ];

    final slots = <Widget>[];
    for (int i = 0; i < 6; i++) {
      final assignment = vm.positions[i];
      final isServer = i == vm.serverIndex && vm.isServing;
      final isSelected = _eventPlayerId == (assignment?.player.id);

      slots.add(
        Positioned(
          left: positions[i].x * w - 31,
          top: positions[i].y * h - 31,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            offset: Offset.zero,
            child: Opacity(
              opacity: _isRotating ? 0.85 : 1.0,
              child: PositionSlot(
                index: i,
                assignment: assignment,
                isServing: isServer,
                isBeingEdited: isSelected,
                onTap: () => _onSlotTap(context, vm, i, assignment),
                onEditNumber: assignment != null ? () => _showEditNumber(context, vm, i) : null,
                onRemove: assignment != null ? () => vm.removePlayerFromPosition(i) : null,
              ),
            ),
          ),
        ),
      );
    }
    return Stack(children: slots);
  }

  void _onSlotTap(BuildContext context, CourtViewModel vm, int index, PlayerAssignment? assignment) {
    if (assignment == null) {
      vm.selectPlayerForPosition(index);
      _showPlayerPicker(context, vm);
      return;
    }

    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _buildPointRecorderSheet(ctx, vm, assignment, colors),
    );
  }

  Widget _buildPointRecorderSheet(BuildContext context, CourtViewModel vm, PlayerAssignment p, ColorScheme colors) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: colors.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text('#${p.effectiveNumber}',
                      style: const TextStyle(color: AppColors.accent, fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(NameFormatter.playerDisplayName(p.player),
                        style: TextStyle(color: colors.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
                      Text('Posición ${p.position} · ${p.player.posicionLabel}',
                        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _EventButton(
                  emoji: '🔥', label: 'Ganador',
                  color: const Color(0xFF22C55E),
                  onTap: () { _recordAndClose(context, vm, p.player.id, EventType.winnerPoint); },
                )),
                const SizedBox(width: 10),
                Expanded(child: _EventButton(
                  emoji: '✔', label: 'Regular',
                  color: const Color(0xFF3B82F6),
                  onTap: () { _recordAndClose(context, vm, p.player.id, EventType.regularPoint); },
                )),
                const SizedBox(width: 10),
                Expanded(child: _EventButton(
                  emoji: '✖', label: 'Error',
                  color: const Color(0xFFEF4444),
                  onTap: () { _recordAndClose(context, vm, p.player.id, EventType.error); },
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _recordAndClose(BuildContext context, CourtViewModel vm, int playerId, EventType type) {
    Navigator.pop(context);
    vm.recordEvent(playerId, type);
    _showEventFeedback(context, type);
  }

  void _showEventFeedback(BuildContext context, EventType type) {
    final colors = Theme.of(context).colorScheme;
    final data = switch (type) {
      EventType.winnerPoint => ('🔥', 'Punto ganador', const Color(0xFF22C55E)),
      EventType.regularPoint => ('✔', 'Punto regular', const Color(0xFF3B82F6)),
      EventType.error => ('✖', 'Error', const Color(0xFFEF4444)),
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(data.$1, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(data.$2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: colors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  void _showPlayerPicker(BuildContext context, CourtViewModel vm) {
    final colors = Theme.of(context).colorScheme;
    final available = vm.unassignedPlayers;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: colors.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text('Seleccionar jugadora',
                style: TextStyle(color: colors.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Posición ${(vm.selectedPositionIndex ?? 0) + 1}',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: 16),
              Expanded(
                child: available.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_search_rounded, size: 40, color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
                            const SizedBox(height: 8),
                            Text('Todas las jugadoras están asignadas',
                              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: available.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (_, i) => _buildPlayerOption(available[i], vm, ctx, colors),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerOption(Player p, CourtViewModel vm, BuildContext ctx, ColorScheme colors) {
    final isAssigned = vm.positions.any((pos) => pos?.player.id == p.id);
    if (isAssigned) return const SizedBox.shrink();

    return InkWell(
      onTap: () {
        vm.assignPlayer(p);
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text('${p.numero ?? "?"}',
                  style: const TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(NameFormatter.playerDisplayName(p), style: TextStyle(color: colors.onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(p.posicionLabel, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.add_circle_outline_rounded, size: 20, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showEditNumber(BuildContext context, CourtViewModel vm, int index) {
    final colors = Theme.of(context).colorScheme;
    final current = vm.positions[index];
    if (current == null) return;

    final ctrl = TextEditingController(text: '${current.effectiveNumber}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Editar número · ${NameFormatter.playerDisplayName(current.player)}',
          style: TextStyle(color: colors.onSurface, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: TextStyle(color: colors.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Número de camiseta',
            labelStyle: TextStyle(color: colors.onSurfaceVariant),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: colors.surface.withValues(alpha: 0.5),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: colors.onSurfaceVariant))),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(ctrl.text.trim());
              if (n != null) vm.editNumber(index, n);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildServerInfo(BuildContext context, CourtViewModel vm) {
    final colors = Theme.of(context).colorScheme;
    final server = vm.serverPlayer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.volunteer_activism, size: 16, color: Color(0xFF22C55E)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Servicio', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w500)),
              Text(
                server != null
                    ? '#${server.effectiveNumber} · ${NameFormatter.playerDisplayName(server.player)}'
                    : 'Sin servidor',
                style: TextStyle(color: colors.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Posición 1',
              style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, CourtViewModel vm) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: vm.isLineupSet
                ? () {
                    setState(() => _isRotating = true);
                    vm.rotate();
                    _rotationAnimCtrl.forward(from: 0);
                  }
                : null,
            icon: AnimatedRotation(
              turns: _isRotating ? 0.166 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: const Icon(Icons.sync_rounded, size: 18),
            ),
            label: const Text('Ganó el saque', style: TextStyle(fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              disabledBackgroundColor: colors.onSurface.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => _showStatsSummary(context, vm),
          icon: const Icon(Icons.bar_chart_rounded, size: 18),
          label: const Text('Estadísticas'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.onSurface,
            side: BorderSide(color: colors.outlineVariant),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  void _showStatsSummary(BuildContext context, CourtViewModel vm) {
    final colors = Theme.of(context).colorScheme;
    final eventCounts = <EventType, int>{
      EventType.winnerPoint: 0,
      EventType.regularPoint: 0,
      EventType.error: 0,
    };
    for (final e in vm.events) {
      eventCounts[e.eventType] = (eventCounts[e.eventType] ?? 0) + 1;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: colors.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.bar_chart_rounded, size: 20, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text('Resumen de la práctica',
                    style: TextStyle(color: colors.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 20),
              _buildStatRow('🔥 Puntos ganadores', eventCounts[EventType.winnerPoint] ?? 0, const Color(0xFF22C55E)),
              _buildStatRow('✔ Puntos regulares', eventCounts[EventType.regularPoint] ?? 0, const Color(0xFF3B82F6)),
              _buildStatRow('✖ Errores', eventCounts[EventType.error] ?? 0, const Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Container(height: 1, color: colors.outlineVariant),
              const SizedBox(height: 12),
              _buildStatRow('Total', vm.events.length, colors.onSurface),
              const SizedBox(height: 20),
              Text('Rotaciones: ${vm.rotationCount}',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text('$count', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SlotPos {
  final double x, y;
  const _SlotPos(this.x, this.y);
}

class _EventButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _EventButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(label,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
