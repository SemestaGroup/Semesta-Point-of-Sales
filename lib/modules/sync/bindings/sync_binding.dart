import 'package:get/get.dart';
import 'package:semesta_pos/modules/sync/controllers/sync_controller.dart';
import 'package:semesta_pos/core/services/sync_service.dart';

class SyncBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SyncService>(() => SyncService());
    Get.lazyPut<SyncController>(() => SyncController());
  }
}
