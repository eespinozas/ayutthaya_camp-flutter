import 'package:flutter/material.dart';

class AccountActivationCard extends StatelessWidget {
  final VoidCallback onActivate;

  const AccountActivationCard({
    super.key,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    // Colores base: ajusta a tu theme si ya tienes un color brand
    final bg = Colors.amber.shade100;
    final border = Colors.amber.shade400;
    final iconColor = Colors.amber.shade800;
    final textColor = Colors.amber.shade900;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header row con icono + título
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_rounded, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tu cuenta no está activa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // descripción
          Text(
            'Para poder reservar clases y completar tu perfil, primero debes matricularte y subir tu comprobante de pago.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: textColor,
            ),
          ),

          const SizedBox(height: 16),

          // botón de acción
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onActivate,
              child: const Text(
                'Matricularme ahora',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
