import 'package:flutter/material.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';

class ConfirmationStep extends StatelessWidget {
  const ConfirmationStep({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Review & confirm your details",
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
