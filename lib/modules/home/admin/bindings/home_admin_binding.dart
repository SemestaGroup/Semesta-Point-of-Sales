import 'package:get/get.dart';
import 'package:semesta_pos/modules/home/admin/controllers/home_admin_controller.dart';

class HomeAdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeAdminController>(() => HomeAdminController());
  }
}
