import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppPageTransitions {
  // Slide Right → Left
  static CustomTransitionPage slideRightToLeft(Widget child) {
    return CustomTransitionPage(
      transitionDuration: const Duration(milliseconds: 700),
      child: child,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  // Slide Bottom → Top
  static CustomTransitionPage slideBottomToTop(
    Widget child, {
    Duration duration = const Duration(milliseconds: 700),
  }) {
    return CustomTransitionPage(
      transitionDuration: duration,
      child: child,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutBack));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  // Fade
  static CustomTransitionPage fade(Widget child) {
    return CustomTransitionPage(
      transitionDuration: const Duration(milliseconds: 700),
      child: child,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.98, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}


