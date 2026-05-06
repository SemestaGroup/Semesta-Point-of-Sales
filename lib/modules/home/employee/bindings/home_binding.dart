import 'package:get/get.dart';
import 'package:semesta_pos/modules/home/employee/controllers/home_controller.dart';
import 'package:semesta_pos/modules/setting/controllers/setting_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<SettingController>(() => SettingController());
  }
}
