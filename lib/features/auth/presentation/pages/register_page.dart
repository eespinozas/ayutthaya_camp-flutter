// lib/features/auth/presentation/pages/register_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo simple para School
class School {
  final String id;
  final String name;

  const School({required this.id, required this.name});

  factory School.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return School(
      id: doc.id,
      name: data['name'] ?? data['nombre'] ?? '',
    );
  }
}

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
  bool _loadingSchools = true;
  List<School> _schools = [];
  School? _selectedSchool;
  String? _errorSchools;

  @override
  void initState() {
    super.initState();
    _setupAuthPersistence();
    _cargarSchools();
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

  Future<void> _cargarSchools() async {
    setState(() {
      _loadingSchools = true;
      _errorSchools = null;
    });
    try {
      debugPrint('📚 Cargando escuelas desde Firestore...');
      final snapshot = await FirebaseFirestore.instance.collection('schools').get();
      debugPrint('✅ Snapshot recibido: ${snapshot.docs.length} documentos');

      final items = snapshot.docs.map((doc) {
        debugPrint('  - School ID: ${doc.id}, data: ${doc.data()}');
        return School.fromFirestore(doc);
      }).toList();

      debugPrint('📊 Total escuelas cargadas: ${items.length}');

      setState(() {
        _schools = items;
        _selectedSchool = items.isNotEmpty ? items.first : null;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error cargando escuelas: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _errorSchools = 'No se pudieron cargar las escuelas: $e');
    } finally {
      if (mounted) setState(() => _loadingSchools = false);
    }
  }

  Future<void> _createDemoSchools() async {
    setState(() => _loadingSchools = true);
    try {
      debugPrint('🏫 Creando escuelas de ejemplo...');

      final schools = [
        {'name': 'Ayutthaya Camp Centro', 'active': true},
        {'name': 'Ayutthaya Camp Norte', 'active': true},
        {'name': 'Ayutthaya Camp Sur', 'active': true},
      ];

      for (var school in schools) {
        await FirebaseFirestore.instance.collection('schools').add({
          ...school,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('  ✅ Creada: ${school['name']}');
      }

      debugPrint('🎉 Escuelas creadas exitosamente');

      // Recargar escuelas
      await _cargarSchools();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Escuelas creadas exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error creando escuelas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creando escuelas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingSchools = false);
    }
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSchool == null) {
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
      final schoolId = _selectedSchool!.id;

      // 1) Crear en Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );
      final user = cred.user!;
      await user.updateDisplayName('$nombre $apellido');

      // 2) Enviar verificación
      await user.sendEmailVerification();

      // 3) Crear documento del usuario en Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': email,
        'name': '$nombre $apellido',
        'role': 'student',
        'membershipStatus': 'none', // none, pending, active, expired, frozen
        'schoolId': schoolId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4) Cerrar sesión SIEMPRE para forzar el flujo de verificación antes del acceso
      await FirebaseAuth.instance.signOut();

      // Pequeño respiro para que cualquier listener de auth se entere del signOut
      await Future.delayed(const Duration(milliseconds: 150));

      if (!mounted) return;

      // 5) Notificar y enviar al login limpiando el stack
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
    final isFormBusy = _loading || _loadingSchools;

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

                  if (_loadingSchools)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_errorSchools != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _errorSchools!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _cargarSchools,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    )
                  else if (_schools.isEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'No hay escuelas disponibles',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Necesitas crear escuelas en Firestore primero.',
                                style: TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _createDemoSchools,
                                icon: const Icon(Icons.add),
                                label: const Text('Crear escuelas de ejemplo'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    DropdownButtonFormField<School>(
                      value: _selectedSchool,
                      items: _schools
                          .map(
                            (e) => DropdownMenuItem<School>(
                              value: e,
                              child: Text(e.name.isEmpty ? e.id : e.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        _selectedSchool = v;
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
