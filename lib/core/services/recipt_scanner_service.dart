import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../features/categories/data/category_model.dart';

class ReceiptScannerService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<Map<String, dynamic>?> scanReceipt(
      String imagePath,
      List<CategoryModel> userCategories
      ) async {
    final InputImage inputImage = InputImage.fromFilePath(imagePath);

    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      String fullText = recognizedText.text.toLowerCase();

      String? amount = _extractTotalAmount(fullText);
      String? title = _extractTitle(recognizedText.blocks);
      String? categoryId = _detectCategory(fullText, userCategories);
      String? notes = _extractNotes(fullText);


      return {
        'amount': amount,
        'title': title,
        'categoryId': categoryId,
        'notes': notes,
      };
    } catch (e) {
      return null;
    }
  }

  String? _extractTotalAmount(String text) {
    RegExp regExp = RegExp(r'(\d+[\.,]\d{2})');
    Iterable<RegExpMatch> matches = regExp.allMatches(text);

    if (matches.isNotEmpty) {
      return matches.last.group(0);
    }
    return null;
  }

  String? _extractTitle(List<TextBlock> blocks) {
    if (blocks.isEmpty) return null;
    for (var block in blocks.take(3)) {
      String text = block.text.trim();
      if (!RegExp(r'^[0-9]').hasMatch(text) && text.length > 3) {
        return text.split('\n').first;
      }
    }
    return blocks.first.text.split('\n').first;
  }

  String? _detectCategory(String text, List<CategoryModel> userCategories) {
    for (var category in userCategories) {
      if (text.contains(category.name.toLowerCase())) {
        return category.id;
      }
    }
    return null;
  }

  String? _extractNotes(String fullText) {
    return "Scanned on ${DateTime.now().toString().split(' ')[0]}";
  }

  void dispose() {
    _textRecognizer.close();
  }
}