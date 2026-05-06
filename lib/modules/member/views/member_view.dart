import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:semesta_pos/modules/member/controllers/member_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class MemberScreen extends StatelessWidget {
  const MemberScreen({super.key});

  String formatRupiah(dynamic number) {
    if (number == null) return "Rp. 0";
    final formatCurrency = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);
    return formatCurrency.format(number is String ? int.tryParse(number) ?? 0 : number);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MemberController());

    // Reset view to list when entering/returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.isFormView.value) {
        controller.isFormView.value = false;
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      body: SafeArea(
        child: Obx(() => controller.isFormView.value
            ? _buildFormView(context, controller)
            : _buildMemberList(context, controller)),
      ),
    );
  }

  Widget _buildMemberList(BuildContext context, MemberController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Action Bar
          Row(
            children: [
              // Search Bar
              Expanded(
                child: Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppTheme.borderColor(context)),
                  ),
                  child: TextField(
                    controller: controller.searchController,
                    onChanged: controller.filterMembers,
                    style: TextStyle(
                      fontFamily: AppTheme.fontMedium,
                      color: AppTheme.textColor(context),
                      fontSize: 16.sp,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search for customers',
                      hintStyle: TextStyle(
                        fontFamily: AppTheme.fontRegular,
                        color: Colors.grey.shade500,
                        fontSize: 15.sp,
                      ),
                      prefixIcon: Icon(CupertinoIcons.search,
                          size: 20.sp, color: Colors.grey.shade500),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              // Add Button
              ElevatedButton.icon(
                onPressed: () {
                  controller.cleanField();
                  controller.isFormView.value = true;
                },
                icon:
                    Icon(CupertinoIcons.add, size: 18.sp, color: Colors.white),
                label: Text(
                  'Add new customer',
                  style: TextStyle(
                    fontFamily: AppTheme.fontBold,
                    fontSize: 15.sp,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Result Count
          Text(
            'Customers matching search ${controller.filteredMemberList.length}',
            style: TextStyle(
              fontFamily: AppTheme.fontRegular,
              color: AppTheme.secondaryTextColor(context),
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 16.h),

          // Member Table
          Expanded(
            child: controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : controller.filteredMemberList.isEmpty
                    ? Center(
                        child: Text(
                          'No customers found.',
                          style: TextStyle(
                            fontFamily: AppTheme.fontRegular,
                            fontSize: 16.sp,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                              child: SingleChildScrollView(
                                  child: _buildMemberDataTable(
                                      context, controller))),
                          SizedBox(height: 16.h),
                          _buildPagination(context, controller),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberDataTable(
      BuildContext context, MemberController controller) {
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
                _buildHeaderCell(context, "No", flex: 1),
                _buildHeaderCell(context, "Name", flex: 2),
                _buildHeaderCell(context, "Phone", flex: 2),
                _buildHeaderCell(context, "Address", flex: 4), // Increased flex
                _buildHeaderCell(context, "", flex: 1), // Empty header for chevron
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(16.r)),
            ),
            child: Obx(() => controller.paginatedList.isEmpty
                ? SizedBox(
                    height: 300.h,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.person_circle,
                              size: 48.sp, color: Colors.grey.shade700),
                          SizedBox(height: 16.h),
                          Text("No customers found",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16.sp,
                                  fontFamily: AppTheme.fontMedium)),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.paginatedList.length,
                    itemBuilder: (context, index) {
                      final member = controller.paginatedList[index];
                      final globalIndex = (controller.currentPage.value - 1) *
                                controller.rowsPerPage.value +
                          index +
                          1;
                      return _buildMemberDataRow(
                          context, controller, member, globalIndex);
                    },
                  )),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontFamily: AppTheme.fontBold,
          fontSize: 15.sp,
        ),
      ),
    );
  }

  Widget _buildMemberDataRow(BuildContext context, MemberController controller,
      dynamic member, int index) {
    return InkWell(
      onTap: () => _selectMember(controller, member),
      borderRadius: BorderRadius.circular(8.r),
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
                flex: 1,
                child: Text('$index',
                    style: TextStyle(
                        fontSize: 14.sp,
                        fontFamily: AppTheme.fontMedium,
                        color: AppTheme.textColor(context)))),
            Expanded(
                flex: 2,
                child: Text(member.nama ?? 'Unnamed',
                    style: TextStyle(
                        fontSize: 14.sp,
                        fontFamily: AppTheme.fontBold,
                        color: AppTheme.primaryColor))),
            Expanded(
                flex: 2,
                child: Text(member.telepon ?? '-',
                    style: TextStyle(
                        fontSize: 14.sp,
                        fontFamily: AppTheme.fontMedium,
                        color: AppTheme.textColor(context)))),
            Expanded(
              flex: 4, // Matched with header
              child: Text(
                member.alamat ?? '-',
                style: TextStyle(
                    fontSize: 14.sp,
                    fontFamily: AppTheme.fontRegular,
                    color: AppTheme.secondaryTextColor(context)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Icon(
                CupertinoIcons.chevron_right,
                size: 16.sp,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectMember(MemberController controller, dynamic member) {
    controller.selectedMember.value = member;
    controller.namaMemberController.text = member.nama ?? "";
    controller.teleponMemberController.text = member.telepon ?? "";
    controller.alamatMemberController.text = member.alamat ?? "";
    
    // Fetch purchase history for this member
    controller.fetchHistory(member.idMember);
    
    controller.isFormView.value = true;
  }

  Widget _buildFormView(BuildContext context, MemberController controller) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => controller.isFormView.value = false,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.arrow_left,
                      size: 18.sp, color: AppTheme.primaryColor),
                  SizedBox(width: 8.w),
                  Text(
                    "Back to Customer List",
                    style: TextStyle(
                      fontFamily: AppTheme.fontBold,
                      fontSize: 14.sp,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Profile Card
              Expanded(
                flex: 4,
                child: Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppTheme.borderColor(context)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 80.w,
                            height: 80.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                              border: Border.all(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.5),
                                  width: 2),
                            ),
                            child: Icon(CupertinoIcons.person_fill,
                                size: 40.sp, color: AppTheme.primaryColor),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Obx(() => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      controller.tempNama.value.isEmpty
                                          ? "Customer Name"
                                          : controller.tempNama.value,
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontBold,
                                        fontSize: 22.sp,
                                        color: AppTheme.textColor(context),
                                      ),
                                    ),
                                    Text(
                                      "Loyal Customer",
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontRegular,
                                        fontSize: 14.sp,
                                        color: AppTheme.secondaryTextColor(
                                            context),
                                      ),
                                    ),
                                  ],
                                )),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Divider(color: AppTheme.borderColor(context)),
                      SizedBox(height: 16.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(context,
                              icon: CupertinoIcons.graph_square,
                              value: "History",
                              label: "Recent Orders"),
                          if (controller.selectedMember.value?.nama?.toLowerCase().contains("walk-in") != true)
                            _buildStatItem(context,
                                icon: CupertinoIcons.star_fill,
                                value: (controller.selectedMember.value?.points?.toString() ?? "0"),
                                label: "Total Points Earned"),
                        ],
                      ),
                ],
              ),
            ),
          ),
          SizedBox(width: 24.w),

              // Right: Forms
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    _buildFormSection(
                      context,
                      title: "Basic Customer Information",
                      children: [
                        _buildInputField(context,
                            controller: controller.namaMemberController,
                            label: "Name",
                            hint: "Enter full name"),
                        SizedBox(height: 12.h),
                        _buildPhoneField(context,
                            controller: controller.teleponMemberController),
                        SizedBox(height: 12.h),
                        _buildInputField(context,
                            controller: controller.alamatMemberController,
                            label: "Address",
                            hint: "Enter full address"),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    _buildPurchaseHistory(context, controller),
                    SizedBox(height: 12.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Obx(() => SizedBox(
                        width: 120.w,
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: controller.isLoadingStore.value 
                              ? null 
                              : () => controller.validationStore(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r)),
                            elevation: 0,
                          ),
                          child: controller.isLoadingStore.value
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: const CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  "Save",
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontBold,
                                    fontSize: 16.sp,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context,
      {required IconData icon, required String value, required String label}) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 28.sp),
        SizedBox(height: 8.h),
        Text(value,
            style: TextStyle(
                fontFamily: AppTheme.fontBold,
                fontSize: 20.sp,
                color: AppTheme.textColor(context))),
        Text(label,
            style: TextStyle(
                fontFamily: AppTheme.fontRegular,
                fontSize: 13.sp,
                color: AppTheme.secondaryTextColor(context))),
      ],
    );
  }

  Widget _buildFormSection(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
            color: AppTheme.borderColor(context).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppTheme.isDark(context)
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50.withValues(alpha: 0.8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontMedium,
                    fontSize: 14.sp,
                    color: AppTheme.secondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(BuildContext context,
      {required TextEditingController controller,
      required String label,
      required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontMedium,
            fontSize: 13.sp,
            color: AppTheme.secondaryTextColor(context),
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          style: TextStyle(
              fontFamily: AppTheme.fontMedium,
              fontSize: 15.sp,
              color: AppTheme.textColor(context)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.sp),
            filled: true,
            fillColor: AppTheme.cardColor(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppTheme.borderColor(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                  color: AppTheme.borderColor(context).withValues(alpha: 0.5)),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField(BuildContext context,
      {required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Phone Number",
          style: TextStyle(
            fontFamily: AppTheme.fontMedium,
            fontSize: 13.sp,
            color: AppTheme.secondaryTextColor(context),
          ),
        ),
        SizedBox(height: 8.h),
        Stack(
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              style: TextStyle(
                  fontFamily: AppTheme.fontMedium,
                  fontSize: 15.sp,
                  color: AppTheme.textColor(context)),
              decoration: InputDecoration(
                hintText: "62xxxx",
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 14.sp),
                filled: true,
                fillColor: AppTheme.cardColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: AppTheme.borderColor(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(
                      color: AppTheme.borderColor(context).withValues(alpha: 0.5)),
                ),
                contentPadding: EdgeInsets.only(
                    left: 60.w, right: 16.w, top: 12.h, bottom: 12.h),
              ),
            ),
            Positioned(
              left: 14.w,
              top: 14.h,
              child: Row(
                children: [
                  Image.network(
                    "https://flagcdn.com/w20/id.png",
                    width: 20.w,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.flag, size: 20.sp),
                  ),
                  SizedBox(width: 4.w),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPurchaseHistory(
      BuildContext context, MemberController controller) {
    return _buildFormSection(
      context,
      title: "Recent Purchase History",
      children: [
        Obx(() => controller.historyList.isEmpty
            ? Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: Text("No transactions found for this customer",
                      style: TextStyle(
                          color: Colors.grey,
                          fontFamily: AppTheme.fontRegular,
                          fontSize: 14.sp)),
                ),
              )
            : Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          flex: 2,
                          child: Text("Date",
                              style: AppTheme.labelMedium
                                  .copyWith(fontFamily: AppTheme.fontBold))),
                      Expanded(
                          flex: 2,
                          child: Text("Invoice",
                              style: AppTheme.labelMedium
                                  .copyWith(fontFamily: AppTheme.fontBold))),
                      Expanded(
                          flex: 1,
                          child: Text("Total",
                              textAlign: TextAlign.right,
                              style: AppTheme.labelMedium
                                  .copyWith(fontFamily: AppTheme.fontBold))),
                    ],
                  ),
                  const Divider(),
                  ...controller.historyList.map((tx) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 2,
                              child: Text(
                                  tx['tgl_penjualan'].toString().split('T')[0],
                                  style: TextStyle(fontSize: 13.sp))),
                          Expanded(
                              flex: 2,
                              child: Text(
                                tx['remote_number'] != null 
                                    ? "POS-${tx['remote_number'].toString().padLeft(6, '0')}" 
                                    : (tx['id_pos'] ?? "-"),
                                style: TextStyle(
                                    fontSize: 13.sp,
                                    color: AppTheme.primaryColor,
                                    fontFamily: AppTheme.fontMedium))),
                          Expanded(
                              flex: 1,
                              child: Text(formatRupiah(tx['bayar'] ?? 0),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 13.sp,
                                      fontFamily: AppTheme.fontBold))),
                        ],
                      ),
                    );
                  }),
                ],
              ))
      ],
    );
  }

  Widget _buildPagination(BuildContext context, MemberController controller) {
    return Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Page ${controller.currentPage.value}",
              style: TextStyle(
                  fontFamily: AppTheme.fontMedium,
                  fontSize: 14.sp,
                  color: AppTheme.secondaryTextColor(context)),
            ),
            SizedBox(width: 16.w),
            IconButton(
              onPressed: controller.currentPage.value > 1
                  ? () => controller.changePage(-1)
                  : null,
              icon: Icon(CupertinoIcons.chevron_left,
                  size: 20.sp, color: AppTheme.primaryColor),
            ),
            IconButton(
              onPressed: () => controller.changePage(1),
              icon: Icon(CupertinoIcons.chevron_right,
                  size: 20.sp, color: AppTheme.primaryColor),
            ),
          ],
        ));
  }
}
