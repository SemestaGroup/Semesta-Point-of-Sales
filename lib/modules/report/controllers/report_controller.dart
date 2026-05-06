import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/models/report/report_model.dart';
import 'package:semesta_pos/core/services/remote/api_service.dart';
import 'package:semesta_pos/core/services/local/database_service.dart';
import 'package:semesta_pos/core/util/constans.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:semesta_pos/modules/setting/controllers/setting_controller.dart';
import 'package:semesta_pos/core/services/app_service.dart';
import 'package:semesta_pos/core/services/user_service.dart';
import 'package:semesta_pos/core/services/sync_service.dart';
import 'package:semesta_pos/core/services/error_log_service.dart';

class ReportController extends GetxController {
  ApiService get apiService {
    if (!Get.isRegistered<ApiService>()) {
      Get.put(ApiService(), permanent: true);
    }
    return Get.find<ApiService>();
  }
  DatabaseService get _dbService {
    if (!Get.isRegistered<DatabaseService>()) {
      Get.put(DatabaseService(), permanent: true);
    }
    return Get.find<DatabaseService>();
  }


  RxList<ReportModel> reportModelList = <ReportModel>[].obs;
  RxBool isLoading = false.obs;
  RxBool isLoadingDatePicker = false.obs;
  TextEditingController controllerDate = TextEditingController();

  // MIGRATED FROM ORDER CONTROLLER
  RxList<Map<String, dynamic>> orders = <Map<String, dynamic>>[].obs;
  RxInt activeTab = 0.obs; // 0 for Order History, 1 for Payment History
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  RxString selectedPaymentMethod = "All".obs;
  RxList<Map<String, dynamic>> paymentModes = <Map<String, dynamic>>[].obs;
  RxInt rowsPerPage = 5.obs;
  RxInt currentPage = 1.obs;
  RxInt totalRows = 0.obs;

  List<Map<String, dynamic>> get paginatedOrders {
    // Determine which orders to render based on the current page
    int start = (currentPage.value - 1) * rowsPerPage.value;
    int end = start + rowsPerPage.value;
    if (start >= orders.length) return [];
    if (end > orders.length) end = orders.length;
    return orders.sublist(start, end);
  }

