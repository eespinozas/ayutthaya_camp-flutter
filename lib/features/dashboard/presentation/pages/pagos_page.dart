import 'package:flutter/material.dart';

class PagosPage extends StatelessWidget {
  const PagosPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ejemplo estático. Después lo cambias por datos reales desde tu backend
    final pagos = [
      {
        'monto': 35000,
        'plan': 'Plan 3x Semana',
        'estado': 'Pagado',
        'fecha': '2025-10-01',
      },
      {
        'monto': 20000,
        'plan': 'Plan 2x Semana',
        'estado': 'Pendiente',
        'fecha': '2025-09-15',
      },
      {
        'monto': 50000,
        'plan': 'Plan Ilimitado',
        'estado': 'Pagado',
        'fecha': '2025-09-01',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Historial de Pagos',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: pagos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final pago = pagos[index];

          final monto = pago['monto'];
          final plan = pago['plan'];
          final estado = pago['estado'];
          final fecha = pago['fecha'];

          // color chip de estado
          final bool pagado = (estado == 'Pagado');
          final Color chipColor = pagado ? Colors.green.shade600 : Colors.amber.shade700;

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // primera fila -> monto + estado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$$monto',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: chipColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$estado',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // plan
                Text(
                  '$plan',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                // fecha compra
                Text(
                  'Fecha: $fecha',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
