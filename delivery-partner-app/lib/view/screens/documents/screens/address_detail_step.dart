
import 'package:flutter/material.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
class AddressDetailsStep extends StatelessWidget {
  const AddressDetailsStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("Enter your address details."),
          SizedBox(height: 20),
          TextField(decoration: InputDecoration(hintText: "Address")),
          SizedBox(height: 12),
          TextField(decoration: InputDecoration(hintText: "City")),
        ],
      ),
    );
  }
}
