import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:semesta_pos/modules/report/controllers/report_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:semesta_pos/core/services/sync_service.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReportController());

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() => Row(
                        children: [
                          _buildTabItem(
                            title: "Order History",
                            isActive: controller.activeTab.value == 0,
                            onTap: () => controller.changeTab(0),
                          ),
                          SizedBox(width: 32.w),
                          _buildTabItem(
                            title: "Report Analysis",
                            isActive: controller.activeTab.value == 1,
                            onTap: () => controller.changeTab(1),
                          ),
                          SizedBox(width: 32.w),
                          _buildTabItem(
                            title: "Top Products",
                            isActive: controller.activeTab.value == 2,
                            onTap: () => controller.changeTab(2),
                          ),
                          /*SizedBox(width: 32.w),
                          _buildTabItem(
                            title: "Cash Flow",
                            isActive: controller.activeTab.value == 3,
                            onTap: () => controller.changeTab(3),
                          ),*/
                        ],
                      )),
                  SizedBox(height: 24.h),
                  Obx(() {
                    if (controller.isLoading.value) {
                      return SizedBox(
                        height: 400.h,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (controller.activeTab.value == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterSection(context, controller),
                          SizedBox(height: 24.h),
                          _buildDataTable(context, controller),
                          SizedBox(height: 16.h),
                          _buildPagination(context, controller),
                        ],
                      );
                    } else if (controller.activeTab.value == 1) {
                      return _buildAnalysisTab(context, controller);
                    } else if (controller.activeTab.value == 2) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterSection(context, controller, showPaymentMethod: false),
                          SizedBox(height: 24.h),
                          _buildTopProductsTable(context, controller),
                        ],
                      );
                    } else {
                      return _buildCashFlowTab(context, controller);
                    }
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        border:
            Border(bottom: BorderSide(color: AppTheme.borderColor(context))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Reports & History",
            style: TextStyle(
              fontSize: AppTheme.fontSizeTitleMedium,
              fontFamily: AppTheme.fontBold,
              color: AppTheme.textColor(context),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
            tooltip: "Refresh Data",
            onPressed: () async {
              final controller = Get.find<ReportController>();
              try {
                if (Get.isRegistered<SyncService>()) {
                  await Get.find<SyncService>().pullCreditNotes();
                }
                await controller.getOrders();
              } catch (e) {
                debugPrint("ReportView: Refresh failed: $e");
                Get.snackbar("Sync Error", "Koneksi bermasalah. Gagal sinkronisasi data terbaru.");
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(
      {required String title,
      required bool isActive,
      required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? AppTheme.primaryColor : Colors.grey,
              fontFamily: AppTheme.fontBold,
              fontSize: AppTheme.fontSizeBodyLarge,
            ),
          ),
        ),
        if (isActive)
          Container(
            margin: EdgeInsets.only(top: 8.h),
            height: 3.h,
            width: 40.w,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterSection(
      BuildContext context, ReportController controller, {bool showPaymentMethod = true}) {
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16.w,
      runSpacing: 16.h,
      children: [
        _buildFilterField(
          context: context,
          label: "Start Date",
          hint: "Input start date",
          controller: controller.startDateController,
          width: 160.w,
          onTap: () =>
              controller.selectDate(context, controller.startDateController),
          icon: Icons.calendar_today_outlined,
        ),
        _buildFilterField(
          context: context,
          label: "End Date",
          hint: "Input end date",
          controller: controller.endDateController,
          width: 160.w,
          onTap: () =>
              controller.selectDate(context, controller.endDateController),
          icon: Icons.calendar_today_outlined,
        ),
        if (showPaymentMethod)
          _buildFilterDropdown(
            context: context,
            label: "Payment Method",
            value: controller.selectedPaymentMethod,
            paymentModes: controller.paymentModes,
            width: 180.w,
          ),
        SizedBox(
          height: 48.h,
          child: ElevatedButton(
            onPressed: () => controller.filterOrders(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text(
              "Filter",
              style: TextStyle(
                color: Colors.white,
                fontFamily: AppTheme.fontBold,
                fontSize: AppTheme.fontSizeLabelLarge,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterField({
    required BuildContext context,
    required String label,
    required String hint,
    required TextEditingController controller,
    required double width,
    VoidCallback? onTap,
    IconData? icon,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: AppTheme.fontBold,
                  fontSize: AppTheme.fontSizeLabelSmall,
                  color: AppTheme.textColor(context).withValues(alpha: 0.8))),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              height: 48.h,
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                border: Border.all(
                    color: AppTheme.borderColor(context), width: 1.5),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: IgnorePointer(
                      ignoring: onTap != null,
                      child: TextField(
                        controller: controller,
                        readOnly: onTap != null,
                        style: TextStyle(
                            fontSize: AppTheme.fontSizeLabelMedium,
                            fontFamily: AppTheme.fontMedium,
                            color: AppTheme.textColor(context)),
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400, fontSize: AppTheme.fontSizeLabelMedium),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                  if (icon != null)
                    Icon(icon, size: 18.sp, color: Colors.grey.shade500),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required BuildContext context,
    required String label,
    required RxString value,
    required double width,
    required RxList<Map<String, dynamic>> paymentModes,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: AppTheme.fontBold,
                  fontSize: AppTheme.fontSizeLabelSmall,
                  color: AppTheme.textColor(context).withValues(alpha: 0.8))),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            height: 48.h,
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              border:
                  Border.all(color: AppTheme.borderColor(context), width: 1.5),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Obx(() {
              final modes = paymentModes.toList();
              // Ensure value is still valid, reset to 'All' if not
              final validNames = modes.map((m) => m['name']?.toString() ?? '').toSet();
              if (value.value != 'All' && !validNames.contains(value.value)) {
                value.value = 'All';
              }
              return DropdownButton<String>(
                value: value.value == 'All' ? null : value.value,
                hint: Text('All methods',
                    style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: AppTheme.fontSizeLabelMedium)),
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: AppTheme.cardColor(context),
                icon: Icon(Icons.keyboard_arrow_down,
                    size: 20.sp, color: Colors.grey.shade500),
                items: modes.map((mode) {
                  final name = mode['name']?.toString() ?? '';
                  return DropdownMenuItem<String>(
                    value: name == 'All' ? null : name,
                    child: Text(name == 'All' ? 'All methods' : name,
                        style: TextStyle(
                            fontSize: AppTheme.fontSizeLabelMedium,
                            fontFamily: AppTheme.fontMedium,
                            color: AppTheme.textColor(context))),
                  );
                }).toList(),
                onChanged: (val) => value.value = val ?? 'All',
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(BuildContext context, ReportController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : const Color(0xFFF1F3F9),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Row(
              children: [
                _buildHeaderCell("Date", flex: 2),
                _buildHeaderCell("Receipt Number", flex: 2),
                _buildHeaderCell("Order Type", flex: 2),
                _buildHeaderCell("Status", flex: 2),
                _buildHeaderCell("Total", flex: 2),
                _buildHeaderCell("Payment Method", flex: 2),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(16.r)),
            ),
            child: Obx(() => controller.orders.isEmpty
                ? SizedBox(
                    height: 300.h,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.doc_text_search,
                              size: 48.sp, color: Colors.grey.shade700),
                          SizedBox(height: 16.h),
                          Text("No data found",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: AppTheme.fontSizeBodyLarge,
                                  fontFamily: AppTheme.fontMedium)),
                          SizedBox(height: 8.h),
                          Text("Try adjusting your date filters",
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: AppTheme.fontSizeLabelMedium,
                                  fontFamily: AppTheme.fontRegular)),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.paginatedOrders.length,
                    itemBuilder: (context, index) {
                      final order = controller.paginatedOrders[index];
                      return _buildDataRow(context, order);
                    },
                  )),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsTable(BuildContext context, ReportController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : const Color(0xFFF1F3F9),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Row(
              children: [
                _buildHeaderCell("Rank", flex: 1),
                _buildHeaderCell("Product Name", flex: 4),
                _buildHeaderCell("Quantity Sold", flex: 2),
                _buildHeaderCell("Total Revenue", flex: 3),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(16.r)),
            ),
            child: Obx(() => controller.topProducts.isEmpty
                ? SizedBox(
                    height: 300.h,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.cube_box,
                              size: 48.sp, color: Colors.grey.shade700),
                          SizedBox(height: 16.h),
                          Text("No products sold in this period",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: AppTheme.fontSizeBodyLarge,
                                  fontFamily: AppTheme.fontMedium)),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.topProducts.length,
                    itemBuilder: (context, index) {
                      final product = controller.topProducts[index];
                      return _buildTopProductRow(context, index + 1, product);
                    },
                  )),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductRow(BuildContext context, int rank, Map<String, dynamic> product) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: AppTheme.borderColor(context).withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 1,
              child: Text("#$rank",
                  style: TextStyle(
                      fontSize: AppTheme.fontSizeLabelMedium,
                      color: AppTheme.primaryColor,
                      fontFamily: AppTheme.fontBold))),
          Expanded(
              flex: 4,
              child: Text(product['item_name']?.toString() ?? "Item",
                  style: TextStyle(
                      fontSize: AppTheme.fontSizeLabelMedium,
                      fontFamily: AppTheme.fontMedium,
                      color: AppTheme.textColor(context)))),
          Expanded(
              flex: 2,
              child: Text(product['qty_sold']?.toString() ?? "0",
                  style: TextStyle(
                      fontSize: AppTheme.fontSizeLabelMedium,
                      fontFamily: AppTheme.fontBold,
                      color: AppTheme.textColor(context)))),
          Expanded(
              flex: 3,
              child: Text(
                  _formatCurrency(
                      double.tryParse(product['total_revenue']?.toString() ?? "0") ?? 0),
                  style: TextStyle(
                      fontSize: AppTheme.fontSizeLabelMedium,
                      fontFamily: AppTheme.fontBold,
                      color: Colors.green.shade600))),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontFamily: AppTheme.fontBold,
          fontSize: AppTheme.fontSizeLabelLarge,
        ),
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, Map<String, dynamic> order) {
    bool isRefund = order['is_refund'] == true;
    int refundCount = order['refund_count'] != null ? int.tryParse(order['refund_count'].toString()) ?? 0 : 0;
    bool hasRefunds = refundCount > 0;
    double bayar = double.tryParse(order['bayar']?.toString() ?? "0") ?? 0;

    return InkWell(
      onTap: () => _showOrderDetailDialog(context, order),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: AppTheme.borderColor(context).withValues(alpha: 0.3))),
        ),
        child: Row(
          children: [
            Expanded(
                flex: 2,
                child: Text(order['tgl_penjualan']?.split('T')[0] ?? "-",
                    style: TextStyle(
                        fontSize: AppTheme.fontSizeLabelMedium,
                        fontFamily: AppTheme.fontMedium,
                        color: AppTheme.textColor(context)))),
            Expanded(
                flex: 2,
                child: Text("#${order['id_penjualan']}",
                    style: TextStyle(
                        fontSize: AppTheme.fontSizeLabelMedium,
                        color: isRefund ? Colors.red.shade600 : AppTheme.primaryColor,
                        fontFamily: AppTheme.fontBold))),
            Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(order['order_type'] ?? "Dine In",
                        style: TextStyle(
                            fontSize: AppTheme.fontSizeLabelMedium,
                            fontFamily: AppTheme.fontMedium,
                            color: isRefund ? Colors.red.shade600 : AppTheme.textColor(context))),
                    if ((int.tryParse(order['queue_number']?.toString() ?? '0') ?? 0) > 0)
                      Container(
                        margin: EdgeInsets.only(top: 4.h),
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          "#${(order['queue_number']).toString().padLeft(3, '0')}",
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                  ],
                )),
            Expanded(flex: 2, child: isRefund 
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text("Refunded",
                        style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: AppTheme.fontSizeLabelSmall,
                            fontFamily: AppTheme.fontBold),
                      ),
                    ),
                  ) 
                : _buildStatusBadge((order['status'] as num?)?.toInt() ?? 1, hasRefunds: hasRefunds)),
            Expanded(
                flex: 2,
                child: Text(
                    _formatCurrency(bayar),
                    style: TextStyle(
                        fontSize: AppTheme.fontSizeLabelMedium,
                        fontFamily: AppTheme.fontBold,
                        color: isRefund ? Colors.red.shade600 : AppTheme.textColor(context)))),
            Expanded(
                flex: 2,
                child: Text(order['payment_method'] ?? "Cash",
                    style: TextStyle(
                        fontSize: AppTheme.fontSizeLabelMedium,
                        fontFamily: AppTheme.fontMedium,
                        color: AppTheme.textColor(context)))),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemRow(BuildContext context, Map<String, dynamic> item, {bool isRefund = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: isRefund ? Colors.red.withValues(alpha: 0.1) : AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Text(
                "${item['jumlah']}x",
                style: TextStyle(
                  color: isRefund ? Colors.red.shade700 : AppTheme.primaryColor,
                  fontFamily: AppTheme.fontBold,
                  fontSize: AppTheme.fontSizeLabelSmall,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['nama_produk']?.toString() ?? item['note']?.toString() ?? "Custom Item",
                        style: TextStyle(
                          fontFamily: AppTheme.fontMedium,
                          fontSize: AppTheme.fontSizeLabelMedium,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                    )
                  ],
                ),
                if (item['note'] != null && item['note'].toString().isNotEmpty && !item['note'].toString().startsWith('REMOTE_ITEM:'))
                  Text(
                    item['note'],
                    style: TextStyle(fontSize: 11.sp, color: const Color.fromARGB(255, 158, 158, 158)),
                  ),
              ],
            ),
          ),
          Text(
            _formatCurrency(double.tryParse(item['subtotal']?.toString() ?? "0") ?? 0),
            style: TextStyle(
              fontFamily: AppTheme.fontBold,
              fontSize: AppTheme.fontSizeLabelMedium,
              color: AppTheme.textColor(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetailDialog(BuildContext context, Map<String, dynamic> order) {
    final controller = Get.find<ReportController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 24.h),
        child: FutureBuilder<Map<String, dynamic>>(
          future: controller.fetchOrderFullDetails(
            order['id_penjualan'] as int,
            order['id_member'],
            isRefund: order['is_refund'] == true,
            refundTotal: double.tryParse(order['total_harga']?.toString() ?? "0") ?? 0,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                height: 200.h,
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final data = snapshot.data!;
            final List items = data['items'] ?? [];
            final Map<String, dynamic>? member = data['member'];

            return Container(
              width: 500.w,
              constraints: BoxConstraints(maxHeight: 1.sh * 0.8),
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- HEADER ---
                  Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Receipt #${order['id_penjualan']}",
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeHeadline,
                                fontFamily: AppTheme.fontBold,
                                color: AppTheme.textColor(context),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              order['tgl_penjualan']?.toString().split('.')[0] ?? "-",
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeLabelSmall,
                                color: isDark ? Colors.grey.shade100 : Colors.grey.shade900,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // --- CONTENT ---
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Customer Detail
                          _buildDetailSectionTitle(context, "Customer Information"),
                          SizedBox(height: 12.h),
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Column(
                              children: [
                                _buildDetailItem(
                                  context, 
                                  "Name", 
                                  member?['nama']?.toString() ?? "General Customer", 
                                  isLast: false,
                                ),
                                _buildDetailItem(
                                  context, 
                                  "Phone", 
                                  member?['telepon']?.toString() ?? "-", 
                                  isLast: member?['alamat'] == null || (member?['alamat']?.toString() ?? "").isEmpty,
                                ),
                                if (member?['alamat'] != null && (member?['alamat']?.toString() ?? "").isNotEmpty)
                                  _buildDetailItem(
                                    context, 
                                    "Address", 
                                    member?['alamat']?.toString() ?? "", 
                                    isLast: true,
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),

                          // Items Detail
                          _buildDetailSectionTitle(context, "Order Items"),
                          SizedBox(height: 12.h),
                          Builder(
                            builder: (context) {
                              final purchasedItems = items.where((item) => item['is_refund']?.toString() != '1' && item['is_refund'] != true).toList();
                              final refundedItems = items.where((item) => item['is_refund']?.toString() == '1' || item['is_refund'] == true).toList();
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (purchasedItems.isNotEmpty) ...[
                                    Text("Purchased Items", style: TextStyle(fontFamily: AppTheme.fontBold, fontSize: 13.sp, color: AppTheme.primaryColor)),
                                    SizedBox(height: 8.h),
                                    ...purchasedItems.map((item) => _buildOrderItemRow(context, item)),
                                  ],
                                  if (refundedItems.isNotEmpty) ...[
                                    if (purchasedItems.isNotEmpty) ...[
                                      SizedBox(height: 8.h),
                                      Divider(color: Colors.red.withValues(alpha: 0.2), thickness: 1),
                                      SizedBox(height: 8.h),
                                    ],
                                    Text("Refunded Items", style: TextStyle(fontFamily: AppTheme.fontBold, fontSize: 13.sp, color: Colors.red.shade600)),
                                    SizedBox(height: 8.h),
                                    ...refundedItems.map((item) => _buildOrderItemRow(context, item, isRefund: true)),
                                  ],
                                ],
                              );
                            }
                          ),
                          const Divider(),

                          // Payment Detail
                          SizedBox(height: 12.h),
                          _buildSummaryRow(context, "Payment Method", order['payment_method'] ?? "Cash"),
                          _buildSummaryRow(context, "Total Item", "${order['total_item'] ?? items.length}"),
                          _buildSummaryRow(context, "Discount", _formatCurrency(double.tryParse(order['diskon']?.toString() ?? "0") ?? 0)),
                          _buildSummaryRow(
                            context, 
                            "Grand Total", 
                            _formatCurrency(double.tryParse(order['bayar']?.toString() ?? "0") ?? 0),
                            isTotal: true
                          ),
                          
                          SizedBox(height: 24.h),
                          
                          // --- REPRINT BUTTON ---
                          Obx(() => SizedBox(
                            width: double.infinity,
                            height: 48.h,
                            child: ElevatedButton.icon(
                              onPressed: controller.isPrinting.value 
                                ? null 
                                : () => controller.printReceiptOnly(order, items, member: member),
                              icon: controller.isPrinting.value 
                                ? SizedBox(width: 18.w, height: 18.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Icon(Icons.print_rounded, color: Colors.white, size: 20.sp),
                              label: Text(
                                controller.isPrinting.value ? "PRINTING..." : "REPRINT RECEIPT",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: AppTheme.fontBold,
                                  fontSize: AppTheme.fontSizeLabelLarge,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailSectionTitle(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 10.sp,
        letterSpacing: 1.2,
        fontFamily: AppTheme.fontBold,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value, {bool isLast = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label, 
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54, 
                fontSize: AppTheme.fontSizeLabelSmall,
                fontFamily: AppTheme.fontMedium,
              )
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.fontBold,
                fontSize: AppTheme.fontSizeLabelSmall,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, {bool isTotal = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? AppTheme.textColor(context) : (isDark ? Colors.white70 : Colors.black87),
              fontFamily: isTotal ? AppTheme.fontBold : AppTheme.fontMedium,
              fontSize: isTotal ? AppTheme.fontSizeLabelLarge : AppTheme.fontSizeLabelMedium,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? AppTheme.primaryColor : (isDark ? Colors.white : Colors.black),
              fontFamily: AppTheme.fontBold,
              fontSize: isTotal ? AppTheme.fontSizeLabelLarge : AppTheme.fontSizeLabelMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(int status, {bool hasRefunds = false}) {
    // Status mapping based on local transactions table:
    // 1 = Active/Pending, 2 = Paid, 3 = On Hold, 4 = Draft, 5 = Cancelled
    String label;
    Color bg;
    Color fg;
    
    if (hasRefunds) {
      label = 'Part. Refunded';
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
    } else {
      switch (status) {
        case 2:
          label = 'Paid';
          bg = Colors.green.shade50;
          fg = Colors.green.shade700;
          break;
        case 5:
          label = 'Cancelled';
          bg = Colors.red.shade50;
          fg = Colors.red.shade700;
          break;
        case 3:
          label = 'On Hold';
          bg = Colors.orange.shade50;
          fg = Colors.orange.shade700;
          break;
        case 4:
        label = 'Draft';
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade600;
        break;
      case 1:
      default:
        label = 'Active';
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        break;
      }
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: fg,
              fontSize: AppTheme.fontSizeLabelSmall,
              fontFamily: AppTheme.fontBold),
        ),
      ),
    );
  }

  Widget _buildPagination(BuildContext context, ReportController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text("Rows per page:",
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: AppTheme.fontSizeLabelMedium,
                fontFamily: AppTheme.fontMedium)),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor(context)),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Obx(() => DropdownButton<int>(
                value: controller.rowsPerPage.value,
                underline: const SizedBox(),
                dropdownColor: AppTheme.cardColor(context),
                style: TextStyle(
                    fontSize: AppTheme.fontSizeLabelMedium,
                    color: AppTheme.textColor(context),
                    fontFamily: AppTheme.fontBold),
                items: [5, 10, 20]
                    .map((int val) =>
                        DropdownMenuItem(value: val, child: Text("$val")))
                    .toList(),
                onChanged: (val) => controller.rowsPerPage.value = val!,
              )),
        ),
        SizedBox(width: 24.w),
        Obx(() {
            int start = (controller.currentPage.value - 1) * controller.rowsPerPage.value + 1;
            int end = start + controller.rowsPerPage.value - 1;
            if (end > controller.totalRows.value) end = controller.totalRows.value;
            if (controller.totalRows.value == 0) start = 0;
            return Text("$start-$end of ${controller.totalRows.value}",
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: AppTheme.fontSizeLabelMedium,
                  fontFamily: AppTheme.fontMedium));
        }),
        SizedBox(width: 16.w),
        InkWell(
          onTap: () => controller.previousPage(),
          child: _buildPageNavIcon(context, Icons.chevron_left),
        ),
        SizedBox(width: 8.w),
        InkWell(
          onTap: () => controller.nextPage(),
          child: _buildPageNavIcon(context, Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildPageNavIcon(BuildContext context, IconData icon) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor(context)),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(icon, color: Colors.grey, size: 20.sp),
    );
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  Widget _buildAnalysisTab(BuildContext context, ReportController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(context, "Today's Sales", controller.todaySales.value, CupertinoIcons.cart_fill, Colors.blue)),
            SizedBox(width: 16.w),
            Expanded(child: _buildStatCard(context, "Yesterday's Sales", controller.yesterdaySales.value, CupertinoIcons.cart_badge_minus, Colors.orange)),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(child: _buildStatCard(context, "This Month", controller.thisMonthSales.value, CupertinoIcons.calendar_today, Colors.green)),
            SizedBox(width: 16.w),
            Expanded(child: _buildStatCard(context, "Last Month", controller.lastMonthSales.value, CupertinoIcons.calendar_circle, Colors.purple)),
          ],
        ),
        SizedBox(height: 32.h),

        // Chart Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Sales Comparison",
               style: TextStyle(
                fontSize: AppTheme.fontSizeTitleMedium,
                fontFamily: AppTheme.fontBold,
                color: AppTheme.textColor(context),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppTheme.borderColor(context)),
              ),
              child: Row(
                children: [
                   _buildModeSelector(context, controller, "Day"),
                   _buildModeSelector(context, controller, "Month"),
                ],
              ),
            )
          ],
        ),
        SizedBox(height: 16.h),
        
        // Chart Area
        Container(
          height: 350.h,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppTheme.borderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem("Current Period", AppTheme.primaryColor),
                  SizedBox(width: 24.w),
                  _buildLegendItem("Previous Period", Colors.blueGrey.shade200),
                ],
              ),
              SizedBox(height: 24.h),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxY(controller.currentPeriodChart, controller.previousPeriodChart),
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            if (controller.analysisViewMode.value == "Day") {
                               if (value % 4 == 0) return Text('${value.toInt()}:00', style: TextStyle(fontSize: 10.sp, color: Colors.grey));
                               return const Text('');
                            } else {
                               if (value % 5 == 0) return Text('${value.toInt() + 1}', style: TextStyle(fontSize: 10.sp, color: Colors.grey));
                               return const Text('');
                            }
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                             if (value == 0) return const Text('');
                             String text = '${(value / 1000).toStringAsFixed(0)}k';
                             return Text(text, style: TextStyle(fontSize: 10.sp, color: Colors.grey));
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _getMaxY(controller.currentPeriodChart, controller.previousPeriodChart) / 4 > 0 
                                         ? _getMaxY(controller.currentPeriodChart, controller.previousPeriodChart) / 4 : 1000,
                      getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(
                      controller.currentPeriodChart.length,
                       (i) => BarChartGroupData(
                         x: i,
                         barRods: [
                           BarChartRodData(
                             toY: controller.currentPeriodChart[i],
                             color: AppTheme.primaryColor,
                             width: controller.analysisViewMode.value == "Day" ? 8.w : 4.w,
                             borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)),
                           ),
                           BarChartRodData(
                             toY: i < controller.previousPeriodChart.length ? controller.previousPeriodChart[i] : 0,
                             color: Colors.blueGrey.shade200,
                             width: controller.analysisViewMode.value == "Day" ? 8.w : 4.w,
                             borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)),
                           ),
                         ],
                       ),
                    ),
                  ),
                ),
              ),
            ]
          )
        )
      ],
    );
  }
  
  double _getMaxY(List<double> curr, List<double> prev) {
    double max = 0;
    for (var c in curr) { if (c > max) max = c; }
    for (var p in prev) { if (p > max) max = p; }
    return max < 1000 ? 5000 : max * 1.2;
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(width: 12.w, height: 12.w, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4.r))),
        SizedBox(width: 8.w),
        Text(title, style: TextStyle(fontSize: 12.sp, fontFamily: AppTheme.fontMedium, color: Colors.grey)),
      ],
    );
  }

  Widget _buildModeSelector(BuildContext context, ReportController controller, String mode) {
     return InkWell(
       onTap: () => controller.toggleAnalysisMode(mode),
       child: Container(
         padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
         decoration: BoxDecoration(
           color: controller.analysisViewMode.value == mode ? AppTheme.primaryColor : Colors.transparent,
           borderRadius: BorderRadius.circular(8.r)
         ),
         child: Text(mode, style: TextStyle(
            color: controller.analysisViewMode.value == mode ? Colors.white : AppTheme.textColor(context),
            fontFamily: AppTheme.fontBold,
            fontSize: AppTheme.fontSizeLabelMedium,
         )),
       ),
     );
  }

  Widget _buildStatCard(BuildContext context, String title, double amount, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: AppTheme.fontSizeLabelMedium, color: Colors.grey, fontFamily: AppTheme.fontMedium)),
                SizedBox(height: 4.h),
                Text(_formatCurrency(amount), style: TextStyle(fontSize: AppTheme.fontSizeBodyLarge, color: AppTheme.textColor(context), fontFamily: AppTheme.fontBold)),
              ],
            ),
          )
        ],
      )
    );
  }

  // ────────────────── CASH FLOW TAB ──────────────────

  Widget _buildCashFlowTab(BuildContext context, ReportController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter row
        Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 16.w,
          runSpacing: 16.h,
          children: [
            _buildFilterField(
              context: context,
              label: 'Start Date',
              hint: 'Start date',
              controller: controller.cashFlowStartDateController,
              width: 160.w,
              onTap: () => controller.selectDate(context, controller.cashFlowStartDateController),
              icon: Icons.calendar_today_outlined,
            ),
            _buildFilterField(
              context: context,
              label: 'End Date',
              hint: 'End date',
              controller: controller.cashFlowEndDateController,
              width: 160.w,
              onTap: () => controller.selectDate(context, controller.cashFlowEndDateController),
              icon: Icons.calendar_today_outlined,
            ),
            SizedBox(
              height: 48.h,
              child: ElevatedButton(
                onPressed: () => controller.loadCashFlow(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                child: Text(
                  'Filter',
                  style: TextStyle(color: Colors.white, fontFamily: AppTheme.fontBold, fontSize: AppTheme.fontSizeLabelLarge),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        _buildCashFlowTable(context, controller),
      ],
    );
  }

  Widget _buildCashFlowTable(BuildContext context, ReportController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : const Color(0xFFF1F3F9),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          // Table header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Row(
              children: [
                _buildHeaderCell('Date', flex: 2),
                _buildHeaderCell('Person in Charge', flex: 3),
                _buildHeaderCell('Purpose', flex: 3),
                _buildHeaderCell('Amount', flex: 2),
                _buildHeaderCell('Direction', flex: 2),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16.r)),
            ),
            child: Obx(() {
              final items = controller.cashFlowItems;
              if (items.isEmpty) {
                return SizedBox(
                  height: 300.h,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 48.sp, color: Colors.grey.shade400),
                        SizedBox(height: 16.h),
                        Text('No cash flow data found', style: TextStyle(color: Colors.grey, fontSize: AppTheme.fontSizeBodyLarge, fontFamily: AppTheme.fontMedium)),
                        SizedBox(height: 8.h),
                        Text('Try adjusting your date filters', style: TextStyle(color: Colors.grey.shade500, fontSize: AppTheme.fontSizeLabelMedium, fontFamily: AppTheme.fontRegular)),
                      ],
                    ),
                  ),
                );
              }

              // Summary row
              final totalOut = items.where((e) => e.direction == 'out').fold(0, (s, e) => s + e.amount);
              final totalIn = items.where((e) => e.direction == 'in').fold(0, (s, e) => s + e.amount);

              return Column(
                children: [
                  // Summary chips row
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    child: Row(
                      children: [
                        _buildCashFlowSummaryChip(
                          context,
                          label: 'Total In',
                          value: _formatCurrency(totalIn.toDouble()),
                          color: Colors.green,
                          icon: Icons.arrow_downward_rounded,
                        ),
                        SizedBox(width: 16.w),
                        _buildCashFlowSummaryChip(
                          context,
                          label: 'Total Out',
                          value: _formatCurrency(totalOut.toDouble()),
                          color: Colors.red,
                          icon: Icons.arrow_upward_rounded,
                        ),
                        SizedBox(width: 16.w),
                        _buildCashFlowSummaryChip(
                          context,
                          label: 'Net',
                          value: _formatCurrency((totalIn - totalOut).toDouble()),
                          color: (totalIn - totalOut) >= 0 ? Colors.blue : Colors.orange,
                          icon: Icons.balance_rounded,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isOut = item.direction == 'out';
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppTheme.borderColor(context).withValues(alpha: 0.3))),
                        ),
                        child: Row(
                          children: [
                            // Date
                            Expanded(
                              flex: 2,
                              child: Text(
                                item.date,
                                style: TextStyle(fontSize: AppTheme.fontSizeLabelMedium, fontFamily: AppTheme.fontMedium, color: AppTheme.textColor(context)),
                              ),
                            ),
                            // Person in Charge
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14.r,
                                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    child: Text(
                                      item.staffName.isNotEmpty ? item.staffName[0].toUpperCase() : '?',
                                      style: TextStyle(fontSize: 11.sp, color: AppTheme.primaryColor, fontFamily: AppTheme.fontBold),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      item.staffName.isNotEmpty ? item.staffName : item.staffEmail,
                                      style: TextStyle(fontSize: AppTheme.fontSizeLabelMedium, fontFamily: AppTheme.fontMedium, color: AppTheme.textColor(context)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Purpose
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.expenseName.isNotEmpty ? item.expenseName : '—',
                                    style: TextStyle(fontSize: AppTheme.fontSizeLabelMedium, fontFamily: AppTheme.fontMedium, color: AppTheme.textColor(context)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.note.isNotEmpty)
                                    Text(
                                      item.note,
                                      style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            // Amount
                            Expanded(
                              flex: 2,
                              child: Text(
                                _formatCurrency(item.amount.toDouble()),
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeLabelMedium,
                                  fontFamily: AppTheme.fontBold,
                                  color: isOut ? Colors.red.shade600 : Colors.green.shade600,
                                ),
                              ),
                            ),
                            // Direction badge
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: (isOut ? Colors.red : Colors.green).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isOut ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                        size: 12.sp,
                                        color: isOut ? Colors.red.shade600 : Colors.green.shade600,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        isOut ? 'Out' : 'In',
                                        style: TextStyle(
                                          fontSize: AppTheme.fontSizeLabelSmall,
                                          fontFamily: AppTheme.fontBold,
                                          color: isOut ? Colors.red.shade600 : Colors.green.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowSummaryChip(BuildContext context, {required String label, required String value, required Color color, required IconData icon}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16.sp, color: color),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10.sp, color: color, fontFamily: AppTheme.fontBold)),
                  Text(value, style: TextStyle(fontSize: 13.sp, color: color, fontFamily: AppTheme.fontBold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
