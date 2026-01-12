import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:kadu/features/scan/presentation/screen_overlay_painter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kadu/core/theme/app_colors.dart'; // Asegúrate de importar tus colores

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false; // Estado del Flash

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    var status = await Permission.camera.request();
    if (status.isDenied) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _controller!.initialize();
      // Fijar el foco automático para evitar imágenes borrosas
      await _controller!.setFocusMode(FocusMode.auto);
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      print("Error cámara: $e");
    }
  }

  void _toggleFlash() async {
    if (_controller == null) return;
    try {
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.off);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
      }
      setState(() => _isFlashOn = !_isFlashOn);
    } catch (e) {
      print("Error flash: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
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
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. CÁMARA (Ocupa todo el fondo)
          SizedBox.expand(
            child: CameraPreview(_controller!),
          ),

          // 2. CAPA OSCURA (Overlay) con hueco transparente
          // Para lograr el efecto de foco, usamos un ColorFiltered o simplemente contenedores opacos arriba y abajo.
          // Usaremos contenedores semitransparentes para simplificar y oscurecer el fondo.
          Container(color: Colors.black.withOpacity(0.5)),

          // 3. INTERFAZ UI (SafeArea)
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),

                const Spacer(),

                // ZONA DE ESCANEO
                const Text(
                  "Align barcode or expiration date",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),

                // El Marco Verde con la vista clara
                _buildScannerFrame(),

                const SizedBox(height: 30),

                // Botón "AI DETECTING" Brillante
                _buildAiDetectingTag(),

                const Spacer(),

                // Link texto
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Can't scan? Enter manually",
                    style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // CONTROLES INFERIORES
                _buildBottomControls(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets Auxiliares ---

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón Cerrar
          CircleAvatar(
            backgroundColor: const Color(0xFF1E1E1E),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                // Volver al dashboard (índice 0)
                // Nota: Esto requiere acceso al estado del Home, por ahora simula un pop
              },
            ),
          ),

          // Pill "Scan Product"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              "Scan Product",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),

          // Botón Flash
          CircleAvatar(
            backgroundColor: _isFlashOn ? AppColors.primary : const Color(0xFF1E1E1E),
            child: IconButton(
              icon: Icon(Icons.flash_on, color: _isFlashOn ? Colors.black : Colors.white),
              onPressed: _toggleFlash,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerFrame() {
    // Usamos un ClipRRect para que la cámara se vea "clara" aquí si usamos la técnica de recorte,
    // pero como pusimos opacidad global, aquí simulamos el marco sobre la cámara.
    return SizedBox(
      height: 300,
      width: 300,
      child: CustomPaint(
        foregroundPainter: CornerPainter(color: AppColors.primary),
        child: Container(
          // Este contenedor es transparente para ver la cámara
          // pero le damos un leve borde sutil si quieres
        ),
      ),
    );
  }

  Widget _buildAiDetectingTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: Colors.black, size: 18), // Icono de estrellas
          SizedBox(width: 8),
          Text(
            "AI DETECTING",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Galería
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.photo_library_outlined, color: Colors.white70),
          ),

          // Botón SHUTTER (Disparador) Gigante
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Teclado
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.keyboard_alt_outlined, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
