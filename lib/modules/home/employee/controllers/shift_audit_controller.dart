import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/models/payment/payment_mode_model.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/core/services/remote/api_service.dart';
import 'package:semesta_pos/modules/dashboard/employee/controllers/dashboard_employee_controller.dart';
import 'package:semesta_pos/modules/home/employee/controllers/shift_controller.dart';
import 'package:semesta_pos/modules/setting/controllers/setting_controller.dart';
import 'package:semesta_pos/core/services/sync_service.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class ShiftAuditController extends GetxController {
  final _dbService = Get.find<DatabaseService>();
  final _apiService = Get.find<ApiService>();
  final _shiftController = Get.find<ShiftController>();

  // State
  RxList<PaymentModeModel> paymentModes = <PaymentModeModel>[].obs;
  RxMap<String, int> openingAmounts = <String, int>{}.obs; // For open shift
  RxMap<String, int> auditAmounts = <String, int>{}.obs;   // For close shift
  RxMap<String, int> recordedAmounts = <String, int>{}.obs; // From DB
  RxBool isLoading = false.obs;
  RxBool isSubmitting = false.obs;

  final noteController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _initialize();
    
    // Reactively reload if background sync finishes while this page is open
    if (Get.isRegistered<SyncService>()) {
      ever(Get.find<SyncService>().syncStatus, (String status) {
        if (status == "Sync Complete" || status.contains("Updated")) {
          if (paymentModes.isEmpty) {
             _loadPaymentModes();
          }
        }
      });
    }
  }

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }

  Future<void> _initialize() async {
    isLoading.value = true;
    try {
      await _loadPaymentModes();
      await _loadRecordedAmounts();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadPaymentModes() async {
    try {
      final response = await _apiService.getPosPaymentModes();
      // NOTE: The API returns {"status": true, "data": [...]}
      // ResponseApiModel.fromJson maps 'data' key correctly, but 'responsestate'
      // is always null because the API uses 'status' not 'responsestate'.
      // So we check response.data directly.
      final rawData = response.data;
      List? list;
      if (rawData is List) {
        list = rawData;
      } else if (rawData is Map && rawData.containsKey('data') && rawData['data'] is List) {
        list = rawData['data'] as List;
      }

      if (list != null && list.isNotEmpty) {
        // Sync to local DB & build list
        for (var item in list) {
          if (item is Map<String, dynamic>) {
            await _dbService.insert('payment_modes', {
              'id': item['id'],
              'name': item['name'],
              'description': item['description'] ?? '',
              'active': item['active'],
              'selected_by_default': item['selected_by_default'] ?? '0',
            });
          }
        }
        paymentModes.value = list
            .whereType<Map<String, dynamic>>()
            .map((e) => PaymentModeModel.fromJson(e))
            .where((e) => e.active == '1')
            .toList();
        debugPrint('ShiftAuditController: Loaded ${paymentModes.length} payment modes from API.');
        return;
      }
    } catch (e) {
      debugPrint('ShiftAuditController: API failed, falling back to local: $e');
    }
    // Fallback to local DB
    final local = await _dbService
        .query('payment_modes', where: 'active = ?', whereArgs: ['1']);
    paymentModes.value =
        local.map((e) => PaymentModeModel.fromJson(e)).toList();
    debugPrint('ShiftAuditController: Loaded ${paymentModes.length} payment modes from local DB.');
  }

  Future<void> _loadRecordedAmounts() async {
    final shift = _shiftController.activeShift.value;
    if (shift == null) return;

    final startTime = shift.startTime.toIso8601String().replaceAll('T', ' ').split('.')[0];

    try {
      // Robust query from RecapController that reads from transactions table
      // and falls back to pos_payments for method mapping.
      final rows = await _dbService.rawQuery('''
        SELECT
          t.id_penjualan,
          t.bayar          AS amount,
          t.payment_method AS local_method,
          (SELECT paymentmethod
             FROM pos_payments
            WHERE id_pos = t.id_pos
            LIMIT 1)       AS pp_method
        FROM transactions t
        WHERE t.status IN (2, 3)
          AND (
            (t.tgl_bayar IS NOT NULL AND t.tgl_bayar != "" AND substr(t.tgl_bayar,1,19) >= ?)
            OR (
              (t.tgl_bayar IS NULL OR t.tgl_bayar = "")
              AND substr(t.tgl_penjualan,1,19) >= ?
            )
          )
      ''', [startTime, startTime]);

      debugPrint('ShiftAuditController: Found ${rows.length} transactions since $startTime');

      recordedAmounts.clear();
      for (var r in rows) {
        final int amount = double.tryParse(r['amount']?.toString() ?? '0')?.toInt() ?? 0;
        if (amount == 0) continue;

        final String ppMethod = r['pp_method']?.toString() ?? '';
        final String localMethod = (r['local_method']?.toString() ?? '').toLowerCase();

        PaymentModeModel? matched;

        // 1. Try matching by numeric ID from pos_payments
        if (ppMethod.isNotEmpty) {
          matched = paymentModes.firstWhereOrNull((m) => m.id == ppMethod);
        }

        // 2. Fall back: match by name from transactions.payment_method
        if (matched == null && localMethod.isNotEmpty) {
          matched = paymentModes.firstWhereOrNull(
            (m) => m.name.toLowerCase() == localMethod,
          );
        }

        final String key = matched?.id ?? (ppMethod.isNotEmpty ? ppMethod : (localMethod.isNotEmpty ? localMethod : 'cash'));
        
        if (recordedAmounts.containsKey(key)) {
          recordedAmounts[key] = recordedAmounts[key]! + amount;
        } else {
          recordedAmounts[key] = amount;
        }
      }

      // Add Opening Balance (Modal Awal) to the Cash recorded total.
      final cashMode = paymentModes.firstWhereOrNull(
        (m) => m.name.toLowerCase().contains('cash') ||
               m.name.toLowerCase().contains('tunai') ||
               m.id == '1',
      );
      if (cashMode != null && shift.startingBalance > 0) {
        final cashKey = cashMode.id;
        if (recordedAmounts.containsKey(cashKey)) {
          recordedAmounts[cashKey] = recordedAmounts[cashKey]! + shift.startingBalance;
        } else {
          recordedAmounts[cashKey] = shift.startingBalance;
        }
      }
    } catch (e) {
      debugPrint('ShiftAuditController: Error loading recorded amounts: $e');
    }
  }

  void setOpeningAmount(String modeId, int amount) {
    openingAmounts[modeId] = amount;
  }

  void setAuditAmount(String modeId, int amount) {
    auditAmounts[modeId] = amount;
  }

  int get totalOpening =>
      openingAmounts.values.fold(0, (a, b) => a + b);

  int get totalAudited =>
      auditAmounts.values.fold(0, (a, b) => a + b);

  int get totalRecorded =>
      recordedAmounts.values.fold(0, (a, b) => a + b);

  /// Called when user taps "Buka Shift" — uses totalOpening as starting balance.
  Future<void> confirmOpenShift(String shiftName) async {
    if (isSubmitting.value) return;
    
    debugPrint('ShiftAuditController: Attempting to open shift: $shiftName');
    isSubmitting.value = true;
    try {
      final totalBalance = totalOpening;
      debugPrint('ShiftAuditController: Total opening balance: $totalBalance');
      
      await _shiftController.openShift(shiftName, totalBalance);
      Get.back(); // Closes audit page
      
      Get.snackbar(
        'Shift Started',
        'Good luck with your $shiftName!',
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stack) {
      debugPrint('ShiftAuditController: Error opening shift: $e');
      debugPrint(stack.toString());
      Get.snackbar(
        'Error',
        'Failed to open shift: ${e.toString()}',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> confirmCloseShift() async {
    if (isSubmitting.value) return;
    
    isSubmitting.value = true;
    try {
      final cashModeId = _getCashModeId();
      final actualCash = cashModeId != null
          ? (auditAmounts[cashModeId] ?? totalAudited)
          : totalAudited;

      debugPrint('ShiftAuditController: Closing shift with actual cash: $actualCash');
      final result = await _shiftController.closeShift(
          actualCash, noteController.text);

      Get.back(); // Pop audit page

      if (Get.isRegistered<DashboardEmployeeController>()) {
        Get.find<DashboardEmployeeController>().stateSelectedIndex.value = 0;
      }

      if (result != null) {
        _showZReportDialog(result);
      }
    } catch (e, stack) {
      debugPrint('ShiftAuditController: Error closing shift: $e');
      debugPrint(stack.toString());
      Get.snackbar(
        'Error',
        'Failed to close shift: ${e.toString()}',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  void _showZReportDialog(Map<String, dynamic> result) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
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
                        side: BorderSide(color: AppTheme.borderColor(Get.context!)),
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
                      icon: Icon(CupertinoIcons.printer_fill, size: 18.sp, color: Colors.white),
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

  /// Find the cash payment mode ID heuristically.
  String? _getCashModeId() {
    for (final m in paymentModes) {
      if (m.name.toLowerCase().contains('cash') ||
          m.name.toLowerCase().contains('tunai')) {
        return m.id;
      }
    }
    return null;
  }
}
