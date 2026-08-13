import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

enum LivenessCheckStage {
  waitingForFace,
  faceDetected,
  waitingForBlink,
  blinkDetected,
  completed
}

class FaceScanController extends ChangeNotifier {
  final bool useBackCamera;
  final int requiredBlinks;
  final TickerProvider vsync;

  FaceScanController({
    required this.vsync,
    this.useBackCamera = false,
    this.requiredBlinks = 1,
  }) {
    _initializeMLKit();
    _initializeAnimations();
    _initializeCamera();
  }

  // Camera
  CameraController? cameraController;
  late List<CameraDescription> cameras;
  int _currentCameraIndex = 0;
  bool _isCameraReady = false;
  bool get isCameraReady => _isCameraReady;

  // ML Kit
  late FaceDetector _faceDetector;
  bool _isDetecting = false;

  // Progress Animation
  late AnimationController _progressController;
  late Animation<double> progressAnimation;

  // Liveness Detection
  LivenessCheckStage _currentStage = LivenessCheckStage.waitingForFace;
  Timer? _detectionTimer;
  int _consecutiveBlinks = 0;
  bool _lastLeftEyeOpen = true;
  bool _lastRightEyeOpen = true;

  // State Management
  bool _isLoading = true;
  bool _isScanning = false;
  bool _isComplete = false;
  File? _capturedImage;

  // Status Messages
  String _statusTitle = 'Initializing Camera...';
  String _statusDescription = 'Please wait while we set up your camera';

  // Getters
  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  bool get isComplete => _isComplete;
  bool get canContinue => _isComplete;
  File? get capturedImage => _capturedImage;
  String get statusTitle => _statusTitle;
  String get statusDescription => _statusDescription;
  LivenessCheckStage get currentStage => _currentStage;

  void _initializeMLKit() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        enableLandmarks: true,
        enableTracking: true,
        minFaceSize: _getMinFaceSize(),
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  double _getMinFaceSize() {
    switch (requiredBlinks) {
      case 0:
        return 0.05;
      case 1:
        return 0.08;
      case 2:
        return 0.1;
      default:
        return 0.15;
    }
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: vsync,
    );

    progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        _updateStatus(
          'Camera Permission Required',
          'Please grant camera permission to continue with face verification.',
        );
        _isLoading = false;
        notifyListeners();
        return;
      }

      cameras = await availableCameras();
      if (cameras.isEmpty) {
        _updateStatus('No Camera Available', 'No camera found on this device.');
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentCameraIndex = cameras.indexWhere(
        (camera) =>
            camera.lensDirection ==
            (useBackCamera
                ? CameraLensDirection.back
                : CameraLensDirection.front),
      );
      if (_currentCameraIndex == -1) _currentCameraIndex = 0;

      cameraController = CameraController(
        cameras[_currentCameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await cameraController!.initialize();

      _isCameraReady = true;
      _isLoading = false;

      _updateStatus(
        'Position Your Face',
        requiredBlinks == 0
            ? 'Center your face in the circle and look at the camera.'
            : 'Center your face in the circle and prepare to blink.',
      );

      _startFaceDetection();
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      _updateStatus(
        'Camera Error',
        'Failed to initialize camera. Please try again.',
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2) return;

    try {
      _detectionTimer?.cancel();
      await cameraController?.dispose();

      _currentCameraIndex = (_currentCameraIndex + 1) % cameras.length;

      cameraController = CameraController(
        cameras[_currentCameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await cameraController!.initialize();
      _isCameraReady = true;

      if (!_isComplete) {
        _startFaceDetection();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  void _startFaceDetection() {
    if (!_isCameraReady || _isComplete) return;

    _detectionTimer = Timer.periodic(
      Duration(milliseconds: _getDetectionInterval()),
      (timer) async {
        if (_isComplete || _isDetecting) return;
        await _detectFace();
      },
    );
  }

  int _getDetectionInterval() {
    if (_consecutiveBlinks > 0) {
      return 50;
    }

    switch (requiredBlinks) {
      case 0:
        return 150;
      case 1:
        return 80;
      case 2:
        return 60;
      default:
        return 50;
    }
  }

  Future<void> _detectFace() async {
    if (!_isCameraReady || _isDetecting) return;

    _isDetecting = true;

    try {
      final image = await cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector.processImage(inputImage);

      await _processFaceDetection(faces);
      await File(image.path).delete();
    } catch (e) {
      debugPrint('Face detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _processFaceDetection(List<Face> faces) async {
    if (faces.isEmpty) {
      _currentStage = LivenessCheckStage.waitingForFace;
      _updateStatus(
        'No Face Detected',
        'Please position your face in the center of the circle.',
      );
      notifyListeners();
      return;
    }

    final face = faces.first;

    if (!_isFaceQualityGood(face)) {
      _updateStatus(
        'Improve Face Position',
        'Move closer and ensure your face is well-lit and centered.',
      );
      notifyListeners();
      return;
    }

    switch (_currentStage) {
      case LivenessCheckStage.waitingForFace:
        _currentStage = LivenessCheckStage.faceDetected;
        HapticFeedback.lightImpact();

        if (requiredBlinks == 0) {
          _updateStatus(
            'Face Detected',
            'Hold steady while we capture your photo...',
          );

          Future.delayed(const Duration(milliseconds: 500), () {
            if (!_isComplete) {
              _currentStage = LivenessCheckStage.completed;
              _completeLivenessCheck();
            }
          });
        } else if (requiredBlinks == 1) {
          _currentStage = LivenessCheckStage.waitingForBlink;
          _updateStatus(
            'Face Detected',
            'Great! Now blink once to verify.',
          );
        } else {
          _currentStage = LivenessCheckStage.waitingForBlink;
          _updateStatus(
            'Face Detected',
            'Good! Now blink your eyes ${_getBlinkText()} to verify you\'re real.',
          );
        }
        break;

      case LivenessCheckStage.faceDetected:
      case LivenessCheckStage.waitingForBlink:
        if (requiredBlinks > 0) {
          await _checkForBlink(face);
        }
        break;

      case LivenessCheckStage.blinkDetected:
        if (requiredBlinks > 0) {
          await _checkForBlink(face);
        }
        break;

      case LivenessCheckStage.completed:
        break;
    }

    notifyListeners();
  }

  String _getBlinkText() {
    if (requiredBlinks == 1) return 'once';
    if (requiredBlinks == 2) return 'twice';
    return '$requiredBlinks times';
  }

  bool _isFaceQualityGood(Face face) {
    final minFaceSize = _getMinFaceSizePixels();
    final maxAngle = _getMaxHeadAngle();

    final faceSize = face.boundingBox.width * face.boundingBox.height;
    if (faceSize < minFaceSize) return false;

    final headEulerAngleY = face.headEulerAngleY ?? 0;
    final headEulerAngleZ = face.headEulerAngleZ ?? 0;

    if (headEulerAngleY.abs() > maxAngle || headEulerAngleZ.abs() > maxAngle) {
      return false;
    }

    return true;
  }

  double _getMinFaceSizePixels() {
    switch (requiredBlinks) {
      case 0:
        return 2000;
      case 1:
        return 4000;
      case 2:
        return 6000;
      default:
        return 8000;
    }
  }

  double _getMaxHeadAngle() {
    switch (requiredBlinks) {
      case 0:
        return 35;
      case 1:
        return 30;
      case 2:
        return 25;
      default:
        return 20;
    }
  }

  Future<void> _checkForBlink(Face face) async {
    final threshold = _getEyeOpenThreshold();
    final leftEyeOpen = (face.leftEyeOpenProbability ?? 0.5) > threshold;
    final rightEyeOpen = (face.rightEyeOpenProbability ?? 0.5) > threshold;

    bool blinkDetected = false;

    if (requiredBlinks == 1) {
      if ((!leftEyeOpen || !rightEyeOpen) &&
          (_lastLeftEyeOpen || _lastRightEyeOpen)) {
        await Future.delayed(const Duration(milliseconds: 10));
      } else if ((leftEyeOpen || rightEyeOpen) &&
          (!_lastLeftEyeOpen || !_lastRightEyeOpen)) {
        blinkDetected = true;
      }
    } else {
      if (!leftEyeOpen &&
          !rightEyeOpen &&
          _lastLeftEyeOpen &&
          _lastRightEyeOpen) {
        await Future.delayed(Duration(milliseconds: _getBlinkDelay()));
      } else if (leftEyeOpen &&
          rightEyeOpen &&
          !_lastLeftEyeOpen &&
          !_lastRightEyeOpen) {
        blinkDetected = true;
      }
    }

    _lastLeftEyeOpen = leftEyeOpen;
    _lastRightEyeOpen = rightEyeOpen;

    if (blinkDetected) {
      _consecutiveBlinks++;
      HapticFeedback.lightImpact();

      if (_consecutiveBlinks >= requiredBlinks) {
        _currentStage = LivenessCheckStage.completed;
        await _completeLivenessCheck();
      } else {
        _currentStage = LivenessCheckStage.blinkDetected;
        final remaining = requiredBlinks - _consecutiveBlinks;
        _updateStatus(
          'Blink Detected!',
          'Great! ${remaining == 1 ? 'Blink once more' : 'Blink $remaining more times'}.',
        );

        Future.delayed(const Duration(milliseconds: 200), () {
          if (_currentStage == LivenessCheckStage.blinkDetected) {
            _currentStage = LivenessCheckStage.waitingForBlink;
            notifyListeners();
          }
        });
      }
    }
  }

  double _getEyeOpenThreshold() {
    switch (requiredBlinks) {
      case 0:
        return 0.5;
      case 1:
        return 0.4;
      case 2:
        return 0.35;
      default:
        return 0.4;
    }
  }

  int _getBlinkDelay() {
    switch (requiredBlinks) {
      case 1:
        return 10;
      case 2:
        return 25;
      default:
        return 30;
    }
  }

  Future<void> _completeLivenessCheck() async {
    if (_isComplete) return;

    _detectionTimer?.cancel();
    _isScanning = true;

    _updateStatus(
      requiredBlinks == 0 ? 'Face Captured' : 'Liveness Verified',
      requiredBlinks == 0
          ? 'Your photo is being processed...'
          : 'Excellent! Capturing your photo now...',
    );

    _progressController.forward();

    Timer(const Duration(milliseconds: 400), () async {
      await _captureFinalImage();
    });
  }

  Future<void> _captureFinalImage() async {
    try {
      final XFile imageFile = await cameraController!.takePicture();
      _capturedImage = File(imageFile.path);

      _isComplete = true;
      _isScanning = false;

      HapticFeedback.mediumImpact();

      _updateStatus(
        'Verification Complete',
        requiredBlinks == 0
            ? 'Your face has been successfully captured!'
            : 'Your face has been successfully verified with liveness detection!',
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error capturing final image: $e');
      _updateStatus(
        'Capture Error',
        'Failed to capture image. Please try again.',
      );
      _resetLivenessCheck();
    }
  }

  void handleContinue(BuildContext context) {
    if (!_isComplete) return;
    Navigator.pop(context, _capturedImage);
  }

  void retakePhoto() {
    if (!_isComplete) return;
    _resetLivenessCheck();
    _startFaceDetection();
  }

  void _resetLivenessCheck() {
    _isComplete = false;
    _isScanning = false;
    _capturedImage = null;
    _currentStage = LivenessCheckStage.waitingForFace;
    _consecutiveBlinks = 0;
    _lastLeftEyeOpen = true;
    _lastRightEyeOpen = true;
    _progressController.reset();

    _updateStatus(
      'Position Your Face',
      'Center your face in the circle and look at the camera.',
    );

    notifyListeners();
  }

  void _updateStatus(String title, String description) {
    _statusTitle = title;
    _statusDescription = description;
    notifyListeners();
  }

  double get livenessProgress {
    if (requiredBlinks == 0) {
      switch (_currentStage) {
        case LivenessCheckStage.waitingForFace:
          return 0.0;
        case LivenessCheckStage.faceDetected:
          return 0.7;
        case LivenessCheckStage.completed:
          return 1.0;
        default:
          return 0.5;
      }
    }

    if (requiredBlinks == 1) {
      switch (_currentStage) {
        case LivenessCheckStage.waitingForFace:
          return 0.0;
        case LivenessCheckStage.faceDetected:
          return 0.4;
        case LivenessCheckStage.waitingForBlink:
          return 0.5;
        case LivenessCheckStage.blinkDetected:
          return 0.9;
        case LivenessCheckStage.completed:
          return 1.0;
      }
    }

    switch (_currentStage) {
      case LivenessCheckStage.waitingForFace:
        return 0.0;
      case LivenessCheckStage.faceDetected:
        return 0.3;
      case LivenessCheckStage.waitingForBlink:
        return 0.4;
      case LivenessCheckStage.blinkDetected:
        return 0.5 + (0.5 * _consecutiveBlinks / requiredBlinks);
      case LivenessCheckStage.completed:
        return 1.0;
    }
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _progressController.dispose();
    _faceDetector.close();
    cameraController?.dispose();
    super.dispose();
  }
}
