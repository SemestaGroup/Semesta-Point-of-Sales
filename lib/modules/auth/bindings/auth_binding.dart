import 'package:get/get.dart';
import 'package:semesta_pos/modules/auth/controllers/auth_controller.dart';
import 'package:semesta_pos/core/services/service_dependency.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    ServiceDependency.init();
    
    Get.lazyPut<AuthController>(
      () => AuthController(),
    );
  }
}
