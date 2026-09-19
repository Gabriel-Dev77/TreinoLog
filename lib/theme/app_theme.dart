import 'package:flutter/material.dart';

// Centraliza as decisões visuais do app num só lugar:
// cores com bom contraste, tamanhos mínimos de toque e tipografia legível.
class AppTheme {
  // Tamanho mínimo recomendado para alvos de toque (Lei de Fitts).
  // As diretrizes de acessibilidade do Material Design recomendam 48x48.
  static const double minTouchTarget = 48.0;

  // Paleta com contraste verificado sobre fundo claro
  static const Color primary = Color(0xFF0B5FA5);      // azul escuro
  static const Color primaryDark = Color(0xFF083D6B);
  static const Color accent = Color(0xFF0277BD);
  static const Color success = Color(0xFF1B5E20);      // verde escuro
  static const Color error = Color(0xFFB00020);
  static const Color textPrimary = Color(0xFF1A1A1A);  // quase preto
  static const Color textSecondary = Color(0xFF4A4A4A);// cinza escuro legível
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Colors.white;

  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        error: error,
        surface: surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,

      // Tipografia com tamanhos legíveis (mínimo 14, corpo 16)
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 15, color: textPrimary),
        bodySmall: TextStyle(fontSize: 14, color: textSecondary),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // Botões grandes o suficiente para toque confortável
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          foregroundColor: primaryDark,
          side: const BorderSide(color: primary, width: 1.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        labelStyle: const TextStyle(fontSize: 15, color: textSecondary),
        floatingLabelStyle: const TextStyle(fontSize: 15, color: primaryDark),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: TextStyle(fontSize: 15, color: Colors.white),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 13),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}