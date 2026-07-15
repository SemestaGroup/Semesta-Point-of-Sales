import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:semesta_pos/core/models/payment/payment_mode_model.dart';
import 'package:semesta_pos/core/services/remote/api_service.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/modules/home/employee/controllers/shift_controller.dart';
import 'package:semesta_pos/modules/dashboard/employee/controllers/dashboard_employee_controller.dart';
import 'package:semesta_pos/modules/setting/controllers/setting_controller.dart';
import 'package:semesta_pos/core/services/sync_service.dart';
import 'package:semesta_pos/styles/app_theme.dart';
import 'package:semesta_pos/core/models/cash_flow/cash_flow_model.dart';

import 'package:semesta_pos/core/util/constans.dart';

class RecapController extends GetxController {
  final _apiService = Get.find<ApiService>();
  final _dbService = Get.find<DatabaseService>();
  final _shiftController = Get.find<ShiftController>();

  RxList<PaymentModeModel> paymentModes = <PaymentModeModel>[].obs;
  RxMap<String, int> recordedTotals = <String, int>{}.obs; // Mode ID -> Amount
  RxMap<String, int> auditedTotals = <String, int>{}.obs; // Mode ID -> Amount
  RxBool isLoading = false.obs;
  RxList<Map<String, dynamic>> shiftHistory = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> productsSoldList = <Map<String, dynamic>>[].obs;
  RxList<CashFlowModel> cashFlowItems = <CashFlowModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    initRecap();
    refreshHistory();

