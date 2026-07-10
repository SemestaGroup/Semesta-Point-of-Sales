import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/modules/sync/controllers/sync_controller.dart';
import 'package:semesta_pos/modules/sync/views/sync_view_mobile.dart';
import 'package:semesta_pos/modules/sync/views/sync_view_tablet.dart';

class SyncView extends GetView<SyncController> {
  const SyncView({super.key});

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 600;
  }

  @override
  Widget build(BuildContext context) {
    return _isMobile(context)
        ? SyncViewMobile(controller: controller)
        : SyncViewTablet(controller: controller);
  }
}
