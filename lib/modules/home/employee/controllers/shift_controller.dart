import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/models/shift/shift_model.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/core/services/remote/api_service.dart';
import 'package:semesta_pos/core/services/sync_service.dart';
import 'package:semesta_pos/core/services/user_service.dart';

class ShiftController extends GetxController {
  DatabaseService get _dbService => Get.find<DatabaseService>();

  final _userService = Get.find<UserService>();
  final _apiService = Get.find<ApiService>();

  Rxn<ShiftSessionModel> activeShift = Rxn<ShiftSessionModel>();
  RxList<ShiftConfig> shiftConfigs = <ShiftConfig>[].obs;
  RxBool isLoading = false.obs;
  RxBool isDataLoaded = false.obs;

  /// Owner-only flag: set to true when owner chooses to dismiss the
  /// "open shift" popup and trial the POS without an active shift.
  /// Resets automatically when a shift is actually opened.
  RxBool isOwnerTrialMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadShiftData();
  }

  Future<void> loadShiftData() async {
    isLoading.value = true;
    try {
      // 1. Load configs from pos_options
      final configResult = await _dbService.rawQuery(
          "SELECT option_value FROM pos_options WHERE option_name = 'pos_shift_config'");
      if (configResult.isNotEmpty) {
        final rawValue = configResult.first['option_value']?.toString() ?? '';
        if (rawValue.isNotEmpty && rawValue != 'null') {
          final List de = jsonDecode(rawValue);
          shiftConfigs.value = de.map((e) => ShiftConfig.fromJson(e)).toList();
        } else {
          _setDefaultConfigs();
        }
      } else {
        _setDefaultConfigs();
      }

      // 2. Load active session
      final sessionResult = await _dbService.rawQuery(
          "SELECT option_value FROM pos_options WHERE option_name = 'pos_active_session'");
      if (sessionResult.isNotEmpty) {
        final rawSession =
            sessionResult.first['option_value']?.toString() ?? '';
        if (rawSession.isNotEmpty && rawSession != 'null') {
          try {
            final decoded = jsonDecode(rawSession);
            activeShift.value = ShiftSessionModel.fromJson(decoded);
            debugPrint('[ShiftController] loadShiftData: Loaded activeShift='
                '${activeShift.value?.shiftName}, '
                'startTime=${activeShift.value?.startTime.toIso8601String()}, '
                'startingBalance=${activeShift.value?.startingBalance}');
          } catch (e) {
            debugPrint(
                "ShiftController: FormatException on pos_active_session, clearing invalid data. $e");
            await _dbService.rawQuery(
                "DELETE FROM pos_options WHERE option_name = 'pos_active_session'");
          }
        }
      }
    } catch (e) {
      debugPrint("ShiftController Error: $e");
    } finally {
      isLoading.value = false;
      isDataLoaded.value = true;
    }
  }

  Future<void> saveShiftConfig() async {
    await _dbService.insert('pos_options', {
      'option_name': 'pos_shift_config',
      'option_value': jsonEncode(shiftConfigs.map((e) => e.toJson()).toList()),
    });
    // Ensure active shift selection can refresh
    shiftConfigs.refresh();
  }

  void addShiftConfig(String name, String staff) {
    shiftConfigs.add(ShiftConfig(name: name, staffName: staff, isActive: true));
    saveShiftConfig();
  }

  void deleteShiftConfig(int index) {
    if (index >= 0 && index < shiftConfigs.length) {
      shiftConfigs.removeAt(index);
      saveShiftConfig();
    }
  }

  void toggleShiftStatus(int index) {
    if (index >= 0 && index < shiftConfigs.length) {
      shiftConfigs[index].isActive = !shiftConfigs[index].isActive;
      saveShiftConfig();
    }
  }

  void updateShiftConfig(int index, String name, String staff) {
    if (index >= 0 && index < shiftConfigs.length) {
      shiftConfigs[index] = ShiftConfig(
          name: name, staffName: staff, isActive: shiftConfigs[index].isActive);
      saveShiftConfig();
    }
  }

  Future<Map<String, dynamic>?> checkContinuedShift() async {
    final result = await _dbService.rawQuery(
        "SELECT option_value FROM pos_options WHERE option_name = 'pos_continued_shift_data'");
    if (result.isNotEmpty) {
      final rawValue = result.first['option_value']?.toString() ?? '';
      if (rawValue.isNotEmpty && rawValue != 'null') {
        return jsonDecode(rawValue);
      }
    }
    return null;
  }

  Future<void> openContinuedShift(String name, Map<String, dynamic> continuedData) async {
    debugPrint('ShiftController: openContinuedShift called with name=$name');
    final startingBalance = continuedData['carried_over_balance'] as int? ?? 0;
    final originalStartTimeStr = continuedData['original_start_time'] as String;
    
    final newShift = ShiftSessionModel(
      shiftName: name,
      userId: _userService.getUserName(),
      startTime: DateTime.parse(originalStartTimeStr),
      startingBalance: startingBalance,
      status: 0,
    );

    try {
      final String shiftJson = jsonEncode(newShift.toJson());
      await _dbService.insert('pos_options', {
        'option_name': 'pos_active_session',
        'option_value': shiftJson,
      });
      
      await _dbService.rawQuery(
        "DELETE FROM pos_options WHERE option_name = 'pos_continued_shift_data'");
      
      // Push active session to server
      if (Get.isRegistered<SyncService>()) {
        Get.find<SyncService>().enqueueCommand(
          method: 'PUT',
          endpoint: '/api/pos_options',
          body: {'pos_active_session': shiftJson},
          localId: 'pos_active_session_open',
        );
      } else {
        await _apiService.updatePosOptions({
          'pos_active_session': shiftJson
        });
      }
    } catch (e) {
      debugPrint('ShiftController: Failed to open continued shift: $e');
    }

    activeShift.value = newShift;
    isOwnerTrialMode.value = false;
  }

  Future<void> openShift(String name, int startingBalance) async {
    debugPrint('ShiftController: openShift called with name=$name, startingBalance=$startingBalance');
    final newShift = ShiftSessionModel(
      shiftName: name,
      userId: _userService.getUserName(),
      startTime: DateTime.now(),
      startingBalance: startingBalance,
      status: 0,
    );

    try {
      final String shiftJson = jsonEncode(newShift.toJson());
      debugPrint('ShiftController: Inserting pos_active_session: $shiftJson');
      await _dbService.insert('pos_options', {
        'option_name': 'pos_active_session',
        'option_value': shiftJson,
      });
      debugPrint('ShiftController: Successfully inserted pos_active_session');
      
      // Push active session to server so other devices can detect and join it
      try {
        if (Get.isRegistered<SyncService>()) {
          Get.find<SyncService>().enqueueCommand(
            method: 'PUT',
            endpoint: '/api/pos_options',
            body: {'pos_active_session': shiftJson},
            localId: 'pos_active_session_open',
          );
          debugPrint('ShiftController: Successfully queued active session update to server');
        } else {
          await _apiService.updatePosOptions({
            'pos_active_session': shiftJson
          });
          debugPrint('ShiftController: Successfully pushed active session to server');
        }
      } catch (e) {
        debugPrint('ShiftController: Failed to push active session to server: $e');
      }

    } catch (e) {
      debugPrint('ShiftController: Failed to insert pos_active_session: $e');
    }

    activeShift.value = newShift;
    // Reset trial mode — shift is now open
    isOwnerTrialMode.value = false;
  }

  Future<Map<String, dynamic>> generateFullReconciliationData() async {
    final startTime = activeShift.value!.startTime.toIso8601String().replaceAll('T', ' ').split('.')[0];
    
    // 1. Payment Modes Summary
    final List<Map<String, dynamic>> paymentModesList = [];
    final pms = await calculateRecap(); 
    
    // We fetch payment modes to ensure we have names for IDs
    final List<Map<String, dynamic>> modeMetadata = await _dbService.query('payment_modes', where: 'active = ?', whereArgs: ['1']);
    
    // Use the same robust query as calculateRecap and RecapController
    final rows = await _dbService.rawQuery('''
      SELECT
        t.bayar          AS amount,
        t.payment_method AS local_method,
        (SELECT paymentmethod
           FROM pos_payments
          WHERE id_pos = t.id_pos
          LIMIT 1)       AS pp_method
      FROM transactions t
      WHERE t.status IN (2, 3)
        AND (
          (t.tgl_bayar IS NOT NULL AND t.tgl_bayar != "" AND REPLACE(substr(t.tgl_bayar,1,19), 'T', ' ') >= ?)
          OR (
            (t.tgl_bayar IS NULL OR t.tgl_bayar = "")
            AND REPLACE(substr(t.tgl_penjualan,1,19), 'T', ' ') >= ?
          )
        )
    ''', [startTime, startTime]);

    final Map<String, int> totals = {};
    for (var r in rows) {
      final int amount = double.tryParse(r['amount']?.toString() ?? '0')?.toInt() ?? 0;
      final String ppMethod = r['pp_method']?.toString() ?? '';
      final String localMethod = (r['local_method']?.toString() ?? '').toLowerCase();
      
      String? matchedId;
      String? matchedName;

      // 1. Try matching by numeric ID from pos_payments
      if (ppMethod.isNotEmpty) {
        final m = modeMetadata.firstWhereOrNull((m) => m['id']?.toString() == ppMethod);
        if (m != null) {
          matchedId = m['id']?.toString();
          matchedName = m['name']?.toString();
        }
      }

      // 2. Fall back: match by name from transactions.payment_method
      if (matchedId == null && localMethod.isNotEmpty) {
        final m = modeMetadata.firstWhereOrNull((m) => (m['name']?.toString() ?? '').toLowerCase() == localMethod);
        if (m != null) {
          matchedId = m['id']?.toString();
          matchedName = m['name']?.toString();
        }
      }

      final String key = matchedId ?? (ppMethod.isNotEmpty ? ppMethod : (localMethod.isNotEmpty ? localMethod : '1'));
      final String name = matchedName ?? (localMethod.isNotEmpty ? r['local_method'] : (ppMethod == '1' ? 'Cash' : 'Other'));
      
      totals[key] = (totals[key] ?? 0) + amount;
      
      // Ensure the mode is in the list with its name
      if (!paymentModesList.any((m) => m['id'] == key)) {
        paymentModesList.add({
          'id': key,
          'name': name,
          'recorded': 0,
        });
      }
    }

    // Update recorded amounts in the final list
    for (var m in paymentModesList) {
      m['recorded'] = totals[m['id']] ?? 0;
    }

    // Add Opening Balance to Cash
    if (activeShift.value!.startingBalance > 0) {
      final cashMode = paymentModesList.firstWhereOrNull((m) => m['name'].toString().toLowerCase().contains('cash') || m['name'].toString().toLowerCase().contains('tunai') || m['id'] == '1');
      if (cashMode != null) {
        cashMode['recorded'] = (cashMode['recorded'] as int) + activeShift.value!.startingBalance;
      } else {
        paymentModesList.add({
          'id': '1',
          'name': 'Cash',
          'recorded': activeShift.value!.startingBalance,
        });
      }
    }

    // 2. Products Sold
    final List<Map<String, dynamic>> productsList = [];
    try {
      final rows = await _dbService.rawQuery('''
        SELECT 
          d.product_name as name, 
          SUM(d.jumlah) as qty, 
          SUM(d.subtotal) as total
        FROM transaction_details d
        JOIN transactions t ON d.id_penjualan = t.id_penjualan
        WHERE (REPLACE(substr(t.tgl_penjualan,1,19), 'T', ' ') >= ? OR REPLACE(substr(t.tgl_bayar,1,19), 'T', ' ') >= ?) AND t.status != 5
        GROUP BY d.id_produk, d.product_name
      ''', [startTime, startTime]);
      
      for (var row in rows) {
        final qty = (row['qty'] as num?)?.toInt() ?? 0;
        final total = (row['total'] as num?)?.toInt() ?? 0;
        productsList.add({
          'name': row['name'],
          'qty': qty,
          'total': total,
          'price': qty > 0 ? (total / qty).round() : 0,
        });
      }
    } catch(e) { debugPrint("ShiftController: Error generating products sold: $e"); }

    // 3. Discounts
    int productDiscount = 0;
    int transactionDiscount = 0;
    try {
      final pDisc = await _dbService.rawQuery('''
        SELECT SUM(d.discountTotal) as total FROM transaction_details d
        JOIN transactions t ON d.id_penjualan = t.id_penjualan
        WHERE (REPLACE(substr(t.tgl_penjualan,1,19), 'T', ' ') >= ? OR REPLACE(substr(t.tgl_bayar,1,19), 'T', ' ') >= ?) AND t.status IN (2, 3)
      ''', [startTime, startTime]);
      productDiscount = (pDisc.first['total'] as num?)?.toInt() ?? 0;

      final tDisc = await _dbService.rawQuery('''
        SELECT SUM(manual_discount_value) as total FROM transactions
        WHERE (REPLACE(substr(tgl_penjualan,1,19), 'T', ' ') >= ? OR REPLACE(substr(tgl_bayar,1,19), 'T', ' ') >= ?) AND status IN (2, 3)
      ''', [startTime, startTime]);
      transactionDiscount = (tDisc.first['total'] as num?)?.toInt() ?? 0;
    } catch(_) {}

    // 4. Order Types
    final List<Map<String, dynamic>> orderTypesList = [];
    try {
      final otRows = await _dbService.rawQuery('''
        SELECT order_type, SUM(bayar) as total
        FROM transactions
        WHERE (REPLACE(substr(tgl_penjualan,1,19), 'T', ' ') >= ? OR REPLACE(substr(tgl_bayar,1,19), 'T', ' ') >= ?) AND t.status IN (2, 3)
        GROUP BY order_type
      ''', [startTime, startTime]);
      for (var r in otRows) {
        orderTypesList.add({
          'name': r['order_type'] ?? 'Unknown',
          'total': (r['total'] as num?)?.toInt() ?? 0,
        });
      }
    } catch(_) {}

    // 5. Members & Credit Notes
    int memberAdditions = 0;
    try {
      final mCount = await _dbService.rawQuery('SELECT COUNT(*) as count FROM members WHERE is_synced = 0');
      memberAdditions = (mCount.first['count'] as num?)?.toInt() ?? 0;
    } catch(_) {}

    final List<Map<String, dynamic>> cnList = [];
    int cnTotal = 0;
    try {
      final cnRows = await _dbService.rawQuery('SELECT formatted_number, total FROM pos_credit_notes WHERE datecreated >= ?', [startTime]);
      for (var r in cnRows) {
        final amt = (r['total'] as num?)?.toInt() ?? 0;
        cnTotal += amt;
        cnList.add({'number': r['formatted_number'], 'total': amt});
      }
    } catch(_) {}

    // 6. Voided Orders
    int voidCount = 0;
    int voidTotal = 0;
    try {
      final vRows = await _dbService.rawQuery('''
        SELECT COUNT(*) as count, SUM(total_harga) as total FROM transactions
        WHERE (REPLACE(substr(tgl_penjualan,1,19), 'T', ' ') >= ? OR REPLACE(substr(tgl_bayar,1,19), 'T', ' ') >= ?) AND status = 5
      ''', [startTime, startTime]);
      voidCount = (vRows.first['count'] as num?)?.toInt() ?? 0;
      voidTotal = (vRows.first['total'] as num?)?.toInt() ?? 0;
    } catch(_) {}

    return {
      'shift_name': activeShift.value!.shiftName,
      'staff': activeShift.value!.userId,
      'payment_modes': paymentModesList,
      'order_types': orderTypesList,
      'products_sold': productsList,
      'discounts': {
        'product': productDiscount,
        'transaction': transactionDiscount,
      },
      'members': {
        'additions': memberAdditions,
      },
      'credit_notes': {
        'list': cnList,
        'total': cnTotal,
      },
      'voids': {
        'count': voidCount,
        'total': voidTotal,
      },
      'summary': {
        'expected_cash': activeShift.value!.startingBalance + (pms['cash'] ?? 0),
        'actual_cash': 0,
        'difference': 0,
        'status': 0
      }
    };
  }

  Future<Map<String, dynamic>?> closeShift(int actualCash, String note,
      {String? reconciliationData, bool isSwitchPerson = false}) async {
    if (activeShift.value == null) return null;

    final originalStartTime = activeShift.value!.startTime;

    // Generate full reconciliation data if not provided (e.g. from POS menu close)
    String? finalData = reconciliationData;
    if (finalData == null) {
      try {
        final fullData = await generateFullReconciliationData();
        finalData = jsonEncode([fullData]);
      } catch (e) {
        debugPrint("ShiftController: Failed to auto-generate reconciliation data: $e");
      }
    }

    final rekap = await calculateRecap();
    final startingBal = activeShift.value!.startingBalance;
    final closedShift = ShiftSessionModel(
      idShift: activeShift.value!.idShift,
      shiftName: activeShift.value!.shiftName,
      userId: activeShift.value!.userId,
      startTime: originalStartTime,
      endTime: DateTime.now(),
      startingBalance: startingBal,
      closingBalance: actualCash,
      // System Cash = opening float + cash collected during shift
      totalCashExpected: startingBal + rekap['cash']!,
      totalCashActual: actualCash,
      totalNonCash: rekap['nonCash']!,
      status: 1,
      note: note,
      reconciliationData: finalData,
    );

    // 1. Save to history table
    await _dbService.insert('shift_sessions', closedShift.toJson());

    // 2. Clear active session locally
    await _dbService.rawQuery(
        "DELETE FROM pos_options WHERE option_name = 'pos_active_session'");

    if (isSwitchPerson) {
       final continuedData = jsonEncode({
         'carried_over_balance': actualCash,
         'original_start_time': originalStartTime.toIso8601String(),
       });
       await _dbService.insert('pos_options', {
         'option_name': 'pos_continued_shift_data',
         'option_value': continuedData,
       });
    }

    // Clear active session on server
    try {
      if (Get.isRegistered<SyncService>()) {
        Get.find<SyncService>().enqueueCommand(
          method: 'PUT',
          endpoint: '/api/pos_options',
          body: {'pos_active_session': ''},
          localId: 'pos_active_session_close',
        );
        debugPrint('ShiftController: Successfully queued active session clear to server');
      } else {
        await _apiService.updatePosOptions({
          'pos_active_session': ''
        });
        debugPrint('ShiftController: Successfully cleared active session from server');
      }
    } catch (e) {
      debugPrint('ShiftController: Failed to clear active session from server: $e');
    }

    activeShift.value = null;

    // 3. Trigger immediate sync to server
    try {
      Get.find<SyncService>().pushShiftLogs();
    } catch (e) {
      debugPrint("ShiftController: Failed to trigger sync: $e");
    }

    return {
      'shift': closedShift,
      'rekap': rekap,
    };
  }

  Future<Map<String, dynamic>?> executeEndOfDay(int actualCash, String note) async {
    try {
      // 1. Generate full End of Day Data
      final eodData = await generateEndOfDayData(actualCash: actualCash);

      // 2. Close the active shift normally (if any)
      final closeResult = await closeShift(actualCash, note, isSwitchPerson: false);
      
      final String userId = closeResult != null 
          ? (closeResult['shift'] as ShiftSessionModel).userId 
          : 'System';

      // 3. Create 'End of Day' shift_sessions record
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      
      // Calculate total cash expected (only Cash income)
      int expectedCash = 0;
      final pms = eodData['payment_modes'] as List<dynamic>;
      for (var pm in pms) {
        final String name = (pm['name']?.toString() ?? '').toLowerCase();
        final String id = pm['id']?.toString() ?? '';
        if (id == '1' || id == '7' || name.contains('cash')) {
          expectedCash += (pm['recorded'] as num?)?.toInt() ?? 0;
        }
      }
      
      final int totalDrawer = (eodData['total_actual_cash'] as num?)?.toInt() ?? 0;
      final int totalOpening = (eodData['total_opening_balance'] as num?)?.toInt() ?? 0;
      final int actualSalesCash = totalDrawer - totalOpening;
      final int diff = actualSalesCash - expectedCash;
      
      // Map eodData to match the reconciliation_data schema used by history
      final eodReconciliationData = {
        'shift_name': 'End of Day',
        'staff': (eodData['staff'] as List<String>).join(', '),
        'payment_modes': eodData['payment_modes'],
        'order_types': [], // EOD doesn't calculate this yet, can add later if needed
        'products_sold': eodData['products'],
        'discounts': eodData['discounts'],
        'members': {
          'additions': eodData['new_members']
        },
        'credit_notes': eodData['refunds'],
        'voids': eodData['voids'],
        'summary': {
          'expected_cash': expectedCash,
          'actual_cash': actualSalesCash,
          'difference': diff,
          'status': 2
        },
        'shifts_summary': eodData['shifts_summary'] // Add it here so we can view it in history if needed
      };
      
      final eodShift = ShiftSessionModel(
        // idShift is omitted to allow auto-increment
        shiftName: 'End of Day',
        userId: userId,
        startTime: startOfDay,
        endTime: now,
        startingBalance: totalOpening, // Note: EOD's starting balance is the total of all starting balances
        closingBalance: totalDrawer,
        totalCashExpected: expectedCash,
        totalCashActual: actualSalesCash,
        totalNonCash: (eodData['today_income'] as int) - expectedCash,
        status: 2, // Special status for End of Day
        note: 'End of Day Auto-generated',
        reconciliationData: jsonEncode([eodReconciliationData]),
      );
      
      // Save EOD record to DB
      await _dbService.insert('shift_sessions', eodShift.toJson());

      // If closeResult was null, we still return a valid map to trigger the success UI and print
      return {
        'closeResult': closeResult ?? {'shift': eodShift, 'rekap': {'cash': 0, 'nonCash': 0}},
        'eodData': eodData,
      };
    } catch (e) {
      debugPrint("ShiftController: executeEndOfDay error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> generateEndOfDayData({int actualCash = 0}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0).toIso8601String().replaceAll('T', ' ').split('.')[0];
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String().replaceAll('T', ' ').split('.')[0];
    final startOfYesterday = DateTime(now.year, now.month, now.day - 1, 0, 0, 0).toIso8601String().replaceAll('T', ' ').split('.')[0];
    final endOfYesterday = DateTime(now.year, now.month, now.day - 1, 23, 59, 59).toIso8601String().replaceAll('T', ' ').split('.')[0];

    // 1. Income by Payment Mode (Today)
    final List<Map<String, dynamic>> modeMetadata = await _dbService.query('payment_modes', where: 'active = ?', whereArgs: ['1']);
    final paymentModesList = <Map<String, dynamic>>[];
    final Map<String, int> totals = {};

    final paymentRows = await _dbService.rawQuery('''
      SELECT t.bayar AS amount, t.payment_method AS local_method,
        (SELECT paymentmethod FROM pos_payments WHERE id_pos = t.id_pos LIMIT 1) AS pp_method
      FROM transactions t
      WHERE t.status IN (2, 3)
        AND (
          (t.tgl_bayar IS NOT NULL AND t.tgl_bayar != "" AND REPLACE(substr(t.tgl_bayar,1,19), 'T', ' ') BETWEEN ? AND ?)
          OR ((t.tgl_bayar IS NULL OR t.tgl_bayar = "") AND REPLACE(substr(t.tgl_penjualan,1,19), 'T', ' ') BETWEEN ? AND ?)
        )
    ''', [startOfDay, endOfDay, startOfDay, endOfDay]);

    int todayIncome = 0;
    for (var r in paymentRows) {
      final amount = double.tryParse(r['amount']?.toString() ?? '0')?.toInt() ?? 0;
      todayIncome += amount;
      final ppMethod = r['pp_method']?.toString() ?? '';
      final localMethod = (r['local_method']?.toString() ?? '').toLowerCase();
      String? matchedId; String? matchedName;

      if (ppMethod.isNotEmpty) {
        final m = modeMetadata.firstWhereOrNull((m) => m['id']?.toString() == ppMethod);
        if (m != null) { matchedId = m['id']?.toString(); matchedName = m['name']?.toString(); }
      }
      if (matchedId == null && localMethod.isNotEmpty) {
        final m = modeMetadata.firstWhereOrNull((m) => (m['name']?.toString() ?? '').toLowerCase() == localMethod);
        if (m != null) { matchedId = m['id']?.toString(); matchedName = m['name']?.toString(); }
      }

      final key = matchedId ?? (ppMethod.isNotEmpty ? ppMethod : (localMethod.isNotEmpty ? localMethod : '1'));
      final name = matchedName ?? (localMethod.isNotEmpty ? r['local_method'] : (ppMethod == '1' ? 'Cash' : 'Other'));
      totals[key] = (totals[key] ?? 0) + amount;
      if (!paymentModesList.any((m) => m['id'] == key)) paymentModesList.add({'id': key, 'name': name, 'recorded': 0});
    }
    for (var m in paymentModesList) m['recorded'] = totals[m['id']] ?? 0;

    // 2. Yesterday's Income
    int yesterdayIncome = 0;
    try {
      final yRows = await _dbService.rawQuery('''
        SELECT SUM(bayar) as total FROM transactions
        WHERE status IN (2, 3)
          AND (
            (tgl_bayar IS NOT NULL AND tgl_bayar != "" AND REPLACE(substr(tgl_bayar,1,19), 'T', ' ') BETWEEN ? AND ?)
            OR ((tgl_bayar IS NULL OR tgl_bayar = "") AND REPLACE(substr(tgl_penjualan,1,19), 'T', ' ') BETWEEN ? AND ?)
          )
      ''', [startOfYesterday, endOfYesterday, startOfYesterday, endOfYesterday]);
      yesterdayIncome = (yRows.first['total'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    // 3. Cash Flow (Expenses)
    int totalExpenses = 0;
    final List<Map<String, dynamic>> expensesList = [];
    try {
      final cfRows = await _dbService.rawQuery('''
        SELECT expense_name, amount, direction FROM cash_flow
        WHERE date BETWEEN ? AND ? AND direction = 'out'
      ''', [startOfDay, endOfDay]);
      for (var r in cfRows) {
        final amount = (r['amount'] as num?)?.toInt() ?? 0;
        totalExpenses += amount;
        expensesList.add({'name': r['expense_name'], 'amount': amount});
      }
    } catch (_) {}

    // 4. Voided Orders
    int voidCount = 0;
    int voidTotal = 0;
    try {
      final vRows = await _dbService.rawQuery('''
        SELECT COUNT(*) as count, SUM(total_harga) as sum FROM transactions
        WHERE status = 5 AND REPLACE(substr(tgl_penjualan,1,19), 'T', ' ') BETWEEN ? AND ?
      ''', [startOfDay, endOfDay]);
      voidCount = (vRows.first['count'] as num?)?.toInt() ?? 0;
      voidTotal = (vRows.first['sum'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    // 5. Products Sold
    final List<Map<String, dynamic>> productsList = [];
    try {
      final pRows = await _dbService.rawQuery('''
        SELECT d.product_name, SUM(d.jumlah) as qty, SUM(d.subtotal) as total
        FROM transaction_details d
        JOIN transactions t ON d.id_penjualan = t.id_penjualan
        WHERE (REPLACE(substr(t.tgl_penjualan,1,19), 'T', ' ') BETWEEN ? AND ? OR REPLACE(substr(t.tgl_bayar,1,19), 'T', ' ') BETWEEN ? AND ?) AND t.status != 5
        GROUP BY d.id_produk, d.product_name ORDER BY SUM(d.subtotal) DESC LIMIT 15
      ''', [startOfDay, endOfDay, startOfDay, endOfDay]);
      for (var row in pRows) {
        final qty = (row['qty'] as num?)?.toInt() ?? 0;
        final total = (row['total'] as num?)?.toInt() ?? 0;
        productsList.add({
          'name': row['product_name'], 
          'qty': qty, 
          'total': total,
          'price': qty > 0 ? (total / qty).round() : 0,
        });
      }
    } catch (_) {}

    // 6. Refunds
    final List<Map<String, dynamic>> refundList = [];
    int refundTotal = 0;
    try {
      final rRows = await _dbService.rawQuery('''
        SELECT formatted_number, total FROM pos_credit_notes
        WHERE datecreated BETWEEN ? AND ?
      ''', [startOfDay, endOfDay]);
      for (var r in rRows) {
        final amt = (r['total'] as num?)?.toInt() ?? 0;
        refundTotal += amt;
        refundList.add({'name': r['formatted_number'], 'amount': amt});
      }
    } catch (_) {}

    // 7. Discounts
    int totalTransactionDiscount = 0;
    int totalProductDiscount = 0;
    try {
      final tDiscRows = await _dbService.rawQuery('''
        SELECT SUM(manual_discount_value) as t_disc FROM transactions
        WHERE (REPLACE(substr(tgl_penjualan,1,19), 'T', ' ') BETWEEN ? AND ?) AND status IN (2, 3)
      ''', [startOfDay, endOfDay]);
      totalTransactionDiscount = (tDiscRows.first['t_disc'] as num?)?.toInt() ?? 0;

      final pDiscRows = await _dbService.rawQuery('''
        SELECT SUM(d.discountTotal) as p_disc 
        FROM transaction_details d
        JOIN transactions t ON d.id_penjualan = t.id_penjualan
        WHERE (REPLACE(substr(t.tgl_penjualan,1,19), 'T', ' ') BETWEEN ? AND ? OR REPLACE(substr(t.tgl_bayar,1,19), 'T', ' ') BETWEEN ? AND ?) AND t.status IN (2, 3)
      ''', [startOfDay, endOfDay, startOfDay, endOfDay]);
      totalProductDiscount = (pDiscRows.first['p_disc'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    // 8. Staff / Shifts Today
    final List<String> staffList = [];
    try {
      final sRows = await _dbService.rawQuery('''
        SELECT DISTINCT user_id FROM shift_sessions
        WHERE REPLACE(substr(start_time,1,19), 'T', ' ') BETWEEN ? AND ?
      ''', [startOfDay, endOfDay]);
      for (var r in sRows) staffList.add(r['user_id']?.toString() ?? 'Unknown');
      
      // Also add current active shift staff if not added
      if (activeShift.value != null && !staffList.contains(activeShift.value!.userId)) {
        staffList.add(activeShift.value!.userId);
      }
    } catch (_) {}

    // 9. New Members
    int newMembersCount = 0;
    try {
      final mRows = await _dbService.rawQuery('''
        SELECT COUNT(*) as count FROM members
        WHERE REPLACE(substr(datecreated,1,19), 'T', ' ') BETWEEN ? AND ?
      ''', [startOfDay, endOfDay]);
      newMembersCount = (mRows.first['count'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    // 10. Shifts Summary (For Reconciliation)
    final List<Map<String, dynamic>> shiftsSummary = [];
    int totalActualCash = 0;
    int totalOpeningBalance = 0;
    try {
      final shRows = await _dbService.rawQuery('''
        SELECT id_shift, shift_name, starting_balance, total_cash_actual
        FROM shift_sessions
        WHERE REPLACE(substr(start_time,1,19), 'T', ' ') BETWEEN ? AND ?
          AND shift_name != 'End of Day'
      ''', [startOfDay, endOfDay]);
      
      for (var row in shRows) {
        final ob = (row['starting_balance'] as num?)?.toInt() ?? 0;
        final ac = (row['total_cash_actual'] as num?)?.toInt() ?? 0;
        totalOpeningBalance += ob;
        totalActualCash += ac;
        shiftsSummary.add({
          'id_shift': row['id_shift'],
          'name': row['shift_name'] ?? 'Shift',
          'opening_balance': ob,
          'actual_cash': ac,
        });
      }
      
      // Add active shift if not already in shiftsSummary (check by id_shift instead of name to avoid collisions)
      if (activeShift.value != null && !shiftsSummary.any((s) => s['id_shift'] == activeShift.value!.idShift)) {
        shiftsSummary.add({
          'id_shift': activeShift.value!.idShift,
          'name': activeShift.value!.shiftName,
          'opening_balance': activeShift.value!.startingBalance,
          'actual_cash': actualCash, // True actual cash submitted by user
        });
        totalOpeningBalance += activeShift.value!.startingBalance;
        totalActualCash += actualCash;
      }
    } catch (_) {}

    return {
      'date': now.toIso8601String(),
      'staff': staffList,
      'today_income': todayIncome,
      'yesterday_income': yesterdayIncome,
      'payment_modes': paymentModesList,
      'expenses': { 'total': totalExpenses, 'list': expensesList },
      'voids': { 'count': voidCount, 'total': voidTotal },
      'refunds': { 'total': refundTotal, 'list': refundList },
      'products': productsList,
      'discounts': {
        'product': totalProductDiscount,
        'transaction': totalTransactionDiscount,
      },
      'new_members': newMembersCount,
      'shifts_summary': shiftsSummary,
      'total_actual_cash': totalActualCash,
      'total_opening_balance': totalOpeningBalance,
    };
  }

  Future<Map<String, int>> calculateRecap() async {
    if (activeShift.value == null) return {'cash': 0, 'nonCash': 0};

    final startTime = activeShift.value!.startTime
        .toIso8601String()
        .replaceAll('T', ' ')
        .substring(0, 19);

    debugPrint('[ShiftController] calculateRecap: startTime=$startTime');

    int cash = 0;
    int nonCash = 0;

    try {
      // ONE ROW PER TRANSACTION — avoiding any JOIN fan-out bugs.
      // Consistent with RecapController logic.
      final rows = await _dbService.rawQuery('''
        SELECT
          t.bayar          AS amount,
          t.payment_method AS local_method,
          (SELECT pm.name 
             FROM pos_payments pp 
             JOIN payment_modes pm ON pm.id = pp.paymentmethod
            WHERE pp.id_pos = t.id_pos 
            LIMIT 1)       AS mode_name,
          (SELECT paymentmethod 
             FROM pos_payments 
            WHERE id_pos = t.id_pos 
            LIMIT 1)       AS pp_method
        FROM transactions t
        WHERE t.status IN (2, 3)
          AND (
            (t.tgl_bayar IS NOT NULL AND t.tgl_bayar != '' AND REPLACE(substr(t.tgl_bayar,1,19), 'T', ' ') >= ?)
            OR (
              (t.tgl_bayar IS NULL OR t.tgl_bayar = '')
              AND REPLACE(substr(t.tgl_penjualan, 1, 19), 'T', ' ') >= ?
            )
          )
      ''', [startTime, startTime]);

      debugPrint('[ShiftController] calculateRecap: found ${rows.length} paid transactions');

      for (var r in rows) {
        final int amount = double.tryParse(r['amount']?.toString() ?? '0')?.toInt() ?? 0;
        final String modeName = (r['mode_name']?.toString() ?? '').toLowerCase();
        final String ppMethod = (r['pp_method']?.toString() ?? '').toLowerCase();
        final String localMethod = (r['local_method']?.toString() ?? '').toLowerCase();

        final bool isCash = modeName.contains('cash') ||
            modeName.contains('tunai') ||
            ppMethod.contains('cash') ||
            ppMethod.contains('tunai') ||
            ppMethod == '1' || // Standard Cash ID
            ppMethod == '7' || // Custom Cash ID
            localMethod.contains('cash') ||
            localMethod.contains('tunai') ||
            localMethod == '1' ||
            localMethod == '7';

        if (isCash) {
          cash += amount;
        } else {
          nonCash += amount;
        }
      }
    } catch (e) {
      debugPrint('ShiftController: calculateRecap error: $e');
    }

    debugPrint('[ShiftController] Final recap: cash=$cash, nonCash=$nonCash');
    return {'cash': cash, 'nonCash': nonCash};
  }

  Future<String> getNextShiftCandidate() async {
    if (shiftConfigs.isEmpty) return 'Shift 1';

    if (activeShift.value != null) return activeShift.value!.shiftName;

    // To implement "looping sequential" logic: 1 -> 2 -> 3
    // 1. Get the last closed shift from history (order by start_time to ensure proper sequencing)
    final lastSessions = await _dbService.query('shift_sessions',
        orderBy: 'start_time DESC', limit: 1);

    String lastShiftName = '';
    if (lastSessions.isNotEmpty) {
      lastShiftName = lastSessions.first['shift_name']?.toString() ?? '';
    }

    // 2. Find its position in our master config
    return _findNextActiveShift(lastShiftName);
  }

  String _findNextActiveShift(String lastClosedName) {
    final activeOnly = shiftConfigs.where((s) => s.isActive).toList();
    if (activeOnly.isEmpty) return 'Shift 1';

    if (lastClosedName.isEmpty) return activeOnly.first.name;

    int currentIndex = activeOnly.indexWhere((s) => s.name == lastClosedName);

    // If not found (maybe deleted), or it's the last one, loop to first
    if (currentIndex == -1 || currentIndex == activeOnly.length - 1) {
      return activeOnly.first.name;
    }

    // Return the next active in sequence
    return activeOnly[currentIndex + 1].name;
  }

  String getAssignedStaff(String shiftName) {
    final cfg = shiftConfigs.firstWhereOrNull((s) => s.name == shiftName);
    return cfg?.staffName ?? '';
  }

  Future<void> _setDefaultConfigs() async {
    shiftConfigs.value = [
      ShiftConfig(name: 'Shift 1', isActive: true),
      ShiftConfig(name: 'Shift 2', isActive: true),
      ShiftConfig(name: 'Shift 3', isActive: true),
    ];
    await saveShiftConfig();
  }

  bool verifyPassword(String input) {
    final cached = _userService.getPrefString('cached_password');
    return input == cached;
  }
}
