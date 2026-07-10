import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/modules/auth/controllers/auth_controller.dart';
import 'package:semesta_pos/modules/auth/views/staff_selection_view_mobile.dart';
import 'package:semesta_pos/modules/auth/views/staff_selection_view_tablet.dart';

class StaffSelectionView extends GetView<AuthController> {
  const StaffSelectionView({super.key});

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 600;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("StaffSelectionView: build() started");
    return _isMobile(context)
        ? StaffSelectionViewMobile(controller: controller)
        : StaffSelectionViewTablet(controller: controller);
  }
}
