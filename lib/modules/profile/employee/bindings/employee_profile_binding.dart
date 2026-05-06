import 'package:get/get.dart';
import 'package:semesta_pos/modules/profile/employee/controllers/employee_profile_controller.dart';

class EmployeeProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EmployeeProfileController>(() => EmployeeProfileController());
  }
}
