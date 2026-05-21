import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:semesta_pos/styles/app_theme.dart';
import 'package:semesta_pos/modules/home/employee/controllers/home_controller.dart';

class CashFlowPage extends StatefulWidget {
  final HomeController controller;

  const CashFlowPage({super.key, required this.controller});

  @override
  State<CashFlowPage> createState() => _CashFlowPageState();
}

class _CashFlowPageState extends State<CashFlowPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _noteController = TextEditingController();

  String _typedAmount = "";
  String _selectedPreset = "";
  bool _isAmountFocused = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = 1; // Default to Cash Out
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onKeyTap(String key) {
    FocusScope.of(context).unfocus();
    setState(() {
      _isAmountFocused = true;
      if (key == "⌫") {
        if (_typedAmount.isNotEmpty) {
          _typedAmount = _typedAmount.substring(0, _typedAmount.length - 1);
        }
      } else if (key == "000") {
        if (_typedAmount.isNotEmpty && _typedAmount != "0") {
          if (_typedAmount.length <= 9) {
            _typedAmount += "000";
          }
        }
      } else {
        if (_typedAmount.length < 12) {
          if (_typedAmount == "0") {
            _typedAmount = key;
          } else {
            _typedAmount += key;
          }
        }
      }
    });
  }

  String _formatDisplayAmount() {
    if (_typedAmount.isEmpty) return "Rp. 0";
    try {
      int val = int.parse(_typedAmount);
      return "Rp. ${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
    } catch (_) {
      return "Rp. $_typedAmount";
    }
  }

  void _submitExpense() async {
    int amount = int.tryParse(_typedAmount) ?? 0;

    if (amount <= 0) {
      Get.snackbar('Error', 'Amount must be greater than 0',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    bool success = await widget.controller.submitExpense(
      name: _nameController.text.trim(),
      note: _noteController.text.trim(),
      amount: amount,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      if (success) {
        Get.back(); // close page and return to POS on success
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor(context),
      resizeToAvoidBottomInset:
          false, // Prevent the entire Scaffold page from resizing
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: AppTheme.textColor(context)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Cash Flow',
          style: TextStyle(
            fontFamily: AppTheme.fontBold,
            fontSize: 20.sp,
            color: AppTheme.textColor(context),
          ),
        ),
        backgroundColor: AppTheme.cardColor(context),
        elevation: 0.5,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: Container(
            color: AppTheme.cardColor(context),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              labelStyle:
                  TextStyle(fontFamily: AppTheme.fontBold, fontSize: 14.sp),
              unselectedLabelStyle:
                  TextStyle(fontFamily: AppTheme.fontMedium, fontSize: 14.sp),
              tabs: const [
                Tab(text: 'Cash In'),
                Tab(text: 'Cash Out'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: [
          _buildCashInTab(),
          _buildCashOutTab(),
        ],
      ),
    );
  }

  Widget _buildCashInTab() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline,
              size: 64.sp, color: Colors.grey.withAlpha((255 * 0.5).round())),
          SizedBox(height: 20.h),
          Text(
            'Cash In is Currently Disabled',
            style: TextStyle(
              fontSize: 18.sp,
              fontFamily: AppTheme.fontBold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'This feature is not available at the moment.',
            style: TextStyle(
              fontSize: 14.sp,
              fontFamily: AppTheme.fontRegular,
              color: Colors.grey.withAlpha((255 * 0.8).round()),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCashOutTab() {
    // Detect keyboard bottom inset height
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 24.h),
      child: Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Pane - Inputs (Resizes and scrolls with keyboard)
            Expanded(
              flex: 11,
              child: Padding(
                padding: EdgeInsets.only(
                    bottom:
                        keyboardHeight), // Shrink scrollable area by keyboard height
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(right: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Amount *'),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isAmountFocused = true;
                            });
                            FocusScope.of(context).unfocus();
                          },
                          borderRadius: BorderRadius.circular(8.r),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 14.h),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor(context),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: _isAmountFocused
                                    ? AppTheme.primaryColor
                                    : AppTheme.borderColor(context),
                                width: _isAmountFocused ? 1.8 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatDisplayAmount(),
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontFamily: AppTheme.fontBold,
                                      color: _typedAmount.isEmpty
                                          ? Colors.grey.shade400
                                          : AppTheme.textColor(context),
                                    ),
                                  ),
                                ),
                                if (_typedAmount.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _typedAmount = "";
                                      });
                                    },
                                    child: Icon(Icons.clear,
                                        size: 20.sp, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _buildLabel('Expense Name (Select or Custom)'),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: [
                            _buildPresetChip("Galon"),
                            _buildPresetChip("Uang Bensin"),
                            _buildPresetChip("Parkir"),
                            _buildPresetChip("Es Batu"),
                            _buildPresetChip("ATK / Print"),
                            _buildPresetChip("Service"),
                            _buildPresetChip("Kustom..."),
                          ],
                        ),
                        if (_selectedPreset == "Kustom...") ...[
                          SizedBox(height: 12.h),
                          TextFormField(
                            controller: _nameController,
                            autofocus: true,
                            style: TextStyle(
                                fontSize: 15.sp,
                                color: AppTheme.textColor(context)),
                            decoration:
                                _inputDecoration('Enter custom name...'),
                            onTap: () {
                              setState(() {
                                _isAmountFocused = false;
                              });
                            },
                          ),
                        ],
                        SizedBox(height: 16.h),
                        _buildLabel('Note (Optional)'),
                        TextFormField(
                          controller: _noteController,
                          maxLines: 3,
                          style: TextStyle(
                              fontSize: 15.sp,
                              color: AppTheme.textColor(context)),
                          decoration: _inputDecoration('Add some details...'),
                          onTap: () {
                            setState(() {
                              _isAmountFocused = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 40.w),

            // Right Pane - Numpad and Submit Button (Stays completely static at full height)
            Expanded(
              flex: 9,
              child: Column(
                children: [
                  Expanded(
                    child: _buildNumpad(),
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitExpense,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              height: 24.h,
                              width: 24.h,
                              child: const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Submit Cash Out',
                              style: TextStyle(
                                fontFamily: AppTheme.fontBold,
                                fontSize: 16.sp,
                                color: Colors.white,
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

  Widget _buildPresetChip(String preset) {
    bool isSelected = _selectedPreset == preset;
    return Material(
      color: isSelected ? AppTheme.primaryColor : AppTheme.cardColor(context),
      borderRadius: BorderRadius.circular(6.r),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPreset = preset;
            if (preset == "Kustom...") {
              _nameController.text = "";
              _isAmountFocused = false;
            } else {
              _nameController.text = preset;
              _isAmountFocused = true;
              FocusScope.of(context).unfocus(); // Dismiss keyboard
            }
          });
        },
        borderRadius: BorderRadius.circular(6.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.borderColor(context),
            ),
          ),
          child: Text(
            preset,
            style: TextStyle(
              fontFamily: AppTheme.fontMedium,
              fontSize: 13.sp,
              color: isSelected ? Colors.white : AppTheme.textColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildNumRow(["7", "8", "9"])),
        SizedBox(height: 10.h),
        Expanded(child: _buildNumRow(["4", "5", "6"])),
        SizedBox(height: 10.h),
        Expanded(child: _buildNumRow(["1", "2", "3"])),
        SizedBox(height: 10.h),
        Expanded(child: _buildNumRow(["0", "000", "⌫"])),
      ],
    );
  }

  Widget _buildNumRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: _buildNumKey(key),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumKey(String key) {
    bool isBackspace = key == "⌫";
    return Material(
      color: isBackspace
          ? Colors.red.withAlpha((255 * 0.1).round())
          : AppTheme.cardColor(context),
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: () => _onKeyTap(key),
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor(context)),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: isBackspace
              ? Icon(Icons.backspace_outlined, color: Colors.red, size: 22.sp)
              : Text(
                  key,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontFamily: AppTheme.fontBold,
                    color: AppTheme.textColor(context),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          fontFamily: AppTheme.fontMedium,
          color: AppTheme.secondaryTextColor(context),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.sp),
      filled: true,
      fillColor: AppTheme.cardColor(context),
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: AppTheme.borderColor(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: AppTheme.borderColor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
