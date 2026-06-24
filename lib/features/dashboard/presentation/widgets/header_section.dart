import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../profiles/presentation/widgets/profile_selector.dart';
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
    if (hour < 12) return 'Buenos días $userName 👋';
    if (hour < 19) return 'Buenas tardes $userName ☀️';
    return 'Buenas noches $userName 🌙';
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
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
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                const NotificationBell(),
                const SizedBox(width: 4),
                _iconButton(Icons.settings_rounded, onSettings),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isDark ? AppColors.surfaceLight : AppColors.lightBorder,
                  child: Icon(Icons.shield_rounded, size: 28,
                      color: isDark ? AppColors.textSecondary : AppColors.textTertiary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teamInfo.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${teamInfo.category} · ${teamInfo.ageGroup}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondary : AppColors.textTertiary,
                        ),
                      ),
                      if (teamInfo.memberCount > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${teamInfo.memberCount} entrenadores${roleLabel != null ? ' · $roleLabel' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const ProfileSelector(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceLight : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20,
            color: isDark ? AppColors.textSecondary : AppColors.textTertiary),
        onPressed: onTap,
      ),
    );
  }
}
