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
import '../../../asistencia/presentation/views/athlete_list_screen.dart' as asis_athlete;
import '../../../estadisticas/presentation/views/play_by_play_screen.dart';
import '../../../admin/presentation/views/admin_screen.dart';
import '../../../atleta/presentation/viewmodels/athlete_viewmodel.dart';
import '../../../atleta/presentation/views/athlete_list_screen.dart' as atleta_athlete;
import '../../../atleta/presentation/views/athlete_detail_screen.dart';
import '../../../asistencia/presentation/views/attendance_analytics_screen.dart';
import '../../../asistencia/presentation/views/attendance_screen.dart';
import '../../../statistics/presentation/views/statistics_screen.dart';
import '../../../partido/presentation/views/match_list_screen.dart';
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
      category: profileVm.currentProfile?.category,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    final bg = isDark ? AppColors.background : AppColors.lightBackground;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _buildBody(isDark),
            ),
            _buildRefreshingIndicator(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    final vm = context.watch<DashboardViewModel>();
    if (vm.loading && vm.data == null) {
      return DashboardSkeleton(isDark: isDark, key: const ValueKey('skeleton'));
    }
    if (vm.error != null && vm.data == null) {
      return _errorState(isDark, key: const ValueKey('error'));
    }
    return _buildDashboard(isDark, key: const ValueKey('dashboard'));
  }

  Widget _buildDashboard(bool isDark, {Key? key}) {
    return RefreshIndicator(
      onRefresh: () => context.read<DashboardViewModel>().refresh(
        profileId: context.read<ProfileViewModel>().currentProfile?.id,
      ),
      child: CustomScrollView(
        key: key,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeaderSection(isDark),
          _buildMainCardSection(isDark),
          _buildAthleteOfMonthSection(isDark),
          _buildQuickSummarySection(isDark),
          _buildTeamStatusSection(isDark),
          _buildLastMatchSection(isDark),
          _buildActivityTimelineSection(isDark),
          _buildQuickAccessSection(isDark),
          _buildEmptyStates(isDark),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildRefreshingIndicator(bool isDark) {
    return ValueListenableBuilder<int>(
      valueListenable: context.read<DashboardViewModel>().skeletonSection,
      builder: (_, __, ___) {
        final refreshing = context.read<DashboardViewModel>().isRefreshing;
        if (!refreshing) return const SizedBox.shrink();
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Actualizando...',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(bool isDark) {
    return ValueListenableBuilder<int>(
      valueListenable: context.read<DashboardViewModel>().headerSection,
      builder: (_, __, ___) {
        final vm = context.read<DashboardViewModel>();
        final data = vm.data;
        if (data == null) return const SizedBox.shrink();
        final user = context.read<AuthViewModel>().user;
        final userName = NameFormatter.formatDisplayName(user?.nombre ?? 'Usuario');
        LogService.instance.auto('🔵 sección reconstruida — Header');
        return SliverToBoxAdapter(
          child: AnimatedSection(
            index: 0,
            child: HeaderSection(
              userName: userName,
              teamInfo: data.teamInfo,
              isDark: isDark,
              onSettings: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminScreen()),
              ),
              roleLabel: _roleLabel(context.read<ClubViewModel>().myRole),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainCardSection(bool isDark) {
    return ValueListenableBuilder<int>(
      valueListenable: context.read<DashboardViewModel>().mainCardSection,
      builder: (_, __, ___) {
        final data = context.read<DashboardViewModel>().data;
        if (data == null) return const SizedBox.shrink();
        LogService.instance.auto('🔵 sección reconstruida — MainCard');
        return SliverToBoxAdapter(
          child: AnimatedSection(
            index: 1,
            child: AnimatedCard(
              child: MainCardSection(
                nextTraining: data.nextTraining,
                nextMatch: data.nextMatch,
                isDark: isDark,
                onTrainingTap: () => context.pushSlide(const AttendanceScreen()),
                onMatchTap: () => context.pushSlide(const MatchListScreen()),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAthleteOfMonthSection(bool isDark) {
    return ValueListenableBuilder<int>(
      valueListenable: context.read<DashboardViewModel>().athleteOfMonthSection,
      builder: (_, __, ___) {
        final data = context.read<DashboardViewModel>().data;
        if (data == null) return const SizedBox.shrink();
        LogService.instance.auto('🔵 sección reconstruida — AthleteOfMonth');
        return SliverToBoxAdapter(
          child: AnimatedSection(
            index: 2,
            child: AnimatedCard(
              child: AthleteOfMonthCard(
                athlete: data.athleteOfMonth,
                isDark: isDark,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickSummarySection(bool isDark) {
    return ValueListenableBuilder<int>(
      valueListenable: context.read<DashboardViewModel>().quickSummarySection,
      builder: (_, __, ___) {
        final data = context.read<DashboardViewModel>().data;
        if (data == null) return const SizedBox.shrink();
        LogService.instance.auto('🔵 sección reconstruida — QuickSummary');
        return SliverToBoxAdapter(
          child: AnimatedSection(
            index: 3,
            child: AnimatedCard(
              child: QuickSummaryGrid(
                summary: data.quickSummary,
                isDark: isDark,
                onAthleteTap: () => context.pushSlide(const atleta_athlete.AthleteListScreen()),
                onMatchTap: () => context.pushSlide(const MatchListScreen()),
                onWinRateTap: () => context.pushSlide(const StatisticsScreen()),
                onTrainingTap: () => context.pushSlide(const AttendanceScreen()),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamStatusSection(bool isDark) {
    return ValueListenableBuilder<int>(
      valueListenable: context.read<DashboardViewModel>().teamStatusSection,
      builder: (_, __, ___) {
        final data = context.read<DashboardViewModel>().data;
        if (data == null) return const SizedBox.shrink();
        LogService.instance.auto('🔵 sección reconstruida — TeamStatus');
        return SliverToBoxAdapter(
          child: AnimatedSection(
            index: 4,
            child: AnimatedCard(
              child: TeamStatusSection(
                status: data.teamStatus,
                isDark: isDark,
                onMedicalTap: () => context.pushSlide(const asis_athlete.AthleteListScreen()),
                onAbsenceTap: () => context.pushSlide(const AttendanceAnalyticsScreen()),
                onStreakTap: () => context.pushSlide(const MatchListScreen()),
                onMvpTap: () {
                  final player = data.mvpPlayer;
                  if (player != null) {
                    context.pushSlide(AthleteDetailScreen(player: player));
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLastMatchSection(bool isDark) {
    return ValueListenableBuilder<int>(
      valueListenable: context.read<DashboardViewModel>().lastMatchSection,
      builder: (_, __, ___) {
        final data = context.read<DashboardViewModel>().data;
        if (data == null) return const SizedBox.shrink();
        LogService.instance.auto('🔵 sección reconstruida — LastMatch');
        return SliverToBoxAdapter(
          child: AnimatedSection(
            index: 5,
            child: AnimatedCard(
              child: LastMatchBanner(
                lastMatch: data.lastMatch,
                isDark: isDark,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityTimelineSection(bool isDark) {
    return ValueListenableBuilder<int>(
      valueListenable: context.read<DashboardViewModel>().activityTimelineSection,
      builder: (_, __, ___) {
        final data = context.read<DashboardViewModel>().data;
        if (data == null) return const SizedBox.shrink();
        LogService.instance.auto('🔵 sección reconstruida — ActivityTimeline');
        return SliverToBoxAdapter(
          child: AnimatedSection(
            index: 6,
            child: RecentActivityTimeline(
              activities: data.recentActivity,
              isDark: isDark,
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAccessSection(bool isDark) {
    return ValueListenableBuilder<int>(
      valueListenable: context.read<DashboardViewModel>().quickAccessSection,
      builder: (_, __, ___) {
        LogService.instance.auto('🔵 sección reconstruida — QuickAccess');
        return SliverToBoxAdapter(
          child: AnimatedSection(
            index: 7,
            child: QuickAccessRow(isDark: isDark),
          ),
        );
      },
    );
  }

  Widget _buildEmptyStates(bool isDark) {
    final vm = context.read<DashboardViewModel>();
    final data = vm.data;
    if (data == null) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Column(
        children: [
          if (data.quickSummary.athleteCount == 0)
            _emptyCard(isDark, 'registerAthlete'),
          if (data.quickSummary.athleteCount > 0 && data.quickSummary.matchCount == 0)
            _emptyCard(isDark, 'createMatch'),
        ],
      ),
    );
  }

  Widget _emptyCard(bool isDark, String type) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : AppColors.lightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.border : AppColors.lightBorder),
        ),
        child: Column(
          children: [
            Text(type == 'registerAthlete' ? '👥' : '🏐', style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              type == 'registerAthlete' ? 'Aún no has registrado atletas' : 'No hay partidos registrados',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              type == 'registerAthlete' ? 'Comienza agregando tu primer atleta al equipo' : 'Crea tu primer partido para ver estadísticas',
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: type == 'registerAthlete'
                  ? () => context.pushSlide(const asis_athlete.AthleteListScreen())
                  : () => context.pushSlide(const PlayByPlayScreen()),
              icon: Icon(type == 'registerAthlete' ? Icons.person_add_rounded : Icons.sports_volleyball_rounded, size: 18),
              label: Text(type == 'registerAthlete' ? 'Registrar atleta' : 'Crear partido'),
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

  String? _roleLabel(ClubRole? role) {
    return switch (role) {
      ClubRole.owner => 'Administrador',
      ClubRole.entrenador => 'Entrenador',
      ClubRole.asistente => 'Asistente',
      null => null,
    };
  }

  Widget _errorState(bool isDark, {Key? key}) {
    final vm = context.read<DashboardViewModel>();
    final textPri = isDark ? Colors.white : AppColors.textPrimary;
    final textSec = isDark ? AppColors.textSecondary : AppColors.textTertiary;
    return Center(
      key: key,
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
            Text(vm.error ?? '', style: TextStyle(fontSize: 12, color: textSec),
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
}
