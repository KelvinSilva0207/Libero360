import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/local_db/database_service.dart';

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({super.key});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer>
    with SingleTickerProviderStateMixin {
  final Set<String> _expandedSections = {'general'};
  bool _rotacionAutomatica = true;

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
                      _buildTile(Icons.language_rounded, 'Idioma', 'Español', onTap: () => _showInfoDialog('Idioma', 'El idioma se detecta automáticamente según la configuración del dispositivo.')),
                      _buildTile(Icons.palette_rounded, 'Tema', 'Oscuro', onTap: () => _showInfoDialog('Tema', 'Solo modo oscuro disponible en esta versión.')),
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
                        _rotacionAutomatica,
                        (v) => setState(() => _rotacionAutomatica = v),
                      ),
                      _buildTile(Icons.timer_rounded, 'Duración de sets', '25 pts, ventaja 2', onTap: _showSetDurationDialog),
                    ],
                  ),
                  _buildSection(
                    'sincronizacion',
                    Icons.cloud_sync_rounded,
                    'Sincronización',
                    [
                      _buildTile(Icons.cloud_upload_rounded, 'Sincronizar dispositivos', 'No vinculado', onTap: () => _showInfoDialog('Sincronizar', 'La sincronización entre dispositivos estará disponible en una próxima actualización.\n\nPor ahora, puedes usar Exportar/Importar datos para transferir información.')),
                      _buildActionTile(Icons.file_download_rounded, 'Exportar datos', 'Respaldo JSON', _exportarDatos),
                      _buildActionTile(Icons.file_upload_rounded, 'Importar datos', 'Restaurar desde JSON', _importarDatos),
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

  Future<void> _exportarDatos() async {
    try {
      final db = DatabaseService.instance;
      await db.initialize();
      final json = await db.exportToJson();
      final dir = await getTemporaryDirectory();
      final date = DateTime.now().toIso8601String().split('T').first;
      final file = File('${dir.path}/libero360_backup_$date.json');
      await file.writeAsString(json);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Respaldo Libero360 - $date',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exportación completada'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importarDatos() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;

      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
              SizedBox(width: 8),
              Text('Importar datos', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: const Text(
            'Se reemplazarán TODOS los datos actuales.\n\n¿Estás seguro?',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Importar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      final file = File(result.files.single.path!);
      final json = await file.readAsString();
      final db = DatabaseService.instance;
      await db.initialize();
      final ok = await db.importFromJson(json);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Datos importados correctamente' : 'Error al importar'),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al importar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 22),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  void _showSetDurationDialog() {
    final ctrl = TextEditingController(text: '25');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.timer_rounded, color: AppColors.accent, size: 22),
            const SizedBox(width: 8),
            Text('Duración de sets', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Puntos para ganar un set:', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                filled: true,
                fillColor: AppColors.surfaceLight,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Ventaja mínima: 2 puntos', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Puntos por set: ${ctrl.text}'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Guardar', style: TextStyle(color: AppColors.accent)),
          ),
        ],
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

  Widget _buildTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
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
        onTap: onTap ?? () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Función no disponible en esta versión'), backgroundColor: AppColors.primary),
          );
        },
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
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
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
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
          value: value,
          activeColor: AppColors.accent,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
