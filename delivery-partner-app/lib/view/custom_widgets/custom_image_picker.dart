import 'dart:io';
import 'package:flutter/material.dart';

class CustomImagePicker extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onPick;
  final double height;
  final double borderRadius;
  final Color backgroundColor;
  final String label;
  final String subLabel;
  final IconData icon;

  const CustomImagePicker({
    super.key,
    required this.imageFile,
    required this.onPick,
    this.height = 150,
    this.borderRadius = 16,
    this.backgroundColor = const Color(0xffF2F2F2),
    this.label = "Upload your image",
    this.subLabel = "PNG, JPG",
    this.icon = Icons.upload,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: Colors.black.withOpacity(0.15),
        highlightColor: Colors.black.withOpacity(0.05),
        child: Ink(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: imageFile == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 28, color: Colors.black87),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      subLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: Image.file(
                    imageFile!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
        ),
      ),
    );
  }
}
