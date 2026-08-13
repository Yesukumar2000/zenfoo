import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class RequestSent extends StatefulWidget {
  final bool popTwice;
  const RequestSent({super.key, this.popTwice = false});

  @override
  State<RequestSent> createState() => _RequestSentState();
}

class _RequestSentState extends State<RequestSent> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        if (widget.popTwice) {
          Navigator.pop(context);
          Navigator.pop(context); // pop previous screen (Joining Bonus)
        } else {
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/booking_successful_check.png',
            width: 90,
            height: 90,
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Request Sent',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'We will review within 24 Hours',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
