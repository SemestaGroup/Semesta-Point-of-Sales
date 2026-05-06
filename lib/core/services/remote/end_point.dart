import 'package:semesta_pos/core/util/constans.dart';

class EndPoint {
  static const domain = 'semestaspace.com'; // Legacy fallback domain
  static const managementDomain = Constants.centralBaseUrl;

  // Primary Login Entry Point (Static)
  static const authEndpoint = '${Constants.centralBaseUrl}api/pos_auth';

  // Base Path (Prefixed for dynamic construction in services)
  static const apiPath = 'api/';
  static const phpApiPath = 'pos_api/';

  // Unified POS Resource Endpoints ({base_url}/api/pos_[resource])
  static const posCategories = 'pos_categories';
  static const posBrands = 'pos_brands';
  static const posItems = 'pos_items';
  static const posCustomers = 'pos_customers';
  static const posOrder = 'pos_order';
  static const posTransaction = 'pos_transaction';
  static const posOptions = 'pos_options';
  static const posProfile = 'pos_profile';
  static const posReport = 'pos_reports';
  static const posStaff = 'pos_staff';
  static const posCreditNotes = 'credit_notes';
  static const posErrorLogs = 'pos_error_logs';
  
  // Legacy or Special Endpoints
  static const dashboard = '${phpApiPath}dashboard.php';
  static const login = '${phpApiPath}login.php';
  static const printNota = 'nota/';
}
