import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/modules/home/employee/controllers/home_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';
import 'package:semesta_pos/modules/dashboard/employee/controllers/dashboard_employee_controller.dart';
import 'package:semesta_pos/modules/dashboard/admin/controllers/dashboard_admin_controller.dart';
import 'package:semesta_pos/modules/home/employee/widgets/cash_keypad_dialog.dart';
import 'package:semesta_pos/core/services/app_service.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  String formatRupiah(int number) {
    if (number == 0) return 'Rp. 0';
    String s = number.abs().toString();
    String result = "";
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      count++;
      result = s[i] + result;
      if (count % 3 == 0 && i != 0) result = ".$result";
    }
    return 'Rp. ${number < 0 ? "-" : ""}$result';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final selectedPaymentMethod = formatRupiah(controller.totalTransaction.value).obs;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.arrow_left,
              color: AppTheme.textColor(context)),
          onPressed: () => Get.back(),
        ),
        title: Text("Payment",
            style: AppTheme.titleLarge.copyWith(fontSize: 20.sp)),
        centerTitle: false,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT COLUMN: ORDER SUMMARY
          Expanded(
            flex: 4,
            child: Container(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Review Order",
                      style: AppTheme.titleLarge.copyWith(fontSize: 18.sp)),
                  SizedBox(height: 24.h),
                  Expanded(
                    child: Obx(() => ListView.separated(
                          itemCount: controller.penjualanDetailModelList.length,
                          separatorBuilder: (context, index) => Divider(
                              height: 24.h,
                              color: AppTheme.borderColor(context)
                                  .withValues(alpha: 0.3)),
                          itemBuilder: (context, index) {
                            final item =
                                controller.penjualanDetailModelList[index];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.description?.isNotEmpty == true ? item.description! : (item.productName ?? ""),
                                          style: AppTheme.bodyLarge.copyWith(
                                              fontFamily: AppTheme.fontBold,
                                              fontSize: 16.sp)),
                                      SizedBox(height: 4.h),
                                      Text(
                                          "${formatRupiah(item.hargaJual)} x ${item.jumlah}",
                                          style: AppTheme.labelMedium),
                                      if (item.orderType.isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(top: 4.h),
                                          child: Text("Type: ${item.orderType}",
                                              style: TextStyle(
                                                  color: AppTheme.primaryColor,
                                                  fontSize: 12.sp,
                                                  fontStyle: FontStyle.italic)),
                                        ),
                                      if (item.discountTotal > 0)
                                        Builder(builder: (_) {
                                          final base = item.hargaAwal > 0
                                              ? item.hargaAwal
                                              : item.hargaJual;
                                          final nominalDiscount =
                                              item.discountType == 'percent'
                                                  ? (base *
                                                          item.discountTotal /
                                                          100)
                                                      .round()
                                                  : item.discountTotal;
                                          final label = item.discountType ==
                                                  'percent'
                                              ? 'Disc ${item.discountTotal}% = -${formatRupiah(nominalDiscount)}'
                                              : 'Disc -${formatRupiah(nominalDiscount)}';
                                          return Padding(
                                            padding: EdgeInsets.only(top: 2.h),
                                            child: Row(
                                              children: [
                                                Icon(CupertinoIcons.tag_fill,
                                                    size: 10.sp,
                                                    color: const Color(
                                                        0xFFFF6B35)),
                                                SizedBox(width: 4.w),
                                                Text(
                                                  label,
                                                  style: TextStyle(
                                                    color: const Color(
                                                        0xFFFF6B35),
                                                    fontSize: 10.sp,
                                                    fontFamily:
                                                        AppTheme.fontMedium,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      if (item.note.isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(top: 2.h),
                                          child: Text(item.note,
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12.sp)),
                                        ),

                                    ],
                                  ),
                                ),
                                Text(formatRupiah(item.subtotal),
                                    style: AppTheme.bodyLarge.copyWith(
                                        fontFamily: AppTheme.fontBold,
                                        color: AppTheme.primaryColor)),
                              ],
                            );
                          },
                        )),
                  ),
                  Divider(
                      height: 32.h,
                      thickness: 1.5,
                      color: AppTheme.borderColor(context)),
                  _buildPriceRow("Base Price",
                      formatRupiah(controller.subtotalRaw.value), context),
                  SizedBox(height: 8.h),
                  _buildPriceRow("Taxes",
                      formatRupiah(controller.taxAmount.value), context),
                  Obx(() {
                    final discVal = controller.manualDiscountValue.value;
                    final isPercent = controller.manualDiscountIsPercent.value;
                    final defaultDisc = controller.disscount.value;

                    if (discVal > 0) {
                      final String label = isPercent ? "Discount ($discVal%)" : "Discount";
                      final int amount = isPercent
                          ? (controller.subtotalRaw.value * discVal / 100).round()
                          : discVal;
                      return Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: _buildPriceRow(
                            label, "-${formatRupiah(amount)}", context,
                            color: const Color(0xFFFF6B35)),
                      );
                    } else if (defaultDisc > 0) {
                      return Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: _buildPriceRow(
                            "Discount ($defaultDisc%)",
                            "-${formatRupiah((controller.subtotalRaw.value * defaultDisc / 100).round())}",
                            context,
                            color: const Color(0xFFFF6B35)),
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total Amount",
                          style: AppTheme.titleLarge.copyWith(fontSize: 20.sp)),
                      Text(formatRupiah(controller.totalTransaction.value),
                          style: AppTheme.titleLarge.copyWith(
                              fontSize: 24.sp,
                              color: AppTheme.primaryColor,
                              fontFamily: AppTheme.fontBold)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // VERTICAL DIVIDER
          Container(width: 1.w, color: AppTheme.borderColor(context)),

          // RIGHT COLUMN: PAYMENT METHODS
          Expanded(
            flex: 6,
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FIXED HEADER: TOTAL BANNER
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(32.w),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total",
                            style: AppTheme.titleLarge.copyWith(
                                color: AppTheme.primaryColor, fontSize: 28.sp)),
                        Obx(() => Text(
                            formatRupiah(controller.totalTransaction.value),
                            style: AppTheme.titleLarge.copyWith(
                                color: AppTheme.primaryColor,
                                fontSize: 32.sp,
                                fontFamily: AppTheme.fontBold))),
                      ],
                    ),
                  ),

                  // SCROLLABLE CONTENT: PAYMENT METHODS
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(vertical: 32.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Select Payment Method",
                              style: AppTheme.titleLarge
                                  .copyWith(fontSize: 18.sp)),
                          SizedBox(height: 24.h),

                          // CASHLESS SECTION
                          Obx(() {
                            if (controller.cashlessPaymentModes.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Cashless",
                                    style: AppTheme.labelMedium
                                        .copyWith(fontFamily: AppTheme.fontBold)),
                                SizedBox(height: 12.h),
                                Builder(
                                  builder: (context) {
                                    final items = controller.cashlessPaymentModes.map((mode) {
                                      final name = mode['name']?.toString() ?? 'Unknown';
                                      final lowerName = name.toLowerCase();
                                      IconData icon = Icons.payment;
                                      if (lowerName.contains('qris') || lowerName.contains('qr')) {
                                        icon = CupertinoIcons.qrcode;
                                      } else if (lowerName.contains('transfer') || lowerName.contains('bank')) {
                                        icon = Icons.account_balance;
                                      } else if (lowerName.contains('card') || lowerName.contains('kartu')) {
                                        icon = Icons.credit_card;
                                      }
                                      return _buildPaymentOption(name, icon, selectedPaymentMethod, context);
                                    }).toList();

                                    if (items.length == 1) {
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: 12.h),
                                        child: items.first,
                                      );
                                    }

                                    return LayoutBuilder(
                                      builder: (context, constraints) {
                                        // 12.w is the spacing between the two columns
                                        final double itemWidth = (constraints.maxWidth - 12.w) / 2;
                                        return Wrap(
                                          spacing: 12.w,
                                          runSpacing: 12.h,
                                          children: items.map((child) => SizedBox(
                                            width: itemWidth,
                                            child: child,
                                          )).toList(),
                                        );
                                      }
                                    );
                                  }
                                ),
                              ],
                            );
                          }),

                          // CASH SECTION
                          SizedBox(height: 12.h),
                          Text("Cash",
                              style: AppTheme.labelMedium
                                  .copyWith(fontFamily: AppTheme.fontBold)),
                          SizedBox(height: 12.h),
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildPaymentOption(
                                          formatRupiah(controller
                                              .totalTransaction.value),
                                          Icons.money,
                                          selectedPaymentMethod,
                                          context,
                                          isCash: true)),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                      child: _buildPaymentOption(
                                          formatRupiah(50000),
                                          Icons.money,
                                          selectedPaymentMethod,
                                          context,
                                          isCash: true)),
                                ],
                              ),
                              SizedBox(height: 16.h),
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildPaymentOption(
                                          formatRupiah(100000),
                                          Icons.money,
                                          selectedPaymentMethod,
                                          context,
                                          isCash: true)),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                      child: Obx(() {
                                        final manualLabel = controller.manualCashAmount.value > 0 
                                            ? formatRupiah(controller.manualCashAmount.value) 
                                            : "Insert Manually";
                                        return _buildPaymentOption(
                                            manualLabel,
                                            CupertinoIcons.keyboard,
                                            selectedPaymentMethod,
                                            context,
                                            isCash: true,
                                            onTap: () async {
                                              selectedPaymentMethod.value = manualLabel;
                                              final result = await showDialog<int>(
                                                context: context,
                                                builder: (context) => CashKeypadDialog(
                                                  initialValue: controller.manualCashAmount.value,
                                                ),
                                              );
                                              if (result != null) {
                                                controller.manualCashAmount.value = result;
                                                selectedPaymentMethod.value = formatRupiah(result);
                                              }
                                            }
                                        );
                                      })),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // FIXED FOOTER: CONTINUE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Extract numeric value from Cash selection
                        int cashValue = controller.totalTransaction.value;
                        String canonicalMethod = selectedPaymentMethod.value;

                        if (controller.manualCashAmount.value > 0 && 
                                   selectedPaymentMethod.value == formatRupiah(controller.manualCashAmount.value)) {
                          cashValue = controller.manualCashAmount.value;
                          canonicalMethod = "Cash";
                        } else if (selectedPaymentMethod.value.contains("Rp.")) {
                          // It's a quick cash amount selection (e.g. "Rp. 50.000")
                          String cleanStr = selectedPaymentMethod.value.replaceAll("Rp. ", "").replaceAll(".", "");
                          cashValue = int.tryParse(cleanStr) ?? controller.totalTransaction.value;
                          canonicalMethod = "Cash";
                        } else {
                          // It's a cashless method (e.g. QRIS, Transfer)
                          cashValue = controller.totalTransaction.value;
                          canonicalMethod = selectedPaymentMethod.value;
                        }
                        
                        _showConfirmationDialog(
                            context, controller, canonicalMethod, cashValue);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r)),
                        elevation: 0,
                      ),
                      child: Text("Continue Transaction",
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: AppTheme.fontBold,
                              fontSize: 18.sp)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, BuildContext context,
      {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.labelMedium),
        Text(value,
            style: AppTheme.bodyLarge
                .copyWith(fontFamily: AppTheme.fontMedium, color: color)),
      ],
    );
  }

  Widget _buildPaymentOption(
      String label, IconData icon, RxString groupValue, BuildContext context,
      {bool isCash = false, VoidCallback? onTap}) {
    return Obx(() {
      bool isSelected = groupValue.value == label;
      return GestureDetector(
        onTap: onTap ?? () => groupValue.value = label,
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.borderColor(context),
                width: isSelected ? 2.w : 1.w),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey,
                  size: 24.sp),
              SizedBox(width: 12.w),
              Expanded(
                  child: Text(label,
                      style: AppTheme.bodyLarge.copyWith(
                          fontFamily: isSelected
                              ? AppTheme.fontBold
                              : AppTheme.fontRegular,
                          color: isSelected ? AppTheme.primaryColor : null))),
              Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey,
                      width: 2.w),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                            width: 10.w,
                            height: 10.w,
                            decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle)))
                    : null,
              ),
            ],
          ),
        ),
      );
    });
  }
  void _showConfirmationDialog(BuildContext context, HomeController controller,
      String paymentMethod, int receivedAmount) {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} - ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    int totalAmount = controller.totalTransaction.value;
    int kembalian = receivedAmount - totalAmount;
    if (kembalian < 0) kembalian = 0;

    Get.dialog(
      Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: 500.w,
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Konfirmasi Pesanan",
                      style: AppTheme.titleLarge.copyWith(fontSize: 20.sp)),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey, size: 24.sp),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() => Text("Nomor Pesanan : ${controller.currentRemoteNumber.value}",
                          style: AppTheme.bodyLarge.copyWith(color: AppTheme.secondaryTextColor(context)))),
                      SizedBox(height: 4.h),
                      Text(dateStr,
                          style: AppTheme.labelMedium.copyWith(color: AppTheme.secondaryTextColor(context))),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("TOTAL",
                          style: AppTheme.labelMedium.copyWith(
                              fontSize: 10.sp, letterSpacing: 1.2)),
                      Text(formatRupiah(totalAmount),
                          style: AppTheme.titleLarge.copyWith(fontSize: 18.sp)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(
                  color: AppTheme.borderColor(context)),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined,
                                size: 14.sp, color: AppTheme.primaryColor),
                            SizedBox(width: 4.w),
                            Text("METODE PEMBAYARAN",
                                style: AppTheme.labelMedium.copyWith(
                                    fontSize: 10.sp, letterSpacing: 1)),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(paymentMethod,
                            style: AppTheme.bodyLarge
                                .copyWith(fontFamily: AppTheme.fontBold)),
                      ],
                    ),
                  ),
                  Container(
                      width: 1.w, height: 40.h, color: AppTheme.borderColor(context)),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.money,
                                  size: 14.sp, color: AppTheme.primaryColor),
                              SizedBox(width: 4.w),
                              Text("DITERIMA",
                                  style: AppTheme.labelMedium.copyWith(
                                      fontSize: 10.sp, letterSpacing: 1)),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(formatRupiah(receivedAmount),
                              style: AppTheme.bodyLarge
                                  .copyWith(fontFamily: AppTheme.fontBold)),
                        ],
                      ),
                    ),
                  ),
                  Container(
                      width: 1.w, height: 40.h, color: AppTheme.borderColor(context)),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.point_of_sale_outlined,
                                  size: 14.sp, color: AppTheme.primaryColor),
                              SizedBox(width: 4.w),
                              Text("KEMBALIAN",
                                  style: AppTheme.labelMedium.copyWith(
                                      fontSize: 10.sp, letterSpacing: 1)),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(formatRupiah(kembalian),
                              style: AppTheme.bodyLarge
                                  .copyWith(fontFamily: AppTheme.fontBold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        side: BorderSide(color: AppTheme.borderColor(context)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                      ),
                      child: Text("Batalkan",
                          style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontFamily: AppTheme.fontMedium,
                              fontSize: 16.sp)),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Obx(() => ElevatedButton(
                          onPressed: controller.isProcessingPayment.value
                              ? null
                              : () async {
                                  bool success = await controller.storePayment(
                                      paymentMethod, totalAmount,
                                      paymentMethod: paymentMethod);

                                  if (success) {
                                    Get.back(); // close confirmation dialog
                                    if (!context.mounted) return;

                                    final appService = Get.find<AppService>();
                                    final printingSettings = appService.posSettings['printing'] ?? {};
                                    final isAutoPrint = printingSettings['auto_print'] as bool? ?? false;

                                    if (isAutoPrint) {
                                      await controller.printReceipt(
                                          paymentMethod: paymentMethod,
                                          total: totalAmount,
                                          diterima: receivedAmount,
                                          kembalian: kembalian);
                                      // Wait for BT to fully release before label prints
                                      await Future.delayed(const Duration(seconds: 2));
                                    }
                                    if (!context.mounted) return;

                                    _showSuccessDialog(context, controller,
                                        paymentMethod, receivedAmount, kembalian);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r)),
                          ),
                          child: controller.isProcessingPayment.value
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: const CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text("Kirim",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: AppTheme.fontBold,
                                      fontSize: 16.sp)),
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showSuccessDialog(BuildContext context, HomeController controller,
      String paymentMethod, int receivedAmount, int kembalian) {
    int totalAmount = controller.totalTransaction.value;

    Get.dialog(
      Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: 550.w,
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey, size: 24.sp),
                    onPressed: () {
                      controller.finalizePayment();
                      Get.back();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              Container(
                width: 80.w,
                height: 80.w,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.check, color: Colors.white, size: 50.sp),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                "Pembayaran Berhasil!",
                style: AppTheme.titleLarge.copyWith(fontSize: 22.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                "Jangan lupa ucapkan terima kasih kepada pelanggan",
                style: AppTheme.bodyLarge
                    .copyWith(color: AppTheme.secondaryTextColor(context)),
              ),
              SizedBox(height: 32.h),
              Row(
                children: [
                  _buildSummaryCard("Pembayaran", paymentMethod,
                      Icons.account_balance_wallet_outlined, context),
                  SizedBox(width: 8.w),
                  _buildSummaryCard("Total", formatRupiah(totalAmount),
                      Icons.receipt_long_outlined, context),
                  SizedBox(width: 8.w),
                  _buildSummaryCard("Diterima", formatRupiah(receivedAmount),
                      Icons.money, context),
                  SizedBox(width: 8.w),
                  _buildSummaryCard("Kembalian", formatRupiah(kembalian),
                      Icons.point_of_sale_outlined, context),
                ],
              ),
              SizedBox(height: 32.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                      onPressed: () async {
                        // Create a snapshot to avoid ConcurrentModificationError if cart is cleared
                        final items = controller.penjualanDetailModelList.toList();
                        await controller.printLabels(items);
                      },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                      side: BorderSide(color: AppTheme.borderColor(context)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text("Cetak Label", style: TextStyle(color: AppTheme.primaryColor, fontFamily: AppTheme.fontMedium, fontSize: 16.sp)),
                  ),
                  SizedBox(width: 16.w),
                  OutlinedButton(
                    onPressed: () {
                      controller.printReceipt(
                          paymentMethod: paymentMethod,
                          total: totalAmount,
                          diterima: receivedAmount,
                          kembalian: kembalian);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.w, vertical: 16.h),
                      side: BorderSide(color: AppTheme.borderColor(context)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text("Cetak Ulang Struk",
                        style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontFamily: AppTheme.fontMedium,
                            fontSize: 16.sp)),
                  ),
                  SizedBox(width: 16.w),
                  ElevatedButton(
                    onPressed: () {
                      // 1. Manually update the existing dashboard state to POS (index 1) 
                      // and ensure sidebar is collapsed. This preserves the existing controllers.
                      if (Get.isRegistered<DashboardEmployeeController>()) {
                        final dCtrl = Get.find<DashboardEmployeeController>();
                        dCtrl.stateSelectedIndex.value = 1;
                        dCtrl.isSidebarCollapsed.value = true;
                      } else if (Get.isRegistered<DashboardAdminController>()) {
                        final dCtrl = Get.find<DashboardAdminController>();
                        dCtrl.stateSelectedIndex.value = 1;
                        dCtrl.isSidebarCollapsed.value = true;
                      }

                      // 2. Clear cart
                      controller.finalizePayment(); 
                      
                      // 3. Close the success dialog and PaymentScreen to return to the Dashboard
                      Get.back(); // Pop Dialog
                      Get.back(); // Pop PaymentScreen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: EdgeInsets.symmetric(
                          horizontal: 32.w, vertical: 16.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text("Selesai",
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: AppTheme.fontBold,
                            fontSize: 16.sp)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildSummaryCard(
      String label, String value, IconData icon, BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14.sp, color: AppTheme.primaryColor),
                SizedBox(width: 4.w),
                Expanded(
                    child: Text(label,
                        style: AppTheme.labelMedium.copyWith(fontSize: 10.sp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
            SizedBox(height: 8.h),
            Text(value,
                style: AppTheme.bodyLarge.copyWith(
                    fontFamily: AppTheme.fontBold, fontSize: 13.sp),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
