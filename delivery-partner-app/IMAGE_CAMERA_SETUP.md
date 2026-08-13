# Image & Camera Permissions Setup Guide

Complete guide for adding photo/camera functionality with proper iOS and Android permissions.

---

## 1. iOS Configuration (Critical)

### Info.plist Permissions

Edit `ios/Runner/Info.plist` and add these keys:

```xml
<!-- Camera Permission -->
<key>NSCameraUsageDescription</key>
<string>We need camera access to take photos for orders</string>

<!-- Photo Library Permission -->
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to select images</string>

<!-- Photo Library Add Permission (for saving photos) -->
<key>NSPhotoLibraryAddOnlyUsageDescription</key>
<string>We need permission to save photos to your library</string>

<!-- Microphone (if recording video) -->
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for video recording</string>
```

### Complete Example Info.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- ... existing keys ... -->

    <key>NSCameraUsageDescription</key>
    <string>We need camera access to take photos for orders</string>

    <key>NSPhotoLibraryUsageDescription</key>
    <string>We need access to your photo library to select images</string>

    <key>NSPhotoLibraryAddOnlyUsageDescription</key>
    <string>We need permission to save photos to your library</string>

    <key>NSMicrophoneUsageDescription</key>
    <string>We need microphone access for video recording</string>

    <!-- ... rest of keys ... -->
</dict>
</plist>
```

---

## 2. Android Configuration

### AndroidManifest.xml Permissions

Edit `android/app/src/main/AndroidManifest.xml` and add:

```xml
<!-- Camera Permission -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Photo Library Permissions -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<!-- For Android 13+ (Scoped Storage) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
```

### Complete Example
```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Permissions -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />

    <!-- ... rest of manifest ... -->

    <application>
        <!-- ... application config ... -->
    </application>
</manifest>
```

---

## 3. Flutter Service Implementation

Create `lib/services/image_picker_service.dart`:

```dart
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

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.camera.request();
      debugPrint('📷 Android Camera Permission: $status');
      return status.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.camera.request();
      debugPrint('📷 iOS Camera Permission: $status');
      return status.isGranted;
    }
    return false;
  }

  /// Request photo library permission
  Future<bool> requestPhotoLibraryPermission() async {
    if (Platform.isAndroid) {
      PermissionStatus status;
      if (Platform.version.contains('13')) {
        // Android 13+: Use READ_MEDIA_IMAGES
        status = await Permission.photos.request();
      } else {
        // Android 12 and below: Use READ_EXTERNAL_STORAGE
        status = await Permission.storage.request();
      }
      debugPrint('📱 Android Photo Permission: $status');
      return status.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      debugPrint('📱 iOS Photo Permission: $status');
      return status.isGranted;
    }
    return false;
  }

  /// Pick image from camera
  /// Returns: File object or null if cancelled/failed
  Future<File?> pickFromCamera() async {
    try {
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        debugPrint('❌ Camera permission denied');
        return null;
      }

      debugPrint('📷 Opening camera...');
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Compress to 85% quality
      );

      if (pickedFile != null) {
        debugPrint('✅ Image captured: ${pickedFile.path}');
        return File(pickedFile.path);
      } else {
        debugPrint('⚠️ Camera cancelled by user');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error capturing image: $e');
      return null;
    }
  }

  /// Pick image from photo library
  /// Returns: File object or null if cancelled/failed
  Future<File?> pickFromGallery() async {
    try {
      final hasPermission = await requestPhotoLibraryPermission();
      if (!hasPermission) {
        debugPrint('❌ Photo library permission denied');
        return null;
      }

      debugPrint('📱 Opening photo library...');
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        debugPrint('✅ Image selected: ${pickedFile.path}');
        return File(pickedFile.path);
      } else {
        debugPrint('⚠️ Photo library cancelled by user');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      return null;
    }
  }

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleFromGallery() async {
    try {
      final hasPermission = await requestPhotoLibraryPermission();
      if (!hasPermission) {
        debugPrint('❌ Photo library permission denied');
        return [];
      }

      debugPrint('📱 Opening photo library (multi-select)...');
      final pickedFiles = await _imagePicker.pickMultipleMedia(
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        final files = pickedFiles.map((file) => File(file.path)).toList();
        debugPrint('✅ Selected ${files.length} images');
        return files;
      } else {
        debugPrint('⚠️ Multi-select cancelled');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error picking multiple images: $e');
      return [];
    }
  }

  /// Check if camera is available on device
  Future<bool> isCameraAvailable() async {
    try {
      final cameras = await _imagePicker.getAvailableCameras();
      return cameras.isNotEmpty;
    } catch (e) {
      debugPrint('⚠️ Error checking camera availability: $e');
      return false;
    }
  }

  /// Get file size in MB
  String getFileSizeMB(File file) {
    final bytes = file.lengthSync();
    final mb = bytes / (1024 * 1024);
    return mb.toStringAsFixed(2);
  }
}
```

---

## 4. Bottom Sheet Implementation

Create a reusable image picker bottom sheet:

```dart
// Add to lib/view/custom_widgets/ or any custom widgets folder

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zenfoo_partner/services/image_picker_service.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';

