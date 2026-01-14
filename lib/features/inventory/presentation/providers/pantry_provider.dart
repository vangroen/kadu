import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/pantry_repository.dart';
import '../../domain/entities/product_entity.dart';

final pantryListProvider = StreamProvider<List<ProductEntity>>((ref) {
  // Al leer este provider, Riverpod busca el repositorio asociado al usuario actual
  final repository = ref.watch(pantryRepositoryProvider);
  return repository.getPantry();
});