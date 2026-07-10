import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:semesta_pos/modules/auth/controllers/auth_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';
import 'package:semesta_pos/modules/auth/views/login_view_mobile.dart';
import 'package:semesta_pos/modules/auth/views/login_view_tablet.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 600;
  }

  @override
  Widget build(BuildContext context) {
    final RxBool isObscured = true.obs;
    final bool isMobile = _isMobile(context);

    // Helper widget for Login Form to keep build method clean
    Widget buildLoginForm() {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(isMobile ? 12.0 : 14.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.r),
            ),
            child: Icon(
              Icons.point_of_sale_rounded,
              color: AppTheme.primaryColor,
              size: isMobile ? 28.0 : 32.sp,
            ),
          ),
          SizedBox(height: isMobile ? 16.0 : 24.h),
          Text(
            'Welcome!',
            style: TextStyle(
              fontFamily: AppTheme.fontBold,
              fontSize: isMobile ? 22.0 : 26.sp,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Login to your account to continue.',
            style: TextStyle(
              fontFamily: AppTheme.fontRegular,
              fontSize: isMobile ? 13.0 : 13.sp,
              color: AppTheme.textColorSecondary,
            ),
          ),
          SizedBox(height: isMobile ? 24.0 : 32.h),

          // Email field
          Text(
            'Email',
            style: TextStyle(
              fontFamily: AppTheme.fontBold,
              fontSize: isMobile ? 13.0 : 13.sp,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              fontFamily: AppTheme.fontMedium,
              fontSize: isMobile ? 14.0 : 14.sp,
              color: AppTheme.textColor(context),
            ),
            decoration: InputDecoration(
              hintText: 'name@email.com',
              hintStyle: TextStyle(
                fontFamily: AppTheme.fontRegular,
                fontSize: isMobile ? 13.0 : 13.sp,
                color: Colors.grey[400],
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: AppTheme.primaryColor,
                size: isMobile ? 20.0 : 20.sp,
              ),
              filled: true,
              fillColor: AppTheme.scaffoldBackgroundColor(context),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : 16.w,
                vertical: isMobile ? 14.0 : 16.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 10.0 : 12.r),
                borderSide: BorderSide(
                  color: AppTheme.borderColor(context),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 10.0 : 12.r),
                borderSide: BorderSide(
                  color: AppTheme.borderColor(context),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 10.0 : 12.r),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),
          SizedBox(height: isMobile ? 16.0 : 20.h),

          // Password field
          Text(
            'Password',
            style: TextStyle(
              fontFamily: AppTheme.fontBold,
              fontSize: isMobile ? 13.0 : 13.sp,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 8.0),
          Obx(
            () => TextFormField(
              controller: controller.pwController,
              obscureText: isObscured.value,
              keyboardType: TextInputType.visiblePassword,
              style: TextStyle(
                fontFamily: AppTheme.fontMedium,
                fontSize: isMobile ? 14.0 : 14.sp,
                color: AppTheme.textColor(context),
              ),
              decoration: InputDecoration(
                hintText: '••••••••',
                hintStyle: TextStyle(
                  fontFamily: AppTheme.fontRegular,
                  fontSize: isMobile ? 13.0 : 13.sp,
                  color: Colors.grey[400],
                ),
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  color: AppTheme.primaryColor,
                  size: isMobile ? 20.0 : 20.sp,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    isObscured.value
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: isObscured.value
                        ? Colors.grey[400]
                        : AppTheme.primaryColor,
                    size: isMobile ? 20.0 : 20.sp,
                  ),
                  onPressed: () => isObscured.value = !isObscured.value,
                ),
                filled: true,
                fillColor: AppTheme.scaffoldBackgroundColor(context),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16.0 : 16.w,
                  vertical: isMobile ? 14.0 : 16.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 10.0 : 12.r),
                  borderSide: BorderSide(
                    color: AppTheme.borderColor(context),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 10.0 : 12.r),
                  borderSide: BorderSide(
                    color: AppTheme.borderColor(context),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 10.0 : 12.r),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: isMobile ? 24.0 : 32.h),

          Obx(
            () => SizedBox(
              width: double.infinity,
              height: isMobile ? 48.0 : 52.h,
              child: controller.isLoading.value
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        controller.validateLogin();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isMobile ? 10.0 : 12.r),
                        ),
                      ),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontFamily: AppTheme.fontBold,
                          fontSize: isMobile ? 14.5 : 15.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(height: isMobile ? 16.0 : 24.h),

          // Footer note
          Center(
            child: Text(
              '© 2025 Flink POS · All rights reserved',
              style: TextStyle(
                fontFamily: AppTheme.fontRegular,
                fontSize: isMobile ? 10.0 : 11.sp,
                color: Colors.grey[400],
              ),
            ),
          ),
        ],
      );
    }

    return isMobile
        ? LoginScreenMobile(
            controller: controller,
            isObscured: isObscured,
            buildLoginForm: buildLoginForm,
          )
        : LoginScreenTablet(
            controller: controller,
            buildLoginForm: buildLoginForm,
          );
  }
}
