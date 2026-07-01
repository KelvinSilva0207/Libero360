import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/category_calculator.dart';
import '../../../estadisticas/data/models/models.dart';
import '../viewmodels/athlete_viewmodel.dart';
import '../../../../core/utils/name_formatter.dart';

class AthleteTrashScreen extends StatefulWidget {
  const AthleteTrashScreen({super.key});

  @override
  State<AthleteTrashScreen> createState() => _AthleteTrashScreenState();
}

class _AthleteTrashScreenState extends State<AthleteTrashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AthleteViewModel>().loadTrashed();
    });
  }

  Future<void> _restore(Player p) async {
    final vm = context.read<AthleteViewModel>();
    final ok = await vm.restore(p.id);
    if (mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Atleta restaurado'), backgroundColor: Color(0xFF22C55E)),
      );
    }
  }

  Future<void> _permanentDelete(Player p) async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerHighest,
        title: Text('Eliminar permanentemente', style: TextStyle(color: cs.onSurface)),
        content: Text('Esta acción no podrá deshacerse.',
          style: TextStyle(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar definitivamente'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final vm = context.read<AthleteViewModel>();
    final ok = await vm.permanentDelete(p.id);
    if (mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Atleta eliminado permanentemente'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: Text('Papelera', style: TextStyle(color: cs.onSurface, fontSize: 16)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AthleteViewModel>(
        builder: (_, vm, __) {
          if (vm.trashed.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_sweep_outlined, color: cs.onSurface.withValues(alpha: 0.38), size: 48),
                  const SizedBox(height: 12),
                  Text('Papelera vacía', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Los atletas eliminados aparecerán aquí',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: vm.trashed.length,
            itemBuilder: (context, index) {
              final p = vm.trashed[index];
              final cat = CategoryCalculator.calculate(p.edad);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: p.fotoUrl != null && File(p.fotoUrl!).existsSync()
                            ? Image.file(File(p.fotoUrl!), width: 48, height: 48, fit: BoxFit.cover)
                            : Container(
                                width: 48, height: 48,
                                color: Colors.red.withValues(alpha: 0.15),
                                child: const Icon(Icons.person_off_rounded, color: Colors.red, size: 24),
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(NameFormatter.playerDisplayName(p),
                              style: TextStyle(color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('#${p.numero ?? '-'}',
                                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(cat,
                                    style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            if (p.deletedAt != null) ...[
                              const SizedBox(height: 4),
                              Text('Eliminado: ${_formatDate(p.deletedAt!)}',
                                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 11)),
                            ],
                            if (p.deletionReason != null && p.deletionReason!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Motivo: ${p.deletionReason}',
                                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38), fontSize: 11)),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.restore_rounded, color: Color(0xFF22C55E), size: 22),
                            onPressed: () => _restore(p),
                            tooltip: 'Restaurar',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 22),
                            onPressed: () => _permanentDelete(p),
                            tooltip: 'Eliminar permanentemente',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
