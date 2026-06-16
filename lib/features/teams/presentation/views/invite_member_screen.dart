import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/team_models.dart';
import '../viewmodels/club_viewmodel.dart';

class InviteMemberScreen extends StatefulWidget {
  const InviteMemberScreen({super.key});

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  final _emailCtrl = TextEditingController();
  ClubRole _selectedRole = ClubRole.entrenador;
  bool _sending = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClubViewModel>();
    final cs = Theme.of(context).colorScheme;
    final isOwner = vm.isOwner;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Invitar miembro del staff'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Correo electrónico',
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7), fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'correo@ejemplo.com',
                hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            Text('Rol',
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.7), fontSize: 14)),
            const SizedBox(height: 8),
            _roleSelector(cs, isOwner),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _sending ? null : () => _sendInvite(context, vm),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _sending
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.onPrimary),
                      )
                    : Text('Enviar invitación',
                        style: TextStyle(fontSize: 16, color: cs.onPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleSelector(ColorScheme cs, bool isOwner) {
    final roles = [
      if (isOwner)
        (ClubRole.owner as ClubRole?, '👑 Propietario',
            'Control total del club: gestionar staff, atletas y configuración'),
      (ClubRole.entrenador, '🏐 Entrenador',
          'Puede registrar y editar atletas, crear partidos, pasar asistencia'),
      (ClubRole.asistente, '📋 Asistente',
          'Puede ver atletas, pasar asistencia, registrar eventos'),
    ];

    return Column(
      children: roles.where((r) => r.$1 != null).map((r) {
        final (role, label, desc) = r;
        final selected = _selectedRole == role;
        return Card(
          color: selected
              ? cs.primary.withValues(alpha: 0.15)
              : cs.surfaceContainerHighest,
          margin: const EdgeInsets.only(bottom: 8),
          child: RadioListTile<ClubRole>(
            value: role!,
            groupValue: _selectedRole,
            activeColor: cs.primary,
            onChanged: (v) => setState(() => _selectedRole = v!),
            title: Text(label, style: TextStyle(color: cs.onSurface)),
            subtitle: Text(desc,
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5), fontSize: 12)),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _sendInvite(BuildContext context, ClubViewModel vm) async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showError('Ingresa un correo electrónico');
      return;
    }

    setState(() => _sending = true);
    final err = await vm.inviteMember(email: email, role: _selectedRole);
    setState(() => _sending = false);

    if (err != null) {
      _showError(err);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Invitación enviada correctamente'),
              backgroundColor: Color(0xFF4CAF50)),
        );
        Navigator.pop(context);
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}
