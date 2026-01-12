import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';

void main() {
  runApp(
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
      debugShowCheckedModeBanner: false,

      // CORRECCIÓN AQUÍ:
      // Cambiamos .lightTheme por .darkTheme para que coincida con tu nuevo archivo de estilos
      theme: AppTheme.darkTheme,

      home: const HomeScreen(),
    );
  }
}