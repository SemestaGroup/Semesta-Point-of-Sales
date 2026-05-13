class Constants {
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
}
