import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/core/services/sync_service.dart';
import 'package:semesta_pos/modules/dashboard/admin/controllers/dashboard_admin_controller.dart';
import 'package:semesta_pos/modules/dashboard/employee/controllers/dashboard_employee_controller.dart';
import 'package:semesta_pos/modules/home/employee/controllers/home_controller.dart';
import 'package:semesta_pos/routes/app_pages.dart';

class OrderController extends GetxController {
  DatabaseService get _dbService => Get.find<DatabaseService>();


  RxBool isLoading = false.obs;
  RxBool isSyncing = false.obs;
  RxList<Map<String, dynamic>> openOrders = <Map<String, dynamic>>[].obs;
  RxBool filterActiveOnly = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Initially load from local DB to avoid blinking
    getOrders(forceRemote: false);
  }

  Future<void> getOrders({bool forceRemote = false, String? query}) async {
    try {
      if (forceRemote) {
        isSyncing.value = true;
      } else {
        isLoading.value = true;
      }
 
      // 1. Pull latest unpaid orders from server IN THE BACKGROUND if forced
      if (forceRemote) {
        // We don't await this anymore, so the UI can immediately proceed to Step 2 (local query)
        Get.find<SyncService>().pullRemoteOrders(unpaidOnly: false).then((_) {
           // Re-query local DB once pull is finished
           _getOrdersFromLocal(query: query).then((newResult) {
             openOrders.value = newResult;
             isSyncing.value = false;
           });
        }).catchError((e) {
          debugPrint("OrderController: Failed to pull remote orders: $e");
          isSyncing.value = false;
          Get.snackbar(
              'Sync Failed', 'Koneksi bermasalah. Pastikan perangkat terhubung ke internet.',
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              icon: const Icon(Icons.error_outline, color: Colors.red));
        });
      }
 
      // 2. Query local DB for the unified view
      final result = await _getOrdersFromLocal(query: query);
      openOrders.value = result;
 
      if (Get.isRegistered<DashboardEmployeeController>()) {
        Get.find<DashboardEmployeeController>().updateActiveOrderCount();
      }
      if (Get.isRegistered<DashboardAdminController>()) {
        Get.find<DashboardAdminController>().updateActiveOrderCount();
      }
 
      isLoading.value = false;
      isSyncing.value = false;
    } catch (e) {
      isLoading.value = false;
      isSyncing.value = false;
      Get.snackbar('Error', 'Koneksi bermasalah. Silakan periksa jaringan internet Anda.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1));
    }
  }

  Future<List<Map<String, dynamic>>> _getOrdersFromLocal({String? query}) async {
    // Active orders are those where status is NOT 5 (Cancelled) and NOT 2 (Paid)
    String where = "";
    if (filterActiveOnly.value) {
      where = "(t.status != 5 AND t.status != 2)";
    } else {
      where = "(datetime(t.tgl_penjualan) >= datetime('now', '-24 hours', 'localtime') OR (t.status != 5 AND t.status != 2))";
    }
    List<dynamic> whereArgs = [];

    if (query != null && query.trim().isNotEmpty) {
      final q = "%${query.trim()}%";
      where += " AND (t.label LIKE ? OR t.id_pos LIKE ? OR t.remote_number LIKE ? OR m.nama LIKE ?)";
      whereArgs.addAll([q, q, q, q]);
    }

    final String sql = """
      SELECT t.*, m.nama as nama,
             CASE WHEN cn.id_credit_note IS NOT NULL THEN 1 ELSE 0 END as has_refund
      FROM transactions t
      LEFT JOIN members m ON t.id_member = m.id_member
      LEFT JOIN pos_credit_notes cn ON cn.reference_no = t.remote_number AND cn.status = '2'
      WHERE $where
      GROUP BY t.id_penjualan
      ORDER BY t.id_penjualan DESC
      LIMIT 50
    """;

    return await _dbService.rawQuery(sql, whereArgs);
  }

  Future<Map<String, dynamic>> _buildPutBody(Map<String, dynamic> order, int newStatus) async {
    final idPenjualan = order['id_penjualan'];
    final itemsList = await _dbService.query('transaction_details', where: 'id_penjualan = ?', whereArgs: [idPenjualan]);
    
    final itemsArray = <Map<String, dynamic>>[];
    for (int i = 0; i < itemsList.length; i++) {
      final item = itemsList[i];
      
      final mapItem = <String, dynamic>{
        'description': item['product_name'] ?? 'Product',
        'long_description': '',
        'qty': (item['jumlah'] as num).toDouble().toStringAsFixed(2),
        'rate': (item['harga_jual'] as num).toDouble().toStringAsFixed(2),
        'order': (i + 1).toString(),
        'unit': '',
        'taxname': <String>[],
      };
      
      if (item['is_refund']?.toString() == '1') {
        mapItem['is_refund'] = 1;
      }

      final remoteItemId = item['remote_item_id']?.toString() ?? '';
      if (remoteItemId.isNotEmpty && remoteItemId != '0' && remoteItemId != 'null') {
        mapItem['itemid'] = remoteItemId;
      }
      itemsArray.add(mapItem);
    }
    
    String number = order['id_penjualan_remote']?.toString() ?? '1';
    
    return <String, dynamic>{
      'clientid': (order['id_member'] ?? 1).toString(),
      'number': number,
      'date': order['tgl_penjualan']?.toString().split(' ')[0] ?? DateTime.now().toIso8601String().split('T')[0],
      'currency': '3',
      'status': newStatus,
      'billing_street': '-',
      'allowed_payment_modes': ['4'],
      'items': itemsArray,
      'subtotal': (order['total_harga'] as num? ?? 0).toDouble().toStringAsFixed(2),
      'total': (order['bayar'] as num? ?? 0).toDouble().toStringAsFixed(2)
    };
  }

  Future<void> deleteOrder(Map<String, dynamic> order) async {
    try {
      final idPenjualan = order['id_penjualan'];
      if (idPenjualan == null) return;

      // Soft cancel: Update local status to 5 instead of deleting
      await _dbService.update('transactions', 
          {'status': 5, 'is_synced': 0}, 
          'id_penjualan = ?', [idPenjualan]);

      // If already synced to API, queue a PUT command to update status to 5 (cancelled)
      final remoteId = order['id_penjualan_remote'];
      if (remoteId != null) {
        final putBody = await _buildPutBody(order, 5);
        final syncService = Get.find<SyncService>();
        await syncService.enqueueCommand(
          method: 'PUT',
          endpoint: '/api/pos_order/$remoteId',
          body: putBody,
          localId: idPenjualan,
        );
      }

      Get.snackbar(
        'Order Dibatalkan',
        'Order #$idPenjualan telah dibatalkan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.cancel_presentation_rounded, color: Colors.white),
      );
      // Refresh the list
      getOrders();
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus order: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> restoreOrder(Map<String, dynamic> order) async {
    try {
      final idPenjualan = order['id_penjualan'];
      if (idPenjualan == null) return;

      await _dbService.update('transactions', 
          {'status': 1, 'is_synced': 0}, 
          'id_penjualan = ?', [idPenjualan]);

      final remoteId = order['id_penjualan_remote'];
      if (remoteId != null) {
        final putBody = await _buildPutBody(order, 1);
        await Get.find<SyncService>().enqueueCommand(
          method: 'PUT',
          endpoint: '/api/pos_order/$remoteId',
          body: putBody,
          localId: idPenjualan,
        );
      }

      Get.snackbar('Order Dipulihkan', 'Order #$idPenjualan kini aktif kembali',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue.shade800,
          colorText: Colors.white);
      getOrders();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memulihkan order: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  void navigateToPos() {
    // Try Admin Dashboard first
    if (Get.isRegistered<DashboardAdminController>()) {
      final dashboardController = Get.find<DashboardAdminController>();
      dashboardController.stateSelectedIndex.value = 1; // Index 1 is POS
      dashboardController.isSidebarCollapsed.value = true;
      return;
    }

    // Try Employee Dashboard
    if (Get.isRegistered<DashboardEmployeeController>()) {
      final dashboardController = Get.find<DashboardEmployeeController>();
      dashboardController.stateSelectedIndex.value = 1; // Index 1 is POS
      dashboardController.isSidebarCollapsed.value = true;
      return;
    }

    // Fallback if no dashboard controller is in memory
    Get.offAllNamed(Routes.home);
  }

  void loadOrderIntoPos(Map<String, dynamic> order, {bool isRefundMode = false}) {
    try {
      // 1. Navigate to POS first
      navigateToPos();

      // 2. Load the transaction data into HomeController
      // Give a tiny delay for navigation to complete and controller to be ready
      Future.delayed(const Duration(milliseconds: 300), () {
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().loadTransaction(order, isRefundMode: isRefundMode);
        }
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to navigate to POS: $e');
    }
  }

  void refreshOrders() {
    getOrders(forceRemote: true);
  }
}
