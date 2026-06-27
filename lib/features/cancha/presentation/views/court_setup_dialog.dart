import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/player.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../../../core/utils/name_formatter.dart';

class CourtSetupDialog extends StatefulWidget {
  final void Function(List<Player> selected) onComplete;

  const CourtSetupDialog({super.key, required this.onComplete});

  @override
  State<CourtSetupDialog> createState() => _CourtSetupDialogState();
}

class _CourtSetupDialogState extends State<CourtSetupDialog> {
  final List<Player?> _selected = List.filled(6, null);
  List<Player> _allPlayers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    try {
      final players = await DatabaseService.instance.getPlayers();
      setState(() {
        _allPlayers = players;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  int get _filledCount => _selected.where((p) => p != null).length;
  bool get _isComplete => _filledCount == 6;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.sports_volleyball_rounded, color: AppColors.accent, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              'Formación inicial',
              style: TextStyle(color: colors.onSurface, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Selecciona 6 jugadoras para la cancha',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else
              ...List.generate(6, (i) => _buildPositionRow(i, colors)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.onSurfaceVariant,
                      side: BorderSide(color: colors.outlineVariant),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _isComplete
                        ? () {
                            widget.onComplete(_selected.whereType<Player>().toList());
                            Navigator.pop(context);
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      disabledBackgroundColor: colors.onSurface.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _isComplete ? 'Iniciar cancha' : '$_filledCount/6 seleccionadas',
                      style: TextStyle(
                        color: _isComplete ? Colors.white : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionRow(int index, ColorScheme colors) {
    final positionNames = ['Z1 (Saque)', 'Z2', 'Z3', 'Z4', 'Z5', 'Z6'];
    final player = _selected[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showPlayerPicker(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: player != null ? AppColors.accent.withValues(alpha: 0.08) : colors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: player != null ? AppColors.accent.withValues(alpha: 0.3) : colors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: player != null ? AppColors.accent : colors.onSurfaceVariant.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: player != null ? Colors.white : colors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  player != null ? NameFormatter.playerDisplayName(player) : positionNames[index],
                  style: TextStyle(
                    color: player != null ? colors.onSurface : colors.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: player != null ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
              if (player != null)
                Text(
                  '#${player.numero ?? "?"}',
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                ),
              const SizedBox(width: 8),
              Icon(
                player != null ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                size: 20,
                color: player != null ? AppColors.accent : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlayerPicker(int index) {
    final available = _allPlayers.where((p) =>
      p.id == _selected[index]?.id || !_selected.whereType<Player>().any((s) => s.id == p.id)
    ).toList();

    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Posición ${index + 1}',
                style: TextStyle(color: colors.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Selecciona una jugadora',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: available.isEmpty
                    ? Center(
                        child: Text('No hay jugadoras disponibles',
                          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: available.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (_, i) => _buildPlayerOption(available[i], index, ctx, colors),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerOption(Player p, int index, BuildContext ctx, ColorScheme colors) {
    return InkWell(
      onTap: () {
        setState(() => _selected[index] = p);
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${p.numero ?? "?"}',
                  style: const TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.w800),
                ),
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
            Icon(Icons.add_rounded, size: 20, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
