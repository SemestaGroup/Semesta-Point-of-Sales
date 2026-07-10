import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/modules/sync/controllers/sync_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class SyncViewTablet extends StatelessWidget {
  final SyncController controller;

  const SyncViewTablet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
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
              horizontal: 32.w,
              vertical: 40.h,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 60.h),
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_2_circlepath,
                    size: 80.sp,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: 48.h),
                Text(
                  "Synchronizing Data",
                  style: AppTheme.titleLarge.copyWith(
                    fontSize: 28.sp,
                    fontFamily: AppTheme.fontBold,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12.0),
                Text(
                  "Please wait while we prepare your workspace\nConnecting to secure server...",
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 16.sp,
                    color: AppTheme.secondaryTextColor(context),
                    fontFamily: AppTheme.fontRegular,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 80.h),
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
                                  fontSize: 13.sp,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              "${(controller.progress.value * 100).toInt()}%",
                              style: AppTheme.labelMedium.copyWith(
                                fontFamily: AppTheme.fontBold,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: LinearProgressIndicator(
                            value: controller.progress.value,
                            backgroundColor: AppTheme.borderColor(context),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor),
                            minHeight: 8.h,
                          ),
                        ),
                      ],
                    )),
                SizedBox(height: 40.h),
                Text(
                  "Offline Mode will be available after sync",
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.secondaryTextColor(context).withValues(alpha: 0.6),
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
