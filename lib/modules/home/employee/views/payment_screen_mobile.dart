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

class PaymentScreenMobile extends StatelessWidget {
  final HomeController controller;

  const PaymentScreenMobile({
    super.key,
    required this.controller,
  });

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
    final bool currentIsMerchant = controller.availableOrderTypes
            .where((type) => type != "Dine In" && type != "Take Away")
            .any((type) => type == controller.selectedOrderType.value);
            
    final initialMethod = currentIsMerchant && controller.filteredCashlessPaymentModes.isNotEmpty
        ? (controller.filteredCashlessPaymentModes.firstOrNull?['name']?.toString() ?? '')
        : (controller.shouldShowCashPayment 
            ? formatRupiah(controller.totalTransaction.value) 
            : (controller.filteredCashlessPaymentModes.firstOrNull?['name']?.toString() ?? ''));
    final selectedPaymentMethod = initialMethod.obs;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor(context)),
          onPressed: () => Get.back(),
        ),
        title: Text("Payment", style: AppTheme.titleLarge.copyWith(fontSize: 20.sp)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // REVIEW ORDER EXPANSION CARD (Collapsible style to save space)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(color: AppTheme.borderColor(context)),
              ),
              color: AppTheme.cardColor(context),
              child: ExpansionTile(
                initiallyExpanded: false,
                title: Text("Review Order Summary", 
                    style: AppTheme.bodyLarge.copyWith(fontFamily: AppTheme.fontBold)),
                subtitle: Obx(() => Text(
                      "${controller.penjualanDetailModelList.length} Items • ${formatRupiah(controller.totalTransaction.value)}",
                      style: AppTheme.labelMedium.copyWith(color: AppTheme.primaryColor),
                    )),
                childrenPadding: EdgeInsets.all(12.w),
                children: [
                  Obx(() => ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.penjualanDetailModelList.length,
                        separatorBuilder: (context, index) => Divider(
                            height: 12.h,
                            color: AppTheme.borderColor(context).withValues(alpha: 0.3)),
                        itemBuilder: (context, index) {
                          final item = controller.penjualanDetailModelList[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.description?.isNotEmpty == true ? item.description! : (item.productName ?? ""),
                                        style: AppTheme.bodyLarge.copyWith(
                                            fontFamily: AppTheme.fontBold,
                                            fontSize: 14.sp)),
                                    SizedBox(height: 2.h),
                                    if (item.hargaAwal > 0 && item.hargaAwal > item.hargaJual)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            formatRupiah(item.hargaAwal),
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 11.sp,
                                              decoration: TextDecoration.lineThrough,
                                              height: 1.0,
                                            ),
                                          ),
                                          Text(
                                            "${formatRupiah(item.hargaJual)} x ${item.jumlah}",
                                            style: AppTheme.labelMedium.copyWith(fontSize: 11.sp, height: 1.0),
                                          ),
                                        ],
                                      )
                                    else
                                      Text(
                                          "${formatRupiah(item.hargaJual)} x ${item.jumlah}",
                                          style: AppTheme.labelMedium.copyWith(fontSize: 11.sp)),
                                    if (item.orderType.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(top: 2.h),
                                        child: Text("Type: ${item.orderType}",
                                            style: TextStyle(
                                                color: AppTheme.primaryColor,
                                                fontSize: 10.sp,
                                                fontStyle: FontStyle.italic)),
                                      ),
                                    if (item.discountTotal > 0)
                                      Builder(builder: (_) {
                                        final base = item.hargaAwal > 0 ? item.hargaAwal : item.hargaJual;
                                        final nominalDiscount = item.discountType == 'percent'
                                            ? (base * item.discountTotal / 100).round()
                                            : (item.discountType == 'final_price'
                                                ? (base - item.discountTotal)
                                                : item.discountTotal);
                                        final label = item.discountType == 'percent'
                                            ? 'Disc ${item.discountTotal}% = -${formatRupiah(nominalDiscount)}'
                                            : 'Disc -${formatRupiah(nominalDiscount)}';
                                        return Padding(
                                          padding: EdgeInsets.only(top: 2.h),
                                          child: Row(
                                            children: [
                                              Icon(CupertinoIcons.tag_fill,
                                                  size: 10.sp,
                                                  color: const Color(0xFFFF6B35)),
                                              SizedBox(width: 4.w),
                                              Text(
                                                label,
                                                style: TextStyle(
                                                  color: const Color(0xFFFF6B35),
                                                  fontSize: 10.sp,
                                                  fontFamily: AppTheme.fontMedium,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    if (item.note.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(top: 6.h),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? const Color(0xFF1E2025)
                                                : const Color(0xFFF3F4F6),
                                            borderRadius: BorderRadius.only(
                                              topRight: Radius.circular(6.r),
                                              bottomRight: Radius.circular(6.r),
                                            ),
                                            border: Border(
                                              left: BorderSide(
                                                color: AppTheme.primaryColor,
                                                width: 3.w,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                CupertinoIcons.chat_bubble_text,
                                                size: 11.sp,
                                                color: AppTheme.secondaryTextColor(context),
                                              ),
                                              SizedBox(width: 6.w),
                                              Text(
                                                item.note,
                                                style: TextStyle(
                                                  color: AppTheme.textColor(context).withValues(alpha: 0.8),
                                                  fontSize: 11.sp,
                                                  fontFamily: AppTheme.fontMedium,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(formatRupiah(item.subtotal),
                                  style: AppTheme.bodyLarge.copyWith(
                                      fontFamily: AppTheme.fontBold,
                                      color: AppTheme.primaryColor,
                                      fontSize: 13.sp)),
                            ],
                          );
                        },
                      )),
                  Divider(
                      height: 16.h,
                      thickness: 1.5,
                      color: AppTheme.borderColor(context)),
                  _buildPriceRow("Base Price",
                      formatRupiah(controller.subtotalRaw.value), context),
                  SizedBox(height: 6.h),
                  _buildPriceRow("Taxes",
                      formatRupiah(controller.taxAmount.value), context),
                  Obx(() {
                    final discVal = controller.manualDiscountValue.value;
                    final isPercent = controller.manualDiscountIsPercent.value;
                    final defaultDisc = controller.disscount.value;
                    final bundleDisc = controller.bundlingDiscountAmount.value;

                    final List<Widget> discountRows = [];

                    if (bundleDisc > 0) {
                      discountRows.add(
                        Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: _buildPriceRow(
                              "Diskon Bundling", "-${formatRupiah(bundleDisc)}", context,
                              color: const Color(0xFFFF6B35)),
                        ),
                      );
                    }

                    if (discVal > 0) {
                      final String label = isPercent ? "Discount ($discVal%)" : "Discount";
                      final int amount = isPercent
                          ? (controller.subtotalRaw.value * discVal / 100).round()
                          : discVal;
                      discountRows.add(
                        Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: _buildPriceRow(
                              label, "-${formatRupiah(amount)}", context,
                              color: const Color(0xFFFF6B35)),
                        ),
                      );
                    } else if (defaultDisc > 0) {
                      discountRows.add(
                        Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: _buildPriceRow(
                              "Discount ($defaultDisc%)",
                              "-${formatRupiah((controller.subtotalRaw.value * defaultDisc / 100).round())}",
                              context,
                              color: const Color(0xFFFF6B35)),
                        ),
                      );
                    }

                    if (discountRows.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: discountRows,
                    );
                  }),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // TOTAL BANNER (Clean V2 style)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total",
                      style: AppTheme.titleLarge.copyWith(
                          color: AppTheme.primaryColor, fontSize: 18.sp)),
                  Obx(() => Text(
                      formatRupiah(controller.totalTransaction.value),
                      style: AppTheme.titleLarge.copyWith(
                          color: AppTheme.primaryColor,
                          fontSize: 20.sp,
                          fontFamily: AppTheme.fontBold))),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Text("Select Payment Method",
                style: AppTheme.titleLarge.copyWith(fontSize: 16.sp)),
            SizedBox(height: 12.h),

            // CASHLESS SECTION (Compact V2 Grid style)
            Obx(() {
              final modes = controller.filteredCashlessPaymentModes;
              if (modes.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Cashless",
                      style: AppTheme.labelMedium.copyWith(fontFamily: AppTheme.fontBold)),
                  SizedBox(height: 8.h),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double itemWidth = (constraints.maxWidth - 10.w) / 2;
                      return Wrap(
                        spacing: 10.w,
                        runSpacing: 10.h,
                        children: modes.map((mode) {
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
                          return SizedBox(
                            width: itemWidth,
                            child: _buildPaymentOption(name, icon, selectedPaymentMethod, context),
                          );
                        }).toList(),
                      );
                    }
                  ),
                ],
              );
            }),

            // CASH SECTION
            Obx(() {
              if (!controller.shouldShowCashPayment) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),
                  Text("Cash",
                      style: AppTheme.labelMedium.copyWith(fontFamily: AppTheme.fontBold)),
                  SizedBox(height: 8.h),
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: _buildPaymentOption(
                                  formatRupiah(controller.totalTransaction.value),
                                  Icons.money,
                                  selectedPaymentMethod,
                                  context,
                                  isCash: true)),
                          SizedBox(width: 10.w),
                          Expanded(
                              child: _buildPaymentOption(
                                  formatRupiah(50000),
                                  Icons.money,
                                  selectedPaymentMethod,
                                  context,
                                  isCash: true)),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Expanded(
                              child: _buildPaymentOption(
                                  formatRupiah(100000),
                                  Icons.money,
                                  selectedPaymentMethod,
                                  context,
                                  isCash: true)),
                          SizedBox(width: 10.w),
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
              );
            }),
            SizedBox(height: 24.h),

            // FIXED FOOTER: CONTINUE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  int cashValue = controller.totalTransaction.value;
                  String canonicalMethod = selectedPaymentMethod.value;

                  if (controller.manualCashAmount.value > 0 && 
                      selectedPaymentMethod.value == formatRupiah(controller.manualCashAmount.value)) {
                    cashValue = controller.manualCashAmount.value;
                    canonicalMethod = "Cash";
                  } else if (selectedPaymentMethod.value.contains("Rp.")) {
                    String cleanStr = selectedPaymentMethod.value.replaceAll("Rp. ", "").replaceAll(".", "");
                    cashValue = int.tryParse(cleanStr) ?? controller.totalTransaction.value;
                    canonicalMethod = "Cash";
                  } else {
                    cashValue = controller.totalTransaction.value;
                    canonicalMethod = selectedPaymentMethod.value;
                  }
                  
                  _showConfirmationDialog(
                      context, controller, canonicalMethod, cashValue);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                  elevation: 0,
                ),
                child: Text("Continue Transaction",
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: AppTheme.fontBold,
                        fontSize: 15.sp)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, BuildContext context, {Color? color}) {
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
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12.r),
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
                  size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                  child: Text(label,
                      style: AppTheme.bodyLarge.copyWith(
                          fontFamily: isSelected
                              ? AppTheme.fontBold
                              : AppTheme.fontRegular,
                          color: isSelected ? AppTheme.primaryColor : null,
                          fontSize: 13.sp))),
              Container(
                width: 16.w,
                height: 16.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey,
                      width: 2.w),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                            width: 8.w,
                            height: 8.w,
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
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Konfirmasi Pesanan",
                      style: AppTheme.titleLarge.copyWith(fontSize: 18.sp)),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey, size: 22.sp),
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
                          style: AppTheme.bodyLarge.copyWith(fontSize: 13.sp, color: AppTheme.secondaryTextColor(context)))),
                      SizedBox(height: 4.h),
                      Text(dateStr,
                          style: AppTheme.labelMedium.copyWith(fontSize: 11.sp, color: AppTheme.secondaryTextColor(context))),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("TOTAL",
                          style: AppTheme.labelMedium.copyWith(
                              fontSize: 9.sp, letterSpacing: 1.2)),
                      Text(formatRupiah(totalAmount),
                          style: AppTheme.titleLarge.copyWith(fontSize: 16.sp)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Divider(color: AppTheme.borderColor(context)),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined,
                                size: 12.sp, color: AppTheme.primaryColor),
                            SizedBox(width: 4.w),
                            Text("METODE PEMBAYARAN",
                                style: AppTheme.labelMedium.copyWith(
                                    fontSize: 8.sp, letterSpacing: 0.5)),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(paymentMethod,
                            style: AppTheme.bodyLarge
                                .copyWith(fontFamily: AppTheme.fontBold, fontSize: 13.sp)),
                      ],
                    ),
                  ),
                  Container(
                      width: 1.w, height: 30.h, color: AppTheme.borderColor(context)),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.money,
                                  size: 12.sp, color: AppTheme.primaryColor),
                              SizedBox(width: 4.w),
                              Text("DITERIMA",
                                  style: AppTheme.labelMedium.copyWith(
                                      fontSize: 8.sp, letterSpacing: 0.5)),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(formatRupiah(receivedAmount),
                              style: AppTheme.bodyLarge
                                  .copyWith(fontFamily: AppTheme.fontBold, fontSize: 13.sp)),
                        ],
                      ),
                    ),
                  ),
                  Container(
                      width: 1.w, height: 30.h, color: AppTheme.borderColor(context)),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.point_of_sale_outlined,
                                  size: 12.sp, color: AppTheme.primaryColor),
                              SizedBox(width: 4.w),
                              Text("KEMBALIAN",
                                  style: AppTheme.labelMedium.copyWith(
                                      fontSize: 8.sp, letterSpacing: 0.5)),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(formatRupiah(kembalian),
                              style: AppTheme.bodyLarge
                                  .copyWith(fontFamily: AppTheme.fontBold, fontSize: 13.sp)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: BorderSide(color: AppTheme.borderColor(context)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r)),
                      ),
                      child: Text("Batalkan",
                          style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontFamily: AppTheme.fontMedium,
                              fontSize: 14.sp)),
                    ),
                  ),
                  SizedBox(width: 12.w),
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
                                      await Future.delayed(const Duration(seconds: 2));
                                    }
                                    if (!context.mounted) return;

                                    _showSuccessDialog(context, controller,
                                        paymentMethod, receivedAmount, kembalian);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r)),
                          ),
                          child: controller.isProcessingPayment.value
                              ? SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: const CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text("Kirim",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: AppTheme.fontBold,
                                      fontSize: 14.sp)),
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

    void doFinish() {
      if (Get.isRegistered<DashboardEmployeeController>()) {
        final dCtrl = Get.find<DashboardEmployeeController>();
        dCtrl.stateSelectedIndex.value = 1;
        dCtrl.isSidebarCollapsed.value = true;
      } else if (Get.isRegistered<DashboardAdminController>()) {
        final dCtrl = Get.find<DashboardAdminController>();
        dCtrl.stateSelectedIndex.value = 1;
        dCtrl.isSidebarCollapsed.value = true;
      }
      controller.finalizePayment();
      Get.back(); // Pop Dialog
      Get.back(); // Pop PaymentScreen
    }

    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey, size: 22.sp),
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
                width: 60.w,
                height: 60.w,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.check, color: Colors.white, size: 36.sp),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "Pembayaran Berhasil!",
                style: AppTheme.titleLarge.copyWith(fontSize: 18.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                "Jangan lupa ucapkan terima kasih kepada pelanggan",
                textAlign: TextAlign.center,
                style: AppTheme.bodyLarge.copyWith(
                    fontSize: 12.sp,
                    color: AppTheme.secondaryTextColor(context)),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  _buildSummaryCard("Pembayaran", paymentMethod,
                      Icons.account_balance_wallet_outlined, context),
                  SizedBox(width: 6.w),
                  _buildSummaryCard("Total", formatRupiah(totalAmount),
                      Icons.receipt_long_outlined, context),
                ],
              ),
              SizedBox(height: 6.w),
              Row(
                children: [
                  _buildSummaryCard("Diterima", formatRupiah(receivedAmount),
                      Icons.money, context),
                  SizedBox(width: 6.w),
                  _buildSummaryCard("Kembalian", formatRupiah(kembalian),
                      Icons.point_of_sale_outlined, context),
                ],
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: doFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r)),
                  ),
                  child: Text("Selesai",
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: AppTheme.fontBold,
                          fontSize: 14.sp)),
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final items =
                            controller.penjualanDetailModelList.toList();
                        await controller.printLabels(items);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        side: BorderSide(color: AppTheme.borderColor(context)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r)),
                      ),
                      child: Text("Cetak Label",
                          style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontFamily: AppTheme.fontMedium,
                              fontSize: 12.sp)),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        controller.printReceipt(
                            paymentMethod: paymentMethod,
                            total: totalAmount,
                            diterima: receivedAmount,
                            kembalian: kembalian);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        side: BorderSide(color: AppTheme.borderColor(context)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r)),
                      ),
                      child: Text("Cetak Struk",
                          style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontFamily: AppTheme.fontMedium,
                              fontSize: 12.sp)),
                    ),
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

  Widget _buildSummaryCard(String label, String value, IconData icon, BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12.sp, color: AppTheme.primaryColor),
                SizedBox(width: 4.w),
                Expanded(
                    child: Text(label,
                        style: AppTheme.labelMedium.copyWith(fontSize: 9.sp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
            SizedBox(height: 6.h),
            Text(value,
                style: AppTheme.bodyLarge.copyWith(
                    fontFamily: AppTheme.fontBold, fontSize: 11.sp),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
