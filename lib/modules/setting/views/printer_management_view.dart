import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';


import 'package:semesta_pos/styles/app_theme.dart';
import 'package:semesta_pos/modules/setting/controllers/setting_controller.dart';
import 'package:semesta_pos/core/models/printer/printer_device.dart';

class PrinterManagementView extends GetView<SettingController> {
  const PrinterManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Printer Management',
          style: TextStyle(
            fontFamily: AppTheme.fontBold,
            fontSize: 16.sp,
            color: AppTheme.textColor(context),
          ),
        ),
        backgroundColor: AppTheme.cardColor(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textColor(context)),
        actions: [
          TextButton.icon(
            onPressed: () {
              controller.startBluetoothScan();
              Get.snackbar('Scanning...', 'Searching for Bluetooth printers',
                  snackPosition: SnackPosition.BOTTOM);
            },
            icon: Icon(CupertinoIcons.search, size: 16.sp),
            label: Text('Scan Devices'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
          ),
          Padding(
            padding: EdgeInsets.only(right: 16.w, left: 8.w),
            child: ElevatedButton.icon(
              onPressed: () {
                _addNewPrinter();
              },
              icon: Icon(CupertinoIcons.add, size: 16.sp, color: Colors.white),
              label: Text('Add Printer', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.assignedPrinters.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.printer, size: 64, color: Colors.grey),
                SizedBox(height: 16.h),
                Text(
                  'No printers configured',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.secondaryTextColor(context),
                    fontFamily: AppTheme.fontMedium,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: controller.assignedPrinters.length,
          separatorBuilder: (context, index) => SizedBox(height: 16.h),
          itemBuilder: (context, index) {
            final printer = controller.assignedPrinters[index];
            return _buildPrinterCard(context, printer);
          },
        );
      }),
    );
  }

  void _addNewPrinter() {
    final newPrinter = PrinterDevice(
      id: const Uuid().v4(),
      name: 'New Printer',
      type: 'bluetooth',
      address: '',
      roles: [],
      paperSize: 58,
      fontSize: 1,
    );
    controller.assignedPrinters.add(newPrinter);
    controller.savePrinterConfigs();
  }

  Widget _buildPrinterCard(BuildContext context, PrinterDevice printer) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12.r),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          childrenPadding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 16.h),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(CupertinoIcons.printer_fill, color: AppTheme.primaryColor, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      printer.name,
                      style: TextStyle(fontFamily: AppTheme.fontBold, fontSize: 14.sp, color: AppTheme.textColor(context)),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'MAC: ${printer.address.isEmpty ? "Not Assigned" : printer.address} • ${printer.roles.isEmpty ? "No Role" : printer.roles.join(", ")}',
                      style: TextStyle(fontSize: 10.sp, color: AppTheme.secondaryTextColor(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Switch(
            value: printer.isActive,
            onChanged: (val) {
              final updated = printer.copyWith(isActive: val);
              _updatePrinter(printer, updated);
            },
            activeThumbColor: Colors.white,
            activeTrackColor: AppTheme.primaryColor,
          ),
          children: [
            // Edit Name
            TextFormField(
              initialValue: printer.name,
              decoration: InputDecoration(
                hintText: 'Printer Name',
                filled: true,
                fillColor: AppTheme.primaryColor.withValues(alpha: 0.03),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(CupertinoIcons.pen, size: 16.sp, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
              ),
              style: TextStyle(fontFamily: AppTheme.fontMedium, fontSize: 14.sp),
              onChanged: (val) {
                final updated = printer.copyWith(name: val);
                _updatePrinter(printer, updated);
              },
            ),
            SizedBox(height: 12.h),

            // Roles Multi-select
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _buildRoleChip(context, printer, 'Receipt (Cashier)', 'cashier'),
                _buildRoleChip(context, printer, 'Kitchen', 'kitchen'),
                _buildRoleChip(context, printer, 'Label', 'label'),
                _buildRoleChip(context, printer, 'Report (Z-Report)', 'report'),
              ],
            ),
            SizedBox(height: 16.h),

            // Configuration Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 4.w, bottom: 6.h),
                        child: Text('Paper Size', style: TextStyle(fontSize: 10.sp, color: AppTheme.secondaryTextColor(context), fontFamily: AppTheme.fontMedium)),
                      ),
                      _buildTypeDropdown(context, printer),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 4.w, bottom: 6.h),
                        child: Text('Font Size', style: TextStyle(fontSize: 10.sp, color: AppTheme.secondaryTextColor(context), fontFamily: AppTheme.fontMedium)),
                      ),
                      _buildFontDropdown(context, printer),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Device Mapping Row
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 4.w, bottom: 6.h),
                  child: Text('Bluetooth Device', style: TextStyle(fontSize: 10.sp, color: AppTheme.secondaryTextColor(context), fontFamily: AppTheme.fontMedium)),
                ),
                Obx(() => _buildDeviceDropdown(context, printer)),
              ],
            ),
            
            SizedBox(height: 20.h),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => controller.printTest(printer),
                  icon: Icon(CupertinoIcons.doc_text, size: 14.sp),
                  label: Text('Test Print', style: TextStyle(fontSize: 12.sp)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  ),
                ),
                SizedBox(width: 8.w),
                TextButton.icon(
                  onPressed: () {
                    controller.assignedPrinters.remove(printer);
                    controller.savePrinterConfigs();
                  },
                  icon: Icon(CupertinoIcons.trash, size: 14.sp),
                  label: Text('Delete', style: TextStyle(fontSize: 12.sp)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                    backgroundColor: Colors.red.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildRoleChip(BuildContext context, PrinterDevice printer, String label, String roleValue) {
    final isSelected = printer.roles.contains(roleValue);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilterChip(
          label: Text(label, style: TextStyle(fontSize: 11.sp)),
          selected: isSelected,
          onSelected: (val) {
            List<String> newRoles = List.from(printer.roles);
            if (val) {
              newRoles.add(roleValue);
            } else {
              newRoles.remove(roleValue);
            }
            final updated = printer.copyWith(roles: newRoles);
            _updatePrinter(printer, updated);
          },
          selectedColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          checkmarkColor: AppTheme.primaryColor,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.02),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.primaryColor : AppTheme.secondaryTextColor(context),
            fontFamily: isSelected ? AppTheme.fontMedium : AppTheme.fontRegular,
          ),
        ),
        if ((roleValue == 'kitchen' || roleValue == 'label') && isSelected)
          IconButton(
            icon: Icon(CupertinoIcons.settings, size: 16.sp, color: AppTheme.primaryColor),
            onPressed: () => _showBrandsDialog(context, printer),
            tooltip: 'Configure Brands',
            constraints: const BoxConstraints(),
            padding: EdgeInsets.only(left: 4.w, right: 8.w),
          ),
      ],
    );
  }

  void _showBrandsDialog(BuildContext context, PrinterDevice printerRef) {
    controller.fetchAvailableBrands(); // Ensure fresh data before showing
    final printerId = printerRef.id;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final printer = controller.assignedPrinters.firstWhere((p) => p.id == printerId, orElse: () => printerRef);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              title: Text('Printer Brands by Role', style: TextStyle(fontSize: 16.sp, fontFamily: AppTheme.fontBold)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select which brands this printer will handle per role. If empty, it will print everything for that role.',
                        style: TextStyle(fontSize: 12.sp, color: AppTheme.secondaryTextColor(context)),
                      ),
                      SizedBox(height: 16.h),
                      if (printer.roles.contains('kitchen')) ...[
                        Text('Kitchen Brands', style: TextStyle(fontSize: 14.sp, fontFamily: AppTheme.fontMedium, color: AppTheme.textColor(context))),
                        SizedBox(height: 8.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: controller.availableBrands.map((brand) {
                            final List<String> currentBrands = printer.roleBrands['kitchen'] ?? [];
                            final isSelected = currentBrands.contains(brand);
                            return FilterChip(
                              label: Text(brand, style: TextStyle(fontSize: 11.sp)),
                              selected: isSelected,
                              onSelected: (val) {
                                Map<String, List<String>> newRoleBrands = Map.from(printer.roleBrands);
                                List<String> newBrands = List.from(currentBrands);
                                if (val) {
                                  newBrands.add(brand);
                                } else {
                                  newBrands.remove(brand);
                                }
                                newRoleBrands['kitchen'] = newBrands;
                                final updated = printer.copyWith(roleBrands: newRoleBrands);
                                _updatePrinter(printer, updated);
                                setState(() {}); // update dialog
                              },
                              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                              checkmarkColor: AppTheme.primaryColor,
                              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.02),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                              labelStyle: TextStyle(
                                color: isSelected ? AppTheme.primaryColor : AppTheme.secondaryTextColor(context),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 16.h),
                      ],
                      if (printer.roles.contains('label')) ...[
                        Text('Label Brands', style: TextStyle(fontSize: 14.sp, fontFamily: AppTheme.fontMedium, color: AppTheme.textColor(context))),
                        SizedBox(height: 8.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: controller.availableBrands.map((brand) {
                            final List<String> currentBrands = printer.roleBrands['label'] ?? [];
                            final isSelected = currentBrands.contains(brand);
                            return FilterChip(
                              label: Text(brand, style: TextStyle(fontSize: 11.sp)),
                              selected: isSelected,
                              onSelected: (val) {
                                Map<String, List<String>> newRoleBrands = Map.from(printer.roleBrands);
                                List<String> newBrands = List.from(currentBrands);
                                if (val) {
                                  newBrands.add(brand);
                                } else {
                                  newBrands.remove(brand);
                                }
                                newRoleBrands['label'] = newBrands;
                                final updated = printer.copyWith(roleBrands: newRoleBrands);
                                _updatePrinter(printer, updated);
                                setState(() {}); // update dialog
                              },
                              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                              checkmarkColor: AppTheme.primaryColor,
                              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.02),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                              labelStyle: TextStyle(
                                color: isSelected ? AppTheme.primaryColor : AppTheme.secondaryTextColor(context),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    textStyle: TextStyle(fontFamily: AppTheme.fontMedium, fontSize: 14.sp),
                  ),
                  child: const Text('Done'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildTypeDropdown(BuildContext context, PrinterDevice printer) {
    // Map paperSize and autoCut to string
    String currentType = '${printer.paperSize}mm${printer.isAutoCut ? " AC" : ""}';
    final options = ["80mm", "58mm", "80mm AC", "58mm AC"];
    
    if (!options.contains(currentType)) currentType = "58mm";

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentType,
          isExpanded: true,
          icon: Icon(CupertinoIcons.chevron_down, size: 14.sp, color: AppTheme.secondaryTextColor(context)),
          style: TextStyle(fontSize: 12.sp, color: AppTheme.textColor(context), fontFamily: AppTheme.fontMedium),
          onChanged: (val) {
            if (val == null) return;
            bool autoCut = val.contains("AC");
            int size = val.contains("80") ? 80 : 58;
            final updated = printer.copyWith(isAutoCut: autoCut, paperSize: size);
            _updatePrinter(printer, updated);
          },
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
      ),
    );
  }

  Widget _buildFontDropdown(BuildContext context, PrinterDevice printer) {
    final options = {1: "Normal", 2: "Large"};
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: options.containsKey(printer.fontSize) ? printer.fontSize : 1,
          isExpanded: true,
          icon: Icon(CupertinoIcons.chevron_down, size: 14.sp, color: AppTheme.secondaryTextColor(context)),
          style: TextStyle(fontSize: 12.sp, color: AppTheme.textColor(context), fontFamily: AppTheme.fontMedium),
          onChanged: (val) {
            if (val == null) return;
            final updated = printer.copyWith(fontSize: val);
            _updatePrinter(printer, updated);
          },
          items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
        ),
      ),
    );
  }

  Widget _buildDeviceDropdown(BuildContext context, PrinterDevice printer) {
    final items = controller.discoveredDevices.map((device) {
      return DropdownMenuItem(
        value: device.address,
        child: Text('${device.name ?? "Unknown"} (${device.address})', overflow: TextOverflow.ellipsis),
      );
    }).toList();

    // Ensure the saved address is in the list to prevent assertion error
    bool hasSavedAddress = printer.address.isNotEmpty;
    bool addressInList = controller.discoveredDevices.any((d) => d.address == printer.address);
    
    if (hasSavedAddress && !addressInList) {
      items.add(DropdownMenuItem(
        value: printer.address,
        child: Text('Saved: ${printer.address}', overflow: TextOverflow.ellipsis),
      ));
    }

    if (items.isEmpty) {
      items.add(DropdownMenuItem(
        value: 'none',
        enabled: false,
        child: Text('No devices found (Scan first)', style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
      ));
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.length == 1 && items.first.value == 'none' ? 'none' : (hasSavedAddress ? printer.address : null),
          hint: Text('Select Scanned Device', style: TextStyle(fontSize: 12.sp)),
          isExpanded: true,
          icon: Icon(CupertinoIcons.chevron_down, size: 14.sp, color: AppTheme.secondaryTextColor(context)),
          style: TextStyle(fontSize: 12.sp, color: AppTheme.textColor(context), fontFamily: AppTheme.fontMedium),
          onChanged: (val) {
            if (val == null || val == 'none') return;
            String newName = printer.name;
            try {
              final selectedDevice = controller.discoveredDevices.firstWhere((d) => d.address == val);
              newName = selectedDevice.name ?? "Unknown Printer";
            } catch (_) {}
            
            final updated = printer.copyWith(address: val, name: newName);
            _updatePrinter(printer, updated);
          },
          items: items,
        ),
      ),
    );
  }

  void _updatePrinter(PrinterDevice oldPrinter, PrinterDevice newPrinter) {
    final index = controller.assignedPrinters.indexWhere((p) => p.id == oldPrinter.id);
    if (index != -1) {
      controller.assignedPrinters[index] = newPrinter;
      controller.savePrinterConfigs();
    }
  }
}
