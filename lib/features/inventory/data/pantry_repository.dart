import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/product_entity.dart';

// Este Provider nos permite acceder al repositorio desde cualquier pantalla
final pantryRepositoryProvider = Provider((ref) => PantryRepository());

class PantryRepository {
  // Instancia de la base de datos
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Nombre de la colección en la nube (como una carpeta)
  final String _collection = 'users_pantry';

  // --- FUNCION PARA GUARDAR ---
  Future<void> addProduct(ProductEntity product) async {
    try {
      // Guardamos en: users_pantry -> [ID del producto] -> [Datos]
      await _db.collection(_collection).doc(product.id).set(product.toMap());
      print("✅ Producto guardado en la nube: ${product.name}");
    } catch (e) {
      print("❌ Error guardando producto: $e");
      rethrow;
    }
  }

  // --- FUNCION PARA LEER (La usaremos luego) ---
  Stream<List<ProductEntity>> getPantry() {
    return _db.collection(_collection).orderBy('expirationDate').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductEntity.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}