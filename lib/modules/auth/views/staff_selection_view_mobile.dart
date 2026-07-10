import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/models/staff/staff_model.dart';
import 'package:semesta_pos/modules/auth/controllers/auth_controller.dart';
import 'package:semesta_pos/modules/auth/views/widgets/pin_pad_widget.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class StaffSelectionViewMobile extends StatelessWidget {
  final AuthController controller;

  const StaffSelectionViewMobile({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const bool isMobile = true;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100.0,
        leading: controller.userService.getPrefBool('has_active_staff')
            ? Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
                child: InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                        color: AppTheme.cardColor(context),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: AppTheme.borderColor(context)),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryColor, size: 12.0),
                        SizedBox(width: 4.0),
                        Text(
                          'Back',
                          style: TextStyle(
                            fontFamily: AppTheme.fontBold,
                            fontSize: 12.0,
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
          if (controller.userService.getPrefBool('has_active_staff'))
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
              child: InkWell(
                onTap: () => controller.lockAccount(),
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.orange.shade600.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, color: Colors.orange.shade700, size: 12.0),
                      const SizedBox(width: 4.0),
                      Text(
                        'Lock',
                        style: TextStyle(
                          fontFamily: AppTheme.fontBold,
                          fontSize: 12.0,
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
                padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
                child: Row(
                  children: [
                    Obx(() => InkWell(
                          onTap: controller.isLoading.value ? null : () => controller.refreshStaff(),
                          borderRadius: BorderRadius.circular(8.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                controller.isLoading.value
                                    ? const SizedBox(
                                        width: 12.0,
                                        height: 12.0,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: AppTheme.primaryColor))
                                    : const Icon(Icons.sync_rounded, color: AppTheme.primaryColor, size: 12.0),
                                const SizedBox(width: 4.0),
                                const Text(
                                  'Sync',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontBold,
                                    fontSize: 12.0,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                    const SizedBox(width: 8.0),
                    InkWell(
                      onTap: () => controller.logoutLocation(),
                      borderRadius: BorderRadius.circular(8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.power_settings_new, color: Colors.redAccent, size: 12.0),
                            SizedBox(width: 4.0),
                            Text(
                              'Logout',
                              style: TextStyle(
                                fontFamily: AppTheme.fontBold,
                                fontSize: 12.0,
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
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 16.0),
            Text(
              'Switch Staff',
              style: TextStyle(
                fontFamily: AppTheme.fontBold,
                fontSize: 24.0,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              'Please select your account and enter your PIN to continue.',
              style: TextStyle(
                fontFamily: AppTheme.fontMedium,
                fontSize: 13.0,
                color: AppTheme.secondaryTextColor(context),
              ),
            ),
            const SizedBox(height: 24.0),
            _buildSearchBar(context, isMobile),
            const SizedBox(height: 24.0),
            Expanded(
              child: Obx(() {
                if (controller.filteredStaff.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.person_3, size: 48.0, color: AppTheme.borderColor(context)),
                        const SizedBox(height: 16.0),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontFamily: AppTheme.fontMedium,
                            fontSize: 14.0,
                            color: AppTheme.textColorSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final isOwner = controller.userService.getRole().toLowerCase() == 'owner';
                final itemsCount = controller.filteredStaff.length + (isOwner ? 1 : 0);

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 16.0, top: 10.0),
                  itemCount: itemsCount,
                  separatorBuilder: (context, index) => const SizedBox(height: 10.0),
                  itemBuilder: (context, index) {
                    if (isOwner && index == controller.filteredStaff.length) {
                      return _buildAddStaffCard(context, isMobile);
                    }
                    final staff = controller.filteredStaff[index];
                    return _buildStaffItem(context, staff, isMobile);
                  },
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Powered by Flink POS',
                style: TextStyle(
                  fontFamily: AppTheme.fontMedium,
                  fontSize: 10.0,
                  color: AppTheme.borderColor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03),
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
            fontSize: 14.0,
            color: AppTheme.secondaryTextColor(context),
          ),
          prefixIcon: Icon(CupertinoIcons.search, color: AppTheme.secondaryTextColor(context), size: 18.0),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
        ),
        style: TextStyle(
          fontFamily: AppTheme.fontMedium,
          fontSize: 14.0,
          color: AppTheme.textColor(context),
        ),
      ),
    );
  }

  Widget _buildStaffItem(BuildContext context, StaffModel staff, bool isMobile) {
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24.0,
              backgroundColor: avatarColor,
              child: Text(
                staff.initials,
                style: const TextStyle(
                  fontFamily: AppTheme.fontBold,
                  fontSize: 16.0,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.fullName,
                    style: TextStyle(
                      fontFamily: AppTheme.fontBold,
                      fontSize: 15.0,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    (staff.role ?? 'User').toUpperCase(),
                    style: const TextStyle(
                      fontFamily: AppTheme.fontMedium,
                      fontSize: 11.0,
                      color: AppTheme.primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.secondaryTextColor(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStaffCard(BuildContext context, bool isMobile) {
    return GestureDetector(
      onTap: () => _showAddStaffDialog(context, isMobile),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24.0,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
              child: const Icon(Icons.person_add_rounded, color: AppTheme.primaryColor, size: 24.0),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Staff',
                    style: TextStyle(
                      fontFamily: AppTheme.fontBold,
                      fontSize: 15.0,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'OWNER ONLY',
                    style: TextStyle(
                      fontFamily: AppTheme.fontBold,
                      fontSize: 10.0,
                      color: AppTheme.primaryColor.withValues(alpha: 0.8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryColor.withValues(alpha: 0.8)),
          ],
        ),
      ),
    );
  }

  void _showPinDialog(BuildContext context, StaffModel staff) {
    Get.dialog(
      PinPadWidget(
        title: 'Enter PIN for ${staff.fullName}',
        staffName: staff.fullName,
        initials: staff.initials,
        onCompleted: (pin) => _verifyPin(staff, pin),
      ),
      barrierDismissible: true,
    );
  }

  void _verifyPin(StaffModel staff, String inputPin) async {
    final storedPin = (staff.pin ?? '').trim();
    if (storedPin.isEmpty) {
      Get.back();
      Get.snackbar(
        'Access Denied',
        'This account does not have a configured PIN. Please contact the Admin to set a PIN.',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (inputPin == storedPin) {
      Get.back();
      controller.completeStaffLogin(staff);
    } else {
      Get.snackbar(
        'Incorrect PIN',
        'The PIN you entered is wrong. Please try again.',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _showAddStaffDialog(BuildContext context, bool isMobile) {
    final firstnameCtrl = TextEditingController();
    final lastnameCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    final selectedRole = '2'.obs;
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(16.0),
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
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40.0,
                        height: 40.0,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryColor, size: 20.0),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Staff',
                              style: TextStyle(
                                fontFamily: AppTheme.fontBold,
                                fontSize: 16.0,
                                color: AppTheme.textColor(context),
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              'Fill in the details to create a new account',
                              style: TextStyle(
                                fontFamily: AppTheme.fontRegular,
                                fontSize: 11.0,
                                color: AppTheme.secondaryTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: Icon(Icons.close_rounded, color: AppTheme.secondaryTextColor(context), size: 18.0),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.borderColor(context).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  Divider(height: 1, color: AppTheme.borderColor(context)),
                  const SizedBox(height: 16.0),
                  _buildDialogFieldLabel(context, 'First Name', isMobile, required: true),
                  const SizedBox(height: 8.0),
                  _buildDialogTextField(context, isMobile, controller: firstnameCtrl, hint: 'e.g. John', icon: CupertinoIcons.person),
                  const SizedBox(height: 12.0),
                  _buildDialogFieldLabel(context, 'Last Name', isMobile, required: false),
                  const SizedBox(height: 8.0),
                  _buildDialogTextField(context, isMobile, controller: lastnameCtrl, hint: 'e.g. Doe (optional)', icon: CupertinoIcons.person),
                  const SizedBox(height: 12.0),
                  _buildDialogFieldLabel(context, 'PIN', isMobile, required: false),
                  const SizedBox(height: 8.0),
                  _buildDialogTextField(context, isMobile, controller: pinCtrl, hint: 'Leave blank to use 0000', icon: CupertinoIcons.lock, keyboardType: TextInputType.number, obscureText: true, maxLength: 6),
                  const SizedBox(height: 12.0),
                  _buildDialogFieldLabel(context, 'Role', isMobile, required: false),
                  const SizedBox(height: 8.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: AppTheme.borderColor(context)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: Obx(() => DropdownButton<String>(
                            value: selectedRole.value,
                            isExpanded: true,
                            dropdownColor: AppTheme.cardColor(context),
                            icon: Icon(CupertinoIcons.chevron_down, size: 16.0, color: AppTheme.secondaryTextColor(context)),
                            style: TextStyle(
                              fontFamily: AppTheme.fontMedium,
                              fontSize: 13.0,
                              color: AppTheme.textColor(context),
                            ),
                            items: roleLabels.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) selectedRole.value = val;
                            },
                          )),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.secondaryTextColor(context),
                            side: BorderSide(color: AppTheme.borderColor(context)),
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontFamily: AppTheme.fontMedium, fontSize: 14.0)),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        flex: 2,
                        child: Obx(() => ElevatedButton(
                              onPressed: controller.isAddingStaff.value
                                  ? null
                                  : () async {
                                      if (firstnameCtrl.text.trim().isEmpty) {
                                        Get.snackbar('Required Field', 'First name is required.', backgroundColor: Colors.orange.shade600, colorText: Colors.white);
                                        return;
                                      }
                                      await controller.addStaff(
                                        firstname: firstnameCtrl.text.trim(),
                                        lastname: lastnameCtrl.text.trim().isEmpty ? null : lastnameCtrl.text.trim(),
                                        roleId: selectedRole.value,
                                        pin: pinCtrl.text.isEmpty ? '0000' : pinCtrl.text,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                              ),
                              child: controller.isAddingStaff.value
                                  ? const SizedBox(
                                      width: 18.0,
                                      height: 18.0,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.person_add_alt_1_rounded, size: 16.0),
                                        SizedBox(width: 8.0),
                                        Text('Add Staff', style: TextStyle(fontFamily: AppTheme.fontBold, fontSize: 14.0)),
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

  Widget _buildDialogFieldLabel(BuildContext context, String label, bool isMobile, {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontMedium,
            fontSize: 12.0,
            color: AppTheme.textColor(context),
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4.0),
          const Text('*', style: TextStyle(color: Colors.red, fontSize: 12.0)),
        ],
      ],
    );
  }

  Widget _buildDialogTextField(
    BuildContext context,
    bool isMobile, {
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
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLength: maxLength,
        style: TextStyle(
          fontFamily: AppTheme.fontMedium,
          fontSize: 13.0,
          color: AppTheme.textColor(context),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: AppTheme.fontRegular,
            fontSize: 13.0,
            color: AppTheme.secondaryTextColor(context),
          ),
          prefixIcon: Icon(icon, size: 16.0, color: AppTheme.secondaryTextColor(context)),
          border: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
        ),
      ),
    );
  }
}
