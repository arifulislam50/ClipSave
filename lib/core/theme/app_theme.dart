import 'package:flutter/material.dart';

/// Material 3 light and dark themes generated from one seed colour.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF3D5AFE);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// Palette used for folder colours.
  static const List<Color> folderColors = [
    Color(0xFF3D5AFE),
    Color(0xFF00897B),
    Color(0xFFF4511E),
    Color(0xFF8E24AA),
    Color(0xFFFFB300),
    Color(0xFF039BE5),
    Color(0xFFD81B60),
    Color(0xFF7CB342),
  ];
}
