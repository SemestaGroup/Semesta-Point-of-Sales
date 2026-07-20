import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Constants {
  static const appVersion = "1.5.2";
  static const centralBaseUrl = "https://flinkaja.com/";
  static const staticAuthToken =
      "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyIjoiIiwibmFtZSI6IiIsIkFQSV9USU1FIjoxNzY4Nzg5Mzg1fQ.ivZLnFkdbTXhYLgCpOuZwSoai6TO9NhbEsUb8uLZ3Qc";

  static const isLogin = "login";
  static const userId = "user_id";
  static const userName = "username";
  static const userEmail = "user_email";
  static const role = "role";
  static const appName = "Angkringan Rizumiya";
  static const successState = "success_state";
  static const errorState = "error_state";
  static const serverErrState = "server_error_state";
  static const baseUrl = "base_url";
  static const authToken = "auth_token";
  static const successTransMsg = "Transaction successful";
  static const allowZeroStock = "allow_zero_stock";
  static const useDefaultDiscount = "use_default_discount";
  static const selectedPrinter = "selected_printer";
  static const imageBaseUrl = "https://flinkaja.com/uploads/products/";

  // Store info keys
  static const posCompanyName = "pos_company_name";
  static const posAddress = "pos_address";
  static const posPhoneNumber = "pos_phone_number";
  static const posDefaultDiscount = "pos_default_discount";
  static const posTransactionWebhookUrl = "pos_transaction_webhook_url";


  // Queue system keys
  static const psNextQueue = "ps_next_queue";
  static const psLastQueueDate = "ps_last_queue_date";
  // Order types mapping (API Key -> UI Label)
  static const Map<String, String> orderTypeLabels = {
    'dinein': 'Dine In',
    'gofood': 'GoFood',
    'grabfood': 'GrabFood',
    'shopeefood': 'ShopeeFood',
    'tiktok': 'TikTok Shop',
    'takeaway': 'Take Away',
  };

  // Payment mode IDs that represent Cash across all tenants.
  // '1' = standard Perfex Cash ID, '7' = Semesta POS custom Cash ID.
  static const List<String> cashPaymentModeIds = ['1', '7'];
  static const String defaultCashPaymentModeId = '7';

  // Custom Snackbar
  static void showSnackbar({
    required String title,
    required String message,
    required bool isSuccess,
    bool isWarning = false,
  }) {
    var bgColor = const Color(0xFF1E293B); // Dark slate default
    var iconData = Icons.info_outline;
    var iconColor = const Color(0xFF38BDF8); // Sky blue

    if (isSuccess) {
      bgColor = const Color(0xFF0F766E); // Deep teal
      iconData = Icons.check_circle_outline;
      iconColor = const Color(0xFF2DD4BF); // Mint green
    } else if (isWarning) {
      bgColor = const Color(0xFFC2410C); // Burnt orange
      iconData = Icons.warning_amber_outlined;
      iconColor = const Color(0xFFFDBA74); // Light peach
    }

    Get.snackbar(
      title,
      message,
      backgroundColor: bgColor,
      colorText: const Color(0xFFF8FAFC),
      icon: Icon(iconData, color: iconColor, size: 24),
      snackPosition: SnackPosition.TOP,
      borderRadius: 12,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 12,
          offset: const Offset(0, 6),
        )
      ],
      duration: const Duration(seconds: 3),
      shouldIconPulse: false,
    );
  }

  static String normalizePhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    if (cleaned.startsWith('62')) {
      cleaned = cleaned.substring(2);
    }
    return '08$cleaned';
  }
}
