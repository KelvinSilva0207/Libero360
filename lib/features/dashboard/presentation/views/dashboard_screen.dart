import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/log_service.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/theme_provider/theme_notifier.dart';
import '../../../../core/widgets_globales/route_transitions.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../profiles/presentation/viewmodels/profile_viewmodel.dart';
import '../../../teams/presentation/viewmodels/club_viewmodel.dart';
import '../../../teams/data/team_models.dart' show ClubRole;
import '../../../asistencia/asistencia.dart';
import '../../../admin/presentation/views/admin_screen.dart';
import '../../../estadisticas/presentation/views/play_by_play_screen.dart';
import '../../../atleta/presentation/viewmodels/athlete_viewmodel.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../widgets/header_section.dart';
import '../widgets/main_card_section.dart';
import '../widgets/athlete_of_month_card.dart';
import '../widgets/quick_summary_grid.dart';
import '../widgets/team_status_section.dart';
import '../widgets/last_match_banner.dart';
import '../widgets/recent_activity_timeline.dart';
import '../widgets/quick_access_row.dart';
import '../widgets/dashboard_skeleton.dart';
import '../widgets/animated_section.dart';
import '../../../../core/utils/name_formatter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _initialized = false;
  bool _didLogReady = false;
  bool _didLogError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  void _load() {
    LogService.instance.auto('🔵 DASHBOARD SKELETON');
    final profileVm = context.read<ProfileViewModel>();
    final clubVm = context.read<ClubViewModel>();
    final athleteVm = context.read<AthleteViewModel>();
    final dashVm = context.read<DashboardViewModel>();
    dashVm.setCategoryFilter(athleteVm.selectedCategories);
    dashVm.load(
      profileId: profileVm.currentProfile?.id,
      clubName: clubVm.currentClub?.name,
      clubMemberCount: clubVm.memberCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    final vm = context.watch<DashboardViewModel>();
    final user = context.watch<AuthViewModel>().user;
    final profile = context.watch<ProfileViewModel>().currentProfile;
    final userName = NameFormatter.formatDisplayName(user?.nombre ?? 'Usuario');

    if (vm.data != null && !_didLogReady) {
      _didLogReady = true;
      LogService.instance.auto('🟢 DASHBOARD READY — ${vm.data!.quickSummary.athleteCount} atletas, ${vm.data!.quickSummary.matchCount} partidos');
    }
    if (vm.error != null && !_didLogError) {
      _didLogError = true;
      LogService.instance.error('🔴 DASHBOARD ERROR — ${vm.error}');
    }

    final bg = isDark ? AppColors.background : AppColors.lightBackground;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      body: SafeArea(
        child: vm.loading && vm.data == null
            ? DashboardSkeleton(isDark: isDark)
            : vm.error != null && vm.data == null
                ? _errorState(vm, isDark)
                : RefreshIndicator(
                    onRefresh: () => vm.refresh(profileId: profile?.id),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        _sectionBuilder(0, 'Header', HeaderSection(
                          userName: userName,
                          teamInfo: vm.data!.teamInfo,
                          isDark: isDark,
                          onSettings: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminScreen()),
                          ),
                          roleLabel: _roleLabel(context.read<ClubViewModel>().myRole),
                        )),
                        _sectionCardBuilder(1, 'MainCard', MainCardSection(
                          nextTraining: vm.data!.nextTraining,
                          nextMatch: vm.data!.nextMatch,
                          isDark: isDark,
                        )),
                        _sectionCardBuilder(2, 'AthleteOfMonth', AthleteOfMonthCard(
                          athlete: vm.data!.athleteOfMonth,
                          isDark: isDark,
                        )),
                        _sectionCardBuilder(3, 'QuickSummary', QuickSummaryGrid(
                          summary: vm.data!.quickSummary,
                          isDark: isDark,
                        )),
                        _sectionCardBuilder(4, 'TeamStatus', TeamStatusSection(
                          status: vm.data!.teamStatus,
                          isDark: isDark,
                        )),
                        _sectionCardBuilder(5, 'LastMatch', LastMatchBanner(
                          lastMatch: vm.data!.lastMatch,
                          isDark: isDark,
                        )),
                        _sectionBuilder(6, 'ActivityTimeline', RecentActivityTimeline(
                          activities: vm.data!.recentActivity,
                          isDark: isDark,
                        )),
                        _sectionCardBuilder(7, 'QuickAccess', QuickAccessRow(isDark: isDark)),
                        if (vm.data!.quickSummary.athleteCount == 0)
                          _sectionBuilder(8, 'EmptyRegister', _emptyState(isDark, 'registerAthlete')),
                        if (vm.data!.quickSummary.athleteCount > 0 &&
                            vm.data!.quickSummary.matchCount == 0)
                          _sectionBuilder(8, 'EmptyMatch', _emptyState(isDark, 'createMatch')),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 32),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _sectionBuilder(int index, String label, Widget child) {
    try {
      LogService.instance.auto('🔵 DASHBOARD RENDER — $label');
      return SliverToBoxAdapter(
        child: AnimatedSection(index: index, child: child),
      );
    } catch (e) {
      LogService.instance.error('🔴 DASHBOARD RENDER FALLÓ — $label — $e');
      return _errorFallback(label);
    }
  }

  Widget _sectionCardBuilder(int index, String label, Widget child) {
    try {
      LogService.instance.auto('🔵 DASHBOARD RENDER — $label');
      return SliverToBoxAdapter(
        child: AnimatedCard(child: AnimatedSection(index: index, child: child)),
      );
    } catch (e) {
      LogService.instance.error('🔴 DASHBOARD RENDER FALLÓ — $label — $e');
      return _errorFallback(label);
    }
  }

  Widget _errorFallback(String label) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Error en $label',
                    style: const TextStyle(color: Colors.orange, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _roleLabel(ClubRole? role) {
    return switch (role) {
      ClubRole.owner => 'Administrador',
      ClubRole.entrenador => 'Entrenador',
      ClubRole.asistente => 'Asistente',
      null => null,
    };
  }

  Widget _errorState(DashboardViewModel vm, bool isDark) {
    final textPri = isDark ? Colors.white : AppColors.textPrimary;
    final textSec = isDark ? AppColors.textSecondary : AppColors.textTertiary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48,
                color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary),
            const SizedBox(height: 16),
            Text('Error al cargar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPri)),
            const SizedBox(height: 8),
            Text(vm.error!, style: TextStyle(fontSize: 12, color: textSec),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(bool isDark, String type) {
    final textPri = isDark ? Colors.white : AppColors.textPrimary;
    final textSec = isDark ? AppColors.textSecondary : AppColors.textTertiary;
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final borderClr = isDark ? AppColors.border : AppColors.lightBorder;

    if (type == 'registerAthlete') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderClr),
          ),
          child: Column(
            children: [
              const Text('👥', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text('Aún no has registrado atletas',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPri)),
              const SizedBox(height: 4),
              Text('Comienza agregando tu primer atleta al equipo',
                  style: TextStyle(fontSize: 12, color: textSec)),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => context.pushSlide(const AthleteFormScreen()),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Registrar atleta'),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (type == 'createMatch') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderClr),
          ),
          child: Column(
            children: [
              const Text('🏐', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text('No hay partidos registrados',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPri)),
              const SizedBox(height: 4),
              Text('Crea tu primer partido para ver estadísticas',
                  style: TextStyle(fontSize: 12, color: textSec)),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => context.pushSlide(const PlayByPlayScreen()),
                icon: const Icon(Icons.sports_volleyball_rounded, size: 18),
                label: const Text('Crear partido'),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
