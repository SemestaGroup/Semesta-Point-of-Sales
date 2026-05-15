import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/modules/dashboard/employee/controllers/dashboard_employee_controller.dart';
import 'package:semesta_pos/modules/dashboard/employee/widget/onrail_menu.dart';
import 'package:semesta_pos/modules/dashboard/widget/custom_sidebar.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class DashboardEmployeeScreen extends StatelessWidget {
  DashboardEmployeeScreen({super.key});
  final controller = Get.put(DashboardEmployeeController());

  void _showLogout() {
    Get.dialog(
      Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        backgroundColor: Colors.white,
        child: Container(
          padding: EdgeInsets.all(24.w),
          width: 350.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.logout_rounded, color: Colors.red, size: 32.sp),
              ),
              SizedBox(height: 20.h),
              Text(
                "Logout Confirmation",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontFamily: AppTheme.fontBold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                "Are you sure you want to log out? Please ensure all your transactions have been saved.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontFamily: AppTheme.fontMedium,
                            fontSize: 14.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async => await controller.logOut(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                      ),
                      child: Text(
                        "Yes, Logout",
                        style: TextStyle(
                            fontFamily: AppTheme.fontBold, fontSize: 14.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(
        () => Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            if (MediaQuery.of(context).size.width >= 640)
              CustomSidebar(
                selectedIndex: controller.stateSelectedIndex.value,
                isCollapsed: controller.isSidebarCollapsed.value,
                onCollapseToggle: () {
                  controller.isSidebarCollapsed.value =
                      !controller.isSidebarCollapsed.value;
                },
                platformItems: _buildPlatformItems(context),
                settingItems: _buildSettingItems(context),
              ),
            Expanded(
              child: Obx(() => EmployeeOnRailMenu
                  .menuContent[controller.stateSelectedIndex.value]),
            ),
          ],
        ),
      ),
    );
  }

  List<SidebarItemData> _buildPlatformItems(BuildContext context) {
    final role = controller.userService.getRole().toLowerCase();
    List<SidebarItemData> items = [];

    // Dashboard - Always active
    items.add(SidebarItemData(
      title: 'Dashboard',
      icon: CupertinoIcons.app_badge,
      index: 0,
      onTap: () => controller.stateSelectedIndex.value = 0,
    ));

    if (role != 'kitchen') {
      items.add(SidebarItemData(
        title: 'POS',
        icon: CupertinoIcons.cart_fill,
        index: 1,
        onTap: () => controller.stateSelectedIndex.value = 1,
      ));

      items.add(SidebarItemData(
        title: 'Order',
        icon: CupertinoIcons.bag_fill,
        index: 2,
        badgeCount: controller.activeOrderCount.value,
        onTap: () => controller.stateSelectedIndex.value = 2,
      ));

      items.add(SidebarItemData(
        title: 'Customer',
        icon: CupertinoIcons.person_3_fill,
        index: 3,
        onTap: () => controller.stateSelectedIndex.value = 3,
      ));

      items.add(SidebarItemData(
        title: 'Reconciliation',
        icon: CupertinoIcons.doc_text_fill,
        index: 4,
        onTap: () => controller.stateSelectedIndex.value = 4,
      ));
    }

    // if (role == 'owner' || role == 'supervisor') {
    items.add(SidebarItemData(
      title: 'Report',
      icon: CupertinoIcons.chart_bar_alt_fill,
      index: 5,
      onTap: () => controller.stateSelectedIndex.value = 5,
    ));
    // }

    if (role == 'kitchen' || role == 'owner' || role == 'supervisor') {
      items.add(SidebarItemData(
        title: 'Kitchen',
        icon: CupertinoIcons.lab_flask_solid,
        index: 8,
        onTap: () => controller.stateSelectedIndex.value = 8,
      ));
    }

    return items;
  }

  List<SidebarItemData> _buildSettingItems(BuildContext context) {
    final role = controller.userService.getRole().toLowerCase();
    List<SidebarItemData> items = [];

    items.add(SidebarItemData(
      title: 'General',
      icon: CupertinoIcons.gear_alt_fill,
      index: 6,
      onTap: () => controller.stateSelectedIndex.value = 6,
    ));

    if (role == 'kitchen' || role == 'owner' || role == 'supervisor') {
      items.add(SidebarItemData(
        title: 'Profile',
        icon: CupertinoIcons.person_fill,
        index: 7,
        onTap: () => controller.stateSelectedIndex.value = 7,
      ));
    }

    if (role == 'owner') {
      items.add(SidebarItemData(
        title: 'Developer',
        icon: CupertinoIcons.doc_text_search,
        index: 9,
        onTap: () => controller.stateSelectedIndex.value = 9,
      ));
    }

    if (role == 'owner') {
      items.add(SidebarItemData(
        title: 'Logout Location',
        icon: CupertinoIcons.power,
        onTap: _showLogout,
      ));
    }

    return items;
  }
}
