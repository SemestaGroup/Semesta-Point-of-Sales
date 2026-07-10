import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/modules/home/employee/controllers/home_controller.dart';
import 'package:semesta_pos/modules/home/employee/controllers/shift_controller.dart';
import 'package:semesta_pos/modules/home/employee/views/home_screen_mobile.dart';
import 'package:semesta_pos/modules/home/employee/views/home_screen_tablet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 600;
  }

  @override
  Widget build(BuildContext context) {
    // Register controllers if not present before rendering child views
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController());
    }
    if (!Get.isRegistered<ShiftController>()) {
      Get.put(ShiftController());
    }

    final controller = Get.find<HomeController>();
    return _isMobile(context)
        ? HomeScreenMobile(controller: controller)
        : HomeScreenTablet(controller: controller);
  }
}
