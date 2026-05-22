import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:semesta_pos/core/services/user_service.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:semesta_pos/core/models/shift/shift_model.dart';
import 'package:semesta_pos/core/services/app_service.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/core/services/remote/api_service.dart';
import 'package:semesta_pos/core/util/constans.dart';
import 'package:semesta_pos/modules/home/employee/controllers/shift_controller.dart';
import 'package:semesta_pos/modules/dashboard/employee/controllers/dashboard_employee_controller.dart';
import 'package:semesta_pos/modules/dashboard/admin/controllers/dashboard_admin_controller.dart';
import 'package:semesta_pos/modules/order/controllers/order_controller.dart';
import 'package:semesta_pos/modules/home/employee/controllers/home_controller.dart';
import 'package:semesta_pos/modules/member/controllers/member_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:semesta_pos/core/services/error_log_service.dart';

// Top-level function for background JSON parsing
dynamic _parseJson(String text) => json.decode(text);

class SyncService extends GetxService {
  ApiService get _apiService => Get.find<ApiService>();
  DatabaseService get _dbService => Get.find<DatabaseService>();
  UserService get _userService => Get.find<UserService>();

  RxBool isProcessingQueue = false.obs;
  RxBool isSyncing = false.obs;
  Timer? _backgroundSyncTimer;

