import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/core/models/printer/printer_device.dart';
import 'package:semesta_pos/modules/setting/controllers/setting_controller.dart';
import 'package:semesta_pos/styles/app_theme.dart';
import 'package:uuid/uuid.dart';

class AddPrinterDialog extends StatefulWidget {
  const AddPrinterDialog({super.key});

  @override
  State<AddPrinterDialog> createState() => _AddPrinterDialogState();
}

class _AddPrinterDialogState extends State<AddPrinterDialog> {
  final controller = Get.find<SettingController>();
  final nameController = TextEditingController();
  final ipController = TextEditingController();
  final portController = TextEditingController(text: '9100');

  String selectedType = 'bluetooth';
  String selectedRole = 'cashier';
  bool isAutoCut = false;
  String? selectedBtAddress;
  String? selectedBtName;

  @override
  void initState() {
    super.initState();
    controller.startBluetoothScan();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      child: Container(
        width: 700.w,
        height: 480.h,
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Printer',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontFamily: AppTheme.fontBold,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Configure a new printer to use in your POS',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.secondaryTextColor(context),
                        fontFamily: AppTheme.fontRegular,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(20.r),
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 24.sp,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side: Form
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Printer Name'),
                          TextField(
                            controller: nameController,
                            style: TextStyle(fontSize: 12.sp, fontFamily: AppTheme.fontMedium),
                            decoration: _inputDecoration('e.g. Front Cashier Printer'),
                          ),
                          SizedBox(height: 16.h),
                          _buildLabel('Connection Type'),
                          Row(
                            children: [
                              _buildTypeChip('Bluetooth', 'bluetooth'),
                              SizedBox(width: 8.w),
                              _buildTypeChip('Network (IP)', 'network'),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          _buildLabel('Printer Role'),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 6.h,
                            children: [
                              _buildRoleChip('Cashier', 'cashier'),
                              _buildRoleChip('Kitchen', 'kitchen'),
                              _buildRoleChip('Label', 'label'),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              'Printer has AutoCut (e.g. large 80mm printer)',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontFamily: AppTheme.fontMedium,
                                color: AppTheme.textColor(context),
                              ),
                            ),
                            subtitle: Text(
                              'Check this if your printer is a large machine to fix QR Code alignment on 58mm paper.',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontFamily: AppTheme.fontRegular,
                                color: AppTheme.secondaryTextColor(context),
                              ),
                            ),
                            value: isAutoCut,
                            onChanged: (val) {
                              setState(() {
                                isAutoCut = val ?? false;
                              });
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 24.w),
                  Container(
                    width: 1.w,
                    height: double.infinity,
                    color: AppTheme.borderColor(context),
                  ),
                  SizedBox(width: 24.w),
                  // Right Side: Bluetooth / Network + Button
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (selectedType == 'network') ...[
                          _buildLabel('IP Address'),
                          TextField(
                            controller: ipController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 12.sp, fontFamily: AppTheme.fontMedium),
                            decoration: _inputDecoration('192.168.1.100'),
                          ),
                          SizedBox(height: 16.h),
                          _buildLabel('Port (Default: 9100)'),
                          TextField(
                            controller: portController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 12.sp, fontFamily: AppTheme.fontMedium),
                            decoration: _inputDecoration('9100'),
                          ),
                          const Spacer(),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildLabel('Select Bluetooth Device'),
                              if (!controller.isScanning.value)
                                InkWell(
                                  onTap: () => controller.startBluetoothScan(),
                                  child: Text('Scan Again', style: TextStyle(fontSize: 11.sp, color: AppTheme.primaryColor, fontFamily: AppTheme.fontMedium)),
                                ),
                            ],
                          ),
                          Expanded(
                            child: Obx(() => controller.isScanning.value
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 24.w,
                                          height: 24.w,
                                          child: const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        SizedBox(height: 12.h),
                                        Text('Scanning devices...', style: TextStyle(fontSize: 11.sp, color: AppTheme.secondaryTextColor(context))),
                                      ],
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.isDark(context) ? Colors.grey.shade900 : Colors.grey.shade50,
                                      border: Border.all(color: AppTheme.borderColor(context)),
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    child: controller.discoveredDevices.isEmpty
                                        ? Center(
                                            child: Text(
                                              'No paired devices found',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: AppTheme.secondaryTextColor(context),
                                              ),
                                            ),
                                          )
                                        : ListView.separated(
                                            padding: EdgeInsets.zero,
                                            itemCount: controller.discoveredDevices.length,
                                            separatorBuilder: (context, index) => Divider(height: 1, color: AppTheme.borderColor(context)),
                                            itemBuilder: (context, index) {
                                              final d = controller.discoveredDevices[index];
                                              final isSelected = selectedBtAddress == d.address;
                                              return ListTile(
                                                dense: true,
                                                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                                                title: Text(
                                                  d.name ?? 'Unknown',
                                                  style: TextStyle(
                                                    fontSize: 13.sp,
                                                    fontFamily: AppTheme.fontMedium,
                                                    color: AppTheme.textColor(context),
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  d.address ?? '',
                                                  style: TextStyle(
                                                    fontSize: 11.sp,
                                                    color: AppTheme.secondaryTextColor(context),
                                                  ),
                                                ),
                                                trailing: isSelected
                                                    ? Icon(CupertinoIcons.checkmark_circle_fill,
                                                        color: AppTheme.primaryColor, size: 20.sp)
                                                    : null,
                                                onTap: () {
                                                  setState(() {
                                                    selectedBtAddress = d.address;
                                                    selectedBtName = d.name;
                                                    if (nameController.text.isEmpty) {
                                                      nameController.text = d.name ?? '';
                                                    }
                                                  });
                                                },
                                              );
                                            },
                                          ),
                                  )),
                          ),
                          SizedBox(height: 16.h),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 48.h,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                            child: Text(
                              'Save Printer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontFamily: AppTheme.fontMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (nameController.text.isEmpty) {
      Get.snackbar('Error', 'Printer name cannot be empty');
      return;
    }

    String address =
        selectedType == 'network' ? ipController.text : (selectedBtAddress ?? '');
    int port = 9100;

    if (selectedType == 'network') {
      // Handle IP:Port format in address field
      if (address.contains(':')) {
        final parts = address.split(':');
        address = parts[0];
        port = int.tryParse(parts[1]) ?? 9100;
      } else {
        port = int.tryParse(portController.text) ?? 9100;
      }
    }

    if (address.isEmpty) {
      Get.snackbar('Error', 'Please select a device or enter an IP address');
      return;
    }

    final newPrinter = PrinterDevice(
      id: const Uuid().v4(),
      name: nameController.text,
      type: selectedType,
      address: address,
      port: port,
      role: selectedRole,
      isAutoCut: isAutoCut,
    );

    controller.addPrinter(newPrinter);
    Get.back();
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          color: AppTheme.secondaryTextColor(context),
          fontFamily: AppTheme.fontMedium,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey.shade400),
      filled: true,
      fillColor: AppTheme.isDark(context) ? Colors.grey.shade900 : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
    );
  }

  Widget _buildTypeChip(String label, String value) {
    bool isSelected = selectedType == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11.sp)),
      selected: isSelected,
      onSelected: (_) => setState(() => selectedType = value),
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor(context),
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textColor(context),
        fontFamily: isSelected ? AppTheme.fontMedium : AppTheme.fontRegular,
        fontSize: 11.sp,
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
    );
  }

  Widget _buildRoleChip(String label, String value) {
    bool isSelected = selectedRole == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11.sp)),
      selected: isSelected,
      onSelected: (_) => setState(() => selectedRole = value),
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.08),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor(context),
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textColor(context),
        fontFamily: isSelected ? AppTheme.fontMedium : AppTheme.fontRegular,
        fontSize: 11.sp,
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
    );
  }


}
