import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:semesta_pos/modules/kitchen/controllers/kitchen_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class KitchenView extends StatelessWidget {
  const KitchenView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(KitchenController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackgroundColor(context),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildHeader(context, controller),
                    TabBar(
                      indicatorColor: AppTheme.primaryColor,
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: AppTheme.bodyLarge.copyWith(fontFamily: AppTheme.fontBold),
                      tabs: const [
                        Tab(text: "Active Orders"),
                        Tab(text: "Completed"),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildOrderList(context, controller, true),
                    _buildOrderList(context, controller, false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, KitchenController controller, bool isActive) {
    return Obx(() {
      final list = isActive ? controller.activeOrders : controller.doneOrders;

      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
      }

      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? Icons.restaurant_menu : Icons.check_circle_outline,
                size: 80.sp,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
              SizedBox(height: 16.h),
              Text(
                isActive ? "No active orders" : "No completed orders",
                style: AppTheme.bodyLarge.copyWith(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return Padding(
        padding: EdgeInsets.all(16.w),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : (MediaQuery.of(context).size.width > 800 ? 3 : 2),
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            childAspectRatio: 0.85,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            return _buildOrderCard(context, controller, item, isActive);
          },
        ),
      );
    });
  }

  Widget _buildOrderCard(BuildContext context, KitchenController controller, Map<String, dynamic> group, bool isActive) {
    final dateTime = DateTime.tryParse(group['tgl_penjualan'] ?? "") ?? DateTime.now();
    final timeStr = DateFormat('HH:mm').format(dateTime);
    final int queueNo = group['queue_number'] ?? 0;
    final String idPos = group['id_pos']?.toString() ?? "";
    final String orderCode = queueNo > 0 
        ? queueNo.toString().padLeft(3, '0')
        : (idPos.length >= 6 ? idPos.substring(idPos.length - 6).toUpperCase() : "---");
    final String orderType = group['order_type'] ?? "Regular";
    final List items = group['items'] as List? ?? [];
    String mainOrderNote = group['order_note']?.toString() ?? "";
    
    // Clean up note: only show main part before ITEM NOTES
    if (mainOrderNote.contains('---ITEM NOTES---')) {
      mainOrderNote = mainOrderNote.split('---ITEM NOTES---').first.trim();
    }
    // Remove any trailing <br /> or newlines
    mainOrderNote = mainOrderNote.replaceAll('<br />', '').replaceAll('\n', ' ').trim();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isActive ? Colors.transparent : Colors.green.withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of Card
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16.r), topRight: Radius.circular(16.r)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("#$orderCode", style: AppTheme.bodyLarge.copyWith(fontFamily: AppTheme.fontBold)),
                    Text(timeStr, style: AppTheme.labelMedium),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primaryColor : Colors.green,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    orderType.toUpperCase(),
                    style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          if (mainOrderNote.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              color: Colors.orange.withValues(alpha: 0.05),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14.sp, color: Colors.orange[800]),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      "Note: $mainOrderNote",
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontSize: 12.sp,
                        fontFamily: AppTheme.fontBold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Main Content - Grouped Items
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(12.w),
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => Divider(height: 16.h, color: Colors.grey.withValues(alpha: 0.1)),
              itemBuilder: (context, index) {
                final item = items[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            "${item['jumlah']}x",
                            style: AppTheme.bodySmall.copyWith(fontFamily: AppTheme.fontBold, color: AppTheme.primaryColor),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            item['nama_produk'] ?? "Unknown",
                            style: AppTheme.bodyMedium.copyWith(fontFamily: AppTheme.fontBold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (item['note'] != null && item['note'].toString().isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Padding(
                        padding: EdgeInsets.only(left: 32.w),
                        child: Text(
                          "* ${item['note']}",
                          style: TextStyle(color: Colors.orange[800], fontSize: 11.sp, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),

          // Bottom Action - Mark Group
          Padding(
            padding: EdgeInsets.all(12.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final String idPos = group['id_pos']?.toString() ?? "";
                  final List<int> ids = items.map<int>((e) => e['id_penjualan_detail'] as int).toList();
                  if (isActive) {
                    controller.markGroupAsDone(ids, idPos: idPos);
                  } else {
                    controller.markGroupAsActive(ids, idPos: idPos);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? AppTheme.primaryColor : Colors.grey[200],
                  foregroundColor: isActive ? Colors.white : Colors.black87,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isActive ? Icons.check_circle_outline : Icons.history, size: 18.sp),
                    SizedBox(width: 8.w),
                    Text(isActive ? "COMPLETE ORDER" : "RE-ACTIVATE"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, KitchenController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
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
                  Icons.restaurant_menu,
                  color: AppTheme.primaryColor,
                  size: AppTheme.fontSizeTitleMedium + 4.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Kitchen Display System",
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeTitleMedium,
                      fontFamily: AppTheme.fontBold,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "Manage incoming food and beverage orders",
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLabelLarge,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
              onPressed: () => controller.fetchKitchenOrders(),
              tooltip: 'Refresh Orders',
            ),
          ),
        ],
      ),
    );
  }
}
