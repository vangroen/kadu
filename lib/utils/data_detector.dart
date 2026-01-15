class DateDetector {
  // Mapa de corrección de errores comunes de OCR
  static final Map<String, String> _replacements = {
    'O': '0', 'o': '0', 'D': '0',
    'I': '1', 'l': '1', '|': '1',
    'Z': '2',
    'S': '5',
    'B': '8',
    'g': '9',
    ',': '.', // Cambiar comas por puntos
    '-': '/', // Normalizar separadores
    '.': '/',
  };

  static DateTime? findDate(String text) {
    // 1. Limpieza preliminar línea por línea
    final lines = text.split('\n');
    
    for (var line in lines) {
      String cleanLine = line.toUpperCase().trim();
      
      // Filtro de ruido: Si la línea es muy corta, ignorar
      if (cleanLine.length < 5) continue;

      // 2. Intentar detectar palabras clave (EXP, VTO, BEST BEFORE)
      // Esto nos ayuda a priorizar líneas, aunque a veces la fecha está sola.
      
      // 3. ESTRATEGIA A: Fechas Numéricas (dd/mm/aa o dd/mm/aaaa)
      // Corregimos caracteres solo si parecen números
      String numericLine = _fixCommonOCRErrors(cleanLine);
      
      // Regex: Captura dd/mm/yy o dd/mm/yyyy
      // Acepta separadores / . - y espacios
      final numericRegex = RegExp(r'\b(\d{1,2})[\/\.\-\s]+(\d{1,2})[\/\.\-\s]+(\d{2,4})\b');
      final matchNum = numericRegex.firstMatch(numericLine);
      
      if (matchNum != null) {
        try {
          int day = int.parse(matchNum.group(1)!);
          int month = int.parse(matchNum.group(2)!);
          int year = int.parse(matchNum.group(3)!);

          final date = _validateAndBuildDate(day, month, year);
          if (date != null) return date;
        } catch (e) {
          // Fallo el parseo, seguimos intentando
        }
      }

      // 4. ESTRATEGIA B: Fechas con Texto (12 ENE 2025)
      // Meses en español e inglés
      final textDateRegex = RegExp(
        r'\b(\d{1,2})[\s\.\-\/]+(ENE|FEB|MAR|ABR|MAY|JUN|JUL|AGO|SEP|OCT|NOV|DIC|JAN|APR|AUG|DEC)[A-Z]*[\s\.\-\/]+(\d{2,4})\b'
      );
      final matchText = textDateRegex.firstMatch(cleanLine);

      if (matchText != null) {
        try {
          int day = int.parse(matchText.group(1)!);
          String monthStr = matchText.group(2)!;
          int year = int.parse(matchText.group(3)!);
          int month = _monthStringToInt(monthStr);

          final date = _validateAndBuildDate(day, month, year);
          if (date != null) return date;
        } catch (e) {
          // Ignorar error
        }
      }
    }
    return null;
  }

  static String _fixCommonOCRErrors(String input) {
    String output = input;
    _replacements.forEach((key, value) {
      output = output.replaceAll(key, value);
    });
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
    return 1; // Default fallback
  }

  static DateTime? _validateAndBuildDate(int d, int m, int y) {
    // Corrección de año a 4 dígitos
    if (y < 100) y += 2000; 

    // Reglas de negocio básicas
    final now = DateTime.now();
    // 1. Si el año es menor al actual (con margen de error de 1 año atrás por productos viejos), descartar.
    // Ej: Si lee "1990" es probable que sea una fecha de nacimiento o error.
    if (y < (now.year - 2) || y > (now.year + 10)) return null;

    // 2. Validación de mes y día
    if (m < 1 || m > 12) return null;
    if (d < 1 || d > 31) return null;

    return DateTime(y, m, d);
  }
}