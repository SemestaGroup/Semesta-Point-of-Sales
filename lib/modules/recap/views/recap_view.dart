import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:semesta_pos/modules/recap/controllers/recap_controller.dart';
import 'package:semesta_pos/modules/recap/widgets/audit_keypad_dialog.dart';
import 'package:semesta_pos/modules/setting/controllers/setting_controller.dart';
import 'package:semesta_pos/core/models/shift/shift_model.dart';
import 'package:semesta_pos/modules/home/employee/controllers/shift_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class RecapView extends StatelessWidget {
  const RecapView({super.key});

  String _formatRupiah(int number) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(number);
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppTheme.primaryColor,
                  size: AppTheme.fontSizeTitleMedium + 4.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Shift Reconciliation",
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeTitleMedium,
                      fontFamily: AppTheme.fontBold,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "Manage actual cash and payment balance for active shift",
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLabelLarge,
                      color:
                          isDark ? Colors.grey.shade100 : Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: AppTheme.primaryColor),
                onPressed: () {
                  final ctrl = Get.find<RecapController>();
                  ctrl.initRecap();
                  ctrl.refreshHistory();
                },
                tooltip: "Refresh Data",
              ),
              SizedBox(width: 8.w),
              ElevatedButton.icon(
                onPressed: () =>
                    Get.find<RecapController>().confirmCloseShift(context),
                icon: Icon(Icons.lock_outline_rounded,
                    size: 18.sp, color: Colors.white),
                label: Text(
                  "Close Shift",
                  style: TextStyle(
                    fontFamily: AppTheme.fontBold,
                    fontSize: 14.sp,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE63946), // Red for closure
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader(BuildContext context) {
    return TabBar(
      indicatorColor: AppTheme.primaryColor,
      labelColor: AppTheme.primaryColor,
      unselectedLabelColor: Colors.grey,
      indicatorWeight: 3,
      labelStyle: AppTheme.bodyLarge.copyWith(fontFamily: AppTheme.fontBold),
      tabs: const [
        Tab(text: "Recap Summary"),
        Tab(text: "History"),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use existing controller if registered, otherwise create it once.
    // Avoid Get.put() here because it re-creates the controller on every
    // render cycle, causing duplicate SyncService listeners.
    final controller = Get.isRegistered<RecapController>()
        ? Get.find<RecapController>()
        : Get.put(RecapController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackgroundColor(context),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildHeader(context),
                    _buildSubHeader(context),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildRecapTab(context, controller),
                    _buildHistoryTab(context, controller),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecapTab(BuildContext context, RecapController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor));
      }

      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          children: [
            // Header Stats
            Row(
              children: [
                _buildStatCard("Total Recorded", _formatRupiah(controller.getTotalRecorded()), AppTheme.primaryColor, context),
                SizedBox(width: 16.w),
                _buildStatCard("Total Audited", _formatRupiah(controller.getTotalAudited()), Colors.green, context),
                SizedBox(width: 16.w),
                _buildStatCard(
                  "Total Difference", 
                  _formatRupiah(controller.getTotalDiff()), 
                  controller.getTotalDiff() < 0 ? Colors.red : (controller.getTotalDiff() > 0 ? Colors.orange : Colors.grey),
                  context
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Opening Balance banner
            Builder(builder: (context) {
              final shift = Get.find<ShiftController>().activeShift.value;
              final openingBal = shift?.startingBalance ?? 0;
              return Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 16.sp, color: Colors.blue),
                  SizedBox(width: 8.w),
                  Text('Opening Balance (Modal Awal):',
                      style: AppTheme.labelMedium.copyWith(color: Colors.blue)),
                  const Spacer(),
                  Text(_formatRupiah(openingBal),
                      style: AppTheme.labelMedium.copyWith(
                          fontFamily: AppTheme.fontBold, color: Colors.blue)),
                ]),
              );
            }),

            // Detailed Breakdown
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 3, child: _buildPaymentModesSection(context, controller, isDark)),
                  SizedBox(width: 16.w),
                  Expanded(flex: 2, child: _buildProductsSoldSection(context, controller, isDark)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPaymentModesSection(BuildContext context, RecapController controller, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12.r), topRight: Radius.circular(12.r)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text("Payment Mode", style: AppTheme.labelMedium.copyWith(fontFamily: AppTheme.fontBold, fontSize: 12.sp))),
                Expanded(flex: 2, child: Text("System", style: AppTheme.labelMedium.copyWith(fontFamily: AppTheme.fontBold, fontSize: 12.sp), textAlign: TextAlign.right)),
                Expanded(flex: 2, child: Text("Actual", style: AppTheme.labelMedium.copyWith(fontFamily: AppTheme.fontBold, fontSize: 12.sp), textAlign: TextAlign.right)),
                Expanded(flex: 2, child: Text("Diff", style: AppTheme.labelMedium.copyWith(fontFamily: AppTheme.fontBold, fontSize: 12.sp), textAlign: TextAlign.right)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: controller.paymentModes.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: AppTheme.borderColor(context)),
              itemBuilder: (context, index) {
                final mode = controller.paymentModes[index];
                final recorded = controller.getRecordedAmount(mode.id);
                final audited = controller.getAuditedAmount(mode.id);
                final diff = controller.getDiffAmount(mode.id);

                return InkWell(
                  onTap: () async {
                    final result = await showDialog<int>(
                      context: context,
                      builder: (context) => AuditKeypadDialog(
                        title: mode.name,
                        initialValue: audited,
                      ),
                    );
                    if (result != null) {
                      controller.updateAuditAmount(mode.id, result);
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Icon(Icons.payment_rounded, size: 14.sp, color: AppTheme.primaryColor),
                              SizedBox(width: 8.w),
                              Text(mode.name, style: AppTheme.bodyLarge.copyWith(fontFamily: AppTheme.fontMedium, fontSize: 13.sp)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(_formatRupiah(recorded), style: AppTheme.bodyLarge.copyWith(fontSize: 12.sp), textAlign: TextAlign.right),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            margin: EdgeInsets.only(left: 8.w),
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: audited > 0 ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(color: audited > 0 ? AppTheme.primaryColor.withValues(alpha: 0.3) : AppTheme.borderColor(context)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(_formatRupiah(audited), style: AppTheme.bodyLarge.copyWith(color: audited > 0 ? AppTheme.primaryColor : Colors.grey, fontFamily: AppTheme.fontBold, fontSize: 12.sp)),
                                SizedBox(width: 4.w),
                                Icon(Icons.edit_note_rounded, size: 14.sp, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(_formatRupiah(diff),
                              style: AppTheme.bodyLarge.copyWith(
                                  color: diff < 0 ? Colors.red : (diff > 0 ? Colors.orange : Colors.grey),
                                  fontFamily: AppTheme.fontBold, fontSize: 12.sp),
                              textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSoldSection(BuildContext context, RecapController controller, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12.r), topRight: Radius.circular(12.r)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text("Products Sold", style: AppTheme.labelMedium.copyWith(fontFamily: AppTheme.fontBold, fontSize: 12.sp))),
                Expanded(flex: 1, child: Text("Qty", style: AppTheme.labelMedium.copyWith(fontFamily: AppTheme.fontBold, fontSize: 12.sp), textAlign: TextAlign.right)),
                Expanded(flex: 2, child: Text("Total", style: AppTheme.labelMedium.copyWith(fontFamily: AppTheme.fontBold, fontSize: 12.sp), textAlign: TextAlign.right)),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.productsSoldList.isEmpty) {
                return Center(child: Text("No items sold yet.", style: AppTheme.bodyLarge.copyWith(color: Colors.grey, fontSize: 13.sp)));
              }
              return ListView.separated(
                itemCount: controller.productsSoldList.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: AppTheme.borderColor(context)),
                itemBuilder: (context, index) {
                  final item = controller.productsSoldList[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(item['name']?.toString() ?? 'Unknown', style: AppTheme.bodyLarge.copyWith(fontSize: 13.sp, fontFamily: AppTheme.fontMedium), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text("${item['qty']}", style: AppTheme.bodyLarge.copyWith(fontSize: 13.sp), textAlign: TextAlign.right),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(_formatRupiah(item['total'] ?? 0), style: AppTheme.bodyLarge.copyWith(fontSize: 13.sp, fontFamily: AppTheme.fontBold), textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, RecapController controller) {
    return Obx(() {
        final history = controller.shiftHistory;

        if (history.isEmpty) {
          return Center(child: Text("No shift history found", style: AppTheme.bodyLarge.copyWith(color: Colors.grey)));
        }

        return ListView.builder(
          padding: EdgeInsets.all(24.w),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final shift = history[index];
            final startTime = DateTime.tryParse(shift['start_time'] ?? "") ?? DateTime.now();
            final endTimeStr = shift['end_time']?.toString() ?? "";
            final endTime = endTimeStr.isNotEmpty ? DateTime.tryParse(endTimeStr) : null;
            final dateStr = DateFormat('dd MMM yyyy').format(startTime);
            final timeRange = "${DateFormat('HH:mm').format(startTime)} - ${endTime != null ? DateFormat('HH:mm').format(endTime) : 'Active'}";

            return InkWell(
              onTap: () => _showShiftDetailDialog(context, shift),
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                margin: EdgeInsets.only(bottom: 16.h),
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppTheme.borderColor(context)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${shift['shift_name']} • ${shift['user_id'] ?? 'Kasir'}", style: AppTheme.titleLarge.copyWith(fontSize: 18.sp)),
                            Text("$dateStr | $timeRange", style: AppTheme.labelMedium),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.print, color: AppTheme.primaryColor, size: 22.sp),
                              onPressed: () {
                                final shiftModel = ShiftSessionModel.fromJson(shift);
                                final Map<String, int> recapData = {
                                  'cash': (shift['total_cash_expected'] as num?)?.toInt() ?? 0,
                                  'nonCash': (shift['total_non_cash'] as num?)?.toInt() ?? 0,
                                };
                                Get.find<SettingController>().printZReport(shiftModel, recapData);
                              },
                              tooltip: "Re-print Z-Report",
                            ),
                            Builder(
                              builder: (context) {
                                final isSynced = (shift['is_synced'] as int?) == 1;
                                return Tooltip(
                                  message: isSynced ? "Synced" : "Pending Sync",
                                  child: Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: isSynced ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isSynced ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded, 
                                      color: isSynced ? Colors.green : Colors.orange, 
                                      size: 24.sp
                                    ),
                                  ),
                                );
                              }
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    const Divider(),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         _buildHistoryStat("Opening", _formatRupiah(shift['starting_balance'] ?? 0)),
                         _buildHistoryStat("System Cash", _formatRupiah(shift['total_cash_expected'] ?? 0)),
                         _buildHistoryStat("Actual Cash", _formatRupiah(shift['total_cash_actual'] ?? 0)),
                         _buildHistoryStat("Difference", _formatRupiah((shift['total_cash_actual'] ?? 0) - (shift['total_cash_expected'] ?? 0))),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.labelMedium.copyWith(fontSize: 10.sp)),
        SizedBox(height: 4.h),
        Text(value, style: AppTheme.bodyLarge.copyWith(fontFamily: AppTheme.fontBold)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTheme.labelMedium.copyWith(color: color, fontFamily: AppTheme.fontBold, fontSize: 10.sp)),
            SizedBox(height: 4.h),
            Text(value, style: AppTheme.titleLarge.copyWith(color: color, fontSize: 18.sp, fontFamily: AppTheme.fontBold)),
          ],
        ),
      ),
    );
  }

  void _showShiftDetailDialog(BuildContext context, Map<String, dynamic> shift) {
    final String reconDataRaw = shift['reconciliation_data']?.toString() ?? "[]";
    List<dynamic> reconList = [];
    try {
      reconList = jsonDecode(reconDataRaw);
    } catch (_) {}

    final Map<String, dynamic> data = reconList.isNotEmpty ? reconList.first : {};
    final List<dynamic> paymentModes = data['payment_modes'] ?? [];
    final List<dynamic> productsSold = data['products_sold'] ?? [];

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Container(
          width: 0.8.sw,
          height: 0.8.sh,
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Shift Detail: ${shift['shift_name']}", style: AppTheme.titleLarge),
                      Text("PIC: ${shift['user_id'] ?? 'Unknown'}", style: AppTheme.labelMedium),
                    ],
                  ),
                  IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              SizedBox(height: 16.h),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Payment Breakdown", style: AppTheme.bodyLarge.copyWith(fontFamily: AppTheme.fontBold)),
                      SizedBox(height: 12.h),
                      Table(
                        border: TableBorder.all(color: AppTheme.borderColor(context), borderRadius: BorderRadius.circular(8.r)),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05)),
                            children: [
                              _tableHeader("Mode"),
                              _tableHeader("System"),
                              _tableHeader("Actual"),
                              _tableHeader("Diff"),
                            ],
                          ),
                          ...paymentModes.map((p) => TableRow(
                            children: [
                              _tableCell(p['name'] ?? ''),
                              _tableCell(_formatRupiah((p['recorded'] as num?)?.toInt() ?? 0), align: TextAlign.right),
                              _tableCell(_formatRupiah((p['audited'] as num?)?.toInt() ?? 0), align: TextAlign.right),
                              _tableCell(_formatRupiah((p['diff'] as num?)?.toInt() ?? 0), align: TextAlign.right, color: (p['diff'] as num? ?? 0) < 0 ? Colors.red : Colors.green),
                            ],
                          )),
                        ],
                      ),
                      SizedBox(height: 32.h),
                      Text("Products Sold", style: AppTheme.bodyLarge.copyWith(fontFamily: AppTheme.fontBold)),
                      SizedBox(height: 12.h),
                      Table(
                        border: TableBorder.all(color: AppTheme.borderColor(context), borderRadius: BorderRadius.circular(8.r)),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05)),
                            children: [
                              _tableHeader("Product Name"),
                              _tableHeader("Qty"),
                              _tableHeader("Total"),
                            ],
                          ),
                          ...productsSold.map((p) => TableRow(
                            children: [
                              _tableCell(p['name'] ?? ''),
                              _tableCell("${p['qty']}", align: TextAlign.right),
                              _tableCell(_formatRupiah((p['total'] as num?)?.toInt() ?? 0), align: TextAlign.right),
                            ],
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tableHeader(String text) => Padding(
    padding: EdgeInsets.all(10.w),
    child: Text(text, style: AppTheme.labelMedium.copyWith(fontFamily: AppTheme.fontBold)),
  );

  Widget _tableCell(String text, {TextAlign align = TextAlign.left, Color? color}) => Padding(
    padding: EdgeInsets.all(10.w),
    child: Text(text, style: AppTheme.bodyLarge.copyWith(fontSize: 13.sp, color: color), textAlign: align),
  );
}
