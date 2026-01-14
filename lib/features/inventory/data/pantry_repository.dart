import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/product_entity.dart';

// Este provider ahora es inteligente: detecta quién es el usuario actual
final pantryRepositoryProvider = Provider<PantryRepository>((ref) {
  // Obtenemos el usuario logueado directamente de Firebase
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception("No hay usuario logueado para acceder a la alacena");
  }
  return PantryRepository(userId: user.uid);
});

class PantryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId; // El ID del dueño de los datos

  PantryRepository({required this.userId});

  // Ahora la colección es privada: users -> [ID] -> pantry
  CollectionReference get _userPantry =>
      _db.collection('users').doc(userId).collection('pantry');

  // --- GUARDAR (Privado) ---
  Future<void> addProduct(ProductEntity product) async {
    try {
      await _userPantry.doc(product.id).set(product.toMap());
      print("✅ Producto guardado en la alacena de $userId");
    } catch (e) {
      print("❌ Error guardando: $e");
      rethrow;
    }
  }

  // --- LEER (Privado) ---
  Stream<List<ProductEntity>> getPantry() {
    return _userPantry.orderBy('expirationDate').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Aseguramos que el mapa sea Map<String, dynamic>
        final data = doc.data() as Map<String, dynamic>;
        return ProductEntity.fromMap(data, doc.id);
      }).toList();
    });
  }

  // --- BORRAR (Privado) ---
  Future<void> deleteProduct(String productId) async {
    await _userPantry.doc(productId).delete();
  }
}