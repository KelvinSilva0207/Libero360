import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/theme_provider/theme_notifier.dart';
import '../widgets/settings_card.dart';

class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeNotifier>();
    final cs = Theme.of(context).colorScheme;
    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _themeOption(
            cs, theme,
            Icons.dark_mode_rounded, 'Oscuro',
            'Modo oscuro predeterminado',
            ThemeMode.dark, theme.isDark, true,
          ),
          const SizedBox(height: 4),
          Divider(color: cs.outlineVariant, height: 1),
          const SizedBox(height: 4),
          _themeOption(
            cs, theme,
            Icons.light_mode_rounded, 'Claro',
            'Fondo claro (próximamente)',
            ThemeMode.light, theme.isLight, false,
          ),
          const SizedBox(height: 4),
          Divider(color: cs.outlineVariant, height: 1),
          const SizedBox(height: 4),
          _themeOption(
            cs, theme,
            Icons.settings_brightness_rounded, 'Sistema',
            'Sigue la configuración del dispositivo (próximamente)',
            ThemeMode.system, theme.isSystem, false,
          ),
        ],
      ),
    );
  }

  Widget _themeOption(
    ColorScheme cs,
    ThemeNotifier theme,
    IconData icon,
    String label,
    String description,
    ThemeMode mode,
    bool selected,
    bool enabled,
  ) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: enabled ? () => theme.setMode(mode) : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.accent.withValues(alpha: 0.25)
                      : cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    color: selected ? AppColors.accent : AppColors.accent.withValues(alpha: 0.5),
                    size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(description,
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontSize: 11)),
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
