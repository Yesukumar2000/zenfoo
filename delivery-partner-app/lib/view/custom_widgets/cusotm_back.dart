import 'package:flutter/material.dart';
import 'package:zenfoo_partner/utils/app_colors.dart';

class CustomBack extends StatelessWidget {
  final VoidCallback? onTap;
  final double radius;
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final EdgeInsetsGeometry? padding;

  const CustomBack({
    super.key,
    this.onTap,
    this.radius = 22,
    this.backgroundColor = AppColors.white,
    this.iconColor = AppColors.black,
    this.icon = Icons.arrow_back,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        splashColor: Colors.black.withOpacity(0.1),
        highlightColor: Colors.black.withOpacity(0.05),
        onTap: onTap ?? () => Navigator.pop(context),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor,
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