class ImagePickerBottomSheet {
  static void show({
    required BuildContext context,
    required AppColorScheme colorScheme,
    required Function(File) onImageSelected,
    String title = 'Select Image',
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ImagePickerSheet(
        colorScheme: colorScheme,
        onImageSelected: onImageSelected,
        title: title,
      ),
    );
  }
}

class _ImagePickerSheet extends StatefulWidget {
  final AppColorScheme colorScheme;
  final Function(File) onImageSelected;
  final String title;

  const _ImagePickerSheet({
    required this.colorScheme,
    required this.onImageSelected,
    required this.title,
  });

  @override
  State<_ImagePickerSheet> createState() => _ImagePickerSheetState();
}

class _ImagePickerSheetState extends State<_ImagePickerSheet> {
  final ImagePickerService _imagePickerService = ImagePickerService();
  bool _isLoading = false;

  /// Pick from camera with permission check
  Future<void> _pickFromCamera() async {
    setState(() => _isLoading = true);

    try {
      final file = await _imagePickerService.pickFromCamera();

      if (file != null) {
        final sizeMB = _imagePickerService.getFileSizeMB(file);
        debugPrint('📷 Camera image size: ${sizeMB}MB');

        if (mounted) {
          Navigator.pop(context);
          widget.onImageSelected(file);
        }
      } else {
        _showError('Failed to capture image');
      }
    } catch (e) {
      debugPrint('❌ Camera error: $e');
      _showError('Error accessing camera');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Pick from gallery with permission check
  Future<void> _pickFromGallery() async {
    setState(() => _isLoading = true);

    try {
      final file = await _imagePickerService.pickFromGallery();

      if (file != null) {
        final sizeMB = _imagePickerService.getFileSizeMB(file);
        debugPrint('📱 Gallery image size: ${sizeMB}MB');

        if (mounted) {
          Navigator.pop(context);
          widget.onImageSelected(file);
        }
      } else {
        _showError('Failed to select image');
      }
    } catch (e) {
      debugPrint('❌ Gallery error: $e');
      _showError('Error accessing photo library');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: widget.colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: widget.colorScheme.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                widget.title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: widget.colorScheme.textPrimary,
                ),
              ),
            ),

            // Camera Option
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildOption(
                icon: Icons.camera_alt_rounded,
                label: 'Take Photo',
                description: 'Capture image using camera',
                onTap: _isLoading ? null : _pickFromCamera,
              ),
            ),

