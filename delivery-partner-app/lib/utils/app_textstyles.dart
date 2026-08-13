import 'package:flutter/material.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/utils/app_colors.dart';
import 'package:zenfoo_partner/utils/app_fonts.dart';

/// Text Styles
class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textColor,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textColor,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    color: AppColors.black,
  );

  static const TextStyle bodyText2 = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textColor,
  );

  static const TextStyle titleBlack = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textColor,
  );

  static const TextStyle titleWhite = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.normal,
    fontFamily: AppFonts.regular,
    color: AppColors.white,
  );
  static const TextStyle normalWhite = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static const TextStyle normalBlack = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );
  static const TextStyle normalPrimary = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );
  static const TextStyle normalGrey = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: Colors.grey,
  );

  static const TextStyle subtitleBlack = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textColor,
  );

  static const TextStyle subtitleWhite = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.normal,
    fontFamily: AppFonts.regular,
    color: AppColors.white,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
}
