import 'package:flutter/material.dart';

class CustomInkWell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  final double borderRadius;
  final double? height;
  final double? width;
  final Color backgroundColor;
  final Color? splashColor;
  final Color? highlightColor;
  final bool isLoading;
  final double elevation;
  final EdgeInsetsGeometry? padding;
  final Border? border;
  final EdgeInsetsGeometry? margin;
  final BoxDecoration? decoration;

  const CustomInkWell(
      {super.key,
      required this.child,
      required this.onTap,
      this.borderRadius = 12,
      this.backgroundColor = Colors.transparent,
      this.isLoading = false,
      this.elevation = 0,
      this.padding,
      this.border,
      this.splashColor,
      this.highlightColor,
      this.margin,
      this.decoration,
      this.height,
      this.width});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      elevation: elevation,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        // ignore: deprecated_member_use
        splashColor: splashColor ?? Colors.black.withOpacity(0.15),
        // ignore: deprecated_member_use
        highlightColor: highlightColor ?? Colors.black.withOpacity(0.05),

        child: Ink(
          width: width,
          height: height,
          padding: padding ?? EdgeInsets.zero,
          decoration: decoration ??
              BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: border,
              ),
          child: child,
        ),
      ),
    );
  }
}
