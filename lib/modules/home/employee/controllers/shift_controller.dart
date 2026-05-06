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
          (t.tgl_bayar IS NOT NULL AND t.tgl_bayar != "" AND substr(t.tgl_bayar,1,19) >= ?)
          OR (
            (t.tgl_bayar IS NULL OR t.tgl_bayar = "")
            AND substr(t.tgl_penjualan,1,19) >= ?
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
        WHERE (substr(t.tgl_penjualan,1,19) >= ? OR substr(t.tgl_bayar,1,19) >= ?) AND t.status != 5
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
        WHERE (t.tgl_penjualan >= ? OR t.tgl_bayar >= ?) AND t.status IN (2, 3)
      ''', [startTime, startTime]);
      productDiscount = (pDisc.first['total'] as num?)?.toInt() ?? 0;

      final tDisc = await _dbService.rawQuery('''
        SELECT SUM(manual_discount_value) as total FROM transactions
        WHERE (tgl_penjualan >= ? OR tgl_bayar >= ?) AND status IN (2, 3)
      ''', [startTime, startTime]);
      transactionDiscount = (tDisc.first['total'] as num?)?.toInt() ?? 0;
    } catch(_) {}

    // 4. Order Types
    final List<Map<String, dynamic>> orderTypesList = [];
    try {
      final otRows = await _dbService.rawQuery('''
        SELECT order_type, SUM(bayar) as total
        FROM transactions
        WHERE (substr(tgl_penjualan,1,19) >= ? OR substr(tgl_bayar,1,19) >= ?) AND t.status IN (2, 3)
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
      'summary': {
        'expected_cash': activeShift.value!.startingBalance + (pms['cash'] ?? 0),
        'actual_cash': 0,
        'difference': 0,
        'status': 0
      }
    };
  }

  Future<Map<String, dynamic>?> closeShift(int actualCash, String note,
      {String? reconciliationData}) async {
    if (activeShift.value == null) return null;

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
      startTime: activeShift.value!.startTime,
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

  Future<Map<String, int>> calculateRecap() async {
    if (activeShift.value == null) return {'cash': 0, 'nonCash': 0};

    final startTime = activeShift.value!.startTime
        .toIso8601String()
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
            (t.tgl_bayar IS NOT NULL AND t.tgl_bayar != "" AND substr(t.tgl_bayar, 1, 19) >= ?)
            OR (
              (t.tgl_bayar IS NULL OR t.tgl_bayar = "")
              AND substr(t.tgl_penjualan, 1, 19) >= ?
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
            localMethod.contains('tunai');

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
    // 1. Get the last closed shift from history
    final lastSessions = await _dbService.query('shift_sessions',
        orderBy: 'id_shift DESC', limit: 1);

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
