import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kadu/core/theme/app_colors.dart';
import '../data/ocr_service.dart'; // Ruta corregida
import '../data/product_search_service.dart'; // Ruta corregida
import 'screen_overlay_painter.dart';
import '../../inventory/data/pantry_repository.dart';
import '../../inventory/domain/entities/product_entity.dart';

enum ScanStep { barcode, date }

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  ScanStep _currentStep = ScanStep.barcode;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isProcessing = false;

  String? _tempBarcode;
  String? _detectedProductName;

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
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFocusMode(FocusMode.auto);

      if (!mounted) return;
      setState(() => _isCameraInitialized = true);

      if (_currentStep == ScanStep.barcode) {
        _startBarcodeStream();
      }

    } catch (e) {
      debugPrint("Error cámara: $e");
    }
  }

  void _startBarcodeStream() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _controller!.startImageStream((CameraImage image) async {
      if (_isProcessing) return;
      if (_currentStep != ScanStep.barcode) return;

      _isProcessing = true;
      try {
        final inputImage = _inputImageFromCameraImage(image);
        if (inputImage == null) return;

        final barcodes = await _barcodeScanner.processImage(inputImage);

        if (barcodes.isNotEmpty) {
          final code = barcodes.first.rawValue;
          if (code != null) {
            await _controller!.stopImageStream();
            _onBarcodeFound(code);
          }
        }
      } catch (e) {
        debugPrint("Error en stream de barras: $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  void _onBarcodeFound(String code) async {
    HapticFeedback.mediumImpact();

    setState(() {
      _tempBarcode = code;
      _currentStep = ScanStep.date;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Código: $code. Buscando nombre... Ahora escanea la fecha."),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );

    if (code != "Manual") {
      final name = await ref.read(productSearchServiceProvider).getProductName(code);
      if (mounted && name != null) {
        setState(() {
          _detectedProductName = name;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("¡Producto identificado: $name!"), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _takePictureAndScanDate() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final XFile image = await _controller!.takePicture();
      final ocrService = ref.read(ocrServiceProvider);
      final DateTime? detectedDate = await ocrService.scanImageForDate(image.path);

      if (!mounted) return;

      _showFinalProductDialog(detectedDate);

    } catch (e) {
      debugPrint("Error escaneando fecha: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showFinalProductDialog(DateTime? date) {
    final initialName = _detectedProductName ?? (_tempBarcode != null ? "Producto $_tempBarcode" : "");
    final nameController = TextEditingController(text: initialName);

    DateTime selectedDate = date ?? DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text("Resumen del Escaneo", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code, color: AppColors.primary),
              title: const Text("Código", style: TextStyle(color: Colors.grey, fontSize: 12)),
              subtitle: Text(_tempBarcode ?? "Manual", style: const TextStyle(color: Colors.white)),
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: AppColors.primary),
              title: const Text("Vencimiento", style: TextStyle(color: Colors.grey, fontSize: 12)),
              subtitle: Text(
                  "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Nombre del Producto",
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _currentStep = ScanStep.barcode;
                _tempBarcode = null;
                _detectedProductName = null;
              });
              Navigator.pop(context);
              _startBarcodeStream();
            },
            child: const Text("Descartar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              final newProduct = ProductEntity(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                barcode: _tempBarcode,
                expirationDate: selectedDate,
                addedDate: DateTime.now(),
                category: "Escaneado",
                quantity: 1,
              );

              await ref.read(pantryRepositoryProvider).addProduct(newProduct);

              if (context.mounted) {
                Navigator.pop(context);
                setState(() {
                  _currentStep = ScanStep.barcode;
                  _tempBarcode = null;
                  _detectedProductName = null;
                });
                _startBarcodeStream();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Guardado exitoso")),
                );
              }
            },
            child: const Text("GUARDAR", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    final String guideText = _currentStep == ScanStep.barcode
        ? "1. Enfoca el CÓDIGO DE BARRAS"
        : "2. Ahora toma foto a la FECHA";

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Container(color: Colors.black.withValues(alpha: 0.5)),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(guideText, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: _currentStep == ScanStep.barcode ? 150 : 100,
                  width: 300,
                  child: CustomPaint(
                    foregroundPainter: CornerPainter(
                        color: _currentStep == ScanStep.barcode ? Colors.white : AppColors.primary
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: (_currentStep == ScanStep.barcode ? Colors.white : AppColors.primary).withValues(alpha: 0.3)
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: _currentStep == ScanStep.barcode
                      ? _buildBarcodeControls()
                      : _buildDateControls(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeControls() {
    return Column(
      children: [
        if (_detectedProductName != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text("¡$_detectedProductName detectado!", style: const TextStyle(color: Colors.greenAccent)),
          ),
        const CircularProgressIndicator(color: Colors.white),
        const SizedBox(height: 10),
        const Text("Buscando código...", style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {
            _onBarcodeFound("Manual");
          },
          child: const Text("¿No tiene código? Saltar", style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }

  Widget _buildDateControls() {
    return GestureDetector(
      onTap: _takePictureAndScanDate,
      child: Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 4),
          color: Colors.white.withValues(alpha: 0.2),
        ),
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 40),
      ),
    );
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _controller!.description;
    final sensorOrientation = camera.sensorOrientation;

    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || (Platform.isAndroid && format != InputImageFormat.nv21)) return null;

    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: Icon(Icons.flash_on, color: _isFlashOn ? AppColors.primary : Colors.white),
          onPressed: _toggleFlash,
        ),
      ],
    );
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
    } catch (e) { debugPrint(e.toString()); }
  }

  @override
  void dispose() {
    _barcodeScanner.close();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
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
}