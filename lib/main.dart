import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';

void main() {
  runApp(
    // ProviderScope es OBLIGATORIO para usar Riverpod.
    // Es el contenedor que guarda el estado de toda la app.
    const ProviderScope(
      child: KaduApp(),
    ),
  );
}

class KaduApp extends StatelessWidget {
  const KaduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kadu',
      debugShowCheckedModeBanner: false, // Quitamos la etiqueta "Debug"

      // Aquí conectamos nuestro diseño profesional
      theme: AppTheme.lightTheme,

      // AHORA SÍ: Usamos la pantalla principal con navegación
      home: const HomeScreen(),
    );
  }
}