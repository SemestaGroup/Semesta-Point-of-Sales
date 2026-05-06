import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/modules/home/employee/controllers/home_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:semesta_pos/modules/setting/controllers/setting_controller.dart';

class ModalNota extends StatelessWidget {
  final String notaUrl;
  final int penjualanId;
  const ModalNota({super.key, required this.notaUrl, required this.penjualanId});

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadRequest(Uri.parse(notaUrl));

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      appBar: AppBar(
        title: Text("Digital Receipt", style: TextStyle(fontFamily: AppTheme.fontBold, fontSize: 18.sp)),
        backgroundColor: AppTheme.cardColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20.sp),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 24.h),
              width: 400.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: WebViewWidget(controller: controller),
              ),
            ),
          ),
          Positioned(
            bottom: 40.h,
            right: 40.w,
            child: FloatingActionButton.extended(
              onPressed: () async {
                if (!Get.isRegistered<SettingController>()) {
                  Get.put(SettingController());
                  await Future.delayed(const Duration(milliseconds: 100));
                }

                HomeController homeCtrl;
                if (Get.isRegistered<HomeController>()) {
                  homeCtrl = Get.find<HomeController>();
                } else {
                  homeCtrl = Get.put(HomeController());
                }
                
                homeCtrl.printTransactionSession(penjualanId);
              },
              backgroundColor: AppTheme.primaryColor,
              icon: Icon(Icons.print_rounded, color: Colors.white, size: 24.sp),
              label: const Text("PRINT TO THERMAL", style: TextStyle(fontFamily: AppTheme.fontBold, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}

