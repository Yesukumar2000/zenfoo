import 'package:flutter/material.dart';

/// Universal wrapper widget that dismisses keyboard and unfocuses text fields on outside click
///
/// Usage:
/// ```dart
/// KeyboardDismissibleWrapper(
///   child: YourWidget(),
/// )
/// ```
class KeyboardDismissibleWrapper extends StatelessWidget {
  final Widget child;
  final bool dismissOnTap;

  const KeyboardDismissibleWrapper({
    Key? key,
    required this.child,
    this.dismissOnTap = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: dismissOnTap ? () => _dismissKeyboard(context) : null,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }

  /// Dismiss keyboard and unfocus all text fields
  static void dismissKeyboard(BuildContext context) {
    _dismissKeyboard(context);
  }

  static void _dismissKeyboard(BuildContext context) {
    // Unfocus all text fields
    FocusScope.of(context).unfocus();

    // Additional way to dismiss keyboard
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
