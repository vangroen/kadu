import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/data/auth_repository.dart';
import 'core/services/notification_service.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar Notificaciones
  await NotificationService().init();
  await NotificationService().requestPermissions(); // Pedir permisos al inicio (Android 13+)

  runApp(
    const ProviderScope(
      child: KaduApp(),
    ),
  );
}

class KaduApp extends ConsumerWidget {
  const KaduApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos el estado de autenticación
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Kadu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,

      // --- AUTH GATE ---
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const HomeScreen(); // Usuario logueado -> Home
          }
          return const LoginScreen(); // Usuario desconocido -> Login
        },
        loading: () => const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: Color(0xFF27E374))),
        ),
        error: (e, stack) => Scaffold(
          body: Center(child: Text('Error fatal: $e')),
        ),
      ),
    );
  }
}