  void nextPage() {
    if (currentPage.value * rowsPerPage.value < orders.length) {
      currentPage.value++;
    }
  }

  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
    }
  }

  // TOP PRODUCTS DATA
  RxList<Map<String, dynamic>> topProducts = <Map<String, dynamic>>[].obs;

  // ANALYSIS DATA
  RxDouble todaySales = 0.0.obs;
  RxDouble yesterdaySales = 0.0.obs;
  RxDouble thisMonthSales = 0.0.obs;
  RxDouble lastMonthSales = 0.0.obs;

  // Chart data for comparing current period vs previous period
  RxList<double> currentPeriodChart = <double>[].obs;
  RxList<double> previousPeriodChart = <double>[].obs;
  RxString analysisViewMode = "Day".obs; // "Day" or "Month"
  
  RxBool isPrinting = false.obs;
  final appService = Get.find<AppService>();
  final userService = Get.find<UserService>();

  @override
  void onInit() {
    super.onInit();
    // getReport('invoices_report', tglAwal(), tglSekarang()); // DROPPED REDUNDANT API CALL

    // Default dates for history (MIGRATED)
    final now = DateTime.now();
    final firstDay = now;
    startDateController.text = _formatDate(firstDay);
    endDateController.text = _formatDate(now);
    getOrders();
    loadPaymentModes();
    
    // Automatically pull latest credit notes when opening reports
    if (Get.isRegistered<SyncService>()) {
      Get.find<SyncService>().pullCreditNotes().then((_) {
        // Refresh orders if credit notes were updated
        getOrders();
      }).catchError((e) {
        debugPrint("ReportController: Failed to pull credit notes: $e");
        // No snackbar here to avoid annoyance on every page load
      });
    }

    // Reactively reload if background sync finishes while the app is open (Fresh Install Fix)
    if (Get.isRegistered<SyncService>()) {
      ever(Get.find<SyncService>().syncStatus, (String status) {
        if (status == "Sync Complete" || status.contains("Updated")) {
          // If we only have the 'All' sentinel, reload from DB
          if (paymentModes.length <= 1) {
            loadPaymentModes();
          }
        }
      });
    }
  }

  Future<void> loadPaymentModes() async {
    try {
      final result = await _dbService.query('payment_modes',
          where: 'active = ?', whereArgs: ['1'], orderBy: 'name ASC');
      // Always prepend the 'All' sentinel so the UI can reset filter
      paymentModes.value = [
        {'id': 'all', 'name': 'All'},
        ...result,
      ];
    } catch (e) {
      debugPrint('ReportController: Failed to load payment modes: $e');
    }
  }

  // --- REPORT API LOGIC ---
  RxList<dynamic> rawReportData = <dynamic>[].obs;
  RxString selectedReportType = "invoices_report".obs;

  Future<void> getReport(String type, String tglAwal, String tglAkhir) async {
    reportModelList.clear();
    rawReportData.clear();
    isLoading.value = true;
    try {
      final responseApiModel = await apiService.getReport(type, tglAwal, tglAkhir);
      isLoading.value = false;
      if (responseApiModel.responsestate == Constants.successState) {
        if (responseApiModel.data is List) {
          rawReportData.addAll(responseApiModel.data);
        }
      } else {
        Get.snackbar('Error', responseApiModel.message.toString());
      }
    } catch (e) {
      isLoading.value = false;
      debugPrint('Error caught in ReportController.getReport: $e');
      Get.snackbar('Modus Offline', 'Tidak dapat mengambil data laporan dari server. Beberapa laporan mungkin tidak tersedia karena koneksi terputus.');
    }
  }

  // --- ORDER HISTORY LOCAL LOGIC (MIGRATED) ---
  Future<void> getOrders() async {
    try {
      isLoading.value = true;
      String startDate = startDateController.text;
      String endDate = endDateController.text;

      debugPrint("ReportController: Querying orders from $startDate to $endDate");

      // LEFT JOIN subquery of pos_payments to get one payment method per transaction
      String sql = '''
        SELECT t.*,
               COALESCE(pp.paymentmethod, t.payment_method) as payment_method,
               (SELECT COUNT(*) FROM transaction_details td WHERE td.id_penjualan = t.id_penjualan AND td.is_refund = 1) as refund_count
        FROM transactions t
        LEFT JOIN (
          SELECT id_pos, invoiceid, paymentmethod
          FROM pos_payments
          GROUP BY id_pos, invoiceid
        ) pp ON (pp.id_pos = t.id_pos AND pp.id_pos IS NOT NULL) 
             OR (pp.invoiceid = t.remote_number AND pp.invoiceid IS NOT NULL AND pp.invoiceid != '')
        WHERE ((date(t.tgl_penjualan) >= date(?)
          AND date(t.tgl_penjualan) <= date(?))
          OR t.status = 1)
          AND (t.status IS NULL OR t.status != 5)
      ''';
      List<dynamic> args = [startDate, endDate];

      if (!userService.isManagerialRole()) {
        sql += ' AND t.id_user = ?';
        args.add(userService.getPrefInt(Constants.userId));
      }

      // Payment method filter: match against pos_payments.paymentmethod
      final filterMethod = selectedPaymentMethod.value;
      if (filterMethod.isNotEmpty && filterMethod != 'All') {
        sql += ' AND LOWER(pp.paymentmethod) = LOWER(?)';
        args.add(filterMethod);
      }

      sql += ' ORDER BY t.tgl_penjualan DESC';

      final result = await _dbService.rawQuery(sql, args);
      List<Map<String, dynamic>> combined = List<Map<String, dynamic>>.from(result);

      // Fetch Credit Notes (Refunds) — isolated so a missing table won't break the main report
      try {
        const String cnSql = '''
          SELECT cn.*, t.id_member as original_customer_id
          FROM pos_credit_notes cn
          LEFT JOIN transactions t ON t.remote_number = cn.reference_no
          WHERE (date(coalesce(cn.datecreated, cn.date)) >= date(?) AND date(coalesce(cn.datecreated, cn.date)) <= date(?))
            AND cn.status = '2'
        ''';
        final cnResult = await _dbService.rawQuery(cnSql, [startDate, endDate]);

        for (var cn in cnResult) {
          combined.add({
            'id_penjualan': cn['id_credit_note'],
            'id_member': cn['original_customer_id'] ?? int.tryParse(cn['clientid']?.toString() ?? ''),
            'remote_number': cn['formatted_number'],
            'tgl_penjualan': cn['datecreated'] ?? cn['date'],
            'order_type': 'Refund',
            'status': 2,
            'bayar': -(double.tryParse(cn['total']?.toString() ?? '0')?.toInt() ?? 0),
            'total_harga': -(double.tryParse(cn['subtotal']?.toString() ?? '0')?.toInt() ?? 0),
            'payment_method': 'Refund',
            'is_refund': true,
          });
        }
      } catch (cnErr) {
        debugPrint('ReportController: credit notes query failed (table may not exist yet): $cnErr');
      }

      // Sort combined list descending by date
      combined.sort((a, b) {
        DateTime dateA = DateTime.tryParse(a['tgl_penjualan']?.toString() ?? '') ?? DateTime(2000);
        DateTime dateB = DateTime.tryParse(b['tgl_penjualan']?.toString() ?? '') ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

      orders.value = combined;
      totalRows.value = combined.length;

      _computeAnalysis(combined);

      await getTopProducts(startDate, endDate);

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      debugPrint('ReportController getOrders error: $e');
      Get.snackbar("Error", "Koneksi bermasalah. Gagal memuat data dari server.");
    }
  }

  Future<void> getTopProducts(String startDate, String endDate) async {
    try {
       String sql = '''
          SELECT 
            COALESCE(p.nama_produk, td.note) as item_name, 
            SUM(td.jumlah) as qty_sold, 
            SUM(td.subtotal) as total_revenue
          FROM transaction_details td
          INNER JOIN transactions t ON t.id_penjualan = td.id_penjualan
          LEFT JOIN products p ON p.id_produk = td.id_produk
          WHERE date(t.tgl_penjualan) >= date(?) 
            AND date(t.tgl_penjualan) <= date(?)
            AND (t.status = 2 OR t.status = 3)
       ''';
       List<dynamic> args = [startDate, endDate];

       if (!userService.isManagerialRole()) {
         sql += ' AND t.id_user = ?';
         args.add(userService.getPrefInt(Constants.userId));
       }

       sql += ' GROUP BY td.id_produk, item_name ORDER BY qty_sold DESC LIMIT 50';
       
       final result = await _dbService.rawQuery(sql, args);
       topProducts.value = result;
    } catch (e) {
       debugPrint("Failed to load top products: $e");
    }
  }

  Future<void> selectDate(
      BuildContext context, TextEditingController textController) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF482CD9)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      textController.text = _formatDate(picked);
    }
  }

  void filterOrders() {
    currentPage.value = 1;
    getOrders();
  }

  void changeTab(int index) {
    activeTab.value = index;
    currentPage.value = 1;
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String tglSekarang() => _formatDate(DateTime.now());
  String tglAwal() {
    DateTime now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
  }

  void _computeAnalysis(List<Map<String, dynamic>> allTx) {
    DateTime now = DateTime.now();
    String today = _formatDate(now);
    String yesterday = _formatDate(now.subtract(const Duration(days: 1)));
    
    String thisMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    String lastMonthDateRaw = now.month == 1 ? "${now.year - 1}-12" : "${now.year}-${(now.month - 1).toString().padLeft(2, '0')}";

    double tSales = 0;
    double ySales = 0;
    double tmSales = 0;
    double lmSales = 0;

    for (var tx in allTx) {
      // Include status 2 (Paid) and 3 (Completed)
      final status = tx['status'];
      if (status == 2 || status == 3) {
        String fullDate = tx['tgl_penjualan']?.toString() ?? "";
        if (fullDate.isEmpty) continue;
        
        DateTime? dt = DateTime.tryParse(fullDate);
        if (dt == null) continue;
        
        String dateOnly = _formatDate(dt);
        String monthOnly = dateOnly.substring(0, 7);
        
        // Use bayar if available, fallback to total_harga
        double total = double.tryParse(tx['bayar']?.toString() ?? "0") ?? 0;
        if (total == 0) {
          total = double.tryParse(tx['total_harga']?.toString() ?? "0") ?? 0;
        }

        if (dateOnly == today) tSales += total;
        if (dateOnly == yesterday) ySales += total;
        
        if (monthOnly == thisMonth) tmSales += total;
        if (monthOnly == lastMonthDateRaw) lmSales += total;
      }
    }

    todaySales.value = tSales;
    yesterdaySales.value = ySales;
    thisMonthSales.value = tmSales;
    lastMonthSales.value = lmSales;
    
    // Default chart data to comparing today vs yesterday hours
    _computeChartData(allTx, analysisViewMode.value);
  }

  void toggleAnalysisMode(String mode) {
    analysisViewMode.value = mode;
    _computeChartData(orders, mode);
  }

  void _computeChartData(List<Map<String, dynamic>> allTx, String mode) {
    DateTime now = DateTime.now();
    currentPeriodChart.clear();
    previousPeriodChart.clear();
    
    if (mode == "Day") {
      // 0 to 23 hours
      List<double> curr = List.filled(24, 0.0);
      List<double> prev = List.filled(24, 0.0);
      
      String today = _formatDate(now);
      String yesterday = _formatDate(now.subtract(const Duration(days: 1)));
      
      for (var tx in allTx) {
        String fullDateStr = tx['tgl_penjualan']?.toString() ?? "";
        DateTime? dt = DateTime.tryParse(fullDateStr);
        if (dt == null) continue;
        
        String dateOnly = _formatDate(dt);
        int hour = dt.hour;
        
        final status = tx['status'];
        if (status != 2 && status != 3) continue;

        double total = double.tryParse(tx['bayar']?.toString() ?? "0") ?? 0;
        if (dateOnly == today) curr[hour] += total;
        if (dateOnly == yesterday) prev[hour] += total;
      }
      
      currentPeriodChart.addAll(curr);
      previousPeriodChart.addAll(prev);
    } else {
      // Month (1-31 days)
      int currDays = DateUtils.getDaysInMonth(now.year, now.month);
      
      DateTime lastMonthDate = DateTime(now.month == 1 ? now.year - 1 : now.year, now.month == 1 ? 12 : now.month - 1);
      int prevDays = DateUtils.getDaysInMonth(lastMonthDate.year, lastMonthDate.month);
      
      List<double> curr = List.filled(currDays, 0.0);
      List<double> prev = List.filled(prevDays, 0.0);
      
      String thisMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
      String lastMonthRaw = "${lastMonthDate.year}-${lastMonthDate.month.toString().padLeft(2, '0')}";
      
      for (var tx in allTx) {
         String fullDateStr = tx['tgl_penjualan']?.toString() ?? "";
         DateTime? dt = DateTime.tryParse(fullDateStr);
         if (dt == null) continue;
         
         String dateOnly = _formatDate(dt);
         String monthOnly = dateOnly.substring(0, 7);
         int day = dt.day;
         
         final status = tx['status'];
         if (status != 2 && status != 3) continue;

         double total = double.tryParse(tx['bayar']?.toString() ?? "0") ?? 0;
         if (monthOnly == thisMonth && day <= currDays) curr[day-1] += total;
         if (monthOnly == lastMonthRaw && day <= prevDays) prev[day-1] += total;
      }
      currentPeriodChart.addAll(curr);
      previousPeriodChart.addAll(prev);
    }
  }

  Future<Map<String, dynamic>> fetchOrderFullDetails(int idPenjualan, dynamic idMember, {bool isRefund = false, double refundTotal = 0}) async {
    List<Map<String, dynamic>> items = [];
    
    // 1. Fetch items
    if (isRefund) {
       items = [
         {
           'jumlah': 1,
           'nama_produk': 'Refund (Credit Note)',
           'note': 'Generated from remote server',
           'subtotal': refundTotal.abs(),
           'is_refund': 1,
         }
       ];
    } else {
      final dbResult = await _dbService.rawQuery('''
        SELECT td.*, p.nama_produk, p.img 
        FROM transaction_details td
        LEFT JOIN products p ON p.id_produk = td.id_produk
        WHERE td.id_penjualan = ?
      ''', [idPenjualan]);
      items = List<Map<String, dynamic>>.from(dbResult);
    }

    // 2. Fetch member info
    Map<String, dynamic>? member;
    if (idMember != null) {
      final memberResult = await _dbService.query('members', 
          where: 'id_member = ?', whereArgs: [idMember]);
      if (memberResult.isNotEmpty) {
        member = memberResult.first;
      }
    }

    return {
      'items': items,
      'member': member,
    };
  }

  Future<void> printReceiptOnly(Map<String, dynamic> order, List items, {Map<String, dynamic>? member}) async {
    try {
      isPrinting.value = true;
      final settingCtrl = Get.find<SettingController>();
      final cashierPrinter = settingCtrl.getPrinterForRole('cashier');
      
      if (cashierPrinter == null) {
        Get.snackbar('No Cashier Printer', 'Please configure a printer with the Cashier role in Settings.');
        isPrinting.value = false;
        return;
      }

      final profile = await CapabilityProfile.load();
      final is80mm = cashierPrinter.paperSize == '80mm';
      final paperSize = is80mm ? PaperSize.mm80 : PaperSize.mm58;
      
      final int maxChars = is80mm ? 48 : 32;
      final int nameWidth = is80mm ? 35 : 25;

      final generator = Generator(paperSize, profile);
      List<int> bytes = [];

      // 1. Logo
      final logoUrl = userService.getPrefString('pos_brand_logo');
      if (logoUrl.isNotEmpty) {
        try {
          final res = await http.get(Uri.parse(logoUrl)).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200) {
            final decodedImage = img.decodeImage(res.bodyBytes);
            if (decodedImage != null) {
              final resized = img.copyResize(decodedImage, width: 250);
              bytes += generator.image(resized);
            }
          }
        } catch (_) {}
      }

      // 2. Header
      String companyName = userService.getPrefString(Constants.posCompanyName);
      if (companyName == 'Guest' || companyName.isEmpty) companyName = appService.appModel.value.namaPerusahaan;
      if (companyName.isEmpty) companyName = 'SEMESTA POS';
      String address = userService.getPrefString(Constants.posAddress);
      if (address == 'Guest') address = '';
      String phone = userService.getPrefString(Constants.posPhoneNumber);
      if (phone == 'Guest') phone = '';

      final String lineSeparator = '-' * maxChars;

      bytes += generator.text(companyName, styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
      if (address.isNotEmpty) bytes += generator.text(address, styles: const PosStyles(align: PosAlign.center));
      if (phone.isNotEmpty) bytes += generator.text(phone, styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('COPY RECEIPT', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text(lineSeparator, styles: const PosStyles(align: PosAlign.center));

      // 3. Order Info
      final String fullDateStr = order['tgl_penjualan']?.toString() ?? "";
      DateTime dt = DateTime.tryParse(fullDateStr) ?? DateTime.now();
      final dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      
      final String idPos = order['id_pos']?.toString() ?? order['id_penjualan']?.toString() ?? '---';
      final orderCode = idPos.length >= 6 ? idPos.substring(idPos.length - 6).toUpperCase() : idPos;

      final orderTypeStr = order['order_type']?.toString() ?? "Dine In";
      final queueNumber = order['queue_number']?.toString() ?? "-";

      final int idMember = int.tryParse(order['id_member']?.toString() ?? "0") ?? 0;
      final isWalkIn = idMember == 0 || idMember == 1;
      final customerName = isWalkIn ? "Walk In Customer" : (member?['nama']?.toString() ?? 'Customer #$idMember');

      bytes += generator.row([
        PosColumn(text: '$dateStr $timeStr', width: 7, styles: const PosStyles(align: PosAlign.left)),
        PosColumn(text: 'Q: $queueNumber', width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
      bytes += generator.text('Order Type: $orderTypeStr', styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text('Receipt No: $orderCode', styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text('Cashier   : ${userService.getPrefString(Constants.userName)}', styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text('Customer  : $customerName', styles: const PosStyles(align: PosAlign.left));
      
      final orderNoteStr = order['note']?.toString() ?? "";
      if (orderNoteStr.isNotEmpty) {
        bytes += generator.text('Note      : $orderNoteStr', styles: const PosStyles(align: PosAlign.left));
      }
      bytes += generator.text(lineSeparator, styles: const PosStyles(align: PosAlign.center));

      // 4. Items
      for (var item in items) {
        final double qty = double.tryParse(item['jumlah']?.toString() ?? "1") ?? 1;
        final String name = item['nama_produk']?.toString() ?? item['note']?.toString() ?? "Item";
        final int subtotal = (double.tryParse(item['subtotal']?.toString() ?? "0") ?? 0).toInt();

        final String prefix = '${qty.toInt()}x ';
        
        // 8/12 of the line is for the item name, 4/12 is for the price.
        final int maxNameLen = (is80mm ? 32 : 24) - prefix.length;
        String displayName = name;
        if (displayName.length > maxNameLen) {
          displayName = displayName.substring(0, maxNameLen - 3) + '..';
        }
        
        final String itemLabel = '$prefix$displayName';
        final String itemPrice = _rawFormatRupiah(subtotal).replaceAll('Rp. ', '');
        
        bytes += generator.row([
          PosColumn(text: itemLabel, width: 9, styles: const PosStyles(align: PosAlign.left)),
          PosColumn(text: itemPrice, width: 3, styles: const PosStyles(align: PosAlign.right)),
        ]);
        
        // Item-level Discount
        final double itemDiscTotal = double.tryParse(item['discountTotal']?.toString() ?? "0") ?? 0;
        final String discType = item['discount_type']?.toString() ?? 'fixed';
        
        if (itemDiscTotal > 0) {
            int totalNominal = itemDiscTotal.toInt();
            if (discType == 'percent') {
                 final double harga = double.tryParse(item['harga_jual']?.toString() ?? "0") ?? 0;
                 final int nominalPerUnit = (harga * itemDiscTotal / 100).round();
                 totalNominal = nominalPerUnit * qty.toInt();
            }

            if (totalNominal > 0) {
              bytes += generator.row([
                PosColumn(text: '   disc', width: 6, styles: const PosStyles(align: PosAlign.left, fontType: PosFontType.fontB)),
                PosColumn(text: '-${_rawFormatRupiah(totalNominal).replaceAll('Rp. ', '')}', width: 6, styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontB)),
              ]);
            }
        }
      }
      bytes += generator.text(lineSeparator, styles: const PosStyles(align: PosAlign.center));

      // 5. Totals
      final int total = (double.tryParse(order['bayar']?.toString() ?? "0") ?? 0).toInt();
      
      // Calculate total discount from both default and manual fields
      int diskon = (double.tryParse(order['diskon']?.toString() ?? "0") ?? 0).toInt();
      int manualDisc = (double.tryParse(order['manual_discount_value']?.toString() ?? "0") ?? 0).toInt();
      String discType = order['discount_type']?.toString() ?? 'fixed';
      
      int totalDiscount = 0;

      // Re-calculate based on how it's stored in DB
      if (manualDisc > 0) {
          totalDiscount = (discType == 'percent') 
              ? (double.tryParse(order['total_harga']?.toString() ?? "0") ?? 0 * manualDisc / 100).round()
              : manualDisc;
      } else if (diskon > 0) {
          totalDiscount = (double.tryParse(order['total_harga']?.toString() ?? "0") ?? 0 * diskon / 100).round();
      }
      
      final int subtotalTotal = total + totalDiscount;
      final int cash = (double.tryParse(order['diterima']?.toString() ?? "0") ?? 0).toInt();
      final int change = cash - total;

      bytes += generator.row([
        PosColumn(text: 'Subtotal', width: 6, styles: const PosStyles(align: PosAlign.left)),
        PosColumn(text: _rawFormatRupiah(subtotalTotal).replaceAll('Rp. ', ''), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);

      if (totalDiscount > 0) {
        bytes += generator.row([
          PosColumn(text: 'Discount', width: 6, styles: const PosStyles(align: PosAlign.left)),
          PosColumn(text: '-${_rawFormatRupiah(totalDiscount).replaceAll('Rp. ', '')}', width: 6, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }

      bytes += generator.row([
        PosColumn(text: 'Total', width: 6, styles: const PosStyles(align: PosAlign.left, bold: true)),
        PosColumn(text: _rawFormatRupiah(total).replaceAll('Rp. ', ''), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
      
      bytes += generator.row([
        PosColumn(text: 'Cash', width: 6, styles: const PosStyles(align: PosAlign.left)),
        PosColumn(text: _rawFormatRupiah(cash).replaceAll('Rp. ', ''), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      
      bytes += generator.row([
        PosColumn(text: 'Change', width: 6, styles: const PosStyles(align: PosAlign.left)),
        PosColumn(text: _rawFormatRupiah(change > 0 ? change : 0).replaceAll('Rp. ', ''), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);

      bytes += generator.text(lineSeparator, styles: const PosStyles(align: PosAlign.center));
      
      bytes += generator.row([
        PosColumn(text: 'PAID', width: 6, styles: const PosStyles(align: PosAlign.left, bold: true)),
        PosColumn(text: _rawFormatRupiah(total).replaceAll('Rp. ', ''), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);

      bytes += generator.text(lineSeparator, styles: const PosStyles(align: PosAlign.center));

      // 6. Points
      if (!isWalkIn) {
        final earnedPoints = (total / 10000).floor();
        final prevPointsStr = member?['points']?.toString() ?? '0';
        final prevPoints = int.tryParse(prevPointsStr) ?? 0;
        final newTotal = prevPoints + earnedPoints;
        if (earnedPoints > 0) {
          bytes += generator.text('Points Earned : +$earnedPoints pts', styles: const PosStyles(align: PosAlign.center));
          bytes += generator.text('Current Points: $newTotal pts', styles: const PosStyles(align: PosAlign.center));
          bytes += generator.hr();
        }
      }

      // 7. Footer
      final footerLine1 = userService.getPrefString('pos_receipt_footer_1');
      if (footerLine1.isNotEmpty && footerLine1 != 'Guest') bytes += generator.text(footerLine1, styles: const PosStyles(align: PosAlign.center));
      if (phone.isNotEmpty) bytes += generator.text('HP : $phone', styles: const PosStyles(align: PosAlign.center));
      final igAccount = userService.getPrefString('pos_ig_account');
      if (igAccount.isNotEmpty && igAccount != 'Guest') bytes += generator.text('IG : $igAccount', styles: const PosStyles(align: PosAlign.center));

      // 8. Feedback QR
      bytes += generator.text('KRITIK & SARAN', styles: const PosStyles(align: PosAlign.center, bold: true));
      final encodedTenant = Uri.encodeComponent(companyName);
      final waUrl = "https://api.whatsapp.com/send?phone=6281387401166&text=Halo%20kak%2C%20saya%20ingin%20menyampaikan%20kritik%20dan%20saran%20untuk%20$encodedTenant";
      bytes += generator.qrcode(waUrl);

      bytes += generator.feed(1);
      bytes += generator.cut();

      await settingCtrl.printToTarget(cashierPrinter, prebuiltBytes: bytes);
    } catch (e) {
      ErrorLogService.log(
        category: 'printer',
        errCode: 'REPRINT_FAIL',
        errMsg: 'orderId=${order['id_penjualan']} | remoteNo=${order['remote_number']} | $e',
      );
      Get.snackbar('Print Error', 'Failed to reprint: $e');
    } finally {
      isPrinting.value = false;
    }
  }

  String _rawFormatRupiah(int number) {
    return NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(number).trim();
  }
  String _truncateProductName(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 2)}..';
  }
}
