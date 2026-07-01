import 'package:flutter/material.dart';
import '../../../../core/services/log_service.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../profiles/presentation/widgets/compact_profile_selector.dart';
import '../../../notifications/presentation/views/notification_bell.dart';
import '../../data/dashboard_model.dart';

class HeaderSection extends StatelessWidget {
  final String userName;
  final TeamInfo teamInfo;
  final bool isDark;
  final VoidCallback onSettings;
  final String? roleLabel;

  const HeaderSection({
    super.key,
    required this.userName,
    required this.teamInfo,
    required this.isDark,
    required this.onSettings,
    this.roleLabel,
  });

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días 👋';
    if (hour < 19) return 'Buenas tardes ☀️';
    return 'Buenas noches 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    LogService.instance.auto('🟢 HeaderSection — construyendo (dark=$isDark, team=${teamInfo.name})', source: 'HeaderSection');
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        LogService.instance.auto('🔵 HeaderSection — isMobile=$isMobile, maxWidth=${constraints.maxWidth}', source: 'HeaderSection');
        final textPri = isDark ? cs.onSurface : AppColors.textPrimary;
        final textSec = isDark ? AppColors.textSecondary : AppColors.textTertiary;

        return Padding(
          padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, isMobile ? 8 : 12, isMobile ? 16 : 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile) _buildMobileHeader(textPri, textSec)
              else _buildTabletDesktopHeader(textPri, textSec),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileHeader(Color textPri, Color textSec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _greeting(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPri,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          userName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textSec,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
              child: Icon(Icons.shield_rounded, size: 22,
                  color: AppColors.primary.withValues(alpha: 0.7)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teamInfo.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPri,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${teamInfo.category} · ${teamInfo.ageGroup}',
                    style: TextStyle(fontSize: 12, color: textSec),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const CompactProfileSelector(),
            const SizedBox(width: 2),
            const NotificationBell(),
            const SizedBox(width: 2),
            _iconButton(Icons.settings_rounded, onSettings),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletDesktopHeader(Color textPri, Color textSec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _greeting(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textPri,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const CompactProfileSelector(),
            const SizedBox(width: 4),
            const NotificationBell(),
            const SizedBox(width: 4),
            _iconButton(Icons.settings_rounded, onSettings),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          userName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textSec,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
              child: Icon(Icons.shield_rounded, size: 26,
                  color: AppColors.primary.withValues(alpha: 0.7)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teamInfo.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPri,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${teamInfo.category} · ${teamInfo.ageGroup}${teamInfo.memberCount > 0 ? ' · ${teamInfo.memberCount} miembros${roleLabel != null ? ' · $roleLabel' : ''}' : ''}',
                    style: TextStyle(fontSize: 12, color: textSec),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceLight : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(icon, size: 20,
              color: isDark ? AppColors.textSecondary : AppColors.textTertiary),
          onPressed: onTap,
          hoverColor: AppColors.primary.withValues(alpha: 0.1),
          splashRadius: 20,
        ),
      ),
    );
  }
}
