// lib/features/auth/presentation/pages/register_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ayutthaya_camp/core/services/auth_email_service.dart';

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

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _repeatEmailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _repeatPassCtrl = TextEditingController();

  bool _loading = false;
  bool _loadingSchools = true;
  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;
  List<School> _schools = [];
  School? _selectedSchool;
  String? _errorSchools;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAuthPersistence();
    _cargarSchools();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
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
    _animationController.dispose();
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
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error creando escuelas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creando escuelas: $e'),
            backgroundColor: const Color(0xFFEF4444),
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
        const SnackBar(
          content: Text('Selecciona una escuela'),
          backgroundColor: Color(0xFFEF4444),
        ),
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

      // 2) Crear documento del usuario en Firestore PRIMERO
      debugPrint('📝 Creando documento de usuario en Firestore...');
      debugPrint('   UID: ${user.uid}');
      debugPrint('   Email: $email');
      debugPrint('   Nombre: $nombre $apellido');
      debugPrint('   School: $schoolId');

      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': email,
          'searchKey': email.toLowerCase(),
          'name': '$nombre $apellido',
          'role': 'student',
          'membershipStatus': 'none',
          'schoolId': schoolId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Documento de usuario creado exitosamente');

        // Verificar que el documento se creó correctamente
        final verifyDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!verifyDoc.exists) {
          throw Exception('El documento del usuario no se pudo crear en Firestore');
        }

        debugPrint('✅ Documento verificado en Firestore');
      } catch (firestoreError) {
        debugPrint('❌ Error crítico al crear documento en Firestore: $firestoreError');
        try {
          await user.delete();
          debugPrint('🗑️ Usuario eliminado de Auth debido a error en Firestore');
        } catch (deleteError) {
          debugPrint('⚠️ No se pudo eliminar usuario de Auth: $deleteError');
        }
        throw Exception('Error al crear perfil de usuario: $firestoreError');
      }

      // 3) Enviar verificación profesional con Cloud Function + Resend
      //    (en try-catch para que no rompa el registro si falla)
      bool emailSent = false;
      try {
        final emailService = AuthEmailService();
        await emailService.sendVerificationEmail();
        emailSent = true;
      } catch (emailError) {
        debugPrint('⚠️ Error enviando email de verificación: $emailError');
        // Continuamos aunque falle el email
      }

      // 4) Cerrar sesión SIEMPRE
      await FirebaseAuth.instance.signOut();
      await Future.delayed(const Duration(milliseconds: 150));

      if (!mounted) return;

      // 5) Notificar y enviar al login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            emailSent
                ? 'Te enviamos un correo de verificación. Valídalo y luego inicia sesión.'
                : 'Cuenta creada. Te enviamos el correo de verificación a tu email.',
          ),
          backgroundColor: emailSent ? const Color(0xFF10B981) : const Color(0xFFFF8534),
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } on FirebaseAuthException catch (e) {
      String msg = "Error en Firebase";
      if (e.code == 'email-already-in-use') msg = "Ese email ya está en uso";
      if (e.code == 'weak-password') msg = "Contraseña muy débil";
      if (e.code == 'invalid-email') msg = "Email inválido";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isFormBusy = _loading || _loadingSchools;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0F0F),
              Color(0xFF1A1A1A),
              Color(0xFF0F0F0F),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 24 : 32,
                    vertical: 32,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isSmallScreen ? double.infinity : 500,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(context, isSmallScreen),
                            SizedBox(height: isSmallScreen ? 32 : 40),
                            _buildRegisterCard(context, isSmallScreen, isFormBusy),
                            SizedBox(height: isSmallScreen ? 24 : 32),
                            _buildFooter(context, isFormBusy),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    return Column(
      children: [
        Container(
          width: isSmallScreen ? 100 : 120,
          height: isSmallScreen ? 100 : 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFF6A00),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6A00).withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: kIsWeb
                ? Image.network(
                    'images/canvas.jpeg',
                    width: isSmallScreen ? 100 : 120,
                    height: isSmallScreen ? 100 : 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF6A00), Color(0xFFFF8534)],
                          ),
                        ),
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
                    width: isSmallScreen ? 100 : 120,
                    height: isSmallScreen ? 100 : 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF6A00), Color(0xFFFF8534)],
                          ),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          size: 60,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 20 : 24),
        Text(
          'ÚNETE A AYUTTHAYA',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isSmallScreen ? 24 : 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: const Color(0xFFFF6A00),
            shadows: const [
              Shadow(
                color: Color(0xFFFF6A00),
                blurRadius: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Crea tu cuenta de atleta',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterCard(BuildContext context, bool isSmallScreen, bool isFormBusy) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFF6A00).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6A00).withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nombre y Apellido en fila
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nombre',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF6A00),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _nombreCtrl,
                      hint: 'Juan',
                      icon: Icons.person_outline,
                      validator: _required,
                      textInputAction: TextInputAction.next,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Apellido',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF6A00),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _apellidoCtrl,
                      hint: 'Pérez',
                      icon: Icons.badge_outlined,
                      validator: _required,
                      textInputAction: TextInputAction.next,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Email
          _buildFieldLabel('Email'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _emailCtrl,
            hint: 'tu@email.com',
            icon: Icons.email_outlined,
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
          const SizedBox(height: 16),

          // Confirmar Email
          _buildFieldLabel('Confirmar Email'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _repeatEmailCtrl,
            hint: 'tu@email.com',
            icon: Icons.email_outlined,
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
          const SizedBox(height: 16),

          // Contraseña
          _buildFieldLabel('Contraseña'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _passCtrl,
            hint: '••••••••',
            icon: Icons.lock_outlined,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (_required(v) != null) return 'Ingresa tu contraseña';
              if ((v ?? '').length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // Confirmar Contraseña
          _buildFieldLabel('Confirmar Contraseña'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _repeatPassCtrl,
            hint: '••••••••',
            icon: Icons.lock_outlined,
            obscureText: _obscureRepeatPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRepeatPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
              onPressed: () => setState(() => _obscureRepeatPassword = !_obscureRepeatPassword),
            ),
            validator: (v) {
              if (_required(v) != null) return 'Repite tu contraseña';
              if (v!.trim() != _passCtrl.text.trim()) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Selector de Escuela
          _buildSchoolSelector(isFormBusy),

          SizedBox(height: isSmallScreen ? 24 : 28),

          // Botón Crear Cuenta
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: isFormBusy ? null : _onRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6A00),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFFF6A00).withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isFormBusy
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'CREAR CUENTA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFFFF6A00),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontWeight: FontWeight.w400,
          fontSize: 15,
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFFFF6A00),
          size: 20,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF0F0F0F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFFF6A00),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        errorStyle: const TextStyle(fontSize: 12, height: 0.8),
      ),
      validator: validator,
    );
  }

  Widget _buildSchoolSelector(bool isFormBusy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Escuela'),
        const SizedBox(height: 6),
        if (_loadingSchools)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF6A00),
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Cargando escuelas...',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          )
        else if (_errorSchools != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEF4444)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorSchools!,
                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _cargarSchools,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reintentar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (_schools.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8534).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFF8534)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFFF8534), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'No hay escuelas disponibles',
                      style: TextStyle(
                        color: Color(0xFFFF8534),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Necesitas crear escuelas en Firestore primero.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _createDemoSchools,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Crear escuelas de ejemplo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8534),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<School>(
            initialValue: _selectedSchool,
            dropdownColor: const Color(0xFF1A1A1A),
            items: _schools
                .map(
                  (e) => DropdownMenuItem<School>(
                    value: e,
                    child: Text(
                      e.name.isEmpty ? e.id : e.name,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                )
                .toList(),
            onChanged: isFormBusy ? null : (v) => setState(() => _selectedSchool = v),
            decoration: InputDecoration(
              hintText: 'Selecciona tu escuela',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 15,
              ),
              prefixIcon: const Icon(
                Icons.school_outlined,
                color: Color(0xFFFF6A00),
                size: 20,
              ),
              filled: true,
              fillColor: const Color(0xFF0F0F0F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFFF6A00),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              errorStyle: const TextStyle(fontSize: 12, height: 0.8),
            ),
            validator: (v) => v == null ? 'Selecciona una escuela' : null,
          ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, bool isFormBusy) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.white.withValues(alpha: 0.2),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '¿Ya tienes cuenta?',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.white.withValues(alpha: 0.2),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: isFormBusy
                ? null
                : () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF6A00),
              side: const BorderSide(
                color: Color(0xFFFF6A00),
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'INICIAR SESIÓN',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
