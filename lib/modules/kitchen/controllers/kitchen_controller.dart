import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/core/services/sync_service.dart';

class KitchenController extends GetxController {
  final _dbService = Get.find<DatabaseService>();

  RxList<Map<String, dynamic>> activeOrders = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> doneOrders = <Map<String, dynamic>>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchKitchenOrders();
  }

  Future<void> fetchKitchenOrders() async {
    try {
      isLoading.value = true;
      
      // Fetch Active (0)
      final active = await _dbService.rawQuery('''
        SELECT 
          td.*, 
          t.tgl_penjualan, 
          t.id_pos, 
          t.remote_number, 
          t.label, 
          t.order_type as total_order_type,
          t.queue_number, t.order_note,
          p.nama_produk
        FROM transaction_details td
        JOIN transactions t ON t.id_penjualan = td.id_penjualan
        LEFT JOIN products p ON p.id_produk = td.id_produk
        WHERE td.kitchen_status = 0
        AND (t.status = 1 OR t.status = 2)
        ORDER BY t.tgl_penjualan ASC
      ''');

      // Fetch Done (1)
      final done = await _dbService.rawQuery('''
        SELECT 
          td.*, 
          t.tgl_penjualan, 
          t.id_pos, 
          t.remote_number, 
          t.label, 
          t.order_type as total_order_type,
          t.queue_number,
          p.nama_produk
        FROM transaction_details td
        JOIN transactions t ON t.id_penjualan = td.id_penjualan
        LEFT JOIN products p ON p.id_produk = td.id_produk
        WHERE td.kitchen_status = 1
        AND (t.status = 1 OR t.status = 2)
        ORDER BY t.tgl_penjualan DESC
        LIMIT 50
      ''');

      activeOrders.value = _groupByTransaction(active);
      doneOrders.value = _groupByTransaction(done);
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      debugPrint("KitchenController Error: $e");
    }
  }

  List<Map<String, dynamic>> _groupByTransaction(List<Map<String, dynamic>> raw) {
    Map<String, Map<String, dynamic>> groups = {};
    for (var item in raw) {
      String idPos = item['id_pos']?.toString() ?? "N/A";
      if (!groups.containsKey(idPos)) {
        groups[idPos] = {
          'id_pos': idPos,
          'tgl_penjualan': item['tgl_penjualan'],
          'remote_number': item['remote_number'],
          'label': item['label'],
          'order_type': item['total_order_type'],
          'queue_number': item['queue_number'],
          'order_note': item['order_note'],
          'items': <Map<String, dynamic>>[]
        };
      }
      (groups[idPos]!['items'] as List).add(item);
    }
    return groups.values.toList();
  }

  Future<void> markGroupAsDone(List<int> detailIds, {String? idPos}) async {
    try {
      await _dbService.transaction((txn) async {
        for (var id in detailIds) {
          await txn.update(
            'transaction_details',
            {'kitchen_status': 1},
            where: 'id_penjualan_detail = ?',
            whereArgs: [id],
          );
        }
      });
      await fetchKitchenOrders();
      if (idPos != null && idPos.isNotEmpty) {
        _syncKitchenStatus(idPos, '1');
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memperbarui status: $e");
    }
  }

  Future<void> markGroupAsActive(List<int> detailIds, {String? idPos}) async {
    try {
      await _dbService.transaction((txn) async {
        for (var id in detailIds) {
          await txn.update(
            'transaction_details',
            {'kitchen_status': 0},
            where: 'id_penjualan_detail = ?',
            whereArgs: [id],
          );
        }
      });
      await fetchKitchenOrders();
      if (idPos != null && idPos.isNotEmpty) {
        _syncKitchenStatus(idPos, '0');
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memperbarui status: $e");
    }
  }

  Future<void> _syncKitchenStatus(String idPos, String sentStatus) async {
    try {
      final txRow = await _dbService.query('transactions', where: 'id_pos = ?', whereArgs: [idPos]);
      if (txRow.isEmpty || txRow.first['id_penjualan_remote'] == null) return;
      
      final tx = txRow.first;
      final remoteId = tx['id_penjualan_remote'];
      final remoteNumber = tx['remote_number']?.toString() ?? remoteId.toString();
      final idPenjualan = tx['id_penjualan'];
      
      // Fetch details
      final details = await _dbService.rawQuery('''
        SELECT td.*, p.nama_produk
        FROM transaction_details td
        LEFT JOIN products p ON p.id_produk = td.id_produk
        WHERE td.id_penjualan = ?
      ''', [idPenjualan]);
      
      List<Map<String, dynamic>> itemsArray = [];
      for (int i = 0; i < details.length; i++) {
        final item = details[i];
        final bool isRefundItem = item['is_refund']?.toString() == '1';
        final qty = (item['jumlah'] as num).toDouble();
        final rate = (item['harga_jual'] as num).toDouble();
        
        Map<String, dynamic> mapItem = {
          'description': item['nama_produk'] ?? item['note'] ?? 'Product',
          'long_description': item['note'] ?? '',
          'qty': qty.toStringAsFixed(2),
          'rate': rate.toStringAsFixed(2),
          'order': (i + 1).toString(),
          'unit': '',
          'taxname': <String>[],
        };
        
        final remoteItemId = item['remote_item_id']?.toString() ?? '';
        if (remoteItemId.isNotEmpty && remoteItemId != '0' && remoteItemId != 'null') {
           mapItem['itemid'] = remoteItemId;
        }
        if (isRefundItem) {
           mapItem['is_refund'] = 1;
        }
        
        itemsArray.add(mapItem);
      }
      
      // Fetch member
      String billingStreet = "-";
      final clientId = tx['id_member'] ?? 1;
      final memberRow = await _dbService.query('members', where: 'id_member = ?', whereArgs: [clientId]);
      if (memberRow.isNotEmpty) {
         billingStreet = memberRow.first['alamat']?.toString() ?? "-";
         if (billingStreet.isEmpty) billingStreet = "-";
      }
      
      final subtotalVal = (tx['total_harga'] as num).toDouble();
      final totalVal = (tx['bayar'] as num).toDouble();
      double discountAmount = subtotalVal > totalVal ? subtotalVal - totalVal : 0;
      
      String dateStr = tx['tgl_penjualan']?.toString() ?? DateTime.now().toIso8601String();
      if (dateStr.contains('T')) {
          dateStr = dateStr.split('T')[0];
      } else if (dateStr.contains(' ')) {
          dateStr = dateStr.split(' ')[0];
      }
      
      final putBody = <String, dynamic>{
        'clientid': clientId.toString(),
        'date': dateStr,
        'currency': '3',
        'number': remoteNumber,
        'billing_street': billingStreet,
        'allowed_payment_modes': ['4'], 
        'items': itemsArray,
        'subtotal': subtotalVal.toStringAsFixed(2),
        'total': totalVal.toStringAsFixed(2),
        'discount_total': discountAmount.toStringAsFixed(2),
        'discount_percent': '0.00',
        'discount_type': 'fixed',
        'clientnote': tx['order_note'] ?? '',
        'terms': tx['order_type'] ?? 'Dine In',
        'sent': sentStatus,
      };

      if (Get.isRegistered<SyncService>()) {
        Get.find<SyncService>().enqueueCommand(
          method: 'PUT',
          endpoint: '/api/pos_order/$remoteId',
          body: putBody,
          localId: idPos,
        );
      }
    } catch (e) {
      debugPrint("KitchenController: Failed to enqueue sync for sent status: $e");
    }
  }

  Future<void> markAsDone(int detailId, {String? idPos}) async {
    await markGroupAsDone([detailId], idPos: idPos);
  }

  Future<void> markAsActive(int detailId, {String? idPos}) async {
    await markGroupAsActive([detailId], idPos: idPos);
  }
}
