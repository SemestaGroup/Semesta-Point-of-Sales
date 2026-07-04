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
    final double shortestSide = MediaQuery.of(context).size.shortestSide;
    final bool isMobile = shortestSide < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 24.0 : 200.w),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 20.0 : 32.r),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(isMobile ? 16.0 : 24.r),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12.0 : 16.w, 
                      vertical: isMobile ? 6.0 : 8.h
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.scaffoldBackgroundColor(context),
                      borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.r),
                      border: Border.all(color: AppTheme.borderColor(context)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: isMobile ? 12.0 : 16.r,
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            widget.initials ?? '?',
                            style: TextStyle(
                              fontSize: isMobile ? 10.0 : 12.sp, 
                              color: Colors.white, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          widget.staffName!,
                          style: TextStyle(
                            fontFamily: AppTheme.fontBold,
                            fontSize: isMobile ? 12.0 : 14.sp,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
            ],
            
            Text(
              widget.title,
              style: TextStyle(
                fontFamily: AppTheme.fontBold,
                fontSize: isMobile ? 18.0 : 22.sp,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 24.0),
            
            // PIN Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.pinLength, (index) {
                bool isFilled = index < _currentPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  width: 12.0,
                  height: 12.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppTheme.primaryColor : Colors.grey[300],
                  ),
                );
              }),
            ),
            const SizedBox(height: 32.0),
            
            // Number Pad
            _buildNumberPad(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad(bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPadRow(['1', '2', '3'], isMobile),
        const SizedBox(height: 12.0),
        _buildPadRow(['4', '5', '6'], isMobile),
        const SizedBox(height: 12.0),
        _buildPadRow(['7', '8', '9'], isMobile),
        const SizedBox(height: 12.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: isMobile ? 60.0 : 70.w), // Empty space
            _buildPadButton('0', isMobile),
            _buildPadButton('backspace', isMobile),
          ],
        ),
      ],
    );
  }

  Widget _buildPadRow(List<String> digits, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((d) => _buildPadButton(d, isMobile)).toList(),
    );
  }

  Widget _buildPadButton(String val, bool isMobile) {
    bool isBackspace = val == 'backspace';
    final double buttonSize = isMobile ? 60.0 : 70.w;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      width: buttonSize,
      height: buttonSize,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isBackspace ? _onBackspace : () => _onDigitPress(val),
          borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.r),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.r),
              border: Border.all(color: AppTheme.borderColor(context).withValues(alpha: 0.5)),
            ),
            alignment: Alignment.center,
            child: isBackspace
                ? Icon(Icons.backspace_outlined, color: AppTheme.primaryColor, size: isMobile ? 20.0 : 24.sp)
                : Text(
                    val,
                    style: TextStyle(
                      fontFamily: AppTheme.fontMedium,
                      fontSize: isMobile ? 20.0 : 24.sp,
                      color: AppTheme.textColor(context),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
