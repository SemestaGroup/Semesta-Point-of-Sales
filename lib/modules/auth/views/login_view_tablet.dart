import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:semesta_pos/modules/auth/controllers/auth_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class LoginScreenTablet extends StatelessWidget {
  final AuthController controller;
  final Widget Function() buildLoginForm;

  const LoginScreenTablet({
    super.key,
    required this.controller,
    required this.buildLoginForm,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      body: SafeArea(
        child: Row(
          children: [
            // LEFT PANEL: Illustration
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

            // RIGHT PANEL: Login Form
            Expanded(
              flex: 4,
              child: Container(
                color: AppTheme.cardColor(context),
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 24.h),
                    child: buildLoginForm(),
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
