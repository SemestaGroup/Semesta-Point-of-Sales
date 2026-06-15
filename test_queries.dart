import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Gunakan perintah: dart run test_queries.dart <nama_file_sqlite>');
    print('Contoh: dart run test_queries.dart pos_database_1780369094396.sqlite');
    exit(1);
  }

  var dbPath = args[0];
  if (!File(dbPath).isAbsolute) {
    dbPath = [Directory.current.path, dbPath].join('\\');
  }
  
  if (!File(dbPath).existsSync()) {
    print('File tidak ditemukan: $dbPath');
    exit(1);
  }

  // Inisialisasi sqflite untuk Desktop/CLI
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;

  print('Membuka database: $dbPath...');
  var db = await databaseFactory.openDatabase(dbPath);

  final today = '2026-06-02';
  final month = '2026-06-%';

  print('\n==========================================');
  print('1. DASHBOARD: TODAY INCOME & PAYMENT METHOD');
  print('==========================================');
  final todayBreakdown = await db.rawQuery('''
    SELECT COALESCE(
             (SELECT paymentmethod FROM pos_payments WHERE id_pos = t.id_pos AND id_pos IS NOT NULL AND id_pos != '' LIMIT 1),
             (SELECT paymentmethod FROM pos_payments WHERE invoiceid = t.id_penjualan_remote AND invoiceid IS NOT NULL AND invoiceid != '' LIMIT 1),
             t.payment_method, 'Cash'
           ) as method, 
           SUM(t.bayar) as total, 
           COUNT(*) as cnt
    FROM transactions t
    WHERE date(t.tgl_penjualan) = date(?) AND t.status = 2
    GROUP BY method
    ORDER BY total DESC
  ''', [today]);
  
  double totalIncome = 0;
  for (var row in todayBreakdown) {
    print('- ${row['method']}: Rp ${row['total']} (${row['cnt']} trx)');
    totalIncome += (row['total'] as num).toDouble();
  }
  print('=> TOTAL INCOME TODAY: Rp $totalIncome');

  print('\n==========================================');
  print('2. DASHBOARD: RECENT TRANSACTIONS');
  print('==========================================');
  final recentTrx = await db.rawQuery('''
    SELECT t.id_penjualan, t.tgl_penjualan, t.order_type, t.bayar, t.status, m.nama as member_name,
           COALESCE(
             (SELECT paymentmethod FROM pos_payments WHERE id_pos = t.id_pos AND id_pos IS NOT NULL AND id_pos != '' LIMIT 1),
             (SELECT paymentmethod FROM pos_payments WHERE invoiceid = t.id_penjualan_remote AND invoiceid IS NOT NULL AND invoiceid != '' LIMIT 1),
             t.payment_method, 'Cash'
           ) as payment_method
    FROM transactions t 
    LEFT JOIN members m ON t.id_member = m.id_member
    WHERE t.status != 5
    ORDER BY t.id_penjualan DESC LIMIT 8
  ''');
  for (var row in recentTrx) {
    print('${row['id_penjualan']} | ${row['tgl_penjualan']} | ${row['member_name']} | ${row['order_type']} | ${row['payment_method']} | Rp ${row['bayar']}');
  }

  print('\n==========================================');
  print('3. ACTIVE ORDERS');
  print('==========================================');
  final activeOrders = await db.rawQuery('''
    SELECT t.id_penjualan, t.tgl_penjualan, m.nama as member_name, t.total_item, t.bayar
    FROM transactions t
    LEFT JOIN members m ON t.id_member = m.id_member
    WHERE t.status = 1
    ORDER BY t.id_penjualan DESC
  ''');
  for (var row in activeOrders) {
    print('Order #${row['id_penjualan']} | ${row['member_name']} | Rp ${row['bayar']} | Status: Pending');
  }

  print('\n==========================================');
  print('4. REPORTS & HISTORY: ORDER HISTORY');
  print('==========================================');
  final historyOrders = await db.rawQuery('''
    SELECT t.id_penjualan, t.tgl_penjualan, t.order_type, t.bayar, t.status,
           COALESCE(
             (SELECT paymentmethod FROM pos_payments WHERE id_pos = t.id_pos AND id_pos IS NOT NULL AND id_pos != '' LIMIT 1),
             (SELECT paymentmethod FROM pos_payments WHERE invoiceid = t.id_penjualan_remote AND invoiceid IS NOT NULL AND invoiceid != '' LIMIT 1),
             t.payment_method, 'Cash'
           ) as payment_method,
           (SELECT COUNT(*) FROM transaction_details td WHERE td.id_penjualan = t.id_penjualan AND td.is_refund = 1) as refund_count
    FROM transactions t
    WHERE date(t.tgl_penjualan) = date(?)
      AND (t.status IS NULL OR t.status != 5)
    GROUP BY t.id_penjualan 
    ORDER BY t.tgl_penjualan DESC
  ''', [today]);
  for (var row in historyOrders) {
    print('#${row['id_penjualan']} | ${row['tgl_penjualan']} | ${row['order_type']} | ${row['payment_method']} | Rp ${row['bayar']} | Refunds: ${row['refund_count']}');
  }

  print('\n==========================================');
  print('5. REPORTS & HISTORY: TOP PRODUCTS');
  print('==========================================');
  final topProducts = await db.rawQuery('''
    SELECT td.id_produk, p.nama_produk, SUM(td.jumlah) as total_sold
    FROM transaction_details td
    JOIN transactions t ON t.id_penjualan = td.id_penjualan
    JOIN products p ON p.id_produk = td.id_produk
    WHERE date(t.tgl_penjualan) = date(?) AND t.status = 2 AND td.is_refund = 0
    GROUP BY td.id_produk
    ORDER BY total_sold DESC
    LIMIT 10
  ''', [today]);
  for (var row in topProducts) {
    print('${row['nama_produk']} : ${row['total_sold']} terjual');
  }

  print('\n==========================================');
  print('6. RECONCILIATION / SHIFT');
  print('==========================================');
  final shiftData = await db.rawQuery('''
    SELECT * FROM shift_sessions ORDER BY id_shift DESC LIMIT 1
  ''');
  if (shiftData.isNotEmpty) {
    final shift = shiftData.first;
    print('Shift Terbaru: ${shift['shift_name']}');
    print('Start Time: ${shift['start_time']}');
    print('Status: ${shift['status'] == 1 ? "Closed" : "Open"}');
    
    if (shift['status'] == 1) {
      print('Total Cash Expected: Rp ${shift['total_cash_expected']}');
      print('Total Cash Actual: Rp ${shift['total_cash_actual']}');
    }
  } else {
    print('Tidak ada data shift.');
  }

  await db.close();
  print('\n=== Selesai ===');
}
