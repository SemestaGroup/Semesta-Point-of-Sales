import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/modules/home/employee/controllers/shift_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class ManageShiftDialog extends StatelessWidget {
  const ManageShiftDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ShiftController>();
    final nameController = TextEditingController();
    final staffController = TextEditingController();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      backgroundColor: AppTheme.cardColor(context),
      surfaceTintColor: Colors.transparent,
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: 500.w,
        padding: EdgeInsets.all(24.w),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(CupertinoIcons.clock_fill, color: AppTheme.primaryColor, size: 24.sp),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Shift Management", style: AppTheme.titleLarge.copyWith(fontSize: 22.sp)),
                      Text("Configure shift schedules and assigned personnel", style: AppTheme.labelMedium),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(CupertinoIcons.multiply, size: 24.sp, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            
            // Add New Shift Form
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppTheme.scaffoldBackgroundColor(context),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppTheme.borderColor(context).withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Add New Shift", style: AppTheme.labelMedium.copyWith(fontFamily: AppTheme.fontBold)),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: "Shift Name (e.g. Shift 1)",
                            hintStyle: TextStyle(fontSize: 13.sp),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: TextField(
                          controller: staffController,
                          decoration: InputDecoration(
                            hintText: "Assigned Staff Name",
                            hintStyle: TextStyle(fontSize: 13.sp),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty) {
                            controller.addShiftConfig(nameController.text, staffController.text);
                            nameController.clear();
                            staffController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                          elevation: 0,
                        ),
                        child: Text("Add", style: TextStyle(color: Colors.white, fontFamily: AppTheme.fontBold, fontSize: 13.sp)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Shift Table Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text("SHIFT NAME", style: AppTheme.labelSmall.copyWith(letterSpacing: 1))),
                  Expanded(flex: 4, child: Text("ASSIGNED STAFF", style: AppTheme.labelSmall.copyWith(letterSpacing: 1))),
                  Expanded(flex: 2, child: Text("STATUS", style: AppTheme.labelSmall.copyWith(letterSpacing: 1), textAlign: TextAlign.center)),
                  SizedBox(width: 48.w), // Space for action
                ],
              ),
            ),
            Divider(color: AppTheme.borderColor(context)),
            
            // Shift List
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 300.h),
              child: Obx(() => ListView.separated(
                shrinkWrap: true,
                itemCount: controller.shiftConfigs.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: AppTheme.borderColor(context).withValues(alpha: 0.3)),
                itemBuilder: (context, index) {
                  final shift = controller.shiftConfigs[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(shift.name, style: AppTheme.bodyLarge.copyWith(fontFamily: AppTheme.fontBold)),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(shift.staffName.isEmpty ? "Unassigned" : shift.staffName, 
                                     style: AppTheme.bodyMedium.copyWith(color: shift.staffName.isEmpty ? Colors.grey : null)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Transform.scale(
                              scale: 0.7,
                              child: CupertinoSwitch(
                                value: shift.isActive,
                                activeTrackColor: AppTheme.primaryColor,
                                onChanged: (_) => controller.toggleShiftStatus(index),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 48.w,
                          child: IconButton(
                            onPressed: () => _showDeleteConfirm(context, controller, index),
                            icon: Icon(CupertinoIcons.trash, color: Colors.red.shade300, size: 18.sp),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )),
            ),
            
            SizedBox(height: 24.h),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.borderColor(context)),
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                child: Text("Close", style: TextStyle(color: AppTheme.textColor(context), fontFamily: AppTheme.fontBold, fontSize: 13.sp)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  void _showDeleteConfirm(BuildContext context, ShiftController controller, int index) {
    Get.dialog(
      AlertDialog(
        title: const Text("Delete Shift?"),
        content: const Text("Are you sure you want to remove this shift configuration?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              controller.deleteShiftConfig(index);
              Get.back();
            }, 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }
}
