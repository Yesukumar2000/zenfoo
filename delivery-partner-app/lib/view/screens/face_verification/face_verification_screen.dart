import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/session_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/services/overlay_service.dart';
import 'package:zenfoo_partner/services/face_recognition_service.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/screens/face_verification/face_scan_screen.dart';
import 'package:geolocator/geolocator.dart';

class FaceVerificationScreen extends StatefulWidget {
  const FaceVerificationScreen({super.key});

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> {
  final FaceRecognitionService _faceService = FaceRecognitionService();
  File? _capturedImage;
  bool _isProcessing = false;
  bool _isSdkInitialized = false;
  bool _faceMatchPassed = false;
  bool _isGoingOnline = false;
  bool _sessionFailed = false;
  String _statusMessage = 'Initializing face verification...';
  double? _matchScore;

  @override
  void initState() {
    super.initState();
    _initializeFaceSDK();
  }

  Future<void> _initializeFaceSDK() async {
    try {
      debugPrint('🔧 Initializing Face Recognition Service...');

      await _faceService.initialize();
      debugPrint('✅ Face Recognition Service initialized successfully');

      if (mounted) {
        setState(() {
          _isSdkInitialized = true;
          _statusMessage = 'Ready to verify your identity';
        });
      }
    } catch (e) {
      debugPrint('❌ Face Recognition Service initialization failed: $e');
      if (mounted) {
        setState(() {
          _isSdkInitialized = false;
          _statusMessage = 'Service initialization failed.';
        });
      }
    }
  }

  Future<void> _captureFaceImage() async {
    if (!_isSdkInitialized) {
      debugPrint('⚠️ Service not initialized');
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Opening liveness detection...';
    });

    try {
      debugPrint('📷 Opening face scan screen with liveness detection...');

      // Navigate to Face Scan Screen with liveness detection
      final File? capturedFile = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const FaceScanScreen(
            useBackCam: false,
            requiredBlinks: 0,
          ),
        ),
      );

      if (capturedFile == null) {
        debugPrint('⚠️ User cancelled face scan');
        setState(() {
          _statusMessage = 'Face scan cancelled. Please try again.';
          _isProcessing = false;
        });
        return;
      }

      debugPrint(
          '📸 Image captured with liveness verification: ${capturedFile.path}');

      setState(() {
        _capturedImage = capturedFile;
        _statusMessage = 'Liveness verified! Verifying face...';
      });