    // Auto-refresh reconciliation data when background sync completes.
    // This is critical because SyncService.pullRemotePayments() wipes pos_payments
    // on every "Sync Master Data". Our new query reads from transactions instead,
    // so a refresh after sync ensures the latest state is displayed without
    // requiring the user to manually press refresh.
    if (Get.isRegistered<SyncService>()) {
      ever(Get.find<SyncService>().syncStatus, (String status) {
        if (status == 'Sync Complete' ||
            status == 'Payments Updated' ||
            status == 'Orders Updated') {
          debugPrint(
              '[RecapController] Sync event "$status" — refreshing shift totals.');
          calculateShiftTotals();
        }
      });
    }
  }

  Future<void> initRecap() async {
    isLoading.value = true;
    try {
      if (Get.isRegistered<ShiftController>()) {
        await Get.find<ShiftController>().loadShiftData();
      }
      await fetchPaymentModes();
      await calculateShiftTotals();

      // Trigger background server pull for latest transaction and payment data
      if (Get.isRegistered<SyncService>()) {
        final syncService = Get.find<SyncService>();
        Future.wait([
          syncService.pullRemoteOrders(unpaidOnly: false),
          syncService.pullRemotePayments(),
          syncService.pullCreditNotes(),
        ]).then((_) {
          // Re-calculate totals using the updated database state
          calculateShiftTotals();
          refreshHistory();
        }).catchError((e) {
          debugPrint("RecapController: Background server refresh failed: $e");
        });
      }
    } catch (e) {
      debugPrint("RecapController: Error in initRecap: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPaymentModes() async {
    try {
      final response = await _apiService.getPosPaymentModes();
      if (response.responsestate == Constants.successState &&
          response.data != null) {
        if (response.data is List) {
          final List list = response.data;
          paymentModes.value = list
              .map((e) => PaymentModeModel.fromJson(e))
              .where((e) => e.active == '1')
              .toList();

          // Also sync to local for offline fallback
          for (var item in list) {
            await _dbService.insert('payment_modes', {
              'id': item['id'],
              'name': item['name'],
              'description': item['description'],
              'active': item['active'],
              'selected_by_default': item['selected_by_default'],
            });
          }
        }
      } else {
        debugPrint(
            "RecapController: API returned non-success state, falling back to local DB");
        await _loadPaymentModesFromLocal();
      }
    } catch (e) {
      debugPrint("RecapController: Error fetching payment modes: $e");
      await _loadPaymentModesFromLocal();
    }

    if (paymentModes.isEmpty) {
      debugPrint(
          "RecapController: Payment modes still empty after API and Local load");
    }
  }

  Future<void> _loadPaymentModesFromLocal() async {
    final local = await _dbService
        .query('payment_modes', where: 'active = ?', whereArgs: ['1']);
    paymentModes.value =
        local.map((e) => PaymentModeModel.fromJson(e)).toList();
  }

  Future<void> calculateShiftTotals() async {
    if (_shiftController.activeShift.value == null) {
      recordedTotals.clear();
      productsSoldList.clear();
      cashFlowItems.clear();
      return;
    }

    await _loadProductsSold();
    await _loadCashFlowForShift();

    final shift = _shiftController.activeShift.value!;
    final startTime =
        shift.startTime.toIso8601String().replaceAll('T', ' ').split('.')[0];

    try {
      // ONE ROW PER TRANSACTION — guaranteed by selecting only from transactions
      // and using a correlated subquery for paymentmethod (avoids fan-out).
      // We deliberately do NOT join payment_modes in SQL because an OR condition
      // in a LEFT JOIN can produce multiple rows per transaction (doubling amounts).
      final rows = await _dbService.rawQuery('''
        SELECT
          t.id_penjualan,
          t.bayar          AS amount,
          COALESCE(
             (SELECT paymentmethod FROM pos_payments WHERE id_pos = t.id_pos AND id_pos IS NOT NULL AND id_pos != '' LIMIT 1),
             (SELECT paymentmethod FROM pos_payments WHERE invoiceid = t.id_penjualan_remote AND invoiceid IS NOT NULL AND invoiceid != '' LIMIT 1),
             t.payment_method, 'Cash'
          ) AS pp_method
        FROM transactions t
        WHERE t.status IN (2, 3)
          AND (
            (t.tgl_bayar IS NOT NULL AND t.tgl_bayar != '' AND REPLACE(substr(t.tgl_bayar,1,19), 'T', ' ') >= ?)
            OR (
              (t.tgl_bayar IS NULL OR t.tgl_bayar = '')
              AND REPLACE(substr(t.tgl_penjualan,1,19), 'T', ' ') >= ?
            )
          )
      ''', [startTime, startTime]);

      debugPrint(
          '[RecapController] calculateShiftTotals: ${rows.length} paid tx since $startTime');

      recordedTotals.clear();
      for (var r in rows) {
        final int amount =
            double.tryParse(r['amount']?.toString() ?? '0')?.toInt() ?? 0;
        if (amount == 0) continue;

        final String ppMethod =
            (r['pp_method']?.toString() ?? 'Cash').toLowerCase();

        PaymentModeModel? matched = paymentModes.firstWhereOrNull(
          (m) => m.id == ppMethod,
        );

        matched ??= paymentModes.firstWhereOrNull(
          (m) => m.name.toLowerCase() == ppMethod,
        );

        // Find the dynamic cash mode to correctly check fallback
        final cashMode = paymentModes.firstWhereOrNull(
          (m) =>
              m.name.toLowerCase().contains('cash') ||
              m.name.toLowerCase().contains('tunai') ||
              Constants.cashPaymentModeIds.contains(m.id),
        );
        final String cashKey = cashMode?.id ?? '1';

        // Fallback to cash only if the method matches cash keywords, otherwise fall back to 'other'
        final bool isMethodCash = ppMethod.contains('cash') ||
            ppMethod.contains('tunai') ||
            Constants.cashPaymentModeIds.contains(ppMethod);
        
        final String groupKey = matched?.id ?? (isMethodCash ? cashKey : 'other');
        recordedTotals[groupKey] = (recordedTotals[groupKey] ?? 0) + amount;
      }

      // Add Opening Balance (Modal Awal) to the Cash recorded total.
      if (shift.startingBalance > 0) {
        final cashMode = paymentModes.firstWhereOrNull(
          (m) =>
              m.name.toLowerCase().contains('cash') ||
              m.name.toLowerCase().contains('tunai') ||
              Constants.cashPaymentModeIds.contains(m.id),
        );
        final cashKey = cashMode?.id ?? Constants.defaultCashPaymentModeId;
        recordedTotals[cashKey] =
            (recordedTotals[cashKey] ?? 0) + shift.startingBalance;
      }
    } catch (e) {
      debugPrint("RecapController: Error calculating shift totals: $e");
    }
  }

  Future<void> _loadProductsSold() async {
    final shift = _shiftController.activeShift.value;
    if (shift == null) return;
    final startTime = shift.startTime.toIso8601String();
    // Format time for SQLite comparison (replace 'T' with ' ')
    final startTimeSql = startTime.replaceAll('T', ' ').split('.')[0];

    final List<Map<String, dynamic>> list = [];
    try {
      final productsQuery = await _dbService.rawQuery('''
        SELECT d.product_name, SUM(d.jumlah) as qty, SUM(d.subtotal) as total
        FROM transaction_details d
        INNER JOIN transactions t ON d.id_penjualan = t.id_penjualan
        WHERE (REPLACE(substr(t.tgl_penjualan,1,19), 'T', ' ') >= ? OR REPLACE(substr(t.tgl_bayar,1,19), 'T', ' ') >= ?)
          AND t.status != 5
        GROUP BY d.id_produk, d.product_name
        ORDER BY SUM(d.subtotal) DESC
      ''', [startTimeSql, startTimeSql]);
      for (var row in productsQuery) {
        final name = row['product_name']?.toString();
        if (name != null && name.isNotEmpty) {
          list.add({
            'name': name,
            'qty': (row['qty'] as num?)?.toInt() ?? 0,
            'total': (row['total'] as num?)?.toInt() ?? 0,
          });
        }
      }
      productsSoldList.value = list;
    } catch (e) {
      debugPrint("Error querying products sold: $e");
    }
  }

  Future<void> _loadCashFlowForShift() async {
    final shift = _shiftController.activeShift.value;
    if (shift == null) {
      cashFlowItems.clear();
      return;
    }
    try {
      final shiftId = shift.idShift ?? 0;
      if (shiftId > 0) {
        // Load by shift ID
        final rows = await _dbService.getCashFlowByShift(shiftId);
        cashFlowItems.value =
            rows.map((r) => CashFlowModel.fromMap(r)).toList();
      } else {
        // Fallback: load by shift start time if no shift ID (e.g. active shift)
        final startTime = shift.startTime.toIso8601String();
        final rows = await _dbService.getCashFlowSince(startTime);
        cashFlowItems.value =
            rows.map((r) => CashFlowModel.fromMap(r)).toList();
      }
    } catch (e) {
      debugPrint('RecapController: Error loading cash flow: $e');
    }
  }

  void updateAuditAmount(String modeId, int amount) {
    auditedTotals[modeId] = amount;
  }

  int getRecordedAmount(String modeId) => recordedTotals[modeId] ?? 0;
  int getAuditedAmount(String modeId) => auditedTotals[modeId] ?? 0;
  int getDiffAmount(String modeId) =>
      getAuditedAmount(modeId) - getRecordedAmount(modeId);

  String? _getCashModeId() {
    final cashMode = paymentModes.firstWhereOrNull(
      (m) =>
          m.name.toLowerCase().contains('cash') ||
          m.name.toLowerCase().contains('tunai') ||
          Constants.cashPaymentModeIds.contains(m.id),
    );
    return cashMode?.id;
  }

  int _getCashRecordedTotal() {
    final cashModeId = _getCashModeId();
    return cashModeId == null ? 0 : getRecordedAmount(cashModeId);
  }

  int _getCashAuditedTotal() {
    final cashModeId = _getCashModeId();
    if (cashModeId == null) return getTotalAudited();
    return auditedTotals[cashModeId] ?? 0;
  }

  int getTotalRecorded() => recordedTotals.values.fold(0, (a, b) => a + b);
  int getTotalAudited() => auditedTotals.values.fold(0, (a, b) => a + b);
  int getTotalDiff() => getTotalAudited() - getTotalRecorded();

  Future<void> refreshHistory() async {
    final data = await _dbService.query('shift_sessions',
        orderBy: "CASE WHEN end_time IS NOT NULL AND end_time != '' AND end_time != 'null' THEN end_time ELSE start_time END DESC",
        limit: 30);
    shiftHistory.value = data;
  }

  Future<void> confirmCloseShift(BuildContext context) async {
    if (_shiftController.activeShift.value == null) {
      Get.snackbar('Error', 'No active shift found');
      return;
    }

    // 1. Confirm Dialog
    bool? confirm = await Get.dialog<bool>(
      AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text('Close Shift?'),
        content: const Text(
            'Are you sure you want to close this shift? The reconciliation recap will be permanently saved along with the PIC identity.'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
            ),
            child: const Text('YES, CLOSE SHIFT',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Prepare Detailed Reconciliation Data
    final startTime = _shiftController.activeShift.value!.startTime
        .toIso8601String()
        .replaceAll('T', ' ')
        .split('.')[0];

    // 2a. Payment Modes
    final List<Map<String, dynamic>> paymentModesList = [];
    for (var mode in paymentModes) {
      final modeId = mode.id;
      if (modeId.isNotEmpty) {
        paymentModesList.add({
          'name': mode.name,
          'recorded': getRecordedAmount(modeId),
          'audited': getAuditedAmount(modeId),
          'diff': getDiffAmount(modeId),
        });
      }
    }

    // 2b. Order Types
    final List<Map<String, dynamic>> orderTypesList = [];
    try {
      final orderTypesQuery = await _dbService.rawQuery('''
        SELECT order_type, SUM(bayar) as total
        FROM transactions
        WHERE (REPLACE(substr(tgl_penjualan,1,19), 'T', ' ') >= ? OR REPLACE(substr(tgl_bayar,1,19), 'T', ' ') >= ?) AND status != 5
        GROUP BY order_type
      ''', [startTime, startTime]);
      for (var row in orderTypesQuery) {
        orderTypesList.add({
          'name': row['order_type']?.toString().isEmpty == true
              ? 'Unknown'
              : row['order_type'],
          'total': (row['total'] as num?)?.toInt() ?? 0,
        });
      }
    } catch (e) {
      debugPrint("Error querying order types: $e");
    }

    // 2c. Products Sold (Updated to include unit price)
    // Already fetched in _loadProductsSold() but we'll enrich it or ensure it has what we need
    final List<Map<String, dynamic>> enrichedProducts = [];
    for (var p in productsSoldList) {
      final qty = p['qty'] as int;
      final total = p['total'] as int;
      final price = qty > 0 ? (total / qty).round() : 0;
      enrichedProducts.add({
        ...p,
        'price': price,
      });
    }

    // 2d. Calculate Discounts
    int totalProductDiscount = 0;
    int totalTransactionDiscount = 0;
    try {
      final productDiscQuery = await _dbService.rawQuery('''
        SELECT SUM(d.discountTotal) as total
        FROM transaction_details d
        INNER JOIN transactions t ON d.id_penjualan = t.id_penjualan
        WHERE (REPLACE(substr(t.tgl_penjualan,1,19), 'T', ' ') >= ? OR REPLACE(substr(t.tgl_bayar,1,19), 'T', ' ') >= ?)
          AND t.status IN (2, 3)
      ''', [startTime, startTime]);
      totalProductDiscount =
          (productDiscQuery.first['total'] as num?)?.toInt() ?? 0;

      final transDiscQuery = await _dbService.rawQuery('''
        SELECT SUM(manual_discount_value) as total
        FROM transactions
        WHERE (REPLACE(substr(tgl_penjualan,1,19), 'T', ' ') >= ? OR REPLACE(substr(tgl_bayar,1,19), 'T', ' ') >= ?)
          AND status IN (2, 3)
      ''', [startTime, startTime]);
      totalTransactionDiscount =
          (transDiscQuery.first['total'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint("Error querying discounts: $e");
    }

    // 2e. Calculate Member Additions
    int memberAdditions = 0;
    try {
      // Members added during this shift locally will have is_synced = 0
      final memberQuery = await _dbService.rawQuery('''
        SELECT COUNT(*) as count FROM members WHERE is_synced = 0
      ''');
      memberAdditions = Sqflite.firstIntValue(memberQuery) ?? 0;
    } catch (e) {
      debugPrint("Error querying member additions: $e");
    }

    // 2f. Credit Notes (Refunds)
    final List<Map<String, dynamic>> creditNotesList = [];
    int totalCreditNotes = 0;
    try {
      final cnQuery = await _dbService.rawQuery('''
        SELECT formatted_number, total, reference_no
        FROM pos_credit_notes
        WHERE date >= ? OR datecreated >= ?
      ''', [startTime, startTime]);
      for (var row in cnQuery) {
        final amount = (row['total'] as num?)?.toInt() ?? 0;
        totalCreditNotes += amount;
        creditNotesList.add({
          'number': row['formatted_number'],
          'total': amount,
          'ref': row['reference_no'],
        });
      }
    } catch (e) {
      debugPrint("Error querying credit notes: $e");
    }

    // 3. Build the full transactions array
    final expectedCash = _getCashRecordedTotal();
    final actualCash = _getCashAuditedTotal();
    final transactionsData = [
      {
        'payment_modes': paymentModesList,
        'order_types': orderTypesList,
        'products_sold': enrichedProducts,
        'discounts': {
          'product': totalProductDiscount,
          'transaction': totalTransactionDiscount,
        },
        'members': {
          'additions': memberAdditions,
        },
        'credit_notes': {
          'list': creditNotesList,
          'total': totalCreditNotes,
        },
        'summary': {
          'expected_cash': expectedCash,
          'actual_cash': actualCash,
          'difference': actualCash - expectedCash,
          'status': 1
        }
      }
    ];

    // 4. Close Shift through ShiftController
    final result = await _shiftController.closeShift(
      actualCash,
      'Closed from Reconciliation View',
      reconciliationData: jsonEncode(transactionsData),
    );

    if (result != null) {
      // 3.5 Sync Shift Logs to Server is automatically handled by SyncService.pushShiftLogs()
      // triggered inside ShiftController.closeShift().

      // 4. Reset local audit state and refresh history
      auditedTotals.clear();
      recordedTotals.clear();
      await refreshHistory();

      // 5. Redirect to Dashboard index
      if (Get.isRegistered<DashboardEmployeeController>()) {
        Get.find<DashboardEmployeeController>().stateSelectedIndex.value = 0;
      }

      // 6. Show Beautiful Print Notification
      Get.dialog(
        Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(Get.context!),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(CupertinoIcons.check_mark_circled_solid,
                      color: Colors.green, size: 48.sp),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Shift Closed Successfully',
                  style: TextStyle(
                    fontFamily: AppTheme.fontBold,
                    fontSize: 18.sp,
                    color: AppTheme.textColor(Get.context!),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'The shift has been closed and reconciliation data is saved. Would you like to print the Z-Report for your records?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontMedium,
                    fontSize: 14.sp,
                    color: AppTheme.secondaryTextColor(Get.context!),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                          side: BorderSide(
                              color: AppTheme.borderColor(Get.context!)),
                        ),
                        child: Text(
                          'LATER',
                          style: TextStyle(
                            fontFamily: AppTheme.fontBold,
                            fontSize: 14.sp,
                            color: AppTheme.textColor(Get.context!),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          if (Get.isRegistered<SettingController>()) {
                            Get.find<SettingController>()
                                .printZReport(result['shift'], result['rekap']);
                          }
                        },
                        icon: Icon(CupertinoIcons.printer_fill,
                            size: 18.sp, color: Colors.white),
                        label: Text(
                          'PRINT NOW',
                          style: TextStyle(
                            fontFamily: AppTheme.fontBold,
                            fontSize: 14.sp,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Future<void> confirmEndOfDay(BuildContext context) async {
    // 1. Confirm Dialog
    bool? confirm = await Get.dialog<bool>(
      AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text('End of Day (Z-Report)?'),
        content: const Text(
            'Are you sure you want to close the store for today? This will calculate all shifts from 00:00 to 23:59, print the full Z-Report, and close the current shift without carrying over the balance to tomorrow.'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
            ),
            child: const Text('YES, END OF DAY',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Call ShiftController's end of day method
    final result = await _shiftController.executeEndOfDay(
        _getCashAuditedTotal(), 'End of Day closed from Reconciliation View');

    if (result != null) {
      // Reset local audit state and refresh history
      auditedTotals.clear();
      recordedTotals.clear();
      await refreshHistory();

      // Redirect to Dashboard index
      if (Get.isRegistered<DashboardEmployeeController>()) {
        Get.find<DashboardEmployeeController>().stateSelectedIndex.value = 0;
      }

      // Show Beautiful Print Notification
      Get.dialog(
        Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(Get.context!),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(CupertinoIcons.check_mark_circled_solid,
                      color: Colors.deepPurple, size: 48.sp),
                ),
                SizedBox(height: 20.h),
                Text(
                  'End of Day Successful',
                  style: TextStyle(
                    fontFamily: AppTheme.fontBold,
                    fontSize: 18.sp,
                    color: AppTheme.textColor(Get.context!),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'The store has been closed for today. Would you like to print the full Z-Report?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontMedium,
                    fontSize: 14.sp,
                    color: AppTheme.secondaryTextColor(Get.context!),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                          side: BorderSide(
                              color: AppTheme.borderColor(Get.context!)),
                        ),
                        child: Text(
                          'LATER',
                          style: TextStyle(
                            fontFamily: AppTheme.fontBold,
                            fontSize: 14.sp,
                            color: AppTheme.textColor(Get.context!),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          if (Get.isRegistered<SettingController>()) {
                            Get.find<SettingController>()
                                .printEndOfDayReport(result['eodData']);
                          }
                        },
                        icon: Icon(CupertinoIcons.printer_fill,
                            size: 18.sp, color: Colors.white),
                        label: Text(
                          'PRINT NOW',
                          style: TextStyle(
                            fontFamily: AppTheme.fontBold,
                            fontSize: 14.sp,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
