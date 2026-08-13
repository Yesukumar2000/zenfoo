import 'package:flutter/material.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class RTextFieldInputTheme {
  RTextFieldInputTheme._();

  // Light theme for TextField Input Decoration
  static InputDecorationTheme lightInputDecorationTheme =
      const InputDecorationTheme(
    filled: true,
    fillColor: Colors.transparent,
    hintStyle: TextStyle(color: Colors.grey),
    labelStyle: TextStyle(color: Colors.black),
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    contentPadding: EdgeInsets.zero,
  );

  // Dark theme for TextField Input Decoration
  static InputDecorationTheme darkInputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: Colors.transparent,
    hintStyle: TextStyle(color: Colors.grey.shade400),
    labelStyle: const TextStyle(color: Colors.white),
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    contentPadding: EdgeInsets.zero,
  );
}
