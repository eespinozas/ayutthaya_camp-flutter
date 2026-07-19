import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_alumno_historial_page.dart';

class AdminAlumnosPage extends StatefulWidget {
  final VoidCallback onNavigateToPagos;

  const AdminAlumnosPage({super.key, required this.onNavigateToPagos});

  @override
  State<AdminAlumnosPage> createState() => _AdminAlumnosPageState();
}

class _AdminAlumnosPageState extends State<AdminAlumnosPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isRefreshing = false;

  /// Función para actualizar la lista
  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);

    // Esperar un momento para dar feedback visual
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _isRefreshing = false);

    // Mostrar mensaje de actualización
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Lista actualizada'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6A00), Color(0xFFFF8534)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6A00).withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.people_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Gestión de Alumnos',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
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
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFF6A00)),
              onPressed: _refreshData,
              tooltip: 'Actualizar',
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6A00)),
            );
          }

          final allUsers = snapshot.data?.docs ?? [];

          // Filtrar solo estudiantes (excluyendo admins)
          final studentUsers = allUsers.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final role = data['role'] ?? 'student';
            return role != 'admin';
          }).toList();

          // Más recientes primero (los registros nuevos quedan arriba)
          studentUsers.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final createdA = dataA['createdAt'] as Timestamp?;
            final createdB = dataB['createdAt'] as Timestamp?;
            if (createdA == null && createdB == null) return 0;
            if (createdA == null) return 1;
            if (createdB == null) return -1;
            return createdB.compareTo(createdA);
          });

          String statusOf(QueryDocumentSnapshot doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['membershipStatus'] ?? 'none';
          }

          final pendingUsers = studentUsers
              .where((doc) => statusOf(doc) == 'pending')
              .toList();

          final activeUsers = studentUsers
              .where((doc) => statusOf(doc) == 'active')
              .toList();

          // Membresías terminadas: el resto del código escribe
          // 'expired'/'frozen' (nunca 'inactive', que se mantiene por
          // compatibilidad con datos antiguos).
          const inactiveStatuses = {'inactive', 'expired', 'frozen'};
          final inactiveUsers = studentUsers
              .where((doc) => inactiveStatuses.contains(statusOf(doc)))
              .toList();

          // Registrados sin membresía ('none' y cualquier valor desconocido):
          // bucket residual para que ningún alumno quede invisible.
          final registeredUsers = studentUsers.where((doc) {
            final status = statusOf(doc);
            return status != 'pending' &&
                status != 'active' &&
                !inactiveStatuses.contains(status);
          }).toList();

          return RefreshIndicator(
            onRefresh: _refreshData,
            color: const Color(0xFFFF6A00),
            backgroundColor: const Color(0xFF1A1A1A),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildEnhancedStatCard(
                          label: 'Registrados',
                          value: '${registeredUsers.length}',
                          icon: Icons.person_add_alt_1_rounded,
                          gradientColors: const [
                            Color(0xFF3B82F6),
                            Color(0xFF2563EB),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildEnhancedStatCard(
                          label: 'Pendientes',
                          value: '${pendingUsers.length}',
                          icon: Icons.pending_actions_rounded,
                          gradientColors: const [
                            Color(0xFFF59E0B),
                            Color(0xFFEF4444),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildEnhancedStatCard(
                          label: 'Activos',
                          value: '${activeUsers.length}',
                          icon: Icons.check_circle_rounded,
                          gradientColors: const [
                            Color(0xFF10B981),
                            Color(0xFF059669),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildEnhancedStatCard(
                          label: 'Inactivos',
                          value: '${inactiveUsers.length}',
                          icon: Icons.cancel_rounded,
                          gradientColors: const [
                            Color(0xFF6B7280),
                            Color(0xFF4B5563),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Usuarios registrados sin membresía (incluye a los nuevos)
                  if (registeredUsers.isNotEmpty) ...[
                    const Text(
                      'Registrados (sin membresía)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...registeredUsers.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      return _UserCard(
                        userId: doc.id,
                        name: _nameOf(data),
                        email: data['email'] as String? ?? 'Sin email',
                        status: 'registered',
                        createdAt: data['createdAt'] as Timestamp?,
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // Usuarios pendientes
                  if (pendingUsers.isNotEmpty) ...[
                    const Text(
                      'Usuarios Pendientes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...pendingUsers.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      return _UserCard(
                        userId: doc.id,
                        name: _nameOf(data),
                        email: data['email'] as String? ?? 'Sin email',
                        status: 'pending',
                        onActivate: () => _goToPagosToActivate(data),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // Usuarios activos
                  if (activeUsers.isNotEmpty) ...[
                    const Text(
                      'Usuarios Activos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...activeUsers.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      return _UserCard(
                        userId: doc.id,
                        name: _nameOf(data),
                        email: data['email'] as String? ?? 'Sin email',
                        status: 'active',
                        expirationDate: data['expirationDate'],
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // Usuarios inactivos
                  if (inactiveUsers.isNotEmpty) ...[
                    const Text(
                      'Usuarios Inactivos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...inactiveUsers.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      return _UserCard(
                        userId: doc.id,
                        name: _nameOf(data),
                        email: data['email'] as String? ?? 'Sin email',
                        status: 'inactive',
                        expirationDate: data['expirationDate'],
                      );
                    }),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedStatCard({
    required String label,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// Nombre a mostrar: el campo `name` del doc de usuario (se guarda en el
  /// registro) o, si viene vacío, la parte local del email.
  String _nameOf(Map<String, dynamic> data) {
    final name = (data['name'] as String?)?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final email = data['email'] as String? ?? '';
    return email.contains('@') ? email.split('@')[0] : 'Sin nombre';
  }

  void _goToPagosToActivate(Map<String, dynamic> userData) {
    final userName = userData['name'] ?? 'Usuario';
    final email = userData['email'] ?? 'Sin email';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFFFF6A00)),
            SizedBox(width: 12),
            Text('Ir a Pagos', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El usuario $userName ya ha enviado un pago.',
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6A00).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF6A00).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Para activar al usuario:',
                    style: TextStyle(
                      color: Color(0xFFFF6A00),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Ve a la pestaña "Pagos"\n2. Encuentra el pago de $userName\n3. Revisa el comprobante\n4. Aprueba o rechaza el pago',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$email',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              widget.onNavigateToPagos();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A00),
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.payment, size: 18),
            label: const Text('Ir a Pagos'),
          ),
        ],
      ),
    );
  }
}

// Card de alumno; el nombre viene directo del documento de usuario.
// Tocar la card abre el historial de clases del alumno.
class _UserCard extends StatelessWidget {
  final String userId;
  final String name;
  final String email;
  final String status; // 'registered', 'pending', 'active', 'inactive'
  final Timestamp? expirationDate;
  final Timestamp? createdAt;
  final VoidCallback? onActivate;

  const _UserCard({
    required this.userId,
    required this.name,
    required this.email,
    required this.status,
    this.expirationDate,
    this.createdAt,
    this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    final Widget card;
    switch (status) {
      case 'pending':
        card = _buildPendingCard(name);
        break;
      case 'active':
        card = _buildActiveCard(name);
        break;
      case 'inactive':
        card = _buildInactiveCard(name);
        break;
      default:
        card = _buildRegisteredCard(name);
    }

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminAlumnoHistorialPage(
            userId: userId,
            userName: name,
            userEmail: email,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: card,
    );
  }

  Widget _buildRegisteredCard(String name) {
    String registeredText = '';
    if (createdAt != null) {
      final date = createdAt!.toDate();
      registeredText = 'Registro: ${date.day}/${date.month}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_outline, color: Color(0xFF3B82F6)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'REGISTRADO',
                        style: TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (registeredText.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text(
                        registeredText,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_outline, color: Colors.orange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PENDIENTE',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onActivate != null)
            Builder(
              builder: (context) => ElevatedButton.icon(
                onPressed: onActivate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(Icons.payment, size: 16),
                label: const Text('Ver Pago', style: TextStyle(fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveCard(String name) {
    // Sin expirationDate = activo por acceso libre (sin membresía pagada)
    String expirationText = 'Sin vencimiento';
    if (expirationDate != null) {
      final date = expirationDate!.toDate();
      expirationText = '${date.day}/${date.month}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_circle, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vence: $expirationText',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveCard(String name) {
    String expirationText = 'Sin fecha';
    if (expirationDate != null) {
      final date = expirationDate!.toDate();
      expirationText = '${date.day}/${date.month}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.cancel_outlined, color: Colors.red),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'INACTIVO',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Venció: $expirationText',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
