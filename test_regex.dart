void main() {
  final text = "22SEP2025";
  final cleanText = text.toUpperCase();
  
  // Regex from ocr_service.dart
  final RegExp dMmYPattern = RegExp(
    r'\b(\d{1,2})[\s\-\/\.]*([A-Z]{3})[\s\-\/\.]*(\d{2,4})\b',
  );

  print("Testing '$cleanText' with regex...");
  final matches = dMmYPattern.allMatches(cleanText);
  if (matches.isEmpty) {
    print("NO MATCH FOUND");
  } else {
    for (final match in matches) {
      print("Match: ${match.group(0)}");
      print("Day: ${match.group(1)}");
      print("Month: ${match.group(2)}");
      print("Year: ${match.group(3)}");
    }
  }
}
