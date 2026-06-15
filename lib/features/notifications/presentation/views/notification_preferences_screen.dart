import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/notification_models.dart';
import '../viewmodels/notification_viewmodel.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  NotificationPreference? _prefs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final vm = context.read<NotificationViewModel>();
    final prefs = await vm.loadPreferences();
    setState(() {
      _prefs = prefs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        title: const Text('Preferencias de notificaciones'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Guardar',
                style: TextStyle(color: Color(0xFFFF8C00))),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF8C00)))
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    if (_prefs == null) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('Atletas', [
          _toggle(NotificationType.athleteCreated),
          _toggle(NotificationType.athleteEdited),
          _toggle(NotificationType.categoryChanged),
          _toggle(NotificationType.birthday),
        ]),
        const SizedBox(height: 16),
        _section('Asistencia', [
          _toggle(NotificationType.attendanceWarning),
          _toggle(NotificationType.consecutiveAbsences),
          _toggle(NotificationType.perfectAttendance),
          _toggle(NotificationType.restPeriodEnded),
          _toggle(NotificationType.injuryRegistered),
        ]),
        const SizedBox(height: 16),
        _section('Partidos', [
          _toggle(NotificationType.matchCreated),
          _toggle(NotificationType.mvpRegistered),
          _toggle(NotificationType.matchResultSaved),
          _toggle(NotificationType.newLeague),
          _toggle(NotificationType.newTournament),
        ]),
        const SizedBox(height: 16),
        _section('Colaboración', [
          _toggle(NotificationType.newCoach),
          _toggle(NotificationType.invitationReceived),
          _toggle(NotificationType.invitationAccepted),
        ]),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title,
              style: const TextStyle(
                  color: Color(0xFFFF8C00),
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ),
        Card(
          color: const Color(0xFF1A1F3D),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _toggle(NotificationType type) {
    return SwitchListTile(
      title: Text(type.label,
          style: const TextStyle(color: Colors.white, fontSize: 14)),
      value: _prefs?.isEnabled(type) ?? true,
      activeColor: const Color(0xFFFF8C00),
      onChanged: (v) {
        setState(() {
          final map = Map<String, bool>.from(_prefs!.enabledTypes);
          map[type.name] = v;
          _prefs = NotificationPreference(enabledTypes: map);
        });
      },
    );
  }

  Future<void> _save() async {
    if (_prefs == null) return;
    final vm = context.read<NotificationViewModel>();
    await vm.savePreferences(_prefs!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Preferencias guardadas'),
            backgroundColor: Color(0xFF4CAF50)),
      );
      Navigator.pop(context);
    }
  }
}
