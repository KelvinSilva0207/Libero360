import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/models.dart';
import '../viewmodels/athlete_viewmodel.dart';

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Eliminar permanentemente', style: TextStyle(color: Colors.white)),
        content: const Text('Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Papelera', style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AthleteViewModel>(
        builder: (_, vm, __) {
          if (vm.trashed.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_sweep_outlined, color: Colors.white24, size: 48),
                  SizedBox(height: 12),
                  Text('Papelera vacía', style: TextStyle(color: Colors.white38, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Los atletas eliminados aparecerán aquí',
                    style: TextStyle(color: Colors.white24, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: vm.trashed.length,
            itemBuilder: (context, index) {
              final p = vm.trashed[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(Icons.person_off_rounded, color: Colors.red, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.displayName,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('#${p.numero ?? '-'} · ${p.posicionLabel}',
                              style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            if (p.deletedAt != null) ...[
                              const SizedBox(height: 2),
                              Text('Eliminado: ${_formatDate(p.deletedAt!)}',
                                style: const TextStyle(color: Colors.white24, fontSize: 11)),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.restore_rounded, color: Color(0xFF22C55E), size: 20),
                        onPressed: () => _restore(p),
                        tooltip: 'Restaurar',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20),
                        onPressed: () => _permanentDelete(p),
                        tooltip: 'Eliminar permanentemente',
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