            // Gallery Option
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildOption(
                icon: Icons.image_rounded,
                label: 'Choose from Gallery',
                description: 'Select from your photos',
                onTap: _isLoading ? null : _pickFromGallery,
              ),
            ),

            // Cancel Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: widget.colorScheme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.colorScheme.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.colorScheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.colorScheme.cardBorder,
            width: 1,
          ),
        ),
        child: _isLoading
            ? Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.colorScheme.primary,
                    ),
                  ),
                ),
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: widget.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.colorScheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: widget.colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: widget.colorScheme.textSecondary,
                    size: 16,
                  ),
                ],
              ),
      ),
    );
  }
}
```

---

## 5. Usage in Your Screen

### Example: Adding to Document Upload Screen

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/services/image_picker_service.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/view/custom_widgets/image_picker_bottom_sheet.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  File? _selectedImage;
  final ImagePickerService _imagePickerService = ImagePickerService();

  /// Handle image selection from bottom sheet
  void _onImageSelected(File imageFile) {
    setState(() {
      _selectedImage = imageFile;
    });

    debugPrint('✅ Image selected: ${imageFile.path}');
    debugPrint('📦 File size: ${_imagePickerService.getFileSizeMB(imageFile)} MB');

    // TODO: Upload image or process it
  }

  /// Show image picker bottom sheet
  void _showImagePicker() {
    final colorScheme = context.read<ThemeProvider>().colorScheme;

    ImagePickerBottomSheet.show(
      context: context,
      colorScheme: colorScheme,
      onImageSelected: _onImageSelected,
      title: 'Upload Document',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Upload Document'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview
            if (_selectedImage != null)
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(_selectedImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: colorScheme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.cardBorder,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                        color: colorScheme.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No image selected',
                        style: TextStyle(
                          color: colorScheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Select Image Button
            GestureDetector(
              onTap: _showImagePicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_a_photo_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Select Image',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Image Details
            if (_selectedImage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Size: ${_imagePickerService.getFileSizeMB(_selectedImage!)} MB',
                      style: TextStyle(
                        color: colorScheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Path: ${_selectedImage!.path}',
                      style: TextStyle(
                        color: colorScheme.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## 6. iOS Permissions Flow

### User Experience
```
User taps "Take Photo" or "Choose from Gallery"
    ↓
App checks permission status
    ↓
If NOT granted:
    ├─ Show iOS native permission dialog
    ├─ User grants or denies
    └─ Proceed accordingly
    ↓
If granted:
    ├─ Open Camera or Photo Library
    ├─ User selects image
    └─ Image returned to app
    ↓
App displays image in preview
```

### Permission Dialog Text
The text users see on iOS:

**Camera:** "We need camera access to take photos for orders"

**Photo Library:** "We need access to your photo library to select images"

---

## 7. Android Permissions Flow

### API Level Handling

**Android 13+ (API 33+):**
- Uses `READ_MEDIA_IMAGES` permission
- Per-media scoped access
- More granular control

**Android 12 and below:**
- Uses `READ_EXTERNAL_STORAGE` permission
- Broader storage access

### Automatic Handling
The `ImagePickerService` automatically handles version checking:

```dart
if (Platform.version.contains('13')) {
  // Android 13+: Use READ_MEDIA_IMAGES
  status = await Permission.photos.request();
} else {
  // Android 12 and below
  status = await Permission.storage.request();
}
```

---

## 8. Permission Status Codes

| Status | Meaning | Action |
|--------|---------|--------|
| `granted` | ✅ Permission given | Proceed with camera/gallery |
| `denied` | ❌ User denied | Show error, ask to allow in settings |
| `restricted` | 🚫 OS restricted (parental controls) | Show explanation |
| `permanentlyDenied` | 🚫 User denied permanently | Guide to app settings |

---

## 9. Error Handling

### Common Scenarios

**Camera/Gallery Cancelled:**
```dart
if (file != null) {
  // Image was selected
} else {
  // User cancelled (dismiss dialog/sheet)
}
```

**Permission Denied:**
```dart
final status = await Permission.camera.request();
if (status.isDenied) {
  showDialog(...); // Show explanation
} else if (status.isPermanentlyDenied) {
  openAppSettings(); // Guide to settings
}
```

**File Too Large:**
```dart
final sizeMB = _imagePickerService.getFileSizeMB(file);
if (sizeMB > 5.0) {
  showError('Image too large (max 5 MB)');
}
```

---

## 10. Image Compression Options

Adjust compression in `ImagePickerService`:

```dart
// Current: 85% quality
final pickedFile = await _imagePicker.pickImage(
  source: ImageSource.camera,
  imageQuality: 85, // 0-100 (higher = better quality, larger file)
);

