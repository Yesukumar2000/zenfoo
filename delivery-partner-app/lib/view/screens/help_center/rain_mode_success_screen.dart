import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';

class RainModeSuccessScreen extends StatefulWidget {
  const RainModeSuccessScreen({super.key});

  @override
  State<RainModeSuccessScreen> createState() => _RainModeSuccessScreenState();
}

class _RainModeSuccessScreenState extends State<RainModeSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<RainDrop> _raindrops = [];
  final Random _random = Random();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    // Initialize raindrops
    for (int i = 0; i < 100; i++) {
      _raindrops.add(RainDrop(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        length: _random.nextDouble() * 20 + 10,
        speed: _random.nextDouble() * 10 + 10,
      ));
    }

    _controller.addListener(() {
      setState(() {
        for (var drop in _raindrops) {
          drop.y += drop.speed * 0.01;
          if (drop.y > 1.0) {
            drop.y = -0.1;
            drop.x = _random.nextDouble();
          }
        }
      });
    });

    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black, // Dark background for rain effect
      body: Stack(
        children: [
          // Rain Animation
          CustomPaint(
            painter: RainPainter(_raindrops, colorScheme.primary),
            child: Container(),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.thunderstorm,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Rain Mode Activated',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rain mode enabled for your zone',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RainDrop {
  double x;
  double y;
  double length;
  double speed;

  RainDrop({
    required this.x,
    required this.y,
    required this.length,
    required this.speed,
  });
}

class RainPainter extends CustomPainter {
  final List<RainDrop> raindrops;
  final Color color;

  RainPainter(this.raindrops, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    for (var drop in raindrops) {
      final x = drop.x * size.width;
      final y = drop.y * size.height;
      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + drop.length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
