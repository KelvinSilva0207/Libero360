import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../features/estadisticas/data/local_db/database_service.dart';
import '../../../../features/profiles/profiles.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../widgets/settings_card.dart';

class DatabaseSection extends StatelessWidget {
  const DatabaseSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        SettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _actionTile(
                cs,
                Icons.file_download_rounded,
                'Exportar datos',
                'Respaldo en formato JSON',
                vm.isExporting ? null : () => _exportData(context, vm),
                trailing: vm.isExporting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.primary),
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              Divider(color: cs.outlineVariant, height: 1),
              const SizedBox(height: 4),
              _actionTile(
                cs,
                Icons.file_upload_rounded,
                'Importar datos',
                'Restaurar desde archivo JSON',
                vm.isImporting ? null : () => _importData(context, vm),
                trailing: vm.isImporting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.primary),
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              Divider(color: cs.outlineVariant, height: 1),
              const SizedBox(height: 4),
              _actionTile(
                cs,
                Icons.restore_rounded,
                'Restaurar copia',
                'Recuperar datos desde un respaldo previo',
                vm.isImporting ? null : () => _importData(context, vm),
              ),
            ],
          ),
        ),
        const _OrphanCard(),
      ],
    );
  }

  Future<void> _exportData(BuildContext context, SettingsViewModel vm) async {
    try {
      await vm.exportDatabase();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Exportación completada'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al exportar: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, SettingsViewModel vm) async {
    final cs = Theme.of(context).colorScheme;
    if (!context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerHighest,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
            const SizedBox(width: 8),
            Text('Importar datos',
                style: TextStyle(
                    color: cs.onSurface, fontSize: 16)),
          ],
        ),
        content: Text(
          'Se reemplazarán TODOS los datos actuales.\n\n¿Estás seguro?',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Importar',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await vm.importDatabase();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Datos restaurados correctamente'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al importar: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  ColorScheme cs(BuildContext context) => Theme.of(context).colorScheme;

  Widget _actionTile(
    ColorScheme cs,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap, {
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
            if (trailing != null)
              trailing
            else
              Icon(Icons.chevron_right,
                  color: cs.onSurface.withValues(alpha: 0.4), size: 18),
          ],
        ),
      ),
    );
  }
}

class _OrphanCard extends StatefulWidget {
  const _OrphanCard();

  @override
  State<_OrphanCard> createState() => _OrphanCardState();
}

class _OrphanCardState extends State<_OrphanCard> {
  Map<String, int>? _counts;
  bool _loading = false;
  bool _assigning = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _counts = await DatabaseService.instance.countOrphanRecords();
    } catch (_) {
      _counts = {};
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _assignAll() async {
    final cs = Theme.of(context).colorScheme;
    final profileVm = context.read<ProfileViewModel>();
    final profile = profileVm.currentProfile;
    if (profile == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surfaceContainerHighest,
        title: const Text('Asignar datos',
            style: TextStyle(fontSize: 16)),
        content: Text(
          'Todos los datos sin perfil serán asignados al perfil activo.\n\n¿Continuar?',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Asignar',
                style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _assigning = true);
    try {
      await DatabaseService.instance.assignOrphansToProfile(
        profile.id,
        profile.clubId,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Datos asignados correctamente'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _assigning = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entries = _counts ?? {};
    final total = entries.values.fold(0, (s, v) => s + v);

    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_off_rounded,
                    color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: 12),
              Text('Datos sin perfil',
                  style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else ...[
            _row(cs, 'Atletas', entries['players'] ?? 0),
            _row(cs, 'Partidos', entries['matches'] ?? 0),
            _row(cs, 'Eventos', entries['events'] ?? 0),
            _row(cs, 'Asistencias', entries['attendance'] ?? 0),
            _row(cs, 'Eventos de partido', entries['matchEvents'] ?? 0),
            const Divider(height: 16),
            _row(cs, 'Total', total, bold: true),
            if (total > 0 && context.read<ProfileViewModel>().hasProfiles) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _assigning ? null : _assignAll,
                  icon: _assigning
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: cs.onPrimary),
                        )
                      : const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Asignar todos al perfil activo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _row(ColorScheme cs, String label, int count, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
          ),
          Text(count.toString(),
              style: TextStyle(
                  color: count > 0 ? AppColors.accent : cs.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
