import 'package:cloud_firestore/cloud_firestore.dart';

class ProductEntity {
  final String id;
  final String name;
  final String? barcode; // Nuevo campo para código de barras
  final DateTime expirationDate;
  final DateTime addedDate;
  final String? category;
  final String? imageUrl; // URL de la imagen en Firebase Storage
  final int quantity;

  ProductEntity({
    required this.id,
    required this.name,
    this.barcode,
    required this.expirationDate,
    required this.addedDate,
    this.category = 'General',
    this.imageUrl, // Opcional
    this.quantity = 1,
  });

  // --- 1. CONVERTIR A FIREBASE (Escritura) ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      // Firebase guarda fechas como Timestamp
      'expirationDate': Timestamp.fromDate(expirationDate),
      'addedDate': Timestamp.fromDate(addedDate),
      'category': category,
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }

  // --- 2. LEER DE FIREBASE (Lectura) ---
  factory ProductEntity.fromMap(Map<String, dynamic> map, String docId) {
    return ProductEntity(
      id: docId, // El ID viene del nombre del documento en Firebase
      name: map['name'] ?? 'Sin nombre',
      barcode: map['barcode'],
      // Convertimos Timestamp de vuelta a DateTime
      expirationDate: (map['expirationDate'] as Timestamp).toDate(),
      addedDate: (map['addedDate'] as Timestamp).toDate(),
      category: map['category'] ?? 'General',
      imageUrl: map['imageUrl'],
      quantity: map['quantity'] ?? 1,
    );
  }
}