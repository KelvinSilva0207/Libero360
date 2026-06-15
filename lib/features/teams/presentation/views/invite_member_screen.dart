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
    final vm = context.read<ClubViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        title: const Text('Invitar entrenador'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Correo electrónico',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'correo@ejemplo.com',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: const Color(0xFF1A1F3D),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            Text('Rol',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
            const SizedBox(height: 8),
            _roleSelector(),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _sending ? null : () => _sendInvite(context, vm),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C00),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Enviar invitación',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleSelector() {
    const roles = [
      (ClubRole.entrenador, '🏐 Entrenador', 'Puede registrar y editar atletas, crear partidos, pasar asistencia'),
      (ClubRole.asistente, '📋 Asistente', 'Puede ver atletas, pasar asistencia, registrar eventos'),
    ];

    return Column(
      children: roles.map((r) {
        final (role, label, desc) = r;
        final selected = _selectedRole == role;
        return Card(
          color: selected ? const Color(0xFFFF8C00).withValues(alpha: 0.15) : const Color(0xFF1A1F3D),
          margin: const EdgeInsets.only(bottom: 8),
          child: RadioListTile<ClubRole>(
            value: role,
            groupValue: _selectedRole,
            activeColor: const Color(0xFFFF8C00),
            onChanged: (v) => setState(() => _selectedRole = v!),
            title: Text(label, style: const TextStyle(color: Colors.white)),
            subtitle: Text(desc,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
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
