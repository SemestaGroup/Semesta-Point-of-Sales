import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class PinPadWidget extends StatefulWidget {
  final int pinLength;
  final Function(String) onCompleted;
  final String title;
  final String? staffName;
  final String? initials;

  const PinPadWidget({
    super.key,
    this.pinLength = 4,
    required this.onCompleted,
    this.title = 'Masukkan PIN',
    this.staffName,
    this.initials,
  });

  @override
  State<PinPadWidget> createState() => _PinPadWidgetState();
}

class _PinPadWidgetState extends State<PinPadWidget> {
  String _currentPin = "";

  void _onDigitPress(String digit) {
    if (_currentPin.length < widget.pinLength) {
      setState(() {
        _currentPin += digit;
      });
      if (_currentPin.length == widget.pinLength) {
        widget.onCompleted(_currentPin);
      }
    }
  }

  void _onBackspace() {
    if (_currentPin.isNotEmpty) {
      setState(() {
        _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 200.w),
      child: Container(
        padding: EdgeInsets.all(32.r),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.staffName != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   Container(
                     padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                     decoration: BoxDecoration(
                       color: AppTheme.scaffoldBackgroundColor(context),
                       borderRadius: BorderRadius.circular(12.r),
                       border: Border.all(color: AppTheme.borderColor(context)),
                     ),
                     child: Row(
                       children: [
                         CircleAvatar(
                           radius: 16.r,
                           backgroundColor: AppTheme.primaryColor,
                           child: Text(
                             widget.initials ?? '?',
                             style: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.bold),
                           ),
                         ),
                         SizedBox(width: 8.w),
                         Text(
                           widget.staffName!,
                           style: TextStyle(
                             fontFamily: AppTheme.fontBold,
                             fontSize: 14.sp,
                             color: AppTheme.textColor(context),
                           ),
                         ),
                       ],
                     ),
                   ),
                ],
              ),
              SizedBox(height: 20.h),
            ],
            
            Text(
              widget.title,
              style: TextStyle(
                fontFamily: AppTheme.fontBold,
                fontSize: 22.sp,
                color: AppTheme.textColor(context),
              ),
            ),
            SizedBox(height: 32.h),
            
            // PIN Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.pinLength, (index) {
                bool isFilled = index < _currentPin.length;
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 12.w),
                  width: 16.w,
                  height: 1.5.h,
                  decoration: BoxDecoration(
                    color: isFilled ? AppTheme.primaryColor : Colors.grey[300],
                  ),
                );
              }),
            ),
            SizedBox(height: 48.h),
            
            // Number Pad
            _buildNumberPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        _buildPadRow(['1', '2', '3']),
        SizedBox(height: 16.h),
        _buildPadRow(['4', '5', '6']),
        SizedBox(height: 16.h),
        _buildPadRow(['7', '8', '9']),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const SizedBox(width: 70, height: 70), // Empty space
             _buildPadButton('0'),
             _buildPadButton('backspace'),
          ],
        ),
      ],
    );
  }

  Widget _buildPadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((d) => _buildPadButton(d)).toList(),
    );
  }

  Widget _buildPadButton(String val) {
    bool isBackspace = val == 'backspace';
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.w),
      width: 70.w,
      height: 70.w,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isBackspace ? _onBackspace : () => _onDigitPress(val),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppTheme.borderColor(context).withValues(alpha: 0.5)),
            ),
            alignment: Alignment.center,
            child: isBackspace
                ? Icon(Icons.backspace_outlined, color: AppTheme.primaryColor, size: 24.sp)
                : Text(
                    val,
                    style: TextStyle(
                      fontFamily: AppTheme.fontMedium,
                      fontSize: 24.sp,
                      color: AppTheme.textColor(context),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
