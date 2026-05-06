import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/models/dashboard/dashboard_model.dart';
import 'package:semesta_pos/core/models/shared_user_model.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/core/services/remote/api_service.dart';
import 'package:semesta_pos/core/services/user_service.dart';


class HomeAdminController extends GetxController {
  RxBool isLoading = false.obs;
  final apiService = Get.find<ApiService>();
  final userService = Get.find<UserService>(); 
  final _dbService = Get.find<DatabaseService>();
  
  SharedUserModel sharedUserModel = SharedUserModel();
  Rx<DashboardModel> dashboardModel = const DashboardModel().obs;

  RxInt incomeToday = 0.obs;
  RxInt incomeMonth = 0.obs;
  RxInt totalMembers = 0.obs;
  RxInt totalTransactionsToday = 0.obs;
  RxInt totalTransactionsMonth = 0.obs;

  /// Payment mode breakdown (today & this month)
  RxList<Map<String, dynamic>> paymentBreakdownToday = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> paymentBreakdownMonth = <Map<String, dynamic>>[].obs;

  RxMap<String, dynamic> topProductToday = <String, dynamic>{'name': '-', 'qty': 0, 'progress': 0.0}.obs; 
  RxMap<String, dynamic> topProductMonth = <String, dynamic>{'name': '-', 'qty': 0, 'progress': 0.0}.obs;
  
  RxList<Map<String, dynamic>> recentTransactions = <Map<String, dynamic>>[].obs;
  
  RxString userName = "".obs;
  RxString userEmail = "".obs;

