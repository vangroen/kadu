import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import 'package:kadu/core/theme/app_colors.dart';
import 'package:kadu/features/inventory/data/pantry_repository.dart';
import 'package:kadu/features/inventory/domain/entities/product_entity.dart';

// --- PANTALLA PRINCIPAL: ALTA DE PRODUCTO ---
class AddProductScreen extends ConsumerStatefulWidget {
  final String? initialBarcode;

  const AddProductScreen({super.key, this.initialBarcode});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _quantityCtrl = TextEditingController(text: "1");
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  File? _productImage;
  bool _isAnalyzing = false; // Loading visual

  // Servicio OCR
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void dispose() {
    // 1. Limpieza de controladores de UI
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    
    // 2. Limpieza de servicio ML Kit
    _textRecognizer.close();
    
    super.dispose();
  }

  // Lógica 1: Foto del Producto (Solo imagen visual)
  Future<void> _takeProductPhoto() async {
    final XFile? photo = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SimpleCameraScreen(
          overlayText: "Foto del Producto",
          isDateScan: false,
        ),
      ),
    );

    if (photo == null) return;

    setState(() {
      _productImage = File(photo.path);
    });
  }

  // Lógica 2: Escaneo de Fecha (Con Zoom y Validación)
  Future<void> _scanExpirationDate() async {
    final XFile? photo = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SimpleCameraScreen(
          overlayText: "Enfoca la Fecha (EXP)",
          isDateScan: true, // ACTIVA ZOOM Y MÁSCARA
        ),
      ),
    );

    if (photo == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final inputImage = InputImage.fromFilePath(photo.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      // DEBUG: Ver qué está leyendo exactamente la cámara
      debugPrint("--- TEXTO OCR CRUDO ---");
      debugPrint(recognizedText.text);
      debugPrint("-----------------------");
      
      // Usamos nuestra clase utilitaria para limpiar la basura
      final DateTime? detectedDate = DateDetector.findDate(recognizedText.text);

      if (detectedDate != null) {
        setState(() => _selectedDate = detectedDate);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("¡Fecha detectada: ${DateFormat('dd/MM/yyyy').format(detectedDate)}!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No se pudo leer la fecha. Intenta acercar o usar flash."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error OCR Fecha: $e");
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  // Guardado en Firebase
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ingresa un nombre")));
      return;
    }

    // MOSTRAR LOADING MIENTRAS GUARDA
    setState(() => _isAnalyzing = true);

    try {
      // CORRECCIÓN: Siempre generamos un ID único basado en fecha/hora
      // para permitir múltiples productos con el mismo código de barras.
      final String productId = DateTime.now().millisecondsSinceEpoch.toString();

      // 1. Subir imagen si existe
      String? imageUrl;
      if (_productImage != null) {
        imageUrl = await ref.read(pantryRepositoryProvider).uploadImage(_productImage!, productId);
        if (imageUrl == null) {
          throw Exception("Fallo la subida de la imagen. Verifica tu conexión o reglas de Firebase Storage.");
        }
      }

      final newProduct = ProductEntity(
        id: productId,
        barcode: (widget.initialBarcode != null && widget.initialBarcode!.isNotEmpty) 
            ? widget.initialBarcode 
            : null,
        name: _nameCtrl.text,
        expirationDate: _selectedDate,
        addedDate: DateTime.now(),
        quantity: int.tryParse(_quantityCtrl.text) ?? 1,
        category: 'Manual',
        imageUrl: imageUrl, // Guardamos la URL
      );

      await ref.read(pantryRepositoryProvider).addProduct(newProduct);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Producto Guardado!")));
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Nuevo Producto", style: TextStyle(color: Colors.white)),
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // FOTO
              Center(
                child: GestureDetector(
                  onTap: _takeProductPhoto,
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                      image: _productImage != null 
                        ? DecorationImage(image: FileImage(_productImage!), fit: BoxFit.cover)
                        : null
                    ),
                    child: _productImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.camera_alt, color: AppColors.primary, size: 40),
                              SizedBox(height: 10),
                              Text("Foto / Nombre", style: TextStyle(color: Colors.white54, fontSize: 12))
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              // LOADING OVERLAY
              if (_isAnalyzing)
                Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text("Analizando imagen...", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

              const SizedBox(height: 30),

              // BARCODE INFO
              if (widget.initialBarcode != null)
                Text("Código: ${widget.initialBarcode}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
              
              const SizedBox(height: 10),
              
              // NOMBRE
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  labelText: "Nombre del Producto",
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.primary), borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: _nameCtrl.clear,
                  )
                ),
              ),

              const SizedBox(height: 20),

              // CANTIDAD Y FECHA
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Cant.",
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.primary), borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: () async {
                         final date = await showDatePicker(
                           context: context, 
                           initialDate: _selectedDate, 
                           firstDate: DateTime.now(), 
                           lastDate: DateTime(2035)
                         );
                         if(date != null) setState(() => _selectedDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            InkWell(
                              onTap: _scanExpirationDate,
                              child: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                 padding: EdgeInsets.only(top: 5, left: 5),
                 child: Text("Toca 📷 para escanear fecha de vencimiento", style: TextStyle(color: Colors.white24, fontSize: 10)),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("GUARDAR EN ALACENA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- UTILIDAD: DETECTOR DE FECHAS ---
class DateDetector {
  static final Map<String, String> _replacements = {
    'O': '0', 'o': '0', 'D': '0', 'I': '1', 'l': '1', '|': '1',
    'Z': '2', 'S': '5', 'B': '8', 'g': '9', ',': '.', '-': '/', '.': '/',
  };

  static DateTime? findDate(String text) {
    final lines = text.split('\n');
    for (var line in lines) {
      String cleanLine = line.toUpperCase().trim();
      if (cleanLine.length < 5) continue;
      
      // Intentar numérico
      String numericLine = _fixCommonOCRErrors(cleanLine);
      final numericRegex = RegExp(r'\b(\d{1,2})[\/\.\-\s]+(\d{1,2})[\/\.\-\s]+(\d{2,4})\b');
      final matchNum = numericRegex.firstMatch(numericLine);
      
      if (matchNum != null) {
        try {
          int d = int.parse(matchNum.group(1)!);
          int m = int.parse(matchNum.group(2)!);
          int y = int.parse(matchNum.group(3)!);
          final date = _validateAndBuildDate(d, m, y);
          if (date != null) return date;
        } catch (_) {}
      }

      // Intentar texto (ENE, FEB...)
      final textDateRegex = RegExp(r'\b(\d{1,2})[\s\.\-\/]*(ENE|FEB|MAR|ABR|MAY|JUN|JUL|AGO|SEP|OCT|NOV|DIC|JAN|APR|AUG|DEC)[A-Z]*[\s\.\-\/]*(\d{2,4})\b');
      final matchText = textDateRegex.firstMatch(cleanLine);
      
      if (matchText != null) {
        try {
          int d = int.parse(matchText.group(1)!);
          String mStr = matchText.group(2)!;
          int y = int.parse(matchText.group(3)!);
          int m = _monthStringToInt(mStr);
          final date = _validateAndBuildDate(d, m, y);
          if (date != null) return date;
        } catch (_) {}
      }
    }
    return null;
  }

  static String _fixCommonOCRErrors(String input) {
    String output = input;
    _replacements.forEach((key, value) => output = output.replaceAll(key, value));
    return output;
  }

  static int _monthStringToInt(String month) {
    if (month.startsWith('ENE') || month.startsWith('JAN')) return 1;
    if (month.startsWith('FEB')) return 2;
    if (month.startsWith('MAR')) return 3;
    if (month.startsWith('ABR') || month.startsWith('APR')) return 4;
    if (month.startsWith('MAY')) return 5;
    if (month.startsWith('JUN')) return 6;
    if (month.startsWith('JUL')) return 7;
    if (month.startsWith('AGO') || month.startsWith('AUG')) return 8;
    if (month.startsWith('SEP')) return 9;
    if (month.startsWith('OCT')) return 10;
    if (month.startsWith('NOV')) return 11;
    if (month.startsWith('DIC') || month.startsWith('DEC')) return 12;
    return 1;
  }

  static DateTime? _validateAndBuildDate(int d, int m, int y) {
    if (y < 100) y += 2000;
    final now = DateTime.now();
    if (y < (now.year - 2) || y > (now.year + 10)) return null;
    if (m < 1 || m > 12) return null;
    if (d < 1 || d > 31) return null;
    return DateTime(y, m, d);
  }
}

// --- UI: CÁMARA MEJORADA ---
class SimpleCameraScreen extends StatefulWidget {
  final String overlayText;
  final bool isDateScan;

  const SimpleCameraScreen({super.key, required this.overlayText, this.isDateScan = false});

  @override
  State<SimpleCameraScreen> createState() => _SimpleCameraScreenState();
}

class _SimpleCameraScreenState extends State<SimpleCameraScreen> {
  // Optimization: Cache global de cámaras
  static List<CameraDescription> _cachedCameras = [];
  
  CameraController? _cameraController;
  bool _isInit = false;
  double _currentZoom = 1.0;
  double _maxZoom = 1.0;
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // OPTIMIZATION: Cache cameras to avoid calling the platform channel every time
    if (_cachedCameras.isEmpty) {
      _cachedCameras = await availableCameras();
    }
    if (_cachedCameras.isEmpty) return;
    
    // OPTIMIZATION: Reduced resolution from max to high for faster startup and capture
    _cameraController = CameraController(
      _cachedCameras[0], 
      ResolutionPreset.high, 
      enableAudio: false, 
      imageFormatGroup: ImageFormatGroup.yuv420
    );

    try {
      await _cameraController!.initialize();
      _maxZoom = await _cameraController!.getMaxZoomLevel();
      
      // Zoom automático para fechas
      // Reducimos el zoom de 2.5 a 1.5 para evitar que se desenfoque en algunos dispositivos
      double initialZoom = widget.isDateScan ? 1.5 : 1.0;
      if (initialZoom > _maxZoom) initialZoom = _maxZoom;
      
      await _cameraController!.setZoomLevel(initialZoom);
      _currentZoom = initialZoom;
      await _cameraController!.setFocusMode(FocusMode.auto);

      if (mounted) setState(() => _isInit = true);
    } catch (e) {
      debugPrint("Error cámara: $e");
    }
  }

  Future<void> _takePicture() async {
    if (!_isInit || _cameraController == null) return;
    try {
      await _cameraController!.setFocusMode(FocusMode.locked);
      final file = await _cameraController!.takePicture();
      await _cameraController!.setFocusMode(FocusMode.auto);
      if (!mounted) return;
      Navigator.pop(context, file);
    } catch (e) { debugPrint("$e"); }
  }

  @override
  void dispose() {
    // --- AQUÍ ESTÁ EL BLINDAJE CORRECTO ---
    // Usamos try-catch porque la librería de cámara a veces falla al cerrar rápido.
    try {
      _cameraController?.dispose();
    } catch (e) {
      debugPrint("Error silenciado al cerrar cámara simple: $e");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) return const Scaffold(backgroundColor: Colors.black);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: CameraPreview(_cameraController!)),
          
          // MÁSCARA OSCURA (Solo fechas)
          if (widget.isDateScan)
            ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
              child: Stack(
                children: [
                  Container(decoration: const BoxDecoration(color: Colors.transparent, backgroundBlendMode: BlendMode.dstOut)),
                  Center(
                    child: Container(
                      height: 100, 
                      width: MediaQuery.of(context).size.width * 0.8,
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
                        child: Text(widget.overlayText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                        onPressed: () async {
                          setState(() => _flashOn = !_flashOn);
                          await _cameraController!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
                        },
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                
                // SLIDER ZOOM
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    children: [
                      const Icon(Icons.zoom_out, color: Colors.white70, size: 20),
                      Expanded(
                        child: Slider(
                          value: _currentZoom,
                          min: 1.0,
                          max: _maxZoom > 4.0 ? 4.0 : _maxZoom,
                          activeColor: AppColors.primary,
                          inactiveColor: Colors.white24,
                          onChanged: (val) async {
                            setState(() => _currentZoom = val);
                            await _cameraController!.setZoomLevel(val);
                          },
                        ),
                      ),
                      const Icon(Icons.zoom_in, color: Colors.white70, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    height: 80, width: 80,
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade400, width: 4)),
                    child: const Icon(Icons.camera_alt, size: 35, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          )
        ],
      ),
    );
  }
}