import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/theme_provider/theme_notifier.dart';
import '../../../../features/estadisticas/data/models/models.dart';
import '../../data/statistics_models.dart';
import '../viewmodels/athlete_list_viewmodel.dart';
import '../viewmodels/player_stats_viewmodel.dart';
import '../views/player_stats_screen.dart';

class AthletesTab extends StatefulWidget {
  const AthletesTab({super.key});

  @override
  State<AthletesTab> createState() => _AthletesTabState();
}

class _AthletesTabState extends State<AthletesTab> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AthleteListViewModel>().load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    final viewModel = context.watch<AthleteListViewModel>();

    return Column(
      children: [
        _SearchBar(
          controller: _searchCtrl,
          isDark: isDark,
          onChanged: (q) => viewModel.search(q),
        ),
        Expanded(child: _buildBody(viewModel, isDark)),
      ],
    );
  }

  Widget _buildBody(AthleteListViewModel vm, bool isDark) {
    if (vm.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (vm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(vm.error!, textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 14)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.read<AthleteListViewModel>().load(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (vm.athletes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(vm.query.isEmpty ? 'No hay atletas registrados' : 'Sin resultados para "${vm.query}"',
                style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AthleteListViewModel>().load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        itemCount: vm.athletes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final athlete = vm.athletes[index];
          return _AthleteCard(
            athlete: athlete,
            isDark: isDark,
            onTap: () => _openPlayerStats(context, athlete.player),
          );
        },
      ),
    );
  }

  void _openPlayerStats(BuildContext context, Player player) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider(
        create: (_) => PlayerStatsViewModel()..load(player),
        child: PlayerStatsScreen(player: player),
      ),
    ));
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, apellido, #, cédula, categoría...',
          hintStyle: TextStyle(color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? AppColors.surface : AppColors.lightCard,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: isDark ? AppColors.border : AppColors.lightBorder, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: isDark ? AppColors.border : AppColors.lightBorder, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 1),
          ),
        ),
      ),
    );
  }
}

class _AthleteCard extends StatelessWidget {
  final AthleteStats athlete;
  final bool isDark;
  final VoidCallback onTap;

  const _AthleteCard({required this.athlete, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = athlete.player;
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final border = isDark ? AppColors.border : AppColors.lightBorder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 0.5),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                backgroundImage: p.fotoUrl != null ? NetworkImage(p.fotoUrl!) : null,
                child: p.fotoUrl == null
                    ? Text(
                        p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.accent, fontSize: 22, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.nombre,
                            style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (p.numero != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('#${p.numero}', style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(p.posicionLabel, style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 12)),
                        const SizedBox(width: 12),
                        Text(p.atletaStatus.label, style: TextStyle(color: p.atletaStatus.color, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Eficiencia: ${athlete.eficiencia.toStringAsFixed(0)}%',
                        style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
