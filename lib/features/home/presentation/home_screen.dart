import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../scan/presentation/scan_screen.dart';
import '../../inventory/data/pantry_repository.dart';
import '../../inventory/domain/entities/product_entity.dart';
import '../../inventory/presentation/screens/pantry_screen.dart';
import '../../auth/data/auth_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Obtenemos los datos del usuario actual (que viene de Google)
    final user = FirebaseAuth.instance.currentUser;
    final String userName = user?.displayName ?? "Usuario";
    final String? userPhoto = user?.photoURL;

    // --- PANTALLA 0: DASHBOARD PERSONALIZADO ---
    final dashboardScreen = Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar del Usuario
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              backgroundImage: userPhoto != null ? NetworkImage(userPhoto) : null,
              child: userPhoto == null
                  ? const Icon(Icons.person, size: 40, color: Colors.black)
                  : null,
            ),
            const SizedBox(height: 16),

            Text(
                'Hola, $userName 👋',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const Text(
              'Tu alacena está segura en la nube',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 40),

            // Tarjeta de Resumen (Ejemplo)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text("0", style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text("Productos", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      Text("0", style: TextStyle(color: AppColors.alertRed, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text("Vencidos", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // BOTÓN PRUEBA FIREBASE (Privado)
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text("GUARDAR EN MI CUENTA"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final newProduct = ProductEntity(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: "Producto de $userName",
                  expirationDate: DateTime.now().add(const Duration(days: 15)),
                  addedDate: DateTime.now(),
                  category: "Personal",
                  quantity: 1,
                );

                try {
                  await ref.read(pantryRepositoryProvider).addProduct(newProduct);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Guardado en tu espacio privado')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
            ),

            const SizedBox(height: 20),

            // BOTÓN CERRAR SESIÓN
            TextButton.icon(
              icon: const Icon(Icons.logout, color: AppColors.alertRed),
              label: const Text("Cerrar Sesión", style: TextStyle(color: AppColors.alertRed)),
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                // El AuthGate en main.dart detectará el cambio y te llevará al Login solo
              },
            ),
          ],
        ),
      ),
    );

    final List<Widget> screens = [
      dashboardScreen,
      const PantryScreen(),
      const SizedBox(), // Placeholder Scan
      const Center(child: Text('📝 Recipes', style: TextStyle(color: Colors.white))),
      const Center(child: Text('⚙️ Settings', style: TextStyle(color: Colors.white))),
    ];

    return Scaffold(
      body: _currentIndex == 2 ? const ScanScreen() : screens[_currentIndex],

      // BOTÓN FLOTANTE SCAN
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
          onPressed: () => setState(() => _currentIndex = 2),
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

      // BARRA INFERIOR
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
            const SizedBox(width: 40),
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