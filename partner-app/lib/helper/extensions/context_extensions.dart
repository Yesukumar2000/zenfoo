import 'package:flutter/material.dart';

/// Extension methods on BuildContext for keyboard and focus management
extension ContextExtensions on BuildContext {
  /// Dismiss keyboard and unfocus all text fields
  void dismissKeyboard() {
    FocusScope.of(this).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// Check if keyboard is currently visible
  bool get isKeyboardVisible {
    return MediaQuery.of(this).viewInsets.bottom > 0;
  }

  /// Get keyboard height
  double get keyboardHeight {
    return MediaQuery.of(this).viewInsets.bottom;
  }
}
