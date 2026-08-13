import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:zenfoo_partner/utils/app_images.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';

class DocumentUploadBox extends StatelessWidget {
  final String title;
  final String subTitle;
  final VoidCallback onTap;

  const DocumentUploadBox({
    super.key,
    required this.title,
    required this.subTitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DottedBorder(
      options: const RoundedRectDottedBorderOptions(
        radius: Radius.circular(14),
        dashPattern: [6, 6],
        strokeWidth: 1.2,
        color: Colors.grey,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFFF7F7F7),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                AppImages.uploadIcon,
                height: AppDimensions.getSize(26),
                width: AppDimensions.getSize(26),
              ),
              const SizedBox(height: 8),
              Text(title, style: textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                subTitle,
                style: textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
