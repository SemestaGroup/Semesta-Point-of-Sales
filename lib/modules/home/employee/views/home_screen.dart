import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/models/product/product_model.dart';
import 'package:semesta_pos/core/services/sync_service.dart';
import 'package:semesta_pos/core/models/penjualan_detail/penjualan_detail_model.dart';
import 'package:semesta_pos/modules/home/employee/controllers/home_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';
import 'package:semesta_pos/modules/home/employee/views/payment_screen.dart';
import 'package:semesta_pos/modules/home/employee/controllers/shift_controller.dart';
import 'package:semesta_pos/modules/home/employee/controllers/shift_audit_controller.dart';
import 'package:semesta_pos/modules/home/employee/views/shift_audit_page.dart';
import 'package:semesta_pos/modules/home/employee/widgets/custom_keypad_dialog.dart';
import 'package:semesta_pos/modules/setting/controllers/setting_controller.dart';
import 'package:semesta_pos/core/services/user_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _buildCartHeader(BuildContext context, HomeController controller) {
    // Diperkecil padding vertikalnya (16.h -> 8.h dan 12.h -> 4.h)
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Obx(() {
                  final isRefund = controller.isRefundMode.value;
                  return GestureDetector(
                    onTap: isRefund ? null : () => _showCustomerDialog(context, controller),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: (isRefund ? Colors.grey : AppTheme.primaryColor).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(CupertinoIcons.person_fill,
                              size: 16.sp,
                              color: isRefund ? Colors.grey : AppTheme.primaryColor),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Customer",
                                  style: AppTheme.labelMedium.copyWith(
                                      fontSize: 10.sp,
                                      color: Colors.grey)),
                              Text(
                                controller.customerName.isEmpty
                                    ? "Walk-in Customer"
                                    : controller.customerName,
                                style: AppTheme.titleLarge
                                    .copyWith(fontSize: 14.sp),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (!isRefund)
                          Icon(CupertinoIcons.chevron_down,
                              size: 14.sp, color: Colors.grey),
                      ],
                    ),
                  );
                }),
              ),
              SizedBox(width: 8.w),
              _buildIconButton(
                context,
                CupertinoIcons.ellipsis_circle,
                onTap: (details) => _showMoreMenu(context, controller, details),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          Obx(() {
            final isRefund = controller.isRefundMode.value;
            if (isRefund) {
              // In refund mode: show read-only locked labels
              return Row(
                children: [
                  Expanded(
                    child: _buildSecondaryAction(
                      context,
                      controller.selectedOrderType.value,
                      CupertinoIcons.tray,
                      onTap: null, // locked
                      backgroundColor: Colors.grey.withValues(alpha: 0.08),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _buildSecondaryAction(
                      context,
                      controller.orderNote.value.isEmpty ? "Order Note" : controller.orderNote.value.replaceAll('<br />', '').replaceAll('<br>', ''),
                      CupertinoIcons.text_bubble,
                      onTap: null, // locked
                      backgroundColor: Colors.grey.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: _buildSecondaryAction(
                        context,
                        controller.selectedOrderType.value,
                        CupertinoIcons.tray,
                        onTap: () => _showOrderTypeDialog(context, controller),
                      ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildSecondaryAction(
                        context,
                        controller.orderNote.value.isEmpty ? "Order Note" : controller.orderNote.value.replaceAll('<br />', '').replaceAll('<br>', ''),
                        CupertinoIcons.text_bubble,
                        onTap: () => _showNoteDialog(context, controller),
                      ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  String formatRupiah(int number) {
    if (number == 0) return 'Rp. 0';
    String s = number.abs().toString();
    String result = "";
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      count++;
      result = s[i] + result;
      if (count % 3 == 0 && i != 0) result = ".$result";
    }
    return 'Rp. ${number < 0 ? "-" : ""}$result';
  }

  @override
  Widget build(BuildContext context) {
    // Use find with fallback — never call Get.put inside build() as it
    // recreates the controller on every rebuild cycle.
    final controller = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());
    final shiftController = Get.isRegistered<ShiftController>()
        ? Get.find<ShiftController>()
        : Get.put(ShiftController());


    // Remove the auto-showing dialog logic to use a non-blocking overlay instead

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      resizeToAvoidBottomInset: false,
      body: SafeArea(

        // FIX: Removed monolithic Obx wrapping the ENTIRE body.
        // Previously every reactive change (e.g., cart update) caused a full
        // rebuild of the whole screen (sidebar + grid + cart). Now each section
        // only rebuilds itself.
        child: Stack(
          fit: StackFit.expand,
          children: [
            // MAIN CONTENT — Static base layer
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  // LEFT PANEL: Product Grid & Sidebar
                  Expanded(
                    flex: 7,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // BRAND SIDEBAR
                        _buildBrandSidebar(context, controller),
                        // PRODUCT AREA
                        Expanded(
                        child: Container(
                          color: AppTheme.scaffoldBackgroundColor(context),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 12.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: Full-width Search Bar & Profile Info
                                Row(
                                  children: [
                                    Obx(() => controller.currentParentId.value != null
                                        ? GestureDetector(
                                            onTap: () {
                                              controller.searchFocusNode.unfocus();
                                              controller.currentParentId.value = null;
                                              controller.getProductData();
                                            },
                                            child: Container(
                                              margin: EdgeInsets.only(right: 12.w),
                                              padding: EdgeInsets.all(12.w),
                                              decoration: BoxDecoration(
                                                color: AppTheme.cardColor(context),
                                                borderRadius: BorderRadius.circular(12.r),
                                                border: Border.all(color: AppTheme.borderColor(context)),
                                              ),
                                              child: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
                                            ),
                                          )
                                        : const SizedBox.shrink()),
                                    Expanded(
                                      child: Container(
                                        height: 50.h,
                                        decoration: BoxDecoration(
                                          color: AppTheme.cardColor(context),
                                          borderRadius: BorderRadius.circular(12.r),
                                          border: Border.all(
                                              color: AppTheme.borderColor(context)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.02),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            )
                                          ],
                                        ),
                                        child: TextField(
                                          controller: controller.searchProductController,
                                          focusNode: controller.searchFocusNode,
                                          onChanged: (value) =>
                                              controller.searchProduct(value),
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontMedium,
                                            fontSize: 14.sp,
                                            color: AppTheme.textColor(context),
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Search products...',
                                            hintStyle: TextStyle(
                                                fontFamily: AppTheme.fontRegular,
                                                fontSize: 14.sp,
                                                color: AppTheme.secondaryTextColor(
                                                    context)),
                                            prefixIcon: Icon(CupertinoIcons.search,
                                                color: AppTheme.primaryColor,
                                                size: 20.sp),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                                vertical: 11.h),
                                          ),
                                        ),
                                      ),
                                    ),

                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Expanded(
                                  // FIX: This Obx now only rebuilds the grid area,
                                  // not the sidebar or cart panel.
                                  child: Obx(() => controller
                                          .isLoadingProduct.value
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                              color: AppTheme.primaryColor))
                                      : controller.productModelList.isEmpty
                                          ? Center(
                                              child: Text('No products found',
                                                  style: AppTheme.bodyLarge))
                                          : (() {
                                              final settings = controller
                                                  .appService.posSettings;
                                              final display =
                                                  settings['display'] ?? {};
                                              final bool showPrice =
                                                  display['show_price']
                                                          as bool? ??
                                                      false;
                                              final bool showStock =
                                                  display['show_stock']
                                                          as bool? ??
                                                      false;

                                              double labelHeight =
                                                  (showPrice || showStock)
                                                      ? 72.h
                                                      : (display['show_name']
                                                                  as bool? ??
                                                              true
                                                          ? 44.h
                                                          : 0);
                                              double extent = 113.h +
                                                  labelHeight;

                                              // FIX: Pre-compute selected IDs as a Set for O(1)
                                              // lookup inside each card, instead of running
                                              // .any() (O(n)) inside 200 individual Obx listeners.
                                              final selectedIds = controller
                                                  .penjualanDetailModelList
                                                  .map((e) => e.idProduk)
                                                  .toSet();

                                              return GridView.builder(
                                                gridDelegate:
                                                    SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 3,
                                                  crossAxisSpacing: 10.w,
                                                  mainAxisExtent: extent,
                                                  mainAxisSpacing: 10.h,
                                                ),
                                                itemCount: controller
                                                    .productModelList.length,
                                                itemBuilder:
                                                    (context, index) {
                                                  var productItem = controller
                                                          .productModelList[
                                                      index];
                                                  return GestureDetector(
                                                    onTap: controller.isRefundMode.value
                                                        ? null
                                                        : () => controller.handleProductTap(productItem),
                                                    child: _buildProductItem(
                                                        context,
                                                        productItem,
                                                        controller,
                                                        selectedIds),
                                                  );
                                                },
                                              );
                                            }())),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // RIGHT PANEL
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor(context),
                      border: Border(
                        left:
                            BorderSide(color: AppTheme.borderColor(context)),
                      ),
                    ),
                    child: Column(
                      children: [
                        // 1. FIXED HEADER
                        _buildCartHeader(context, controller),
                        Divider(
                            height: 1, color: AppTheme.borderColor(context)),
                        // 2. SCROLLABLE CART LIST
                        Expanded(
                          child:
                              Obx(() => _buildCartList(context, controller)),
                        ),
                        // 3. FIXED FOOTER
                        _buildCartFooter(context, controller),
                      ],
                    ),
                  ),
                ),
              ],
            ),

          // SHIFT PROTECTION OVERLAY
          Obx(() {
            if (!shiftController.isDataLoaded.value) {
              return Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (shiftController.activeShift.value != null) {
              return const SizedBox.shrink();
            }

            final userService = Get.isRegistered<UserService>() ? Get.find<UserService>() : Get.put(UserService());
            final isOwner = userService.getRole().toLowerCase() == 'owner';

            // If owner has explicitly dismissed the popup (isTrialMode flag), hide overlay
            if (isOwner && shiftController.isOwnerTrialMode.value) {
              return const SizedBox.shrink();
            }

            return Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: BackdropFilter(
                    filter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.2),
                      BlendMode.darken,
                    ),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(32.w),
                        margin: EdgeInsets.symmetric(horizontal: 100.w),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor(context),
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.all(20.w),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(CupertinoIcons.lock_shield_fill,
                                    color: Colors.orange, size: 60.sp),
                              ),
                              SizedBox(height: 24.h),
                              Text("Shift Not Active",
                                  style: AppTheme.titleLarge
                                      .copyWith(fontSize: 24.sp)),
                              SizedBox(height: 12.h),
                              Text(
                                  "Please open a shift first to start transacting at the POS.",
                                  textAlign: TextAlign.center,
                                  style: AppTheme.bodyLarge.copyWith(
                                      color: AppTheme.secondaryTextColor(
                                          context))),
                              SizedBox(height: 32.h),
                              SizedBox(
                                width: double.infinity,
                                height: 55.h,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final candidate = await shiftController
                                        .getNextShiftCandidate();
                                    if (context.mounted) {
                                      _navigateToOpenShift(shiftController, candidate);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.r)),
                                  ),
                                  child: Text("Open Shift Now",
                                      style: AppTheme.bodyLarge.copyWith(
                                          color: Colors.white,
                                          fontFamily: AppTheme.fontBold)),
                                ),
                              ),
                              // Owner-only: option to try POS without opening shift
                              if (isOwner) ...[
                                SizedBox(height: 12.h),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50.h,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      shiftController.isOwnerTrialMode.value = true;
                                    },
                                    icon: Icon(CupertinoIcons.play_circle,
                                        size: 18.sp, color: Colors.orange),
                                    label: Text(
                                      "Coba POS Tanpa Buka Shift",
                                      style: AppTheme.bodyMedium.copyWith(
                                          color: Colors.orange,
                                          fontFamily: AppTheme.fontBold),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.orange.withValues(alpha: 0.6)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12.r)),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ), // BackdropFilter
                ); // Container
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryAction(
      BuildContext context, String label, IconData icon,
      {VoidCallback? onTap,
      Color? backgroundColor,
      Function(TapDownDetails)? onTapDown}) {
    return GestureDetector(
      onTap: onTap,
      onTapDown: onTapDown,
      child: Container(
        // Padding diperkecil drastis
        padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(8.r), // Border radius dikurangi
          border:
              Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
          // BoxShadow dihilangkan agar lebih clean dan flat (membantu menghemat ruang visual)
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 14.sp, color: AppTheme.primaryColor), // Icon diperkecil
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: AppTheme.fontBold,
                    fontSize: 12.sp, // Font diperkecil (14 -> 12)
                    color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderTypeDialog(BuildContext context, HomeController controller) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        backgroundColor: AppTheme.scaffoldBackgroundColor(context),
        child: Container(
          padding: EdgeInsets.all(28.w),
          width: 400.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Order Type",
                      style: AppTheme.titleLarge.copyWith(
                          fontSize: 22.sp, color: AppTheme.primaryColor)),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle),
                      child: Icon(Icons.close, size: 20.sp, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text("Select delivery method", style: AppTheme.labelMedium),
              SizedBox(height: 24.h),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Obx(() => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: controller.availableOrderTypes.map((type) {
                          bool isSelected =
                              controller.selectedOrderType.value == type;

                          IconData icon;
                          final lowType = type.toLowerCase();
                          if (lowType.contains("dine")) {
                            icon = CupertinoIcons.tray;
                          } else if (lowType.contains("take")) {
                            icon = CupertinoIcons.bag;
                          } else if (lowType.contains("go")) {
                            icon = Icons.delivery_dining;
                          } else if (lowType.contains("grab")) {
                            icon = Icons.delivery_dining;
                          } else if (lowType.contains("shopee")) {
                            icon = Icons.delivery_dining;
                          } else if (lowType.contains("tiktok")) {
                            icon = Icons.shopping_bag;
                          } else {
                            icon = Icons.local_shipping;
                          }

                          return GestureDetector(
                            onTap: () {
                              controller.selectedOrderType.value = type;
                              Get.back();
                            },
                            child: Container(
                              margin: EdgeInsets.only(bottom: 12.h),
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                        .withValues(alpha: 0.05)
                                    : AppTheme.cardColor(context),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : AppTheme.borderColor(context),
                                    width: isSelected ? 1.5.w : 1.w),
                              ),
                              child: Row(
                                children: [
                                  Icon(icon,
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : AppTheme.secondaryTextColor(
                                              context),
                                      size: 22.sp),
                                  SizedBox(width: 16.w),
                                  Text(type,
                                      style: AppTheme.bodyLarge.copyWith(
                                        fontFamily: isSelected
                                            ? AppTheme.fontBold
                                            : AppTheme.fontMedium,
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : AppTheme.textColor(context),
                                      )),
                                  const Spacer(),
                                  if (isSelected)
                                    Icon(Icons.check_circle,
                                        color: AppTheme.primaryColor,
                                        size: 20.sp),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomerDialog(BuildContext context, HomeController controller) {
    // Always refresh member list when opening dialog to ensure we have the latest data/addresses
    controller.getMember();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        backgroundColor: AppTheme.scaffoldBackgroundColor(context),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.fromLTRB(28.w, 28.w, 28.w,
                28.w + MediaQuery.of(context).viewInsets.bottom),
            width: 450.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() => Text(
                        controller.isAddingCustomer.value
                            ? "New Customer"
                            : "Customer & Label",
                        style: AppTheme.titleLarge.copyWith(
                            fontSize: 22.sp, color: AppTheme.primaryColor))),
                    Obx(() => GestureDetector(
                          onTap: () => controller.isAddingCustomer.value
                              ? controller.isAddingCustomer.value = false
                              : Get.back(),
                          child: Container(
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                shape: BoxShape.circle),
                            child: Icon(
                                controller.isAddingCustomer.value
                                    ? Icons.arrow_back
                                    : Icons.close,
                                size: 20.sp,
                                color: Colors.grey),
                          ),
                        )),
                  ],
                ),
                SizedBox(height: 16.h),
                // Label / Call ID Field (Integrated)
                Obx(() => controller.isAddingCustomer.value
                    ? Column(
                        children: [
                          _buildTextField(context, "Full Name",
                              controller.nameController, Icons.person),
                          SizedBox(height: 16.h),
                          _buildTextField(context, "Phone Number",
                              controller.phoneController, Icons.phone,
                              keyboardType: TextInputType.phone),
                          SizedBox(height: 16.h),
                          _buildTextField(context, "Address",
                              controller.addressController, Icons.location_on,
                              maxLines: 3),
                          SizedBox(height: 24.h),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => controller.saveNewCustomer(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r)),
                              ),
                              child: Text("Save Customer",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: AppTheme.fontBold,
                                      fontSize: 16.sp)),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor(context),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                  color: AppTheme.borderColor(context)),
                            ),
                            child: TextField(
                              autofocus:
                                  false, // Fix: Disable auto-focus to prevent keyboard pop-up
                              decoration: InputDecoration(
                                hintText: "Search customer name or phone...",
                                prefixIcon: const Icon(Icons.search,
                                    color: AppTheme.primaryColor),
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 14.h),
                              ),
                              onChanged: (value) {
                                controller.searchMemberQuery.value = value;
                              },
                            ),
                          ),
                          SizedBox(height: 16.h),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: 300.h),
                            child: Obx(() => controller.isLoadingMember.value
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : controller.filteredMemberList.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.person_off,
                                                size: 48.sp,
                                                color: Colors.grey.shade400),
                                            SizedBox(height: 8.h),
                                            Text("No customers found",
                                                style: AppTheme.labelMedium),
                                          ],
                                        ),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        itemCount: controller
                                            .filteredMemberList.length,
                                        separatorBuilder: (c, i) => Divider(
                                            color:
                                                AppTheme.borderColor(context),
                                            height: 1),
                                        itemBuilder: (context, index) {
                                          final member = controller
                                              .filteredMemberList[index];
                                          bool isSelected = controller
                                                  .selectedMember
                                                  .value
                                                  ?.idMember ==
                                              member.idMember;

                                          return ListTile(
                                            dense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 12.w,
                                                    vertical: 4.h),
                                            leading: CircleAvatar(
                                              radius: 16.r,
                                              backgroundColor: isSelected
                                                  ? AppTheme.primaryColor
                                                  : AppTheme.borderColor(
                                                      context),
                                              child: Icon(Icons.person,
                                                  size: 16.sp,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : AppTheme
                                                          .secondaryTextColor(
                                                              context)),
                                            ),
                                            title: Text(
                                                member.nama ?? "Unknown",
                                                style: AppTheme.bodyLarge
                                                    .copyWith(
                                                        fontSize: 14.sp,
                                                        fontFamily: isSelected
                                                            ? AppTheme.fontBold
                                                            : AppTheme
                                                                .fontRegular)),
                                            subtitle: Text(
                                                member.telepon ?? "No phone",
                                                style: AppTheme.labelMedium
                                                    .copyWith(fontSize: 11.sp)),
                                            trailing: isSelected
                                                ? Icon(Icons.check_circle,
                                                    color:
                                                        AppTheme.primaryColor,
                                                    size: 18.sp)
                                                : null,
                                            onTap: () {
                                              controller.selectedMember.value =
                                                  member;
                                              controller.memberId.value =
                                                  member.idMember;
                                              controller.customerLabel.value =
                                                  member.nama ?? '';
                                              Get.back();
                                            },
                                          );
                                        },
                                      )),
                          ),
                          SizedBox(height: 24.h),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                controller.clearCustomerForm();
                                controller.isAddingCustomer.value = true;
                              },
                              icon: const Icon(Icons.person_add_alt_1,
                                  color: Colors.white),
                              label: Text("Add New Customer",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: AppTheme.fontBold,
                                      fontSize: 16.sp)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.r)),
                              ),
                            ),
                          ),
                        ],
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNoteDialog(BuildContext context, HomeController controller) {
    final noteController =
        TextEditingController(text: controller.orderNote.value);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        backgroundColor: AppTheme.scaffoldBackgroundColor(context),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.fromLTRB(28.w, 28.w, 28.w,
                28.w + MediaQuery.of(context).viewInsets.bottom),
            width: 400.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Order Note",
                        style: AppTheme.titleLarge.copyWith(
                            fontSize: 22.sp, color: AppTheme.primaryColor)),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child:
                            Icon(Icons.close, size: 20.sp, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppTheme.borderColor(context)),
                  ),
                  child: TextField(
                    controller: noteController,
                    maxLines: 2,
                    style: AppTheme.bodyLarge.copyWith(fontSize: 16.sp),
                    decoration: InputDecoration(
                      hintText: "Add special instructions or requests...",
                      hintStyle: AppTheme.labelMedium.copyWith(fontSize: 14.sp),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12.w),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      controller.orderNote.value = noteController.text;
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                      elevation: 0,
                    ),
                    child: Text("Save Note",
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: AppTheme.fontBold,
                            fontSize: 16.sp)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDiscountDialog(
      BuildContext context, HomeController controller) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CustomKeypadDialog(
        initialValue: controller.manualDiscountValue.value,
        initialIsPercent: controller.manualDiscountIsPercent.value,
      ),
    );

    if (result != null) {
      controller.manualDiscountValue.value = result['value'];
      controller.manualDiscountIsPercent.value = result['isPercent'];
      controller.calculateTotals();
    }
  }

  void _showMoreMenu(
      BuildContext context, HomeController controller, TapDownDetails details) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu<dynamic>(
      context: context,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<dynamic>>[
        PopupMenuItem(
          height: 38.h,
          onTap: () => _showDiscountDialog(context, controller),
          child: Row(
            children: [
              Icon(CupertinoIcons.tag,
                  size: 18.sp, color: AppTheme.primaryColor),
              SizedBox(width: 12.w),
              Text("Discount",
                  style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textColor(context),
                      fontFamily: AppTheme.fontMedium))
            ],
          ),
        ),
        PopupMenuItem(
          height: 38.h,
          onTap: () => controller.clearOrder(),
          child: Row(
            children: [
              Icon(CupertinoIcons.clear_circled,
                  size: 18.sp, color: AppTheme.primaryColor),
              SizedBox(width: 12.w),
              Text("Clear Order",
                  style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textColor(context),
                      fontFamily: AppTheme.fontMedium))
            ],
          ),
        ),
        PopupMenuItem(
          height: 38.h,
          onTap: () => controller.cancelOrder(),
          child: Row(
            children: [
              Icon(CupertinoIcons.trash, size: 18.sp, color: Colors.redAccent),
              SizedBox(width: 12.w),
              Text("Cancel Order",
                  style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.redAccent,
                      fontFamily: AppTheme.fontMedium))
            ],
          ),
        ),
        PopupMenuItem(
          height: 38.h,
          child: Row(
            children: [
              Icon(CupertinoIcons.arrow_2_circlepath,
                  size: 18.sp, color: AppTheme.primaryColor),
              SizedBox(width: 12.w),
              Text("Sync Data",
                  style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textColor(context),
                      fontFamily: AppTheme.fontMedium))
            ],
          ),
          onTap: () async {
            final syncService = Get.find<SyncService>();
            try {
              Get.dialog(
                Obx(() => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r)),
                      backgroundColor:
                          AppTheme.scaffoldBackgroundColor(context),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          SizedBox(height: 24.h),
                          Text("Syncing data...", style: AppTheme.bodyLarge),
                          SizedBox(height: 8.h),
                          Text(syncService.syncStatus.value,
                              style: AppTheme.labelMedium.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontFamily: AppTheme.fontBold)),
                        ],
                      ),
                    )),
                barrierDismissible: false,
              );

              await syncService.syncBrands();
              await syncService.syncCategories();
              await syncService.syncProducts();
              await syncService.syncMembers();
              await syncService.pullRemoteOrders(unpaidOnly: true);
              await syncService.syncPaymentModes(); // Added payment modes sync

              await controller.updateCategoriesForBrand();
              await controller.getProductData();
              await controller.getMember();
              await controller.discoverOrderTypes();

              Get.back(); // close dialog

              Get.snackbar('Success', 'Everything is up to date',
                  icon: const Icon(CupertinoIcons.check_mark_circled,
                      color: Colors.green),
                  backgroundColor: Colors.green.withValues(alpha: 0.1));
            } catch (e) {
              if (Get.isDialogOpen ?? false) Get.back();
              Get.snackbar('Sync Error', e.toString(),
                  icon: const Icon(CupertinoIcons.exclamationmark_circle,
                      color: Colors.red),
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  duration: const Duration(seconds: 5));
            }
          },
        ),
        PopupMenuItem(
          height: 38.h,
          onTap: () async {
            final shiftController = Get.find<ShiftController>();
            if (shiftController.activeShift.value != null) {
              _navigateToCloseShift(shiftController);
            } else {
              final candidate = await shiftController.getNextShiftCandidate();
              if (context.mounted) {
                _navigateToOpenShift(shiftController, candidate);
              }
            }
          },
          child: Row(
            children: [
              Icon(CupertinoIcons.power,
                  size: 18.sp, color: AppTheme.primaryColor),
              SizedBox(width: 12.w),
              Obx(() => Text(
                  Get.find<ShiftController>().activeShift.value == null
                      ? "Buka Outlet"
                      : "Tutup Outlet",
                  style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textColor(context),
                      fontFamily: AppTheme.fontMedium)))
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          height: 38.h,
          child: Row(
            children: [
              Icon(CupertinoIcons.settings,
                  size: 18.sp, color: AppTheme.primaryColor),
              SizedBox(width: 12.w),
              Text("Settings",
                  style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textColor(context),
                      fontFamily: AppTheme.fontMedium))
            ],
          ),
          onTap: () {
            _showPosSettingsDialog(context, controller);
          },
        ),
      ],
    );
  }

  void _showPosSettingsDialog(BuildContext context, HomeController controller) {
    final currentSettings =
        Map<String, dynamic>.from(controller.appService.posSettings);
    final displaySettings =
        Map<String, dynamic>.from(currentSettings['display'] ?? {});

    final printingSettings =
        Map<String, dynamic>.from(currentSettings['printing'] ?? {});

    final bool initName = displaySettings['show_name'] as bool? ?? true;
    final bool initPrice = displaySettings['show_price'] as bool? ?? false;
    final bool initStock = displaySettings['show_stock'] as bool? ?? false;
    final bool initAutoPrint = printingSettings['auto_print'] as bool? ?? false;

    final RxBool showImage = true.obs; // LOCKED - image always shown

    RxBool showName = initName.obs;
    RxBool showPrice = initPrice.obs;
    RxBool showStock = initStock.obs;
    RxBool autoPrint = initAutoPrint.obs;
    RxInt activeTab = 0.obs;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        backgroundColor: AppTheme.scaffoldBackgroundColor(context),
        child: SizedBox(
          width: 550.w,
          height: 480.h,
          child: Row(
            children: [
              Container(
                width: 180.w,
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      bottomLeft: Radius.circular(16.r)),
                  border: Border(
                      right: BorderSide(color: AppTheme.borderColor(context))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text("POS Settings",
                          style: TextStyle(
                              fontSize: 18.sp,
                              fontFamily: AppTheme.fontBold,
                              color: AppTheme.primaryColor)),
                    ),
                    Divider(height: 1, color: AppTheme.borderColor(context)),
                    Obx(() => _buildSettingsTabItem(
                        context,
                        "Display",
                        CupertinoIcons.rectangle_grid_2x2,
                        activeTab.value == 0,
                        () => activeTab.value = 0)),
                    Obx(() => _buildSettingsTabItem(
                        context,
                        "Printing",
                        CupertinoIcons.printer,
                        activeTab.value == 1,
                        () => activeTab.value = 1)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.w, vertical: 16.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(() => Text(
                              activeTab.value == 0
                                  ? "Display Options"
                                  : (activeTab.value == 1
                                      ? "Printing Options"
                                      : "Settings"),
                              style: TextStyle(
                                  fontSize: 16.sp,
                                  fontFamily: AppTheme.fontBold,
                                  color: AppTheme.textColor(context)))),
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: Icon(Icons.close,
                                color: Colors.grey.shade400, size: 22.sp),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: AppTheme.borderColor(context)),
                    Expanded(
                      child: Obx(() {
                        if (activeTab.value == 0) {
                          return ListView(
                            padding: EdgeInsets.symmetric(
                                horizontal: 24.w, vertical: 16.h),
                            children: [
                              Text(
                                  "Customize what product information is visible on the grid cards.",
                                  style: AppTheme.labelMedium
                                      .copyWith(fontSize: 12.sp)),
                              SizedBox(height: 14.h),
                              // Product Images - LOCKED ALWAYS ON
                              ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                contentPadding: EdgeInsets.zero,
                                title: Row(
                                  children: [
                                    Text("Product images",
                                        style: AppTheme.bodyLarge
                                            .copyWith(fontSize: 14.sp)),
                                    SizedBox(width: 8.w),
                                    Icon(CupertinoIcons.lock_fill,
                                        size: 12.sp,
                                        color: AppTheme.primaryColor
                                            .withValues(alpha: 0.6)),
                                  ],
                                ),
                                subtitle: Text("Always displayed (required)",
                                    style: AppTheme.labelMedium
                                        .copyWith(fontSize: 12.sp)),
                                trailing: const Opacity(
                                  opacity: 0.6,
                                  child: Switch(
                                    value: true,
                                    activeThumbColor: AppTheme.primaryColor,
                                    onChanged: null, // LOCKED
                                  ),
                                ),
                              ),

                              Obx(() => SwitchListTile(
                                    title: Text("Product names",
                                        style: AppTheme.bodyLarge
                                            .copyWith(fontSize: 14.sp)),
                                    subtitle: Text("Enable multi-line labels",
                                        style: AppTheme.labelMedium
                                            .copyWith(fontSize: 12.sp)),
                                    value: showName.value,
                                    activeThumbColor: AppTheme.primaryColor,
                                    onChanged: (val) => showName.value = val,
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    contentPadding: EdgeInsets.zero,
                                  )),
                              Obx(() => SwitchListTile(
                                    title: Text("Current pricing",
                                        style: AppTheme.bodyLarge
                                            .copyWith(fontSize: 14.sp)),
                                    subtitle: Text("Show base selling price",
                                        style: AppTheme.labelMedium
                                            .copyWith(fontSize: 12.sp)),
                                    value: showPrice.value,
                                    activeThumbColor: AppTheme.primaryColor,
                                    onChanged: (val) => showPrice.value = val,
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    contentPadding: EdgeInsets.zero,
                                  )),
                              Obx(() => SwitchListTile(
                                    title: Text("Stock levels",
                                        style: AppTheme.bodyLarge
                                            .copyWith(fontSize: 14.sp)),
                                    subtitle: Text("Indicate remaining stock",
                                        style: AppTheme.labelMedium
                                            .copyWith(fontSize: 12.sp)),
                                    value: showStock.value,
                                    activeThumbColor: AppTheme.primaryColor,
                                    onChanged: (val) => showStock.value = val,
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    contentPadding: EdgeInsets.zero,
                                  )),
                              SizedBox(height: 16.h),
                            ],
                          );
                        } else if (activeTab.value == 1) {
                          return ListView(
                            padding: EdgeInsets.symmetric(
                                horizontal: 24.w, vertical: 16.h),
                            children: [
                              Text("Configure your thermal printer behavior.",
                                  style: AppTheme.labelMedium
                                      .copyWith(fontSize: 12.sp)),
                              SizedBox(height: 14.h),
                              Obx(() => SwitchListTile(
                                    title: Text("Auto-print Receipt",
                                        style: AppTheme.bodyLarge
                                            .copyWith(fontSize: 14.sp)),
                                    subtitle: Text(
                                        "Print automatically after payment",
                                        style: AppTheme.labelMedium
                                            .copyWith(fontSize: 12.sp)),
                                    value: autoPrint.value,
                                    activeThumbColor: AppTheme.primaryColor,
                                    onChanged: (val) => autoPrint.value = val,
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    contentPadding: EdgeInsets.zero,
                                  )),
                            ],
                          );
                        } else {
                          return const SizedBox();
                        }
                      }),
                    ),
                    Divider(height: 1, color: AppTheme.borderColor(context)),
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Get.back(),
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20.w, vertical: 10.h)),
                            child: Text("CANCEL",
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13.sp,
                                    fontFamily: AppTheme.fontBold)),
                          ),
                          SizedBox(width: 8.w),
                          Obx(() => ElevatedButton(
                                onPressed: controller.isSavingSettings.value
                                    ? null
                                    : () {
                                        // Validation: Minimum 2 options must be selected
                                        int selectedCount = 0;
                                        if (showImage.value) selectedCount++;
                                        if (showName.value) selectedCount++;
                                        if (showPrice.value) selectedCount++;
                                        if (showStock.value) selectedCount++;

                                        if (selectedCount < 2 &&
                                            !autoPrint.value) {
                                          // Count logic updated
                                          // Logic for autoPrint doesn't count towards display min
                                        }

                                        Map<String, dynamic> updatedSettings =
                                            Map.from(currentSettings);
                                        updatedSettings['display'] = {
                                          'show_image':
                                              true, // LOCKED - always true
                                          'show_name': showName.value,
                                          'show_price': showPrice.value,
                                          'show_stock': showStock.value,
                                        };
                                        updatedSettings['printing'] = {
                                          'auto_print': autoPrint.value,
                                        };
                                        Get.back();
                                        controller
                                            .savePosSettings(updatedSettings);
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 24.w, vertical: 10.h),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r)),
                                  elevation: 0,
                                ),
                                child: controller.isSavingSettings.value
                                    ? SizedBox(
                                        width: 20.w,
                                        height: 20.w,
                                        child: const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : Text("SAVE CHANGES",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13.sp,
                                            fontFamily: AppTheme.fontBold)),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTabItem(BuildContext context, String label,
      IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          border: isActive
              ? Border(
                  right: BorderSide(color: AppTheme.primaryColor, width: 3.w))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20.sp,
                color: isActive ? AppTheme.primaryColor : Colors.grey.shade500),
            SizedBox(width: 12.w),
            Text(label,
                style: TextStyle(
                    fontSize: 14.sp,
                    fontFamily:
                        isActive ? AppTheme.fontBold : AppTheme.fontMedium,
                    color: isActive
                        ? AppTheme.primaryColor
                        : AppTheme.textColor(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandSidebar(BuildContext context, HomeController controller) {
    return Container(
      width: 130.w,
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        border: Border(right: BorderSide(color: AppTheme.borderColor(context))),
      ),
      child: Column(
        children: [
          // Sidebar header icon
          GestureDetector(
            onTap: () {
              controller.expandedBrandId.value = -1;
              controller.filterByBrandDirect(0);
            },
            child: Obx(() => Container(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: controller.selectedBrandId.value == 0 &&
                            controller.expandedBrandId.value == -1
                        ? AppTheme.primaryColor.withValues(alpha: 0.08)
                        : Colors.transparent,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.square_grid_2x2_fill,
                          color: AppTheme.primaryColor, size: 22.sp),
                      SizedBox(width: 6.w),
                      Text('All',
                          style: TextStyle(
                            fontFamily: AppTheme.fontBold,
                            fontSize: 13.sp,
                            color: AppTheme.primaryColor,
                          )),
                    ],
                  ),
                )),
          ),
          Divider(height: 1, color: AppTheme.borderColor(context)),
          Expanded(
            child: Obx(() => ListView(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  children: controller.brandList.map((brand) {
                    final brandId = brand['id_brand'] as int;
                    final brandName = brand['nama_brand']?.toString() ?? '';
                    final isExpanded =
                        controller.expandedBrandId.value == brandId;
                    final isBrandActive =
                        controller.selectedBrandId.value == brandId;

                    return _buildBrandAccordionItem(
                      context,
                      controller,
                      brandId: brandId,
                      brandName: brandName,
                      isExpanded: isExpanded,
                      isBrandActive: isBrandActive,
                    );
                  }).toList(),
                )),
          ),
        ],
      ),
    );
  }
  Widget _buildBrandAccordionItem(
    BuildContext context,
    HomeController controller, {
    required int brandId,
    required String brandName,
    required bool isExpanded,
    required bool isBrandActive,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Brand header row
        GestureDetector(
          onTap: () {
            if (controller.expandedBrandId.value == brandId) {
              // Collapse if already expanded — reset product filter to "All"
              controller.expandedBrandId.value = -1;
              controller.filterByBrandDirect(0);
            } else {
              // Expand this brand and filter products by it
              controller.expandedBrandId.value = brandId;
              controller.filterByBrandDirect(brandId);
            }
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isBrandActive
                  ? AppTheme.primaryColor
                  : isExpanded
                      ? AppTheme.primaryColor.withValues(alpha: 0.06)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: isBrandActive
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Brand initial avatar
                Container(
                  width: 24.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: isBrandActive
                        ? Colors.white.withValues(alpha: 0.25)
                        : AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    brandName.isNotEmpty ? brandName[0].toUpperCase() : 'B',
                    style: TextStyle(
                      fontFamily: AppTheme.fontBold,
                      fontSize: 13.sp,
                      color:
                          isBrandActive ? Colors.white : AppTheme.primaryColor,
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    brandName,
                    style: TextStyle(
                      fontFamily: AppTheme.fontBold,
                      fontSize: 12.sp,
                      color: isBrandActive
                          ? Colors.white
                          : AppTheme.textColor(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  isExpanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 14.sp,
                  color: isBrandActive
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppTheme.secondaryTextColor(context),
                ),
              ],
            ),
          ),
        ),
        // Expanded category list
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: EdgeInsets.only(left: 8.w, right: 8.w, bottom: 4.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // "All [Brand]" item at the top
                _buildCategoryItem(
                  context,
                  controller,
                  label: 'All',
                  categoryId: 0,
                  isSelected:
                      isBrandActive && controller.selectedCategoryId.value == 0,
                  onTap: () {
                    controller.selectedCategoryId.value = 0;
                    controller.filterByBrand(brandId);
                  },
                ),
                // Category items
                ...controller.categoryList.map((cat) {
                  final catIdValue = cat['id_kategori'];
                  final int catId = catIdValue is int
                      ? catIdValue
                      : int.tryParse(catIdValue.toString()) ?? 0;
                  final catName = cat['nama_kategori']?.toString() ?? '';
                  return _buildCategoryItem(
                    context,
                    controller,
                    label: catName,
                    categoryId: catId,
                    isSelected: controller.selectedCategoryId.value == catId,
                    onTap: () => controller.filterByCategory(catId),
                  );
                }),
              ],
            ),
          ),
        ),
        Divider(
            height: 1,
            color: AppTheme.borderColor(context).withValues(alpha: 0.4),
            indent: 8.w,
            endIndent: 8.w),
      ],
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    HomeController controller, {
    required String label,
    required int categoryId,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(top: 3.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: isSelected
              ? Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.4), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 4.w,
              height: 4.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.secondaryTextColor(context),
              ),
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontBold,
                  fontSize: 11.5.sp,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textColor(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(CupertinoIcons.checkmark_alt,
                  size: 10.sp, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, ProductModel productItem,
      HomeController controller, Set<int?> selectedIds) {
    // FIX: No Obx here. The parent GridView Obx already rebuilds when cart changes.
    // We use a pre-computed selectedIds Set for O(1) lookup instead of O(n) .any().
    final isSelected = selectedIds.contains(productItem.idProduk);

    final settings = controller.appService.posSettings;
    final display = settings['display'] ?? {};
    const bool showImg = true; // IMAGE IS ALWAYS SHOWN - LOCKED
    final bool showName = display['show_name'] as bool? ?? true;
    final bool showPrice = display['show_price'] as bool? ?? false;
    final bool showStock = display['show_stock'] as bool? ?? false;

    // Check if product has a discount
    final bool hasDiscount = productItem.discountTotal > 0;

    // Check if product has children
    final bool hasChildren = productItem.children != null && 
                             productItem.children != "[]" && 
                             productItem.children != "null" && 
                             productItem.children!.isNotEmpty;

      return Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.borderColor(context),
            width: isSelected ? 2.w : 1.w,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showImg)
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(isSelected ? 10.r : 12.r),
                          bottom: Radius.circular(
                              (!showName && !showPrice && !showStock)
                                  ? (isSelected ? 10.r : 12.r)
                                  : 0)),
                      child:
                          productItem.img != null && productItem.img!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: controller
                                      .getProductImageUrl(productItem.img!),
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) =>
                                      _buildPlaceholderImage(),
                                  errorWidget: (context, url, error) =>
                                      _buildPlaceholderImage(),
                                )
                              : _buildPlaceholderImage(),
                    ),
                  ),
                if (showName || showPrice || showStock)
                  Container(
                    height: (showPrice || showStock)
                        ? 72.h
                        : (showName
                            ? 44.h
                            : 0), // Dynamic height based on visibility
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: (showPrice || showStock) ? 6.h : 4.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: (showPrice || showStock)
                          ? MainAxisAlignment.spaceBetween
                          : MainAxisAlignment.center, // Center when name only
                      children: [
                        if (showName)
                          Text(
                            productItem.namaProduk!,
                            textAlign: TextAlign.center,
                            style: AppTheme.bodyLarge.copyWith(
                                height: 1.1,
                                fontSize: 13.sp,
                                fontFamily: AppTheme.fontBold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (showName && (showPrice || showStock))
                          SizedBox(height: 4.h),
                        if (showPrice || showStock)
                          Row(
                            mainAxisAlignment: MainAxisAlignment
                                .spaceBetween, // Separate price and stock
                            children: [
                              if (showPrice)
                                Obx(() => Text(
                                      formatRupiah(controller.getDynamicPrice(
                                          productItem.orderTypes,
                                          controller.selectedOrderType.value,
                                          productItem.hargaJual)),
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontFamily: AppTheme.fontBold,
                                        fontSize: 13.sp,
                                      ),
                                      textAlign: TextAlign.left,
                                    )),
                              if (showStock)
                                Text(
                                  'Stock: ${productItem.stok}',
                                  style: AppTheme.labelMedium
                                      .copyWith(fontSize: 11.sp),
                                  textAlign: TextAlign.right,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            // PROMO BADGE: shown when product has a discount
            if (hasDiscount)
              Positioned(
                top: 8.h,
                left: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(6.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.tag_fill,
                          size: 9.sp, color: Colors.white),
                      SizedBox(width: 3.w),
                      Text(
                        'PROMO',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: AppTheme.fontBold,
                          fontSize: 9.sp,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // MENU BADGE: shown when product is a parent
            if (hasChildren)
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(6.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.square_stack_3d_up_fill,
                          size: 10.sp, color: Colors.white),
                      SizedBox(width: 4.w),
                      Text(
                        'MENU',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: AppTheme.fontBold,
                          fontSize: 9.sp,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (isSelected && !hasChildren)
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14.sp,
                  ),
                ),
              ),
          ],
        ),
      );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppTheme.darkBackgroundColor.withValues(alpha: 0.05),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.photo,
              color: Colors.grey.shade400,
              size: 32.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              "No Image",
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 10.sp,
                fontFamily: AppTheme.fontRegular,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemRow(BuildContext context, HomeController controller,
      PenjualanDetailModel item, int index) {
    final bool isRefundRow = item.isRefund;
    return InkWell(
      onTap: isRefundRow
          ? () => _showAdjustRefundDialog(context, controller, index)
          : () => _showItemEditDialog(context, controller, index),
      child: Padding(
        // Padding vertikal diperkecil (10.h -> 4.h) untuk merapatkan list
        padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName ?? "Unknown Product",
                      style: AppTheme.bodyLarge.copyWith(
                          fontSize: 15.sp,
                          fontFamily: AppTheme.fontBold,
                          color: isRefundRow ? Colors.red.shade400 : null),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  SizedBox(height: 2.h), // Jarak teks diperkecil
                  if (item.hargaAwal > 0 && item.hargaAwal > item.hargaJual)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatRupiah(item.hargaAwal),
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11.sp,
                            decoration: TextDecoration.lineThrough,
                            height: 1.0, // Rapatkan tinggi baris
                          ),
                        ),
                        Text(
                          "${formatRupiah(item.hargaJual)}  x ${item.jumlah}",
                          style: AppTheme.labelMedium
                              .copyWith(fontSize: 12.sp, height: 1.0),
                        ),
                      ],
                    )
                  else
                    Text("${formatRupiah(item.hargaJual)}  x ${item.jumlah}",
                        style: AppTheme.labelMedium
                            .copyWith(fontSize: 12.sp, height: 1.0)),


                  if (item.discountTotal > 0)
                    Builder(builder: (_) {
                      final base =
                          item.hargaAwal > 0 ? item.hargaAwal : item.hargaJual;
                      final nominalDiscount = item.discountType == 'percent'
                          ? (base * item.discountTotal / 100).round()
                          : item.discountTotal;
                      final label = item.discountType == 'percent'
                          ? 'Disc ${item.discountTotal}% = -${formatRupiah(nominalDiscount)}'
                          : 'Disc -${formatRupiah(nominalDiscount)}';
                      return Padding(
                        padding: EdgeInsets.only(
                            top: 2.h), // Jarak diskon diperkecil
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.tag_fill,
                                size: 10.sp, color: const Color(0xFFFF6B35)),
                            SizedBox(width: 4.w),
                            Text(
                              label,
                              style: TextStyle(
                                color: const Color(0xFFFF6B35),
                                fontSize: 10.sp,
                                fontFamily: AppTheme.fontMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  if (item.note.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Text(item.note,
                          style:
                              TextStyle(color: Colors.grey, fontSize: 10.sp)),
                    ),
                  // Refund badge (replaces normal orderType badge for refund rows)
                  if (isRefundRow)
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.arrow_uturn_left,
                              size: 10.sp, color: Colors.red.shade400),
                          SizedBox(width: 3.w),
                          Text(
                            'Refund • ${item.jumlah} item',
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontSize: 9.sp,
                              fontFamily: AppTheme.fontBold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (item.orderType.isNotEmpty && item.orderType != controller.selectedOrderType.value)
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(item.orderType,
                            style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 9.sp,
                                fontFamily: AppTheme.fontBold)),
                      ),
                    ),
                ],
              ),
            ),
            Text(formatRupiah(item.subtotal),
                style: TextStyle(
                    color: isRefundRow ? Colors.red.shade400 : AppTheme.primaryColor,
                    fontFamily: AppTheme.fontBold,
                    fontSize: 15.sp,
                    decoration: isRefundRow ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.red.shade400)),

          ],
        ),
      ),
    );
  }
  void _showAdjustRefundDialog(
      BuildContext context, HomeController controller, int index) {
    final item = controller.penjualanDetailModelList[index];
    final int originalQty =
        item.originalQty > 0 ? item.originalQty : item.jumlah;
    final qty = item.jumlah.obs; // current refund qty

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(CupertinoIcons.arrow_uturn_left,
                    size: 18.sp, color: Colors.red.shade400),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Adjust Refund: ${item.productName ?? "Item"}',
                    style: AppTheme.titleLarge.copyWith(
                        fontSize: 15.sp, fontFamily: AppTheme.fontBold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              'Original qty: $originalQty  •  Set refund qty (0 = cancel refund)',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
            SizedBox(height: 20.h),
            Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildQtyBtn(context, CupertinoIcons.minus,
                        onTap: qty.value > 0 ? () => qty.value-- : null),
                    Container(
                      width: 90.w,
                      alignment: Alignment.center,
                      child: Text(
                        qty.value == 0 ? 'Cancel' : qty.value.toString(),
                        style: AppTheme.titleLarge.copyWith(
                          fontSize: 26.sp,
                          color: qty.value == 0
                              ? Colors.grey
                              : Colors.red.shade400,
                        ),
                      ),
                    ),
                    _buildQtyBtn(context, CupertinoIcons.plus,
                        onTap: qty.value < originalQty
                            ? () => qty.value++
                            : null),
                  ],
                )),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: Obx(() => _buildPrimaryButton(
                    qty.value == 0 ? 'Cancel Refund' : 'Update Refund',
                    qty.value == 0
                        ? CupertinoIcons.xmark_circle_fill
                        : CupertinoIcons.checkmark_shield_fill,
                    onTap: () {
                      Get.back();
                      controller.adjustRefundQty(index, qty.value);
                    },
                    backgroundColor:
                        qty.value == 0 ? Colors.grey.shade600 : Colors.red.shade700,
                  )),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showItemEditDialog(
      BuildContext context, HomeController controller, int index) {
    final item = controller.penjualanDetailModelList[index];
    final qty = item.jumlah.obs;
    final int maxQty = controller.isRefundMode.value && item.originalQty > 0
        ? item.originalQty
        : (item.totalStock > 0 ? item.totalStock : 9999);
    final noteController = TextEditingController(text: item.note);
    final selectedType = item.orderType.obs;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        elevation: 8,
        backgroundColor: AppTheme.scaffoldBackgroundColor(context),
        child: SingleChildScrollView(
          child: Container(
            width: 400.w,
            padding: EdgeInsets.fromLTRB(28.w, 28.w, 28.w,
                28.w + MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Edit Order",
                        style: AppTheme.titleLarge.copyWith(
                            fontSize: 18.sp, color: AppTheme.primaryColor)),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child:
                            Icon(Icons.close, size: 20.sp, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(item.productName ?? "Product Name",
                    style: AppTheme.bodyLarge.copyWith(
                        fontSize: 18.sp,
                        color: AppTheme.secondaryTextColor(context))),
                SizedBox(height: 12.h),

                // Quantity Section
                Text("Quantity",
                    style: AppTheme.labelMedium
                        .copyWith(fontFamily: AppTheme.fontBold)),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildQtyBtn(context, CupertinoIcons.minus, onTap: () {
                      if (qty.value > 1) qty.value--;
                    }),
                    Container(
                      width: 100.w,
                      alignment: Alignment.center,
                      child: Obx(() => Text(qty.value.toString(),
                          style:
                              AppTheme.titleLarge.copyWith(fontSize: 28.sp))),
                    ),
                    Obx(() => _buildQtyBtn(context, CupertinoIcons.plus,
                        onTap: qty.value >= maxQty ? null : () => qty.value++)),
                  ],
                ),
                if (controller.isRefundMode.value && maxQty > 0)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      'Max refund qty: $maxQty',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.red.shade400,
                        fontFamily: AppTheme.fontMedium,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(height: 12.h),

                // Fields
                _buildDropdownField(
                  context, "Order Type", selectedType,
                  controller.isRefundMode.value
                      ? [
                          ...controller.availableOrderTypes.map((t) => t),
                          if (!controller.availableOrderTypes.contains('Refund')) 'Refund',
                        ]
                      : controller.availableOrderTypes,
                ),
                SizedBox(height: 12.h),

                // PRICE PREVIEW SECTION
                Obx(() {
                  // Re-calculate price for PREVIEW only
                  var productDb = controller.productModelList
                      .firstWhereOrNull((p) => p.idProduk == item.idProduk);
                  int defaultBasePrice = productDb?.hargaJual ??
                      (item.hargaAwal > 0 ? item.hargaAwal : item.hargaJual);

                  int dynamicUnitPrice = controller.getDynamicPrice(
                      item.orderTypesJson,
                      selectedType.value,
                      defaultBasePrice);
                  int finalUnitPrice = dynamicUnitPrice;

                  // Apply discounts for preview
                  if (item.discountTotal > 0) {
                    if (item.discountType == 'percent') {
                      finalUnitPrice = dynamicUnitPrice -
                          (dynamicUnitPrice * item.discountTotal ~/ 100);
                    } else {
                      finalUnitPrice = dynamicUnitPrice - item.discountTotal;
                    }
                    if (finalUnitPrice < 0) finalUnitPrice = 0;
                  }

                  int currentSubtotal = finalUnitPrice * qty.value;

                  return Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Unit Price",
                                style: AppTheme.labelMedium
                                    .copyWith(fontSize: 12.sp)),
                            Text(formatRupiah(finalUnitPrice),
                                style: AppTheme.bodyLarge.copyWith(
                                    fontSize: 14.sp,
                                    fontFamily: AppTheme.fontBold)),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Subtotal",
                                style: AppTheme.labelMedium.copyWith(
                                    fontSize: 12.sp,
                                    color: AppTheme.primaryColor)),
                            Text(formatRupiah(currentSubtotal),
                                style: AppTheme.titleLarge.copyWith(
                                    fontSize: 18.sp,
                                    color: AppTheme.primaryColor,
                                    fontFamily: AppTheme.fontBold)),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                SizedBox(height: 12.h),
                _buildNoteField(
                    context, "Notes / Special Requests", noteController),
                SizedBox(height: 16.h),

                // Actions
                Row(
                  children: [
                    if (!controller.isRefundMode.value) ...[
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          icon: const Icon(CupertinoIcons.trash, size: 18),
                          onPressed: () {
                            controller.removeItemCart(index);
                            Get.back();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r)),
                          ),
                          label: Text("Delete",
                              style: TextStyle(
                                  fontFamily: AppTheme.fontBold,
                                  fontSize: 16.sp)),
                        ),
                      ),
                      SizedBox(width: 12.w),
                    ],
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: () {
                          controller.updateItemCart(index,
                              qty: qty.value,
                              note: noteController.text,
                              orderType: selectedType.value);
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                          elevation: 0,
                        ),
                        child: Text("Update Order",
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: AppTheme.fontBold,
                                fontSize: 16.sp)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQtyBtn(BuildContext context, IconData icon,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          border:
              Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 24.sp),
      ),
    );
  }

  Widget _buildDropdownField(BuildContext context, String label, RxString value,
      List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                AppTheme.labelMedium.copyWith(fontFamily: AppTheme.fontBold)),
        SizedBox(height: 8.h),
        Obx(() => Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppTheme.borderColor(context)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value.value.isEmpty ? options[0] : value.value,
                  isExpanded: true,
                  dropdownColor: AppTheme.cardColor(context),
                  style: AppTheme.bodyLarge.copyWith(fontSize: 14.sp),
                  icon: const Icon(CupertinoIcons.chevron_down, size: 16),
                  items: options
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) value.value = v;
                  },
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildNoteField(
      BuildContext context, String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                AppTheme.labelMedium.copyWith(fontFamily: AppTheme.fontBold)),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppTheme.borderColor(context)),
          ),
          child: TextField(
            controller: controller,
            maxLines: 2,
            style: AppTheme.bodyLarge.copyWith(fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: "Add notes here...",
              hintStyle: AppTheme.labelMedium.copyWith(fontSize: 12.sp),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12.w),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(HomeController controller, BuildContext context) {
    return Container(
      // Padding diminimalkan sangat drastis
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        border: Border(top: BorderSide(color: AppTheme.borderColor(context))),
        // BoxShadow dihilangkan agar flat dan ringkas
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => _buildSummaryRow(
              context, "Subtotal", formatRupiah(controller.subtotalRaw.value))),
          SizedBox(height: 2.h),
          Obx(() => _buildSummaryRow(
              context, "Tax / Pajak", formatRupiah(controller.taxAmount.value))),

          Obx(() {
            final discVal = controller.manualDiscountValue.value;
            final isPercent = controller.manualDiscountIsPercent.value;
            final defaultDisc = controller.disscount.value;

            if (discVal > 0) {
              final String label = isPercent ? "Diskon ($discVal%)" : "Diskon";
              final int amount = isPercent
                  ? (controller.subtotalRaw.value * discVal / 100).round()
                  : discVal;
              return Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: _buildSummaryRow(
                    context, label, "-${formatRupiah(amount)}",
                    valueColor: const Color(0xFFFF6B35)),
              );
            } else if (defaultDisc > 0) {
              return Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: _buildSummaryRow(context, "Diskon ($defaultDisc%)",
                    "-${formatRupiah((controller.subtotalRaw.value * defaultDisc / 100).round())}",
                    valueColor: const Color(0xFFFF6B35)),
              );
            }
            return const SizedBox.shrink();
          }),

          // Hapus Padding & Divider (Garis horizontal di atas Total Pay)

          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Pay",
                      style: AppTheme.titleLarge.copyWith(fontSize: 16.sp)),
                  Text(formatRupiah(controller.totalTransaction.value),
                      style: AppTheme.titleLarge.copyWith(
                          fontSize: 20.sp, // Ukuran dikembalikan standar
                          fontFamily: AppTheme.fontBold,
                          color: AppTheme.primaryColor)),
                ],
              )),

          SizedBox(height: 8.h),

          // Buttons: single Confirm Refunds button in refund mode, normal buttons otherwise
          Obx(() {
            final isRefund = controller.isRefundMode.value;
            final isLoading = controller.isLoadingTransaction.value;
            final shiftController = Get.find<ShiftController>();
            final userService = Get.isRegistered<UserService>() ? Get.find<UserService>() : Get.put(UserService());
            final isTrialMode = shiftController.activeShift.value == null && 
                                userService.getRole().toLowerCase() == 'owner';

            if (isTrialMode) {
              final hasItems = controller.penjualanDetailModelList.isNotEmpty;
              return SizedBox(
                width: double.infinity,
                child: _buildPrimaryButton(
                  hasItems ? "Print Preview Struk" : "Test Print Receipt",
                  CupertinoIcons.printer_fill,
                  onTap: () async {
                    if (hasItems) {
                      // Print the actual selected items as a preview receipt
                      await controller.printReceipt(
                        paymentMethod: 'Preview',
                        total: controller.totalTransaction.value,
                        diterima: controller.totalTransaction.value,
                        kembalian: 0,
                      );
                    } else {
                      // No items selected — fall back to generic test print
                      if (Get.isRegistered<SettingController>()) {
                        final sc = Get.find<SettingController>();
                        if (sc.assignedPrinters.isNotEmpty) {
                          Get.snackbar(
                            'Mode Percobaan',
                            'Mencetak struk simulasi ke ${sc.assignedPrinters.first.name}...',
                            backgroundColor: Colors.orange.withValues(alpha: 0.9),
                            colorText: Colors.white,
                          );
                          await sc.performTestPrint(sc.assignedPrinters.first);
                        } else {
                          Get.snackbar('Error', 'Tidak ada printer yang terhubung. Tambah item ke keranjang atau hubungkan printer.');
                        }
                      } else {
                        Get.snackbar('Info', 'Tambahkan produk ke keranjang terlebih dahulu untuk mencetak preview struk.');
                      }
                    }
                  },
                  backgroundColor: Colors.orange.shade700,
                ),
              );
            }

            if (isRefund) {
              return Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildOutlineButton(
                      "Cancel",
                      CupertinoIcons.xmark,
                      onTap: () {
                        controller.cancelRefund();
                      },
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    flex: 2,
                    child: _buildPrimaryButton(
                      isLoading ? "Saving..." : "Confirm Refunds",
                      CupertinoIcons.checkmark_shield_fill,
                      onTap: isLoading ? null : () => controller.transactionValidation(isSaveOnly: true),
                      backgroundColor: Colors.red.shade700,
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: _buildPrimaryButton(
                    isLoading ? "Process..." : "Send to Kitchen",
                    CupertinoIcons.lab_flask_solid,
                    onTap: isLoading ? null : () => controller.sendToKitchen(),
                    backgroundColor: const Color(0xFF2980B9),
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildOutlineButton(
                        "Save",
                        CupertinoIcons.square_arrow_down,
                        onTap: () {
                          if (controller.penjualanDetailModelList.isEmpty) return;
                          controller.transactionValidation(isSaveOnly: true);
                        },
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      flex: 3,
                      child: _buildPrimaryButton(
                        "Pay Now",
                        CupertinoIcons.creditcard_fill,
                        onTap: () async {
                          if (controller.penjualanDetailModelList.isEmpty) return;
                          bool success = await controller.saveOrderLocally();
                          if (success) {
                            Get.to(() => const PaymentScreen(),
                                transition: Transition.cupertino);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value,
      {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTheme.labelMedium.copyWith(
                fontSize: 13.sp, color: AppTheme.secondaryTextColor(context))),
        Text(value,
            style: AppTheme.bodyLarge.copyWith(
                fontSize: 14.sp,
                fontFamily: AppTheme.fontMedium,
                color: valueColor ?? AppTheme.textColor(context))),
      ],
    );
  }

  Widget _buildOutlineButton(String label, IconData icon,
      {VoidCallback? onTap}) {
    return OutlinedButton.icon(
      onPressed: onTap ?? () {},
      icon: Icon(icon, size: 14.sp),
      label: Text(label,
          style: TextStyle(
              fontFamily: AppTheme.fontBold,
              fontSize: 12.sp)), // Font diperkecil
      style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          side: const BorderSide(color: AppTheme.primaryColor),
          padding: EdgeInsets.symmetric(
              vertical: 8.h), // Padding dikurangi (10.h -> 8.h)
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
    );
  }

  Widget _buildPrimaryButton(String label, IconData icon,
      {VoidCallback? onTap, Color? backgroundColor}) {
    return ElevatedButton.icon(
      onPressed: onTap ?? () {},
      icon: Icon(icon, size: 14.sp, color: Colors.white), // Icon diperkecil
      label: Text(label,
          style: TextStyle(
              color: Colors.white,
              fontFamily: AppTheme.fontBold,
              fontSize: 13.sp)), // Font diperkecil (15.sp -> 13.sp)
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppTheme.primaryColor,
        padding: EdgeInsets.symmetric(
            vertical: 10.h), // Padding dikurangi (14.h -> 10.h)
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r)), // Radius diselaraskan
        elevation: 0,
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label,
      TextEditingController textController, IconData icon,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.labelMedium),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppTheme.borderColor(context)),
          ),
          child: TextField(
            controller: textController,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: AppTheme.bodyLarge,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.primaryColor),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
            ),
          ),
        ),
      ],
    );
  }



  // RESTORED UI HELPER METHODS
  Widget _buildIconButton(BuildContext context, IconData icon,
      {Function? onTap}) {
    return GestureDetector(
      onTapDown: onTap is Function(TapDownDetails) ? onTap : null,
      onTap: onTap is VoidCallback ? onTap : null,
      child: Container(
        padding: EdgeInsets.all(6.w), // Diperkecil drastis dari 12.w
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(8.r),
          border:
              Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 18.sp),
      ),
    );
  }

  Widget _buildCartList(BuildContext context, HomeController controller) {
    if (controller.penjualanDetailModelList.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.cart,
                  size: 60.sp, color: Colors.grey.withValues(alpha: 0.2)),
              SizedBox(height: 16.h),
              Text("Cart is empty",
                  style: AppTheme.bodyLarge.copyWith(color: Colors.grey)),
              SizedBox(height: 4.h),
              Text("Add items from the menu to start",
                  style:
                      AppTheme.labelMedium.copyWith(color: Colors.grey.shade400)),
            ],
          ),
        ),
      );
    }

    final normalItems = controller.penjualanDetailModelList.where((e) => !e.isRefund).toList();
    final voidItems = controller.penjualanDetailModelList.where((e) => e.isRefund).toList();

    return ListView(
      shrinkWrap: false,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: [
        ...normalItems.map((item) {
          int originalIndex = controller.penjualanDetailModelList.indexOf(item);
          return _buildOrderItemRow(context, controller, item, originalIndex);
        }),
        if (voidItems.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Row(
              children: [
                Expanded(child: Divider(color: Colors.red.withValues(alpha: 0.3))),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Text("Void / Refunds", 
                    style: AppTheme.labelMedium.copyWith(color: Colors.red, fontFamily: AppTheme.fontBold)),
                ),
                Expanded(child: Divider(color: Colors.red.withValues(alpha: 0.3))),
              ],
            ),
          ),
          ...voidItems.map((item) {
            int originalIndex = controller.penjualanDetailModelList.indexOf(item);
            // Render void item with a slight opacity and red tint if desired
            return Opacity(
              opacity: 0.8,
              child: _buildOrderItemRow(context, controller, item, originalIndex),
            );
          }),
        ]
      ],
    );
  }

  Widget _buildCartFooter(BuildContext context, HomeController controller) {
    return _buildSummarySection(controller, context);
  }

  /// Navigate to the elegant full-page Open Shift Audit screen.
  void _navigateToOpenShift(
      ShiftController shiftController, String candidateName) {
    // Ensure the audit controller is fresh each time
    if (Get.isRegistered<ShiftAuditController>()) {
      Get.delete<ShiftAuditController>();
    }
    Get.put(ShiftAuditController());

    Get.to(
      () => ShiftAuditPage(
        mode: ShiftAuditMode.open,
        shiftName: candidateName,
      ),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  /// Navigate to the elegant full-page Close Shift Audit screen.
  void _navigateToCloseShift(ShiftController shiftController) {
    if (Get.isRegistered<ShiftAuditController>()) {
      Get.delete<ShiftAuditController>();
    }
    Get.put(ShiftAuditController());

    Get.to(
      () => ShiftAuditPage(
        mode: ShiftAuditMode.close,
        shiftName: shiftController.activeShift.value?.shiftName ?? 'Active Shift',
      ),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }
}