  @override
  void onInit() {
    super.onInit();

    // Trigger queue flush whenever internet reconnects
    InternetConnectionChecker().onStatusChange.listen((status) {
      if (status == InternetConnectionStatus.connected) {
        debugPrint("SyncService: Internet reconnected, flushing queue...");
        processQueue();
      }
    });

    // Background periodic sync — runs every 30s silently without blocking any UI
    _backgroundSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // Avoid starting background sync if the user is currently busy in the POS (checkout, payment, or loading)
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        if (homeController.isSyncingDirectly.value ||
            homeController.isProcessingPayment.value ||
            homeController.isLoadingTransaction.value) {
          debugPrint(
              "SyncService: Deferring background sync — POS foreground operation in progress.");
          return;
        }
      }
      debugPrint("SyncService: [Background] Periodic queue flush triggered.");
      processQueue();
    });
  }

  @override
  void onClose() {
    _backgroundSyncTimer?.cancel();
    super.onClose();
  }

  /// Orchestrates the mandatory post-login sequence in the exact order requested
  Future<void> runPostLoginSync() async {
    if (isSyncing.value) {
      debugPrint(
          "SyncService: Sync already in progress, skipping redundant call.");
      return;
    }
    isSyncing.value = true;
    debugPrint("SyncService: Starting mandatory post-login sync sequence...");
    syncProgress.value = 0.0;

    try {
      // 1. Customer
      syncStatus.value = "Fetching Customers...";
      await syncMembers();
      syncProgress.value = 0.15;

      // 2. Options
      syncStatus.value = "Fetching POS Options...";
      await syncOptions();
      syncProgress.value = 0.30;

      // 3. Brand
      syncStatus.value = "Fetching Brands...";
      await syncBrands();
      syncProgress.value = 0.45;

      // 4. Items
      syncStatus.value = "Fetching Items...";
      await syncProducts();
      syncProgress.value = 0.60;

      // 5. Categories
      syncStatus.value = "Fetching Categories...";
      await syncCategories();
      syncProgress.value = 0.75;

      // 6. Order (Remote history)
      syncStatus.value = "Fetching Order History...";
      await pullRemoteOrders();
      syncProgress.value = 0.90;

      // 7. Transaction (Payment history)
      syncStatus.value = "Fetching Transaction History...";
      await pullRemotePayments();
      syncProgress.value = 0.95;

      // 8. Payment Modes
      syncStatus.value = "Fetching Payment Modes...";
      await syncPaymentModes();
      syncProgress.value = 0.98;

      // 9. Credit Notes (Refunds)
      syncStatus.value = "Fetching Credit Notes...";
      await pullCreditNotes();
      syncProgress.value = 0.97;

      // 10. Staff
      syncStatus.value = "Fetching Staff...";
      await syncStaff();

      // 11. Promotions
      await syncPromotions();

      // 12. Expenses
      syncStatus.value = "Fetching Expenses...";
      await pullRemoteExpenses();

      // 13. Cleanup
      syncStatus.value = "Optimizing Database...";
      await _cleanupOldOrders();
      syncProgress.value = 1.0;

      syncStatus.value = "Sync Complete";

      // Flush any pending queue items from previous offline sessions
      debugPrint("SyncService: Post-login sync done — flushing pending queue.");
      processQueue();
    } catch (e) {
      syncStatus.value = "Sync Interrupted: $e";
      debugPrint("SyncService Error: $e");
      ErrorLogService.log(
        category: 'sync',
        errCode: 'SYNC_LOOP_ERROR',
        errMsg: e.toString(),
      );
      // As requested, we do our best and continue or log clearly
    } finally {
      isSyncing.value = false;
    }
  }

  /// Compatibility wrapper for existing callers
  Future<void> pullMasterData() async {
    await runPostLoginSync();
  }

  Future<void> syncFullData() async {
    if (isSyncing.value) {
      debugPrint("SyncService: Full sync already in progress, skipping.");
      return;
    }
    isSyncing.value = true;
    try {
      // Check network connectivity first
      final hasConnection = await InternetConnectionChecker().hasConnection;
      if (!hasConnection) {
        Get.snackbar(
          'Connection Failed',
          'Unable to connect to the network. Please check your internet connection and try again.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFFFDECEA),
          colorText: const Color(0xFFB91C1C),
          showProgressIndicator: false,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.signal_wifi_off, color: Color(0xFFB91C1C)),
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
        );
        return;
      }

      Get.snackbar(
        'Synchronization',
        'Please wait, updating master data and orders...',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white,
        colorText: Colors.black,
        showProgressIndicator: true,
        isDismissible: false,
        duration: const Duration(minutes: 1),
        icon: const Icon(Icons.sync, color: Color(0xFF3B82F6)),
      );

      await syncBrands();
      await syncCategories();
      await syncProducts();
      await syncMembers();
      await syncOptions();
      await syncPaymentModes();
      await pushLocalTransactions();
      await pushLocalPayments();
      await pushShiftLogs();
      await pullRemoteOrders();
      await syncStaff();
      await syncPromotions();
      await pullRemoteExpenses();

      // Final cleanup
      await _cleanupOldOrders();

      if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

      // Removed intrusive success snackbar as requested
    } catch (e) {
      if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
      debugPrint("SyncService: syncFullData failed: $e");
      ErrorLogService.log(
        category: 'sync',
        errCode: 'SYNC_FULL_DATA_FAIL',
        errMsg: e.toString(),
      );
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> pullRemoteOrders({bool unpaidOnly = false}) async {
    syncStatus.value = "Pulling Remote Orders...";
    debugPrint(
        "SyncService: Pulling Remote Orders (unpaidOnly: $unpaidOnly)...");
    final response = unpaidOnly
        ? await _apiService.getUnpaidOrders()
        : await _apiService.getPosOrders();

    if (response.responsestate == Constants.successState &&
        response.data != null) {
      // Data is already decoded in ApiService, but if it was raw, we'd use compute here.
      final List remoteOrders = response.data;
      final List<int> pulledRemoteIds = [];

      // Fetch all pending payments once to avoid querying inside the loop (prevents query spam)
      final pendingPayments =
          await _dbService.query('pos_payments', where: 'is_synced = 0');
      final Set<String> pendingPaymentOrderIds =
          pendingPayments.map((p) => p['id_pos']?.toString() ?? '').toSet();
      final Set<String> pendingPaymentInvoiceIds =
          pendingPayments.map((p) => p['invoiceid']?.toString() ?? '').toSet();

      for (var orderJson in remoteOrders) {
        final remoteId = int.parse(orderJson['id'].toString());
        pulledRemoteIds.add(remoteId);
        final idPos = orderJson['id_pos']?.toString();

        // 1. Check if the order already exists locally
        final localCheck = await _dbService.rawQuery(
            "SELECT id_penjualan, is_synced, id_penjualan_remote FROM transactions WHERE id_pos = ? OR id_penjualan_remote = ?",
            [idPos, remoteId]);

        int? localIdPenjualan;
        if (localCheck.isNotEmpty) {
          final localOrder = localCheck.first;
          localIdPenjualan = localOrder['id_penjualan'];

          if (localOrder['id_penjualan_remote'] == null) {
            // The server has the order, but local doesn't know the remote ID yet!
            // This means our POST succeeded, but we didn't get the response.
            // 1. Update the remote ID so future edits use PUT
            await _dbService.update('transactions', {'id_penjualan_remote': remoteId}, 'id_penjualan = ?', [localIdPenjualan]);
            
            // 2. Remove the POST from queue so we don't duplicate it
            await _dbService.delete('sync_queue', "method = 'POST' AND endpoint LIKE '%pos_order%' AND local_id = ?", [localIdPenjualan.toString()]);
            
            // 3. Remap any pending PUT/payments (created while offline) to use the correct remoteId instead of UUID placeholder
            await _remapLocalIdInQueue(localIdPenjualan.toString(), remoteId.toString());
            if (idPos != null && idPos.isNotEmpty) {
              await _remapLocalIdInQueue(idPos, remoteId.toString());
            }
          }

          // If local order is un-synced (modified locally but not yet pushed), skip pulling to avoid overriding it
          if (localOrder['is_synced'] == 0) continue;

          // PAYMENT GUARD: If the local transaction has a pending payment
          if (idPos != null && pendingPaymentOrderIds.contains(idPos) ||
              pendingPaymentInvoiceIds.contains(remoteId.toString())) {
            debugPrint(
                'SyncService: Skipping pullRemoteOrders override for id_pos=$idPos — pending local payment found.');
            continue;
          }
        }

        // 2. Fetch full items detail for this order
        final detailResp =
            await _apiService.getPosOrderDetails(remoteId.toString());
        if (detailResp.responsestate != Constants.successState ||
            detailResp.data == null) {
          continue;
        }

        final fullOrderData = detailResp.data;

        final tglPenjualan = fullOrderData['datecreated'] ??
            fullOrderData['date'] ??
            DateTime.now().toString();
        final totalHarga =
            double.tryParse(fullOrderData['subtotal']?.toString() ?? '0') ?? 0;
        final totalBayar =
            double.tryParse(fullOrderData['total']?.toString() ?? '0') ?? 0;
        final diskon = double.tryParse(
                fullOrderData['discount_total']?.toString() ?? '0') ??
            0;

        final adminNoteStr = fullOrderData['adminnote']?.toString() ?? '';
        final queueNumRemote = int.tryParse(adminNoteStr) ?? 0;

        await _dbService.transaction((txn) async {
          // Insert or Update Header
          final headerMap = {
            'id_member': fullOrderData['clientid'] ?? 1,
            'id_user': fullOrderData['addedfrom'] ?? 1,
            'tgl_penjualan': tglPenjualan.toString(),
            'total_item': (fullOrderData['items'] as List?)?.length ?? 0,
            'total_harga': totalHarga.toInt(),
            'diskon': diskon.toInt(),
            'bayar': totalBayar.toInt(),
            'diterima': totalBayar.toInt(),
            'order_note': fullOrderData['clientnote']?.toString() ?? '',
            'discount_type':
                fullOrderData['discount_type']?.toString() ?? 'percent',
            'manual_discount_value': (double.tryParse(
                        fullOrderData['discount_percent']?.toString() ?? '0') ??
                    0)
                .toInt(),
            'is_synced': 1, // It's from remote, so it's already synced
            'id_pos': idPos,
            'id_penjualan_remote': remoteId,
            'remote_number': fullOrderData['number']?.toString() ?? '',
            'order_type': fullOrderData['terms'] ?? 'Dine In',
            'label': fullOrderData['label']?.toString() ?? '',
            'status': _toInt(fullOrderData['status']),
          };

          if (queueNumRemote > 0) {
            headerMap['queue_number'] = queueNumRemote;
          }

          if (localIdPenjualan != null) {
            await txn.update('transactions', headerMap,
                where: 'id_penjualan = ?', whereArgs: [localIdPenjualan]);
          } else {
            localIdPenjualan = await txn.insert('transactions', headerMap);
          }

          // SMART NOTE UNMERGING: Parse consolidated note to restore item-specific notes and types
          Map<String, String> itemNotesMap = {};
          Map<String, String> itemTypesMap = {};
          final String remoteNote =
              fullOrderData['clientnote']?.toString() ?? '';
          if (remoteNote.contains('---ITEM NOTES---')) {
            final parts = remoteNote.split('---ITEM NOTES---');
            if (parts.length > 1) {
              final notesSection = parts[1].trim();
              // Remove HTML-encoded newlines from server response
              final cleanSection = notesSection
                  .replaceAll('<br />', '\n')
                  .replaceAll('<br>', '\n');
              final lines = cleanSection.split('\n');
              for (var rawLine in lines) {
                final line = rawLine.trim();
                if (line.isEmpty) continue;
                if (line.contains(' | ')) {
                  // Format: 'Name | Type - Note'  OR  'Name | Type'
                  final pipeIdx = line.indexOf(' | ');
                  final namePart = line.substring(0, pipeIdx).trim();
                  final rest = line.substring(pipeIdx + 3).trim();
                  if (rest.contains(' - ')) {
                    // Has both type and note
                    final dashIdx = rest.indexOf(' - ');
                    itemTypesMap[namePart] = rest.substring(0, dashIdx).trim();
                    itemNotesMap[namePart] = rest.substring(dashIdx + 3).trim();
                  } else {
                    // Type only, no note
                    itemTypesMap[namePart] = rest;
                  }
                } else if (line.contains(' - ')) {
                  // Format: 'Name - Note' (no custom order type)
                  final dashIdx = line.indexOf(' - ');
                  final namePart = line.substring(0, dashIdx).trim();
                  itemNotesMap[namePart] = line.substring(dashIdx + 3).trim();
                }
              }
            }
          }

          // Clear existing local items and replace with server's source-of-truth
          await txn.delete('transaction_details',
              where: 'id_penjualan = ?', whereArgs: [localIdPenjualan]);

          final items = fullOrderData['items'] as List? ?? [];
          for (var item in items) {
            final String desc = item['description']?.toString() ?? '';
            final qty = double.tryParse(item['qty']?.toString() ?? '1') ?? 1.0;
            final rate =
                double.tryParse(item['rate']?.toString() ?? '0') ?? 0.0;

            // 3. Match reverse ID by string matching the product name
            final prodHit = await txn.query('products',
                columns: ['id_produk', 'order_types', 'description'],
                where: 'nama_produk = ?',
                whereArgs: [desc],
                limit: 1);
            int produkId = 0; // Default 0 for custom/deleted items
            String orderTypesJson = '';
            String? prodDescription;
            if (prodHit.isNotEmpty) {
              produkId = (prodHit.first['id_produk'] as num?)?.toInt() ?? 0;
              orderTypesJson = prodHit.first['order_types']?.toString() ?? '';
              prodDescription = prodHit.first['description']?.toString();
            }

            final String itemNote = itemNotesMap[desc] ?? '';
            final String itemOrderType = itemTypesMap[desc] ??
                headerMap['order_type']?.toString() ??
                'Dine In';
            final remoteItemId = item['id']; // Perfex item row ID

            await txn.insert('transaction_details', {
              'id_penjualan': localIdPenjualan,
              'id_produk': produkId,
              'jumlah': qty.toInt(),
              'harga_jual': rate.toInt(),
              'subtotal': (qty * rate).toInt(),
              'note': itemNote.isNotEmpty
                  ? itemNote
                  : (produkId == 0 ? 'REMOTE_ITEM:$desc' : ''),
              'order_type': itemOrderType,
              'orderTypesJson': orderTypesJson,
              'remote_item_id': _toInt(remoteItemId),
              'product_name': desc,
              'description': prodDescription,
              'kitchen_status': _toInt(fullOrderData['sent']) == 1 ? 1 : 0,
              'is_refund': item['is_refund']?.toString() == '1' ||
                      item['is_refund'] == true
                  ? 1
                  : 0
            });
          }
        });
      }

      // 4. CLEANUP: Delete orders older than 24h that are already Paid (2) or Cancelled (5)
      // Active orders (unpaid) are always kept regardless of age.
      // await _cleanupOldOrders(); // Edit RIZKI Jangan dihapus

      debugPrint(
          "SyncService: Pulled ${remoteOrders.length} Remote Orders successfully. Retention policy applied.");

      // Instantly refresh the badge counter on the UI
      try {
        if (Get.isRegistered<DashboardEmployeeController>()) {
          Get.find<DashboardEmployeeController>().updateActiveOrderCount();
        }
        if (Get.isRegistered<DashboardAdminController>()) {
          Get.find<DashboardAdminController>().updateActiveOrderCount();
        }
      } catch (_) {}
      // Also refresh the order screen list if they are currently looking at it
      if (Get.isRegistered<OrderController>()) {
        try {
          Get.find<OrderController>().getOrders();
        } catch (_) {}
      }
      syncStatus.value = "Orders Updated";
    }
  }

  Future<void> enqueueCommand({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    bool isFormData = false,
    dynamic localId, // Add localId for remapping
  }) async {
    final baseUrl = _userService.getBaseUrl();

    // Deduplication: Check if an identical pending command already exists
    final existing = await _dbService.rawQuery(
        "SELECT id FROM sync_queue WHERE method = ? AND endpoint = ? AND local_id = ? AND status IN ('pending', 'failed')",
        [method, endpoint, localId?.toString()]);

    if (existing.isNotEmpty) {
      debugPrint(
          "SyncService: Skipping redundant command for $endpoint ($localId)");
      return;
    }

    await _dbService.insert('sync_queue', {
      'method': method,
      'base_url': baseUrl,
      'endpoint': endpoint,
      'body': body != null ? jsonEncode(body) : null,
      'is_form_data': isFormData ? 1 : 0,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
      'local_id': localId?.toString(),
    });

    // DO NOT call processQueue() here — it will run on the background 30s timer
    // or when internet reconnects. This keeps all POS operations instant (SQLite-only).
    debugPrint("SyncService: Queued [$method] $endpoint for background sync.");
  }

  /// Like enqueueCommand but for idempotent updates (e.g. pos_options queue counter).
  /// Instead of inserting a duplicate row every time, it UPDATES the body of the
  /// existing pending command for this [localId] + [endpoint]. Inserts if none exists.
  /// This prevents the sync_queue from accumulating hundreds of identical PUT requests.
  Future<void> upsertQueueSync({
    required String method,
    required String endpoint,
    required String localId,
    Map<String, dynamic>? body,
  }) async {
    final baseUrl = _userService.getBaseUrl();
    final bodyJson = body != null ? jsonEncode(body) : null;

    // Check for an existing pending/failed command for this localId + endpoint
    final existing = await _dbService.rawQuery(
        "SELECT id FROM sync_queue WHERE method = ? AND endpoint = ? AND local_id = ? AND status IN ('pending', 'failed')",
        [method, endpoint, localId]);

    if (existing.isNotEmpty) {
      // Update the body with the latest value — only the most recent state matters
      final existingId = existing.first['id'];
      await _dbService.update(
        'sync_queue',
        {
          'body': bodyJson,
          'status': 'pending', // reset failed → pending with fresh data
          'retry_count': 0,
          'last_error': null,
          'created_at': DateTime.now().toIso8601String(),
        },
        'id = ?',
        [existingId],
      );
      debugPrint(
          "SyncService: Updated existing sync command for $endpoint ($localId).");
    } else {
      await _dbService.insert('sync_queue', {
        'method': method,
        'base_url': baseUrl,
        'endpoint': endpoint,
        'body': bodyJson,
        'is_form_data': 0,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'local_id': localId,
      });
      debugPrint(
          "SyncService: Inserted new sync command for $endpoint ($localId).");
    }
  }

  Future<void> processQueue() async {
    if (isProcessingQueue.value) return;

    // Add a reasonable timeout to connectivity check to avoid hanging the queue
    final hasConnection = await InternetConnectionChecker()
        .hasConnection
        .timeout(const Duration(seconds: 5), onTimeout: () => false);

    if (!hasConnection) {
      debugPrint(
          "SyncService: [Background] No internet or timeout, skipping queue processing.");
      return;
    }

    isProcessingQueue.value = true;
    try {
      bool hasMore = true;
      final blockedLocalIds =
          <String>{}; // Persistent blocks during this entire process session

      while (hasMore) {
        final pending = await _dbService.rawQuery(
            "SELECT * FROM sync_queue WHERE status IN ('pending', 'failed') AND retry_count < 5 ORDER BY created_at ASC");

        if (pending.isEmpty) {
          hasMore = false;
          break;
        }

        debugPrint(
            "SyncService: Processing ${pending.length} items. Current Blocked: ${blockedLocalIds.length}");

        for (var snapshot in pending) {
          final latestRows = await _dbService.query('sync_queue',
              where: 'id = ?', whereArgs: [snapshot['id']]);
          if (latestRows.isEmpty) continue;
          final item = latestRows.first;

          if (item['status'] == 'success') continue;

          final localId = item['local_id']?.toString();
          if (localId != null && blockedLocalIds.contains(localId)) {
            debugPrint(
                "SyncService: Skipping item ${item['id']} because record $localId is currently blocked by previous failure.");
            continue;
          }

          // Cross-entity dependency check:
          // If body contains a negative clientid/invoiceid OR a UUID placeholder, check if that placeholder is still pending in the queue.
          final bodyStr = item['body']?.toString();
          if (bodyStr != null) {
            bool hasPendingDependency = false;
            
            // 1. Check for negative numeric placeholders
            if (bodyStr.contains('":-') || bodyStr.contains('":"-')) {
              final matches = RegExp(r'":"?(-?\d+)"?').allMatches(bodyStr);
              for (final m in matches) {
                final val = m.group(1);
                if (val != null && val.startsWith('-')) {
                  final depItems = await _dbService.rawQuery(
                      "SELECT id FROM sync_queue WHERE local_id = ? AND status IN ('pending', 'failed') AND id < ?",
                      [val, item['id']]);
                  if (depItems.isNotEmpty) {
                    hasPendingDependency = true;
                    break;
                  }
                }
              }
            }
            
            // 2. Check for UUID placeholders in invoiceid or clientid
            if (!hasPendingDependency && (bodyStr.contains('invoiceid') || bodyStr.contains('clientid'))) {
              try {
                final jsonMap = jsonDecode(bodyStr);
                final invoiceId = jsonMap['invoiceid']?.toString() ?? '';
                final clientId = jsonMap['clientid']?.toString() ?? '';
                
                // If invoiceid or clientid is a UUID (contains '-' and length > 20), it's a placeholder.
                // We defer this item because its parent hasn't been successfully synced yet.
                if ((invoiceId.contains('-') && invoiceId.length > 20) || 
                    (clientId.contains('-') && clientId.length > 20)) {
                  hasPendingDependency = true;
                }
              } catch (_) {}
            }

            if (hasPendingDependency) {
              debugPrint(
                  "SyncService: Deferring item ${item['id']} due to pending dependency in body.");
              continue;
            }
          }

          final mutableItem = Map<String, dynamic>.from(item);



          final success = await _executeCommand(mutableItem);
          if (success) {
            await _dbService.update(
                'sync_queue', {'status': 'success'}, 'id = ?', [mutableItem['id']]);
          } else {
            if (localId != null) {
              final lastError = (await _dbService.query('sync_queue',
                      columns: ['last_error'],
                      where: 'id = ?',
                      whereArgs: [item['id']]))
                  .first['last_error'];
              debugPrint(
                  "SyncService: CRITICAL BLOCK - Item $localId (Endpoint: ${item['endpoint']}) failed and is now blocking subsequent tasks for this record. Error: $lastError");
              blockedLocalIds.add(localId);
            }
          }
        }

        // Re-check for new items added during this batch
        final recheck = await _dbService.rawQuery(
            "SELECT id, local_id, endpoint FROM sync_queue WHERE status IN ('pending', 'failed') AND retry_count < 5");

        if (recheck.isEmpty) {
          hasMore = false;
          break;
        }

        // Check if EVERYTHING remaining is already blocked
        bool allBlocked = true;
        for (var row in recheck) {
          final lId = row['local_id']?.toString();
          if (lId == null || !blockedLocalIds.contains(lId)) {
            allBlocked = false;
            break;
          }
        }

        if (allBlocked) {
          debugPrint(
              "SyncService: All ${recheck.length} remaining items are logically blocked. Stopping queue processing session.");
          hasMore = false;
          break;
        }

        hasMore = true;
        debugPrint(
            "SyncService: Loop hasMore (${recheck.length} items). Pausing 2s before retry...");
        await Future.delayed(const Duration(seconds: 2));
        debugPrint("SyncService: Restarting loop...");
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      isProcessingQueue.value = false;
    }
  }

  /// Forces immediate execution of a specific pending command in the queue.
  /// Useful for ensuring dependencies (like a new member) are synced before
  /// dependent objects (like an order).
  Future<bool> processSpecificCommand(
      String localId, String endpointPattern) async {
    try {
      final items = await _dbService.query('sync_queue',
          where:
              "local_id = ? AND endpoint LIKE ? AND status IN ('pending', 'failed')",
          whereArgs: [localId, endpointPattern],
          limit: 1);

      if (items.isEmpty) return true; // Already processed or never existed

      final item = items.first;
      final success = await _executeCommand(item);
      if (success) {
        await _dbService.update(
            'sync_queue', {'status': 'success'}, 'id = ?', [item['id']]);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("SyncService: Error processing specific command: $e");
      return false;
    }
  }

  Future<bool> _executeCommand(Map<String, dynamic> item) async {
    final id = item['id'];
    final method = item['method'] as String;
    final baseUrl = item['base_url'] as String;
    final endpoint = item['endpoint'] as String;
    final isFormData = item['is_form_data'] == 1;
    final localId = item['local_id'];

    dynamic body;
    try {
      body = item['body'] != null
          ? await compute(_parseJson, item['body'] as String)
          : null;
    } catch (e) {
      debugPrint(
          "SyncService: Corrupted JSON body in queue item $id. Discarding: $e");
      await _dbService.delete('sync_queue', 'id = ?', [id]);
      return false;
    }

    try {
      String fullUrl = baseUrl;
      if (fullUrl.endsWith('/') && endpoint.startsWith('/')) {
        fullUrl = fullUrl.substring(0, fullUrl.length - 1) + endpoint;
      } else if (!fullUrl.endsWith('/') && !endpoint.startsWith('/')) {
        fullUrl = '$fullUrl/$endpoint';
      } else {
        fullUrl = fullUrl + endpoint;
      }

      final uri = Uri.parse(fullUrl);

      if ((method == 'PUT' || method == 'DELETE') && fullUrl.contains('/-')) {
        debugPrint("SyncService: Deferring $method with local ID: $fullUrl");
        return false;
      }

      final token = _userService.getAuthToken();
      final headers = {
        'authtoken': token,
        'Accept': 'application/json',
      };

      http.Response response;
      if (method == 'POST') {
        if (isFormData) {
          final request = http.MultipartRequest('POST', uri);
          request.headers.addAll(headers);
          if (body != null) {
            body.forEach((key, value) {
              request.fields[key.toString()] = value.toString();
            });
          }
          final streamedResponse =
              await request.send().timeout(const Duration(seconds: 15));
          response = await http.Response.fromStream(streamedResponse)
              .timeout(const Duration(seconds: 15));
        } else {
          headers['Content-Type'] = 'application/json';
          response = await http
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 15));
        }
      } else if (method == 'PUT') {
        headers['Content-Type'] = 'application/json';

        response = await http
            .put(uri, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 15));
      } else if (method == 'DELETE') {
        response = await http
            .delete(uri, headers: headers)
            .timeout(const Duration(seconds: 15));
      } else {
        return false;
      }

      _logSyncCall(method, uri, body,
          response: response.body, statusCode: response.statusCode);

      bool isTreatedAsSuccess =
          response.statusCode >= 200 && response.statusCode < 300;

      // Check for logical API failures masked as HTTP 200 (common in Perfex CRM).
      if (isTreatedAsSuccess) {
        try {
          final respData = jsonDecode(response.body);
          if (respData is Map &&
              respData.containsKey('status') &&
              respData['status'] == false) {
            isTreatedAsSuccess = false;
            debugPrint(
                "SyncService: Ignored HTTP ${response.statusCode} - Logical Failure: ${response.body}");
          }
        } catch (_) {
          // Body is not JSON or unparseable, rely on HTTP status
        }
      }

      // Perfex API workaround: PUT to pos_order often returns 404 'Invoice Update Fail'
      // when the server can't match the update due to status, items, or timing issues.
      if (method == 'PUT' &&
          endpoint.contains('pos_order') &&
          (response.statusCode == 404 || response.statusCode == 422) &&
          response.body.contains('Invoice Update Fail')) {
        isTreatedAsSuccess = true;
        debugPrint(
            "SyncService: Ignored Perfex ${response.statusCode} 'Invoice Update Fail' — order data is already saved locally.");
      }

      // Perfex API workaround: PUT to pos_options returns 500 'Failed to update data'
      // when the submitted value is identical to what is already on the server (no-op update).
      // This is safe to treat as success — the server already has the correct value.
      if (method == 'PUT' &&
          endpoint.contains('pos_options') &&
          response.statusCode == 500 &&
          response.body.contains('Failed to update data')) {
        isTreatedAsSuccess = true;
        debugPrint(
            "SyncService: Ignored pos_options 500 'Failed to update data' — server already has the current value.");
      }

      if (isTreatedAsSuccess) {
        if (method == 'POST' && endpoint.contains('pos_customers')) {
          try {
            final respData = jsonDecode(response.body);
            final dynamic dataRaw = respData['data'];
            Map<String, dynamic>? remoteMember;

            if (dataRaw is List && dataRaw.isNotEmpty) {
              remoteMember = dataRaw.first;
            } else if (dataRaw is Map<String, dynamic>) {
              remoteMember = dataRaw;
            }

            String? remoteId;
            String? remoteIdPos;

            if (remoteMember != null) {
              remoteId = remoteMember['id']?.toString() ?? remoteMember['clientid']?.toString();
              remoteIdPos = remoteMember['id_pos']?.toString();
            } else {
              // Fallback if API only returns the ID in 'data' or root 'id'/'clientid'
              remoteId = respData['clientid']?.toString() ??
                         respData['id']?.toString() ??
                         ((dataRaw is int || dataRaw is String) ? dataRaw.toString() : null);
            }

            if (remoteId != null && remoteId.isNotEmpty) {
              // 1. Remap other items in the queue using UUID (more stable)
              if (remoteIdPos != null) {
                await _remapLocalIdInQueue(remoteIdPos, remoteId);
              }

              // 2. Remap other items in the queue using numeric localId (legacy/compatibility)
              if (localId != null) {
                await _remapLocalIdInQueue(localId.toString(), remoteId);
              }

              // 3. Update the local tables (members, transactions)
              // We prioritize using the numeric localId for updating the id_member column
              await _updateLocalIdAfterSync(
                  localId?.toString() ?? remoteIdPos ?? "", remoteId, endpoint);
            } else {
              debugPrint("SyncService: Could not extract remote ID from pos_customers response. Body: ${response.body}");
            }
          } catch (e) {
            debugPrint(
                "SyncService: Failed to parse Member data for remapping: $e");
          }
        } else if (method == 'POST' && localId != null) {
          debugPrint(
              "SyncService: POST response for $endpoint (status ${response.statusCode}): ${response.body}");
          try {
            final respData = await compute(_parseJson, response.body);

            // Extract remote ID (invoice ID or member ID)
            final remoteId = respData['id'] ??
                (respData['data'] is Map ? respData['data']['id'] : null) ??
                respData['id_member'] ??
                (respData['data'] is Map
                    ? respData['data']['id_member']
                    : null);

            if (remoteId != null) {
              final String? remoteNumber = respData['number']?.toString() ??
                  (respData['data'] is Map
                      ? respData['data']['number']?.toString()
                      : null);
              debugPrint(
                  "SyncService: Found remote ID $remoteId ${remoteNumber != null ? '(Number $remoteNumber)' : ''} for local ID $localId. Updating...");
              
              // 1. Remap using the local numeric ID
              await _remapLocalIdInQueue(
                  localId.toString(), remoteId.toString());
                  
              // 2. Remap using the UUID (id_pos) placeholder to catch dependent pos_transactions
              final requestUuid = (body is Map) ? body['id_pos']?.toString() : null;
              if (requestUuid != null && requestUuid.isNotEmpty) {
                await _remapLocalIdInQueue(requestUuid, remoteId.toString());
              }

              await _updateLocalIdAfterSync(
                  localId.toString(), remoteId.toString(), endpoint,
                  remoteNumber: remoteNumber);

              // Mapping returned item IDs for pos_order
              if (endpoint.contains('pos_order')) {
                final List? remoteItems = respData['items'] ??
                    (respData['data'] is Map
                        ? respData['data']['items']
                        : null);
                if (remoteItems != null && remoteItems.isNotEmpty) {
                  final localItems = await _dbService.query(
                      'transaction_details',
                      where: 'id_penjualan = ?',
                      whereArgs: [localId]);
                  for (int i = 0; i < remoteItems.length; i++) {
                    final remoteItem = remoteItems[i];
                    final String? serverItemId =
                        remoteItem['itemid']?.toString() ??
                            remoteItem['id']?.toString();
                    if (serverItemId != null && i < localItems.length) {
                      await _dbService.update(
                          'transaction_details',
                          {'remote_item_id': int.tryParse(serverItemId)},
                          'id_penjualan_detail = ?',
                          [localItems[i]['id_penjualan_detail']]);
                    }
                  }
                }
              }
            } else {
              debugPrint(
                  "SyncService: Could not find remote ID in response body for $endpoint.");
            }
          } catch (e) {
            debugPrint(
                "SyncService: Failed to parse ID for remapping for $endpoint: $e");
            debugPrint(
                "SyncService: Invalid response body summary: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}");
          }
        } else if (method == 'PUT' &&
            endpoint.contains('pos_order') &&
            localId != null) {
          debugPrint(
              "SyncService: PUT success for $endpoint (status ${response.statusCode}). Marking as synced.");
          try {
            // For PUT, we already have the remote ID from the endpoint itself
            // Extract remote number if available in response
            final respData = await compute(_parseJson, response.body);
            final String? remoteNumber = respData['number']?.toString() ??
                (respData['data'] is Map
                    ? respData['data']['number']?.toString()
                    : null);
            final String? statusId = respData['data'] is Map
                ? respData['data']['status']?.toString()
                : null;

            // MANDATORY REMAPPING: Ensure payments in the queue use the correct ID after update
            final uriParts = endpoint.split('/');
            final remoteId = uriParts.last;
            await _remapLocalIdInQueue(localId.toString(), remoteId.toString());

            // Extract remote ID from endpoint
            final actualRemoteId = uriParts.last;

            await _updateLocalIdAfterSync(
                localId.toString(), actualRemoteId, endpoint,
                remoteNumber: remoteNumber);

            if (statusId != null && statusId.isNotEmpty) {
              await _dbService.update(
                  'transactions',
                  {'status': int.tryParse(statusId) ?? 1},
                  'id_penjualan = ?',
                  [localId]);
              if (Get.isRegistered<OrderController>()) {
                Get.find<OrderController>().refreshOrders();
              }
            }
          } catch (e) {
            debugPrint(
                "SyncService: Failed to mark PUT as synced for $endpoint: $e");
          }
        } else if (method == 'DELETE' &&
            endpoint.contains('pos_order') &&
            localId != null) {
          debugPrint(
              "SyncService: DELETE success for $endpoint. Marking as synced.");
          final localIdInt = int.tryParse(localId);
          if (localIdInt != null) {
            await _dbService.update('transactions', {'is_synced': 1},
                'id_penjualan = ?', [localIdInt]);
          }
        } else {
          // Fallback: If no ID in response but endpoint is a known entity, mark it synced anyway
          if (localId != null &&
              (endpoint.contains('pos_transaction') ||
                  endpoint.contains('pos_shift_logs'))) {
            await _updateLocalIdAfterSync(localId.toString(), "0", endpoint);
          }
          debugPrint(
              "SyncService: Successful $method request to $endpoint, handled via fallback or no remapping needed.");
        }

        // POST-SYNC REFRESH: If we just synced a customer, order, or payment, refresh relevant controllers
        if (endpoint.contains('pos_customers') ||
            endpoint.contains('pos_order') ||
            endpoint.contains('pos_payments')) {
          debugPrint(
              "SyncService: Triggering background member sync to update points...");
          syncMembers().catchError((e) =>
              debugPrint("SyncService: Background points refresh failed: $e"));
        }

        // After payment is recorded, refresh the order list so the status updates immediately
        if (endpoint.contains('pos_transaction')) {
          if (Get.isRegistered<OrderController>()) {
            Get.find<OrderController>().getOrders();
          }
          // Notify any listeners watching sync status
          syncStatus.value = "Payment Synced";
        }

        return true;
      } else {
        final errorMsg =
            "Server error: ${response.statusCode} - ${response.body}";
        debugPrint("SyncService: Request failed for $endpoint: $errorMsg");
        await _updateQueueError(id, item['retry_count'] as int, errorMsg);
        return false;
      }
    } catch (e) {
      debugPrint(
          "SyncService: Exception during _executeCommand for $endpoint: $e");
      await _updateQueueError(id, item['retry_count'] as int, e.toString());
      ErrorLogService.log(
        category: 'sync_queue',
        errCode: 'EXECUTE_COMMAND_FAIL',
        errMsg: '$endpoint | ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> _updateQueueError(int id, int currentRetry, String error) async {
    await _dbService.update(
        'sync_queue',
        {
          'status': 'failed',
          'retry_count': currentRetry + 1,
          'last_error': error,
        },
        'id = ?',
        [id]);
  }

  RxString syncStatus = "Idle".obs;
  RxDouble syncProgress = 0.0.obs;

  // --- Methods used by Batch Tasks ---

  Future<void> syncBrands() async {
    syncStatus.value = "Pulling Brands...";
    final response = await _apiService.getBrand();
    if (response.responsestate == Constants.successState &&
        response.data != null) {
      final List brands = response.data;
      final db = await _dbService.database;
      final batch = db.batch();

      batch.delete('brands');
      for (var item in brands) {
        batch.insert(
            'brands',
            {
              'id_brand': item.idBrand,
              'nama_brand': item.namaBrand?.trim(),
              'commodity_group_code': item.commodityGroupCode?.trim(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      syncStatus.value = "Brands Updated";
    }
  }

  Future<void> syncOptions() async {
    syncStatus.value = "Pulling Options...";
    final response = await _apiService.getPosOptions();
    if (response.responsestate == Constants.successState &&
        response.data != null) {
      Map<String, dynamic> options = {};
      if (response.data is Map) {
        options = response.data as Map<String, dynamic>;
      } else if (response.data is List && (response.data as List).isNotEmpty) {
        options = (response.data as List).first as Map<String, dynamic>;
      }

      final db = await _dbService.database;
      final batch = db.batch();

      // Only wipe old cache if we ACTUALLY got new valid options mapped.
      if (options.isNotEmpty) {
        // IMPORTANT: Exclude queue keys and session keys from the wipe.
        // ps_next_queue / ps_last_queue_date are local-authoritative — the device
        // is the only one incrementing them. Wiping them causes queue to reset to 1.
        batch.rawDelete("DELETE FROM pos_options WHERE option_name NOT IN ("
            "'pos_active_session', 'pos_shift_config', 'pos_active_staff', "
            "'${Constants.psNextQueue}', '${Constants.psLastQueueDate}')");

        options.forEach((key, value) {
          final serverVal = value?.toString() ?? '';

          if (key == 'pos_active_session' || key == 'pos_active_staff') {
            // ONLY overwrite local device session if the server has an active session AND local does NOT.
            if (serverVal.isNotEmpty && serverVal.length > 5) {
              try {
                final decoded = jsonDecode(serverVal);
                if (decoded is Map<String, dynamic>) {
                  if (key == 'pos_active_session' &&
                      Get.isRegistered<ShiftController>()) {
                    final shiftCtrl = Get.find<ShiftController>();
                    if (shiftCtrl.activeShift.value == null) {
                      batch.insert(
                          'pos_options',
                          {
                            'option_name': key,
                            'option_value': serverVal,
                          },
                          conflictAlgorithm: ConflictAlgorithm.replace);
                      shiftCtrl.activeShift.value =
                          ShiftSessionModel.fromJson(decoded);
                    }
                  } else if (key == 'pos_active_staff') {
                    batch.insert(
                        'pos_options',
                        {
                          'option_name': key,
                          'option_value': serverVal,
                        },
                        conflictAlgorithm: ConflictAlgorithm.ignore);
                  }
                }
              } catch (e) {
                debugPrint('SyncService: Invalid JSON for $key: $e');
              }
            }
            return;
          }

          // Queue counter protection: only accept server value if it is NEWER than local.
          // This prevents stale server data from overwriting a fresh local counter after
          // coming back online (e.g. server still has yesterday's date).
          if (key == Constants.psNextQueue ||
              key == Constants.psLastQueueDate) {
            if (Get.isRegistered<AppService>()) {
              final appSvc = Get.find<AppService>();
              final today = DateTime.now().toIso8601String().split('T').first;
              final localDate = appSvc.lastQueueDate.value;
              final serverDate = key == Constants.psLastQueueDate
                  ? serverVal
                  : options[Constants.psLastQueueDate]?.toString() ?? '';

              // Skip if local date is today (device has authoritative data for today)
              if (localDate == today) {
                debugPrint(
                    'SyncService: Skipping server $key — local queue is current for today ($today).');
                return;
              }
              // If server date is newer, allow it to restore the counter
              if (serverDate.isNotEmpty &&
                  serverDate.compareTo(localDate) > 0) {
                debugPrint(
                    'SyncService: Applying server $key — server date ($serverDate) is newer than local ($localDate).');
              } else {
                // Server data is same or older; keep local
                return;
              }
            } else {
              return; // AppService not ready; skip
            }
          }

          batch.insert(
              'pos_options',
              {
                'option_name': key,
                'option_value': serverVal,
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
        });

        await batch.commit(noResult: true);

        // Refresh AppService so UI components can react to new data.
        // loadLocalSettings will now correctly restore the protected queue counter.
        if (Get.isRegistered<AppService>()) {
          await Get.find<AppService>().loadLocalSettings();
        }
      }
      syncStatus.value = "Options Updated";
    }
  }

  Future<void> syncCategories() async {
    syncStatus.value = "Pulling Categories...";
    final response = await _apiService.getCategory();
    if (response.responsestate == Constants.successState &&
        response.data != null) {
      final List cats = response.data;
      final db = await _dbService.database;
      final batch = db.batch();

      batch.delete('categories');
      try {
        for (var item in cats) {
          batch.insert(
              'categories',
              {
                'id_kategori': item.idKategori,
                'nama_kategori': item.namaKategori?.trim(),
                'brand_name': item.brand?.trim(),
                'commodity_code': item.commondityCode?.trim(),
                'is_synced': 1,
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
        syncStatus.value = "Categories Updated";
      } catch (e) {
        debugPrint('error get category: $e');
      }
    }
  }

  Future<void> syncProducts() async {
    syncStatus.value = "Pulling Products...";
    final response = await _apiService.getProduct();
    if (response.responsestate == Constants.successState &&
        response.data != null) {
      final Map<String, dynamic> data = response.data;
      final List items = data['items'];
      final db = await _dbService.database;
      final batch = db.batch();

      batch.delete('products');
      for (var item in items) {
        int idBrand = _toInt(item['brand_id']);
        String? brandName;
        if (idBrand == 0 &&
            item['group_names'] != null &&
            (item['group_names'] as List).isNotEmpty) {
          final firstGroup = item['group_names'][0];
          idBrand = int.tryParse(firstGroup['id'].toString()) ?? 0;
          brandName = firstGroup['name'];
        }
        batch.insert(
            'products',
            {
              'id_produk': _toInt(item['id']),
              'id_kategori': _toInt(item['category_id']),
              'id_brand': idBrand,
              'nama_produk': item['name']?.toString() ?? '',
              'kode_produk': item['sku']?.toString(),
              'harga_beli': _toInt(item['cost']),
              'harga_jual': _toInt(item['price']),
              'stok': _toInt(item['stock_quantity']),
              'img': item['image_url'],
              'merk': brandName ?? item['brand_name'] ?? '',
              'description': item['description']?.toString(),
              'order_types': item['order_types'] != null
                  ? jsonEncode(item['order_types'])
                  : '',
              'discount_total': _toInt(item['discount_total']),
              'discount_type': item['discount_type']?.toString() ?? 'percent',
              'status': item['status']?.toString() ?? 'active',
              'parent': item['parent']?.toString(),
              'children': item['children']?.toString(),
              'is_synced': 1,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      syncStatus.value = "Products Updated";
    }
  }

  Future<void> syncMembers() async {
    syncStatus.value = "Pulling Customers...";
    final response = await _apiService.getMember();
    if (response.responsestate == Constants.successState &&
        response.data != null) {
      final db = await _dbService.database;
      final batch = db.batch();

      batch.delete('members', where: 'is_synced = ?', whereArgs: [1]);
      for (var item in response.data) {
        batch.insert(
            'members',
            {
              'id_member': item.idMember,
              'id_pos': item.idPos,
              'nama': item.nama,
              'telepon': item.telepon,
              'alamat': item.alamat,
              'email': item.email,
              'jenis_kel': item.jenisKel,
              'kategori_cust': item.kategoriCust,
              'points': item.points?.toString(),
              'is_synced': 1,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      syncStatus.value = "Customers Updated";
    }
  }

  Future<void> pushLocalTransactions() async {
    // Only push unsynced orders that are NOT cancelled
    // Cancelled orders (status = 5) should be handled by PUT/DELETE, not posted as new.
    final unsynced = await _dbService.query('transactions',
        where: 'is_synced = ? AND (status IS NULL OR status != 5)',
        whereArgs: [0]);
    for (var row in unsynced) {
      final localId = row['id_penjualan'];
      
      // Check if it's already in the queue
      final existingQueue = await _dbService.query('sync_queue',
          where: 'local_id = ? AND endpoint LIKE ?',
          whereArgs: [localId.toString(), '%pos_order%']);
      if (existingQueue.isNotEmpty) continue; // Already explicitly queued

      final details = await _dbService.query('transaction_details',
          where: 'id_penjualan = ?', whereArgs: [localId]);

      // Fetch customer details for billing_street
      final customer = await _dbService.query('members',
          where: 'id_member = ?', whereArgs: [row['id_member']]);
      final billingStreet = customer.isNotEmpty
          ? (customer.first['alamat']?.toString() ?? "-")
          : "-";
      final String finalBillingStreet =
          billingStreet.isEmpty || billingStreet == "null"
              ? "-"
              : billingStreet;

      final subtotal = (row['total_harga'] ?? 0).toDouble().toStringAsFixed(2);
      final total = (row['bayar'] ?? 0).toDouble().toStringAsFixed(2);

      final discountType = row['discount_type']?.toString() ?? 'percent';
      double discountPercent = 0.0;
      double discountAmount = (row['diskon'] ?? 0).toDouble();
      
      if (discountType == 'percent') {
        discountPercent = (row['manual_discount_value'] ?? 0).toDouble();
      } else {
        discountPercent = 0.0;
      }
      
      final queueNum = row['queue_number'] ?? 0;
      final orderNote = row['order_note']?.toString() ?? '';
      
      // SMART NOTE MERGING: Rebuild merged note to preserve item notes during background sync
      String cleanedNote = orderNote;
      if (cleanedNote.contains('---ITEM NOTES---')) {
        cleanedNote = cleanedNote.split('---ITEM NOTES---')[0].trim();
      }
      
      final itemLines = details.where((i) {
        final itemOrderType = i['order_type']?.toString() ?? '';
        final itemNote = i['note']?.toString() ?? '';
        final diffType = itemOrderType.isNotEmpty && itemOrderType != "Dine In";
        final hasNote = itemNote.isNotEmpty;
        return diffType || hasNote;
      }).map((i) {
        final itemOrderType = i['order_type']?.toString() ?? '';
        final itemNote = i['note']?.toString() ?? '';
        final type = itemOrderType.isNotEmpty ? itemOrderType : "Dine In";
        final noteStr = itemNote.isNotEmpty ? ' - $itemNote' : '';
        return '${i['product_name'] ?? 'Item'} | $type$noteStr';
      }).toList();

      String mergedNote = cleanedNote;
      if (itemLines.isNotEmpty) {
        final buffer = StringBuffer();
        if (cleanedNote.isNotEmpty) buffer.writeln(cleanedNote);
        buffer.writeln('---ITEM NOTES---');
        buffer.writeAll(itemLines, '\n');
        mergedNote = buffer.toString().trim();
      }
      
      final terms = row['order_type']?.toString() ?? 'dine_in';

      final map = {
        'clientid': row['id_member'],
        'date': row['tgl_penjualan'].toString().split('T')[0], // YYYY-MM-DD
        'prefix': 'POS-',
        'id_pos': row['id_pos'] ?? "",
        'currency': 3, // Indonesian Rupiah
        'newitems': details
            .asMap()
            .entries
            .map((entry) => {
                  'description': entry.value['product_name'] ?? 'Product',
                  'long_description': '',
                  'qty': entry.value['jumlah'].toString(),
                  'rate':
                      (entry.value['harga_jual'] ?? 0).toDouble().toStringAsFixed(2),
                  'order': (entry.key + 1).toString(),
                  'unit': '',
                  'taxname': [],
                })
            .toList(),
        'allowed_payment_modes': ["7"], 
        'billing_street': finalBillingStreet,
        'subtotal': subtotal,
        'total': total,
        'discount_total': discountAmount.toStringAsFixed(2),
        'discount_percent': discountPercent.toStringAsFixed(2),
        'discount_type': discountType,
        'clientnote': mergedNote,
        'terms': terms,
        'adminnote': queueNum > 0 ? queueNum.toString() : '',
        'sale_agent': row['id_user']?.toString() ?? '',
      };

      await enqueueCommand(
        method: 'POST',
        endpoint: '/api/pos_order',
        body: map,
        localId: localId,
      );
    }
  }

  Future<void> pushLocalPayments() async {
    final unsynced = await _dbService
        .query('pos_payments', where: 'is_synced = ?', whereArgs: [0]);
    for (var row in unsynced) {
      final localPaymentId = row['id'];

      // Check if it's already in the queue
      final existingQueue = await _dbService.query('sync_queue',
          where: 'local_id = ? AND endpoint LIKE ?',
          whereArgs: [localPaymentId.toString(), '%pos_transaction%']);
      if (existingQueue.isNotEmpty) continue; // Already explicitly queued

      // Retrieve InvoiceID if needed or if it's currently a UUID placeholder
      String invoiceIdStr = row['invoiceid']?.toString() ?? '';
      if (invoiceIdStr.isEmpty || invoiceIdStr.contains('-') || invoiceIdStr.length > 20) {
        final tx = await _dbService.query('transactions',
            where: 'id_pos = ?', whereArgs: [row['id_pos']]);
        if (tx.isNotEmpty) {
          final localTxId = tx.first['id_penjualan'] as int;
          if (tx.first['id_penjualan_remote'] != null && tx.first['id_penjualan_remote'].toString() != '0') {
            invoiceIdStr = tx.first['id_penjualan_remote'].toString();
            // Automatically clean up the SQLite table since we found the real remote ID
            await _dbService.update('pos_payments', {'invoiceid': invoiceIdStr}, 'id = ?', [localPaymentId]);
          } else {
            invoiceIdStr = localTxId.toString(); // Placeholder!
          }
        }
      }

      final apiPaymentBody = {
        'id_pos': row['id_pos'],
        'invoiceid': invoiceIdStr,
        'amount': row['amount']?.toString() ?? '0',
        'paymentmode': row['paymentmode']?.toString().toLowerCase() ?? '7',
        'paymentmethod': row['paymentmethod'] ?? row['paymentmode'] ?? '7',
        'date': row['date']?.toString() ??
            DateTime.now().toIso8601String().split('T')[0],
        'transactionid': row['transactionid'] ?? '',
        'note': row['note'] ?? '',
      };

      await enqueueCommand(
        method: 'POST',
        endpoint: '/api/pos_transaction',
        body: apiPaymentBody,
        localId: localPaymentId,
      );
    }
  }

  Future<void> pushShiftLogs() async {
    final unsynced = await _dbService
        .query('shift_sessions', where: 'is_synced = ?', whereArgs: [0]);
    for (var row in unsynced) {
      final localId = row['id_shift'];

      // Check if it's already in the queue
      final existingQueue = await _dbService.query('sync_queue',
          where: 'local_id = ? AND endpoint LIKE ?',
          whereArgs: [localId.toString(), '%pos_shift_logs%']);
      if (existingQueue.isNotEmpty) continue; // Already explicitly queued

      List<dynamic> transactions = [];
      if (row['reconciliation_data'] != null &&
          row['reconciliation_data'].toString().isNotEmpty) {
        try {
          transactions = jsonDecode(row['reconciliation_data']);
        } catch (e) {
          debugPrint(
              "SyncService: Error parsing reconciliation_data for shift: $e");
        }
      }

      String dateStr = row['start_time'] ??
          '${DateTime.now().toIso8601String().split('T')[0]} 00:00:00';
      try {
        if (dateStr.contains('T')) {
          final dt = DateTime.parse(dateStr);
          dateStr =
              "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
        }
      } catch (e) {
        debugPrint("SyncService: Error parsing date for shift log: $e");
      }

      final payload = {
        'date': dateStr,
        'name': row['user_id'] ?? 'Kasir',
        'shift': row['shift_name'] ?? 'Shift 1',
        'transactions': transactions,
      };

      await enqueueCommand(
        method: 'POST',
        endpoint: '/api/pos_shift_logs',
        body: payload,
        localId: localId,
      );
    }
  }

  Future<void> _remapLocalIdInQueue(String localId, String remoteId) async {
    final pendingItems = await _dbService.query('sync_queue',
        where:
            "status IN ('pending', 'failed') AND (endpoint LIKE ? OR body LIKE ? OR body LIKE ? OR local_id = ?)",
        whereArgs: [
          '%/$localId%',
          '%"$localId"%', // matches "clientid":"-123"
          '%:$localId%', // matches "clientid":-123
          localId
        ]);

    for (var item in pendingItems) {
      final id = item['id'];
      String endpoint = item['endpoint'] as String;
      String? body = item['body'] as String?;
      bool modified = false;

      // Map UUID placeholder in URL
      if (endpoint.contains('/$localId')) {
        endpoint = endpoint.replaceFirst('/$localId', '/$remoteId');
        modified = true;
      }

      // Map UUID placeholder in JSON Body
      if (body != null && body.contains(localId)) {
        try {
          final Map<String, dynamic> jsonBody = jsonDecode(body);
          bool jsonModified = false;

          if (jsonBody['clientid']?.toString() == localId) {
            jsonBody['clientid'] = remoteId;
            jsonModified = true;
          }
          if (jsonBody['invoiceid']?.toString() == localId) {
            jsonBody['invoiceid'] = remoteId;
            jsonModified = true;
          }
          if (jsonBody['id_member']?.toString() == localId) {
            jsonBody['id_member'] = remoteId;
            jsonModified = true;
          }
          if (jsonBody['id_pos']?.toString() == localId) {
            // Keep UUID but maybe link internal remoteId here too
          }

          if (jsonModified) {
            body = jsonEncode(jsonBody);
            modified = true;
          }
        } catch (_) {
          // Safely ignore parsing or non-Map failures
        }
      }

      if (modified) {
        debugPrint(
            "SyncService: Remapped sync item $id ($endpoint) from local placeholder $localId to remote ID $remoteId");
        await _dbService.update(
            'sync_queue',
            {
              'endpoint': endpoint,
              'body': body,
              'status': 'pending',
              'retry_count': 0,
            },
            'id = ?',
            [id]);
      }
    }
    // Don't call processQueue recursively here, it's called by the main loop re-query
  }

  Future<void> _updateLocalIdAfterSync(
      String localId, String remoteId, String endpoint,
      {String? remoteNumber}) async {
    if (endpoint.contains('customers')) {
      final remoteIdInt = int.parse(remoteId);
      final localIdInt = int.tryParse(localId);

      // We update by id_member if localId is numeric, OR by id_pos if it's a UUID
      String whereClause = 'id_member = ?';
      dynamic whereArg = localIdInt ?? localId;
      if (localIdInt == null) {
        whereClause = 'id_pos = ?';
      }

      await _dbService.update('members',
          {'id_member': remoteIdInt, 'is_synced': 1}, whereClause, [whereArg]);

      // ALSO update all transactions using this localId
      await _dbService.update(
          'transactions', {'id_member': remoteIdInt}, whereClause, [whereArg]);

      // CRITICAL FIX: Update in-memory state of HomeController if it's holding the stale localId
      if (Get.isRegistered<HomeController>()) {
        final homeCtrl = Get.find<HomeController>();
        if (homeCtrl.memberId.value.toString() == localId) {
          if (remoteIdInt != 0) {
            homeCtrl.memberId.value = remoteIdInt;
            if (homeCtrl.selectedMember.value != null) {
              homeCtrl.selectedMember.value = homeCtrl.selectedMember.value!.copyWith(
                idMember: remoteIdInt
              );
            }
            debugPrint("SyncService: Updated HomeController in-memory customer ID from $localId to $remoteId");
          }
        }
      }
      
      // CRITICAL FIX: Update MemberController's in-memory list
      if (Get.isRegistered<MemberController>()) {
        final memberCtrl = Get.find<MemberController>();
        if (localIdInt != null && remoteIdInt != 0) {
          final index = memberCtrl.memberModelList.indexWhere((m) => m.idMember == localIdInt);
          if (index != -1) {
            memberCtrl.memberModelList[index] = memberCtrl.memberModelList[index].copyWith(idMember: remoteIdInt);
            memberCtrl.memberModelList.refresh();
          }
          if (memberCtrl.selectedMember.value?.idMember == localIdInt) {
            memberCtrl.selectedMember.value = memberCtrl.selectedMember.value!.copyWith(idMember: remoteIdInt);
          }
        }
      }
    } else if (endpoint.contains('pos_order')) {
      // Save remote invoice ID back to local transactions table
      final remoteIdInt = int.tryParse(remoteId);
      if (remoteIdInt != null) {
        final Map<String, dynamic> updateData = {
          'id_penjualan_remote': remoteIdInt,
          'is_synced': 1
        };
        if (remoteNumber != null) {
          updateData['remote_number'] = remoteNumber;
        }

        // Handle both numeric ID and UUID (id_pos)
        final localIdInt = int.tryParse(localId);
        String? idPosForPayment;

        if (localIdInt != null) {
          await _dbService.update(
              'transactions', updateData, 'id_penjualan = ?', [localIdInt]);
          final txs = await _dbService.query('transactions', columns: ['id_pos'], where: 'id_penjualan = ?', whereArgs: [localIdInt]);
          if (txs.isNotEmpty) idPosForPayment = txs.first['id_pos']?.toString();
        } else {
          await _dbService
              .update('transactions', updateData, 'id_pos = ?', [localId]);
          idPosForPayment = localId;
        }

        // Clean up pos_payments in SQLite so it looks correct in Inspector
        if (idPosForPayment != null && idPosForPayment.isNotEmpty) {
           await _dbService.update('pos_payments', {'invoiceid': remoteId}, 'id_pos = ?', [idPosForPayment]);
        }
        debugPrint(
            'SyncService: pos_order synced — local $localId → remote #$remoteId ${remoteNumber ?? ''}');
      }
    } else if (endpoint.contains('pos_transaction')) {
      // Handle both numeric ID and UUID (id_pos) for payments
      final localIdInt = int.tryParse(localId);
      if (localIdInt != null) {
        await _dbService.update(
            'pos_payments', {'is_synced': 1}, 'id = ?', [localIdInt]);

        // Also update the parent transaction status to 2 (Paid/Closed)
        // Look up id_pos from the payment row to link back to the transaction
        final paymentRows = await _dbService
            .query('pos_payments', where: 'id = ?', whereArgs: [localIdInt]);
        if (paymentRows.isNotEmpty) {
          final idPos = paymentRows.first['id_pos']?.toString();
          if (idPos != null && idPos.isNotEmpty) {
            await _dbService.update('transactions',
                {'status': 2, 'is_synced': 1}, 'id_pos = ?', [idPos]);
            debugPrint(
                'SyncService: pos_transaction synced — transaction $idPos marked as Paid (status=2)');
          }
        }
      } else {
        await _dbService.update(
            'pos_payments', {'is_synced': 1}, 'id_pos = ?', [localId]);
        // Update transaction status directly by id_pos
        await _dbService.update('transactions', {'status': 2, 'is_synced': 1},
            'id_pos = ?', [localId]);
        debugPrint(
            'SyncService: pos_transaction synced — transaction $localId marked as Paid (status=2)');
      }
      debugPrint(
          'SyncService: pos_transaction synced — payment local $localId');
    } else if (endpoint.contains('pos_shift_logs')) {
      final localIdInt = int.tryParse(localId);
      final remoteIdInt = int.tryParse(remoteId);
      if (localIdInt != null) {
        await _dbService.update(
            'shift_sessions',
            {'is_synced': 1, 'id_remote': remoteIdInt},
            'id_shift = ?',
            [localIdInt]);
        debugPrint(
            'SyncService: pos_shift_logs synced — local $localId -> remote $remoteId');
      }
    }
  }

  Future<void> pullRemotePayments() async {
    syncStatus.value = "Pulling Remote Payments...";
    try {
      final response = await _apiService.getPosTransaction();
      if (response.responsestate == Constants.successState &&
          response.data != null) {
        List remotePayments = [];
        if (response.data is List) {
          remotePayments = response.data;
        } else if (response.data is Map) {
          final dynamic dataRaw =
              response.data['data'] ?? response.data['items'];
          if (dataRaw is List) {
            remotePayments = dataRaw;
          }
        }

        final db = await _dbService.database;
        final batch = db.batch();

        // Clear synced payments to avoid duplicates while keeping local-only ones
        batch.delete('pos_payments', where: 'is_synced = 1');

        for (var p in remotePayments) {
          batch.insert('pos_payments', {
            'id_pos': p['id_pos']?.toString(),
            'invoiceid': p['invoiceid']?.toString(),
            'amount': p['amount']?.toString(),
            'paymentmode': p['paymentmode']?.toString(),
            'paymentmethod': p['paymentmethod']?.toString(),
            'date': p['date']?.toString(),
            'daterecorded': p['daterecorded']?.toString(),
            'note': p['note']?.toString(),
            'transactionid': p['transactionid']?.toString(),
            'is_synced': 1,
          });
        }
        await batch.commit(noResult: true);
        syncStatus.value = "Payments Updated (${remotePayments.length})";
      }
    } catch (e) {
      debugPrint("SyncService: Error in pullRemotePayments: $e");
      syncStatus.value = "Payment Sync Error";
    }
  }

  Future<void> pullCreditNotes() async {
    syncStatus.value = "Pulling Credit Notes...";
    final response = await _apiService.getCreditNotes();
    if (response.responsestate == Constants.successState &&
        response.data != null) {
      final List creditNotes = response.data;
      final db = await _dbService.database;
      final batch = db.batch();

      batch.delete('pos_credit_notes');

      for (var cn in creditNotes) {
        batch.insert('pos_credit_notes', {
          'id_credit_note': _toInt(cn['id']),
          'clientid': cn['clientid']?.toString(),
          'formatted_number': cn['formatted_number']?.toString(),
          'datecreated': cn['datecreated']?.toString(),
          'date': cn['date']?.toString(),
          'subtotal':
              double.tryParse(cn['subtotal']?.toString() ?? '0')?.toInt() ?? 0,
          'total':
              double.tryParse(cn['total']?.toString() ?? '0')?.toInt() ?? 0,
          'status': cn['status']?.toString(),
          'reference_no': cn['reference_no']?.toString(),
        });
      }
      await batch.commit(noResult: true);
      syncStatus.value = "Credit Notes Updated";
    }
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return double.tryParse(value)?.toInt() ?? 0;
    return 0;
  }

  void _logSyncCall(String method, Uri uri, dynamic body,
      {String? response, int? statusCode}) {
    final timestamp = DateTime.now().toString();
    debugPrint('');
    debugPrint('=== [DEBUG SYNC API CALL] ===');
    debugPrint('Time: $timestamp');
    debugPrint('Command: [$method] $uri');
    if (body != null && body is! String) {
      debugPrint('Payload: ${jsonEncode(body)}');
    } else if (body is String) {
      debugPrint('Payload: $body');
    }
    if (response != null) {
      debugPrint('Status Code: $statusCode');
      debugPrint('Response: $response');
    }
    debugPrint('==============================');
    debugPrint('');
  }

  /// Deletes orders older than 24 hours from local storage,
  /// UNLESS they are still active (not paid/cancelled).
  Future<void> _cleanupOldOrders() async {
    try {
      final db = await _dbService.database;

      // 1. Delete transactions older than 30 days that are already Paid (2) or Cancelled (5)
      // We use datetime('now', '-30 days', 'localtime') to match the UI filter
      final deletedCount = await db.rawDelete("""
        DELETE FROM transactions 
        WHERE tgl_penjualan < datetime('now', '-30 days', 'localtime') 
        AND (status = 2 OR status = 5)
      """);

      if (deletedCount > 0) {
        debugPrint("SyncService: Cleaned up $deletedCount old closed orders.");
        // 2. Orphan cleanup for transaction_details
        await db.execute("""
          DELETE FROM transaction_details 
          WHERE id_penjualan NOT IN (SELECT id_penjualan FROM transactions)
        """);
      }
    } catch (e) {
      debugPrint("SyncService: Error during order cleanup: $e");
    }
  }

  Future<void> syncPaymentModes() async {
    try {
      final response = await _apiService.getPosPaymentModes();
      if (response.responsestate == Constants.successState &&
          response.data != null) {
        final List modes = response.data;
        final db = await _dbService.database;
        final batch = db.batch();

        // Clear existing modes
        batch.delete('payment_modes');

        for (var mode in modes) {
          batch.insert('payment_modes', {
            'id': mode['id']?.toString(),
            'name': mode['name']?.toString(),
            'description': mode['description']?.toString(),
            'active': mode['active']?.toString(),
            'selected_by_default': mode['selected_by_default']?.toString(),
          });
        }
        await batch.commit(noResult: true);
        debugPrint("SyncService: Payment modes synchronized");

        // Notify UI if ShiftAuditController is active
        syncStatus.value = "Payment Modes Updated";
      }
    } catch (e) {
      debugPrint("SyncService Error in syncPaymentModes: $e");
    }
  }

  Future<void> syncStaff() async {
    try {
      syncStatus.value = "Fetching Staff...";
      final response = await _apiService.getStaff();
      if (response.responsestate == Constants.successState &&
          response.data != null) {
        final List staffList = response.data;
        final db = await _dbService.database;
        await db.transaction((txn) async {
          await txn.delete('staff');
          for (var s in staffList) {
            final staffId = s.id != null ? int.tryParse(s.id.toString()) : null;
            final row = <String, dynamic>{
              'firstname': s.firstname ?? '',
              'lastname': s.lastname ?? '',
              'email': s.email ?? '',
              'phonenumber': s.phonenumber ?? '',
              'role': s.role ?? '',
              'active': s.active ?? '1',
              'password': s.password ?? '',
              'pin': s.pin ?? '',
            };
            // Only include id if the API actually returned one (non-null, non-zero)
            if (staffId != null && staffId > 0) {
              row['id'] = staffId;
            }
            await txn.insert('staff', row,
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        });
        debugPrint("SyncService: Synced ${staffList.length} staff members.");
      }
    } catch (e) {
      debugPrint("SyncService Error in syncStaff: $e");
    }
  }

  Future<void> syncPromotions() async {
    try {
      syncStatus.value = "Fetching Promotions...";
      final db = await _dbService.database;

      final session = await db.query('user_session', limit: 1);
      debugPrint(
          "SyncService: Checking user_session for location... session exists: ${session.isNotEmpty}");
      if (session.isNotEmpty) {
        final idLocation = session.first['location']?.toString() ?? '';
        debugPrint("SyncService: Found location ID: '$idLocation'");
        if (idLocation.isNotEmpty) {
          final response = await _apiService.getPosPromotions(idLocation);
          debugPrint(
              "SyncService: getPosPromotions response status: ${response.responsestate}, message: ${response.message}");
          if (response.responsestate == Constants.successState &&
              response.data != null) {
            final List promos =
                response.data is List ? response.data : [response.data];
            debugPrint(
                "SyncService: Fetched ${promos.length} promotions from API. Saving to database...");
            await db.transaction((txn) async {
              await txn.delete('pos_promotions');
              for (var p in promos) {
                await txn.insert(
                    'pos_promotions',
                    {
                      'id': p['id']?.toString(),
                      'name': p['name']?.toString(),
                      'promo_type': p['promo_type']?.toString(),
                      'brands':
                          p['brands'] != null ? jsonEncode(p['brands']) : null,
                      'locations': p['locations'] != null
                          ? jsonEncode(p['locations'])
                          : null,
                      'description': p['description']?.toString(),
                      'terms_conditions': p['terms_conditions']?.toString(),
                      'items':
                          p['items'] != null ? jsonEncode(p['items']) : null,
                      'order_types': p['order_types'] != null
                          ? jsonEncode(p['order_types'])
                          : null,
                      'start_date': p['start_date']?.toString(),
                      'end_date': p['end_date']?.toString(),
                      'is_multiplied': p['is_multiplied']?.toString(),
                      'is_stackable': p['is_stackable']?.toString(),
                      'status': p['status']?.toString(),
                      'created_at': p['created_at']?.toString(),
                    },
                    conflictAlgorithm: ConflictAlgorithm.replace);
              }
            });
            debugPrint(
                "SyncService: Successfully saved ${promos.length} promotions to database.");
            syncStatus.value = "Promotions Updated";
          } else {
            debugPrint(
                "SyncService: Failed to fetch promotions. Response data was null or error state.");
          }
        } else {
          debugPrint("SyncService: location is empty in user_session");
        }
      }
    } catch (e) {
      debugPrint("SyncService Error in syncPromotions: $e");
    }
  }

  Future<void> pullRemoteExpenses() async {
    try {
      syncStatus.value = "Pulling Remote Expenses...";
      debugPrint("SyncService: Pulling Remote Expenses...");
      final response = await _apiService.getExpenses();

      if (response.responsestate == Constants.successState && response.data != null) {
        final List remoteExpenses = response.data;
        
        await _dbService.transaction((txn) async {
          // Instead of clearing all expenses, maybe we clear only remote ones?
          // For simplicity, if we pull all expenses, we can clear those that are already synced,
          // or we can just replace by remote_id if we have one. But our cash_flow table
          // uses auto-increment id, and we might not have a remote_id column. 
          // Wait, in my previous task, I added 'remote_id' column to cash_flow!
          // So we can check if it exists or we can just clear synced expenses and re-insert.
          
          await txn.delete('cash_flow', where: 'is_synced = ? OR remote_id IS NOT NULL', whereArgs: [1]);
          
          for (var item in remoteExpenses) {
            await txn.insert(
              'cash_flow',
              {
                'remote_id': int.tryParse(item['id']?.toString() ?? '0'),
                'id_shift': int.tryParse(item['id_shift']?.toString() ?? '0'),
                'expense_name': item['expense_name']?.toString() ?? '',
                'note': item['note']?.toString() ?? '',
                'category': item['category']?.toString() ?? '1',
                'date': item['date']?.toString() ?? '',
                'amount': double.tryParse(item['amount']?.toString() ?? '0')?.toInt() ?? 0,
                'addedfrom': item['addedfrom']?.toString() ?? '1',
                'is_synced': 1,
                // created_at needs to be preserved if available, otherwise use date or now
                'created_at': item['dateadded']?.toString() ?? item['created_at']?.toString() ?? DateTime.now().toIso8601String(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });
        debugPrint("SyncService: Successfully synced ${remoteExpenses.length} expenses.");
        syncStatus.value = "Expenses Updated";
      } else {
        debugPrint("SyncService: Failed to fetch expenses. Reason: ${response.message}");
      }
    } catch (e) {
      debugPrint("SyncService Error in pullRemoteExpenses: $e");
    }
  }
}
