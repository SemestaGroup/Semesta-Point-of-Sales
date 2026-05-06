import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/services/app_service.dart';
import 'package:semesta_pos/modules/dashboard/admin/controllers/dashboard_admin_controller.dart';
import 'package:semesta_pos/modules/dashboard/widget/custom_sidebar.dart';
import 'package:semesta_pos/modules/home/admin/views/home_admin_screen.dart';
import 'package:semesta_pos/modules/home/employee/views/home_screen.dart';
import 'package:semesta_pos/modules/order/views/order_view.dart';
import 'package:semesta_pos/modules/member/views/member_view.dart';
import 'package:semesta_pos/modules/product/views/product_view.dart';
import 'package:semesta_pos/modules/report/views/report_view.dart';
import 'package:semesta_pos/modules/setting/views/setting_view.dart';
import 'package:semesta_pos/modules/profile/employee/views/employee_profile_view.dart';
import 'package:semesta_pos/modules/developer/views/database_inspector_screen.dart';
import 'package:semesta_pos/modules/recap/views/recap_view.dart';
import 'package:semesta_pos/modules/kitchen/views/kitchen_view.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class DashboardAdminScreen extends StatelessWidget {
  DashboardAdminScreen({super.key});
  final controller = Get.put(DashboardAdminController());

  void _showLogout() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
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
                child: Icon(Icons.logout_rounded, color: Colors.red, size: 32.sp),
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
                "Are you sure you want to log out?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade700,
                  fontFamily: AppTheme.fontMedium,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        "All local data will be erased, including active shifts, unsynced transactions, and settings. Please sync all data to the server before you log out.",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.amber.shade900,
                          fontFamily: AppTheme.fontRegular,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
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
                        "Batal",
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
                        "Ya, Logout",
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
                platformItems: [
                  SidebarItemData(
                    title: 'Dashboard',
                    icon: CupertinoIcons.app_badge,
                    index: 0,
                    onTap: () => controller.stateSelectedIndex.value = 0,
                  ),
                  SidebarItemData(
                    title: 'POS',
                    icon: CupertinoIcons.cart_fill,
                    index: 1,
                    onTap: () => controller.stateSelectedIndex.value = 1,
                  ),
                  SidebarItemData(
                    title: 'Order',
                    icon: CupertinoIcons.bag_fill,
                    index: 2,
                    badgeCount: controller.activeOrderCount.value,
                    onTap: () => controller.stateSelectedIndex.value = 2,
                  ),
                  SidebarItemData(
                    title: 'Customer',
                    icon: CupertinoIcons.person_3_fill,
                    index: 3,
                    onTap: () => controller.stateSelectedIndex.value = 3,
                  ),
                  SidebarItemData(
                    title: 'Reconciliation',
                    icon: CupertinoIcons.doc_text_fill,
                    index: 4,
                    onTap: () => controller.stateSelectedIndex.value = 4,
                  ),
                  SidebarItemData(
                    title: 'Reports',
                    icon: CupertinoIcons.chart_bar_alt_fill,
                    index: 5,
                    onTap: () => controller.stateSelectedIndex.value = 5,
                  ),
                  SidebarItemData(
                    title: 'Kitchen',
                    icon: CupertinoIcons.lab_flask_solid,
                    index: 8,
                    onTap: () => controller.stateSelectedIndex.value = 8,
                  ),
                ],
                settingItems: [
                  SidebarItemData(
                    title: 'General',
                    icon: CupertinoIcons.gear_alt_fill,
                    index: 6,
                    onTap: () => controller.stateSelectedIndex.value = 6,
                  ),
                  // SidebarItemData(
                  //   title: 'Product',
                  //   icon: CupertinoIcons.cube_box_fill,
                  //   index: 10,
                  //   onTap: () => controller.stateSelectedIndex.value = 10,
                  // ),
                  SidebarItemData(
                    title: 'Profile',
                    icon: CupertinoIcons.person_fill,
                    index: 7,
                    onTap: () => controller.stateSelectedIndex.value = 7,
                  ),
                  // Developer menu — only visible when Developer Mode is enabled
                  if (Get.isRegistered<AppService>() && Get.find<AppService>().developerMode.value)
                    SidebarItemData(
                      title: 'Developer',
                      icon: CupertinoIcons.doc_text_search,
                      index: 9,
                      onTap: () => controller.stateSelectedIndex.value = 9,
                    ),

                  SidebarItemData(
                    title: 'Logout Location',
                    icon: CupertinoIcons.power,
                    onTap: _showLogout,
                  ),
                ],
              ),
            Expanded(
            // FIX: Use a switch expression for LAZY rendering.
            // Previously AdminOnRailMenu.menuContent[index] was a static list of
            // pre-instantiated widgets — ALL screens (HomeScreen, ReportScreen, etc.)
            // were built at once, creating all their controllers simultaneously.
            // Now only the ACTIVE screen is built.
            child: _buildContent(controller.stateSelectedIndex.value),
          ),
        ],
      ),
     ),
    );
  }

  Widget _buildContent(int index) {
    switch (index) {
      case 0: return const HomeAdminScreen();
      case 1: return const HomeScreen();
      case 2: return const OrderScreen();
      case 3: return const MemberScreen();
      case 4: return const RecapView();
      case 5: return const ReportScreen();
      case 6: return const SettingScreen();
      case 7: return const EmployeeProfileScreen();
      case 8: return const KitchenView();
      case 9: return const DatabaseInspectorScreen();
      case 10: return const ProductScreen();
      default: return const HomeAdminScreen();
    }
  }
}
