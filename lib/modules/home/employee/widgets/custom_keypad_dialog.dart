import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class CustomKeypadDialog extends StatefulWidget {
  final int initialValue;
  final bool initialIsPercent;

  const CustomKeypadDialog({
    super.key,
    required this.initialValue,
    required this.initialIsPercent,
  });

  @override
  State<CustomKeypadDialog> createState() => _CustomKeypadDialogState();
}

class _CustomKeypadDialogState extends State<CustomKeypadDialog> {
  late String _typedValue;
  late bool _isPercent;

  @override
  void initState() {
    super.initState();
    _typedValue = widget.initialValue > 0 ? widget.initialValue.toString() : "";
    _isPercent = widget.initialIsPercent;
  }

  void _onKeyTap(String key) {
    setState(() {
      if (key == "⌫") {
        if (_typedValue.isNotEmpty) {
          _typedValue = _typedValue.substring(0, _typedValue.length - 1);
        }
      } else if (key == ".") {
        if (!_typedValue.contains(".")) {
          _typedValue += ".";
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
    if (_typedValue.isEmpty) return _isPercent ? "0 %" : "Rp 0";
    
    if (_isPercent) {
      return "$_typedValue %";
    } else {
      // Basic formatting for IDR
      try {
        double val = double.parse(_typedValue);
        return "Rp ${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
      } catch (_) {
        return "Rp $_typedValue";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      backgroundColor: Colors.white,
      child: Container(
        width: 320.w,
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Adjustment Amount",
                    style: AppTheme.bodyLarge.copyWith(fontFamily: AppTheme.fontBold)),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            
            // Display Area
            Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Text(
                "- ${_formatDisplay()}",
                style: TextStyle(
                  fontSize: 28.sp,
                  fontFamily: AppTheme.fontBold,
                  color: Colors.black87,
                ),
              ),
            ),
            
            SizedBox(height: 10.h),
            
            // Mode Selectors
            Row(
              children: [
                _buildModeButton("+", false, enabled: false), // Placeholder
                _buildModeButton("-", true, enabled: false), // Placeholder
                _buildModeButton("VAL", !_isPercent, onTap: () => setState(() => _isPercent = false)),
                _buildModeButton("%", _isPercent, onTap: () => setState(() => _isPercent = true)),
                
                const Spacer(),
                GestureDetector(
                  onTap: () => _onKeyTap("⌫"),
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    child: Icon(Icons.backspace_outlined, size: 24.sp, color: Colors.grey.shade700),
                  ),
                )
              ],
            ),
            
            SizedBox(height: 10.h),
            
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
                      _buildNumRow(["0", "."]),
                    ],
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      double val = double.tryParse(_typedValue) ?? 0;
                      Get.back(result: {"value": val.toInt(), "isPercent": _isPercent});
                    },
                    child: Container(
                      height: 180.h, // Adjusted to match grid height
                      margin: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      alignment: Alignment.center,
                      child: Text("OK",
                          style: TextStyle(
                              fontSize: 20.sp,
                              color: Colors.white,
                              fontFamily: AppTheme.fontBold)),
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(String label, bool active, {VoidCallback? onTap, bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border.all(color: active ? AppTheme.primaryColor : Colors.transparent),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18.sp,
            color: active ? AppTheme.primaryColor : (enabled ? Colors.grey : Colors.grey.shade300),
            fontFamily: AppTheme.fontBold,
          ),
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onKeyTap(key),
      child: Container(
        height: 50.h,
        alignment: Alignment.center,
        child: Text(key,
            style: TextStyle(
                fontSize: 22.sp,
                fontFamily: AppTheme.fontMedium,
                color: Colors.black87)),
      ),
    );
  }
}
