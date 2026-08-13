import 'package:flutter/material.dart';

/// Premium custom page route with smooth transitions and Hero support
class PremiumPageRoute<T> extends PageRoute<T> {
  final Widget page;
  final RouteTransitionsBuilder? customTransition;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;
  final Curve curve;
  final Curve reverseCurve;
  final bool maintainState;
  final bool opaque;
  final bool barrierDismissible;
  final Color? barrierColor;
  final String? barrierLabel;

  PremiumPageRoute({
    required this.page,
    this.customTransition,
    this.transitionDuration = const Duration(milliseconds: 400),
    this.reverseTransitionDuration = const Duration(milliseconds: 350),
    this.curve = Curves.easeInOutCubic,
    this.reverseCurve = Curves.easeInOutCubic,
    this.maintainState = true,
    this.opaque = true,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    RouteSettings? settings,
  }) : super(settings: settings);


  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return page;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (customTransition != null) {
      return customTransition!(context, animation, secondaryAnimation, child);
    }

    // Default fade + scale transition
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: curve,
        reverseCurve: reverseCurve,
      ),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.95,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: curve,
            reverseCurve: reverseCurve,
          ),
        ),
        child: child,
      ),
    );
  }
}




/// Collection of premium transitions
class PremiumTransitions {
  /// Smooth fade with scale (default)
  static RouteTransitionsBuilder fadeScale = (
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      ),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          ),
        ),
        child: child,
      ),
    );
  };

  /// Slide from right (Material style)
  static RouteTransitionsBuilder slideFromRight = (
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    final tween = Tween(begin: begin, end: end);
    final offsetAnimation = animation.drive(
      tween.chain(CurveTween(curve: Curves.easeInOutCubic)),
    );

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  };

  /// Slide from bottom (Modal style)
  static RouteTransitionsBuilder slideFromBottom = (
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    final tween = Tween(begin: begin, end: end);
    final offsetAnimation = animation.drive(
      tween.chain(CurveTween(curve: Curves.easeOutCubic)),
    );

    return SlideTransition(
      position: offsetAnimation,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  };

  /// Fade through (Material 3 style)
  static RouteTransitionsBuilder fadeThrough = (
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          ),
        ),
        child: child,
      ),
    );
  };

  /// Shared axis (Material 3 style)
  static RouteTransitionsBuilder sharedAxisVertical = (
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 0.05),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        ),
      ),
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(0.0, -0.05),
          ).animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInOutCubic,
            ),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
              secondaryAnimation,
            ),
            child: child,
          ),
        ),
      ),
    );
  };

  /// Scale with fade (Premium feel)
  static RouteTransitionsBuilder scaleCenter = (
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        ),
      ),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  };

  /// Rotation with fade (Unique)
  static RouteTransitionsBuilder rotateWithFade = (
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return RotationTransition(
      turns: Tween<double>(begin: 0.02, end: 0.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        ),
      ),
      child: FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: child,
        ),
      ),
    );
  };
}



/// Extension methods for easy navigation with custom transitions
extension NavigationExtensions on BuildContext {
  /// Navigate with premium transition
  Future<T?> navigateTo<T extends Object?>(
    Widget page, {
    RouteTransitionsBuilder? transition,
    Duration? duration,
    Curve? curve,
    bool replace = false,
  }) {
    final route = PremiumPageRoute<T>(
      page: page,
      customTransition: transition,
      transitionDuration: duration ?? const Duration(milliseconds: 400),
      curve: curve ?? Curves.easeInOutCubic,
    );

    if (replace) {
      return Navigator.of(this).pushReplacement(route);
    }
    return Navigator.of(this).push(route);
  }

  /// Navigate with fade scale transition
  Future<T?> navigateWithFadeScale<T extends Object?>(Widget page) {
    return navigateTo<T>(
      page,
      transition: PremiumTransitions.fadeScale,
    );
  }

  /// Navigate with slide from right
  Future<T?> navigateWithSlide<T extends Object?>(Widget page) {
    return navigateTo<T>(
      page,
      transition: PremiumTransitions.slideFromRight,
    );
  }

  /// Navigate with slide from bottom (modal style)
  Future<T?> navigateWithModalSlide<T extends Object?>(Widget page) {
    return navigateTo<T>(
      page,
      transition: PremiumTransitions.slideFromBottom,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  /// Navigate with fade through
  Future<T?> navigateWithFadeThrough<T extends Object?>(Widget page) {
    return navigateTo<T>(
      page,
      transition: PremiumTransitions.fadeThrough,
      duration: const Duration(milliseconds: 450),
    );
  }

  /// Navigate with shared axis
  Future<T?> navigateWithSharedAxis<T extends Object?>(Widget page) {
    return navigateTo<T>(
      page,
      transition: PremiumTransitions.sharedAxisVertical,
    );
  }

  /// Navigate with scale
  Future<T?> navigateWithScale<T extends Object?>(Widget page) {
    return navigateTo<T>(
      page,
      transition: PremiumTransitions.scaleCenter,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
    );
  }

  /// Navigate with rotation
  Future<T?> navigateWithRotation<T extends Object?>(Widget page) {
    return navigateTo<T>(
      page,
      transition: PremiumTransitions.rotateWithFade,
      duration: const Duration(milliseconds: 500),
    );
  }
}
