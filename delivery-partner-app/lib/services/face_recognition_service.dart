import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_face_api/flutter_face_api.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class FaceRecognitionService {
  final FaceSDK _faceSDK = FaceSDK.instance;
  bool _isInitialized = false;

  /// Initialize the Face SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize the SDK
      // The SDK may require a license key for production use
      _isInitialized = true;
      debugPrint('Face SDK ready');
    } catch (e) {
      debugPrint('Error initializing Face SDK: $e');
      rethrow;
    }
  }

  /// Compare a captured face image with a profile image URL.
  /// Returns a similarity score between 0.0 and 1.0.
  /// Returns -1.0 if comparison fails.
  Future<double> compareFaces({
    required File capturedImage,
    required String profileImageUrl,
  }) async {
    try {
      // Ensure SDK is initialized
      if (!_isInitialized) {
        await initialize();
      }

      debugPrint('📥 Captured image path: ${capturedImage.path}');
      debugPrint('📥 Captured image exists: ${await capturedImage.exists()}');

      if (!await capturedImage.exists()) {
        debugPrint('❌ Captured image file does not exist');
        return -1.0;
      }

      // Download profile image
      final profileImageFile = await _downloadFile(profileImageUrl);
      if (profileImageFile == null) {
        debugPrint('❌ Failed to download profile image');
        return -1.0;
      }

      debugPrint('📥 Profile image downloaded: ${profileImageFile.path}');
      debugPrint('📥 Profile image size: ${await profileImageFile.length()} bytes');

      // Read image bytes and validate
      final image1Bytes = await capturedImage.readAsBytes();
      final image2Bytes = await profileImageFile.readAsBytes();

      debugPrint('📊 Captured image bytes length: ${image1Bytes.length}');
      debugPrint('📊 Profile image bytes length: ${image2Bytes.length}');

      if (image1Bytes.isEmpty) {
        debugPrint('❌ Captured image has no data');
        await profileImageFile.delete();
        return -1.0;
      }

      if (image2Bytes.isEmpty) {
        debugPrint('❌ Profile image has no data');
        await profileImageFile.delete();
        return -1.0;
      }

      debugPrint('🔄 Creating MatchFacesImage objects...');

      // Create MatchFacesImage objects with LIVE type for captured image
      final image1 = MatchFacesImage(image1Bytes, ImageType.LIVE);
      final image2 = MatchFacesImage(image2Bytes, ImageType.PRINTED);

      debugPrint('🔄 Creating MatchFacesRequest...');

      // Create match request
      final request = MatchFacesRequest([image1, image2]);

      debugPrint('🔄 Calling matchFaces...');

      // Perform face matching - returns MatchFacesResponse directly
      final matchResponse = await _faceSDK.matchFaces(request);

      debugPrint('✅ Match response received');

      // Clean up downloaded file
      await profileImageFile.delete();

      // Check if we have match results
      final results = matchResponse.results;
      if (results.isEmpty) {
        debugPrint('⚠️ No match results - no faces detected');
        return 0.0;
      }

      // Get the similarity score from the first result
      final similarity = results.first.similarity;

      debugPrint('✅ Face match similarity: $similarity');

      return similarity;
    } catch (e, stackTrace) {
      debugPrint('❌ Error comparing faces: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return -1.0;
    }
  }

  Future<File?> _downloadFile(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/temp_profile_image.jpg');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      debugPrint('Error downloading file: $e');
    }
    return null;
  }

  void dispose() {
    // Clean up if needed
  }
}
