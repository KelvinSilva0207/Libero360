import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/court_state.dart';
import 'court_widget.dart';

class SetStartDialog extends StatefulWidget {
  final int setNumber;
  final bool hasPreviousSet;

  const SetStartDialog({
    super.key,
    required this.setNumber,
    this.hasPreviousSet = false,
  });

  @override
  State<SetStartDialog> createState() => _SetStartDialogState();
}

class _SetStartDialogState extends State<SetStartDialog> {
  bool _usePrevious = true;
  late CourtState _courtState;

  @override
  void initState() {
    super.initState();
    _courtState = CourtState.empty();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set ${widget.setNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Configurar rotación inicial',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              if (widget.hasPreviousSet) _buildPreviousToggle(),
              if (!_usePrevious || !widget.hasPreviousSet) _buildPositionGrid(),
              const SizedBox(height: 20),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviousToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Usar rotación anterior?',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ToggleOption(
                label: 'Sí',
                selected: _usePrevious,
                onTap: () => setState(() => _usePrevious = true),
              ),
              const SizedBox(width: 12),
              _ToggleOption(
                label: 'No',
                selected: !_usePrevious,
                onTap: () => setState(() => _usePrevious = false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPositionGrid() {
    return Column(
      children: [
        const Text(
          'Asignar jugadores a posiciones',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: CourtWidget(
            state: _courtState,
            onZoneTap: (zoneNumber) => _showPlayerPicker(zoneNumber),
          ),
        ),
      ],
    );
  }

  void _showPlayerPicker(int zoneNumber) {
    showDialog(
      context: context,
      builder: (ctx) => _PlayerNumberPicker(
        onSelected: (number) {
          setState(() {
            _courtState = _courtState.withZone(
              zoneNumber,
              _courtState.zone(zoneNumber).copyWith(athleteNumber: number),
            );
          });
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (_usePrevious && widget.hasPreviousSet) {
                Navigator.of(context).pop({'usePrevious': true});
              } else {
                final slots = List<int?>.generate(6, (i) {
                  final zoneNum = i + 1;
                  return _courtState.zone(zoneNum).athleteNumber;
                });
                Navigator.of(context).pop({
                  'usePrevious': false,
                  'slots': slots,
                });
              }
            },
            child: const Text('Comenzar Set'),
          ),
        ),
      ],
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.3) : Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.accent : Colors.white54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _PlayerNumberPicker extends StatelessWidget {
  final ValueChanged<int> onSelected;

  const _PlayerNumberPicker({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Número de jugador',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(20, (i) {
                final num = i + 1;
                return GestureDetector(
                  onTap: () => onSelected(num),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.3),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Center(
                      child: Text(
                        '$num',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
