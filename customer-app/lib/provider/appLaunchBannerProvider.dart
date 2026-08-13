import 'package:flutter/material.dart';
import 'package:project/models/app_launch_banner.dart';
import 'package:project/repositories/appLaunchBannerApi.dart';

enum AppLaunchBannerState { initial, loading, loaded, error }

class AppLaunchBannerProvider extends ChangeNotifier {
  AppLaunchBannerState state = AppLaunchBannerState.initial;
  AppLaunchBanner? bannerData;
  String message = "";

  Future<void> fetchBanner(BuildContext context) async {
    state = AppLaunchBannerState.loading;
    notifyListeners();

    try {
      final response = await getAppLaunchBanner(context: context);
      debugPrint('+++++++++++++fetch banners data+++++++++');
      print(response);
 
      if (response['status'] == 1) {
        bannerData = AppLaunchBanner.fromJson(response);
        state = AppLaunchBannerState.loaded;
      } else {
        message = response['message'] ?? "Failed to load banner";
        state = AppLaunchBannerState.error;
      }
    } catch (e) {
      debugPrint("❌ Error fetching app launch banner: $e");
      message = e.toString();
      state = AppLaunchBannerState.error;
    }

    notifyListeners();
  }

  bool get hasBanner => bannerData?.isActive ?? false;

  String get bannerUrl => bannerData?.url ?? "";

  Color get bannerColor {
    final colorString = bannerData?.color ?? "#9AC444";
    return _colorFromHex(colorString);
  }

  double get bannerAspectRatio => bannerData?.aspectRatio ?? (16 / 9);

  List<dynamic> get specialItems => bannerData?.specialItems?.data ?? [];

  /// Returns "video", "gif", or "image" based on the banner URL extension
  String get bannerMediaType {
    final url = bannerUrl.toLowerCase();
    if (url.contains(".mp4") ||
        url.contains(".mov") ||
        url.contains(".avi") ||
        url.contains(".webm")) {
      return "video";
    }
    if (url.contains(".gif")) {
      return "gif";
    }
    return "image";
  }

  Color _colorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
