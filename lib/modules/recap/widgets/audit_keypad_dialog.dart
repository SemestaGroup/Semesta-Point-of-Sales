import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/styles/app_theme.dart';

class AuditKeypadDialog extends StatefulWidget {
  final String title;
  final int initialValue;

  const AuditKeypadDialog({
    super.key,
    required this.title,
    this.initialValue = 0,
  });

  @override
  State<AuditKeypadDialog> createState() => _AuditKeypadDialogState();
}

class _AuditKeypadDialogState extends State<AuditKeypadDialog> {
  late final TextEditingController _textCtrl;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(
        text: widget.initialValue == 0 ? "" : widget.initialValue.toString());
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(24.w),
      child: Container(
        constraints: BoxConstraints(maxWidth: 400.w),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title Row
            Padding(
              padding: EdgeInsets.fromLTRB(28.w, 28.h, 28.w, 0),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: _iconColorForMode(widget.title).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(_iconForMode(widget.title),
                        size: 20.sp, color: _iconColorForMode(widget.title)),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontFamily: AppTheme.fontBold,
                            fontSize: 18.sp,
                            color: AppTheme.textColor(context),
                          ),
                        ),
                        Text(
                          'Enter actual physical cash',
                          style: TextStyle(
                            fontFamily: AppTheme.fontMedium,
                            fontSize: 13.sp,
                            color: AppTheme.secondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.h),

            // Display Area
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 28.w),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBackgroundColor(context),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppTheme.borderColor(context)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Rp ',
                      style: TextStyle(
                        fontFamily: AppTheme.fontBold,
                        fontSize: 20.sp,
                        color: AppTheme.secondaryTextColor(context),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _textCtrl.text.isEmpty ? '0' : _textCtrl.text,
                        style: TextStyle(
                          fontFamily: AppTheme.fontBold,
                          fontSize: 28.sp,
                          color: _textCtrl.text.isEmpty
                              ? AppTheme.borderColor(context)
                              : AppTheme.primaryColor,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Numpad
            _buildNumpad(),

            SizedBox(height: 18.h),

            // Action Buttons
            Padding(
              padding: EdgeInsets.fromLTRB(28.w, 0, 28.w, 24.h),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                        side: BorderSide(color: AppTheme.borderColor(context)),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          fontFamily: AppTheme.fontBold,
                          color: AppTheme.textColor(context),
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final val = int.tryParse(_textCtrl.text) ?? 0;
                        Get.back(result: val);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Simpan',
                        style: TextStyle(
                          fontFamily: AppTheme.fontBold,
                          color: Colors.white,
                          fontSize: 14.sp,
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
    );
  }

  Widget _buildNumpad() {
    final keys = ['7', '8', '9', '4', '5', '6', '1', '2', '3', '000', '0', '⌫'];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        childAspectRatio: 2.8,
        mainAxisSpacing: 8.h,
        crossAxisSpacing: 8.w,
        physics: const NeverScrollableScrollPhysics(),
        children: keys.map((k) {
          return InkWell(
            onTap: () {
              setState(() {
                if (k == '⌫') {
                  if (_textCtrl.text.isNotEmpty) {
                    _textCtrl.text =
                        _textCtrl.text.substring(0, _textCtrl.text.length - 1);
                  }
                } else {
                  if (_textCtrl.text == '0' || _textCtrl.text == '') {
                    _textCtrl.text = k == '000' ? '0' : k;
                  } else {
                    if (_textCtrl.text.length < 15) {
                      _textCtrl.text = _textCtrl.text + k;
                    }
                  }
                }
              });
            },
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              decoration: BoxDecoration(
                color: k == '⌫'
                    ? Colors.red.withValues(alpha: 0.1)
                    : AppTheme.scaffoldBackgroundColor(context),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppTheme.borderColor(context)),
              ),
              alignment: Alignment.center,
              child: k == '⌫'
                  ? Icon(CupertinoIcons.delete_left_fill,
                      size: 16.sp, color: Colors.red)
                  : Text(
                      k,
                      style: TextStyle(
                        fontFamily: AppTheme.fontBold,
                        fontSize: 18.sp,
                        color: AppTheme.textColor(context),
                      ),
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _iconForMode(String name) {
    final n = name.toLowerCase();
    if (n.contains('cash') || n.contains('tunai')) {
      return CupertinoIcons.money_dollar_circle_fill;
    }
    if (n.contains('transfer') || n.contains('bank')) {
      return CupertinoIcons.arrow_right_arrow_left_circle_fill;
    }
    if (n.contains('qris') || n.contains('qr')) return CupertinoIcons.qrcode;
    if (n.contains('edc') ||
        n.contains('card') ||
        n.contains('debit') ||
        n.contains('kredit')) return CupertinoIcons.creditcard_fill;
    if (n.contains('shopee')) return CupertinoIcons.bag_fill;
    if (n.contains('grab')) return CupertinoIcons.car_fill;
    if (n.contains('gofood') || n.contains('go-food')) {
      return CupertinoIcons.cube_box_fill;
    }
    return CupertinoIcons.creditcard;
  }

  Color _iconColorForMode(String name) {
    final n = name.toLowerCase();
    if (n.contains('cash') || n.contains('tunai')) return Colors.green;
    if (n.contains('transfer') || n.contains('bank')) return Colors.blue;
    if (n.contains('qris') || n.contains('qr')) return const Color(0xFF9C27B0);
    if (n.contains('edc') || n.contains('card')) return Colors.orange;
    if (n.contains('shopee')) return Colors.deepOrange;
    if (n.contains('grab')) return Colors.teal;
    if (n.contains('gofood') || n.contains('go-food')) return Colors.red;
    return Colors.blueGrey;
  }
}
