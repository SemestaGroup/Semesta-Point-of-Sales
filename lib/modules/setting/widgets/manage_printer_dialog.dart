import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/modules/setting/controllers/setting_controller.dart';
import 'package:semesta_pos/modules/setting/widgets/add_printer_dialog.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class ManagePrinterDialog extends StatelessWidget {
  const ManagePrinterDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingController>();

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 24.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      child: Container(
        width: 800.w,
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Printers',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontFamily: AppTheme.fontBold,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Configure printers for Cashier, Kitchen, or Label',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.secondaryTextColor(context),
                        fontFamily: AppTheme.fontRegular,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => Get.dialog(const AddPrinterDialog()),
                      icon: Icon(Icons.add, color: AppTheme.primaryColor, size: 16.sp),
                      label: Text(
                        'Add Printer',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12.sp,
                          fontFamily: AppTheme.fontMedium,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(20.r),
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 22.sp,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Divider
            Divider(height: 1, color: AppTheme.borderColor(context)),
            SizedBox(height: 4.h),

            // Printer Table
            Flexible(
              child: Obx(() => controller.assignedPrinters.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(3),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(2),
                          4: FlexColumnWidth(2),
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          _buildTableHeader(context),
                          ...controller.assignedPrinters
                              .map((p) => _buildTableRow(context, controller, p)),
                        ],
                      ),
                    )),
            ),

            SizedBox(height: 12.h),
            Divider(height: 1, color: AppTheme.borderColor(context)),
            SizedBox(height: 12.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => controller.autoConnectAll(),
                  icon: Icon(Icons.sync, size: 14.sp),
                  label: Text(
                    'Refresh & Reconnect All',
                    style: TextStyle(fontSize: 12.sp, fontFamily: AppTheme.fontMedium),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.borderColor(context)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableHeader(BuildContext context) {
    TextStyle headerStyle = TextStyle(
      fontFamily: AppTheme.fontMedium,
      fontSize: 11.sp,
      color: AppTheme.secondaryTextColor(context),
      letterSpacing: 0.4,
    );
    return TableRow(
      decoration: BoxDecoration(
        color: AppTheme.isDark(context)
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6.r),
      ),
      children: [
        Padding(padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w), child: Text('PRINTER NAME', style: headerStyle)),
        Padding(padding: EdgeInsets.symmetric(vertical: 10.h), child: Text('ROLE', style: headerStyle)),
        Padding(padding: EdgeInsets.symmetric(vertical: 10.h), child: Text('CONNECTION', style: headerStyle)),
        Padding(padding: EdgeInsets.symmetric(vertical: 10.h), child: Text('STATUS', style: headerStyle)),
        Padding(padding: EdgeInsets.symmetric(vertical: 10.h), child: Text('ACTIONS', style: headerStyle)),
      ],
    );
  }

  TableRow _buildTableRow(BuildContext context, SettingController controller, dynamic p) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.08))),
      ),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.name,
                style: TextStyle(
                  fontFamily: AppTheme.fontMedium,
                  fontSize: 12.sp,
                  color: AppTheme.textColor(context),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                p.address,
                style: TextStyle(fontSize: 10.sp, color: AppTheme.secondaryTextColor(context)),
              ),
            ],
          ),
        ),
        _buildRoleBadge(p.role),
        Text(
          p.type.toUpperCase(),
          style: TextStyle(
            fontSize: 11.sp,
            color: AppTheme.secondaryTextColor(context),
            fontFamily: AppTheme.fontMedium,
          ),
        ),
        _buildStatusBadge(p.isConnected, p.type),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => controller.performTestPrint(p),
              icon: Icon(CupertinoIcons.printer, color: AppTheme.primaryColor, size: 16.sp),
              tooltip: 'Test Print',
              padding: EdgeInsets.all(6.w),
              constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.w),
            ),
            IconButton(
              onPressed: () => controller.deletePrinter(p.id),
              icon: Icon(CupertinoIcons.trash, color: Colors.red.shade400, size: 16.sp),
              tooltip: 'Remove',
              padding: EdgeInsets.all(6.w),
              constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.w),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    String label;
    switch (role) {
      case 'cashier':
        color = Colors.green;
        label = 'Cashier';
        break;
      case 'kitchen':
        color = Colors.orange;
        label = 'Kitchen';
        break;
      case 'label':
        color = Colors.purple;
        label = 'Label';
        break;
      default:
        color = Colors.grey;
        label = role;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10.sp, fontFamily: AppTheme.fontMedium),
      ),
    );
  }

  Widget _buildStatusBadge(bool isConnected, String type) {
    if (isConnected) {
      return Row(children: [
        Container(width: 6.w, height: 6.w, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
        SizedBox(width: 6.w),
        Text('Connected', style: TextStyle(fontSize: 11.sp, color: Colors.green, fontFamily: AppTheme.fontMedium)),
      ]);
    }
    // BT printers in idle/disconnected state = normal (connect on demand)
    if (type == 'bluetooth') {
      return Row(children: [
        Container(width: 6.w, height: 6.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade400)),
        SizedBox(width: 6.w),
        Text('Paired / Ready', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500, fontFamily: AppTheme.fontMedium)),
      ]);
    }
    return Row(children: [
      Container(width: 6.w, height: 6.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.shade400)),
      SizedBox(width: 6.w),
      Text('Disconnected', style: TextStyle(fontSize: 11.sp, color: Colors.red.shade400, fontFamily: AppTheme.fontMedium)),
    ]);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48.h),
        child: Column(
          children: [
            Icon(CupertinoIcons.printer, size: 48.sp, color: Colors.grey.shade300),
            SizedBox(height: 12.h),
            Text(
              'No printers configured',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade500,
                fontFamily: AppTheme.fontMedium,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Tap "Add Printer" to get started',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey.shade400,
                fontFamily: AppTheme.fontRegular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
