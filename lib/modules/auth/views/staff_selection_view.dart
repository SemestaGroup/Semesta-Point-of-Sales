import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:semesta_pos/core/models/staff/staff_model.dart';
import 'package:semesta_pos/modules/auth/controllers/auth_controller.dart';
import 'package:semesta_pos/modules/auth/views/widgets/pin_pad_widget.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class StaffSelectionView extends GetView<AuthController> {
  const StaffSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("StaffSelectionView: build() started");
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 150.w,
        leading: Padding(
          padding: EdgeInsets.only(left: 24.w, top: 8.h, bottom: 8.h),
          child: InkWell(
            onTap: () => Get.back(),
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppTheme.borderColor(context)),
                boxShadow: isDark ? [] : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryColor, size: 16.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Back',
                    style: TextStyle(
                      fontFamily: AppTheme.fontBold,
                      fontSize: 14.sp,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          Builder(
            builder: (context) {
              try {
                final role = controller.userService.getRole().toLowerCase();
                if (role != 'owner') return const SizedBox.shrink();

                return Padding(
                  padding: EdgeInsets.only(right: 24.w, top: 8.h, bottom: 8.h),
                  child: Row(
                    children: [
                      // Sync Staff button
                      Obx(() => InkWell(
                        onTap: controller.isLoading.value ? null : () => controller.refreshStaff(),
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              controller.isLoading.value
                                ? SizedBox(width: 16.w, height: 16.w, child: const CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                                : Icon(Icons.sync_rounded, color: AppTheme.primaryColor, size: 16.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'Sync Staff',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontBold,
                                  fontSize: 14.sp,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                      SizedBox(width: 12.w),
                      // Logout Location button
                      InkWell(
                        onTap: () => controller.logoutLocation(),
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.power_settings_new, color: Colors.redAccent, size: 16.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'Logout Location',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontBold,
                                  fontSize: 14.sp,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                return const SizedBox.shrink();
              }
            }
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 100.w),
        child: Column(
          children: [
            SizedBox(height: 30.h),
            Text(
              'Switch Staff',
              style: TextStyle(
                fontFamily: AppTheme.fontBold,
                fontSize: 32.sp,
                color: AppTheme.textColor(context),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please select your account and enter your PIN to continue.',
              style: TextStyle(
                fontFamily: AppTheme.fontMedium,
                fontSize: 16.sp,
                color: AppTheme.secondaryTextColor(context),
              ),
            ),
            SizedBox(height: 40.h),
            
            // Search Bar
            _buildSearchBar(context),
            
            SizedBox(height: 40.h),
            
            // Grid of Staff
            Expanded(
              child: Obx(() {
                if (controller.filteredStaff.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.person_3, size: 60.sp, color: AppTheme.borderColor(context)),
                        SizedBox(height: 16.h),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontFamily: AppTheme.fontMedium,
                            fontSize: 18.sp,
                            color: AppTheme.textColorSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: EdgeInsets.only(bottom: 20.h, top: 10.h),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 30.w,
                    mainAxisSpacing: 30.h,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: controller.filteredStaff.length +
                      (controller.userService.getRole().toLowerCase() == 'owner' ? 1 : 0),
                  itemBuilder: (context, index) {
                    final isOwner = controller.userService.getRole().toLowerCase() == 'owner';
                    // Last slot for owner = Add Staff card
                    if (isOwner && index == controller.filteredStaff.length) {
                      return _buildAddStaffCard(context);
                    }
                    final staff = controller.filteredStaff[index];
                    return _buildStaffItem(context, staff);
                  },
                );
              }),
            ),
            
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Text(
                'Powered by Semesta POS',
                style: TextStyle(
                  fontFamily: AppTheme.fontMedium,
                  fontSize: 12.sp,
                  color: AppTheme.borderColor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      width: 500.w,
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller.searchController,
        decoration: InputDecoration(
          hintText: 'Search by name or role...',
          hintStyle: TextStyle(
            fontFamily: AppTheme.fontMedium,
            fontSize: 15.sp,
            color: AppTheme.secondaryTextColor(context),
          ),
          prefixIcon: Icon(CupertinoIcons.search, color: AppTheme.secondaryTextColor(context), size: 20.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 18.h),
        ),
        style: TextStyle(
          fontFamily: AppTheme.fontMedium,
          fontSize: 15.sp,
          color: AppTheme.textColor(context),
        ),
      ),
    );
  }

  Widget _buildStaffItem(BuildContext context, StaffModel staff) {
    final List<Color> colors = [
      const Color(0xFF264653),
      const Color(0xFF2A9D8F),
      const Color(0xFFE9C46A),
      const Color(0xFFF4A261),
      const Color(0xFFE76F51),
      const Color(0xFF1D3557),
      const Color(0xFF457B9D),
    ];
    
    final Color avatarColor = colors[staff.fullName.hashCode % colors.length];

    return GestureDetector(
      onTap: () => _showPinDialog(context, staff),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: AppTheme.borderColor(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90.w,
              height: 90.w,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.cardColor(context), width: 4.w),
                boxShadow: [
                  BoxShadow(
                    color: avatarColor.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                staff.initials,
                style: TextStyle(
                  fontFamily: AppTheme.fontBold,
                  fontSize: 32.sp,
                  color: Colors.white, // Ensure white text for colors
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                staff.fullName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontBold,
                  fontSize: 18.sp,
                  color: AppTheme.textColor(context),
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                (staff.role ?? 'User').toUpperCase(),
                style: TextStyle(
                  fontFamily: AppTheme.fontBold,
                  fontSize: 10.sp,
                  color: AppTheme.primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinDialog(BuildContext context, StaffModel staff) {
    Get.dialog(
      PinPadWidget(
        staffName: staff.fullName,
        initials: staff.initials,
        onCompleted: (pin) => _verifyPin(staff, pin),
      ),
      barrierDismissible: true,
    );
  }

  void _verifyPin(StaffModel staff, String inputPin) async {
    final storedPin = (staff.pin ?? '').trim();

    // If no PIN is configured for this staff, allow access directly
    // (Admin should configure a PIN in the backend for security)
    if (storedPin.isEmpty) {
      Get.back(); // close dialog
      Get.snackbar(
        'No PIN Set',
        'Warning: No PIN configured for ${staff.fullName}. Please set a PIN in the backend.',
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      controller.completeStaffLogin(staff);
      return;
    }

    if (inputPin == storedPin) {
      Get.back(); // close dialog
      controller.completeStaffLogin(staff);
    } else {
      // Shake/clear feedback — snackbar over the dialog
      Get.snackbar(
        'Incorrect PIN',
        'The PIN you entered is wrong. Please try again.',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Widget _buildAddStaffCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showAddStaffDialog(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.08 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90.w,
              height: 90.w,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_add_rounded, size: 36.sp, color: AppTheme.primaryColor),
            ),
            SizedBox(height: 24.h),
            Text(
              'Tambah Staff',
              style: TextStyle(
                fontFamily: AppTheme.fontBold,
                fontSize: 18.sp,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'OWNER ONLY',
                style: TextStyle(
                  fontFamily: AppTheme.fontBold,
                  fontSize: 10.sp,
                  color: AppTheme.primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    final firstnameCtrl = TextEditingController();
    final lastnameCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    final selectedRole = '2'.obs; // Default: Cashier
    final roleLabels = {'1': 'Owner', '2': 'Cashier', '3': 'Kitchen', '4': 'Supervisor'};

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 60.w, vertical: 40.h),
        child: Container(
          width: 480.w,
          padding: EdgeInsets.all(32.w),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tambah Staff Baru', style: TextStyle(fontFamily: AppTheme.fontBold, fontSize: 22.sp, color: AppTheme.textColor(context))),
                  IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close, color: Colors.grey)),
                ],
              ),
              SizedBox(height: 24.h),
              TextField(
                controller: firstnameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Depan *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: lastnameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Belakang (opsional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'PIN (default: 0000)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              SizedBox(height: 16.h),
              Obx(() => DropdownButtonFormField<String>(
                initialValue: selectedRole.value,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                items: roleLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (val) { if (val != null) selectedRole.value = val; },
              )),
              SizedBox(height: 28.h),
              Obx(() => SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: controller.isAddingStaff.value
                    ? null
                    : () async {
                        if (firstnameCtrl.text.trim().isEmpty) {
                          Get.snackbar('Perhatian', 'Nama depan harus diisi.',
                              backgroundColor: Colors.orange.shade600, colorText: Colors.white);
                          return;
                        }
                        await controller.addStaff(
                          firstname: firstnameCtrl.text,
                          lastname: lastnameCtrl.text.isEmpty ? null : lastnameCtrl.text,
                          roleId: selectedRole.value,
                          pin: pinCtrl.text.isEmpty ? '0000' : pinCtrl.text,
                        );
                        Get.back();
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    elevation: 0,
                  ),
                  child: controller.isAddingStaff.value
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text('Tambahkan Staff', style: TextStyle(fontFamily: AppTheme.fontBold, fontSize: 16.sp)),
                ),
              )),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}

