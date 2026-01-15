import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/pantry_repository.dart';
import '../providers/pantry_provider.dart';

class PantryScreen extends ConsumerWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos al proveedor de la lista
    final pantryAsync = ref.watch(pantryListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Mi Alacena 📦"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      // Riverpod maneja los 3 estados: Cargando, Error y Datos Listos
      body: pantryAsync.when(
        // 1. CARGANDO...
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),

        // 2. ERROR ❌
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),

        // 3. DATOS LISTOS ✅
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text("Tu alacena está vacía 🍃", style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              // Tarjeta del Producto (Deslizar para borrar)
              return Dismissible(
                key: Key(product.id ?? UniqueKey().toString()), // Aseguramos key única
                direction: DismissDirection.horizontal,
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  // 1. Borrar visualmente y en BD
                  ref.read(pantryRepositoryProvider).deleteProduct(product.id);

                  // 2. Feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('🗑️ ${product.name} eliminado')),
                  );
                },
                child: Card(
                  color: AppColors.cardSurface,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Container(
                      padding: product.imageUrl == null ? const EdgeInsets.all(10) : EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
                            _showImagePreview(context, product.imageUrl!);
                          }
                        },
                        child: _buildProductImage(product.imageUrl),
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Vence: ${DateFormat('dd/MM/yyyy').format(product.expirationDate)}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Text(
                      "x${product.quantity}",
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }



  // Helper para obtener el proveedor de imagen (lo reusamos para el modal)
  ImageProvider? _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    }
    try {
      return MemoryImage(base64Decode(imageUrl));
    } catch (_) {
      return null;
    }
  }

  Widget _buildProductImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.fastfood, color: AppColors.primary);
    }

    final imageProvider = _getImageProvider(imageUrl);
    if (imageProvider == null) {
      return const Icon(Icons.error, color: Colors.red);
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.transparent,
      backgroundImage: imageProvider,
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    final imageProvider = _getImageProvider(imageUrl);
    if (imageProvider == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9), // Fondo casi negro
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Imagen interactiva (zoom opcional)
            InteractiveViewer(
              maxScale: 4.0,
              child: Image(image: imageProvider, fit: BoxFit.contain),
            ),
            // Botón de cerrar
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}