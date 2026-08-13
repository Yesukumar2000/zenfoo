import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/weather_provider.dart';
import 'package:zenfoo_partner/utils/app_images.dart';

/// Rain indicator shown in the home header, mirroring the customer app.
/// Renders nothing unless it is actually raining at the driver's location.
class WeatherAnimationWidget extends StatelessWidget {
  const WeatherAnimationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isRaining = context.watch<WeatherProvider>().isRaining;

    if (!isRaining) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.asset(
          AppImages.rains,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
