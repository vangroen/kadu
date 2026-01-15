import 'dart:io'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/product_entity.dart';

// --- PROVIDER ---
// Este Provider ahora inyecta dinámicamente el UID del usuario en el repositorio.
final pantryRepositoryProvider = Provider<PantryRepository>((ref) {
  // TODO: Cuando conectes el AuthRepository real, usa esto:
  // final user = ref.watch(authProvider).currentUser;
  // if (user == null) throw Exception("Debes iniciar sesión");
  // return PantryRepository(uid: user.uid);

  // TEMPORAL: Usamos un ID fijo para desarrollo local.
  // Esto aísla tus pruebas de las de otros desarrolladores/usuarios.
  return PantryRepository(uid: 'test_user_dev_1');
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
}