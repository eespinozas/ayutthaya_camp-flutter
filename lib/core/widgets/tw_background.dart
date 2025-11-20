import 'package:flutter/material.dart';

class TwBackground extends StatelessWidget {
  final Widget child;
  final bool applyTextWhite;
  final bool expandChild;
  final bool useSafeArea;

  const TwBackground({
    super.key,
    required this.child,
    this.applyTextWhite = true,
    this.expandChild = false,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    Widget content = Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24), // p-6 pt-20
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [expandChild ? Expanded(child: child) : Center(child: child)],
      ),
    );

    if (useSafeArea) content = SafeArea(child: content);

    if (applyTextWhite) {
      content = DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: IconTheme(
          data: const IconThemeData(color: Colors.white),
          child: content,
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.black, Color(0xFF7C2D12)],
        ),
      ),
      child: content,
    );
  }
}
