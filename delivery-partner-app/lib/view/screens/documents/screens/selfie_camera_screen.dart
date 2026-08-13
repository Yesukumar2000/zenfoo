import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';

class SelfieCameraScreen extends StatefulWidget {
  const SelfieCameraScreen({super.key});

  @override
  State<SelfieCameraScreen> createState() => _SelfieCameraScreenState();
}

class _SelfieCameraScreenState extends State<SelfieCameraScreen> {
  CameraController? _controller;
  FaceDetector? _faceDetector;
  bool _isDetecting = false;
  String _statusMessage = 'Initializing camera...';
  Color _statusColor = Colors.orange;
  bool _canCapture = false;
  int _faceCount = 0;
  double? _brightness;

  final FaceDetectorOptions _faceDetectorOptions = FaceDetectorOptions(
    enableContours: true,
    enableClassification: true,
    enableTracking: true,
    performanceMode: FaceDetectorMode.accurate,
  );

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _faceDetector = FaceDetector(options: _faceDetectorOptions);
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      await _controller!.startImageStream(_processCameraImage);

      if (mounted) {
        setState(() {
          _statusMessage = 'Position your face in the frame';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Camera error: $e';
        _statusColor = Colors.red;
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final faces = await _faceDetector!.processImage(inputImage);
      _analyzeFaces(faces, image);
    } catch (e) {
      debugPrint('Face detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      // Determine rotation based on device orientation and camera lens direction
      final sensorOrientation = _controller?.description.sensorOrientation ?? 0;
      InputImageRotation? rotation;

      if (Platform.isIOS) {
        rotation = InputImageRotation.rotation0deg;
      } else if (Platform.isAndroid) {
        final rotationCompensation = sensorOrientation ~/ 90;
        final rotations = [
          InputImageRotation.rotation0deg,
          InputImageRotation.rotation90deg,
          InputImageRotation.rotation180deg,
          InputImageRotation.rotation270deg,
        ];
        rotation = rotations[rotationCompensation % 4];
      }

      if (rotation == null) {
        debugPrint('Rotation is null');
        return null;
      }

      // Determine image format
      InputImageFormat? format;
      if (Platform.isAndroid) {
        format = InputImageFormat.nv21;
      } else if (Platform.isIOS) {
        format = InputImageFormat.bgra8888;
      }

      if (format == null) {
        debugPrint('Image format is null');
        return null;
      }

      // Concatenate planes for Android (NV21 format)
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImageData = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }

  void _analyzeFaces(List<Face> faces, CameraImage image) {
    _faceCount = faces.length;

    // Calculate brightness (simple average of Y plane)
    double brightness = 0;
    if (image.planes.isNotEmpty) {
      final yPlane = image.planes[0].bytes;
      int sum = 0;
      for (int i = 0; i < yPlane.length; i += 100) {
        // Sample every 100th pixel
        sum += yPlane[i];
      }
      brightness = sum / (yPlane.length / 100);
    }
    _brightness = brightness;

    // Validate selfie quality
    if (faces.isEmpty) {
      _updateStatus('No face detected', Colors.orange, false);
    } else if (faces.length > 1) {
      _updateStatus('Multiple faces detected. Only one person allowed',
          Colors.red, false);
    } else {
      final face = faces.first;

      // Check if face is too small or too far
      final faceArea = face.boundingBox.width * face.boundingBox.height;
      final imageArea = image.width * image.height;
      final faceRatio = faceArea / imageArea;

      if (faceRatio < 0.08) {
        _updateStatus('Move closer to the camera', Colors.orange, false);
      } else if (faceRatio > 0.5) {
        _updateStatus('Move back from the camera', Colors.orange, false);
      } else if (brightness < 80) {
        _updateStatus(
            'Poor lighting. Move to a brighter area', Colors.red, false);
      } else if (brightness > 220) {
        _updateStatus('Too bright. Avoid direct light', Colors.red, false);
      } else {
        // Check face orientation
        final headEulerAngleY = face.headEulerAngleY;
        final headEulerAngleZ = face.headEulerAngleZ;

        if (headEulerAngleY != null &&
            (headEulerAngleY > 15 || headEulerAngleY < -15)) {
          _updateStatus('Look straight at the camera', Colors.orange, false);
        } else if (headEulerAngleZ != null &&
            (headEulerAngleZ > 15 || headEulerAngleZ < -15)) {
          _updateStatus('Keep your head straight', Colors.orange, false);
        } else {
          _updateStatus('Perfect! Tap to capture', Colors.green, true);
        }
      }
    }
  }

  void _updateStatus(String message, Color color, bool canCapture) {
    if (mounted && (_statusMessage != message || _canCapture != canCapture)) {
      setState(() {
        _statusMessage = message;
        _statusColor = color;
        _canCapture = canCapture;
      });
    }
  }

  Future<void> _captureImage() async {
    if (!_canCapture ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    try {
      await _controller!.stopImageStream();
      final XFile image = await _controller!.takePicture();

      if (mounted) {
        Navigator.pop(context, image.path);
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      _updateStatus('Capture failed. Try again', Colors.red, false);
      await _controller!.startImageStream(_processCameraImage);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          Center(
            child: CameraPreview(_controller!),
          ),

          // Face detection overlay
          CustomPaint(
            painter: FaceOverlayPainter(
              faceCount: _faceCount,
              canCapture: _canCapture,
              colorScheme: colorScheme,
            ),
          ),

          // Top bar with status
          SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusMessage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance for close button
                    ],
                  ),
                ),

                const Spacer(),

                // Tips section
                if (!_canCapture)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tips for a good selfie:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTip('✓ Face the camera directly'),
                        _buildTip('✓ Ensure good lighting'),
                        _buildTip('✓ No other people in frame'),
                        _buildTip('✓ Plain background preferred'),
                        if (_brightness != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Brightness: ${_brightness!.toInt()}/255',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Capture button
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: GestureDetector(
                    onTap: _canCapture ? _captureImage : null,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        color: _canCapture ? colorScheme.primary : Colors.grey,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
        ),
      ),
    );
  }
}

class FaceOverlayPainter extends CustomPainter {
  final int faceCount;
  final bool canCapture;
  final dynamic colorScheme;

  FaceOverlayPainter({
    required this.faceCount,
    required this.canCapture,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw oval guide
    final center = Offset(size.width / 2, size.height / 2);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.7,
      height: size.height * 0.5,
    );

    paint.color = canCapture
        ? Colors.green.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.5);

    canvas.drawOval(ovalRect, paint);

    // Draw corner guides
    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = canCapture ? Colors.green : Colors.white;

    // Top-left
    canvas.drawLine(
      Offset(ovalRect.left, ovalRect.top + cornerLength),
      Offset(ovalRect.left, ovalRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(ovalRect.left, ovalRect.top),
      Offset(ovalRect.left + cornerLength, ovalRect.top),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(ovalRect.right - cornerLength, ovalRect.top),
      Offset(ovalRect.right, ovalRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(ovalRect.right, ovalRect.top),
      Offset(ovalRect.right, ovalRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(ovalRect.left, ovalRect.bottom - cornerLength),
      Offset(ovalRect.left, ovalRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(ovalRect.left, ovalRect.bottom),
      Offset(ovalRect.left + cornerLength, ovalRect.bottom),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(ovalRect.right - cornerLength, ovalRect.bottom),
      Offset(ovalRect.right, ovalRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(ovalRect.right, ovalRect.bottom - cornerLength),
      Offset(ovalRect.right, ovalRect.bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(FaceOverlayPainter oldDelegate) {
    return oldDelegate.faceCount != faceCount ||
        oldDelegate.canCapture != canCapture;
  }
}
