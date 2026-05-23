import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFFF4F7FA);

  static const Color primary = Color(0xFF2F6F8F);
  static const Color primaryDark = Color(0xFF174A63);
  static const Color secondary = Color(0xFF5FA8A3);
  static const Color accent = Color(0xFFF2A65A);
  static const Color success = Color(0xFF4CAF88);

  static const Color textDark = Color(0xFF203040);
  static const Color textMuted = Color(0xFF667085);
  static const Color softBlue = Color(0xFFE3F1F5);
  static const Color softGreen = Color(0xFFE7F6F2);
  static const Color softOrange = Color(0xFFFFF1E3);
  static const Color lightText = Color(0xFF98A2B3);

  static ThemeData lightTheme = ThemeData(
    fontFamily: 'Arial',
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textDark,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: softBlue,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
