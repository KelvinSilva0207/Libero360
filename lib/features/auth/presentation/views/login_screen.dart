import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../ui/components/app_text_field.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    final success = await vm.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );
    if (success && mounted) {
      Navigator.pop(context);
    } else if (!success && mounted) {
      _showError(vm.error ?? 'Error al iniciar sesión');
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Próximamente disponible'), backgroundColor: AppColors.primary),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E21), Color(0xFF0F172A), Color(0xFF060A1A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                    child: Consumer<AuthViewModel>(
                      builder: (context, vm, _) {
                        return Stack(
                          children: [
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Text(
                                        'Iniciar Sesión',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white.withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ),
                                  ),
                                  AppTextField(
                                    controller: _emailCtrl,
                                    label: 'Correo electrónico',
                                    hint: 'tu@correo.com',
                                    prefixIcon: Icons.email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Ingresa tu correo';
                                      if (!v.contains('@')) return 'Correo inválido';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  AppTextField(
                                    controller: _passwordCtrl,
                                    label: 'Contraseña',
                                    hint: 'Mínimo 6 caracteres',
                                    prefixIcon: Icons.lock_rounded,
                                    isPassword: true,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                                      if (v.length < 6) return 'Mínimo 6 caracteres';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => _showComingSoon(context),
                                      child: const Text(
                                        '¿Olvidaste tu contraseña?',
                                        style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: FilledButton(
                                      onPressed: vm.isLoading ? null : () => _submit(vm),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.accent,
                                        disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: vm.isLoading
                                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.textOnAccent))
                                          : const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.login_rounded, size: 18, color: AppColors.textOnAccent),
                                                SizedBox(width: 10),
                                                Text('Iniciar Sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildDivider(),
                                  const SizedBox(height: 20),
                                  _SocialButton(
                                    label: 'Continuar con Google',
                                    icon: Icons.g_mobiledata_rounded,
                                    iconColor: AppColors.google,
                                    onPressed: () => _showComingSoon(context),
                                  ),
                                  const SizedBox(height: 12),
                                  _SocialButton(
                                    label: 'Continuar con Facebook',
                                    icon: Icons.facebook_rounded,
                                    iconColor: AppColors.facebook,
                                    onPressed: () => _showComingSoon(context),
                                  ),
                                  const SizedBox(height: 28),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('¿No tienes cuenta? ', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                                      GestureDetector(
                                        onTap: () => Navigator.pushNamed(context, '/register'),
                                        child: const Text('Regístrate', style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                            if (vm.isLoading)
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: const Color(0xCC0A0E21),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 28, height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Color(0xFFFF8C00),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Text('Iniciando sesión...', style: TextStyle(color: Colors.white54, fontSize: 14)),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('O continúa con', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
        ),
        Expanded(child: Container(height: 1, color: AppColors.border)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.borderLight),
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
