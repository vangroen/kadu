import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/pantry_repository.dart';
import '../../domain/entities/product_entity.dart';

// Este provider escucha el flujo de datos (Stream) de Firebase.
// Si algo cambia en la nube, este provider se actualiza solo.
final pantryListProvider = StreamProvider<List<ProductEntity>>((ref) {
  // 1. Obtenemos el repositorio
  final repository = ref.read(pantryRepositoryProvider);

  // 2. Pedimos la lista en tiempo real
  return repository.getPantry();
});