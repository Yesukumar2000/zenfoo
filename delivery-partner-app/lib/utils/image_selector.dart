import 'package:flutter/material.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:image_picker/image_picker.dart';

Future<String?> showImageSelector(
  BuildContext context,
) async {
  String? imagePath;
  await showDialog(
    context: context,
    builder: (context) {
      return ImagePickerDialog(
        onCameraPressed: () async {
          imagePath = await getImage(ImageSource.camera, context, () {});
          // ignore: use_build_context_synchronously
          // Navigator.pop(context);
        },
        onGalleryPressed: () async {
          imagePath = await getImage(ImageSource.gallery, context, () {});
          // ignore: use_build_context_synchronously
          // Navigator.pop(context);
          // Handle gallery selection
        },
      );
    },
  );
  print('returned image $imagePath');
  return imagePath;
}

class ImagePickerDialog extends StatelessWidget {
  final void Function() onCameraPressed;
  final void Function() onGalleryPressed;

  ImagePickerDialog(
      {required this.onCameraPressed, required this.onGalleryPressed});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 8.0, // Adjust the elevation as needed
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16.0), // Adjust the border radius as needed
      ),
      backgroundColor: Colors.white, // Change the background color as needed
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(16.0),
            onTap: onCameraPressed,
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.only()),
              child: const Padding(
                padding: EdgeInsets.only(top: 15, left: 30, bottom: 15),
                child: Row(
                  children: [
                    Icon(Icons.photo_camera),
                    SizedBox(
                      width: 20,
                    ),
                    Text('Take a Photo'),
                  ],
                ),
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(16.0),
            onTap: onGalleryPressed,
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.only()),
              child: const Padding(
                padding: EdgeInsets.only(top: 15, left: 30, bottom: 15),
                child: Row(
                  children: [
                    Icon(Icons.photo),
                    SizedBox(
                      width: 20,
                    ),
                    Text('Choose from Gallery'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final picker = ImagePicker();
Future<String?> getImage(
    ImageSource imageSource, BuildContext context, Function() function) async {
  final pickedFile = await picker.pickImage(source: imageSource);
  XFile? xfilePick = pickedFile;
  if (xfilePick != null) {
    Navigator.pop(context);
    return pickedFile!.path;
  } else {
    ScaffoldMessenger.of(context).showSnackBar(// is this context <<<
        const SnackBar(content: Text('Nothing is selected')));
  }
  return null;
}
