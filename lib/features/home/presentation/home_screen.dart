import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kadu/core/theme/app_colors.dart';
import '../../scan/presentation/scan_screen.dart'; // Importa tu pantalla de Scan

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  // Las pantallas de tu diseño
  final List<Widget> _screens = [
    const Center(child: Text('🏠 Home Dashboard', style: TextStyle(color: Colors.white))), // Aquí haremos el dashboard luego
    const Center(child: Text('📦 Pantry', style: TextStyle(color: Colors.white))),
    const SizedBox(), // Espacio vacío para el botón de Scan
    const Center(child: Text('📝 Recipes', style: TextStyle(color: Colors.white))),
    const Center(child: Text('⚙️ Settings', style: TextStyle(color: Colors.white))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El contenido principal
      body: _currentIndex == 2 ? const ScanScreen() : _screens[_currentIndex],

      // EL BOTÓN GIGANTE DE SCAN (FLOTANTE)
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
              _currentIndex = 2; // Índice 2 es la cámara
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

      // LA BARRA INFERIOR (Dock)
      bottomNavigationBar: BottomAppBar(
        color: AppColors.cardSurface,
        shape: const CircularNotchedRectangle(), // El recorte curvado
        notchMargin: 10,
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Lado Izquierdo
            _buildNavItem(Icons.grid_view_rounded, "Home", 0),
            _buildNavItem(Icons.inventory_2_outlined, "Pantry", 1),

            // Espacio central para el botón flotante
            const SizedBox(width: 40),

            // Lado Derecho
            _buildNavItem(Icons.receipt_long_rounded, "Recipes", 3),
            _buildNavItem(Icons.settings_outlined, "Settings", 4),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para crear los botones pequeños
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