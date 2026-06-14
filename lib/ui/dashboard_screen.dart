import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../core/themes/app_colors.dart';
import '../core/widgets_globales/route_transitions.dart';
import '../features/estadisticas/data/models/models.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../features/partido/presentation/views/match_start_dialog.dart';
import '../features/asistencia/presentation/views/athlete_list_screen.dart';
import '../features/asistencia/presentation/views/athlete_form_screen.dart';
import '../features/asistencia/presentation/views/attendance_screen.dart';
import '../features/estadisticas/presentation/views/play_by_play_screen.dart';
import '../features/estadisticas/data/local_db/database_service.dart';
import '../features/settings/presentation/widgets/settings_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _athleteCount = 0;
  int _matchCount = 0;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final db = DatabaseService.instance;
      await db.initialize();
      final players = await db.getAllPlayers();
      final matches = await db.getMatchesByState(EstadoPartido.finalizado);
      if (mounted) setState(() {
        _athleteCount = players.length;
        _matchCount = matches.length;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    final today = DateTime.now();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      endDrawer: const SettingsDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(user, today),
              const SizedBox(height: 24),
              _statsRow(),
              const SizedBox(height: 28),
              _sectionTitle('Acciones Rápidas'),
              const SizedBox(height: 12),
              _quickActions(),
              const SizedBox(height: 28),
              _sectionTitle('Resumen Reciente'),
              const SizedBox(height: 12),
              _resumenCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(dynamic user, DateTime today) {
    final months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.surfaceLight,
          child: Image.asset('assets/images/logo_libero.png', width: 28, height: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${user?.nombre?.split(' ').first ?? "Usuario"}',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '${days[today.weekday - 1]}, ${today.day} ${months[today.month - 1]} ${today.year}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppColors.textSecondary),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ),
      ],
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(child: _statCard(Icons.people_rounded, 'Atletas', '$_athleteCount', AppColors.primary,
          onTap: () => context.pushSlide(const AthleteListScreen()),
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(Icons.sports_volleyball_rounded, 'Partidos', '$_matchCount', AppColors.accent,
          onTap: () => context.pushSlide(const PlayByPlayScreen()),
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(Icons.show_chart_rounded, 'Sets', '--', AppColors.success)),
      ],
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color, {VoidCallback? onTap}) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 14),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActions() {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            Icons.sports_volleyball_rounded,
            'Nuevo Partido',
            AppColors.accent,
            () => showDialog(context: context, builder: (_) => const MatchStartDialog()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionCard(
            Icons.person_add_rounded,
            'Nuevo Atleta',
            AppColors.primary,
            () => context.pushSlide(const AthleteFormScreen()),
          ),
        ),
      ],
    );
  }

  Widget _actionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _resumenCards() {
    return Column(
      children: [
        _resumenItem(
          Icons.people_rounded,
          'Gestiona tus atletas',
          'Ver roster completo, agregar o editar jugadores',
          () => context.pushSlide(const AthleteListScreen()),
        ),
        const SizedBox(height: 8),
        _resumenItem(
          Icons.bar_chart_rounded,
          'Estadísticas en vivo',
          'Sigue el rendimiento durante el partido',
          () => context.pushSlide(const PlayByPlayScreen()),
        ),
        const SizedBox(height: 8),
        _resumenItem(
          Icons.calendar_month_rounded,
          'Control de asistencia',
          'Registra la asistencia a entrenamientos',
          () => context.pushSlide(const AttendanceScreen()),
        ),
      ],
    );
  }

  Widget _resumenItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
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
