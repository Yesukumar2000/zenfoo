import 'package:flutter/material.dart';

class WeatherAnimationWidget extends StatelessWidget {
  final bool isRaining;
  const WeatherAnimationWidget({Key? key, required this.isRaining})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isRaining) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/icons/rains.gif',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
