import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImagePickerService {
  static final ImagePickerService _instance = ImagePickerService._internal();
  final ImagePicker _imagePicker = ImagePicker();

  factory ImagePickerService() {
    return _instance;
  }

  ImagePickerService._internal();

  /// Request photo library permission (iOS specific)
  Future<bool> requestPhotoPermission() async {
    try {
      debugPrint('📸 Requesting photo library permission...');

      final status = await Permission.photos.status;
      debugPrint('📸 Photo current status: $status');

      if (status.isPermanentlyDenied) {
        debugPrint('📸 Photo permission is permanently denied');
        debugPrint('📸 User must enable it in Settings');
        return false;
      }

      final requestedStatus = await Permission.photos.request();

      debugPrint('📸 Photo permission status: $requestedStatus');
      debugPrint('📸 Is granted: ${requestedStatus.isGranted}');

      return requestedStatus.isGranted;
    } catch (e) {
      debugPrint('❌ Error requesting photo permission: $e');
      return false;
    }
  }

  /// Request camera permission (iOS specific)
  Future<bool> requestCameraPermission() async {
    try {
      debugPrint('📷 Requesting camera permission...');

      final status = await Permission.camera.status;
      debugPrint('📷 Camera current status: $status');

      if (status.isPermanentlyDenied) {
        debugPrint('📷 Camera permission is permanently denied');
        debugPrint('📷 User must enable it in Settings');
        return false;
      }

      final requestedStatus = await Permission.camera.request();

      debugPrint('📷 Camera permission status: $requestedStatus');
      debugPrint('📷 Is granted: ${requestedStatus.isGranted}');

      return requestedStatus.isGranted;
    } catch (e) {
      debugPrint('❌ Error requesting camera permission: $e');
      return false;
    }
  }

  /// Pick image from gallery (RECOMMENDED FOR PHOTOS)
  Future<File?> pickImageFromGallery() async {
    try {
      debugPrint('📱 Opening photo gallery...');

      // Step 1: Request permission
      // final hasPermission = await requestPhotoPermission();
      // if (!hasPermission) {
      //   debugPrint('❌ Photo permission denied');
      //   return null;
      // }

      debugPrint('✅ Permission granted, opening picker...');

      // Step 2: Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        debugPrint('✅ Image selected: ${file.path}');
        debugPrint('✅ File exists: ${file.existsSync()}');
        debugPrint('✅ File size: ${await file.length()} bytes');
        return file;
      } else {
        debugPrint('⚠️ User cancelled photo picker');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      return null;
    }
  }

  /// Pick multiple images from gallery
  Future<List<File>> pickMultiImageFromGallery() async {
    try {
      debugPrint('📱 Opening photo gallery for multiple images...');

      debugPrint('✅ Opening picker...');

      // Step 2: Pick images
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        final files = pickedFiles.map((x) => File(x.path)).toList();
        debugPrint('✅ ${files.length} images selected');
        return files;
      } else {
        debugPrint('⚠️ User cancelled photo picker');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error picking images: $e');
      return [];
    }
  }

  /// Take photo with camera
  Future<File?> pickImageFromCamera() async {
    try {
      debugPrint('📷 Opening camera...');

      // Step 1: Request permission
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        debugPrint('❌ Camera permission denied');
        return null;
      }

      debugPrint('✅ Permission granted, opening camera...');

      // Step 2: Capture photo
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        debugPrint('✅ Photo captured: ${file.path}');
        return file;
      } else {
        debugPrint('⚠️ User cancelled camera');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error using camera: $e');
      return null;
    }
  }

  /// Get file size in MB
  String getFileSizeMB(File file) {
    try {
      final bytes = file.lengthSync();
      final mb = bytes / (1024 * 1024);
      return mb.toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }

  /// Check current permission status (for debugging)
  Future<void> debugPermissionStatus() async {
    final photoStatus = await Permission.photos.status;
    final cameraStatus = await Permission.camera.status;

    debugPrint('\n=== PERMISSION STATUS ===');
    debugPrint('📱 Photo Library: $photoStatus');
    debugPrint('  - isDenied: ${photoStatus.isDenied}');
    debugPrint('  - isGranted: ${photoStatus.isGranted}');
    debugPrint('  - isPermanentlyDenied: ${photoStatus.isPermanentlyDenied}');
    debugPrint('  - isRestricted: ${photoStatus.isRestricted}');
    debugPrint('');
    debugPrint('📷 Camera: $cameraStatus');
    debugPrint('  - isDenied: ${cameraStatus.isDenied}');
    debugPrint('  - isGranted: ${cameraStatus.isGranted}');
    debugPrint('  - isPermanentlyDenied: ${cameraStatus.isPermanentlyDenied}');
    debugPrint('  - isRestricted: ${cameraStatus.isRestricted}');
    debugPrint('========================\n');
  }
}
