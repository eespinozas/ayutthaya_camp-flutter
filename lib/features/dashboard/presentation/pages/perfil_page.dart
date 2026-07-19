import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;

import 'package:ayutthaya_camp/core/services/auth_email_service.dart';
import 'package:ayutthaya_camp/core/services/ranking_service.dart';
import 'package:ayutthaya_camp/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ayutthaya_camp/features/auth/presentation/pages/login_page.dart';
// import 'package:ayutthaya_camp/features/gamification/presentation/widgets/avatar_progress_widget.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _birthDate;
  String? _photoUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _isRefreshing = false;
  bool _isRequestingDeletion = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _totalAttendedClasses = 0;

  final ImagePicker _picker = ImagePicker();

  /// Función para actualizar el perfil
  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);

    await _loadUserData();

    setState(() => _isRefreshing = false);

    // Mostrar mensaje de actualización
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Perfil actualizado'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final auth = context.read<AuthViewModel>();
    final userId = auth.currentUser?.uid;

    if (userId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          // Combinar nombre y apellido si existen
          final nombre = data['nombre'] ?? data['name'] ?? '';
          final apellido = data['apellido'] ?? '';
          _nameController.text = apellido.isNotEmpty
              ? '$nombre $apellido'.trim()
              : nombre;

          _emailController.text = data['email'] ?? '';
          _addressController.text = data['address'] ?? '';
          _photoUrl = data['photoUrl'];

          if (data['birthDate'] != null) {
            _birthDate = (data['birthDate'] as Timestamp).toDate();
          }

          _isLoading = false;
        });
      }

      // Cargar número de clases asistidas
      await _loadAttendedClasses();
    } catch (e) {
      debugPrint('Error cargando datos del usuario: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAttendedClasses() async {
    final auth = context.read<AuthViewModel>();
    final userId = auth.currentUser?.uid;

    if (userId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'attended')
          .get();

      if (mounted) {
        setState(() {
          _totalAttendedClasses = snapshot.docs.length;
        });
      }

      debugPrint('📊 Total de clases asistidas: $_totalAttendedClasses');
    } catch (e) {
      debugPrint('Error cargando clases asistidas: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar contraseñas si se ingresaron
    if (_passwordController.text.isNotEmpty) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Las contraseñas no coinciden'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final auth = context.read<AuthViewModel>();
      final userId = auth.currentUser?.uid;

      if (userId == null) return;

      // Actualizar datos en Firestore
      final updates = <String, dynamic>{
        'address': _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_birthDate != null) {
        updates['birthDate'] = Timestamp.fromDate(_birthDate!);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(updates);

      // Si hay contraseña nueva, actualizarla
      if (_passwordController.text.isNotEmpty) {
        await auth.currentUser?.updatePassword(_passwordController.text);
        _passwordController.clear();
        _confirmPasswordController.clear();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Color _getProgressColor() {
    if (_totalAttendedClasses <= 2) return Colors.grey;
    if (_totalAttendedClasses <= 5) return Colors.blue;
    if (_totalAttendedClasses <= 8) return Colors.orange;
    return Colors.red;
  }

  String _getProgressMessage() {
    if (_totalAttendedClasses == 0) {
      return '¡Comienza tu viaje! 🥊';
    } else if (_totalAttendedClasses <= 2) {
      return 'Descansando 🪑';
    } else if (_totalAttendedClasses <= 5) {
      return 'Calentando 🚶';
    } else if (_totalAttendedClasses <= 8) {
      return 'En Movimiento 🏃';
    } else {
      return '¡Imparable! 🥊';
    }
  }

  // Color por tier del sistema de rangos.
  static const Map<String, Color> _tierColors = {
    'Nak Rian': Color(0xFFB08D57), // bronce/cobre real (no naranjo)
    'Nak Muay': Color(0xFFC0C0C0), // plateado
    'Nak Su': Color(0xFFFFD700), // dorado
    'Yod Muay': Color(0xFF7FDBFF), // celeste/diamante
  };

  Color _tierColor(String tier) => _tierColors[tier] ?? Colors.grey;

  Widget _buildRankBadge() {
    final rango = RankingService.rangoDesdeClases(_totalAttendedClasses);
    final color = _tierColor(rango.tier);
    // Borde, glow y texto en un tono un poco más claro que el base del tier
    // (p. ej. cobre claro sobre bronce) para asegurar contraste sobre fondo oscuro.
    final accent = Color.lerp(color, Colors.white, 0.25)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.military_tech, color: accent, size: 18),
          const SizedBox(width: 6),
          Text(
            rango.nombre,
            style: TextStyle(
              color: accent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankProgress() {
    const umbral = RankingService.clasesPorDivision;
    final progreso = RankingService.progresoEnDivision(_totalAttendedClasses);
    final siguiente = RankingService.siguienteRango(_totalAttendedClasses);
    final faltan =
        RankingService.clasesParaSiguienteRango(_totalAttendedClasses);
    final actual = RankingService.rangoDesdeClases(_totalAttendedClasses);
    final color = _tierColor((siguiente ?? actual).tier);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progreso',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$progreso/$umbral clases',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progreso / umbral,
            minHeight: 8,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          siguiente == null
              ? '¡Rango máximo alcanzado! 🏆'
              : 'Te faltan $faltan ${faltan == 1 ? 'clase' : 'clases'} para ${siguiente.nombre}',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRankMilestones() {
    final actual = RankingService.rangoDesdeClases(_totalAttendedClasses);
    final ventana = RankingService.ventanaDeRangos(_totalAttendedClasses);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ventana.map((rango) {
        final achieved = rango.index <= actual.index;
        final faltan = RankingService.clasesParaRango(rango.index) -
            _totalAttendedClasses;
        final color = achieved ? _tierColor(rango.tier) : Colors.grey.shade700;

        return Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: achieved
                      ? color.withValues(alpha: 0.2)
                      : Colors.grey.shade900,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: achieved ? color : Colors.grey.shade800,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.military_tech,
                  color: achieved ? color : Colors.grey.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                rango.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: achieved ? color : Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                achieved ? 'Obtenido' : 'Faltan $faltan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: achieved
                      ? color.withValues(alpha: 0.8)
                      : Colors.grey.shade700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF6A00),
              onPrimary: Colors.white,
              surface: Color(0xFF2A2A2A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  /// Flujo de eliminación de cuenta: confirmación en la app y luego
  /// confirmación definitiva por correo (el backend elimina la cuenta
  /// solo cuando el usuario abre el enlace enviado a su email).
  Future<void> _requestAccountDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '¿Eliminar tu cuenta?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esta acción es permanente: se borrarán tu perfil, tus clases '
          'agendadas, tu progreso y tu foto.\n\n'
          'Para confirmar, te enviaremos un correo con un enlace de '
          'eliminación (válido por 24 horas). Tu cuenta seguirá activa '
          'hasta que lo abras.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enviar correo de confirmación'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isRequestingDeletion = true);
    try {
      await AuthEmailService().requestAccountDeletion();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Te enviamos un correo para confirmar la eliminación. '
              'Revisa tu bandeja de entrada (y spam). El enlace dura 24 horas.',
            ),
            backgroundColor: Color(0xFFFF8534),
            duration: Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingDeletion = false);
      }
    }
  }

  Future<void> _uploadProfilePhoto() async {
    // Capturar auth y userId antes de cualquier operación asíncrona
    final auth = context.read<AuthViewModel>();
    final userId = auth.currentUser?.uid;

    // Las reglas de Storage exigen un usuario autenticado cuyo uid coincida
    // con el nombre del archivo: sin sesión no tiene sentido intentar subir.
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tu sesión expiró. Inicia sesión de nuevo para cambiar tu foto.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // En web, solo galería (la cámara requiere permisos especiales)
      final ImageSource source;
      if (kIsWeb) {
        source = ImageSource.gallery;
      } else {
        // Mostrar opciones: Cámara o Galería en móvil
        final selected = await showDialog<ImageSource>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'Seleccionar foto',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Color(0xFFFF6A00)),
                  title: const Text(
                    'Cámara',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Color(0xFFFF6A00)),
                  title: const Text(
                    'Galería',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
        if (selected == null) return;
        source = selected;
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return;

      setState(() {
        _isUploadingPhoto = true;
      });

      // Subir a Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('$userId.jpg');

      // Para web, usar bytes en lugar de File. En ambos casos se declara el
      // contentType: las reglas de Storage solo aceptan imágenes.
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        await storageRef.putFile(
          File(image.path),
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }

      // Obtener URL de descarga
      final downloadUrl = await storageRef.getDownloadURL();

      // Actualizar Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _photoUrl = downloadUrl;
          _isUploadingPhoto = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseException catch (e) {
      debugPrint('❌ FirebaseException subiendo foto: ${e.code} - ${e.message}');
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });

        final msg = switch (e.code) {
          'unauthorized' =>
            'No tienes permiso para subir esta foto. Vuelve a iniciar sesión e inténtalo de nuevo.',
          'canceled' => 'Subida cancelada.',
          'quota-exceeded' =>
            'No se pudo subir la foto por límite de almacenamiento. Inténtalo más tarde.',
          'retry-limit-exceeded' =>
            'La subida tardó demasiado. Revisa tu conexión e inténtalo de nuevo.',
          _ => 'No se pudo subir la foto, inténtalo de nuevo.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error inesperado subiendo foto: $e');
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo subir la foto, inténtalo de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFF6A00),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6A00),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: const Color(0xFFFF6A00),
              backgroundColor: const Color(0xFF1A1A1A),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar con foto de perfil
                    Center(
                      child: Stack(
                        children: [
                          ClipOval(
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: _photoUrl == null
                                    ? const LinearGradient(
                                        colors: [Color(0xFFFF6A00), Color(0xFFFF8C42)],
                                      )
                                    : null,
                                color: _photoUrl != null ? Colors.grey.shade300 : null,
                              ),
                              child: _photoUrl != null
                                  ? Image.network(
                                      _photoUrl!,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                            color: const Color(0xFFFF6A00),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.white,
                                        );
                                      },
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isUploadingPhoto ? null : _uploadProfilePhoto,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFF6A00),
                                  border: Border.all(
                                    color: const Color(0xFF0F0F0F),
                                    width: 2,
                                  ),
                                ),
                                child: _isUploadingPhoto
                                    ? const Padding(
                                        padding: EdgeInsets.all(6.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // COMMENTED OUT: Rive Avatar de progreso
                    /*
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFF6A00).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Título de la sección
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: Color(0xFFFF6A00),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Tu Progreso',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Avatar animado
                          AvatarProgressWidget(
                            totalClasses: _totalAttendedClasses,
                            size: 200,
                          ),

                          const SizedBox(height: 16),

                          // Contador de clases
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F0F0F),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getProgressColor().withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$_totalAttendedClasses',
                                  style: TextStyle(
                                    color: _getProgressColor(),
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _totalAttendedClasses == 1
                                      ? 'Clase Completada'
                                      : 'Clases Completadas',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getProgressMessage(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _getProgressColor(),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    */

                    // NEW: Pixel Art Fighter Avatar
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFF6A00).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Título de la sección
                          const Text(
                            'Tu Luchador',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Badge del rango actual (tier + división)
                          _buildRankBadge(),

                          const SizedBox(height: 16),

                          // Progreso hacia la siguiente división
                          _buildRankProgress(),

                          const SizedBox(height: 20),

                          // Contador de clases
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F0F0F),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getProgressColor().withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$_totalAttendedClasses',
                                  style: TextStyle(
                                    color: _getProgressColor(),
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _totalAttendedClasses == 1
                                      ? 'Clase Completada'
                                      : 'Clases Completadas',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getProgressMessage(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _getProgressColor(),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Próximos rangos a alcanzar
                          _buildRankMilestones(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Nombre (solo lectura)
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nombre',
                      icon: Icons.person,
                      enabled: false,
                    ),

                    const SizedBox(height: 16),

                    // Email (solo lectura)
                    _buildTextField(
                      controller: _emailController,
                      label: 'Correo Electrónico',
                      icon: Icons.email,
                      enabled: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El correo es requerido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Fecha de Nacimiento
                    InkWell(
                      onTap: _selectBirthDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white12,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cake,
                              color: Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _birthDate == null
                                    ? 'Seleccionar fecha de nacimiento'
                                    : DateFormat('dd/MM/yyyy').format(_birthDate!),
                                style: TextStyle(
                                  color: _birthDate == null
                                      ? Colors.white38
                                      : Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white38,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Dirección
                    _buildTextField(
                      controller: _addressController,
                      label: 'Dirección',
                      icon: Icons.home,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),

                    // Sección de cambio de contraseña
                    const Text(
                      'Cambiar Contraseña',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Deja en blanco si no deseas cambiar tu contraseña',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Nueva Contraseña
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Nueva Contraseña',
                      icon: Icons.lock,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white38,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Confirmar Contraseña
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirmar Nueva Contraseña',
                      icon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white38,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (_passwordController.text.isNotEmpty &&
                            value != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Botón Guardar Cambios
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6A00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade700,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'GUARDAR CAMBIOS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // Botón Cerrar Sesión
                    OutlinedButton.icon(
                      onPressed: auth.loading
                          ? null
                          : () async {
                              await context.read<AuthViewModel>().logout();

                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                      icon: auth.loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.red,
                              ),
                            )
                          : const Icon(Icons.logout),
                      label: Text(
                        auth.loading ? 'Cerrando sesión...' : 'Cerrar Sesión',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Zona de peligro: eliminación de cuenta
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Eliminar cuenta',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Se eliminarán permanentemente tu perfil, tus clases '
                            'agendadas y tu progreso. Te enviaremos un correo '
                            'para confirmar antes de borrar nada.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isRequestingDeletion
                                  ? null
                                  : _requestAccountDeletion,
                              icon: _isRequestingDeletion
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.red,
                                      ),
                                    )
                                  : const Icon(Icons.delete_forever, size: 18),
                              label: Text(
                                _isRequestingDeletion
                                    ? 'Enviando correo...'
                                    : 'Eliminar mi cuenta',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade400,
                                side: BorderSide(color: Colors.red.shade400),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool enabled = true,
    int maxLines = 1,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      maxLines: maxLines,
      style: TextStyle(
        color: enabled ? Colors.white : Colors.white38,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          color: enabled ? Colors.orange[600] : Colors.orange[900],
        ),
        prefixIcon: Icon(
          icon,
          color: enabled ? Colors.white70 : Colors.white38,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: enabled ? const Color(0xFF1A1A1A) : const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}
