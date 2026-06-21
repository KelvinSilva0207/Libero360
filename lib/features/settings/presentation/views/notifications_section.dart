import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../widgets/settings_card.dart';

class NotificationsSection extends StatelessWidget {
  const NotificationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final cs = Theme.of(context).colorScheme;
    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _switchTile(
            cs,
            Icons.notifications_active_rounded,
            'Notificaciones',
            'Activar o desactivar todas las notificaciones',
            vm.notificationsEnabled,
            vm.setNotificationsEnabled,
          ),
          const SizedBox(height: 4),
          Divider(color: cs.outlineVariant, height: 1),
          const SizedBox(height: 4),
          _switchTile(
            cs,
            Icons.notification_important_rounded,
            'Contador en icono',
            'Mostrar número de notificaciones no leídas',
            true,
            (_) {},
            enabled: false,
          ),
        ],
      ),
    );
  }

  Widget _switchTile(ColorScheme cs, IconData icon, String title,
      String subtitle, bool value, ValueChanged<bool> onChanged,
      {bool enabled = true}) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.6),
                          fontSize: 11)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}
