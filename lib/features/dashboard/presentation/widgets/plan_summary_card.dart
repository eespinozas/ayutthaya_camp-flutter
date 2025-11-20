import 'package:flutter/material.dart';

class PlanSummaryCard extends StatelessWidget {
  final String planName;
  final String clasesRestantes;
  final String vigencia;
  final String estado;
  final Color estadoColor;

  const PlanSummaryCard({
    super.key,
    required this.planName,
    required this.clasesRestantes,
    required this.vigencia,
    required this.estado,
    this.estadoColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70);
    final valueStyle = Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.white);

    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.70), borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth < 420 ? 1 : (c.maxWidth < 840 ? 2 : 4);
        const spacing = 12.0;
        final tileW = (c.maxWidth - (cols - 1) * spacing) / cols;

        Widget tile({required double width, required IconData icon, required String label, required String value, Widget? trailing}) {
          return SizedBox(
            width: width,
            child: Row(children: [
              Icon(icon, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(label, style: labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(value, style: valueStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing],
            ]),
          );
        }

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            tile(
              width: tileW,
              icon: Icons.assignment,
              label: 'Plan',
              value: planName,
              trailing: _statusPill(estado, estadoColor),
            ),
            tile(width: tileW, icon: Icons.fitness_center, label: 'Clases restantes', value: clasesRestantes),
            tile(width: tileW, icon: Icons.schedule, label: 'Vigencia', value: vigencia),
          ],
        );
      }),
    );
  }

  Widget _statusPill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      );
}
