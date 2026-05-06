import 'package:get/get.dart';
import 'package:semesta_pos/modules/report/controllers/report_controller.dart';

class ReportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReportController>(() => ReportController());
  }
}
