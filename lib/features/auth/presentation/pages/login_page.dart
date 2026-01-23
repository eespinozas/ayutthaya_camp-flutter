// lib/features/auth/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 👇 importa las navbars
import 'package:ayutthaya_camp/features/dashboard/presentation/pages/main_nav_bar.dart';
import 'package:ayutthaya_camp/features/admin/presentation/pages/admin_main_nav_bar.dart';
import 'package:ayutthaya_camp/core/services/auth_email_service.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final email = _email.text.trim();
      final pass = _password.text.trim();
      final authVM = context.read<AuthViewModel>();

      // 1) Login usando AuthViewModel
      final success = await authVM.login(email: email, password: pass);

      if (!success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authVM.error ?? 'Error de autenticación')),
        );
        setState(() => _loading = false);
        return;
      }

      // 2) Validar verificación de email (excepto para admin o emails que empiezan con "admin")
      final user = authVM.currentUser;
      if (user != null && !user.emailVerified && !authVM.isAdmin && !email.startsWith('admin')) {
        await authVM.logout();
        if (!mounted) return;

        await showDialog(
          context: context,
          builder: (_) => EmailNotVerifiedDialog(
            email: email,
            onResend: _onResendVerification,
          ),
        );
        setState(() => _loading = false);
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authVM.isAdmin
              ? 'Bienvenido Admin!'
              : 'Inicio de sesión exitoso'
          ),
        ),
      );

      // 3) Redirigir según el rol
      final Widget destination = authVM.isAdmin
          ? const AdminMainNavBar()
          : const MainNavBar();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Error de autenticación';
      switch (e.code) {
        case 'user-not-found':
          msg = 'Usuario no encontrado';
          break;
        case 'wrong-password':
          msg = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          msg = 'Email inválido';
          break;
        case 'too-many-requests':
          msg = 'Demasiados intentos, inténtalo más tarde';
          break;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Reenvía el correo de verificación usando SendGrid (email profesional).
  /// Nota: Para enviarlo, el usuario debe estar autenticado; hacemos un login silencioso.
  Future<void> _onResendVerification() async {
    try {
      final email = _email.text.trim();
      final pass = _password.text.trim();

      // Login silencioso para autenticar al usuario
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      // Enviar email profesional con SendGrid
      final emailService = AuthEmailService();
      await emailService.sendVerificationEmail();

      // Logout después de enviar
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📧 Correo de verificación enviado. Revisa tu bandeja de entrada.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo reenviar: ${e.message ?? e.code}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo circular
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: kIsWeb
                                ? Image.network(
                                    'images/canvas.jpeg',
                                    height: 120,
                                    width: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 120,
                                        width: 120,
                                        color: Theme.of(context).primaryColor,
                                        child: const Icon(
                                          Icons.fitness_center,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  )
                                : Image.asset(
                                    'assets/images/canvas.jpeg',
                                    height: 120,
                                    width: 120,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Título
                        Text(
                          'Bienvenido',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'a Ayutthaya',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 32),

                        // Input Email
                        TextFormField(
                          controller: _email,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'tu@email.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Ingresa tu email' : null,
                        ),
                        const SizedBox(height: 16),

                        // Input Password
                        TextFormField(
                          controller: _password,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          obscureText: true,
                          validator: (v) =>
                              (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                        ),
                        const SizedBox(height: 24),

                        // Botón Ingresar
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            onPressed: busy ? null : _onLogin,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: busy
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Ingresar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Olvidaste tu contraseña
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => Navigator.pushNamed(context, '/forgot-password'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange,
                          ),
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                        const SizedBox(height: 8),

                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'o',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Crear cuenta
                        OutlinedButton(
                          onPressed: busy
                              ? null
                              : () => Navigator.pushNamed(context, '/register'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Crear cuenta nueva',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

/// Diálogo para usuarios no verificados con botón para reenviar correo.
class EmailNotVerifiedDialog extends StatefulWidget {
  final String email;
  final Future<void> Function() onResend;

  const EmailNotVerifiedDialog({
    super.key,
    required this.email,
    required this.onResend,
  });

  @override
  State<EmailNotVerifiedDialog> createState() => _EmailNotVerifiedDialogState();
}

class _EmailNotVerifiedDialogState extends State<EmailNotVerifiedDialog> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verifica tu correo'),
      content: Text(
        'Tu cuenta "${widget.email}" aún no está verificada.\n'
        'Revisa tu bandeja y spam. Puedes reenviar el correo de verificación.',
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        TextButton(
          onPressed: _busy
              ? null
              : () async {
                  setState(() => _busy = true);
                  try {
                    await widget.onResend();
                    if (mounted) Navigator.pop(context);
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
          child: _busy
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Reenviar verificación'),
        ),
      ],
    );
  }
}
