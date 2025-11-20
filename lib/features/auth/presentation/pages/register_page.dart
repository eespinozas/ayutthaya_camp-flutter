// lib/features/auth/presentation/pages/register_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../escuelas/data/escuelas_repository_http.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

const _baseUrl = "http://localhost:3000"; // en emulador Android usa "http://10.0.2.2:3000"

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _repeatEmailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _repeatPassCtrl = TextEditingController();

  bool _loading = false;
  bool _loadingEscuelas = true;
  List<Escuela> _escuelas = [];
  Escuela? _escuelaSeleccionada;
  String? _errorEscuelas;

  @override
  void initState() {
    super.initState();
    _setupAuthPersistence();
    _cargarEscuelas();
  }

  Future<void> _setupAuthPersistence() async {
    // En Web puedes ajustar la persistencia para evitar sesiones pegadas post-registro
    if (kIsWeb) {
      try {
        await FirebaseAuth.instance.setPersistence(Persistence.SESSION);
      } catch (_) {
        // Ignorar si no está soportado
      }
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _repeatEmailCtrl.dispose();
    _passCtrl.dispose();
    _repeatPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarEscuelas() async {
    setState(() {
      _loadingEscuelas = true;
      _errorEscuelas = null;
    });
    try {
      final repo = EscuelasRepositoryHttp();
      final items = await repo.fetchEscuelas();
      setState(() {
        _escuelas = items;
        _escuelaSeleccionada = items.isNotEmpty ? items.first : null;
      });
    } catch (e) {
      setState(() => _errorEscuelas = 'No se pudieron cargar las escuelas.');
    } finally {
      if (mounted) setState(() => _loadingEscuelas = false);
    }
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_escuelaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una escuela')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final nombre = _nombreCtrl.text.trim();
      final apellido = _apellidoCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final pass = _passCtrl.text.trim();
      final escuelaId = _escuelaSeleccionada!.id;

      // 1) Crear en Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );
      final user = cred.user!;
      await user.updateDisplayName('$nombre $apellido');

      // 2) Enviar verificación
      await user.sendEmailVerification();

      // 3) ID Token para backend (Bearer)
      final idToken = await user.getIdToken(true);

      // 4) Crear en tu backend (estado pendiente de verificación)
      final res = await http.post(
        Uri.parse("$_baseUrl/api/users/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $idToken",
        },
        body: jsonEncode({
          "uid": user.uid,
          "nombre": nombre,
          "apellido": apellido,
          "email": email,
          "escuelaId": escuelaId,
          "estado": "pendingEmail",
        }),
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("Error backend (${res.statusCode}): ${res.body}");
      }

      // 5) Cerrar sesión SIEMPRE para forzar el flujo de verificación antes del acceso
      await FirebaseAuth.instance.signOut();

      // Pequeño respiro para que cualquier listener de auth se entere del signOut
      await Future.delayed(const Duration(milliseconds: 150));

      if (!mounted) return;

      // 6) Notificar y enviar al login limpiando el stack
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Te enviamos un correo de verificación. Valídalo y luego inicia sesión.',
          ),
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } on FirebaseAuthException catch (e) {
      String msg = "Error en Firebase";
      if (e.code == 'email-already-in-use') msg = "Ese email ya está en uso";
      if (e.code == 'weak-password') msg = "Contraseña muy débil";
      if (e.code == 'invalid-email') msg = "Email inválido";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _required(String? v, {String msg = 'Campo requerido'}) {
    if (v == null || v.trim().isEmpty) return msg;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isFormBusy = _loading || _loadingEscuelas;

    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nombreCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: _required,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _apellidoCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Apellido',
                            prefixIcon: Icon(Icons.badge),
                          ),
                          validator: _required,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (_required(v) != null) return 'Ingresa tu email';
                      final email = v!.trim();
                      final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!regex.hasMatch(email)) return 'Email no válido';
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _repeatEmailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Repetir email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (_required(v) != null) return 'Repite tu email';
                      if (v!.trim() != _emailCtrl.text.trim()) {
                        return 'Los emails no coinciden';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (v) {
                      if (_required(v) != null) return 'Ingresa tu contraseña';
                      if ((v ?? '').length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _repeatPassCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Repetir contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (v) {
                      if (_required(v) != null) return 'Repite tu contraseña';
                      if (v!.trim() != _passCtrl.text.trim()) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_loadingEscuelas)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_errorEscuelas != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _errorEscuelas!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _cargarEscuelas,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    )
                  else
                    DropdownButtonFormField<Escuela>(
                      value: _escuelaSeleccionada,
                      items: _escuelas
                          .map(
                            (e) => DropdownMenuItem<Escuela>(
                              value: e,
                              child: Text(e.nombre.isEmpty ? e.id : e.nombre),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        _escuelaSeleccionada = v;
                      }),
                      decoration: const InputDecoration(
                        labelText: 'Escuela',
                        prefixIcon: Icon(Icons.school),
                      ),
                      validator: (v) =>
                          v == null ? 'Selecciona una escuela' : null,
                    ),

                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: isFormBusy ? null : _onRegister,
                    child: isFormBusy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Crear cuenta'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isFormBusy
                        ? null
                        : () => Navigator.of(context)
                            .pushNamedAndRemoveUntil('/login', (r) => false),
                    child: const Text('¿Ya tienes cuenta? Inicia sesión'),
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
