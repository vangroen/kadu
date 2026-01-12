import 'package:flutter/material.dart';

class AppColors {
  // Colores Principales (Brand)
  static const Color primary = Color(0xFF2E7D32); // Verde Bosque (Serio pero fresco)
  static const Color secondary = Color(0xFF81C784); // Verde suave (Accentos)

  // Colores Semánticos (Estado de la comida)
  static const Color fresh = Color(0xFF4CAF50);    // Comida en buen estado
  static const Color warning = Color(0xFFFFC107);  // Por vencer (Amarillo ámbar)
  static const Color expired = Color(0xFFE53935);  // Vencido (Rojo alerta)

  // Fondos y Textos
  static const Color background = Color(0xFFF5F7FA); // Gris muy clarito (Más moderno que blanco puro)
  static const Color surface = Colors.white;         // Tarjetas
  static const Color textPrimary = Color(0xFF1A1A1A); // Casi negro (Mejor lectura)
  static const Color textSecondary = Color(0xFF757575); // Gris medio
}