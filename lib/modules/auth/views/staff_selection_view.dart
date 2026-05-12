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
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 150.w,
        leading: controller.userService.getPrefBool('has_active_staff')
            ? Padding(
                padding: EdgeInsets.only(left: 24.w, top: 8.h, bottom: 8.h),
                child: InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    decoration: BoxDecoration(
                        color: AppTheme.cardColor(context),
                        borderRadius: BorderRadius.circular(12.r),
                        border:
                            Border.all(color: AppTheme.borderColor(context)),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back_ios_new,
                            color: AppTheme.primaryColor, size: 16.sp),
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
              )
            : const SizedBox.shrink(),
        actions: [
          // Lock Account button (visible to everyone who has an active session to lock)
          if (controller.userService.getPrefBool('has_active_staff'))
            Padding(
              padding: EdgeInsets.only(right: 12.w, top: 8.h, bottom: 8.h),
              child: InkWell(
                onTap: () => controller.lockAccount(),
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                        color: Colors.orange.shade600.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          color: Colors.orange.shade700, size: 16.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Lock App',
                        style: TextStyle(
                          fontFamily: AppTheme.fontBold,
                          fontSize: 14.sp,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Builder(builder: (context) {
            try {
              final role = controller.userService.getRole().toLowerCase();
              if (role != 'owner') return const SizedBox.shrink();

              return Padding(
                padding: EdgeInsets.only(right: 24.w, top: 8.h, bottom: 8.h),
                child: Row(
                  children: [
                    // Sync Staff button
                    Obx(() => InkWell(
                          onTap: controller.isLoading.value
                              ? null
                              : () => controller.refreshStaff(),
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                controller.isLoading.value
                                    ? SizedBox(
                                        width: 16.w,
                                        height: 16.w,
                                        child: const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.primaryColor))
                                    : Icon(Icons.sync_rounded,
                                        color: AppTheme.primaryColor,
                                        size: 16.sp),
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
                          border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.power_settings_new,
                                color: Colors.redAccent, size: 16.sp),
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
          }),
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
                        Icon(CupertinoIcons.person_3,
                            size: 60.sp, color: AppTheme.borderColor(context)),
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
                      (controller.userService.getRole().toLowerCase() == 'owner'
                          ? 1
                          : 0),
                  itemBuilder: (context, index) {
                    final isOwner =
                        controller.userService.getRole().toLowerCase() ==
                            'owner';
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
                'Powered by Flink POS',
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
            color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.2
                    : 0.03),
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
          prefixIcon: Icon(CupertinoIcons.search,
              color: AppTheme.secondaryTextColor(context), size: 20.sp),
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
              color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.2
                      : 0.05),
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
                border:
                    Border.all(color: AppTheme.cardColor(context), width: 4.w),
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
              color:
                  AppTheme.primaryColor.withValues(alpha: isDark ? 0.08 : 0.05),
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
              child: Icon(Icons.person_add_rounded,
                  size: 36.sp, color: AppTheme.primaryColor),
            ),
            SizedBox(height: 24.h),
            Text(
              'Add Staff',
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
    final roleLabels = {
      '1': 'Owner',
      '2': 'Cashier',
      '3': 'Kitchen',
      '4': 'Supervisor'
    };
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 60.w, vertical: 24.h),
        child: Container(
          width: 520.w,
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Icon(Icons.person_add_alt_1_rounded,
                            color: AppTheme.primaryColor, size: 24.sp),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Staff',
                              style: TextStyle(
                                fontFamily: AppTheme.fontBold,
                                fontSize: 20.sp,
                                color: AppTheme.textColor(context),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Fill in the details to create a new account',
                              style: TextStyle(
                                fontFamily: AppTheme.fontRegular,
                                fontSize: 12.sp,
                                color: AppTheme.secondaryTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: Icon(Icons.close_rounded,
                            color: AppTheme.secondaryTextColor(context),
                            size: 20.sp),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.borderColor(context)
                              .withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r)),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 28.h),
                  Divider(height: 1, color: AppTheme.borderColor(context)),
                  SizedBox(height: 24.h),

                  // First Name
                  _buildDialogFieldLabel(context, 'First Name', required: true),
                  SizedBox(height: 8.h),
                  _buildDialogTextField(
                    context,
                    controller: firstnameCtrl,
                    hint: 'e.g. John',
                    icon: CupertinoIcons.person,
                  ),

                  SizedBox(height: 18.h),

                  // Last Name
                  _buildDialogFieldLabel(context, 'Last Name', required: false),
                  SizedBox(height: 8.h),
                  _buildDialogTextField(
                    context,
                    controller: lastnameCtrl,
                    hint: 'e.g. Doe (optional)',
                    icon: CupertinoIcons.person,
                  ),

                  SizedBox(height: 18.h),

                  // PIN
                  _buildDialogFieldLabel(context, 'PIN', required: false),
                  SizedBox(height: 8.h),
                  _buildDialogTextField(
                    context,
                    controller: pinCtrl,
                    hint: 'Leave blank to use 0000',
                    icon: CupertinoIcons.lock,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                  ),

                  SizedBox(height: 18.h),

                  // Role
                  _buildDialogFieldLabel(context, 'Role', required: false),
                  SizedBox(height: 8.h),
                  Obx(() => Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14.r),
                          border:
                              Border.all(color: AppTheme.borderColor(context)),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedRole.value,
                          decoration: InputDecoration(
                            prefixIcon: Icon(CupertinoIcons.shield,
                                size: 18.sp,
                                color: AppTheme.secondaryTextColor(context)),
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 14.h),
                          ),
                          style: TextStyle(
                            fontFamily: AppTheme.fontMedium,
                            fontSize: 14.sp,
                            color: AppTheme.textColor(context),
                          ),
                          dropdownColor: AppTheme.cardColor(context),
                          items: roleLabels.entries
                              .map((e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value,
                                        style: TextStyle(
                                            fontFamily: AppTheme.fontMedium)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) selectedRole.value = val;
                          },
                        ),
                      )),

                  SizedBox(height: 32.h),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                AppTheme.secondaryTextColor(context),
                            side: BorderSide(
                                color: AppTheme.borderColor(context)),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r)),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                                fontFamily: AppTheme.fontMedium,
                                fontSize: 15.sp),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 2,
                        child: Obx(() => ElevatedButton(
                              onPressed: controller.isAddingStaff.value
                                  ? null
                                  : () async {
                                      if (firstnameCtrl.text.trim().isEmpty) {
                                        Get.snackbar(
                                          'Required Field',
                                          'First name is required.',
                                          backgroundColor:
                                              Colors.orange.shade600,
                                          colorText: Colors.white,
                                        );
                                        return;
                                      }
                                      await controller.addStaff(
                                        firstname: firstnameCtrl.text.trim(),
                                        lastname:
                                            lastnameCtrl.text.trim().isEmpty
                                                ? null
                                                : lastnameCtrl.text.trim(),
                                        roleId: selectedRole.value,
                                        pin: pinCtrl.text.isEmpty
                                            ? '0000'
                                            : pinCtrl.text,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppTheme.primaryColor
                                    .withValues(alpha: 0.5),
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14.r)),
                              ),
                              child: controller.isAddingStaff.value
                                  ? SizedBox(
                                      width: 20.w,
                                      height: 20.w,
                                      child: const CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.person_add_alt_1_rounded,
                                            size: 18.sp),
                                        SizedBox(width: 8.w),
                                        Text(
                                          'Add Staff',
                                          style: TextStyle(
                                              fontFamily: AppTheme.fontBold,
                                              fontSize: 15.sp),
                                        ),
                                      ],
                                    ),
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildDialogFieldLabel(BuildContext context, String label,
      {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontMedium,
            fontSize: 13.sp,
            color: AppTheme.textColor(context),
          ),
        ),
        if (required) ...[
          SizedBox(width: 4.w),
          Text(
            '*',
            style: TextStyle(color: Colors.red, fontSize: 13.sp),
          ),
        ],
      ],
    );
  }

  Widget _buildDialogTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    int? maxLength,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLength: maxLength,
        style: TextStyle(
          fontFamily: AppTheme.fontMedium,
          fontSize: 14.sp,
          color: AppTheme.textColor(context),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: AppTheme.fontRegular,
            fontSize: 14.sp,
            color: AppTheme.secondaryTextColor(context),
          ),
          prefixIcon: Icon(icon,
              size: 18.sp, color: AppTheme.secondaryTextColor(context)),
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.symmetric(vertical: 14.h),
        ),
      ),
    );
  }
}
