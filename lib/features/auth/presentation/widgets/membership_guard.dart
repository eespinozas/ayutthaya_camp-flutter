import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../viewmodels/auth_viewmodel.dart';

/// Widget que valida la membresía antes de mostrar contenido protegido
class MembershipGuard extends StatelessWidget {
  final Widget child;
  final String pageName; // "Agendar", "Mis Clases", "Pagos"

  const MembershipGuard({
    super.key,
    required this.child,
    required this.pageName,
  });

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    // Si es admin, no validar membresía
    if (authVM.isAdmin) {
      return child;
    }

    // Si tiene membresía activa, mostrar contenido
    if (authVM.hasActiveMembership) {
      return child;
    }

    // Si no tiene membresía activa, mostrar pantalla bloqueada
    return _buildBlockedScreen(context, authVM);
  }

  Widget _buildBlockedScreen(BuildContext context, AuthViewModel authVM) {
    IconData icon;
    String title;
    String message;
    Color iconColor;

    if (authVM.needsEnrollment) {
      // Usuario no matriculado
      icon = Icons.how_to_reg;
      iconColor = Colors.orangeAccent;
      title = 'Matrícula Requerida';
      message = 'Para acceder a $pageName necesitas estar matriculado.\n\n'
          'Usa la barra de navegación inferior para ir a "Pagos" y completa tu matrícula para empezar a entrenar.';
    } else if (authVM.isMembershipExpired) {
      // Membresía expirada
      icon = Icons.event_busy;
      iconColor = Colors.red;
      title = 'Membresía Expirada';
      message = 'Tu membresía ha expirado.\n\n'
          'Usa la barra de navegación inferior para ir a "Pagos" y renovar tu plan para continuar entrenando.';

      if (authVM.expirationDate != null) {
        final formattedDate = DateFormat('dd/MM/yyyy').format(authVM.expirationDate!);
        message += '\n\nExpiró el: $formattedDate';
      }
    } else if (authVM.membershipStatus == 'pending') {
      // Pago pendiente
      icon = Icons.pending_actions;
      iconColor = Colors.orange;
      title = 'Pago Pendiente';
      message = 'Tu pago está siendo verificado.\n\n'
          'Una vez aprobado por el administrador, podrás acceder a todas las funciones.';
    } else {
      // Frozen u otro estado
      icon = Icons.block;
      iconColor = Colors.grey;
      title = 'Acceso Restringido';
      message = 'Tu membresía está en estado: ${authVM.membershipStatus}.\n\n'
          'Contacta al administrador para más información.';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(
          pageName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícono
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 80,
                  color: iconColor,
                ),
              ),

              const SizedBox(height: 32),

              // Título
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Mensaje
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Botón para refrescar estado (solo si tiene pago pendiente)
              if (authVM.membershipStatus == 'pending') ...[
                // Botón para refrescar estado
                OutlinedButton.icon(
                  onPressed: () async {
                    await authVM.refreshMembershipStatus();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            authVM.hasActiveMembership
                                ? '¡Membresía activada!'
                                : 'Estado actualizado: ${authVM.membershipStatus}',
                          ),
                          backgroundColor: authVM.hasActiveMembership
                              ? Colors.green
                              : Colors.orange,
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orangeAccent,
                    side: const BorderSide(color: Colors.orangeAccent),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Actualizar Estado',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
