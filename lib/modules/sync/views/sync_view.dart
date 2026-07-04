import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/modules/sync/controllers/sync_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class SyncView extends GetView<SyncController> {
  const SyncView({super.key});

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 600;
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = _isMobile(context);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.05),
              AppTheme.scaffoldBackgroundColor(context),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20.0 : 32.w,
              vertical: isMobile ? 30.0 : 40.h,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: isMobile ? 40.0 : 60.h),
                // Elegant Sync Icon with Glow
                Container(
                  padding: EdgeInsets.all(isMobile ? 18.0 : 24.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_2_circlepath,
                    size: isMobile ? 50.0 : 80.sp,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: isMobile ? 30.0 : 48.h),
                Text(
                  "Synchronizing Data",
                  style: AppTheme.titleLarge.copyWith(
                    fontSize: isMobile ? 20.0 : 28.sp,
                    fontFamily: AppTheme.fontBold,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.0),
                Text(
                  "Please wait while we prepare your workspace\nConnecting to secure server...",
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: isMobile ? 13.0 : 16.sp,
                    color: AppTheme.secondaryTextColor(context),
                    fontFamily: AppTheme.fontRegular,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 40.0 : 80.h),
                // Progress Section
                Obx(() => Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                controller.status.value,
                                style: AppTheme.labelMedium.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontFamily: AppTheme.fontMedium,
                                  fontSize: isMobile ? 12.0 : 13.sp,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              "${(controller.progress.value * 100).toInt()}%",
                              style: AppTheme.labelMedium.copyWith(
                                fontFamily: AppTheme.fontBold,
                                fontSize: isMobile ? 12.0 : 13.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.0),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: LinearProgressIndicator(
                            value: controller.progress.value,
                            backgroundColor: AppTheme.borderColor(context),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor),
                            minHeight: isMobile ? 6.0 : 8.h,
                          ),
                        ),
                      ],
                    )),
                SizedBox(height: isMobile ? 24.0 : 40.h),
                Text(
                  "Offline Mode will be available after sync",
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.secondaryTextColor(context).withValues(alpha: 0.6),
                    fontSize: isMobile ? 10.0 : 11.sp,
                  ),
                ),
                SizedBox(height: isMobile ? 16.0 : 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
