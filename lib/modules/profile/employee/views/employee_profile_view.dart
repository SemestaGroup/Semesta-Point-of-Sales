import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/modules/profile/employee/controllers/employee_profile_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  final controller = Get.put(EmployeeProfileController());
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(context),
                    SizedBox(height: 32.h),
                    // _buildActionButtons(context), // Disabled per user request
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor(context)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Profile',
            style: TextStyle(
              fontSize: AppTheme.fontSizeTitleMedium,
              fontFamily: AppTheme.fontBold,
              color: AppTheme.textColor(context),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Manage your account information here.',
            style: AppTheme.labelMedium.copyWith(
              color: AppTheme.secondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration(context),
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.person_crop_circle_fill, size: 24.sp, color: AppTheme.primaryColor),
              SizedBox(width: 8.w),
              Text('Account Information', style: AppTheme.titleMedium.copyWith(fontSize: AppTheme.fontSizeHeadline)),
            ],
          ),
          Divider(color: AppTheme.borderColor(context), height: 32.h),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50.r,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Icon(
                    CupertinoIcons.person_fill,
                    size: 50.r,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.cardColor(context), width: 2),
                    ),
                    padding: EdgeInsets.all(6.r),
                    child: Icon(CupertinoIcons.camera_fill, size: 16.sp, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          _buildTextField(
            context: context,
            label: 'Full Name',
            hint: 'Enter your name',
            icon: CupertinoIcons.person,
            controller: controller.nameController,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            context: context,
            label: 'Email',
            hint: 'Enter your email address',
            icon: CupertinoIcons.mail,
            isReadOnly: true,
            controller: controller.emailController,
          ),
        ],
      ),
    );
  }


  Widget _buildTextField({
    required BuildContext context,
    required String label,
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    bool isReadOnly = false,
    String? initialValue,
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
        TextFormField(
          controller: controller,
          readOnly: isReadOnly,
          initialValue: initialValue,
          style: TextStyle(
            fontFamily: AppTheme.fontMedium,
            fontSize: AppTheme.fontSizeBodyLarge,
            color: AppTheme.textColor(context),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: AppTheme.fontSizeLabelMedium),
            prefixIcon: Icon(icon, size: 20.sp, color: AppTheme.secondaryTextColor(context)),
            filled: true,
            fillColor: AppTheme.isDark(context) ? Colors.grey.shade900 : Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
