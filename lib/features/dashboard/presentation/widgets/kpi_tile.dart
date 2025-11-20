import 'package:flutter/material.dart';

class KpiTile extends StatelessWidget {
  final Color color;
  final String title;
  final String value;
  const KpiTile({super.key, required this.color, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 72,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}
