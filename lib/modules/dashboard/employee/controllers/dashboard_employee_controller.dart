import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/services/user_service.dart';
import 'package:semesta_pos/routes/app_pages.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/modules/auth/controllers/auth_controller.dart';
import 'package:semesta_pos/modules/order/controllers/order_controller.dart';

class DashboardEmployeeController extends GetxController {
  RxInt stateSelectedIndex = 0.obs;
  RxBool isSidebarCollapsed = false.obs;
  RxBool isDarkMode = false.obs;
  final userService = Get.put(UserService());

  RxInt activeOrderCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    updateActiveOrderCount();

    // Handle landing index if passed (e.g. from Success Page)
    if (Get.arguments != null && Get.arguments is Map && Get.arguments['index'] != null) {
      stateSelectedIndex.value = Get.arguments['index'] as int;
      if (stateSelectedIndex.value == 1) {
        isSidebarCollapsed.value = true;
      }
    }

    // Listen to tab changes to automate UI transitions
    ever(stateSelectedIndex, (int index) {
      if (index == 1) { // 1 is POS
        isSidebarCollapsed.value = true;
      } else if (index == 2) { // 2 is Orders Tab
        if (Get.isRegistered<OrderController>()) {
          Get.find<OrderController>().getOrders(forceRemote: false);
        }
      }
    });
  }

  Future<void> updateActiveOrderCount() async {
    try {
      final dbService = Get.find<DatabaseService>();
      final result = await dbService.rawQuery(
        "SELECT COUNT(*) as count FROM transactions WHERE status IS NULL OR (status != 5 AND status != 2)"
      );
      if (result.isNotEmpty) {
        activeOrderCount.value = result.first['count'] as int;
      }
    } catch (e) {
      // Ignored initially or DB not ready
    }
  }

  Future logOut() async {
    // Tampilkan dialog loading
    Get.dialog(
      const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
      barrierDismissible: false,
    );

    await userService.initSharedPref();
    await userService.destroySession();
    
    // Hapus database SQLite
    final dbService = Get.find<DatabaseService>();
    await dbService.deleteDatabaseFile();

    Get.offAllNamed(Routes.login);
  }

  Future<void> changeStaff() async {
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());
    await authController.changeUser();
  }
}
