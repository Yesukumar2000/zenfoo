import 'package:flutter/material.dart';

/// Helper class for creating smooth and consistent Hero animations
/// across the app, especially for product transitions.
class HeroAnimationHelper {
  /// Generates a unique hero tag for product images
  ///
  /// [productId] - The unique identifier for the product
  /// [suffix] - Optional suffix to differentiate multiple hero tags for the same product
  static String productImageTag(String productId, {String suffix = ''}) {
    return 'product_image_$productId$suffix';
  }

  /// Generates a unique hero tag for product names/titles
  ///
  /// [productId] - The unique identifier for the product
  static String productNameTag(String productId) {
    return 'product_name_$productId';
  }

  /// Generates a unique hero tag for product prices
  ///
  /// [productId] - The unique identifier for the product
  static String productPriceTag(String productId) {
    return 'product_price_$productId';
  }

  /// Generates a unique hero tag for product ratings
  ///
  /// [productId] - The unique identifier for the product
  static String productRatingTag(String productId) {
    return 'product_rating_$productId';
  }

  /// Creates a Hero widget with a Material wrapper for smooth text transitions
  ///
  /// [tag] - Unique identifier for the hero animation
  /// [child] - The widget to animate
  static Widget createMaterialHero({
    required String tag,
    required Widget child,
  }) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: true,
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }

  /// Creates a Hero widget with custom flight shuttle builder for smooth transitions
  ///
  /// [tag] - Unique identifier for the hero animation
  /// [child] - The widget to animate
  /// [transitionOnUserGestures] - Whether to animate during user gestures (default: true)
  static Widget createCustomHero({
    required String tag,
    required Widget child,
    bool transitionOnUserGestures = true,
  }) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: transitionOnUserGestures,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        return DefaultTextStyle(
          style: DefaultTextStyle.of(toHeroContext).style,
          child: toHeroContext.widget,
        );
      },
      child: child,
    );
  }

  /// Creates a Hero widget specifically for images with smooth scaling transition
  ///
  /// [tag] - Unique identifier for the hero animation
  /// [imageWidget] - The image widget to animate
  static Widget createImageHero({
    required String tag,
    required Widget imageWidget,
  }) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: true,
      child: imageWidget,
    );
  }

  /// Custom page route with hero animation support and custom transitions
  static PageRoute createHeroPageRoute({
    required Widget page,
    Duration transitionDuration = const Duration(milliseconds: 350),
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: transitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Curved animation for smooth acceleration and deceleration
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
          reverseCurve: Curves.easeInOutCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );
      },
    );
  }
}

/// Custom Hero Controller for fine-tuning hero animations
class CustomHeroController extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      // Custom logic when pushing a new route with heroes
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is PageRoute) {
      // Custom logic when popping a route with heroes
    }
  }
}

/// Extension methods for easier Hero widget creation
extension HeroWidgetExtension on Widget {
  /// Wraps the widget with a Hero widget
  Widget withHero(String tag) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: true,
      child: this,
    );
  }

  /// Wraps the widget with a Hero widget and Material for text transitions
  Widget withMaterialHero(String tag) {
    return Hero(
      tag: tag,
      child: Material(
        color: Colors.transparent,
        child: this,
      ),
    );
  }
}
