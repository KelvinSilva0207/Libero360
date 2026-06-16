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
  bool _modoTodas = true;

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
      _modoTodas = prefs.allEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Preferencias de notificaciones'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Guardar', style: TextStyle(color: cs.primary)),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _buildForm(cs),
    );
  }

  Widget _buildForm(ColorScheme cs) {
    if (_prefs == null) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: cs.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Modo de notificaciones',
                    style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _modeChip(cs, 'Todas', true, Icons.notifications_active),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _modeChip(cs, 'Personalizadas', false, Icons.tune),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!_modoTodas) ...[
          _section(cs, 'Atletas', [
            _toggle(cs, NotificationType.athleteCreated),
            _toggle(cs, NotificationType.athleteEdited),
            _toggle(cs, NotificationType.categoryChanged),
            _toggle(cs, NotificationType.birthday),
          ]),
          const SizedBox(height: 16),
          _section(cs, 'Asistencia', [
            _toggle(cs, NotificationType.attendanceWarning),
            _toggle(cs, NotificationType.consecutiveAbsences),
            _toggle(cs, NotificationType.perfectAttendance),
            _toggle(cs, NotificationType.restPeriodEnded),
            _toggle(cs, NotificationType.injuryRegistered),
          ]),
          const SizedBox(height: 16),
          _section(cs, 'Partidos', [
            _toggle(cs, NotificationType.matchCreated),
            _toggle(cs, NotificationType.mvpRegistered),
            _toggle(cs, NotificationType.matchResultSaved),
            _toggle(cs, NotificationType.newLeague),
            _toggle(cs, NotificationType.newTournament),
          ]),
          const SizedBox(height: 16),
          _section(cs, 'Colaboración', [
            _toggle(cs, NotificationType.newCoach),
            _toggle(cs, NotificationType.invitationReceived),
            _toggle(cs, NotificationType.invitationAccepted),
          ]),
        ],
      ],
    );
  }

  Widget _modeChip(ColorScheme cs, String label, bool isAll, IconData icon) {
    final selected = _modoTodas == isAll;
    return GestureDetector(
      onTap: () => setState(() => _modoTodas = isAll),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected ? cs.primary : cs.onSurface,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _section(ColorScheme cs, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title,
              style: TextStyle(
                  color: cs.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ),
        Card(
          color: cs.surfaceContainerHighest,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _toggle(ColorScheme cs, NotificationType type) {
    return SwitchListTile(
      title: Text(type.label,
          style: TextStyle(color: cs.onSurface, fontSize: 14)),
      value: _prefs?.isEnabled(type) ?? true,
      activeTrackColor: cs.primary.withValues(alpha: 0.5),
      activeThumbColor: cs.primary,
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
    final prefsToSave = _modoTodas
        ? NotificationPreference.allEnabled()
        : _prefs!;
    await vm.savePreferences(prefsToSave);
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
