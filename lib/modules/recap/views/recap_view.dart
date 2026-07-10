import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/modules/recap/controllers/recap_controller.dart';
import 'package:semesta_pos/modules/recap/views/recap_view_mobile.dart';
import 'package:semesta_pos/modules/recap/views/recap_view_tablet.dart';

class RecapView extends StatelessWidget {
  const RecapView({super.key});

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 600;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<RecapController>()
        ? Get.find<RecapController>()
        : Get.put(RecapController());

    return _isMobile(context)
        ? RecapViewMobile(controller: controller)
        : RecapViewTablet(controller: controller);
  }
}
