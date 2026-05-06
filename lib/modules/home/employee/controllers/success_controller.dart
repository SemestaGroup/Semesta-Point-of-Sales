import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/services/app_service.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/core/services/remote/end_point.dart';
import 'package:semesta_pos/core/services/user_service.dart';
import 'package:semesta_pos/modules/home/employee/controllers/home_controller.dart';
import 'package:semesta_pos/modules/home/employee/widgets/modal_nota.dart';
import 'package:semesta_pos/modules/setting/controllers/setting_controller.dart';

class SuccessController extends GetxController {
  final userService = Get.put(UserService());

  int penjualanId = 0;
  @override
  void onInit() {
    if (Get.arguments != null) {
      penjualanId = Get.arguments['penjualan_id'];

      // QUEUE LOGIC & AUTO-PRINT
      final appService = Get.find<AppService>();
      
      _assignQueueAndIncrement(appService);

      final printingSettings = appService.posSettings['printing'] ?? {};
      final isAutoPrint = printingSettings['auto_print'] as bool? ?? false;

      if (isAutoPrint && penjualanId != 0) {
        Future.delayed(const Duration(milliseconds: 800), () {
          printToThermal();
        });
      }
    }
    super.onInit();
  }

  Future<void> _assignQueueAndIncrement(AppService appService) async {
    if (penjualanId == 0) return;
    
    try {
      final dbService = Get.find<DatabaseService>();
      final currentQueue = appService.getTodayQueueNumber();
      
      // Save queue number to the transaction record
      await dbService.update('transactions', 
          {'queue_number': currentQueue}, 
          'id_penjualan = ?', [penjualanId]);
          
      // Increment and sync for next transaction
      await appService.incrementQueue();
    } catch (e) {
      debugPrint("SuccessController: Failed to assign queue: $e");
    }
  }

  void printToThermal() async {
    if (penjualanId == 0) return;
    
    if (!Get.isRegistered<SettingController>()) {
      Get.put(SettingController());
      await Future.delayed(const Duration(milliseconds: 100));
    }

    HomeController homeCtrl;
    if (Get.isRegistered<HomeController>()) {
      homeCtrl = Get.find<HomeController>();
    } else {
      homeCtrl = Get.put(HomeController());
    }
    
    homeCtrl.printTransactionSession(penjualanId);
  }

  void showModalNota() {
    if (penjualanId == 0) {
      Get.snackbar(
        'Error',
        'Could not identify transaction for printing.',
      );
      return;
    }

    final notaUrl = EndPoint.printNota + penjualanId.toString();

    debugPrint(notaUrl);
    Get.to(
      ModalNota(
        notaUrl: notaUrl,
        penjualanId: penjualanId, // Pass ID for thermal print capability inside modal
      ),
    );
    return;
  }
}
