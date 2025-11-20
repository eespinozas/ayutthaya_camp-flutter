import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ayutthaya_camp/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ayutthaya_camp/features/auth/presentation/pages/login_page.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.currentUser;

    return Container(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // “AppBar” manual dentro del contenido
            const Text(
              'Mi Perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Card con datos del usuario
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Datos del alumno',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white70),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user?.email ?? 'Sin correo',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (user?.uid != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.badge,
                          color: Colors.white38,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ID: ${user!.uid}',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Próximamente podrás editar tus datos personales y contraseña desde aquí.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),

            const Spacer(),

            if (auth.error != null) ...[
              Text(
                auth.error!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: auth.loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.logout),
                label: Text(
                  auth.loading ? 'Cerrando sesión...' : 'Cerrar sesión',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: auth.loading
                    ? null
                    : () async {
                        await context.read<AuthViewModel>().logout();

                        // limpiamos el stack y vamos a LoginPage
                        // ignore: use_build_context_synchronously
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginPage(),
                          ),
                          (route) => false,
                        );
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
