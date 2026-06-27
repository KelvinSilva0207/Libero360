import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/widgets_globales/route_transitions.dart';
import '../../../estadisticas/data/models/models.dart';
import '../viewmodels/athlete_viewmodel.dart';
import 'athlete_form_screen.dart';
import 'athlete_detail_screen.dart';
import 'athlete_trash_screen.dart';
import 'category_manager_screen.dart';
import '../../../../core/utils/name_formatter.dart';

class AthleteListScreen extends StatefulWidget {
  const AthleteListScreen({super.key});

  @override
  State<AthleteListScreen> createState() => _AthleteListScreenState();
}

class _AthleteListScreenState extends State<AthleteListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AthleteViewModel>().load();
    });
  }

  Future<void> _addAthlete() async {
    final result = await context.pushSlide<bool>(const AthleteFormScreen());
    if (result == true && mounted) {
      context.read<AthleteViewModel>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Consumer<AthleteViewModel>(
          builder: (_, vm, __) => Row(
            children: [
              const Text('Atletas', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              if (!vm.loading && vm.athletes.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${vm.athletes.length}',
                    style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          Consumer<AthleteViewModel>(
            builder: (_, vm, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (vm.trashed.isNotEmpty)
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white54),
                        onPressed: () => context.pushSlide(const AthleteTrashScreen()),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text(
                            '${vm.trashed.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                IconButton(
                  icon: Icon(Icons.search, color: vm.query.isNotEmpty ? AppColors.accent : Colors.white54),
                  onPressed: () => _showSearchDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<AthleteViewModel>(
        builder: (_, vm, __) {
          if (vm.loading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          if (vm.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(vm.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => vm.load(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                  ),
                ],
              ),
            );
          }
          if (vm.athletes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people_outline, color: Colors.white24, size: 48),
                  ),
                  const SizedBox(height: 20),
                  const Text('Aún no hay atletas', style: TextStyle(color: Colors.white54, fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text('Agrega tu primer atleta', style: TextStyle(color: Colors.white38, fontSize: 13)),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _addAthlete,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Atleta'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }
          final filtered = vm.filtered;
          return Column(
            children: [
              _buildCategoryChips(vm),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () => vm.load(),
                  child: filtered.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.2,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.search_off_rounded, color: Colors.white24, size: 40),
                                    const SizedBox(height: 8),
                                    const Text('Sin resultados', style: TextStyle(color: Colors.white38, fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _athleteCard(filtered[index]),
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAthlete,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryChips(AthleteViewModel vm) {
    final categories = vm.allCategoryNames;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('Todos', style: TextStyle(fontSize: 12, color: !vm.hasActiveFilter ? Colors.white : Colors.white54)),
              selected: !vm.hasActiveFilter,
              selectedColor: AppColors.accent.withValues(alpha: 0.3),
              backgroundColor: AppColors.surface,
              side: BorderSide.none,
              onSelected: (_) {
                vm.setQuery('');
                vm.setFilterPosicion(null);
                vm.clearCategoryFilter();
              },
            ),
          ),
          ...categories.map((cat) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat, style: TextStyle(fontSize: 12, color: vm.selectedCategories.contains(cat) ? Colors.white : Colors.white54)),
              selected: vm.selectedCategories.contains(cat),
              selectedColor: AppColors.accent.withValues(alpha: 0.3),
              backgroundColor: AppColors.surface,
              side: BorderSide.none,
              onSelected: (_) => vm.toggleCategory(cat),
            ),
          )),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ActionChip(
              avatar: const Icon(Icons.tune, color: Colors.white38, size: 16),
              label: const Text('Gestionar', style: TextStyle(color: Colors.white38, fontSize: 11)),
              backgroundColor: AppColors.surface,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              onPressed: () => context.pushSlide(const CategoryManagerScreen()),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final vm = context.read<AthleteViewModel>();
    showSearch(context: context, delegate: _AthleteSearchDelegate(vm));
  }

  Color _saludColor(EstadoSalud e) {
    switch (e) {
      case EstadoSalud.disponible: return const Color(0xFF22C55E);
      case EstadoSalud.lesionado: return const Color(0xFFEF4444);
      case EstadoSalud.enDuda: return const Color(0xFFF59E0B);
    }
  }

  Widget _athleteCard(Player p) {
    final healthColor = _saludColor(p.estadoSalud);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.pushSlide(AthleteDetailScreen(player: p)),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'player-${p.id}',
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: p.esCapitan
                          ? const LinearGradient(colors: [AppColors.accent, Color(0xFFFFA940)])
                          : LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.8),
                                AppColors.primary,
                              ],
                            ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${p.numero ?? '-'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              NameFormatter.playerDisplayName(p),
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (p.esCapitan) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.star, color: AppColors.accent, size: 15),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p.posicionLabel,
                              style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p.categoria,
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${p.edad} años',
                            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                          ),
                          if (p.cedula.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              p.cedula,
                              style: const TextStyle(color: AppColors.textTertiary, fontSize: 10),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: healthColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: healthColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p.estadoSaludLabel,
                        style: TextStyle(color: healthColor, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AthleteSearchDelegate extends SearchDelegate<void> {
  final AthleteViewModel vm;
  _AthleteSearchDelegate(this.vm);

  @override
  String get searchFieldLabel => 'Buscar por nombre, número o cédula...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white38),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white54),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final lower = query.toLowerCase().trim();
    final results = lower.isEmpty
        ? vm.athletes
        : vm.athletes.where((p) =>
            NameFormatter.playerDisplayName(p).toLowerCase().contains(lower) ||
            (p.numero?.toString() ?? '').contains(lower) ||
            p.cedula.replaceAll('.', '').contains(lower)
          ).toList();

    if (results.isEmpty) {
      return const Center(
        child: Text('Sin resultados', style: TextStyle(color: Colors.white38, fontSize: 14)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final p = results[index];
        return ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('${p.numero ?? '-'}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          title: Text(NameFormatter.playerDisplayName(p), style: const TextStyle(color: Colors.white, fontSize: 14)),
          subtitle: Text('${p.posicionLabel} · ${p.categoria}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
          onTap: () {
            close(context, null);
            context.pushSlide(AthleteDetailScreen(player: p));
          },
        );
      },
    );
  }
}
