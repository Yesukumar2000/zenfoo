import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';

class ColorsRes {
  static const MaterialColor appColor = MaterialColor(
    0xFF9AC444,
    <int, Color>{
      50: Color(0xFFEFF6E3),
      100: Color(0xFFD7E9BD),
      200: Color(0xFFBDDB94),
      300: Color(0xFFA3CD6B),
      400: Color(0xFF90C24B),
      500: Color(0xFF9AC444), // base
      600: Color(0xFF84AA3B),
      700: Color(0xFF719032),
      800: Color(0xFF5E7629),
      900: Color(0xFF48571E),
    },
  );

  static Color appColorLight = Color(0xffF4FAE3);
  static Color appColorLightHalfTransparent = Color(0x269AC444);

  static List<Color> sellerStatisticsColors = [
    Color(0xff406fc6),
    Color(0xfffe9670),
    Color(0xff3c8dbc),
    Color(0xff64c77a),
  ];

  static Color gradient1 = Color(0xffB9E990);
  static Color gradient2 = Color(0xff9AC444);

  static Color defaultPageInnerCircle = Color(0x1A999999);
  static Color defaultPageOuterCircle = Color(0x0d999999);

  static Color mainTextColor = Colors.black;
  static Color subTitleTextColor = Color(0xff999999);

  static Color bgColorLight = Color(0xfff7f7f7);
  static Color bgColorDark = Color(0xff141A1F);

  static Color cardColorLight = Color(0xffffffff);
  static Color cardColorDark = Color(0xff202934);

  //This will remain same in dark and light theme as well
  static Color lightThemeTextColor = Colors.black;
  static Color darkThemeTextColor = Colors.white;

  static MaterialColor grey = Colors.grey;
  static Color appColorWhite = Colors.white;
  static Color appColorBlack = Colors.black;
  static MaterialColor appColorRed = Colors.red;
  static Color appColorOrange = Colors.orange;
  static Color appColorGreen = Colors.green;
  static Color appColorTransparent = Colors.transparent;
  static Color appColorAmber = Colors.amber;
  static MaterialColor appColorYellow = Colors.yellow;
  static Color appColorBlack45 = Colors.black45;
  static Color appColorBlack38 = Colors.black38;

  static Color greyBox = Color(0x0a000000);
  static Color lightGreyBox = Color.fromARGB(9, 213, 212, 212);

  //It will be same for both theme
  static Color shimmerBaseColor = Colors.white;
  static Color shimmerHighlightColor = Colors.white;
  static Color shimmerContentColor = Colors.white;

  //Dark theme shimmer color
  static Color shimmerBaseColorDark = Colors.grey.withValues(alpha: 0.05);
  static Color shimmerHighlightColorDark = Colors.grey.withValues(alpha: 0.005);
  static Color shimmerContentColorDark = Colors.black;

  //Light theme shimmer color
  static Color shimmerBaseColorLight = Colors.black.withValues(alpha: 0.05);
  static Color shimmerHighlightColorLight =
      Colors.black.withValues(alpha: 0.005);
  static Color shimmerContentColorLight = Colors.white;

  static ThemeData lightTheme = ThemeData(
    primaryColor: appColor,
    brightness: Brightness.light,
    scaffoldBackgroundColor: bgColorLight,
    cardColor: cardColorLight,
    iconTheme: IconThemeData(
      color: Colors.black,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(
        color: Colors.black,
      ),
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: ColorsRes.appColor,
      accentColor: ColorsRes.appColor,
    ).copyWith(
      surface: Colors.white,
      brightness: Brightness.light,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    primaryColor: appColor,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgColorDark,
    cardColor: cardColorDark,
    iconTheme: IconThemeData(
      color: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: ColorsRes.appColor,
      accentColor: ColorsRes.appColor,
    ).copyWith(
      surface: Colors.grey,
      brightness: Brightness.dark,
    ),
  );

  static ThemeData setAppTheme() {
    String theme = Constant.session.getData(SessionManager.appThemeName);
    bool isDarkTheme = Constant.session.getBoolData(SessionManager.isDarkTheme);

    bool isDark = false;
    if (theme == Constant.themeList[2]) {
      isDark = true;
    } else if (theme == Constant.themeList[1]) {
      isDark = false;
    } else if (theme == "" || theme == Constant.themeList[0]) {
      var brightness = PlatformDispatcher.instance.platformBrightness;
      isDark = brightness == Brightness.dark;

      if (theme == "") {
        Constant.session
            .setData(SessionManager.appThemeName, Constant.themeList[0], false);
      }
    }

    if (isDark) {
      if (!isDarkTheme) {
        Constant.session.setBoolData(SessionManager.isDarkTheme, true, false);
      }
      mainTextColor = darkThemeTextColor;
      shimmerBaseColor = shimmerBaseColorDark;
      shimmerHighlightColor = shimmerHighlightColorDark;

      shimmerContentColor = shimmerContentColorDark;
      return darkTheme;
    } else {
      if (isDarkTheme) {
        Constant.session.setBoolData(SessionManager.isDarkTheme, false, false);
      }
      mainTextColor = lightThemeTextColor;
      shimmerBaseColor = shimmerBaseColorLight;
      shimmerHighlightColor = shimmerHighlightColorLight;
      shimmerContentColor = shimmerContentColorLight;
      return lightTheme;
    }
  }
}
