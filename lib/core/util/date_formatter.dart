import 'package:intl/intl.dart';

class DateFormatter {
  /// Format: 'dd MMM yyyy, HH:mm'
  /// Example: '15 Jul 2026, 14:20'
  static String formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "-";
    try {
      final cleanStr = dateStr.replaceAll('T', ' ');
      final parsedDate = DateTime.tryParse(cleanStr);
      if (parsedDate != null) {
        return DateFormat('dd MMM yyyy, HH:mm').format(parsedDate.toLocal());
      }
    } catch (_) {}
    return dateStr;
  }

  /// Format: 'dd/MM/yyyy HH:mm'
  /// Example: '15/07/2026 14:20'
  static String formatDateTimeShort(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "-";
    try {
      final cleanStr = dateStr.replaceAll('T', ' ');
      final parsedDate = DateTime.tryParse(cleanStr);
      if (parsedDate != null) {
        return DateFormat('dd/MM/yyyy HH:mm').format(parsedDate.toLocal());
      }
    } catch (_) {}
    return dateStr;
  }

  /// Format Date only: 'dd MMM yyyy'
  /// Example: '15 Jul 2026'
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "-";
    try {
      final cleanStr = dateStr.replaceAll('T', ' ');
      final parsedDate = DateTime.tryParse(cleanStr);
      if (parsedDate != null) {
        return DateFormat('dd MMM yyyy').format(parsedDate.toLocal());
      }
    } catch (_) {}
    // Fallback if not parsable but split-friendly
    if (dateStr.contains('T')) {
      return dateStr.split('T')[0];
    } else if (dateStr.contains(' ')) {
      return dateStr.split(' ')[0];
    }
    return dateStr;
  }
}
