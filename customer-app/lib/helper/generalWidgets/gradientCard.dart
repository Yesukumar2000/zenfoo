import 'package:flutter/material.dart';

/// A rounded card whose background *and* 1px border are painted with
/// gradients.
///
/// [BoxDecoration] can only stroke a border with a solid colour, so the
/// gradient outline is faked the usual way: an outer box filled with the
/// border gradient, inset by [borderWidth], holding the real surface.
class GradientBorderCard extends StatelessWidget {
  final Widget child;

  /// Fill of the inner surface. Falls back to [color] when null.
  final Gradient? gradient;

  /// Solid fill, used only when [gradient] is null.
  final Color? color;

  /// Paint for the outline. A plain [Border] is used when null.
  final Gradient? borderGradient;
  final Color? borderColor;

  final double borderWidth;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? shadows;
  final double? width;
  final double? height;

  /// When set the whole card becomes tappable with a clipped ripple.
  final VoidCallback? onTap;
  final Color? splashColor;

  const GradientBorderCard({
    Key? key,
    required this.child,
    this.gradient,
    this.color,
    this.borderGradient,
    this.borderColor,
    this.borderWidth = 1,
    this.borderRadius = 16,
    this.padding = EdgeInsets.zero,
    this.margin,
    this.shadows,
    this.width,
    this.height,
    this.onTap,
    this.splashColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double innerRadius =
        (borderRadius - borderWidth).clamp(0, borderRadius).toDouble();

    Widget surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? color : null,
        borderRadius: BorderRadius.circular(innerRadius),
      ),
      child: child,
    );

    if (onTap != null) {
      surface = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(innerRadius),
          splashColor: splashColor,
          child: surface,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        gradient: borderGradient,
        color: borderGradient == null ? borderColor : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: surface,
      ),
    );
  }
}

/// The small rounded square that sits in front of a settings row label.
class GradientIconTile extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final double padding;
  final double borderRadius;
  final Color? borderColor;

  const GradientIconTile({
    Key? key,
    required this.child,
    required this.gradient,
    this.padding = 8,
    this.borderRadius = 10,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 1),
      ),
      child: child,
    );
  }
}

/// Short vertical bar used to lead a section heading.
class GradientAccentBar extends StatelessWidget {
  final Gradient gradient;
  final double width;
  final double height;

  const GradientAccentBar({
    Key? key,
    required this.gradient,
    this.width = 4,
    this.height = 18,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
