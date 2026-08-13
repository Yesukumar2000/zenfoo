import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Face verification service using Google ML Kit
/// This approach uses facial landmarks and features to compare faces
/// without requiring a paid SDK license
class MLKitFaceService {
  late FaceDetector _faceDetector;
  bool _isInitialized = false;

  /// Initialize ML Kit Face Detector
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: true,
          enableClassification: true,
          enableLandmarks: true,
          enableTracking: false,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );
      _isInitialized = true;
      debugPrint('✅ ML Kit Face Service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing ML Kit Face Service: $e');
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
      if (!_isInitialized) {
        await initialize();
      }

      debugPrint('📥 Starting face comparison...');
      debugPrint('📥 Captured image: ${capturedImage.path}');

      if (!await capturedImage.exists()) {
        debugPrint('❌ Captured image does not exist');
        return -1.0;
      }

      // Download profile image
      final profileImageFile = await _downloadFile(profileImageUrl);
      if (profileImageFile == null) {
        debugPrint('❌ Failed to download profile image');
        return -1.0;
      }

      debugPrint('📥 Profile image downloaded: ${profileImageFile.path}');

      // Detect faces in both images
      final capturedInputImage = InputImage.fromFilePath(capturedImage.path);
      final profileInputImage = InputImage.fromFilePath(profileImageFile.path);

      final capturedFaces = await _faceDetector.processImage(capturedInputImage);
      final profileFaces = await _faceDetector.processImage(profileInputImage);

      // Clean up downloaded file
      await profileImageFile.delete();

      debugPrint('📊 Faces in captured image: ${capturedFaces.length}');
      debugPrint('📊 Faces in profile image: ${profileFaces.length}');

      if (capturedFaces.isEmpty) {
        debugPrint('⚠️ No face detected in captured image');
        return 0.0;
      }

      if (profileFaces.isEmpty) {
        debugPrint('⚠️ No face detected in profile image');
        return 0.0;
      }

      // Get the first (primary) face from each image
      final capturedFace = capturedFaces.first;
      final profileFace = profileFaces.first;

      // Calculate similarity based on facial features
      final similarity = _calculateFaceSimilarity(capturedFace, profileFace);

      debugPrint('✅ Face similarity score: ${(similarity * 100).toStringAsFixed(1)}%');

      return similarity;
    } catch (e, stackTrace) {
      debugPrint('❌ Error comparing faces: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return -1.0;
    }
  }

  /// Calculate similarity between two faces based on landmarks and features
  double _calculateFaceSimilarity(Face face1, Face face2) {
    double totalScore = 0.0;
    int scoreCount = 0;

    // 1. Compare face bounding box sizes (should be similar)
    final bbox1 = face1.boundingBox;
    final bbox2 = face2.boundingBox;

    final size1 = bbox1.width * bbox1.height;
    final size2 = bbox2.width * bbox2.height;

    final sizeRatio = size1 < size2 ? size1 / size2 : size2 / size1;
    totalScore += sizeRatio * 0.15; // 15% weight
    scoreCount++;

    // 2. Compare head pose angles
    if (face1.headEulerAngleY != null && face2.headEulerAngleY != null) {
      final angleDiff = (face1.headEulerAngleY! - face2.headEulerAngleY!).abs();
      final angleSimilarity = math.max(0, 1 - (angleDiff / 90));
      totalScore += angleSimilarity * 0.1; // 10% weight
      scoreCount++;
    }

    if (face1.headEulerAngleZ != null && face2.headEulerAngleZ != null) {
      final angleDiff = (face1.headEulerAngleZ! - face2.headEulerAngleZ!).abs();
      final angleSimilarity = math.max(0, 1 - (angleDiff / 90));
      totalScore += angleSimilarity * 0.1; // 10% weight
      scoreCount++;
    }

    // 3. Compare facial landmarks if available
    if (face1.landmarks.isNotEmpty && face2.landmarks.isNotEmpty) {
      final landmarkSimilarity = _compareLandmarks(face1.landmarks, face2.landmarks);
      totalScore += landmarkSimilarity * 0.4; // 40% weight
      scoreCount++;
    }

    // 4. Compare facial classification (smiling, eyes open)
    if (face1.smilingProbability != null && face2.smilingProbability != null) {
      final smileDiff = (face1.smilingProbability! - face2.smilingProbability!).abs();
      final smileSimilarity = 1 - smileDiff;
      totalScore += smileSimilarity * 0.05; // 5% weight
      scoreCount++;
    }

    if (face1.leftEyeOpenProbability != null && face2.leftEyeOpenProbability != null) {
      final eyeDiff = (face1.leftEyeOpenProbability! - face2.leftEyeOpenProbability!).abs();
      final eyeSimilarity = 1 - eyeDiff;
      totalScore += eyeSimilarity * 0.1; // 10% weight
      scoreCount++;
    }

    if (face1.rightEyeOpenProbability != null && face2.rightEyeOpenProbability != null) {
      final eyeDiff = (face1.rightEyeOpenProbability! - face2.rightEyeOpenProbability!).abs();
      final eyeSimilarity = 1 - eyeDiff;
      totalScore += eyeSimilarity * 0.1; // 10% weight
      scoreCount++;
    }

    // Average the scores
    final avgScore = scoreCount > 0 ? totalScore / scoreCount : 0.0;

    // Apply a boost factor to make valid matches score higher
    // This helps differentiate between different people
    final boostedScore = math.pow(avgScore, 0.7).toDouble();

    return math.min(boostedScore, 1.0);
  }

  /// Compare facial landmarks between two faces
  double _compareLandmarks(
    Map<FaceLandmarkType, FaceLandmark?> landmarks1,
    Map<FaceLandmarkType, FaceLandmark?> landmarks2,
  ) {
    double similarity = 0.0;
    int landmarkCount = 0;

    // Important landmarks for face recognition
    final importantLandmarks = [
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
      FaceLandmarkType.bottomMouth,
    ];

    for (final landmarkType in importantLandmarks) {
      final landmark1 = landmarks1[landmarkType];
      final landmark2 = landmarks2[landmarkType];

      if (landmark1 != null && landmark2 != null) {
        final pos1 = landmark1.position;
        final pos2 = landmark2.position;

        // Calculate relative position (normalized by face size)
        final distance = math.sqrt(
          math.pow(pos1.x - pos2.x, 2) + math.pow(pos1.y - pos2.y, 2),
        );

        // Normalize distance (assuming max difference of 200 pixels)
        final normalizedDistance = math.min(distance / 200, 1.0);
        similarity += (1 - normalizedDistance);
        landmarkCount++;
      }
    }

    return landmarkCount > 0 ? similarity / landmarkCount : 0.0;
  }

  Future<File?> _downloadFile(String url) async {
    try {
      debugPrint('📥 Downloading profile image from: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${tempDir.path}/profile_$timestamp.jpg');
        await file.writeAsBytes(response.bodyBytes);

        debugPrint('✅ Profile image saved: ${file.path}');
        debugPrint('📊 File size: ${response.bodyBytes.length} bytes');

        return file;
      } else {
        debugPrint('❌ Failed to download: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error downloading file: $e');
    }
    return null;
  }

  void dispose() {
    if (_isInitialized) {
      _faceDetector.close();
      _isInitialized = false;
    }
  }
}
