import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Proveedor global para acceder a este repositorio
final authRepositoryProvider = Provider((ref) => AuthRepository());

// Proveedor que nos dice EN TIEMPO REAL si hay alguien logueado o no
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // CORRECCIÓN: Inicializamos GoogleSignIn con scopes vacíos.
  // Esto evita el error del constructor y es compatible con versiones recientes.
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: []);

  // Escuchar si el usuario entra o sale (Stream)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // --- LOGIN CON GOOGLE ---
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Inicia el flujo interactivo (ventana de Google)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Si el usuario cancela la ventana, no hacemos nada
      if (googleUser == null) return null;

      // 2. Obtiene los tokens de acceso
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Crea la credencial para Firebase con esos tokens
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Inicia sesión en Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print("Error en Google Sign-In: $e");
      rethrow;
    }
  }

  // --- CERRAR SESIÓN ---
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print("Error cerrando sesión de Google (no crítico): $e");
    }
    await _auth.signOut();
  }
}