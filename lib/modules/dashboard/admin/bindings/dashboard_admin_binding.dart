import 'package:get/get.dart';
import 'package:semesta_pos/modules/dashboard/admin/controllers/dashboard_admin_controller.dart';

class DashboardAdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardAdminController>(() => DashboardAdminController());
  }
}
