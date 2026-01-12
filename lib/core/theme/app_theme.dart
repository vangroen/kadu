import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark, // Modo oscuro activado
      scaffoldBackgroundColor: AppColors.background,

      // Colores principales
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.cardSurface,
        onSurface: AppColors.textWhite,
        error: AppColors.alertRed,
      ),

      // Estilo de las Tarjetas (Bordes redondeados suaves)
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0, // Diseño plano (Flat)
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Fuente (opcional, usa la por defecto por ahora)
      fontFamily: 'Roboto',
    );
  }
}