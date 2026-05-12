import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:semesta_pos/modules/auth/controllers/auth_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RxBool isObscured = true.obs;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      body: SafeArea(
        child: Row(
          children: [
            // ─── LEFT PANEL: Illustration ───────────────────────────────
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF482CD9),
                      Color(0xFF6A4FE8),
                      Color(0xFF9B7FFF),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -60,
                      left: -60,
                      child: Container(
                        width: 220.w,
                        height: 220.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -80,
                      right: -80,
                      child: Container(
                        width: 280.w,
                        height: 280.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 100,
                      left: -40,
                      child: Container(
                        width: 140.w,
                        height: 140.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    // Content
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Illustration
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24.r),
                              child: Image.asset(
                                'assets/img/login_illustration.png',
                                width: 240.w,
                                height: 240.w,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.store_rounded,
                                  size: 120.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: 32.h),
                            Text(
                              'Flink POS',
                              style: TextStyle(
                                fontFamily: AppTheme.fontBold,
                                fontSize: 28.sp,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              'Kelola bisnis Anda lebih efisien\ndengan sistem kasir modern.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTheme.fontRegular,
                                fontSize: 14.sp,
                                color: Colors.white.withValues(alpha: 0.80),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── RIGHT PANEL: Login Form ─────────────────────────────────
            Expanded(
              flex: 4,
              child: Container(
                color: AppTheme.cardColor(context),
                child: Center(
                  child: SingleChildScrollView(
                    padding:
                        EdgeInsets.symmetric(horizontal: 40.w, vertical: 24.h),
                    child: Obx(
                      () => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Container(
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Icon(
                              Icons.point_of_sale_rounded,
                              color: AppTheme.primaryColor,
                              size: 32.sp,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            'Welcome!',
                            style: TextStyle(
                              fontFamily: AppTheme.fontBold,
                              fontSize: 26.sp,
                              color: AppTheme.textColor(context),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Login to your account to continue.',
                            style: TextStyle(
                              fontFamily: AppTheme.fontRegular,
                              fontSize: 13.sp,
                              color: AppTheme.textColorSecondary,
                            ),
                          ),
                          SizedBox(height: 36.h),

                          // Email field
                          Text(
                            'Email',
                            style: TextStyle(
                              fontFamily: AppTheme.fontBold,
                              fontSize: 13.sp,
                              color: AppTheme.textColor(context),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: controller.emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              fontFamily: AppTheme.fontMedium,
                              fontSize: 14.sp,
                              color: AppTheme.textColor(context),
                            ),
                            decoration: InputDecoration(
                              hintText: 'name@email.com',
                              hintStyle: TextStyle(
                                fontFamily: AppTheme.fontRegular,
                                fontSize: 13.sp,
                                color: Colors.grey[400],
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppTheme.primaryColor,
                                size: 20.sp,
                              ),
                              filled: true,
                              fillColor:
                                  AppTheme.scaffoldBackgroundColor(context),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 16.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(
                                  color: AppTheme.borderColor(context),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(
                                  color: AppTheme.borderColor(context),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),

                          // Password field
                          Text(
                            'Password',
                            style: TextStyle(
                              fontFamily: AppTheme.fontBold,
                              fontSize: 13.sp,
                              color: AppTheme.textColor(context),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: controller.pwController,
                            obscureText: isObscured.value,
                            keyboardType: TextInputType.visiblePassword,
                            style: TextStyle(
                              fontFamily: AppTheme.fontMedium,
                              fontSize: 14.sp,
                              color: AppTheme.textColor(context),
                            ),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: TextStyle(
                                fontFamily: AppTheme.fontRegular,
                                fontSize: 13.sp,
                                color: Colors.grey[400],
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: AppTheme.primaryColor,
                                size: 20.sp,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isObscured.value
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: isObscured.value
                                      ? Colors.grey[400]
                                      : AppTheme.primaryColor,
                                  size: 20.sp,
                                ),
                                onPressed: () =>
                                    isObscured.value = !isObscured.value,
                              ),
                              filled: true,
                              fillColor:
                                  AppTheme.scaffoldBackgroundColor(context),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 16.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(
                                  color: AppTheme.borderColor(context),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(
                                  color: AppTheme.borderColor(context),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 32.h),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 320.w),
                              child: SizedBox(
                                width: double.infinity,
                                height: 52.h,
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
                                          backgroundColor:
                                              AppTheme.primaryColor,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.r),
                                          ),
                                        ),
                                        child: Text(
                                          'Login',
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontBold,
                                            fontSize: 15.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),

                          // Footer note
                          Center(
                            child: Text(
                              '© 2025 Flink POS · All rights reserved',
                              style: TextStyle(
                                fontFamily: AppTheme.fontRegular,
                                fontSize: 11.sp,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
