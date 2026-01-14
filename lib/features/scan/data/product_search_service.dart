import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productSearchServiceProvider = Provider((ref) => ProductSearchService());

class ProductSearchService {
  // CORRECCIÓN: URL base correcta sin etiquetas extrañas y con "product" completo.
  // Usamos la versión v2 de la API que es más robusta, aunque la v0 sigue funcionando.
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v0/product';

  Future<String?> getProductName(String barcode) async {
    try {
      final url = Uri.parse('$_baseUrl/$barcode.json');
      print("🔍 Buscando producto: $url");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Verificamos si el producto fue encontrado (status 1 = encontrado)
        if (data['status'] == 1) {
          final product = data['product'];
          // Intentamos obtener el nombre en español, o el genérico, o el inglés
          final String? nameEs = product['product_name_es'];
          final String? name = product['product_name'];
          final String? nameEn = product['product_name_en'];

          final foundName = nameEs ?? name ?? nameEn;

          if (foundName != null && foundName.isNotEmpty) {
            print("✅ Producto encontrado: $foundName");
            return foundName;
          }
        } else {
          print("⚠️ Producto no encontrado en OpenFoodFacts (Status: ${data['status_verbose']})");
        }
      } else {
        print("❌ Error en API: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error de conexión: $e");
    }
    return null; // Si falla o no encuentra, devuelve null
  }
}