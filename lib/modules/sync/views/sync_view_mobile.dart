import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/modules/sync/controllers/sync_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class SyncViewMobile extends StatelessWidget {
  final SyncController controller;

  const SyncViewMobile({super.key, required this.controller});

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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40.0),
                Container(
                  padding: const EdgeInsets.all(18.0),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.arrow_2_circlepath,
                    size: 50.0,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 30.0),
                Text(
                  "Synchronizing Data",
                  style: AppTheme.titleLarge.copyWith(
                    fontSize: 20.0,
                    fontFamily: AppTheme.fontBold,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12.0),
                Text(
                  "Please wait while we prepare your workspace\nConnecting to secure server...",
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 13.0,
                    color: AppTheme.secondaryTextColor(context),
                    fontFamily: AppTheme.fontRegular,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40.0),
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
                                  fontSize: 12.0,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              "${(controller.progress.value * 100).toInt()}%",
                              style: AppTheme.labelMedium.copyWith(
                                fontFamily: AppTheme.fontBold,
                                fontSize: 12.0,
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
                            minHeight: 6.0,
                          ),
                        ),
                      ],
                    )),
                const SizedBox(height: 24.0),
                Text(
                  "Offline Mode will be available after sync",
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.secondaryTextColor(context).withValues(alpha: 0.6),
                    fontSize: 10.0,
                  ),
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
