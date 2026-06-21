import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../ui/components/app_logo.dart';
import '../../../../ui/components/app_text_field.dart';
import '../viewmodels/auth_viewmodel.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    final error = await vm.register(
      _nombreCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );
    if (error == null) {
      return;
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
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
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded, size: 16),
                              label: const Text('Volver', style: TextStyle(fontSize: 14)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const AppLogo(size: 72, showText: false),
                          const SizedBox(height: 24),
                          const Text(
                            'Crear tu cuenta',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: -0.3),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Comienza a gestionar tu equipo',
                            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)),
                          ),
                          const SizedBox(height: 36),
                          AppTextField(
                            controller: _nombreCtrl,
                            label: 'Nombre del equipo / entrenador',
                            hint: 'Tu nombre o el de tu equipo',
                            prefixIcon: Icons.person_rounded,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Ingresa tu nombre';
                              if (v.trim().length < 2) return 'Nombre muy corto';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          AppTextField(
                            controller: _emailCtrl,
                            label: 'Correo electrónico',
                            hint: 'ejemplo@correo.com',
                            prefixIcon: Icons.email_rounded,
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
                            prefixIcon: Icons.lock_rounded,
                            isPassword: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                              if (v.length < 6) return 'Mínimo 6 caracteres';
                              if (!v.contains(RegExp(r'[A-Z]'))) return 'Debe contener una mayúscula';
                              if (!v.contains(RegExp(r'[0-9]'))) return 'Debe contener un número';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          AppTextField(
                            controller: _confirmCtrl,
                            label: 'Confirmar contraseña',
                            hint: 'Repite la contraseña',
                            prefixIcon: Icons.lock_rounded,
                            isPassword: true,
                            validator: (v) {
                              if (v != _passwordCtrl.text) return 'Las contraseñas no coinciden';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
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
                                        Icon(Icons.person_add_rounded, size: 18),
                                        SizedBox(width: 10),
                                        Text('Crear Cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Al registrarte, aceptas nuestros Términos y Condiciones y Política de Privacidad.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11, height: 1.4),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('¿Ya tienes cuenta? ', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/login'),
                                child: const Text('Inicia sesión', style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
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
}
