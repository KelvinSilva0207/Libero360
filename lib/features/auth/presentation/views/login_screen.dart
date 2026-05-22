import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../ui/components/app_logo.dart';
import '../../../../ui/components/app_text_field.dart';
import '../../../../ui/components/app_button.dart';
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
    if (!success && mounted) {
      _showError(vm.error ?? 'Error al iniciar sesión');
    }
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
                    return Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(8),
                            child: const Row(
                              children: [
                                Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary, size: 22),
                                SizedBox(width: 4),
                                Text('Volver', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const AppLogo(size: 64),
                          const SizedBox(height: 32),
                          const Text(
                            'Bienvenido de nuevo',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ingresa tus credenciales para continuar',
                            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)),
                          ),
                          const SizedBox(height: 32),
                          AppTextField(
                            controller: _emailCtrl,
                            label: 'Correo electrónico',
                            hint: 'ejemplo@correo.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                              final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(v.trim())) return 'Correo inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          AppTextField(
                            controller: _passwordCtrl,
                            label: 'Contraseña',
                            hint: 'Mínimo 6 caracteres',
                            prefixIcon: Icons.lock_outlined,
                            isPassword: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                              if (v.length < 6) return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            label: 'Iniciar Sesión',
                            icon: Icons.login_rounded,
                            isLoading: vm.isLoading,
                            onPressed: () => _submit(vm),
                          ),
                          const SizedBox(height: 24),
                          _buildDivider(),
                          const SizedBox(height: 20),
                          SocialButton(
                            label: 'Continuar con Google',
                            icon: Icons.g_mobiledata_rounded,
                            iconColor: AppColors.google,
                            onPressed: () {},
                          ),
                          const SizedBox(height: 12),
                          SocialButton(
                            label: 'Continuar con Facebook',
                            icon: Icons.facebook_rounded,
                            iconColor: AppColors.facebook,
                            onPressed: () {},
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('¿No tienes cuenta? ', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(context, '/register'),
                                child: const Text('Regístrate', style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
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
