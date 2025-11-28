import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAlumnosPage extends StatefulWidget {
  final VoidCallback onNavigateToPagos;

  const AdminAlumnosPage({
    super.key,
    required this.onNavigateToPagos,
  });

  @override
  State<AdminAlumnosPage> createState() => _AdminAlumnosPageState();
}

class _AdminAlumnosPageState extends State<AdminAlumnosPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Gestión de Alumnos',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
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
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            );
          }

          final allUsers = snapshot.data?.docs ?? [];

          // Filtrar solo estudiantes (excluyendo admins)
          final studentUsers = allUsers.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final role = data['role'] ?? 'student';
            return role != 'admin';
          }).toList();

          final pendingUsers = studentUsers
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['membershipStatus'] ?? 'none';
                return status == 'pending' || status == 'none';
              })
              .toList();

          final activeUsers = studentUsers
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['membershipStatus'] ?? 'none';
                return status == 'active';
              })
              .toList();

          final inactiveUsers = studentUsers
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['membershipStatus'] ?? 'none';
                return status == 'inactive';
              })
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        label: 'Pendientes',
                        value: '${pendingUsers.length}',
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        label: 'Activos',
                        value: '${activeUsers.length}',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        label: 'Inactivos',
                        value: '${inactiveUsers.length}',
                        icon: Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

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
                    final email = data['email'] as String?;

                    return _UserCardWithName(
                      userId: doc.id,
                      email: email ?? 'Sin email',
                      status: 'pending',
                      onActivate: () => _goToPagosToActivate(data),
                    );
                  }).toList(),
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
                    final email = data['email'] as String?;

                    return _UserCardWithName(
                      userId: doc.id,
                      email: email ?? 'Sin email',
                      status: 'active',
                      expirationDate: data['expirationDate'],
                    );
                  }).toList(),
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
                    final email = data['email'] as String?;

                    return _UserCardWithName(
                      userId: doc.id,
                      email: email ?? 'Sin email',
                      status: 'inactive',
                      expirationDate: data['expirationDate'],
                    );
                  }).toList(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _goToPagosToActivate(Map<String, dynamic> userData) {
    final userName = userData['name'] ?? 'Usuario';
    final email = userData['email'] ?? 'Sin email';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orangeAccent),
            SizedBox(width: 12),
            Text(
              'Ir a Pagos',
              style: TextStyle(color: Colors.white),
            ),
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
                color: Colors.orangeAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Para activar al usuario:',
                    style: TextStyle(
                      color: Colors.orangeAccent,
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
              backgroundColor: Colors.orangeAccent,
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

// Widget que obtiene el nombre del usuario desde bookings
class _UserCardWithName extends StatelessWidget {
  final String userId;
  final String email;
  final String status; // 'pending', 'active', 'inactive'
  final Timestamp? expirationDate;
  final VoidCallback? onActivate;

  const _UserCardWithName({
    required this.userId,
    required this.email,
    required this.status,
    this.expirationDate,
    this.onActivate,
  });

  Future<String> _getUserName() async {
    try {
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (bookingsSnapshot.docs.isNotEmpty) {
        final booking = bookingsSnapshot.docs.first.data();
        final userName = booking['userName'] as String?;
        if (userName != null && userName.isNotEmpty) {
          return userName;
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo userName de bookings: $e');
    }

    // Fallback: usar parte del email antes del @
    return email.split('@')[0];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getUserName(),
      builder: (context, snapshot) {
        // Esperar a que cargue el nombre antes de mostrar el card
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Mostrar un placeholder mientras carga
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_outline, color: Colors.white30, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 180,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final name = snapshot.data ?? email.split('@')[0];

        switch (status) {
          case 'pending':
            return _buildPendingCard(name);
          case 'active':
            return _buildActiveCard(name);
          case 'inactive':
            return _buildInactiveCard(name);
          default:
            return _buildPendingCard(name);
        }
      },
    );
  }

  Widget _buildPendingCard(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
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
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
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
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    String expirationText = 'Sin fecha';
    if (expirationDate != null) {
      final date = expirationDate!.toDate();
      expirationText =
          '${date.day}/${date.month}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
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
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vence: $expirationText',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
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
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
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
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
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