  String _capitalizeName(String name) {
    if (name.isEmpty) return "";
    return name.split(' ').map((word) {
      if (word.isEmpty) return "";
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Future<void> getUserData() async {
    final session = await userService.getUserSession();
    if (session != null) {
      final rawName = session['staff'] ?? 'User';
      userName.value = _capitalizeName(rawName);
      userEmail.value = session['email'] ?? '';
    } else {
      final userData = await userService.getSharedUserModel();
      userName.value = _capitalizeName(userData.userName);
      userEmail.value = 'admin@gmail.com';
    }
  }

  Future<void> getDashboardData() async {
    try {
      isLoading.value = true;
      
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final monthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}%";

      // ── Income: only PAID orders (status = 2), exclude cancelled (status = 5)
      final todayRes = await _dbService.rawQuery(
        "SELECT SUM(bayar) as total, COUNT(*) as cnt FROM transactions WHERE date(tgl_penjualan) = date(?) AND status = 2",
        [todayStr],
      );
      incomeToday.value = (todayRes.first['total'] as num?)?.toInt() ?? 0;
      totalTransactionsToday.value = (todayRes.first['cnt'] as num?)?.toInt() ?? 0;

      final monthRes = await _dbService.rawQuery(
        "SELECT SUM(bayar) as total, COUNT(*) as cnt FROM transactions WHERE tgl_penjualan LIKE ? AND status = 2",
        [monthStr],
      );
      
      // Calculate Credit Notes (Refunds) to subtract from total income
      int cnToday = 0;
      int cnMonth = 0;
      try {
         final cnTodayRes = await _dbService.rawQuery(
            "SELECT SUM(total) as total FROM pos_credit_notes WHERE date(coalesce(datecreated, date)) = date(?) AND status = '2'", [todayStr]);
         cnToday = (double.tryParse(cnTodayRes.first['total']?.toString() ?? '0') ?? 0).toInt();

         final cnMonthRes = await _dbService.rawQuery(
            "SELECT SUM(total) as total FROM pos_credit_notes WHERE coalesce(datecreated, date) LIKE ? AND status = '2'", [monthStr]);
         cnMonth = (double.tryParse(cnMonthRes.first['total']?.toString() ?? '0') ?? 0).toInt();
      } catch (e) {
        debugPrint("HomeAdminController: Error calculating credit notes: $e");
      }

      incomeToday.value = ((todayRes.first['total'] as num?)?.toInt() ?? 0) - cnToday;
      totalTransactionsToday.value = (todayRes.first['cnt'] as num?)?.toInt() ?? 0;

      incomeMonth.value = ((monthRes.first['total'] as num?)?.toInt() ?? 0) - cnMonth;
      totalTransactionsMonth.value = (monthRes.first['cnt'] as num?)?.toInt() ?? 0;

      final memberRes = await _dbService.rawQuery("SELECT COUNT(*) as count FROM members");
      totalMembers.value = (memberRes.first['count'] as num?)?.toInt() ?? 0;

      // ── Payment mode breakdown
      await _loadPaymentBreakdown(todayStr, monthStr);

      // ── Top Products (exclude cancelled)
      await _calculateTopProduct(todayStr, isMonth: false);
      await _calculateTopProduct(monthStr, isMonth: true);

      // ── Chart (paid-only)
      await _calculateChartData();

      // ── Recent Transactions: show all except deleted(5); cancelled shown with their status
      final recent = await _dbService.rawQuery('''
        SELECT t.*, m.nama as member_name,
               COALESCE(pp.paymentmethod, t.payment_method) as payment_method
        FROM transactions t 
        LEFT JOIN members m ON t.id_member = m.id_member
        LEFT JOIN (
          SELECT id_pos, invoiceid, paymentmethod 
          FROM pos_payments 
          GROUP BY id_pos, invoiceid
        ) pp ON (pp.id_pos = t.id_pos AND pp.id_pos IS NOT NULL) 
             OR (pp.invoiceid = t.remote_number AND pp.invoiceid IS NOT NULL AND pp.invoiceid != '')
        WHERE t.status != 5
        ORDER BY t.id_penjualan DESC LIMIT 8
      ''');
      recentTransactions.value = recent;

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      debugPrint("HomeAdminController Error: $e");
    }
  }

  Future<void> _loadPaymentBreakdown(String todayStr, String monthStr) async {
    try {
      // Deduplicate: one payment row per transaction, then group by method
      final todayBreakdown = await _dbService.rawQuery('''
        SELECT COALESCE(pp.method, t.payment_method, 'Cash') as method, 
               SUM(COALESCE(pp.amount, t.bayar)) as total, 
               COUNT(*) as cnt
        FROM transactions t
        LEFT JOIN (
          SELECT id_pos, invoiceid, paymentmethod as method,
                 CAST(amount AS REAL) as amount
          FROM pos_payments
          GROUP BY id_pos, invoiceid
        ) pp ON (pp.id_pos = t.id_pos AND pp.id_pos IS NOT NULL)
             OR (pp.invoiceid = t.remote_number AND pp.invoiceid IS NOT NULL AND pp.invoiceid != '')
        WHERE date(t.tgl_penjualan) = date(?) AND t.status = 2
        GROUP BY method
        ORDER BY total DESC
      ''', [todayStr]);

      paymentBreakdownToday.value = todayBreakdown.map((r) => {
        'method': r['method']?.toString() ?? 'Other',
        'total': (r['total'] as num?)?.toInt() ?? 0,
        'cnt': (r['cnt'] as num?)?.toInt() ?? 0,
      }).toList();

      // Same dedup for month
      final monthBreakdown = await _dbService.rawQuery('''
        SELECT COALESCE(pp.method, t.payment_method, 'Cash') as method, 
               SUM(COALESCE(pp.amount, t.bayar)) as total, 
               COUNT(*) as cnt
        FROM transactions t
        LEFT JOIN (
          SELECT id_pos, invoiceid, paymentmethod as method,
                 CAST(amount AS REAL) as amount
          FROM pos_payments
          GROUP BY id_pos, invoiceid
        ) pp ON (pp.id_pos = t.id_pos AND pp.id_pos IS NOT NULL)
             OR (pp.invoiceid = t.remote_number AND pp.invoiceid IS NOT NULL AND pp.invoiceid != '')
        WHERE t.tgl_penjualan LIKE ? AND t.status = 2
        GROUP BY method
        ORDER BY total DESC
      ''', [monthStr]);

      paymentBreakdownMonth.value = monthBreakdown.map((r) => {
        'method': r['method']?.toString() ?? 'Other',
        'total': (r['total'] as num?)?.toInt() ?? 0,
        'cnt': (r['cnt'] as num?)?.toInt() ?? 0,
      }).toList();
    } catch (e) {
      debugPrint("HomeAdminController: _loadPaymentBreakdown error: $e");
    }
  }

  Future<void> _calculateTopProduct(String datePattern, {required bool isMonth}) async {
    final query = isMonth 
        ? '''SELECT p.nama_produk as productName, td.note, SUM(td.jumlah) as qty
             FROM transaction_details td
             JOIN transactions t ON td.id_penjualan = t.id_penjualan
             LEFT JOIN products p ON td.id_produk = p.id_produk
             WHERE t.tgl_penjualan LIKE ? AND t.status != 5
             GROUP BY td.id_produk, td.note ORDER BY qty DESC'''
        : '''SELECT p.nama_produk as productName, td.note, SUM(td.jumlah) as qty
             FROM transaction_details td
             JOIN transactions t ON td.id_penjualan = t.id_penjualan
             LEFT JOIN products p ON td.id_produk = p.id_produk
             WHERE date(t.tgl_penjualan) = date(?) AND t.status != 5
             GROUP BY td.id_produk, td.note ORDER BY qty DESC''';
    
    final results = await _dbService.rawQuery(query, [datePattern]);
    
    if (results.isNotEmpty) {
      final top = results.first;
      final totalQty = results.fold<num>(0, (sum, item) => sum + (item['qty'] as num)).toDouble();
      final popularity = totalQty > 0 ? (top['qty'] as num).toDouble() / totalQty : 0.0;
      
      String name = top['productName'] ?? 'Unknown';
      if (top['note'] != null && top['note'].toString().startsWith('REMOTE_ITEM:')) {
         name = top['note'].toString().substring(12);
      }
      
      final data = {
        'name': name,
        'qty': (top['qty'] as num).toInt(),
        'progress': popularity,
      };

      if (isMonth) {
        topProductMonth.value = data;
      } else {
        topProductToday.value = data;
      }
    } else {
      final empty = {'name': '-', 'qty': 0, 'progress': 0.0};
      if (isMonth) {
        topProductMonth.value = empty;
      } else {
        topProductToday.value = empty;
      }
    }
  }

  Future<void> _calculateChartData() async {
    final List<String> dates = [];
    final List<int> incomes = [];
    
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final displayStr = "${date.day}/${date.month}";
      
      final res = await _dbService.rawQuery(
        "SELECT SUM(bayar) as total FROM transactions WHERE date(tgl_penjualan) = date(?) AND status = 2",
        [dateStr],
      );
      
      dates.add(displayStr);
      incomes.add((res.first['total'] as num?)?.toInt() ?? 0);
    }

    dashboardModel.value = dashboardModel.value.copyWith(
      dataTanggal: dates,
      dataPendapatan: incomes,
    );
  }
}
