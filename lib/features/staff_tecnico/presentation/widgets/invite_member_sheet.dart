import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/staff_tecnico_models.dart';

class InviteMemberSheet extends StatefulWidget {
  final Future<bool> Function(StaffInvitation invitation) onInvite;

  const InviteMemberSheet({super.key, required this.onInvite});

  @override
  State<InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends State<InviteMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  StaffRole _selectedRole = StaffRole.entrenador;
  bool _submitting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Invitar entrenador',
                  style: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
                filled: true,
                fillColor: AppColors.surfaceLight.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.3)),
                ),
                prefixIcon: Icon(Icons.email_rounded, color: cs.onSurface.withValues(alpha: 0.4)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa un correo';
                if (!v.contains('@')) return 'Correo inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<StaffRole>(
              value: _selectedRole,
              dropdownColor: cs.surface,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                labelText: 'Rol',
                labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
                filled: true,
                fillColor: AppColors.surfaceLight.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.3)),
                ),
                prefixIcon: Icon(Icons.badge_rounded, color: cs.onSurface.withValues(alpha: 0.4)),
              ),
              items: StaffRole.values.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text('${role.icon}  ${role.displayName}'),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedRole = v);
              },
            ),
            const SizedBox(height: 8),
            Text(
              'No se enviarán correos reales. La invitación se guardará localmente.',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Enviar invitación', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final ok = await widget.onInvite(StaffInvitation(
      email: _emailCtrl.text.trim(),
      role: _selectedRole,
    ));
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _submitting = false);
    }
  }
}
