import 'package:flutter/material.dart';

class OrDivider extends StatelessWidget {
  final String text;
  const OrDivider({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline.withOpacity(0.5);
    return Row(
      children: [
        Expanded(child: Divider(color: color, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Divider(color: color, thickness: 1)),
      ],
    );
  }
}
