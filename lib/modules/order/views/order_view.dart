import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:semesta_pos/modules/order/controllers/order_controller.dart';
import 'package:semesta_pos/modules/report/controllers/report_controller.dart';
import 'package:semesta_pos/core/services/user_service.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  late final OrderController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(OrderController());
    // Data is initially loaded in Controller.onInit() from local SQLite.
    // No automatic network fetch here to ensure instant screen opening.
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      body: Column(
        children: [
          _buildHeader(context, controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                          color: AppTheme.primaryColor),
                      SizedBox(height: 16.h),
                      Text(
                        "Loading orders...",
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeLabelMedium,
                          color: isDark ? Colors.grey.shade100 : Colors.grey.shade900,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (controller.openOrders.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(32.w),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            size: 80.sp,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          "No Active Orders",
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeTitleMedium,
                            fontFamily: AppTheme.fontBold,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "Start a new order to see it here",
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeLabelMedium,
                            color: isDark
                                ? Colors.grey.shade100
                                : Colors.grey.shade900,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        ElevatedButton.icon(
                          onPressed: () => controller.navigateToPos(),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text("Create Order"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: EdgeInsets.symmetric(
                                horizontal: 32.w, vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return GridView.builder(
                padding: EdgeInsets.all(24.w),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 20.w,
                  mainAxisSpacing: 20.h,
                  childAspectRatio: 1.3,
                ),
                itemCount: controller.openOrders.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildAddOrderCard(context, controller);
                  }
                  final order = controller.openOrders[index - 1];
                  return _buildOrderCard(context, order, controller);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, OrderController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: AppTheme.primaryColor,
                  size: AppTheme.fontSizeTitleMedium + 4.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Active Orders",
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeTitleMedium,
                      fontFamily: AppTheme.fontBold,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Obx(() => Text(
                        "${controller.openOrders.length} order${controller.openOrders.length != 1 ? 's' : ''} found",
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeLabelLarge,
                          color: isDark ? Colors.grey.shade100 : Colors.grey.shade900,
                        ),
                      )),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 300.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkBackgroundColor
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                      color: isDark
                          ? AppTheme.darkBorderColor
                          : Colors.grey.withValues(alpha: 0.1)),
                ),
                child: TextField(
                  onChanged: (value) => controller.getOrders(query: value),
                  style: TextStyle(fontSize: AppTheme.fontSizeLabelMedium),
                  decoration: InputDecoration(
                    hintText: "Search by ID or Customer...",
                    hintStyle: TextStyle(
                        fontSize: AppTheme.fontSizeLabelMedium,
                        color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search_rounded,
                        size: AppTheme.fontSizeBodyLarge,
                        color: Colors.grey.shade400),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Obx(() => PopupMenuButton<String>(
                tooltip: "Options",
                icon: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: controller.isSyncing.value
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                        )
                      : Icon(Icons.more_vert_rounded, size: 20.sp, color: AppTheme.primaryColor),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                elevation: 4,
                onSelected: (value) {
                  if (value == 'sync') {
                    controller.refreshOrders();
                  } else if (value == 'toggle_filter') {
                    controller.filterActiveOnly.value = !controller.filterActiveOnly.value;
                    controller.getOrders();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'toggle_filter',
                    child: Row(
                      children: [
                        Icon(
                          controller.filterActiveOnly.value
                              ? Icons.filter_alt_rounded
                              : Icons.filter_alt_off_rounded,
                          size: 18.sp,
                          color: controller.filterActiveOnly.value ? AppTheme.primaryColor : Colors.grey,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          controller.filterActiveOnly.value ? "Show All Orders" : "Show Active Only",
                          style: TextStyle(
                            fontFamily: AppTheme.fontMedium,
                            fontSize: 14.sp,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'sync',
                    enabled: !controller.isSyncing.value,
                    child: Row(
                      children: [
                        Icon(Icons.sync_rounded, size: 18.sp, color: AppTheme.primaryColor),
                        SizedBox(width: 12.w),
                        Text(
                          controller.isSyncing.value ? "Syncing..." : "Sync Orders",
                          style: TextStyle(
                            fontFamily: AppTheme.fontMedium,
                            fontSize: 14.sp,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddOrderCard(BuildContext context, OrderController controller) {
    return GestureDetector(
      onTap: () => controller.navigateToPos(),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              width: 1,
              style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: 40.sp,
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: 12.h),
            Text(
              "New Order",
              style: TextStyle(
                fontSize: 18.sp,
                fontFamily: AppTheme.fontMedium,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order,
      OrderController controller) {
    final tanggal = order['tgl_penjualan'] ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = (order['label'] as String?)?.isNotEmpty == true
        ? order['label'] as String
        : (order['nama'] as String?)?.isNotEmpty == true
            ? order['nama'] as String
            : 'Walk-in Customer';
    final note = (order['order_note'] as String?) ?? '';
    final orderType = (order['order_type'] as String?)?.isNotEmpty == true
        ? order['order_type'] as String
        : 'Dine In';
    final statusId = int.tryParse(order['status']?.toString() ?? '1') ?? 1;
    final isPaid = statusId == 2;
    final isCancelled = statusId == 5;
    final isActive = !isPaid && !isCancelled;
    final int queueNo = int.tryParse(order['queue_number']?.toString() ?? '0') ?? 0;
    final bool hasRefund = (order['has_refund'] as int? ?? 0) == 1;

    // Build context menu items dynamically based on status
    final List<PopupMenuEntry<String>> menuItems = [];

    if (isActive) {
      menuItems.add(PopupMenuItem<String>(
        value: 'open',
        child: _menuItem(Icons.edit_note_rounded, 'Open in POS', Colors.blue, context),
      ));
      menuItems.add(PopupMenuItem<String>(
        value: 'cancel',
        child: _menuItem(Icons.cancel_outlined, 'Cancel Order', Colors.red, context),
      ));
    }

    if (isPaid) {
      menuItems.add(PopupMenuItem<String>(
        value: 'reprint',
        child: _menuItem(Icons.print_rounded, 'Reprint Receipt', AppTheme.primaryColor, context),
      ));
      
      // Khusus owner/managerial: bisa void order yang sudah closed atau edit (refund)
      if (Get.find<UserService>().isManagerialRole()) {
        menuItems.add(PopupMenuItem<String>(
          value: 'edit_void',
          child: _menuItem(Icons.edit_note_rounded, 'Edit Order', Colors.orange, context),
        ));
        menuItems.add(PopupMenuItem<String>(
          value: 'void',
          child: _menuItem(Icons.block_rounded, 'Set as Void', Colors.red, context),
        ));
      }
    }

    if (isCancelled) {
      menuItems.add(PopupMenuItem<String>(
        value: 'restore',
        child: _menuItem(Icons.restore_rounded, 'Buka Kembali', Colors.blue, context),
      ));
    }

    // Fallback to ensure dots always visible
    if (menuItems.isEmpty) {
      menuItems.add(PopupMenuItem<String>(
        value: 'details',
        child: _menuItem(Icons.info_outline_rounded, 'Detail Order', Colors.grey, context),
      ));
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: isActive ? () => controller.loadOrderIntoPos(order) : null,
          child: Opacity(
            opacity: isActive ? 1.0 : 0.65,
            child: Container(
              padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 10.h, bottom: 12.h),
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
                border: Border.all(
                    color: isDark
                        ? AppTheme.darkBorderColor
                        : Colors.grey.withValues(alpha: 0.1),
                    width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 32.h,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                      Row(
                        children: [
                          Text(
                            _formatTime(tanggal),
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeOverline + 3.sp,
                              color: isDark ? Colors.grey.shade100 : Colors.grey.shade900,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : isCancelled
                                      ? Colors.red.withValues(alpha: 0.1)
                                      : Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              isPaid ? "Closed" : isCancelled ? "Cancelled" : "Active",
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeLabelMedium,
                                color: isPaid
                                    ? Colors.green.shade700
                                    : isCancelled
                                        ? Colors.red.shade700
                                        : Colors.blue.shade700,
                                fontFamily: AppTheme.fontBold,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 24.w,
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.more_vert_rounded,
                                size: 20.sp,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              elevation: 4,
                              onSelected: (value) async {
                                if (value == 'open') {
                                  controller.loadOrderIntoPos(order);
                                } else if (value == 'cancel') {
                                  _showCancelDialog(context, order);
                                } else if (value == 'reprint') {
                                  final idPenjualan = order['id_penjualan'];
                                  if (idPenjualan == null) return;
                                  final reportCtrl = Get.isRegistered<ReportController>()
                                      ? Get.find<ReportController>()
                                      : Get.put(ReportController());
                                  final fetched = await reportCtrl.fetchOrderFullDetails(idPenjualan, order['id_member']);
                                  final items = fetched['items'] as List? ?? [];
                                  await reportCtrl.printReceiptOnly(order, items, member: fetched['member']);
                                } else if (value == 'void') {
                                  _showVoidDialog(context, order);
                                } else if (value == 'edit_void') {
                                  controller.loadOrderIntoPos(order, isRefundMode: true);
                                } else if (value == 'restore') {
                                  controller.restoreOrder(order);
                                }
                              },
                              itemBuilder: (context) => menuItems,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                  SizedBox(height: 10.h),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeBodyLarge,
                      fontFamily: AppTheme.fontBold,
                      color: AppTheme.textColor(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _getFormattedOrderId(order),
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeBodySmall,
                      color: isDark ? Colors.grey.shade100 : Colors.grey.shade900,
                    ),
                  ),
                  if (hasRefund) ...[
                    SizedBox(height: 2.h),
                    Text(
                      "Edited by Staff ID: ${order['id_user'] ?? '-'}",
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeLabelMedium,
                        fontFamily: AppTheme.fontMedium,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                  if (note.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text(
                      note.split('---ITEM NOTES---')[0].trim(),
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeLabelMedium,
                        color: isDark ? Colors.grey.shade100 : Colors.grey.shade900,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency((order['bayar'] ?? 0).toDouble()),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontFamily: AppTheme.fontBold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (queueNo > 0)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              margin: EdgeInsets.only(right: 12.w),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                "#${queueNo.toString().padLeft(3, '0')}",
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                          if (hasRefund)
                            Container(
                              margin: EdgeInsets.only(right: 6.w),
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                'Refunded',
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  color: Colors.orange.shade700,
                                  fontFamily: AppTheme.fontBold,
                                ),
                              ),
                            ),
                          Text(
                            orderType,
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeLabelLarge,
                              color: isDark ? Colors.grey.shade100 : Colors.grey.shade900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _menuItem(IconData icon, String label, Color color, BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17.sp, color: color),
        SizedBox(width: 10.w),
        Text(label, style: TextStyle(fontSize: 13.sp, fontFamily: AppTheme.fontMedium, color: AppTheme.textColor(context))),
      ],
    );
  }

  String _getFormattedOrderId(Map<String, dynamic> order) {
    final idPos = order['id_pos']?.toString() ?? '';
    if (idPos.length >= 6) {
      return idPos.substring(idPos.length - 6).toUpperCase();
    }
    return idPos.isEmpty ? "---" : idPos;
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '---';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      return DateFormat('HH:mm:ss dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return '---';
    }
  }

  void _showCancelDialog(BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        elevation: 8,
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange, size: 28.sp),
            SizedBox(width: 12.w),
            Text('Hapus Orderan?',
                style: TextStyle(
                    fontFamily: AppTheme.fontBold,
                    fontSize: AppTheme.fontSizeHeadline,
                    color: AppTheme.textColor(context))),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus order ini? Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(
              fontSize: AppTheme.fontSizeLabelMedium,
              color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            ),
            child: Text('Simpan',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontFamily: AppTheme.fontBold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Get.find<OrderController>().deleteOrder(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
              elevation: 0,
            ),
            child: const Text('Ya, Batalkan',
                style: TextStyle(fontFamily: AppTheme.fontBold)),
          ),
        ],
      ),
    );
  }

  void _showVoidDialog(BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        elevation: 8,
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red, size: 28.sp),
            SizedBox(width: 12.w),
            Text('Set as Void?',
                style: TextStyle(
                    fontFamily: AppTheme.fontBold,
                    fontSize: AppTheme.fontSizeHeadline,
                    color: AppTheme.textColor(context))),
          ],
        ),
        content: Text(
          'Transaksi ini sudah ditutup (Closed). Apakah Anda yakin ingin menandainya sebagai Void (Dibatalkan)?\nTotal pendapatan dari transaksi ini akan dikurangi.',
          style: TextStyle(
              fontSize: AppTheme.fontSizeLabelMedium,
              color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            ),
            child: Text('Kembali',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontFamily: AppTheme.fontBold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Get.find<OrderController>().deleteOrder(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
              elevation: 0,
            ),
            child: const Text('Ya, Void',
                style: TextStyle(fontFamily: AppTheme.fontBold)),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }
}