// Options:
// imageQuality: 70  // High compression, ~1-2 MB
// imageQuality: 85  // Moderate compression, ~2-4 MB  (RECOMMENDED)
// imageQuality: 95  // Low compression, ~4-8 MB
// imageQuality: 100 // No compression, >8 MB
```

---

## 11. Testing Checklist

### iOS Testing
- [ ] Request camera permission → see dialog
- [ ] Grant permission → camera opens
- [ ] Take photo → image appears
- [ ] Request photo library → see dialog
- [ ] Grant permission → library opens
- [ ] Select image → image appears
- [ ] Deny permission → error shown
- [ ] Check Settings for permission toggle

### Android Testing
- [ ] On Android 13+ device
- [ ] On Android 12 device
- [ ] Grant permission → works
- [ ] Deny permission → error shown
- [ ] Image quality correct
- [ ] File size reasonable

---

## 12. Quick Reference Code

### One-liner: Pick Image and Show
```dart
final file = await ImagePickerService().pickFromCamera();
if (file != null) {
  setState(() => _image = file);
}
```

### Show Bottom Sheet
```dart
ImagePickerBottomSheet.show(
  context: context,
  colorScheme: colorScheme,
  onImageSelected: (file) {
    setState(() => _image = file);
  },
  title: 'Select Photo',
);
```

### Check Permissions
```dart
final hasCameraPermission =
  await ImagePickerService().requestCameraPermission();
```

### Get File Size
```dart
final sizeMB = ImagePickerService().getFileSizeMB(imageFile);
print('File size: ${sizeMB}MB');
```

---

## 13. Troubleshooting

### iOS Issues

**"Cannot access camera" error:**
- Check `Info.plist` has `NSCameraUsageDescription`
- Verify key names are exact
- Restart app after Info.plist changes

**Photo library not showing:**
- Check `NSPhotoLibraryUsageDescription` in Info.plist
- Grant permission in Settings → App
- Restart app

**Permission dialog not appearing:**
- User may have permanently denied (check Settings)
- Clear app cache: Settings → General → iPhone Storage → App → Delete → Reinstall

### Android Issues

**"Cannot access gallery" error:**
- Check `AndroidManifest.xml` has READ_EXTERNAL_STORAGE
- For Android 13+, add READ_MEDIA_IMAGES
- Rebuild and reinstall app

**Image picker crashes:**
- Add `android:requestLegacyExternalStorage="true"` to `<application>` tag
- Target API 32+ for READ_MEDIA_IMAGES support

**Scoped storage errors (Android 11+):**
- Ensure permissions are for individual media, not all storage
- Use proper scope attributes in manifest

---

## 14. File Locations

### iOS
- **Info.plist:** `ios/Runner/Info.plist`
- **Build settings:** `ios/Runner.xcodeproj`

### Android
- **AndroidManifest.xml:** `android/app/src/main/AndroidManifest.xml`
- **Build settings:** `android/app/build.gradle`

---

## 15. Summary

✅ **Setup Required:**
1. Add permissions to `Info.plist` (iOS)
2. Add permissions to `AndroidManifest.xml` (Android)
3. Create `ImagePickerService` class
4. Create `ImagePickerBottomSheet` widget
5. Import and use in your screens

✅ **Dependencies Already Added:**
- `image_picker: ^1.2.0` ✓
- `permission_handler: ^12.0.1` ✓

✅ **Automatic Features:**
- Permission checking and requesting
- Camera/Gallery opening
- Image compression
- Error handling
- Platform-specific handling (iOS/Android/Windows)

---

## Appendix: Full File Checklist

**New Files to Create:**
- `lib/services/image_picker_service.dart` - Service
- `lib/view/custom_widgets/image_picker_bottom_sheet.dart` - UI

**Files to Modify:**
- `ios/Runner/Info.plist` - Add 4 keys
- `android/app/src/main/AndroidManifest.xml` - Add permissions

**Files to Update in Your Screens:**
- Add `import` statements
- Add `_showImagePicker()` method
- Add image preview widget
- Add "Select Image" button with `_showImagePicker()` callback
