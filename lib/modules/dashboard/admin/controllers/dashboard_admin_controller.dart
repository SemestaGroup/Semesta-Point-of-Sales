import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/services/local/database_service.dart' as semesta_pos;
import 'package:semesta_pos/core/services/user_service.dart';
import 'package:semesta_pos/modules/home/employee/controllers/shift_controller.dart';
import 'package:semesta_pos/routes/app_pages.dart';
import 'package:semesta_pos/modules/auth/controllers/auth_controller.dart';

class DashboardAdminController extends GetxController {
  RxInt stateSelectedIndex = 0.obs;
  RxBool isSidebarCollapsed = false.obs;
  RxBool isDarkMode = false.obs;
  RxInt activeOrderCount = 0.obs;
  final _userService = Get.put(UserService());
  @override
  void onInit() {
    super.onInit();
    updateActiveOrderCount();
    if (Get.arguments != null && Get.arguments is Map && Get.arguments['index'] != null) {
      stateSelectedIndex.value = Get.arguments['index'] as int;
      if (stateSelectedIndex.value == 1) {
        isSidebarCollapsed.value = true;
      }
    }

    // Auto-collapse sidebar when POS (index 1) is selected
    ever(stateSelectedIndex, (int index) {
      if (index == 1) {
        isSidebarCollapsed.value = true;
      }
    });
  }

  Future<void> updateActiveOrderCount() async {
    try {
      final dbService = Get.find<semesta_pos.DatabaseService>();
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
    // Show loading
    Get.dialog(
      const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
      barrierDismissible: false,
    );

    await _userService.initSharedPref();
    await _userService.destroySession();

    // Explicitly clear in-memory shift state BEFORE deleting the DB
    // so reactive listeners don't try to re-read stale values on teardown
    try {
      if (Get.isRegistered<ShiftController>()) {
        final sc = Get.find<ShiftController>();
        sc.activeShift.value = null;
        sc.isOwnerTrialMode.value = false;
        sc.shiftConfigs.clear();
      }
    } catch (_) {}

    // Delete the entire SQLite database (clears all local data cleanly)
    final dbService = Get.find<semesta_pos.DatabaseService>();
    await dbService.deleteDatabaseFile();

    // Clear non-permanent controllers, but KEEP core services
    Get.deleteAll(force: false);

    Get.offAllNamed(Routes.login);
  }

  Future<void> changeStaff() async {
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());
    await authController.changeUser();
  }
}
