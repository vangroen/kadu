import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importamos nuestros íconos (puedes usar los de Cupertino o Material)
import 'package:flutter/cupertino.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  // Aquí pondremos las pantallas reales más adelante
  final List<Widget> _screens = [
    const Center(child: Text('📦 Aquí irá el Inventario')),
    const Center(child: Text('📷 Aquí irá el Escáner')),
    const Center(child: Text('⚙️ Aquí irán los Ajustes')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El body cambia según el índice seleccionado
      body: _screens[_currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.kitchen_outlined),
            selectedIcon: Icon(Icons.kitchen),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.viewfinder), // Icono estilo cámara
            selectedIcon: Icon(CupertinoIcons.viewfinder_circle_fill),
            label: 'Escanear',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}