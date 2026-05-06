import 'package:get/get.dart';
import 'package:semesta_pos/modules/developer/controllers/database_inspector_controller.dart';

class DatabaseInspectorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DatabaseInspectorController>(
      () => DatabaseInspectorController(),
    );
  }
}
