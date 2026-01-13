import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
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

              // Tarjeta del Producto
              return Card(
                color: AppColors.cardSurface,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fastfood, color: AppColors.primary),
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
              );
            },
          );
        },
      ),
    );
  }
}