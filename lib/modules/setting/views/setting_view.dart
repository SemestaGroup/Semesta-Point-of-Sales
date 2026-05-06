import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/services/app_service.dart';
import 'package:semesta_pos/core/services/theme_service.dart';
import 'package:semesta_pos/modules/home/employee/controllers/shift_controller.dart';
import 'package:semesta_pos/modules/setting/controllers/setting_controller.dart';
import 'package:semesta_pos/modules/setting/widgets/manage_printer_dialog.dart';
import 'package:semesta_pos/modules/setting/widgets/manage_shift_dialog.dart';
import 'package:semesta_pos/styles/app_theme.dart';
import 'package:semesta_pos/routes/app_pages.dart';

class SettingScreen extends GetView<SettingController> {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SettingController>()) {
      Get.lazyPut(() => SettingController());
    }
    final controller = Get.find<SettingController>();
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      body: SafeArea(
        child: Obx(() => controller.isLoading.value
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              )
            : Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // General Settings Section
                          _buildSectionTitle(context, 'General Information'),
                          SizedBox(height: 16.h),
                          _buildCard(
                            context,
                            child: Column(
                              children: [
                                _buildInputField(
                                  context,
                                  controller:
                                      controller.companyNameFieldController,
                                  label: 'Company Name',
                                  hint: 'Enter company name',
                                  icon: CupertinoIcons.building_2_fill,
                                ),
                                SizedBox(height: 20.h),
                                _buildInputField(
                                  context,
                                  controller:
                                      controller.companyTelpFieldController,
                                  label: 'Phone Number',
                                  hint: 'Enter phone number',
                                  icon: CupertinoIcons.phone_fill,
                                ),
                                SizedBox(height: 20.h),
                                _buildInputField(
                                  context,
                                  controller:
                                      controller.companyAddressFieldController,
                                  label: 'Address',
                                  hint: 'Enter company address',
                                  icon: CupertinoIcons.house_fill,
                                  maxLines: 3,
                                ),
                                SizedBox(height: 20.h),
                                _buildInputField(
                                  context,
                                  controller:
                                      controller.companyDiscFieldController,
                                  label: 'Discount (%)',
                                  hint: 'Enter default discount',
                                  icon: CupertinoIcons.percent,
                                  keyboardType: TextInputType.number,
                                ),
                                SizedBox(height: 20.h),
                                Divider(
                                    height: 1.h,
                                    color: AppTheme.borderColor(context)),
                                InkWell(
                                  onTap: () =>
                                      _showAppInfoDialog(context, controller),
                                  child: _buildSettingTile(
                                    context,
                                    icon: CupertinoIcons.info_circle_fill,
                                    title: 'App Info',
                                    subtitle:
                                        'Version and developer information',
                                    trailing: Icon(CupertinoIcons.chevron_right,
                                        color: Colors.grey.shade400,
                                        size: 20.sp),
                                  ),
                                ),
                                Divider(
                                    height: 1.h,
                                    color: AppTheme.borderColor(context)),
                                InkWell(
                                  onTap: () {
                                    if (!controller.isCheckingUpdate.value) {
                                      controller.checkUpdate();
                                    }
                                  },
                                  child: Obx(() => _buildSettingTile(
                                        context,
                                        icon:
                                            CupertinoIcons.cloud_download_fill,
                                        title: 'Check for Updates',
                                        subtitle:
                                            'Check for legacy app updates',
                                        trailing: controller
                                                .isCheckingUpdate.value
                                            ? SizedBox(
                                                width: 20.w,
                                                height: 20.w,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2.w,
                                                        color: AppTheme
                                                            .primaryColor))
                                            : Icon(CupertinoIcons.chevron_right,
                                                color: Colors.grey.shade400,
                                                size: 20.sp),
                                      )),
                                ),
                                Divider(
                                    height: 1.h,
                                    color: AppTheme.borderColor(context)),
                                Obx(() {
                                  final appService = Get.isRegistered<AppService>()
        ? Get.find<AppService>()
        : Get.put(AppService());
                                  return _buildSettingTile(
                                    context,
                                    icon: CupertinoIcons.cube_box_fill,
                                    title: 'Allow Selling Out of Stock',
                                    subtitle:
                                        'Enable adding products to cart even when system stock is 0',
                                    trailing: CupertinoSwitch(
                                      value: appService.allowZeroStock.value,
                                      activeTrackColor: AppTheme.primaryColor,
                                      onChanged: (v) =>
                                          appService.setAllowZeroStock(v),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),

                          // Operational Settings Section (Only for Managerial Roles)
                          if (controller.userService.isManagerialRole()) ...[
                            _buildSectionTitle(context, 'Operational Settings'),
                            SizedBox(height: 16.h),
                            _buildCard(
                              context,
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      if (!Get.isRegistered<ShiftController>()) {
                                        Get.lazyPut(() => ShiftController());
                                      }
                                      Get.dialog(const ManageShiftDialog());
                                    },
                                    child: _buildSettingTile(
                                      context,
                                      icon: CupertinoIcons.clock_fill,
                                      title: 'Manage Shifts',
                                      subtitle:
                                          'Predefine shifts and assigned staff',
                                      trailing: Icon(
                                          CupertinoIcons.chevron_right,
                                          color: Colors.grey.shade400,
                                          size: 20.sp),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.h),
                          ],

                          // Display Settings Section
                          _buildSectionTitle(context, 'Display Settings'),
                          SizedBox(height: 16.h),
                          _buildCard(
                            context,
                            child: Column(
                              children: [
                                Obx(() {
                                  final appService = Get.find<AppService>();
                                  final display = appService.posSettings['display'] ?? {};
                                  return Column(
                                    children: [
                                      Obx(() {
                                        final themeService = Get.isRegistered<ThemeService>()
                                            ? Get.find<ThemeService>()
                                            : Get.put(ThemeService());
                                        return _buildSettingTile(
                                          context,
                                          icon: CupertinoIcons.moon_fill,
                                          title: 'Dark Mode',
                                          subtitle: 'Switch between light and dark themes',
                                          trailing: CupertinoSwitch(
                                            value: themeService.isDarkMode.value,
                                            activeTrackColor: AppTheme.primaryColor,
                                            onChanged: (v) => themeService.setTheme(v),
                                          ),
                                        );
                                      }),
                                      Divider(height: 1.h, color: AppTheme.borderColor(context)),
                                      _buildSettingTile(
                                        context,
                                        icon: CupertinoIcons.photo,
                                        title: 'Show Product Image',
                                        subtitle: 'Images are always shown (required)',
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(CupertinoIcons.lock_fill,
                                                size: 14.sp,
                                                color: AppTheme.primaryColor.withValues(alpha: 0.6)),
                                            SizedBox(width: 6.w),
                                            const Opacity(
                                              opacity: 0.6,
                                              child: CupertinoSwitch(
                                                value: true,
                                                activeTrackColor: AppTheme.primaryColor,
                                                onChanged: null, // LOCKED
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Divider(height: 1.h, color: AppTheme.borderColor(context)),
                                      _buildSettingTile(
                                        context,
                                        icon: CupertinoIcons.textformat,
                                        title: 'Show Product Name',
                                        subtitle: 'Display names on product cards',
                                        trailing: CupertinoSwitch(
                                          value: display['show_name'] ?? true,
                                          activeTrackColor: AppTheme.primaryColor,
                                          onChanged: (v) => appService.updateDisplaySetting('show_name', v),
                                        ),
                                      ),
                                      Divider(height: 1.h, color: AppTheme.borderColor(context)),
                                      _buildSettingTile(
                                        context,
                                        icon: CupertinoIcons.money_dollar,
                                        title: 'Show Product Price',
                                        subtitle: 'Display prices on product cards',
                                        trailing: CupertinoSwitch(
                                          value: display['show_price'] ?? false,
                                          activeTrackColor: AppTheme.primaryColor,
                                          onChanged: (v) => appService.updateDisplaySetting('show_price', v),
                                        ),
                                      ),
                                      Divider(height: 1.h, color: AppTheme.borderColor(context)),
                                      _buildSettingTile(
                                        context,
                                        icon: CupertinoIcons.cube_box,
                                        title: 'Show Product Stock',
                                        subtitle: 'Display stock levels on product cards',
                                        trailing: CupertinoSwitch(
                                          value: display['show_stock'] ?? false,
                                          activeTrackColor: AppTheme.primaryColor,
                                          onChanged: (v) => appService.updateDisplaySetting('show_stock', v),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),

                          // Data Synchronization Section
                          _buildSectionTitle(context, 'Data Synchronization'),
                          SizedBox(height: 16.h),
                          _buildCard(
                            context,
                            child: Column(
                              children: [
                                _buildSyncTile(
                                  context,
                                  icon: CupertinoIcons.refresh_thick,
                                  title: 'Sync Master Data',
                                  subtitle:
                                      'Update Products, Members, and Orders from server',
                                  onTap: () => controller.syncAllData(),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),

                          // Printer Settings Section
                          _buildSectionTitle(context, 'Printer Settings'),
                          SizedBox(height: 16.h),
                          _buildCard(
                            context,
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: () => Get.dialog(
                                      const ManagePrinterDialog()),
                                  child: Obx(() {
                                    final count = controller.assignedPrinters.length;
                                    final connectedCount = controller.assignedPrinters.where((p) => p.isConnected).length;
                                    return _buildSettingTile(
                                      context,
                                      icon: CupertinoIcons.printer_fill,
                                      title: 'Manage Printer',
                                      subtitle: count == 0 
                                          ? 'No printers configured yet' 
                                          : '$connectedCount / $count Printers Connected',
                                      trailing: Icon(CupertinoIcons.chevron_right,
                                          color: Colors.grey.shade400,
                                          size: 20.sp),
                                    );
                                  }),
                                ),
                                Divider(height: 1.h, color: AppTheme.borderColor(context)),
                                Obx(() {
                                  final appService = Get.find<AppService>();
                                  final printing = appService.posSettings['printing'] ?? {};
                                  return _buildSettingTile(
                                    context,
                                    icon: CupertinoIcons.doc_plaintext,
                                    title: 'Auto Print Receipt',
                                    subtitle: 'Automatically print receipt after payment',
                                    trailing: CupertinoSwitch(
                                      value: printing['auto_print'] ?? false,
                                      activeTrackColor: AppTheme.primaryColor,
                                      onChanged: (v) => appService.updatePrintingSetting('auto_print', v),
                                    ),
                                  );
                                }),
                                Divider(height: 1.h, color: AppTheme.borderColor(context)),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  child: _buildInputField(
                                    context,
                                    controller: controller.labelOffsetXFieldController,
                                    label: 'Label X-Offset (Dots)',
                                    hint: 'Default: 20',
                                    icon: CupertinoIcons.arrow_right_square_fill,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),

                          // Kitchen Settings Section
                          _buildSectionTitle(context, 'Kitchen Settings'),
                          SizedBox(height: 16.h),
                          _buildCard(
                            context,
                            child: Obx(() {
                              final appService = Get.find<AppService>();
                              final currentMode = appService.kitchenMode.value;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 12.h),
                                    child: Text(
                                      'Send to Kitchen Mode',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontMedium,
                                        fontSize: AppTheme.fontSizeLabelLarge,
                                        color: AppTheme.textColor(context),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Choose how orders are sent to the kitchen when payment is made.',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontRegular,
                                      fontSize: AppTheme.fontSizeLabelSmall,
                                      color: AppTheme.secondaryTextColor(context),
                                    ),
                                  ),
                                  SizedBox(height: 20.h),
                                  _buildKitchenModeOption(
                                    context,
                                    mode: 'printer',
                                    currentMode: currentMode,
                                    icon: CupertinoIcons.printer_fill,
                                    title: 'Kitchen Printer',
                                    subtitle: 'Order ticket is printed to the registered kitchen printer. Works offline.',
                                    onTap: () => appService.updateKitchenSetting('printer'),
                                  ),
                                  SizedBox(height: 12.h),
                                  _buildKitchenModeOption(
                                    context,
                                    mode: 'livesync',
                                    currentMode: currentMode,
                                    icon: CupertinoIcons.wifi,
                                    title: 'Live Sync (KDS)',
                                    subtitle: 'Order is pushed to the Kitchen Display System in real-time. Requires the POS to be online.',
                                    onTap: () => appService.updateKitchenSetting('livesync'),
                                  ),
                                ],
                              );
                            }),
                          ),
                          SizedBox(height: 24.h),

                          // POS Settings Section
                          _buildSectionTitle(context, 'POS Settings'),

                          SizedBox(height: 16.h),
                          _buildCard(
                            context,
                            child: Column(
                              children: [
                                _buildSettingTile(
                                  context,
                                  icon: CupertinoIcons.cart,
                                  title: 'Default Customer',
                                  subtitle:
                                      'Walk-in customer for general sales',
                                  trailing: Icon(
                                    CupertinoIcons.chevron_right,
                                    color: Colors.grey.shade400,
                                    size: 20.sp,
                                  ),
                                ),
                                Divider(
                                    height: 1.h,
                                    color: AppTheme.borderColor(context)),
                                Obx(() {
                                  final appService = Get.find<AppService>();
                                  return _buildSettingTile(
                                    context,
                                    icon: CupertinoIcons.percent,
                                    title: 'Default Discount',
                                    subtitle:
                                        'Apply discount to all transactions',
                                    trailing: CupertinoSwitch(
                                      value:
                                          appService.useDefaultDiscount.value,
                                      activeTrackColor: AppTheme.primaryColor,
                                      onChanged: (v) =>
                                          appService.setUseDefaultDiscount(v),
                                    ),
                                  );
                                }),
                                Divider(
                                    height: 1.h,
                                    color: AppTheme.borderColor(context)),
                                _buildSettingTile(
                                  context,
                                  icon: CupertinoIcons.doc_text,
                                  title: 'Invoice Number Format',
                                  subtitle: 'Auto-generate invoice numbers',
                                  trailing: Text(
                                    'INV-YYYYMMDD-###',
                                    style: TextStyle(
                                      fontSize: AppTheme.fontSizeLabelSmall,
                                      color:
                                          AppTheme.secondaryTextColor(context),
                                      fontFamily: AppTheme.fontRegular,
                                    ),
                                  ),
                                ),
                                Divider(
                                    height: 1.h,
                                    color: AppTheme.borderColor(context)),
                                _buildSettingTile(
                                  context,
                                  icon: CupertinoIcons.clock,
                                  title: 'Fiscal Year Start',
                                  subtitle: 'Set your business fiscal year',
                                  trailing: Text(
                                    'January',
                                    style: TextStyle(
                                      fontSize: AppTheme.fontSizeLabelMedium,
                                      color: AppTheme.textColor(context),
                                      fontFamily: AppTheme.fontMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),

                          // Developer Settings Section (Owner only)
                          if (controller.userService.getRole().toLowerCase() == 'owner') ...[
                            _buildSectionTitle(context, 'Developer'),
                            SizedBox(height: 16.h),
                            _buildCard(
                              context,
                              child: Obx(() {
                                final appService = Get.find<AppService>();
                                return Column(
                                  children: [
                                    _buildSettingTile(
                                      context,
                                      icon: CupertinoIcons.wrench_fill,
                                      title: 'Developer Mode',
                                      subtitle: 'Enables SQLite Inspector menu and detailed error logs. Owner-only.',
                                      trailing: CupertinoSwitch(
                                        value: appService.developerMode.value,
                                        activeTrackColor: Colors.deepPurple,
                                        onChanged: (v) {
                                          if (controller.userService.getRole().toLowerCase() == 'owner') {
                                            appService.setDeveloperMode(v);
                                            Get.snackbar(
                                              'Developer Mode ${v ? 'ON' : 'OFF'}',
                                              v ? 'SQLite Inspector & detailed errors are now visible.' : 'Developer features hidden.',
                                              backgroundColor: v ? Colors.deepPurple.shade700 : Colors.grey.shade700,
                                              colorText: Colors.white,
                                              duration: const Duration(seconds: 2),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    if (appService.developerMode.value) ...[
                                      Divider(height: 1.h, color: AppTheme.borderColor(context)),
                                      InkWell(
                                        onTap: () => Get.toNamed(Routes.inspector),
                                        child: _buildSettingTile(
                                          context,
                                          icon: CupertinoIcons.table_fill,
                                          title: 'SQLite Inspector',
                                          subtitle: 'Browse and inspect local database tables',
                                          trailing: Icon(CupertinoIcons.chevron_right,
                                              color: Colors.grey.shade400, size: 20.sp),
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              }),
                            ),
                            SizedBox(height: 24.h),
                          ],

                          // Save Button
                          Align(
                            alignment: Alignment.centerRight,
                            child: Obx(() => SizedBox(
                                  width: 180.w,
                                  height: 48.h,
                                  child: ElevatedButton.icon(
                                    onPressed: controller.isLoadingStore.value
                                        ? null
                                        : () => controller.formValidate(),
                                    icon: controller.isLoadingStore.value
                                        ? SizedBox(
                                            width: 20.w,
                                            height: 20.w,
                                            child: const CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            CupertinoIcons
                                                .checkmark_circle_fill,
                                            size: 20.sp),
                                    label: Text(
                                      controller.isLoadingStore.value
                                          ? 'Saving...'
                                          : 'Save Changes',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontBold,
                                        fontSize: AppTheme.fontSizeBodyMedium,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      disabledBackgroundColor: AppTheme
                                          .primaryColor
                                          .withValues(alpha: 0.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                )),
                          ),
                          SizedBox(height: 32.h),
                        ],
                      ),
                    ),
                  ),
                ],
              )),
    ),
  );
}

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.settings_suggest_rounded,
                  color: AppTheme.primaryColor,
                  size: AppTheme.fontSizeTitleMedium + 4.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "General Settings",
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeTitleMedium,
                      fontFamily: AppTheme.fontBold,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "Manage your application preferences and general configurations",
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLabelLarge,
                      color:
                          isDark ? Colors.grey.shade100 : Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Obx(() => controller.isLoadingStore.value
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.primaryColor))
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 3.w, // Slightly thinner
          height: 16.h, // Slightly shorter
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTheme.fontBold, // Use Bold for better emphasis at smaller size
            fontSize: AppTheme.fontSizeBodyMedium,
            color: AppTheme.textColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: AppTheme.isDark(context)
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      padding: EdgeInsets.all(20.w),
      child: child,
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: AppTheme.isDark(context)
                  ? Colors.grey.shade800
                  : AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: AppTheme.isDark(context)
                  ? AppTheme.secondaryTextColor(context)
                  : AppTheme.primaryColor,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontMedium,
                    fontSize: AppTheme.fontSizeLabelLarge,
                    color: AppTheme.textColor(context),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTheme.fontRegular,
                    fontSize: AppTheme.fontSizeLabelSmall,
                    color: AppTheme.secondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          trailing,
        ],
      ),
    );
  }

  Widget _buildKitchenModeOption(
    BuildContext context, {
    required String mode,
    required String currentMode,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isSelected = mode == currentMode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.07)
              : AppTheme.scaffoldBackgroundColor(context),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor(context),
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.15)
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade500,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTheme.fontBold,
                      fontSize: AppTheme.fontSizeLabelLarge,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textColor(context),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppTheme.fontRegular,
                      fontSize: AppTheme.fontSizeLabelSmall,
                      color: AppTheme.secondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Colors.white, size: 13.sp)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontMedium,
            fontSize: AppTheme.fontSizeLabelSmall,
            color: AppTheme.secondaryTextColor(context),
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(
            fontFamily: AppTheme.fontMedium,
            fontSize: AppTheme.fontSizeBodyMedium, // Reduced from BodyLarge
            color: AppTheme.textColor(context),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: AppTheme.fontSizeLabelMedium,
            ),
            prefixIcon: Icon(
              icon,
              size: 18.sp, // Reduced from 20
              color: AppTheme.secondaryTextColor(context),
            ),
            filled: true,
            fillColor: AppTheme.isDark(context)
                ? Colors.grey.shade900
                : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r), // Slightly smaller radius
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 20.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeLabelLarge,
                        fontFamily: AppTheme.fontMedium,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppTheme.fontRegular,
                        fontSize: AppTheme.fontSizeLabelSmall,
                        color: AppTheme.secondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16.sp,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppInfoDialog(BuildContext context, SettingController controller) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          backgroundColor: AppTheme.cardColor(context),
          title: Row(
            children: [
          const Icon(CupertinoIcons.info_circle,
                  color: AppTheme.primaryColor),
              SizedBox(width: 10.w),
              Text('App Info',
                  style: TextStyle(
                      fontFamily: AppTheme.fontBold,
                      fontSize: 18.sp,
                      color: AppTheme.textColor(context))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(context, 'Association', 'Semesta POS'),
              _infoRow(
                  context,
                  'App Version',
                  controller.companyVersionFieldController.text.isNotEmpty
                      ? controller.companyVersionFieldController.text
                      : '1.0.0'),
              _infoRow(context, 'POS Programmer', 'Rizki & Semesta Team'),
              _infoRow(context, 'Web Back Office Programmer',
                  'Semesta Web Dev Team'),
              _infoRow(context, 'Support', 'support@semestaspace.com'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close',
                  style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontFamily: AppTheme.fontBold)),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.secondaryTextColor(context),
                  fontFamily: AppTheme.fontMedium)),
          SizedBox(height: 2.h),
          Text(value,
              style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textColor(context),
                  fontFamily: AppTheme.fontBold)),
          Divider(color: AppTheme.borderColor(context), height: 12.h),
        ],
      ),
    );
  }
}
