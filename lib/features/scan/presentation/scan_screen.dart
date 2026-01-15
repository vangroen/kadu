import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kadu/core/theme/app_colors.dart';
import 'package:kadu/features/scan/presentation/screen_overlay_painter.dart';
import '../../inventory/presentation/screens/add_product_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  // --- Controladores de Cámara ---
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;

  // --- Controladores de ML Kit ---
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isScanning = false;
  bool _processingBarcode = false;

  // --- CORTACIRCUITOS ---
  bool _isAutoScanEnabled = true;
  int _streamErrorCount = 0;

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
      await _controller!.setFocusMode(FocusMode.auto);

      if (mounted) {
        setState(() => _isCameraInitialized = true);
        if (_isAutoScanEnabled) {
          _startImageStream();
        }
      }
    } catch (e) {
      debugPrint("Error cámara: $e");
    }
  }

  void _startImageStream() {
    if (!_isAutoScanEnabled) return;

    _controller?.startImageStream((CameraImage image) async {
      if (_isScanning || _processingBarcode || !_isAutoScanEnabled) return;

      _isScanning = true;
      try {
        await _processCameraImage(image);
      } catch (e) {
        // Ignoramos errores transitorios
      } finally {
        _isScanning = false;
      }
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

      final sensorOrientation = _controller?.description.sensorOrientation ?? 0;
      final imageRotation = InputImageRotationValue.fromRawValue(sensorOrientation)
          ?? InputImageRotation.rotation0deg;

      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw)
          ?? InputImageFormat.yuv420;

      final inputImageMetadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageMetadata,
      );

      final barcodes = await _barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
        _streamErrorCount = 0;
        _onBarcodeDetected(barcodes.first.rawValue!);
      }

    } catch (e) {
      _streamErrorCount++;
      // Si falla 5 veces, asumimos incompatibilidad y apagamos el auto-scan
      if (_streamErrorCount > 5) {
        debugPrint("⚠️ Stream incompatible. Cambiando a modo manual.");
        _stopStreamSafely();
        if (mounted) {
          setState(() => _isAutoScanEnabled = false);
        }
      }
    }
  }

  Future<void> _stopStreamSafely() async {
    try {
      if (_controller != null && _controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
    } catch (e) {
      debugPrint("Stream ya estaba detenido.");
    }
  }

  // --- LÓGICA MANUAL (Botón) ---
  Future<void> _takePictureAndScan() async {
    if (_controller == null || !_controller!.value.isInitialized || _processingBarcode) return;

    setState(() => _processingBarcode = true);

    try {
      await _stopStreamSafely();
      // await Future.delayed(const Duration(milliseconds: 150)); // REMOVED DELAY

      // Lock focus to prevent autofocus hunting during capture
      await _controller!.setFocusMode(FocusMode.locked);
      final XFile file = await _controller!.takePicture();
      await _controller!.setFocusMode(FocusMode.auto); // Unlock focus after capture
      final inputImage = InputImage.fromFilePath(file.path);

      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
        _handleFoundCode(barcodes.first.rawValue!);
      } else {
        debugPrint("⚠️ Producto no encontrado. Yendo a alta inteligente.");

        if (!mounted) return;

        // REEMPLAZAR EL DIÁLOGO CON ESTA NAVEGACIÓN
        // CORRECCIÓN: Se pasa un barcode vacío o nulo si no se encontró nada,
        // o se puede pedir al usuario que lo ingrese.
        // En este caso, como no se encontró barcode, pasamos null o string vacío.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddProductScreen(initialBarcode: ""),
          ),
        ).then((_) {
          // Al volver, reiniciamos el escáner si estaba activo
          _resetScanner();
        });
      }

    } catch (e) {
      debugPrint("Error foto manual: $e");
      setState(() => _processingBarcode = false);
      if (_isAutoScanEnabled) _startImageStream();
    }
  }

  // --- LÓGICA AUTOMÁTICA ---
  Future<void> _onBarcodeDetected(String barcode) async {
    if (_processingBarcode) return;
    _processingBarcode = true;
    await _stopStreamSafely();
    _handleFoundCode(barcode);
  }

  // --- NAVEGACIÓN ---
  void _handleFoundCode(String barcode) {
    debugPrint("🔍 Procesando código: $barcode");

    // MOCK TEMPORAL
    bool productFound = (barcode == "7750000000000");

    if (!mounted) return;

    if (productFound) {
      debugPrint("✅ Producto encontrado.");
      // Navegar a confirmación...
    } else {
      debugPrint("⚠️ Producto no encontrado.");
      _showManualEntryDialog(barcode);
    }
  }

  void _showManualEntryDialog(String barcode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Producto Nuevo", style: TextStyle(color: Colors.white)),
        content: Text(
          "No encontramos datos para $barcode.\n¿Deseas agregarlo manualmente?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetScanner();
            },
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              // Ir a pantalla de agregar manual pasando el barcode
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddProductScreen(initialBarcode: barcode),
                ),
              ).then((_) => _resetScanner());
            },
            child: const Text("Agregar Manual", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    if (mounted) {
      setState(() => _processingBarcode = false);
      if (_isAutoScanEnabled) _startImageStream();
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
      debugPrint("Error flash: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

@override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _barcodeScanner.close();
    
    // CORRECCIÓN: Usamos '_controller' en lugar de '_cameraController'
    try {
      _controller?.dispose();
    } catch (e) {
      debugPrint("Error silenciado al cerrar cámara: $e");
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: AppColors.primary))
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(
            child: CameraPreview(_controller!),
          ),
          Container(color: Colors.black.withValues(alpha: 0.5)),
          
          if (_processingBarcode) ...[
            Container(color: Colors.black54),
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 20),
                  Text("Procesando...", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600))
                ],
              ),
            ),
          ],
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(),

                // Mensaje dinámico traducido
                Text(
                  _isAutoScanEnabled
                      ? "Alinea el código de barras"
                      : "Usa el botón para capturar",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),

                _buildScannerFrame(),

                const SizedBox(height: 30),

                if (_processingBarcode)
                  const CircularProgressIndicator(color: AppColors.primary)
                else
                  _buildAiDetectingTag(),

                const Spacer(),

                TextButton(
                  onPressed: () {
                    // Acción manual directa (sin código)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddProductScreen(initialBarcode: null),
                      ),
                    ).then((_) => _resetScanner());
                  },
                  child: const Text(
                    "¿Problemas? Ingresar código manual",
                    style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildBottomControls(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF1E1E1E),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              "Escanear Producto",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
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
    return SizedBox(
      width: 320,
      height: 150,
      child: CustomPaint(
        foregroundPainter: CornerPainter(
          color: AppColors.primary,
          strokeWidth: 4.0,
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white12, width: 1),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildAiDetectingTag() {
    if (!_isAutoScanEnabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orangeAccent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Text(
          "USA EL BOTÓN DE CAPTURA",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_scanner, color: Colors.black, size: 18),
          SizedBox(width: 8),
          Text(
            "BUSCANDO CÓDIGO...",
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.photo_library_outlined, color: Colors.white70),
          ),

          // BOTÓN PRINCIPAL
          GestureDetector(
            onTap: _takePictureAndScan,
            child: Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: _processingBarcode ? Colors.grey : Colors.white,
                    width: 4
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _processingBarcode ? Colors.grey : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: _processingBarcode
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Icon(Icons.camera_alt, color: Colors.black, size: 30),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.keyboard_alt_outlined, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}