import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:semesta_pos/modules/dashboard/admin/controllers/dashboard_admin_controller.dart';
import 'package:semesta_pos/modules/dashboard/employee/controllers/dashboard_employee_controller.dart';
import 'package:semesta_pos/modules/home/admin/controllers/home_admin_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class HomeAdminScreen extends GetView<HomeAdminController> {
  const HomeAdminScreen({super.key});

  static String _fmtRp(int v) {
    final f = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return f.format(v);
  }

  String _cleanProductName(String rawName) {
    String name = rawName.trim();
    if (name.contains('_')) {
      name = name.replaceAll('_', ' ');
    }
    return name.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(HomeAdminController());
    ctrl.getDashboardData();
    ctrl.getUserData();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      body: Obx(() => ctrl.isLoading.value
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── HEADER ───────────────────────────────────────────
                    _buildHeader(context, ctrl),
                    SizedBox(height: 24.h),

                    // ── ROW 1: KPI CARDS ──────────────────────────────────
                    Row(children: [
                      _kpiCard(context,
                          label: 'Income Today',
                          value: _fmtRp(ctrl.incomeToday.value),
                          sub: '${ctrl.totalTransactionsToday.value} transactions',
                          icon: CupertinoIcons.money_dollar_circle_fill,
                          color: Colors.green),
                      SizedBox(width: 12.w),
                      _kpiCard(context,
                          label: 'Income This Month',
                          value: _fmtRp(ctrl.incomeMonth.value),
                          sub: '${ctrl.totalTransactionsMonth.value} transactions',
                          icon: CupertinoIcons.chart_bar_fill,
                          color: AppTheme.primaryColor),
                      SizedBox(width: 12.w),
                      _kpiCard(context,
                          label: 'Total Members',
                          value: ctrl.totalMembers.value.toString(),
                          sub: 'Registered customers',
                          icon: CupertinoIcons.person_2_fill,
                          color: Colors.orange),
                    ]),
                    SizedBox(height: 16.h),

                    // ── ROW 2: PAYMENT BREAKDOWN + RECENT TX ──────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT col
                        Expanded(
                          flex: 3,
                          child: Column(children: [
                            _paymentBreakdownCard(context, ctrl),
                            SizedBox(height: 16.h),
                            _topProductsCard(context, ctrl),
                          ]),
                        ),
                        SizedBox(width: 16.w),
                        // RIGHT col – recent transactions
                        Expanded(
                          flex: 5,
                          child: _recentTransactions(context, ctrl),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // ── ROW 3: 7-DAY CHART ────────────────────────────────
                    _chartCard(context, ctrl),
                  ],
                ),
              ),
            )),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, HomeAdminController ctrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Overview',
              style: TextStyle(
                  fontFamily: AppTheme.fontBold,
                  fontSize: 24.sp,
                  color: AppTheme.textColor(context))),
          Text('Welcome, ${ctrl.userName.value}',
              style: TextStyle(
                  fontSize: 13.sp,
                  color: AppTheme.secondaryTextColor(context))),
        ]),
        GestureDetector(
          onTap: () => ctrl.getDashboardData(),
          child: Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppTheme.borderColor(context)),
            ),
            child: Icon(Icons.refresh_rounded,
                color: AppTheme.primaryColor, size: 22.sp),
          ),
        ),
      ],
    );
  }

  // ── KPI CARD ────────────────────────────────────────────────────────────────
  Widget _kpiCard(BuildContext context,
      {required String label,
      required String value,
      required String sub,
      required IconData icon,
      required Color color}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Row(children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11.sp,
                      color: AppTheme.secondaryTextColor(context),
                      fontFamily: AppTheme.fontMedium)),
              SizedBox(height: 4.h),
              Text(value,
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontFamily: AppTheme.fontBold,
                      color: AppTheme.textColor(context))),
              Text(sub,
                  style: TextStyle(
                      fontSize: 10.sp,
                      color: AppTheme.secondaryTextColor(context))),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── PAYMENT BREAKDOWN CARD ───────────────────────────────────────────────────
  Widget _paymentBreakdownCard(BuildContext context, HomeAdminController ctrl) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Income by Payment Method',
            style: TextStyle(
                fontFamily: AppTheme.fontBold,
                fontSize: 14.sp,
                color: AppTheme.textColor(context))),
        SizedBox(height: 4.h),
        Text('Today',
            style: TextStyle(
                fontSize: 11.sp, color: AppTheme.secondaryTextColor(context))),
        SizedBox(height: 12.h),
        Obx(() {
          final items = ctrl.paymentBreakdownToday;
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Text('No transactions yet',
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.secondaryTextColor(context))),
              ),
            );
          }
          final totalAll = items.fold<int>(0, (s, e) => s + (e['total'] as int));
          return Column(
            children: items.map((item) {
              final pct = totalAll > 0
                  ? (item['total'] as int) / totalAll
                  : 0.0;
              final color = _methodColor(item['method'] as String);
              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                        ),
                        SizedBox(width: 8.w),
                        Text(item['method'] as String,
                            style: TextStyle(
                                fontSize: 12.sp,
                                fontFamily: AppTheme.fontMedium,
                                color: AppTheme.textColor(context))),
                      ]),
                      Text(_fmtRp(item['total'] as int),
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontFamily: AppTheme.fontBold,
                              color: AppTheme.textColor(context))),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5.h,
                      backgroundColor: AppTheme.borderColor(context),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ]),
              );
            }).toList(),
          );
        }),
      ]),
    );
  }

  Color _methodColor(String method) {
    final m = method.toLowerCase();
    if (m.contains('cash') || m.contains('tunai')) return Colors.green;
    if (m.contains('qris') || m.contains('qr')) return Colors.purple;
    if (m.contains('transfer') || m.contains('bank')) return Colors.blue;
    if (m.contains('card') || m.contains('kartu')) return Colors.orange;
    return Colors.teal;
  }

  // ── TOP PRODUCTS CARD ────────────────────────────────────────────────────────
  Widget _topProductsCard(BuildContext context, HomeAdminController ctrl) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Products',
              style: TextStyle(
                  fontFamily: AppTheme.fontBold,
                  fontSize: 14.sp,
                  color: AppTheme.textColor(context))),
          SizedBox(height: 12.h),
          _topProductRow(context,
              label: 'Today',
              name: _cleanProductName(ctrl.topProductToday['name'] as String),
              qty: ctrl.topProductToday['qty'] as int,
              progress: (ctrl.topProductToday['progress'] as double),
              color: Colors.green),
          SizedBox(height: 10.h),
          _topProductRow(context,
              label: 'This Month',
              name: _cleanProductName(ctrl.topProductMonth['name'] as String),
              qty: ctrl.topProductMonth['qty'] as int,
              progress: (ctrl.topProductMonth['progress'] as double),
              color: AppTheme.primaryColor),
        ],
      )),
    );
  }

  Widget _topProductRow(BuildContext context,
      {required String label,
      required String name,
      required int qty,
      required double progress,
      required Color color}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 10.sp, color: AppTheme.secondaryTextColor(context))),
      SizedBox(height: 3.h),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
          child: Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13.sp,
                  fontFamily: AppTheme.fontMedium,
                  color: AppTheme.textColor(context))),
        ),
        Text('$qty pcs',
            style: TextStyle(
                fontSize: 12.sp,
                fontFamily: AppTheme.fontBold,
                color: color)),
      ]),
      SizedBox(height: 4.h),
      ClipRRect(
        borderRadius: BorderRadius.circular(4.r),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 5.h,
          backgroundColor: AppTheme.borderColor(context),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    ]);
  }

  // ── RECENT TRANSACTIONS ──────────────────────────────────────────────────────
  Widget _recentTransactions(BuildContext context, HomeAdminController ctrl) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Recent Transactions',
                style: TextStyle(
                    fontFamily: AppTheme.fontBold,
                    fontSize: 16.sp,
                    color: AppTheme.textColor(context))),
            Text('Excludes deleted orders',
                style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.secondaryTextColor(context))),
          ]),
          ElevatedButton.icon(
            onPressed: _goToPOS,
            icon: Icon(Icons.add, size: 16.sp, color: Colors.white),
            label: Text('New Order',
                style: TextStyle(
                    fontFamily: AppTheme.fontBold,
                    fontSize: 13.sp,
                    color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
            ),
          ),
        ]),
        SizedBox(height: 16.h),
        // Table header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(children: [
            Expanded(flex: 2, child: _th('Date')),
            Expanded(flex: 2, child: _th('Type')),
            Expanded(flex: 2, child: _th('Customer')),
            Expanded(flex: 2, child: _th('Method')),
            Expanded(flex: 2, child: _th('Total', align: TextAlign.right)),
            Expanded(flex: 2, child: _th('Status', align: TextAlign.center)),
          ]),
        ),
        SizedBox(height: 4.h),
        Obx(() {
          final txs = ctrl.recentTransactions;
          if (txs.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Text('No transactions yet',
                    style: TextStyle(
                        color: AppTheme.secondaryTextColor(context),
                        fontSize: 13.sp)),
              ),
            );
          }
          return Column(
            children: txs.asMap().entries.map((entry) {
              final tx = entry.value;
              final idx = entry.key;
              return _txRow(context, tx, idx);
            }).toList(),
          );
        }),
      ]),
    );
  }

  void _goToPOS() {
    if (Get.isRegistered<DashboardAdminController>()) {
      final d = Get.find<DashboardAdminController>();
      d.stateSelectedIndex.value = 1;
      d.isSidebarCollapsed.value = true;
    } else if (Get.isRegistered<DashboardEmployeeController>()) {
      final d = Get.find<DashboardEmployeeController>();
      d.stateSelectedIndex.value = 1;
      d.isSidebarCollapsed.value = true;
    }
  }

  Widget _th(String t, {TextAlign align = TextAlign.left}) => Text(t,
      textAlign: align,
      style: TextStyle(
          fontSize: 11.sp,
          fontFamily: AppTheme.fontBold,
          color: AppTheme.textColorSecondary));

  Widget _txRow(BuildContext context, Map<String, dynamic> tx, int idx) {
    final status = tx['status'] as int? ?? 0;
    final isCancelled = status == 5 || status == 4;
    final isPaid = status == 2 || status == 3;

    Color statusColor;
    String statusLabel;
    if (isPaid) { statusColor = Colors.green; statusLabel = 'Paid'; }
    else if (isCancelled) { statusColor = Colors.red; statusLabel = 'Cancelled'; }
    else { statusColor = Colors.orange; statusLabel = 'Pending'; }

    final total = double.tryParse(
            (tx['bayar'] ?? tx['total_harga'] ?? '0').toString())
        ?.toInt() ?? 0;

    DateTime? dt = DateTime.tryParse(tx['tgl_penjualan']?.toString() ?? '');
    final dateStr = dt != null
        ? DateFormat('dd/MM HH:mm').format(dt)
        : '-';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: idx.isEven
            ? Colors.transparent
            : (isDark
                ? Colors.white.withValues(alpha: 0.02)
                : Colors.grey.withValues(alpha: 0.025)),
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor(context), width: 0.5),
        ),
      ),
      child: Row(children: [
        Expanded(flex: 2, child: Text(dateStr, style: _cellStyle(context))),
        Expanded(flex: 2, child: Text(tx['order_type']?.toString() ?? '-', style: _cellStyle(context))),
        Expanded(
          flex: 2,
          child: Row(children: [
            CircleAvatar(
              radius: 11.r,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Icon(CupertinoIcons.person_fill,
                  size: 12.sp, color: AppTheme.primaryColor),
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                tx['member_name']?.toString() ?? 'Walk In',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _cellStyle(context),
              ),
            ),
          ]),
        ),
        Expanded(
          flex: 2,
          child: Text(tx['payment_method']?.toString() ?? '-',
              style: _cellStyle(context)),
        ),
        Expanded(
          flex: 2,
          child: Text(_fmtRp(total),
              textAlign: TextAlign.right,
              style: _cellStyle(context)
                  .copyWith(fontFamily: AppTheme.fontBold)),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10.sp,
                      fontFamily: AppTheme.fontBold)),
            ),
          ),
        ),
      ]),
    );
  }

  TextStyle _cellStyle(BuildContext context) => TextStyle(
        fontSize: 12.sp,
        color: AppTheme.textColor(context),
        fontFamily: AppTheme.fontMedium,
      );

  // ── 7-DAY CHART ───────────────────────────────────────────────────────────
  Widget _chartCard(BuildContext context, HomeAdminController ctrl) {
    return Container(
      height: 310.h,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Revenue – Last 7 Days',
            style: TextStyle(
                fontFamily: AppTheme.fontBold,
                fontSize: 14.sp,
                color: AppTheme.textColor(context))),
        SizedBox(height: 16.h),
        Expanded(child: _lineChart(context, ctrl)),
      ]),
    );
  }

  /// Compact Rupiah label: e.g. 150000 → "150rb", 1500000 → "1,5jt"
  String _compactRp(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(v % 1000000 == 0 ? 0 : 1)}jt';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
    return v.toStringAsFixed(0);
  }

  Widget _lineChart(BuildContext context, HomeAdminController ctrl) {
    return Obx(() {
      final model = ctrl.dashboardModel.value;
      final dates = model.dataTanggal as List<String>? ?? [];
      final incomes = model.dataPendapatan as List<int>? ?? [];

      if (incomes.isEmpty) {
        return Center(
            child: Text('No data available',
                style:
                    TextStyle(color: AppTheme.secondaryTextColor(context))));
      }

      final spots = incomes.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), e.value.toDouble());
      }).toList();

      final maxY = incomes.reduce((a, b) => a > b ? a : b).toDouble();
      final effectiveMax = maxY == 0 ? 100.0 : maxY * 1.35;
      final yInterval = maxY == 0 ? 50.0 : (maxY * 0.35).ceilToDouble();

      return LineChart(LineChartData(
        minY: 0,
        maxY: effectiveMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (v) => FlLine(
              color: AppTheme.borderColor(context),
              strokeWidth: 0.6,
              dashArray: [4, 4]),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          // Bottom: date labels
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28.h,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= dates.length) return const SizedBox();
                return Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(dates[i],
                      style: TextStyle(
                          fontSize: 9.sp,
                          color: AppTheme.secondaryTextColor(context))),
                );
              },
            ),
          ),
          // Left: compact Rp labels
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42.w,
              interval: yInterval,
              getTitlesWidget: (v, _) {
                if (v == 0) return const SizedBox();
                return Text(
                  _compactRp(v),
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: AppTheme.secondaryTextColor(context),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
              _fmtRp(s.y.toInt()),
              TextStyle(
                  color: Colors.white,
                  fontFamily: AppTheme.fontBold,
                  fontSize: 11.sp),
            )).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.2, // Lebih lurus, tidak terlalu melengkung
            preventCurveOverShooting: true,
            color: AppTheme.primaryColor,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (s, _, __, ___) {
                // Highlight titik non-nol dengan warna lebih menonjol
                final isZero = s.y == 0;
                return FlDotCirclePainter(
                  radius: isZero ? 3 : 5,
                  color: isZero
                      ? AppTheme.primaryColor.withValues(alpha: 0.3)
                      : AppTheme.primaryColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            showingIndicators: spots
                .asMap()
                .entries
                .where((e) => e.value.y > 0)
                .map((e) => e.key)
                .toList(),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.18),
                  AppTheme.primaryColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        // Show value labels above each non-zero point
        showingTooltipIndicators: spots
            .asMap()
            .entries
            .where((e) => e.value.y > 0)
            .map((e) => ShowingTooltipIndicators([
                  LineBarSpot(
                    LineChartBarData(spots: spots),
                    0,
                    e.value,
                  ),
                ]))
            .toList(),
      ));
    });
  }
}
