import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/document_provider.dart';
import 'package:zenfoo_partner/providers/incoming_order_provider.dart';
import 'package:zenfoo_partner/providers/personal_details_provider.dart';
import 'package:zenfoo_partner/router/app_router_name.dart';
import 'package:zenfoo_partner/services/local_storage.dart';
import 'package:zenfoo_partner/services/native_floating_service.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_images.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> scaleAnim;
  late Animation<double> fadeAnim;
  late Animation<Offset> slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    scaleAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    slideAnim = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start animation
    _controller.forward();

    // Check if launched from overlay - skip animation if so
    _checkOverlayLaunchAndNavigate();
  }

  Future<void> _checkOverlayLaunchAndNavigate() async {
    // Check if app was launched from overlay (Android only)
    bool fromOverlay = false;
    if (Platform.isAndroid) {
      fromOverlay = await NativeFloatingService.wasLaunchedFromOverlay();
    }

    if (fromOverlay) {
      // Skip animation delay if launched from overlay
      debugPrint('📱 Launched from overlay - navigating immediately');
      await _navigateToNextScreen();
    } else {
      // Normal launch - wait for animation
      Future.delayed(const Duration(seconds: 3), () async {
        await _navigateToNextScreen();
      });
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    bool isLogin = await LocalStorage.isLoggedIn();

    if (!isLogin){
      // User not logged in - go to login screen
      if (!mounted) return;
      context.go(AppRouterName.login);
    } else {
      // User is logged in - fetch personal details (SINGLE API call for both providers)
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final personalDetailsProvider =
          Provider.of<PersonalDetailsProvider>(context, listen: false);

      // Single API call - fetches all details including documents, bank, verification status
      bool success = await personalDetailsProvider.fetchPersonalDetails();

      if (!mounted) return;

      // Load delivery boy data from local storage into AuthProvider (no second API call)
      if (success && personalDetailsProvider.personalDetails != null) {
        await authProvider.loadUserData();
        debugPrint(
            '✅ Personal details fetched (single API call) - both providers updated');
      }

      if (!mounted) return;

      // Get delivery boy data from local storage
      final deliveryBoyData = await LocalStorage.getDeliveryBoyData();

      if (deliveryBoyData == null) {
        // No data found - go to login
        if (mounted) context.go(AppRouterName.login);
        return;
      }

      // Get status: 0=Registered, 1=Pending, 2=Approved, 3=Rejected
      final status = deliveryBoyData['status'] ?? 0;
      final documents = deliveryBoyData['documents'];

      // Load documents into DocumentProvider if available
      if (documents != null && mounted) {
        final docProvider = context.read<DocumentProvider>();
        docProvider.loadDocumentsFromApi(documents);
      }

      if (!mounted) return;

      // Route based on status
      if (status == 1) {
        // Status 1: Approved - Navigate to dashboard
        debugPrint('✅ Status 1 (Approved) - Going to home');
        final incomingOrderProvider = context.read<IncomingOrderProvider>();
        final deliveryBoyId = authProvider.currentDeliveryBoy?.id ?? 0;

        if (deliveryBoyId > 0) {
          // Check if there's an active current order in Firebase
          final currentOrder = await incomingOrderProvider
              .getCurrentAcceptedOrder(deliveryBoyId);

          if (currentOrder != null) {
            // Order is in active delivery - restore it to provider and keep listening
            debugPrint(
                '📦 Found active order ${currentOrder.orderId} - resuming delivery');
            incomingOrderProvider.setCurrentAcceptedOrder(currentOrder);
          } else {
            // No active order - start listening for new orders
            incomingOrderProvider.startListening(deliveryBoyId);
            debugPrint('🎧 No active order - listening for new orders');
          }
        }
        if (!mounted) return;
        context.go(AppRouterName.bottomNavScreen);
        return;
      }

      if (status == 2) {
        // Status 2: Rejected - Go back to form to fix rejected documents
        debugPrint('❌ Status 2 (Rejected) - Going to form with remark');

        // Show rejection notification
        final remark = deliveryBoyData['rejection_remark'] ?? deliveryBoyData['remark'];
        if (remark != null && remark.toString().isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Rejected',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    remark.toString(),
                    style: const TextStyle(fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        }

        if (!mounted) return;
        context.go(AppRouterName.multiStepForm);
        return;
      }

      if (status == 3) {
        // Status 3: Rejected - Go back to form to fix rejected documents
        debugPrint('❌ Status 3 (Rejected) - Going to form with remark');

        // Show rejection notification
        final remark = deliveryBoyData['rejection_remark'] ?? deliveryBoyData['remark'];
        if (remark != null && remark.toString().isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Rejected',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    remark.toString(),
                    style: const TextStyle(fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        }

        if (!mounted) return;
        context.go(AppRouterName.multiStepForm);
        return;
      }

      // Status 0: Registered - Check registration progress and navigate accordingly

      // FIRST: Check if personal details have been filled
      final isDetailsGiven = deliveryBoyData['is_details_given'] ?? 0;
      if (isDetailsGiven == 0) {
        // Details not given yet - start from signup (step 0)
        debugPrint('📝 Details not given - Going to signup form');
        context.go(AppRouterName.multiStepForm);
        return;
      }

      // Check if documents are uploaded and pending verification
      if (documents != null) {
        final overallStatus = documents['overall_status'];
        if (overallStatus == 'pending_verification' ||
            overallStatus == 'verified') {
          debugPrint(
              '📄 Documents pending verification - Going to verifying details');
          context.go(AppRouterName.verifyingDetails);
          return;
        }
      }

      // Details given but registration incomplete - skip signup step
      debugPrint('📝 Details given, registration incomplete - Going to form step 1');
      context.go(AppRouterName.multiStepForm, extra: {'initialStep': 1});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return CustomScaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: fadeAnim,
          child: ScaleTransition(
            scale: scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  AppImages.splash,
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
