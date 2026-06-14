import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({super.key});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer>
    with SingleTickerProviderStateMixin {
  final Set<String> _expandedSections = {'general'};

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      width: min(320, MediaQuery.of(context).size.width * 0.85),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(color: AppColors.border, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildSection(
                    'general',
                    Icons.tune_rounded,
                    'General',
                    [
                      _buildTile(Icons.language_rounded, 'Idioma', 'Español'),
                      _buildTile(Icons.palette_rounded, 'Tema', 'Oscuro'),
                    ],
                  ),
                  _buildSection(
                    'partido',
                    Icons.sports_volleyball_rounded,
                    'Partido',
                    [
                      _buildSwitchTile(
                        Icons.sync_alt_rounded,
                        'Rotación automática',
                        true,
                      ),
                      _buildTile(Icons.timer_rounded, 'Duración de sets', '25 pts, ventaja 2'),
                    ],
                  ),
                  _buildSection(
                    'sincronizacion',
                    Icons.cloud_sync_rounded,
                    'Sincronización',
                    [
                      _buildTile(Icons.cloud_upload_rounded, 'Sincronizar dispositivos', 'No vinculado'),
                      _buildTile(Icons.file_download_rounded, 'Exportar datos', 'JSON / CSV'),
                    ],
                  ),
                  _buildSection(
                    'acerca',
                    Icons.info_outline_rounded,
                    'Acerca de',
                    [
                      _buildTile(Icons.info_rounded, 'Versión', '1.0.0'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Configuración',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String key, IconData icon, String title, List<Widget> children) {
    final isExpanded = _expandedSections.contains(key);
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedSections.remove(key);
              } else {
                _expandedSections.add(key);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more_rounded, color: AppColors.textSecondary, size: 20),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(children: children),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
        const Divider(color: AppColors.border, height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 18, color: AppColors.textSecondary),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 18),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Próximamente disponible'), backgroundColor: AppColors.primary),
          );
        },
      ),
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, bool initialValue) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 18, color: AppColors.textSecondary),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        trailing: Switch(
          value: initialValue,
          activeColor: AppColors.accent,
          onChanged: (v) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Próximamente disponible'), backgroundColor: AppColors.primary),
            );
          },
        ),
      ),
    );
  }
}
