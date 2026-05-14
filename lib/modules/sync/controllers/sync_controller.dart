import 'package:get/get.dart';
import 'package:semesta_pos/core/services/sync_service.dart';
import 'package:semesta_pos/core/services/user_service.dart';
import 'package:semesta_pos/routes/app_pages.dart';

class SyncController extends GetxController {
  final SyncService _syncService = Get.find<SyncService>();
  final UserService _userService = Get.find<UserService>();

  RxString get status => _syncService.syncStatus;
  RxDouble get progress => _syncService.syncProgress;

  @override
  void onInit() {
    super.onInit();
    startInitialSync();
  }

  Future<void> startInitialSync() async {
    try {
      await _syncService.pullMasterData();
    } catch (e) {
      Get.snackbar("Sync Error",
          "Koneksi bermasalah. Gagal melakukan sinkronisasi awal.");
    } finally {
      // Check active staff to determine destination
      final hasActiveStaff = _userService.getPrefBool('has_active_staff');

      if (!hasActiveStaff) {
        Get.offAllNamed(Routes.staffSelection);
      } else {
        final userData = await _userService.getSharedUserModel();
        if (userData.role == 'owner' || userData.role == 'supervisor') {
          Get.offAllNamed(Routes.dashboardAdmin);
        } else {
          Get.offAllNamed(Routes.dashboardEmployee);
        }
      }
    }
  }
}
