import 'package:zenfoo_partner/main.dart';

class AppDimensions {
  static double getWidth(double width) {
    return screenWidth * (width / 100);
  }

  static double getHeight(double height) {
    return screenHeight * (height / 100);
  }

  static double getSize(double size) {
    // return 20 * (size / 100);
    return size;
  }

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  static const double marginSmall = 8.0;
  static const double marginMedium = 18.0;
  static const double marginLarge = 24.0;

  static const double borderRadius = 12.0;
}
