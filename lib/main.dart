import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart'; // <--- Importante
import 'firebase_options.dart'; // <--- El archivo que acabas de generar
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';

// Convertimos el main en asíncrono para esperar a Firebase
Future<void> main() async {
  // 1. Asegura que el motor gráfico esté listo
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Conecta con la Nube usando la configuración de Android que creaste
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Arranca la App
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

      // Tu tema oscuro profesional
      theme: AppTheme.darkTheme,

      home: const HomeScreen(),
    );
  }
}