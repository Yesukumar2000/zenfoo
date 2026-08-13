import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';

/// Base shimmer skeleton widget that can be reused for any skeleton loading effect
class ShimmerSkeleton extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerSkeleton({
    super.key,
    required this.child,
    this.duration =
        const Duration(milliseconds: 800), // Faster animation = feels snappier
  });

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          return _ShimmerProvider(
            animation: _animation,
            child: RepaintBoundary(
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Provider to pass animation value down the widget tree
class _ShimmerProvider extends InheritedWidget {
  final Animation<double> animation;

  const _ShimmerProvider({
    required this.animation,
    required super.child,
  });

  static Animation<double> of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ShimmerProvider>()!
        .animation;
  }

  @override
  bool updateShouldNotify(_ShimmerProvider oldWidget) =>
      animation != oldWidget.animation;
}

/// Shimmer base widget - creates a shimmer gradient effect
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsets padding;
  final EdgeInsets margin;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final animation = _ShimmerProvider.of(context);

    final animValue = animation.value;
    // Tighter gradient for faster shimmer effect (0.2 instead of 0.3)
    final stop1 = (animValue - 0.2).clamp(0.0, 1.0);
    final stop2 = animValue.clamp(0.0, 1.0);
    final stop3 = (animValue + 0.2).clamp(0.0, 1.0);

    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(4);

    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: effectiveBorderRadius,
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              colorScheme.surfaceVariant,
              colorScheme.surface.withValues(
                  alpha: 0.9), // Brighter middle for more visible shimmer
              colorScheme.surfaceVariant,
            ],
            stops: [stop1, stop2, stop3],
          ),
        ),
      ),
    );
  }
}

/// Transaction/Order card skeleton loader
class ShimmerTransactionCard extends StatelessWidget {
  final bool showBorder;
  final bool showDivider;

  const ShimmerTransactionCard({
    super.key,
    this.showBorder = true,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return ShimmerSkeleton(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: showBorder
              ? Border.all(color: colorScheme.border, width: 1)
              : null,
          boxShadow: colorScheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row (title + status badge)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(
                  width: 140,
                  height: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
                ShimmerBox(
                  width: 80,
                  height: 28,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (showDivider) Container(height: 1, color: colorScheme.border),
            if (showDivider) const SizedBox(height: 16),
            // First item row (icon + text)
            Row(
              children: [
                ShimmerBox(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                        width: 60,
                        height: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 6),
                      ShimmerBox(
                        width: 120,
                        height: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Second item row (icon + text)
            Row(
              children: [
                ShimmerBox(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                        width: 100,
                        height: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 6),
                      ShimmerBox(
                        width: 180,
                        height: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Delivery Confirmation Screen skeleton - matches exact UI structure
class ShimmerDeliveryConfirmation extends StatelessWidget {
  final bool isPickup;

  const ShimmerDeliveryConfirmation({
    super.key,
    this.isPickup = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return ShimmerSkeleton(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Order Information Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.cardBorder,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  ShimmerBox(
                    width: 120,
                    height: 18,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),
                  // Order ID and OTP row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(
                              width: 50,
                              height: 12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 10),
                            ShimmerBox(
                              width: 80,
                              height: 28,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: colorScheme.border,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(
                              width: 50,
                              height: 12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 10),
                            ShimmerBox(
                              width: 80,
                              height: 28,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isPickup) ...[
                    const SizedBox(height: 16),
                    Divider(color: colorScheme.border, height: 1),
                    const SizedBox(height: 16),
                    // Payment Method row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerBox(
                          width: 80,
                          height: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        ShimmerBox(
                          width: 70,
                          height: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Total Amount row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerBox(
                          width: 80,
                          height: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        ShimmerBox(
                          width: 70,
                          height: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // PIN entry section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(
                          width: 150,
                          height: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        ShimmerBox(
                          width: 200,
                          height: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 10),
                        // PIN input fields
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: List.generate(
                            4,
                            (index) => Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ShimmerBox(
                                width: 50,
                                height: 50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            /// Items Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.cardBorder,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerBox(
                        width: 100,
                        height: 18,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      ShimmerBox(
                        width: 20,
                        height: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Item count
                  ShimmerBox(
                    width: 60,
                    height: 18,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 16),
                  // Item rows
                  ...List.generate(
                    3,
                    (index) => Padding(
                      padding: EdgeInsets.only(
                        bottom: index < 2 ? 12 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          ShimmerBox(
                            width: 180,
                            height: 14,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          ShimmerBox(
                            width: 120,
                            height: 12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Bottom action button skeleton
class ShimmerButtonSkeleton extends StatelessWidget {
  const ShimmerButtonSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return ShimmerSkeleton(
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

/// Generic skeleton card with customizable rows
class ShimmerCard extends StatelessWidget {
  final double? width;
  final double? height;
  final List<ShimmerRow> rows;
  final EdgeInsets padding;
  final bool showBorder;

  const ShimmerCard({
    Key? key,
    this.width,
    this.height,
    required this.rows,
    this.padding = const EdgeInsets.all(16),
    this.showBorder = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return ShimmerSkeleton(
      child: Container(
        width: width ?? double.infinity,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: showBorder
              ? Border.all(color: colorScheme.border, width: 1)
              : null,
          boxShadow: colorScheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            rows.length,
            (index) {
              final row = rows[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < rows.length - 1 ? row.spacing : 0,
                ),
                child: row,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Represents a single row in a skeleton card
class ShimmerRow extends StatelessWidget {
  final List<ShimmerColumn> columns;
  final double spacing;
  final MainAxisAlignment mainAxisAlignment;

  const ShimmerRow({
    Key? key,
    required this.columns,
    this.spacing = 12,
    this.mainAxisAlignment = MainAxisAlignment.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        columns.length,
        (index) {
          final column = columns[index];
          final child = Expanded(
            flex: column.flex,
            child: column,
          );
          return index < columns.length - 1
              ? Padding(
                  padding: EdgeInsets.only(right: spacing),
                  child: child,
                )
              : child;
        },
      ),
    );
  }
}

/// Represents a single column in a row
class ShimmerColumn extends StatelessWidget {
  final List<ShimmerItem> items;
  final double spacing;
  final int flex;

  const ShimmerColumn({
    Key? key,
    required this.items,
    this.spacing = 6,
    this.flex = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        items.length,
        (index) {
          final item = items[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < items.length - 1 ? spacing : 0,
            ),
            child: item,
          );
        },
      ),
    );
  }
}

/// Individual shimmer item
class ShimmerItem extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerItem({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(4),
    );
  }
}
