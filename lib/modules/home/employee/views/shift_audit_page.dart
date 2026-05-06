import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/models/payment/payment_mode_model.dart';
import 'package:semesta_pos/modules/home/employee/controllers/shift_audit_controller.dart';
import 'package:semesta_pos/modules/home/employee/controllers/shift_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';

/// Mode this page is shown in.
enum ShiftAuditMode { open, close }

class ShiftAuditPage extends StatelessWidget {
  final ShiftAuditMode mode;
  final String shiftName;

  const ShiftAuditPage({
    super.key,
    required this.mode,
    required this.shiftName,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ShiftAuditController>();
    final isOpen = mode == ShiftAuditMode.open;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isOpen, ctrl),
            Expanded(
              child: Obx(() {
                if (ctrl.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildBody(context, ctrl, isOpen);
              }),
            ),
            _buildFooter(context, ctrl, isOpen),
          ],
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(
      BuildContext context, bool isOpen, ShiftAuditController ctrl) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        border:
            Border(bottom: BorderSide(color: AppTheme.borderColor(context))),
      ),
      child: Row(
        children: [
          // Back button
          InkWell(
            onTap: () => Get.back(),
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppTheme.scaffoldBackgroundColor(context),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppTheme.borderColor(context)),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios_new,
                      size: 14.sp, color: AppTheme.primaryColor),
                  SizedBox(width: 6.w),
                  Text(
                    'Back',
                    style: TextStyle(
                      fontFamily: AppTheme.fontBold,
                      fontSize: 13.sp,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 24.w),
          // Icon badge
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isOpen
                  ? Colors.green.withValues(alpha: 0.12)
                  : Colors.orange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOpen ? CupertinoIcons.lock_open_fill : CupertinoIcons.lock_fill,
              color: isOpen ? Colors.green : Colors.orange,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOpen ? 'Open Shift — Cash Recap' : 'Close Shift — Cash Audit',
                  style: TextStyle(
                    fontFamily: AppTheme.fontBold,
                    fontSize: 20.sp,
                    color: AppTheme.textColor(context),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  isOpen
                      ? 'Enter starting cash per payment method to record opening balance.'
                      : 'Count physical cash/receipts and enter actual amounts for each method.',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMedium,
                    fontSize: 13.sp,
                    color: AppTheme.secondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          // Shift name badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.time,
                    size: 14.sp, color: AppTheme.primaryColor),
                SizedBox(width: 6.w),
                Text(
                  shiftName,
                  style: TextStyle(
                    fontFamily: AppTheme.fontBold,
                    fontSize: 13.sp,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── BODY ────────────────────────────────────────────────────────────────────
  Widget _buildBody(
      BuildContext context, ShiftAuditController ctrl, bool isOpen) {
    if (ctrl.paymentModes.isEmpty) {
      return _buildEmptyState(context);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT: payment mode list
        Expanded(
          flex: 6,
          child: _buildPaymentList(context, ctrl, isOpen),
        ),

        // RIGHT: close shift summary (only on close mode)
        if (!isOpen) ...[
          Container(
            width: 1,
            color: AppTheme.borderColor(context),
          ),
          Expanded(
            flex: 4,
            child: _buildCloseSummary(context, ctrl),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.creditcard_fill,
              size: 60.sp, color: AppTheme.borderColor(context)),
          SizedBox(height: 16.h),
          Text(
            'No payment modes available',
            style: TextStyle(
              fontFamily: AppTheme.fontMedium,
              fontSize: 18.sp,
              color: AppTheme.textColorSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Please sync data first to load payment modes.',
            style: TextStyle(
              fontFamily: AppTheme.fontRegular,
              fontSize: 14.sp,
              color: AppTheme.textColorSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList(
      BuildContext context, ShiftAuditController ctrl, bool isOpen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info banner
        Container(
          margin: EdgeInsets.all(24.w),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.info_circle_fill,
                  size: 18.sp, color: AppTheme.primaryColor),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  isOpen
                      ? 'Enter the cash amount for each payment method before opening the shift. Leave at Rp 0 if none.'
                      : 'Count the physical cash and receipts for each payment method. Any discrepancy will be highlighted.',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMedium,
                    fontSize: 13.sp,
                    color: AppTheme.primaryColor,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Payment mode rows
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 4.h),
            itemCount: ctrl.paymentModes.length,
            separatorBuilder: (_, __) => SizedBox(height: 8.h),
            itemBuilder: (context, index) {
              final mode = ctrl.paymentModes[index];
              return _buildPaymentRow(context, ctrl, mode, isOpen);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(BuildContext context, ShiftAuditController ctrl,
      PaymentModeModel mode, bool isOpen) {
    return Obx(() {
      final amount = isOpen
          ? ctrl.openingAmounts[mode.id] ?? 0
          : ctrl.auditAmounts[mode.id] ?? 0;
      final recorded = ctrl.recordedAmounts[mode.id] ?? 0;
      final diff = amount - recorded;
      final hasValue = amount > 0;

      return InkWell(
        onTap: () => _showNumpad(context, ctrl, mode, isOpen),
        borderRadius: BorderRadius.circular(16.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: hasValue
                ? AppTheme.primaryColor.withValues(alpha: 0.06)
                : AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: hasValue
                  ? AppTheme.primaryColor.withValues(alpha: 0.3)
                  : AppTheme.borderColor(context),
              width: hasValue ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: _iconColorForMode(mode.name).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  _iconForMode(mode.name),
                  size: 16.sp,
                  color: _iconColorForMode(mode.name),
                ),
              ),
              SizedBox(width: 16.w),

              // Name + recorded amount (close mode)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.name,
                      style: TextStyle(
                        fontFamily: AppTheme.fontBold,
                        fontSize: 14.sp,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    if (!isOpen && recorded > 0) ...[
                      SizedBox(height: 2.h),
                      Text(
                        'System: ${_fmtRp(recorded)}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontMedium,
                          fontSize: 12.sp,
                          color: AppTheme.secondaryTextColor(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Amount + diff badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmtRp(amount),
                    style: TextStyle(
                      fontFamily: AppTheme.fontBold,
                      fontSize: 14.sp,
                      color: hasValue
                          ? AppTheme.primaryColor
                          : AppTheme.textColorSecondary,
                    ),
                  ),
                  if (!isOpen && (amount > 0 || recorded > 0)) ...[
                    SizedBox(height: 4.h),
                    _buildDiffBadge(context, diff),
                  ],
                ],
              ),

              SizedBox(width: 8.w),
              Icon(CupertinoIcons.chevron_right,
                  size: 16.sp, color: AppTheme.secondaryTextColor(context)),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDiffBadge(BuildContext context, int diff) {
    if (diff == 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          'Balanced',
          style: TextStyle(
              fontFamily: AppTheme.fontBold,
              fontSize: 10.sp,
              color: Colors.green[700]),
        ),
      );
    }
    final isOver = diff > 0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: (isOver ? Colors.blue : Colors.red).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        '${isOver ? '+' : ''}${_fmtRp(diff)}',
        style: TextStyle(
          fontFamily: AppTheme.fontBold,
          fontSize: 10.sp,
          color: isOver ? Colors.blue[700] : Colors.red[700],
        ),
      ),
    );
  }

  // ── CLOSE SHIFT SUMMARY (right panel) ─────────────────────────────────────
  Widget _buildCloseSummary(
      BuildContext context, ShiftAuditController ctrl) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shift Summary',
            style: TextStyle(
              fontFamily: AppTheme.fontBold,
              fontSize: 18.sp,
              color: AppTheme.textColor(context),
            ),
          ),
          SizedBox(height: 16.h),

          // Opening Balance Info Box (Modal Awal)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.info_circle_fill,
                    size: 16.sp, color: AppTheme.primaryColor),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Opening Balance (Modal Awal)',
                    style: TextStyle(
                      fontFamily: AppTheme.fontMedium,
                      fontSize: 13.sp,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                ),
                Text(
                  _fmtRp(Get.find<ShiftController>().activeShift.value?.startingBalance ?? 0),
                  style: TextStyle(
                    fontFamily: AppTheme.fontBold,
                    fontSize: 13.sp,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Per-mode comparison table
          ...ctrl.paymentModes.map((mode) {
            return Obx(() {
              final recorded = ctrl.recordedAmounts[mode.id] ?? 0;
              final audited = ctrl.auditAmounts[mode.id] ?? 0;
              final diff = audited - recorded;
              return _buildSummaryRow(context, mode.name, recorded, audited, diff);
            });
          }),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Divider(color: AppTheme.borderColor(context)),
          ),

          // Totals
          Obx(() {
            final totalRecorded = ctrl.totalRecorded;
            final totalAudited = ctrl.totalAudited;
            final totalDiff = totalAudited - totalRecorded;
            return Column(
              children: [
                _buildTotalRow(context, 'Total System', totalRecorded,
                    color: AppTheme.primaryColor),
                SizedBox(height: 8.h),
                _buildTotalRow(context, 'Total Physical', totalAudited,
                    color: AppTheme.textColor(context)),
                SizedBox(height: 12.h),
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: _diffColor(totalDiff).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                        color: _diffColor(totalDiff).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Difference',
                        style: TextStyle(
                          fontFamily: AppTheme.fontBold,
                          fontSize: 14.sp,
                          color: _diffColor(totalDiff),
                        ),
                      ),
                      Text(
                        '${totalDiff >= 0 ? '+' : ''}${_fmtRp(totalDiff)}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontBold,
                          fontSize: 18.sp,
                          color: _diffColor(totalDiff),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),

          SizedBox(height: 24.h),

          // Notes field
          Text(
            'Shift Closing Notes',
            style: TextStyle(
              fontFamily: AppTheme.fontBold,
              fontSize: 14.sp,
              color: AppTheme.textColor(context),
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: ctrl.noteController,
            maxLines: 3,
            style: TextStyle(
              fontFamily: AppTheme.fontMedium,
              fontSize: 14.sp,
              color: AppTheme.textColor(context),
            ),
            decoration: InputDecoration(
              hintText: 'Add optional notes...',
              hintStyle: TextStyle(
                color: AppTheme.secondaryTextColor(context),
                fontFamily: AppTheme.fontMedium,
                fontSize: 14.sp,
              ),
              filled: true,
              fillColor: AppTheme.cardColor(context),
              contentPadding: EdgeInsets.all(16.w),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppTheme.borderColor(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppTheme.borderColor(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide:
                    const BorderSide(color: AppTheme.primaryColor, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, int recorded,
      int audited, int diff) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontMedium,
                fontSize: 13.sp,
                color: AppTheme.textColor(context),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtRp(audited),
                style: TextStyle(
                  fontFamily: AppTheme.fontBold,
                  fontSize: 13.sp,
                  color: AppTheme.textColor(context),
                ),
              ),
              if (diff != 0)
                Text(
                  '${diff > 0 ? '+' : ''}${_fmtRp(diff)} vs system',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMedium,
                    fontSize: 11.sp,
                    color: diff > 0 ? Colors.blue : Colors.red,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(BuildContext context, String label, int amount,
      {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontMedium,
            fontSize: 14.sp,
            color: AppTheme.textColor(context),
          ),
        ),
        Text(
          _fmtRp(amount),
          style: TextStyle(
            fontFamily: AppTheme.fontBold,
            fontSize: 15.sp,
            color: color ?? AppTheme.textColor(context),
          ),
        ),
      ],
    );
  }

  // ── FOOTER ──────────────────────────────────────────────────────────────────
  Widget _buildFooter(
      BuildContext context, ShiftAuditController ctrl, bool isOpen) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        border: Border(top: BorderSide(color: AppTheme.borderColor(context))),
      ),
      child: Row(
        children: [
          // Total entered
          Obx(() {
            final total = isOpen ? ctrl.totalOpening : ctrl.totalAudited;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOpen ? 'Total Opening Balance' : 'Total Physical Cash',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMedium,
                    fontSize: 12.sp,
                    color: AppTheme.secondaryTextColor(context),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _fmtRp(total),
                  style: TextStyle(
                    fontFamily: AppTheme.fontBold,
                    fontSize: 22.sp,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            );
          }),

          const Spacer(),

          // Cancel button
          OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              padding:
                  EdgeInsets.symmetric(horizontal: 28.w, vertical: 16.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r)),
              side: BorderSide(color: AppTheme.borderColor(context)),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: AppTheme.fontBold,
                fontSize: 15.sp,
                color: AppTheme.textColor(context),
              ),
            ),
          ),
          SizedBox(width: 16.w),

          // Confirm button
          Obx(() => ElevatedButton.icon(
                onPressed: ctrl.isSubmitting.value
                    ? null
                    : () => _onConfirm(context, ctrl, isOpen),
                icon: ctrl.isSubmitting.value
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Icon(
                        isOpen
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.lock_fill,
                        size: 18.sp,
                      ),
                label: Text(
                  isOpen ? 'Open Shift' : 'Close Shift',
                  style: TextStyle(
                    fontFamily: AppTheme.fontBold,
                    fontSize: 16.sp,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isOpen ? Colors.green : const Color(0xFFE63946),
                  disabledBackgroundColor:
                      isOpen ? Colors.green.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.4),
                  padding: EdgeInsets.symmetric(
                      horizontal: 32.w, vertical: 16.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r)),
                  elevation: 0,
                ),
              )),
        ],
      ),
    );
  }

  // ── NUMPAD DIALOG ─────────────────────────────────────────────────────────
  void _showNumpad(BuildContext context, ShiftAuditController ctrl,
      PaymentModeModel mode, bool isOpen) {
    final current =
        isOpen ? ctrl.openingAmounts[mode.id] ?? 0 : ctrl.auditAmounts[mode.id] ?? 0;
    final textCtrl = TextEditingController(text: current == 0 ? '' : current.toString());

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(24.w),
        child: Container(
          constraints: BoxConstraints(maxWidth: 400.w),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Padding(
                padding: EdgeInsets.fromLTRB(28.w, 28.h, 28.w, 0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: _iconColorForMode(mode.name).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(_iconForMode(mode.name),
                          size: 20.sp, color: _iconColorForMode(mode.name)),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode.name,
                            style: TextStyle(
                              fontFamily: AppTheme.fontBold,
                              fontSize: 18.sp,
                              color: AppTheme.textColor(context),
                            ),
                          ),
                          Text(
                            isOpen ? 'Opening cash' : 'Actual physical cash',
                            style: TextStyle(
                              fontFamily: AppTheme.fontMedium,
                              fontSize: 13.sp,
                              color: AppTheme.secondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Amount display + Numpad + Save Button
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 28.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    'Rp ',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontBold,
                                      fontSize: 20.sp,
                                      color:
                                          AppTheme.secondaryTextColor(context),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      textCtrl.text.isEmpty
                                          ? '0'
                                          : textCtrl.text,
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontBold,
                                        fontSize: 28.sp,
                                        color: textCtrl.text.isEmpty
                                            ? AppTheme.borderColor(context)
                                            : AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isOpen &&
                                (ctrl.recordedAmounts[mode.id] ?? 0) > 0)
                              Text(
                                'System recorded: ${_fmtRp(ctrl.recordedAmounts[mode.id] ?? 0)}',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontMedium,
                                  fontSize: 12.sp,
                                  color: AppTheme.secondaryTextColor(context),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 8.h),

                      // Numpad
                      _buildNumpad(textCtrl, () {
                        setDialogState(() {});
                      }),

                      SizedBox(height: 16.h),

                      // Buttons
                      Padding(
                        padding: EdgeInsets.fromLTRB(28.w, 0, 28.w, 24.h),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Get.back(),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12.r)),
                                  side: BorderSide(
                                      color: AppTheme.borderColor(context)),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontBold,
                                    color: AppTheme.textColor(context),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final amount = int.tryParse(textCtrl.text
                                          .replaceAll(',', '')
                                          .replaceAll('.', '')) ??
                                      0;
                                  if (isOpen) {
                                    ctrl.setOpeningAmount(mode.id, amount);
                                  } else {
                                    ctrl.setAuditAmount(mode.id, amount);
                                  }
                                  Get.back();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12.r)),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Save',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontBold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildNumpad(TextEditingController ctrl, VoidCallback onUpdate) {
    final keys = ['7', '8', '9', '4', '5', '6', '1', '2', '3', '000', '0', '⌫'];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        childAspectRatio: 2.8,
        mainAxisSpacing: 8.h,
        crossAxisSpacing: 8.w,
        physics: const NeverScrollableScrollPhysics(),
        children: keys.map((k) {
          return InkWell(
            onTap: () {
              if (k == '⌫') {
                if (ctrl.text.isNotEmpty) {
                  ctrl.text = ctrl.text.substring(0, ctrl.text.length - 1);
                }
              } else {
                if (ctrl.text == '0' || ctrl.text == '') {
                  ctrl.text = k == '000' ? '0' : k;
                } else {
                  if (ctrl.text.length < 15) {
                    ctrl.text = ctrl.text + k;
                  }
                }
              }
              onUpdate();
            },
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              decoration: BoxDecoration(
                color: k == '⌫'
                    ? Colors.red.withValues(alpha: 0.1)
                    : AppTheme.scaffoldBackgroundColor(Get.context!),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                    color: AppTheme.borderColor(Get.context!)),
              ),
              alignment: Alignment.center,
              child: k == '⌫'
                  ? Icon(CupertinoIcons.delete_left_fill,
                      size: 16.sp, color: Colors.red)
                  : Text(
                      k,
                      style: TextStyle(
                        fontFamily: AppTheme.fontBold,
                        fontSize: 16.sp,
                        color: AppTheme.textColor(Get.context!),
                      ),
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── CONFIRM ACTION ─────────────────────────────────────────────────────────
  Future<void> _onConfirm(
      BuildContext context, ShiftAuditController ctrl, bool isOpen) async {
    debugPrint('ShiftAuditPage: Confirm button pressed. Mode: ${isOpen ? 'Open' : 'Close'}');
    if (isOpen) {
      await ctrl.confirmOpenShift(shiftName);
    } else {
      await ctrl.confirmCloseShift();
    }
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────
  Color _diffColor(int diff) {
    if (diff == 0) return Colors.green;
    return diff > 0 ? Colors.blue : Colors.red;
  }

  String _fmtRp(int v) {
    if (v == 0) return 'Rp 0';
    String s = v.abs().toString();
    String result = '';
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      count++;
      result = s[i] + result;
      if (count % 3 == 0 && i != 0) result = '.$result';
    }
    return 'Rp ${v < 0 ? "-" : ""}$result';
  }

  IconData _iconForMode(String name) {
    final n = name.toLowerCase();
    if (n.contains('cash') || n.contains('tunai')) return CupertinoIcons.money_dollar_circle_fill;
    if (n.contains('transfer') || n.contains('bank')) return CupertinoIcons.arrow_right_arrow_left_circle_fill;
    if (n.contains('qris') || n.contains('qr')) return CupertinoIcons.qrcode;
    if (n.contains('edc') || n.contains('card') || n.contains('debit') || n.contains('kredit')) return CupertinoIcons.creditcard_fill;
    if (n.contains('shopee')) return CupertinoIcons.bag_fill;
    if (n.contains('grab')) return CupertinoIcons.car_fill;
    if (n.contains('gofood') || n.contains('go-food')) return CupertinoIcons.cube_box_fill;
    return CupertinoIcons.creditcard;
  }

  Color _iconColorForMode(String name) {
    final n = name.toLowerCase();
    if (n.contains('cash') || n.contains('tunai')) return Colors.green;
    if (n.contains('transfer') || n.contains('bank')) return Colors.blue;
    if (n.contains('qris') || n.contains('qr')) return const Color(0xFF9C27B0);
    if (n.contains('edc') || n.contains('card')) return Colors.orange;
    if (n.contains('shopee')) return Colors.deepOrange;
    if (n.contains('grab')) return Colors.teal;
    if (n.contains('gofood') || n.contains('go-food')) return Colors.red;
    return Colors.blueGrey;
  }
}
