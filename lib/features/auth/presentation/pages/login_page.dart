// lib/features/auth/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 👇 importa las navbars
import 'package:ayutthaya_camp/features/dashboard/presentation/pages/main_nav_bar.dart';
import 'package:ayutthaya_camp/features/admin/presentation/pages/admin_main_nav_bar.dart';
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

  /// Reenvía el correo de verificación.
  /// Nota: Para enviarlo, el usuario debe estar autenticado; hacemos un login silencioso.
  Future<void> _onResendVerification() async {
    try {
      final email = _email.text.trim();
      final pass = _password.text.trim();

      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
      await cred.user?.sendEmailVerification();
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correo de verificación reenviado')),
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
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Ingresa tu email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: busy ? null : _onLogin,
                    child: busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Ingresar'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed:
                        busy ? null : () => Navigator.pushNamed(context, '/register'),
                    child: const Text('¿No tienes cuenta? Crear una'),
                  ),
                ],
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
