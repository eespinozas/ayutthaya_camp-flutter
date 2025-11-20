import 'package:flutter/material.dart';

class AppTheme {
  static const _orange = Color(0xFFFF6A00);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _orange,
        brightness: Brightness.light,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _orange,
        brightness: Brightness.dark,
      );
}
