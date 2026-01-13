import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../scan/presentation/scan_screen.dart';
import '../../inventory/data/pantry_repository.dart';
import '../../inventory/domain/entities/product_entity.dart';
import '../../inventory/presentation/screens/pantry_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Definimos las pantallas aquí para poder usar 'ref' y 'context'
    final List<Widget> screens = [
      // --- PANTALLA 0: DASHBOARD (Con botón de prueba) ---
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏠 Home Dashboard', style: TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 20),

            // BOTÓN DE PRUEBA FIREBASE
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text("PROBAR FIREBASE"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                // 1. Crear producto de prueba
                final newProduct = ProductEntity(
                  id: DateTime.now().millisecondsSinceEpoch.toString(), // ID único temporal
                  name: "Leche Gloria Test",
                  expirationDate: DateTime.now().add(const Duration(days: 7)), // Vence en 1 semana
                  addedDate: DateTime.now(),
                  category: "Lácteos",
                  quantity: 1,
                );

                // 2. Guardar en la nube usando el Repositorio
                try {
                  await ref.read(pantryRepositoryProvider).addProduct(newProduct);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ ¡Enviado a Firebase! Revisa la consola web.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error: $e'),
                        backgroundColor: AppColors.alertRed,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),

      // --- PANTALLA 1: PANTRY ---
      const PantryScreen(),

      // --- PANTALLA 2: SCAN (Se maneja abajo, esto es placeholder) ---
      const SizedBox(),

      // --- PANTALLA 3: RECIPES ---
      const Center(child: Text('📝 Recipes', style: TextStyle(color: Colors.white))),

      // --- PANTALLA 4: SETTINGS ---
      const Center(child: Text('⚙️ Settings', style: TextStyle(color: Colors.white))),
    ];

    return Scaffold(
      // Lógica: Si el índice es 2, mostramos el Scanner a pantalla completa.
      // Si no, mostramos la pantalla correspondiente de la lista.
      body: _currentIndex == 2 ? const ScanScreen() : screens[_currentIndex],

      // --- BOTÓN FLOTANTE GIGANTE (SCAN) ---
      floatingActionButton: Container(
        height: 75,
        width: 75,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          elevation: 0,
          onPressed: () {
            setState(() {
              _currentIndex = 2; // Cambia a la pantalla de cámara
            });
          },
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, color: Colors.black, size: 30),
              Text("SCAN", style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold))
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- BARRA INFERIOR ---
      bottomNavigationBar: BottomAppBar(
        color: AppColors.cardSurface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.grid_view_rounded, "Home", 0),
            _buildNavItem(Icons.inventory_2_outlined, "Pantry", 1),
            const SizedBox(width: 40), // Espacio para el botón central
            _buildNavItem(Icons.receipt_long_rounded, "Recipes", 3),
            _buildNavItem(Icons.settings_outlined, "Settings", 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textGrey,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textGrey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}