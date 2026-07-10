import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/modules/home/employee/controllers/home_controller.dart';
import 'package:semesta_pos/modules/home/employee/views/payment_screen_mobile.dart';
import 'package:semesta_pos/modules/home/employee/views/payment_screen_tablet.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 600;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return _isMobile(context)
        ? PaymentScreenMobile(controller: controller)
        : PaymentScreenTablet(controller: controller);
  }
}
