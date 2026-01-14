import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ocrServiceProvider = Provider((ref) => OcrService());

class OcrService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<DateTime?> scanImageForDate(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      print("--- INICIANDO ESCANEO INTELIGENTE ---");

      // ESTRATEGIA DE "FOCO":
      // En lugar de leer todo el texto junto (que mezcla código de barras con fechas),
      // analizamos cada línea por separado. Esto aísla la fecha del ruido.

      // 1. Barrido Línea por Línea (Prioridad Alta)
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          // Filtramos líneas muy cortas que suelen ser ruido
          if (line.text.length < 5) continue;

          final date = _findDateInText(line.text);
          if (date != null) {
            print("✅ Fecha detectada limpiamente en línea: '${line.text}'");
            return date;
          }
        }
      }

      // 2. Barrido Bloque por Bloque (Prioridad Media)
      // A veces la fecha está partida en dos renglones dentro del mismo bloque visual.
      for (TextBlock block in recognizedText.blocks) {
        final date = _findDateInText(block.text);
        if (date != null) {
          print("✅ Fecha detectada en bloque: '${block.text}'");
          return date;
        }
      }

      // 3. Último recurso: Texto Completo (Prioridad Baja)
      // Solo si todo lo anterior falla, analizamos la "sopa de letras" completa.
      print("⚠️ Intentando buscar en texto completo...");
      return _findDateInText(recognizedText.text);

    } catch (e) {
      print('Error procesando imagen: $e');
      return null;
    }
  }

  DateTime? _findDateInText(String text) {
    final String cleanText = text.toUpperCase();

    // --- BATERÍA DE PATRONES ---

    // 1. FORMATO LATINO/EUROPEO: dd/mm/yyyy o dd-mm-yy
    final RegExp dmyPattern = RegExp(
      r'\b(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{2,4})\b',
    );
    for (final match in dmyPattern.allMatches(cleanText)) {
      final date = _parseDate(
        day: int.parse(match.group(1)!),
        month: int.parse(match.group(2)!),
        year: int.parse(match.group(3)!),
      );
      if (_isValidDate(date)) return date;
    }

    // 2. FORMATO ALFANUMÉRICO: dd MMM yy (30 SEP 25)
    final RegExp dMmYPattern = RegExp(
      r'\b(\d{1,2})[\s\-\/\.]*([A-Z]{3})[\s\-\/\.]*(\d{2,4})\b',
    );
    for (final match in dMmYPattern.allMatches(cleanText)) {
      final month = _monthTextToNumber(match.group(2)!);
      if (month == 0) continue;

      final date = _parseDate(
        day: int.parse(match.group(1)!),
        month: month,
        year: int.parse(match.group(3)!),
      );
      if (_isValidDate(date)) return date;
    }

    // 3. FORMATO INTERNACIONAL/ISO: yyyy-mm-dd
    final RegExp ymdPattern = RegExp(
      r'\b(\d{4})[\s\-\/\.](\d{1,2})[\s\-\/\.](\d{1,2})\b',
    );
    for (final match in ymdPattern.allMatches(cleanText)) {
      final date = _parseDate(
        year: int.parse(match.group(1)!),
        month: int.parse(match.group(2)!),
        day: int.parse(match.group(3)!),
      );
      if (_isValidDate(date)) return date;
    }

    // 4. FORMATO GRINGO/INVERSO: MMM dd yy (SEP 30 25)
    final RegExp mmdyPattern = RegExp(
      r'\b([A-Z]{3})[\s\-\/\.]*(\d{1,2})[\s\-\/\.]*(\d{2,4})\b',
    );
    for (final match in mmdyPattern.allMatches(cleanText)) {
      final month = _monthTextToNumber(match.group(1)!);
      if (month == 0) continue;

      final date = _parseDate(
        month: month,
        day: int.parse(match.group(2)!),
        year: int.parse(match.group(3)!),
      );
      if (_isValidDate(date)) return date;
    }

    // 5. FORMATO COMPACTO LOTE: L1234 300925 (Difícil, pero común en latas)
    // Busca 6 dígitos seguidos que parezcan una fecha futura válida
    final RegExp compactPattern = RegExp(r'\b(\d{2})(\d{2})(\d{2})\b');
    for (final match in compactPattern.allMatches(cleanText)) {
      // Asumimos formato ddMMyy o yyMMdd. Probamos ddMMyy primero.
      final d1 = int.parse(match.group(1)!);
      final d2 = int.parse(match.group(2)!);
      final d3 = int.parse(match.group(3)!);

      // Caso ddMMyy (30 09 25)
      final date1 = _parseDate(day: d1, month: d2, year: d3);
      if (_isValidDate(date1)) return date1;
    }

    return null;
  }

  DateTime? _parseDate({required int day, required int month, required int year}) {
    try {
      if (year < 100) {
        year += 2000;
      }
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  bool _isValidDate(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    // Filtro: La fecha debe ser mayor a 2020 y menor a 2035.
    // Además, para evitar leer fechas de nacimiento o producción viejas,
    // podríamos sugerir que la fecha de vencimiento usualmente es futura o reciente.
    if (date.year < 2020 || date.year > 2035) return false;

    return true;
  }

  int _monthTextToNumber(String m) {
    const months = {
      'ENE': 1, 'FEB': 2, 'MAR': 3, 'ABR': 4, 'MAY': 5, 'JUN': 6,
      'JUL': 7, 'AGO': 8, 'SEP': 9, 'SET': 9, 'OCT': 10, 'NOV': 11, 'DIC': 12,
      'JAN': 1, 'APR': 4, 'AUG': 8, 'DEC': 12
    };
    return months[m] ?? 0;
  }

  void dispose() {
    _textRecognizer.close();
  }
}