      // Perform face match
      await _performFaceMatch(capturedFile);
    } catch (e, stackTrace) {
      debugPrint('❌ Face scan error: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _statusMessage = 'Error: ${e.toString()}';
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _performFaceMatch(File capturedImage) async {
    final authProvider = context.read<AuthProvider>();
    final deliveryBoy = authProvider.currentDeliveryBoy;

    if (deliveryBoy?.profileImageUrl == null) {
      setState(() {
        _statusMessage =
            'No profile image found. Please upload a profile photo first.';
        _isProcessing = false;
      });
      return;
    }

    try {
      setState(() {
        _statusMessage = 'Matching face with profile...';
      });

      debugPrint('🔍 Comparing captured face with profile image...');

      // Use Face Recognition Service to compare faces
      final similarity = await _faceService.compareFaces(
        capturedImage: capturedImage,
        profileImageUrl: deliveryBoy!.profileImageUrl!,
      );

      debugPrint('📊 Similarity score: $similarity');

      if (similarity == -1.0) {
        setState(() {
          _statusMessage = 'Failed to perform face comparison';
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _matchScore = similarity;
        _faceMatchPassed = similarity >= 0.75; // 75% threshold
        _statusMessage = _faceMatchPassed
            ? 'Face verified successfully! (${(similarity * 100).toStringAsFixed(1)}% match)'
            : 'Face verification failed. Match score too low (${(similarity * 100).toStringAsFixed(1)}%)';
        _isProcessing = false;
      });

      // If face match passed, proceed to go online
      if (_faceMatchPassed) {
        setState(() {
          _isGoingOnline = true;
          _statusMessage = 'Starting session...';
        });
        await _goOnline();
        // Note: _goOnline() will handle navigation
      }
    } catch (e) {
      debugPrint('❌ Face match error: $e');
      setState(() {
        _statusMessage = 'Error during face matching: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  Future<void> _goOnline() async {
    try {
      // Get current location
      Position? position = await _getCurrentPosition();

      if (position == null) {
        if (mounted) {
          setState(() {
            _isGoingOnline = false;
            _statusMessage = 'Unable to get location. Please enable GPS.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Unable to get location. Please enable GPS.')),
          );
        }
        return;
      }

      if (!mounted) return;

      // Start session with timeout
      final sessionProvider = context.read<SessionProvider>();
      bool success;
      try {
        success = await sessionProvider.startSession(
          latitude: position.latitude,
          longitude: position.longitude,
        ).timeout(const Duration(seconds: 15));
      } on TimeoutException {
        if (mounted) {
          setState(() {
            _isGoingOnline = false;
            _sessionFailed = true;
            _statusMessage = 'Session request timed out. Please try again.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request timed out. Please retry.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        if (success) {
          // Request overlay permission after successfully going online (non-blocking)
          try {
            final overlayService = OverlayService();
            if (mounted) {
              await overlayService.requestOverlayPermission(context);
            }
          } catch (e) {
            debugPrint('⚠️ Error requesting overlay permission: $e');
            // Continue even if overlay permission fails - not critical
          }

          if (!mounted) return;

          // Show success and navigate back
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are now online!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context, true);
          // Navigation successful, no need to reset _isGoingOnline
        } else {
          // Session start failed, reset loading state
          setState(() {
            _isGoingOnline = false;
            _sessionFailed = true;
            _statusMessage = sessionProvider.startSessionState.message ??
                'Failed to go online. Please try again.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(sessionProvider.startSessionState.message ??
                  'Failed to go online'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error going online: $e');
      if (mounted) {
        setState(() {
          _isGoingOnline = false;
          _sessionFailed = true;
          _statusMessage = 'Error: ${e.toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint('Error getting position: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final authProvider = context.watch<AuthProvider>();
    final deliveryBoy = authProvider.currentDeliveryBoy;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppHeader(
              label: 'Security',
              title: 'Face Verification',
              showBackButton: true,
            ),
            const SizedBox(height: 20),

            // Profile Image
            CircleAvatar(
              radius: 60,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              backgroundImage: deliveryBoy?.profileImageUrl != null
                  ? NetworkImage(deliveryBoy!.profileImageUrl!)
                  : null,
              child: deliveryBoy?.profileImageUrl == null
                  ? HugeIcon(
                      icon: HugeIcons.strokeRoundedUser,
                      color: colorScheme.primary,
                      size: 60,
                    )
                  : null,
            ),

            const SizedBox(height: 16),

            Text(
              deliveryBoy?.name ?? 'Delivery Partner',
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Verify your identity to go online',
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.border),
              ),
              child: Column(
                children: [
                  // Face Match Status
                  _buildStatusRow(
                    colorScheme,
                    'Face Verification',
                    _faceMatchPassed,
                    score: _matchScore,
                  ),

                  const SizedBox(height: 20),

                  // Status Message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedInformationCircle,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: GoogleFonts.inter(
                              color: colorScheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Captured Image Preview
            if (_capturedImage != null) ...[
              Text(
                'Captured Image',
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _capturedImage!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Instructions
            if (!_faceMatchPassed && !_isProcessing) ...[
              _buildInstructionCard(
                colorScheme,
                'Instructions',
                [
                  'Position your face in the camera frame',
                  'Blink once when prompted',
                  'Ensure good lighting',
                  'Remove glasses if possible',
                  'Look straight at the camera',
                ],
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.background,
          border: Border(
            top: BorderSide(
              color: colorScheme.border,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: CustomButton(
            text: _isGoingOnline
                ? 'Going Online...'
                : _sessionFailed
                    ? 'Retry Going Online'
                    : _faceMatchPassed
                        ? 'Verification Complete'
                        : !_isSdkInitialized
                            ? 'Initializing...'
                            : _isProcessing
                                ? 'Processing...'
                                : _capturedImage != null && !_faceMatchPassed
                                    ? 'Retry Verification'
                                    : 'Start Liveness Check',
            backgroundColor: _sessionFailed
                ? Colors.red
                : _faceMatchPassed && !_isGoingOnline
                    ? colorScheme.success
                    : colorScheme.primary,
            isLoading: !_isSdkInitialized || _isProcessing || _isGoingOnline,
            onPressed: (!_isSdkInitialized || _isProcessing || _isGoingOnline)
                ? null
                : _sessionFailed
                    ? () {
                        setState(() {
                          _sessionFailed = false;
                          _isGoingOnline = true;
                          _statusMessage = 'Retrying session...';
                        });
                        _goOnline();
                      }
                    : _captureFaceImage,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    colorScheme,
    String label,
    bool passed, {
    double? score,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: passed
                    ? colorScheme.success.withValues(alpha: 0.1)
                    : colorScheme.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: HugeIcon(
                icon: passed
                    ? HugeIcons.strokeRoundedCheckmarkCircle02
                    : HugeIcons.strokeRoundedCircle,
                color: passed ? colorScheme.success : colorScheme.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (score != null)
                  Text(
                    '${(score * 100).toStringAsFixed(1)}% match',
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (passed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.success.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'Passed',
              style: GoogleFonts.inter(
                color: colorScheme.success,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInstructionCard(
    colorScheme,
    String title,
    List<String> instructions,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...instructions.map((instruction) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        instruction,
                        style: GoogleFonts.inter(
                          color: colorScheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Cleanup captured image
    _capturedImage?.delete();
    super.dispose();
  }
}
