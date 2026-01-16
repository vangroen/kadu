import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/pantry_repository.dart';
import '../providers/pantry_provider.dart';
import 'add_product_screen.dart';
import '../../../../core/services/notification_service.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.orange),
            tooltip: "Probar Notificaciones (Vencen <= 15 días)",
            onPressed: () async {
              // Obtener lista actual del provider
              final productsAsync = ref.read(pantryListProvider);
              
              if (productsAsync.hasValue) {
                final products = productsAsync.value!;
                final count = await NotificationService().checkProductsInstant(products);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Test finalizado. Alertas enviadas: $count"))
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Espera a que carguen los productos..."))
                );
              }
            },
          ),
        ],
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

              // Tarjeta del Producto (Deslizar para borrar o editar)
              return Dismissible(
                key: Key(product.id ?? UniqueKey().toString()),
                // EDITAR: De Izquierda a Derecha (StartToEnd) -> Azul
                // BORRAR: De Derecha a Izquierda (EndToStart) -> Rojo
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: const [
                      Icon(Icons.edit, color: Colors.white, size: 30),
                      SizedBox(width: 8),
                      Text("EDITAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                    ],
                  ),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      Text("ELIMINAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.delete, color: Colors.white, size: 30),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  // CASO 1: EDITAR (Swipe Right)
                  if (direction == DismissDirection.startToEnd) {
                    // Navegamos a editar
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddProductScreen(productToEdit: product),
                      ),
                    );
                    return false; // NO borramos la fila, solo fuimos a editar
                  }
                  
                  // CASO 2: BORRAR (Swipe Left)
                  if (direction == DismissDirection.endToStart) {
                    final bool? confirm = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: const Color(0xFF1E1E1E),
                          title: const Text("Confirmar eliminación", style: TextStyle(color: Colors.white)),
                          content: Text(
                            "¿Estás seguro de que deseas eliminar '${product.name}'?",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text("CANCELAR", style: TextStyle(color: Colors.white54)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text("ELIMINAR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        );
                      },
                    );
                    return confirm ?? false;
                  }
                  
                  return false;
                },
                onDismissed: (direction) {
                  // Solo llegamos aquí si confirmDismiss retornó true (Borrar)
                  if (direction == DismissDirection.endToStart) {
                    ref.read(pantryRepositoryProvider).deleteProduct(product.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('🗑️ ${product.name} eliminado')),
                    );
                  }
                },
                  child: Card(
                  color: AppColors.cardSurface,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  // SEMÁFORO VISUAL: Borde izquierdo de color
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          _getStatusColor(product.expirationDate).withOpacity(0.15),
                          Colors.transparent
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      border: Border(
                        left: BorderSide(
                          color: _getStatusColor(product.expirationDate),
                          width: 6,
                        ),
                      ),
                    ),
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
                        _getExpirationText(product.expirationDate),
                        style: TextStyle(
                          color: _getStatusColor(product.expirationDate), 
                          fontWeight: FontWeight.w500
                        ),
                      ),
                      trailing: Text(
                        "x${product.quantity}",
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
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

  // --- LÓGICA DEL SEMÁFORO ---
  Color _getStatusColor(DateTime expirationDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(expirationDate.year, expirationDate.month, expirationDate.day);
    final days = date.difference(today).inDays;

    if (days <= 0) return Colors.redAccent; // Vencido
    if (days <= 15) return Colors.orangeAccent; // Atención (15 días)
    return Colors.greenAccent; // Fresco
  }

  String _getExpirationText(DateTime expirationDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(expirationDate.year, expirationDate.month, expirationDate.day);
    final days = date.difference(today).inDays;
    final dateStr = DateFormat('dd/MM/yy').format(expirationDate);

    if (days < 0) return "VENCIDO hace ${days.abs()} días ($dateStr)";
    if (days == 0) return "VENCE HOY ($dateStr)";
    if (days <= 15) return "Vence en $days días ($dateStr)";
    return "Vence el $dateStr";
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