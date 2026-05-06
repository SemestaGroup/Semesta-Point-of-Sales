import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF6366F1); // Indigo from reference
  static const Color secondaryColor = Color(0xFFC7B8F5);
  static const Color scaffoldBgColor = Color(0xFFF8FAFB);

  // Dark Theme Palette
  static const Color darkBackgroundColor = Color(0xFF0F1115);
  static const Color darkCardColor = Color(0xFF1C1C21);
  static const Color darkBorderColor = Color(0xFF2A2A32);
  static const Color darkSidebarColor = Color(0xFF181A1F);

  // Theme-aware colors
  static Color scaffoldBackgroundColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBackgroundColor
          : const Color(0xFFF8FAFB);

  static Color cardColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkCardColor
          : Colors.white;

  static Color borderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBorderColor
          : Colors.grey.shade300;

  static Color textColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black;

  static Color secondaryTextColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF9CA3AF)
          : Colors.grey.shade700;

  // Getters for compatibility (uses Get.context)
  static Color get textColorPrimary {
    try {
      final context = Get.context;
      if (context != null) return textColor(context);
    } catch (_) {}
    return Colors.black;
  }

  static Color get textColorSecondary {
    try {
      final context = Get.context;
      if (context != null) return secondaryTextColor(context);
    } catch (_) {}
    return Colors.grey.shade700;
  }

  // Font Sizes
  static double get fontSizeTitleLarge => 24.sp;
  static double get fontSizeTitleMedium => 20.sp;
  static double get fontSizeHeadline => 18.sp;
  static double get fontSizeBodyLarge => 16.sp;
  static double get fontSizeBodyMedium => 14.sp;
  static double get fontSizeBodySmall => 13.sp;
  static double get fontSizeLabelLarge => 13.sp;
  static double get fontSizeLabelMedium => 12.sp;
  static double get fontSizeLabelSmall => 11.sp;
  static double get fontSizeCaption => 10.sp;
  static double get fontSizeOverline => 9.sp;
  static double get fontSizeTiny => 8.sp;
  static double get fontSizeMicro => 6.sp;
  static double get fontSizeBadge => 9.sp;

  // Font Families
  static const String fontBold = 'popsem';
  static const String fontMedium = 'popmed';
  static const String fontRegular = 'popreg';

  // Text Styles (using Get.context for reactivity)
  static TextStyle get titleLarge => TextStyle(
        fontFamily: fontBold,
        fontSize: fontSizeTitleLarge,
        color: textColorPrimary,
      );

  static TextStyle get titleMedium => TextStyle(
        fontFamily: fontBold,
        fontSize: fontSizeTitleMedium,
        color: textColorPrimary,
      );

  static TextStyle get bodyLarge => TextStyle(
        fontFamily: fontMedium,
        fontSize: fontSizeBodyLarge,
        color: textColorPrimary,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontFamily: fontRegular,
        fontSize: fontSizeBodyMedium,
        color: textColorPrimary,
      );

  static TextStyle get bodySmall => TextStyle(
        fontFamily: fontRegular,
        fontSize: fontSizeBodySmall,
        color: textColorPrimary,
      );

  static TextStyle get labelMedium => TextStyle(
        fontFamily: fontRegular,
        fontSize: fontSizeLabelMedium,
        color: textColorSecondary,
      );

  static TextStyle get labelSmall => TextStyle(
        fontFamily: fontRegular,
        fontSize: fontSizeLabelSmall,
        color: textColorSecondary,
      );

  static TextStyle get caption => TextStyle(
        fontFamily: fontRegular,
        fontSize: fontSizeCaption,
        color: textColorSecondary,
      );

  static TextStyle get overline => TextStyle(
        fontFamily: fontRegular,
        fontSize: fontSizeOverline,
        color: textColorSecondary,
      );

  static Color sidebarColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSidebarColor
          : Colors.white;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Common Decorations
  static BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
        color: cardColor(context),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      );
}
