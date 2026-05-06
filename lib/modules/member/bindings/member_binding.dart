import 'package:get/get.dart';
import 'package:semesta_pos/modules/member/controllers/member_controller.dart';

class MemberBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MemberController>(() => MemberController());
  }
}
