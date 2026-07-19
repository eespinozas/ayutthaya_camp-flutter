import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ayutthaya_camp/utils/validators.dart';

/// Formulario para crear cuentas de administrador.
///
/// La cuenta se crea vía Cloud Function (Admin SDK) para no cerrar la
/// sesión del admin actual. El backend genera una contraseña temporal que
/// se muestra UNA sola vez; el nuevo admin debe cambiarla en su primer login.
class AdminCreateAdminPage extends StatefulWidget {
  const AdminCreateAdminPage({super.key});

  @override
  State<AdminCreateAdminPage> createState() => _AdminCreateAdminPageState();
}

class _AdminCreateAdminPageState extends State<AdminCreateAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _creating = false;
  bool _loadingSchools = true;
  List<({String id, String name})> _schools = [];
  String? _selectedSchoolId;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSchools() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('schools')
          .get();
      if (!mounted) return;
      setState(() {
        _schools = snapshot.docs
            .map(
              (doc) => (
                id: doc.id,
                name: (doc.data()['name'] ?? doc.data()['nombre'] ?? doc.id)
                    .toString(),
              ),
            )
            .toList();
        _selectedSchoolId = _schools.isNotEmpty ? _schools.first.id : null;
        _loadingSchools = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSchools = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron cargar las escuelas'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _onCreate() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSchoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una escuela'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _creating = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'createAdminUser',
      );
      final result = await callable.call<Map<String, dynamic>>({
        'nombre': _nombreCtrl.text.trim(),
        'apellido': _apellidoCtrl.text.trim(),
        'email': Validators.normalizeEmail(_emailCtrl.text),
        'schoolId': _selectedSchoolId,
      });

      final tempPassword = result.data['tempPassword'] as String;
      if (!mounted) return;
      await _showPasswordDialog(
        email: Validators.normalizeEmail(_emailCtrl.text),
        tempPassword: tempPassword,
      );

      if (mounted) {
        _formKey.currentState!.reset();
        _nombreCtrl.clear();
        _apellidoCtrl.clear();
        _emailCtrl.clear();
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        final msg = switch (e.code) {
          'already-exists' => 'Ya existe una cuenta con ese correo',
          'permission-denied' =>
            'Solo un administrador puede crear otros administradores',
          'invalid-argument' => e.message ?? 'Datos inválidos',
          _ => 'No se pudo crear el administrador. Intenta de nuevo.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo crear el administrador. Intenta de nuevo.',
            ),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _showPasswordDialog({
    required String email,
    required String tempPassword,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Administrador creado',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cuenta: $email\n\nContraseña temporal (se muestra una sola '
              'vez, cópiala y entrégasela de forma segura):',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F0F),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFF6A00).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      tempPassword,
                      style: const TextStyle(
                        color: Color(0xFFFF6A00),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white70),
                    tooltip: 'Copiar',
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: tempPassword),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contraseña copiada'),
                            backgroundColor: Color(0xFF10B981),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'En su primer inicio de sesión se le pedirá crear una '
              'contraseña propia.',
              style: TextStyle(color: Colors.white54, fontSize: 12.5),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A00),
              foregroundColor: Colors.white,
            ),
            child: const Text('Listo'),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      prefixIcon: Icon(icon, color: const Color(0xFFFF6A00), size: 20),
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Crear Administrador'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6A00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF6A00).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFFFF6A00),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Se generará una contraseña temporal y el nuevo '
                        'administrador deberá cambiarla en su primer inicio '
                        'de sesión.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nombreCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration('Nombre', Icons.person_outline),
                validator: Validators.validateName,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _apellidoCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration('Apellido', Icons.badge_outlined),
                validator: Validators.validateName,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: _decoration(
                  'correo@ejemplo.com',
                  Icons.email_outlined,
                ),
                validator: Validators.validateEmail,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),

              if (_loadingSchools)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: Color(0xFFFF6A00)),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedSchoolId,
                  dropdownColor: const Color(0xFF1A1A1A),
                  decoration: _decoration('Escuela', Icons.school_outlined),
                  items: _schools
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(
                            s.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _creating
                      ? null
                      : (v) => setState(() => _selectedSchoolId = v),
                  validator: (v) => v == null ? 'Selecciona una escuela' : null,
                ),

              const SizedBox(height: 28),

              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _creating || _loadingSchools ? null : _onCreate,
                  icon: _creating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_add_alt_1),
                  label: Text(
                    _creating ? 'Creando...' : 'CREAR ADMINISTRADOR',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6A00),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(
                      0xFFFF6A00,
                    ).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
