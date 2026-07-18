// lib/theme/themed_time_picker.dart
//
// Shared showTimePicker theming (teal/navy, matches the rest of the app)
// so every new time picker doesn't have to redeclare the same ThemeData —
// pulled out as a standalone builder rather than duplicating the private
// copy already living inside AdvancedDatePicker.
import 'package:flutter/material.dart';
import 'app_colors.dart';

Widget themedTimePickerBuilder(BuildContext context, Widget? child) {
  return Theme(
    data: ThemeData.light().copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.teal,
        onPrimary: AppColors.white,
        onSurface: AppColors.deepNavy,
        surface: AppColors.white,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.teal),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.white,
        dialBackgroundColor: AppColors.subtleGray,
        dialHandColor: AppColors.teal,
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hourMinuteColor: WidgetStateColor.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.lightTeal
                : AppColors.subtleGray),
        hourMinuteTextColor: WidgetStateColor.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.teal
                : AppColors.deepNavy),
        dialTextColor: WidgetStateColor.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.white
                : AppColors.deepNavy),
        dayPeriodShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.border),
        ),
        dayPeriodBorderSide: const BorderSide(color: AppColors.border),
        dayPeriodColor: WidgetStateColor.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.lightTeal
                : AppColors.white),
        dayPeriodTextColor: WidgetStateColor.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.teal
                : AppColors.slateGray),
        entryModeIconColor: AppColors.slateGray,
        helpTextStyle: const TextStyle(
            color: AppColors.deepNavy, fontWeight: FontWeight.w600),
      ),
    ),
    child: child!,
  );
}
