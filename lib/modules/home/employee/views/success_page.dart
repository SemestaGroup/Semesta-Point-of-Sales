import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/util/constans.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:semesta_pos/modules/home/employee/controllers/success_controller.dart';
import 'package:semesta_pos/routes/app_pages.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class SuccessPage extends GetView<SuccessController> {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/anim/success_anim.json',
                  width: 150.w,
                  height: 150.h,
                  repeat: false,
                ),
                SizedBox(height: 24.h),
                Text(
                  "Order Successful!",
                  style: TextStyle(
                      fontFamily: AppTheme.fontBold,
                      fontSize: 24.sp,
                      color: AppTheme.textColor(context)),
                ),
                SizedBox(height: 8.h),
                Text(
                  'The transaction has been completed successfully.',
                  style: TextStyle(
                      fontFamily: AppTheme.fontMedium,
                      fontSize: 14.sp,
                      color: AppTheme.secondaryTextColor(context)),
                ),
                SizedBox(height: 48.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      onPressed: () => controller.printToThermal(),
                      icon: Icons.print_rounded,
                      label: "Print Receipt",
                      color: AppTheme.primaryColor,
                      isPrimary: true,
                    ),
                    SizedBox(width: 16.w),
                    _buildActionButton(
                      onPressed: () => controller.showModalNota(),
                      icon: Icons.receipt_long_rounded,
                      label: "View Invoice",
                      color: Colors.orange,
                      isPrimary: false,
                    ),
                  ],
                ),
                SizedBox(height: 32.h),
                TextButton(
                  onPressed: () {
                    if (controller.userService.getPrefInt(Constants.role) == 1) {
                      Get.offAllNamed(Routes.dashboardAdmin, arguments: {'index': 1});
                    } else {
                      Get.offAllNamed(Routes.dashboardEmployee, arguments: {'index': 1});
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("NEW TRANSACTION", 
                          style: TextStyle(fontFamily: AppTheme.fontBold, fontSize: 14.sp, color: AppTheme.primaryColor)),
                      SizedBox(width: 8.w),
                      Icon(Icons.arrow_forward_rounded, size: 18.sp, color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isPrimary,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isPrimary ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: isPrimary ? null : Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isPrimary ? Colors.white : color, size: 20.sp),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontBold,
                fontSize: 14.sp,
                color: isPrimary ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
