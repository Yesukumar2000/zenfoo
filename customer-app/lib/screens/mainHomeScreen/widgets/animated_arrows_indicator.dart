import 'package:flutter/material.dart';

class AnimatedArrowsIndicator extends StatefulWidget {
  final bool
      isUp; // true for pointing up (footer), false for pointing down (header)
  final double size;
  final Color color;

  const AnimatedArrowsIndicator({
    Key? key,
    required this.isUp,
    this.size = 24.0,
    this.color = const Color(0xFF9AC444),
  }) : super(key: key);

  @override
  State<AnimatedArrowsIndicator> createState() =>
      _AnimatedArrowsIndicatorState();
}

class _AnimatedArrowsIndicatorState extends State<AnimatedArrowsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        // For pointing UP: Arrow 1 is bottom, Arrow 3 is top.
        // We want animation to flow upwards: 1 -> 2 -> 3
        // So visually:
        //   ^  (3)
        //   ^  (2)
        //   ^  (1)
        // List generation is top-down (0, 1, 2).
        // If pointing UP, we want arrow at index 0 to be the top arrow (3).
        // Logic:
        // UP: Draw arrows pointing up. Order top-to-bottom: [Top, Middle, Bottom].
        // Animation flow UPWARDS: Bottom(2) -> Middle(1) -> Top(0).
        // DOWN: Draw arrows pointing down. Order top-to-bottom: [Top, Middle, Bottom].
        // Animation flow DOWNWARDS: Top(0) -> Middle(1) -> Bottom(2).

        final int animationIndex;
        if (widget.isUp) {
          // Visual: [Top(0), Middle(1), Bottom(2)]
          // Flow: Bottom -> Middle -> Top. (2 -> 1 -> 0)
          // So delay should be: 0 needs most delay? No, 2 starts first.
          // Wait, if 2 starts first, its phase is earliest?
          // Let's use staggered opacity.
          // Time 0: Bottom highlights. Time 0.3: Middle. Time 0.6: Top.
          // animationIndex 0 (Top) corresponds to later time.
          animationIndex = 2 - index;
        } else {
          // Visual: [Top(0), Middle(1), Bottom(2)]
          // Flow: Top -> Middle -> Bottom. (0 -> 1 -> 2)
          animationIndex = index;
        }

        // Create a staggered opacity animation
        // Total duration 1500ms.
        // Interval: 0.0-0.5, 0.25-0.75, 0.5-1.0
        final double begin = animationIndex * 0.2;
        final double end = begin + 0.4;

        final double arrowSize;
        if (widget.isUp) {
          // Pointing UP: Base is bottom (index 2), Tip is top (index 0)
          // Index 0: Smallest, Index 2: Largest
          arrowSize = widget.size * (0.6 + 0.2 * index);
        } else {
          // Pointing DOWN: Base is top (index 0), Tip is bottom (index 2)
          // Index 0: Largest, Index 2: Smallest
          arrowSize = widget.size * (1.0 - 0.2 * index);
        }

        return FadeTransition(
          opacity: TweenSequence<double>([
            TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.0), weight: 50),
            TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.2), weight: 50),
          ]).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(
                begin,
                (end > 1.0 ? 1.0 : end),
                curve: Curves.easeInOut,
              ),
            ),
          ),
          child: Icon(
            widget.isUp
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: arrowSize,
            color: widget.color,
          ),
        );
      }),
    );
  }
}
