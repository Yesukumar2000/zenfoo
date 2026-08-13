import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/utils/app_colors.dart';

import '../../theme/theme_provider.dart';

class CustomImageIcon extends StatelessWidget {
  const CustomImageIcon(
      {super.key, required this.imagePath, this.size, this.padding});

  final String imagePath;
  final double? size;
  final double? padding;
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return Container(
        padding: EdgeInsets.all(padding ?? 4),
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          shape: BoxShape.circle,
        ),
        child: ImageIcon(
          ResizeImage(
            AssetImage(imagePath),
            width: ((size ?? 25) * 3).toInt(),
            height: ((size ?? 25) * 3).toInt(),
          ),
          size: size ?? 25,
        ));
  }
}
