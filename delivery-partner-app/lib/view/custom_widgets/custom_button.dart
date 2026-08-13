import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zenfoo_partner/utils/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String? text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double borderRadius;
  final Color backgroundColor;
  final Color? borderColor;
  final double? elevation;
  final Color? textColor;
  final double? borderWidth;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final EdgeInsetsGeometry? padding;
  final double fontSize;
  final FontWeight fontWeight;
  final Widget? child;

  const CustomButton({
    super.key,
    this.text,
    this.onPressed,
    this.isLoading = false,
    this.borderRadius = 16.0,
    this.backgroundColor = AppColors.primaryColor,
    this.elevation,
    this.borderColor,
    this.borderWidth,
    this.textColor,
    this.width,
    this.height,
    this.boxShadow,
    this.prefixIcon,
    this.suffixIcon,
    this.padding,
    this.fontSize = 17,
    this.fontWeight = FontWeight.w700,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Get current MediaQuery and create a safe copy with valid text scale factor
    final mediaQuery = MediaQuery.of(context);
    final safeMediaQuery = mediaQuery.copyWith(
      // Clamp text scale factor to prevent invalid values on some devices (Vivo, Oppo)
      textScaler: TextScaler.linear(
        mediaQuery.textScaler.scale(1.0).clamp(0.5, 2.0),
      ),
    );

    return MediaQuery(
      data: safeMediaQuery,
      child: Container(
        height: height ?? 56,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: boxShadow ??
              [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
          backgroundColor: isLoading
              ? backgroundColor.withValues(alpha: 0.7)
              : backgroundColor,
          foregroundColor: textColor ?? Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: borderColor != null
                ? BorderSide(
                    color: borderColor!,
                    width: borderWidth ?? 1.5,
                  )
                : BorderSide.none,
          ),
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        child: child ??
            (isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (prefixIcon != null) ...[
                        prefixIcon!,
                        const SizedBox(width: 12),
                      ],
                      Flexible(
                        child: Text(
                          text ?? '',
                          softWrap: true,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: textColor ?? Colors.white,
                            fontSize: fontSize,
                            letterSpacing: -0.3,
                            fontWeight: fontWeight,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (suffixIcon != null) ...[
                        const SizedBox(width: 12),
                        suffixIcon!,
                      ],
                    ],
                  )),
        ),
      ),
    );
  }
}
