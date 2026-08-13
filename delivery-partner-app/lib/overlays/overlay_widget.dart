import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// This is the overlay widget that will be displayed as a floating window
// @pragma("vm:entry-point")
// void overlayMain() {
//   runApp(const OverlayApp());
// }

class OverlayApp extends StatefulWidget {
  const OverlayApp({super.key});

  @override
  State<OverlayApp> createState() => _OverlayAppState();
}

class _OverlayAppState extends State<OverlayApp> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _listenForData();
    _listenForTaps();
  }

  void _listenForData() {
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map) {
        setState(() {
          _isOnline = event['isOnline'] ?? true;
        });
      }
    });
  }

  void _listenForTaps() {
    // Listen for notification taps
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event == 'openApp') {
        debugPrint('🎯 Notification tapped - opening app');
        _openApp();
      }
    });
  }

  Future<void> _openApp() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
      debugPrint('✅ Overlay closed, app should come to foreground');
    } catch (e) {
      debugPrint('❌ Error opening app: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: _buildOverlayContent(),
      ),
    );
  }

  Widget _buildOverlayContent() {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: GestureDetector(
          onTap: () {
            debugPrint('🎯 Overlay icon tapped - opening app');
            _openApp();
          },
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9AC444), Color(0xFF89B33D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Main icon
                const Center(
                  child: Icon(
                    Icons.delivery_dining,
                    color: Colors.white,
                    size: 34,
                  ),
                ),

                // Online status indicator
                if (_isOnline)
                  Positioned(
                    top: 3,
                    right: 3,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
