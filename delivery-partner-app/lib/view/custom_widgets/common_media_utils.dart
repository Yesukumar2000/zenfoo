import 'dart:io';
import 'package:file_picker/file_picker.dart';

class MediaPickerUtils {
  static Future<List<File>> pickMedia({bool allowMultiple = true}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'mp4',
        'mov',
        'avi',
        'mkv',
      ],
    );

    if (result == null) return [];

    return result.files
        .where((f) => f.path != null)
        .map((f) => File(f.path!))
        .toList();
  }

  static bool isVideo(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith(".mp4") ||
        ext.endsWith(".mov") ||
        ext.endsWith(".avi") ||
        ext.endsWith(".mkv");
  }
}
