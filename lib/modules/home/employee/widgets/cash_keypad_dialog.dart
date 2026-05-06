import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class CashKeypadDialog extends StatefulWidget {
  final int initialValue;

  const CashKeypadDialog({
    super.key,
    required this.initialValue,
  });

  @override
  State<CashKeypadDialog> createState() => _CashKeypadDialogState();
}

class _CashKeypadDialogState extends State<CashKeypadDialog> {
  late String _typedValue;

  @override
  void initState() {
    super.initState();
    _typedValue = widget.initialValue > 0 ? widget.initialValue.toString() : "";
  }

  void _onKeyTap(String key) {
    setState(() {
      if (key == "⌫") {
        if (_typedValue.isNotEmpty) {
          _typedValue = _typedValue.substring(0, _typedValue.length - 1);
        }
      } else {
        // Limit length to avoid overflow
        if (_typedValue.length < 12) {
          _typedValue += key;
        }
      }
    });
  }

  String _formatDisplay() {
    if (_typedValue.isEmpty) return "0";
    
    // Basic formatting for IDR (thousand separator '.')
    try {
      double val = double.parse(_typedValue);
      return val.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    } catch (_) {
      return _typedValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      backgroundColor: AppTheme.cardColor(context),
      child: Container(
        width: 300.w,
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Enter Cash Amount",
                    style: AppTheme.bodyLarge.copyWith(fontFamily: AppTheme.fontBold)),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Icon(Icons.close, color: AppTheme.secondaryTextColor(context)),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            
            // "Screen" Display Area
            Container(
              width: double.infinity,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
              ),
              child: Text(
                _formatDisplay(),
                style: TextStyle(
                  fontSize: 32.sp,
                  fontFamily: AppTheme.fontBold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Numeric Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildNumRow(["7", "8", "9"]),
                      _buildNumRow(["4", "5", "6"]),
                      _buildNumRow(["1", "2", "3"]),
                      _buildNumRow(["0", "000"]),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _onKeyTap("⌫"),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      height: 56.h,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.backspace_outlined, color: Colors.red, size: 24.sp),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      int val = int.tryParse(_typedValue) ?? 0;
                      Get.back(result: val);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: Size.fromHeight(56.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      elevation: 0,
                    ),
                    child: Text("CONFIRM",
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontFamily: AppTheme.fontBold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumRow(List<String> keys) {
    return Row(
      children: keys.map((k) => Expanded(child: _buildNumKey(k))).toList(),
    );
  }

  Widget _buildNumKey(String key) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKeyTap(key),
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          height: 64.h,
          alignment: Alignment.center,
          child: Text(key,
              style: TextStyle(
                  fontSize: 24.sp,
                  fontFamily: AppTheme.fontMedium,
                  color: AppTheme.textColor(context))),
        ),
      ),
    );
  }
}
