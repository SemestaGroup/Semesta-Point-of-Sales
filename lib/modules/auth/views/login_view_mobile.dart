import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/modules/auth/controllers/auth_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class LoginScreenMobile extends StatelessWidget {
  final AuthController controller;
  final RxBool isObscured;
  final Widget Function() buildLoginForm;

  const LoginScreenMobile({
    super.key,
    required this.controller,
    required this.isObscured,
    required this.buildLoginForm,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: buildLoginForm(),
          ),
        ),
      ),
    );
  }
}
