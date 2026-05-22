import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/models.dart';

class ActionButtonConfig {
  final String label;
  final IconData icon;
  final Color color;
  final TipoAccion tipo;
  final bool positivo;

  const ActionButtonConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.tipo,
    required this.positivo,
  });
}

class ActionButtonsWidget extends StatelessWidget {
  final bool canAct;
  final bool hasSelection;
  final ValueChanged<TipoAccion> onPositiva;
  final ValueChanged<TipoAccion> onNegativa;
  final VoidCallback onErrorContrario;

  static const buttons = [
    ActionButtonConfig(
      label: 'ATAQUE',
      icon: Icons.sports_volleyball,
      color: AppColors.accent,
      tipo: TipoAccion.ataque,
      positivo: true,
    ),
    ActionButtonConfig(
      label: 'SAQUE',
      icon: Icons.dry_cleaning,
      color: AppColors.primary,
      tipo: TipoAccion.saque,
      positivo: true,
    ),
    ActionButtonConfig(
      label: 'BLOQUEO',
      icon: Icons.pan_tool,
      color: AppColors.success,
      tipo: TipoAccion.bloqueo,
      positivo: true,
    ),
  ];

  static const negButtons = [
    ActionButtonConfig(
      label: 'ATAQUE -',
      icon: Icons.sports_volleyball,
      color: AppColors.error,
      tipo: TipoAccion.ataque,
      positivo: false,
    ),
    ActionButtonConfig(
      label: 'SAQUE -',
      icon: Icons.dry_cleaning,
      color: AppColors.error,
      tipo: TipoAccion.saque,
      positivo: false,
    ),
    ActionButtonConfig(
      label: 'BLOQUEO -',
      icon: Icons.pan_tool,
      color: AppColors.error,
      tipo: TipoAccion.bloqueo,
      positivo: false,
    ),
  ];

  const ActionButtonsWidget({
    super.key,
    required this.canAct,
    required this.hasSelection,
    required this.onPositiva,
    required this.onNegativa,
    required this.onErrorContrario,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hasSelection)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app, color: Color(0xFFFF8C00), size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Selecciona un jugador en la cancha',
                      style: TextStyle(color: Color(0xFFFF8C00), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ...buttons.map((b) => _buildActionButton(b, context)),
        const SizedBox(height: 8),
        Container(height: 1, color: Colors.white12),
        const SizedBox(height: 8),
        ...negButtons.map((b) => _buildActionButton(b, context)),
        const SizedBox(height: 8),
        _buildErrorButton(),
      ],
    );
  }

  Widget _buildActionButton(ActionButtonConfig config, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ElevatedButton.icon(
        onPressed: canAct && hasSelection
            ? () {
                if (config.positivo) {
                  onPositiva(config.tipo);
                } else {
                  onNegativa(config.tipo);
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: config.color.withOpacity(0.85),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade800,
          disabledForegroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: hasSelection ? 4 : 0,
        ),
        icon: Icon(config.icon, size: 18),
        label: Text(
          config.label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildErrorButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ElevatedButton.icon(
        onPressed: canAct ? onErrorContrario : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.withOpacity(0.7),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade800,
          disabledForegroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.error_outline, size: 18),
        label: const Text(
          'ERROR CONTRARIO',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
