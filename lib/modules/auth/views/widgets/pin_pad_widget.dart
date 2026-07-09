import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Color> colors = [
      const Color(0xFF264653),
      const Color(0xFF2A9D8F),
      const Color(0xFFE9C46A),
      const Color(0xFFF4A261),
      const Color(0xFFE76F51),
      const Color(0xFF1D3557),
      const Color(0xFF457B9D),
    ];
    final Color avatarColor = colors[(widget.staffName ?? '').hashCode % colors.length];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 36.0 : 200.w,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? 320.0 : 400.w,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20.0 : 32.r,
          vertical: isMobile ? 20.0 : 32.r,
        ),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(isMobile ? 16.0 : 24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar with Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: AppTheme.secondaryTextColor(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              
              if (widget.staffName != null) ...[
                // Centered Avatar
                CircleAvatar(
                  radius: isMobile ? 24.0 : 36.r,
                  backgroundColor: avatarColor,
                  child: Text(
                    widget.initials ?? '?',
                    style: TextStyle(
                      fontFamily: AppTheme.fontBold,
                      fontSize: isMobile ? 16.0 : 24.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  widget.staffName!,
                  style: TextStyle(
                    fontFamily: AppTheme.fontBold,
                    fontSize: isMobile ? 15.0 : 18.sp,
                    color: AppTheme.textColor(context),
                  ),
                ),
                const SizedBox(height: 4.0),
              ],

              Text(
                widget.title,
                style: TextStyle(
                  fontFamily: AppTheme.fontMedium,
                  fontSize: isMobile ? 12.0 : 14.sp,
                  color: AppTheme.secondaryTextColor(context),
                ),
              ),
              const SizedBox(height: 16.0),

              // PIN Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.pinLength, (index) {
                  bool isFilled = index < _currentPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 6.0),
                    width: isFilled ? 10.0 : 8.0,
                    height: isFilled ? 10.0 : 8.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? AppTheme.primaryColor
                          : (isDark ? Colors.grey[800] : Colors.grey[300]),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20.0),

              // Number Pad
              _buildNumberPad(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad(bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPadRow(['1', '2', '3'], isMobile),
        SizedBox(height: isMobile ? 8.0 : 14.0),
        _buildPadRow(['4', '5', '6'], isMobile),
        SizedBox(height: isMobile ? 8.0 : 14.0),
        _buildPadRow(['7', '8', '9'], isMobile),
        SizedBox(height: isMobile ? 8.0 : 14.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cancel Button
            _buildActionTextButton(isMobile),
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

  Widget _buildActionTextButton(bool isMobile) {
    final double buttonSize = isMobile ? 54.0 : 70.w;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 12.0),
      width: buttonSize,
      height: buttonSize,
      child: Center(
        child: TextButton(
          onPressed: () => Get.back(),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Batal',
            style: TextStyle(
              fontFamily: AppTheme.fontMedium,
              fontSize: isMobile ? 13.0 : 15.sp,
              color: Colors.redAccent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPadButton(String val, bool isMobile) {
    bool isBackspace = val == 'backspace';
    final double buttonSize = isMobile ? 54.0 : 70.w;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 12.0),
      width: buttonSize,
      height: buttonSize,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isBackspace ? _onBackspace : () => _onDigitPress(val),
          borderRadius: BorderRadius.circular(buttonSize / 2),
          child: Ink(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isBackspace
                  ? Colors.transparent
                  : (isDark
                      ? Colors.grey.shade900
                      : Colors.grey.shade100),
              border: isBackspace
                  ? null
                  : Border.all(
                      color: AppTheme.borderColor(context).withValues(alpha: 0.3)),
            ),
            child: Align(
              alignment: Alignment.center,
              child: isBackspace
                  ? Icon(Icons.backspace_outlined,
                      color: AppTheme.primaryColor,
                      size: isMobile ? 18.0 : 24.sp)
                  : Text(
                      val,
                      style: TextStyle(
                        fontFamily: AppTheme.fontBold,
                        fontSize: isMobile ? 18.0 : 26.sp,
                        color: AppTheme.textColor(context),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
