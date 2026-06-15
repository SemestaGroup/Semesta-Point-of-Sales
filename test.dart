import 'dart:convert';

void main() {
  String orderType = "Take Away";
  String rawOrderTypes = '["dinein","gofood","shopeefood","grabfood","tiktok","takeaway"]';
  bool matchOrderType = false;

  if (rawOrderTypes.isNotEmpty) {
    try {
      final List types = jsonDecode(rawOrderTypes);
      final normalizedInput = orderType.replaceAll(' ', '').toLowerCase();
      for (var type in types) {
        final normalizedType = type.toString().replaceAll(' ', '').toLowerCase();
        if (normalizedType == normalizedInput) {
          matchOrderType = true;
          break;
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }
  
  print("Match: $matchOrderType");
}
