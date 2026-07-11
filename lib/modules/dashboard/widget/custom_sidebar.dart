import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/services/sync_service.dart';
import 'package:semesta_pos/modules/auth/controllers/auth_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class SidebarItemData {
  final String title;
  final IconData icon;
  final int? badgeCount;
  final VoidCallback onTap;
  final int? index;

  SidebarItemData({
    required this.title,
    required this.icon,
    this.badgeCount,
    required this.onTap,
    this.index,
  });
}

class CustomSidebar extends StatelessWidget {
  final int selectedIndex;
  final List<SidebarItemData> platformItems;
  final List<SidebarItemData> settingItems;
  final VoidCallback onCollapseToggle;
  final bool isCollapsed;

  const CustomSidebar({
    super.key,
    required this.selectedIndex,
    required this.platformItems,
    required this.settingItems,
    required this.onCollapseToggle,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    Color activeBgColor = AppTheme.primaryColor.withValues(alpha: 0.15);
    Color activeTextColor = AppTheme.primaryColor;
    Color inactiveTextColor = AppTheme.secondaryTextColor(context);
    Color inactiveIconColor = AppTheme.secondaryTextColor(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCollapsed ? 80.w : 200.w,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: AppTheme.sidebarColor(context),
        border: Border(
          right: BorderSide(color: AppTheme.borderColor(context), width: 1),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool showText = !isCollapsed && constraints.maxWidth >= 190.w;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                child: Obx(() {
                  final syncService = Get.isRegistered<SyncService>() ? Get.find<SyncService>() : null;
                  
                  final colorMap = {
                    'green': const Color(0xFF10B981),
                    'yellow': const Color(0xFFFBBF24),
                    'red': const Color(0xFFEF4444),
                  };
                  final statusColor = syncService != null 
                      ? (colorMap[syncService.syncIndicatorColor.value] ?? const Color(0xFF10B981))
                      : const Color(0xFF10B981);
                  final labelText = syncService != null ? syncService.syncTimeLabel.value : 'Sync OK';
                  final isSyncing = syncService != null && syncService.isSyncing.value;

                  return Column(
                    crossAxisAlignment: isCollapsed ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: isCollapsed
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        children: [
                          // Logo Icon (with overlay dot in collapsed mode)
                          GestureDetector(
                            onTap: () {
                              if (isCollapsed && syncService != null && !isSyncing) {
                                syncService.syncFullData();
                              }
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  CupertinoIcons.checkmark_seal_fill,
                                  color: activeTextColor,
                                  size: 24.sp,
                                ),
                                // In collapsed mode, display status indicator as an overlay badge on the logo icon
                                if (isCollapsed && syncService != null)
                                  Positioned(
                                    right: -4.w,
                                    top: -4.h,
                                    child: isSyncing
                                        ? SizedBox(
                                            width: 11.w,
                                            height: 11.w,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.8,
                                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                            ),
                                          )
                                        : Container(
                                            width: 10.w,
                                            height: 10.w,
                                            decoration: BoxDecoration(
                                              color: statusColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: AppTheme.sidebarColor(context), width: 1.5),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: statusColor.withValues(alpha: 0.3),
                                                  blurRadius: 3,
                                                  spreadRadius: 0.5,
                                                )
                                              ],
                                            ),
                                          ),
                                  ),
                              ],
                            ),
                          ),
                          if (showText) ...[
                            SizedBox(width: 8.w),
                            Text(
                              'Flink',
                              style: TextStyle(
                                fontFamily: AppTheme.fontBold,
                                fontSize: 20.sp,
                                color: AppTheme.textColor(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'POS',
                              style: TextStyle(
                                fontFamily: AppTheme.fontBold,
                                fontSize: 20.sp,
                                color: activeTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Expanded Sync Banner (di bawah logo)
                      if (showText && syncService != null) ...[
                        SizedBox(height: 14.h),
                        GestureDetector(
                          onTap: () {
                            if (!isSyncing) {
                              syncService.syncFullData();
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: statusColor.withValues(alpha: 0.15), width: 1),
                            ),
                            child: Row(
                              children: [
                                // Glowing indicator dot
                                isSyncing
                                    ? SizedBox(
                                        width: 8.w,
                                        height: 8.w,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.2,
                                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                        ),
                                      )
                                    : Container(
                                        width: 7.w,
                                        height: 7.w,
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: statusColor.withValues(alpha: 0.3),
                                              blurRadius: 3,
                                              spreadRadius: 0.5,
                                            )
                                          ],
                                        ),
                                      ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        labelText,
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontBold,
                                          fontSize: 10.sp,
                                          color: statusColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        () {
                                          if (labelText == "Offline") {
                                            return "Data disimpan lokal";
                                          } else if (labelText == "Menyelaraskan...") {
                                            final count = syncService.pendingSyncCount.value;
                                            return "$count data mengantre • otomatis";
                                          } else {
                                            return isSyncing ? "Sedang menyelaraskan..." : "Ketuk untuk sync manual";
                                          }
                                        }(),
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontRegular,
                                          fontSize: 8.sp,
                                          color: statusColor.withValues(alpha: 0.6),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Icon(
                                  isSyncing ? CupertinoIcons.arrow_2_circlepath : CupertinoIcons.refresh_thin,
                                  size: 11.sp,
                                  color: statusColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                }),
              ),
          Divider(color: AppTheme.borderColor(context), height: 1),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showText)
                    Padding(
                      padding:
                          EdgeInsets.only(left: 16.w, top: 16.h, bottom: 8.h),
                      child: Text(
                        'Platform Navigation',
                        style: TextStyle(
                          color: AppTheme.secondaryTextColor(context),
                          fontSize: AppTheme.fontSizeLabelMedium,
                          fontFamily: AppTheme.fontRegular,
                        ),
                      ),
                    ),
                  ...platformItems.asMap().entries.map((entry) {
                    return _buildSidebarItem(
                      item: entry.value,
                      isActive: entry.value.index != null &&
                          selectedIndex == entry.value.index,
                      activeBgColor: activeBgColor,
                      activeTextColor: activeTextColor,
                      inactiveTextColor: inactiveTextColor,
                      inactiveIconColor: inactiveIconColor,
                      showText: showText,
                    );
                  }),
                  if (showText)
                    Padding(
                      padding:
                          EdgeInsets.only(left: 16.w, top: 16.h, bottom: 8.h),
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          color: AppTheme.secondaryTextColor(context),
                          fontSize: AppTheme.fontSizeLabelSmall,
                          fontFamily: AppTheme.fontRegular,
                        ),
                      ),
                    ),
                  ...settingItems.asMap().entries.map((entry) {
                    return _buildSidebarItem(
                      item: entry.value,
                      isActive: entry.value.index != null &&
                          selectedIndex == entry.value.index,
                      activeBgColor: activeBgColor,
                      activeTextColor: activeTextColor,
                      inactiveTextColor: inactiveTextColor,
                      inactiveIconColor: inactiveIconColor,
                      showText: showText,
                    );
                  }),
                ],
              ),
            ),
          ),

          Divider(color: AppTheme.borderColor(context), height: 1),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 8.w : 16.w, vertical: 16.h),
            child: _buildSwitchUser(context, showText),
          ),
          Divider(color: AppTheme.borderColor(context), height: 1),
          InkWell(
            onTap: onCollapseToggle,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              alignment: isCollapsed ? Alignment.center : Alignment.centerRight,
              child: Icon(
                isCollapsed
                    ? CupertinoIcons.line_horizontal_3
                    : Icons.format_indent_decrease,
                color: AppTheme.textColorSecondary,
                size: 20.sp,
              ),
            ),
          ),
        ],
       );
      },
     ),
    );
  }

  Widget _buildSidebarItem({
    required SidebarItemData item,
    required bool isActive,
    required Color activeBgColor,
    required Color activeTextColor,
    required Color inactiveTextColor,
    required Color inactiveIconColor,
    required bool showText,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: isActive ? activeBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            clipBehavior: Clip.none,
            child: SizedBox(
              width: isCollapsed ? (80.w - 48.w) : (200.w - 48.w),
              child: Row(
                mainAxisAlignment: isCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                   Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    item.icon,
                    color: isActive ? activeTextColor : inactiveIconColor,
                    size: 20.sp,
                  ),
                  if (isCollapsed &&
                      item.badgeCount != null &&
                      item.badgeCount! > 0)
                    Positioned(
                      right: -10.w,
                      top: -10.h,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 18.w,
                          minHeight: 18.h,
                        ),
                        child: Center(
                          child: Text(
                            item.badgeCount! > 9 ? '9+' : item.badgeCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (showText) ...[
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    item.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? activeTextColor : inactiveTextColor,
                      fontSize: AppTheme.fontSizeLabelLarge,
                      fontFamily:
                          isActive ? AppTheme.fontBold : AppTheme.fontRegular,
                    ),
                  ),
                ),
                if (item.badgeCount != null && item.badgeCount! > 0)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: activeTextColor,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      item.badgeCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppTheme.fontSizeBadge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ]
            ],
          ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchUser(BuildContext context, bool showText) {
    return InkWell(
      onTap: () {
        if (!Get.isRegistered<AuthController>()) {
          Get.put(AuthController());
        }
        Get.find<AuthController>().changeUser();
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: isCollapsed 
            ? EdgeInsets.symmetric(vertical: 12.h) 
            : EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            width: isCollapsed ? (80.w - 16.w) : (200.w - 64.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.person_2_alt, color: AppTheme.primaryColor, size: 20.sp),
                if (showText) ...[
                  SizedBox(width: 10.w),
                  Expanded( 
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Switch Staff",
                        style: TextStyle(
                          fontFamily: AppTheme.fontBold,
                          fontSize: 14.sp,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
