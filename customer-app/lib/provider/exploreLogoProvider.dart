import 'package:project/helper/utils/generalImports.dart';

class ExploreLogoProvider extends ChangeNotifier {
  String? mediaUrl;
  bool isLoaded = false;

  /// Determines media type from URL extension
  /// Returns: "video", "gif", or "image"
  String get mediaType {
    if (mediaUrl == null) return "image";
    final lower = mediaUrl!.toLowerCase();
    if (lower.contains(".mp4") ||
        lower.contains(".mov") ||
        lower.contains(".avi") ||
        lower.contains(".webm")) {
      return "video";
    }
    if (lower.contains(".gif")) {
      return "gif";
    }
    return "image";
  }

  Future<void> fetchExploreLogo(BuildContext context) async {
    try {
      final response =
          await fetchAppMedia(context: context, type: "explore_logo");
      if (response['status'] == 1 && response['data'] != null) {
        mediaUrl = response['data']['explore_logo']?.toString();
        isLoaded = true;
      }
    } catch (e) {
      debugPrint("Error fetching explore logo: $e");
    }
    notifyListeners();
  }
}
