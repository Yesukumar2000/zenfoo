import 'package:flutter/material.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class CustomImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;

  CustomImage(
      {required this.imageUrl, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(child: Icon(Icons.error));
        },
      ),
    );
  }
}
