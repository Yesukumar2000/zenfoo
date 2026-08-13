import 'package:flutter/material.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class RButtonTheme {
  RButtonTheme._();
  static ElevatedButtonThemeData lightElevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.all(16.0), // Add padding inside the button
      backgroundColor: Colors.black, // Background color for light mode
    ),
  );

  static ElevatedButtonThemeData darkElevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      // padding: EdgeInsets.all(16.0),
      shape: const CircleBorder(), // Add padding inside the button
      backgroundColor: const Color.fromARGB(
          255, 67, 160, 236), // Background color for light mode
    ),
  );
}
