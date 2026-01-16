import 'dart:io'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/entities/product_entity.dart';
import '../../../../core/services/notification_service.dart';


// --- PROVIDER ---
// Este Provider ahora inyecta dinámicamente el UID del usuario en el repositorio.
final pantryRepositoryProvider = Provider<PantryRepository>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final user = authRepo.currentUser;

  // Si no hay usuario, lanzamos excepción.
  // (La UI debería prevenir esto gracias al AuthGate, pero es buena práctica defensiva)
  if (user == null) {
      throw Exception("Intento de acceso a Alacena sin usuario autenticado.");
  }

  return PantryRepository(uid: user.uid);
});

// --- REPOSITORIO ---
class PantryRepository {
  // Instancia de la base de datos
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // El ID del usuario dueño de esta alacena
  final String uid;

  PantryRepository({required this.uid});

  // Getter para obtener la referencia a la colección privada:
  // Ruta: users -> [ID Usuario] -> pantry
  CollectionReference get _userPantry => _db
      .collection('users')
      .doc(uid)
      .collection('pantry');

  // --- FUNCION PARA GUARDAR ---
  Future<void> addProduct(ProductEntity product) async {
    try {
      // Guardamos en la ruta privada usando el ID del producto
      await _userPantry.doc(product.id).set(product.toMap());
      print("✅ Producto guardado en alacena de ($uid): ${product.name}");
    } catch (e) {
      print("❌ Error guardando producto: $e");
      rethrow;
    }
  }

  // --- FUNCION PARA LEER ---
  Stream<List<ProductEntity>> getPantry() {
    // Escuchamos solo la colección del usuario actual
    return _userPantry.orderBy('expirationDate').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Convertimos los datos de Firestore a nuestra entidad
        final data = doc.data() as Map<String, dynamic>;
        return ProductEntity.fromMap(data, doc.id);
      }).toList();
    });
  }
  // --- FUNCION PARA BORRAR ---
  Future<void> deleteProduct(String productId) async {
    try {
      await _userPantry.doc(productId).delete();
      
      // Cancelar notificaciones asociadas
      try {
        await NotificationService().cancelNotifications(productId);
      } catch (_) {}

      print("🗑️ Producto eliminado: $productId");
    } catch (e) {
      print("❌ Error eliminando producto: $e");
      rethrow;
    }
  }
}