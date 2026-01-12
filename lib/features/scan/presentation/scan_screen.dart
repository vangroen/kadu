import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    // Registramos el observer para saber si el usuario minimiza la app
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    // 1. Verificar Permisos
    var status = await Permission.camera.request();
    if (status.isDenied) return;

    // 2. Buscar cámaras
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    // 3. Configurar el controlador (Usamos la trasera: index 0)
    // ResolutionPreset.high es suficiente para leer texto y gasta menos batería que .max
    _controller = CameraController(
      _cameras[0],
      ResolutionPreset.high,
      enableAudio: false, // No necesitamos audio para escanear comida
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print("Error de cámara: $e");
    }
  }

  // Esto es VITAL para evitar crasheos si el usuario se sale de la app y vuelve
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // Si no hay controlador o no está iniciado, no hacemos nada
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Si minimiza la app, liberamos la memoria de la cámara
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Si vuelve, la reiniciamos
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // CameraPreview ocupa toda la pantalla
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),

          // Capa visual: Marco de escaneo
          _buildOverlay(),

          // Botón de captura (Visual por ahora)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.large(
                onPressed: () {
                  // Aquí conectaremos la IA luego
                  print("Click de escaneo!");
                },
                child: const Icon(Icons.camera_alt, size: 40),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Center(
        child: Container(
          width: 300,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.greenAccent, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              "Enfoca la fecha de vencimiento",
              style: TextStyle(color: Colors.white, shadows: [
                Shadow(blurRadius: 4, color: Colors.black, offset: Offset(1, 1))
              ]),
            ),
          ),
        ),
      ),
    );
  }
}