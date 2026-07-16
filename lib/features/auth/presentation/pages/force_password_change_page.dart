import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ayutthaya_camp/utils/validators.dart';
import 'package:ayutthaya_camp/features/admin/presentation/pages/admin_main_nav_bar.dart';
import 'package:ayutthaya_camp/features/dashboard/presentation/pages/main_nav_bar.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/session_guard.dart';
import 'login_page.dart';

/// Cambio de contraseña obligatorio al primer login.
///
/// Las cuentas creadas por un administrador nacen con una contraseña
/// temporal y `mustChangePassword: true`: esta pantalla bloquea el acceso
/// a la app hasta definir una contraseña propia. No se puede retroceder;
/// la única salida alternativa es cerrar sesión.
class ForcePasswordChangePage extends StatefulWidget {
  const ForcePasswordChangePage({super.key});

  @override
  State<ForcePasswordChangePage> createState() =>
      _ForcePasswordChangePageState();
}

class _ForcePasswordChangePageState extends State<ForcePasswordChangePage> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _repeatPassCtrl = TextEditingController();

  bool _saving = false;
  bool _obscurePass = true;
  bool _obscureRepeat = true;

  @override
  void dispose() {
    _passCtrl.dispose();
    _repeatPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final authVM = context.read<AuthViewModel>();

    try {
      await authVM.changeTemporaryPassword(_passCtrl.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada. ¡Bienvenido!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      final Widget destination = authVM.isAdmin
          ? const SessionGuard(child: AdminMainNavBar())
          : const SessionGuard(child: MainNavBar());
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'requires-recent-login' =>
          'Por seguridad, vuelve a iniciar sesión e inténtalo de nuevo.',
        'weak-password' => 'La contraseña es muy débil.',
        _ => 'No se pudo cambiar la contraseña. Intenta de nuevo.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: const Color(0xFFEF4444)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cambiar la contraseña. Intenta de nuevo.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onLogout() async {
    await context.read<AuthViewModel>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  /// Checklist en vivo de requisitos (mismo patrón que el registro).
  Widget _buildChecklist() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _passCtrl,
      builder: (context, value, _) {
        final rules = [
          (
            'Mínimo ${Validators.passwordMinLength} caracteres',
            Validators.passwordHasMinLength(value.text),
          ),
          ('Al menos una mayúscula', Validators.passwordHasUppercase(value.text)),
          ('Letras y números', Validators.passwordIsAlphanumeric(value.text)),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rules.map((rule) {
            final (label, ok) = rule;
            final color =
                ok ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.4);
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(
                    ok ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Text(label, style: TextStyle(fontSize: 12, color: color)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  InputDecoration _decoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFFFF6A00), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF0F0F0F),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
      errorStyle: const TextStyle(fontSize: 12, height: 0.8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return PopScope(
      canPop: false, // No hay vuelta atrás: la contraseña temporal debe cambiarse
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.password_rounded,
                        size: 64,
                        color: Color(0xFFFF6A00),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Crea tu contraseña',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tu cuenta $email fue creada con una contraseña '
                        'temporal. Por seguridad debes definir una propia '
                        'antes de continuar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        style: const TextStyle(color: Colors.white),
                        decoration: _decoration(
                          'Nueva contraseña',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                        validator: Validators.validatePassword,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 4),
                      _buildChecklist(),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _repeatPassCtrl,
                        obscureText: _obscureRepeat,
                        style: const TextStyle(color: Colors.white),
                        decoration: _decoration(
                          'Confirmar contraseña',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureRepeat
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscureRepeat = !_obscureRepeat),
                          ),
                        ),
                        validator: (v) =>
                            Validators.validatePasswordMatch(v, _passCtrl.text),
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6A00),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFFFF6A00).withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'GUARDAR Y CONTINUAR',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _saving ? null : _onLogout,
                        child: Text(
                          'Cerrar sesión',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
