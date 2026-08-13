import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/controllers/face_scan_controller.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';

class FaceScanScreen extends StatefulWidget {
  final bool useBackCam;
  final int requiredBlinks;

  const FaceScanScreen({
    super.key,
    this.useBackCam = false,
    this.requiredBlinks = 1,
  });

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen>
    with TickerProviderStateMixin {
  late FaceScanController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FaceScanController(
      vsync: this,
      useBackCamera: widget.useBackCam,
      requiredBlinks: widget.requiredBlinks,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<FaceScanController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: colorScheme.background,
            body: SafeArea(
              top: false,
              child: Stack(
                children: [
                  Column(
                    children: [
                      AppHeader(
                        label: 'Face Verification',
                        title: 'Liveness detection enabled',
                        showBackButton: true,
                        trailing: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            controller.switchCamera();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.border,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.flip_camera_ios_rounded,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                          child: _buildCameraSection(controller, colorScheme)),
                      _buildStatusSection(controller, colorScheme),
                      _buildActionButtons(controller, context, colorScheme),
                      const SizedBox(height: 16),
                    ],
                  ),
                  if (controller.isLoading)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
      FaceScanController controller, BuildContext context, colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.border,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_rounded,
                color: colorScheme.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Face Verification',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Liveness detection enabled',
                  style: GoogleFonts.inter(
                    color: colorScheme.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              controller.switchCamera();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.border,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.flip_camera_ios_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: GoogleFonts.inter(
                    color: colorScheme.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSection(FaceScanController controller, colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 276,
                height: 276,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.border, width: 11),
                ),
              ),
              SizedBox(
                width: 298,
                height: 298,
                child: CustomPaint(
                  painter: LivenessProgressRingPainter(
                    progress: controller.isComplete
                        ? 1.0
                        : controller.isScanning
                            ? controller.progressAnimation.value
                            : controller.livenessProgress,
                    strokeWidth: 11.0,
                    color: _getProgressColor(controller, colorScheme),
                  ),
                ),
              ),
              Container(
                width: 242,
                height: 242,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                clipBehavior: Clip.antiAlias,
                child: controller.capturedImage != null
                    ? Image.file(
                        controller.capturedImage!,
                        fit: BoxFit.cover,
                      )
                    : controller.isCameraReady
                        ? ClipOval(
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: OverflowBox(
                                alignment: Alignment.center,
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: 242,
                                    height: 242 /
                                        controller.cameraController!.value
                                            .aspectRatio,
                                    child: CameraPreview(
                                      controller.cameraController!,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: colorScheme.surface,
                            child: Icon(
                              Icons.camera_alt_outlined,
                              color: colorScheme.textSecondary,
                              size: 60,
                            ),
                          ),
              ),
              if (controller.isCameraReady && !controller.isComplete)
                Container(
                  width: 242,
                  height: 242,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 160,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(80),
                      ),
                    ),
                  ),
                ),
              if (controller.currentStage ==
                      LivenessCheckStage.waitingForBlink ||
                  controller.currentStage == LivenessCheckStage.blinkDetected)
                Positioned(
                  top: 60,
                  child: _buildBlinkIndicator(controller, colorScheme),
                ),
            ],
          ),
          const SizedBox(height: 40),
          Column(
            children: [
              Text(
                controller.isComplete
                    ? '100%'
                    : '${(controller.livenessProgress * 100).round()}%',
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  height: 0.45,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getStageName(controller.currentStage),
                style: GoogleFonts.inter(
                  color: _getProgressColor(controller, colorScheme),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlinkIndicator(FaceScanController controller, colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility_outlined,
            color: colorScheme.background,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Blink your eyes',
            style: GoogleFonts.inter(
              color: colorScheme.background,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(FaceScanController controller, colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
      child: Column(
        children: [
          if (controller.isComplete) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.background,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.check,
                    color: colorScheme.background,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Liveness Verified',
                  style: GoogleFonts.inter(
                    color: colorScheme.success,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Text(
            controller.statusTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.statusDescription,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      FaceScanController controller, BuildContext context, colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 29.0),
      child: controller.isComplete
          ? Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        controller.retakePhoto();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.textPrimary,
                        side: BorderSide(
                          color: colorScheme.border,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Retake',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        controller.handleContinue(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Continue',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _getButtonText(controller),
                  style: GoogleFonts.inter(
                    color: colorScheme.background,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
    );
  }

  Color _getProgressColor(FaceScanController controller, colorScheme) {
    if (controller.isComplete) {
      return colorScheme.success;
    }

    switch (controller.currentStage) {
      case LivenessCheckStage.waitingForFace:
        return colorScheme.textSecondary;
      case LivenessCheckStage.faceDetected:
        return colorScheme.primary;
      case LivenessCheckStage.waitingForBlink:
      case LivenessCheckStage.blinkDetected:
        return const Color(0xFF64B5F6);
      case LivenessCheckStage.completed:
        return colorScheme.success;
    }
  }

  String _getStageName(LivenessCheckStage stage) {
    switch (stage) {
      case LivenessCheckStage.waitingForFace:
        return 'Looking for face...';
      case LivenessCheckStage.faceDetected:
        return 'Face detected';
      case LivenessCheckStage.waitingForBlink:
        return 'Waiting for blink...';
      case LivenessCheckStage.blinkDetected:
        return 'Blink detected!';
      case LivenessCheckStage.completed:
        return 'Verification complete';
    }
  }

  String _getButtonText(FaceScanController controller) {
    switch (controller.currentStage) {
      case LivenessCheckStage.waitingForFace:
        return 'Position Your Face';
      case LivenessCheckStage.faceDetected:
        return 'Face Detected';
      case LivenessCheckStage.waitingForBlink:
        return 'Please Blink';
      case LivenessCheckStage.blinkDetected:
        return 'Processing...';
      case LivenessCheckStage.completed:
        return 'Capturing Image...';
    }
  }
}

class LivenessProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;

  LivenessProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (progress < 1.0) {
      final pulseRadius =
          radius + (math.sin(DateTime.now().millisecondsSinceEpoch / 200) * 2);
      final pulsePaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(center, pulseRadius, pulsePaint);
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
