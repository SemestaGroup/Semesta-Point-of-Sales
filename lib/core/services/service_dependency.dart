import 'package:get/get.dart';
import 'package:semesta_pos/core/services/app_service.dart';
import 'package:semesta_pos/core/services/remote/api_service.dart';
import 'package:semesta_pos/core/services/theme_service.dart';
import 'package:semesta_pos/core/services/user_service.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/core/services/sync_service.dart';
import 'package:semesta_pos/modules/home/employee/controllers/shift_controller.dart';
import 'package:semesta_pos/modules/setting/controllers/setting_controller.dart';

class ServiceDependency {
  static Future<void> init() async {
    // Core Infrastructure
    if (!Get.isRegistered<DatabaseService>()) {
      Get.put(DatabaseService(), permanent: true);
    }
    
    if (!Get.isRegistered<UserService>()) {
      final userService = Get.put(UserService(), permanent: true);
      await userService.initSharedPref();
    }
    
    if (!Get.isRegistered<ThemeService>()) {
      final theme = ThemeService();
      await theme.init();
      Get.put(theme, permanent: true);
    }
    
    if (!Get.isRegistered<ApiService>()) {
      Get.put(ApiService(), permanent: true);
    }
    
    if (!Get.isRegistered<AppService>()) {
      Get.put(AppService(), permanent: true);
    }
    
    // Global State Controllers
    if (!Get.isRegistered<SettingController>()) {
      Get.put(SettingController(), permanent: true);
    }
    
    if (!Get.isRegistered<ShiftController>()) {
      Get.put(ShiftController(), permanent: true);
    }
    
    if (!Get.isRegistered<SyncService>()) {
      Get.put(SyncService(), permanent: true);
    }
  }
}
