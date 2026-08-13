import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/document_provider.dart';
import 'package:zenfoo_partner/providers/incoming_order_provider.dart';
import 'package:zenfoo_partner/router/app_router_name.dart';
import 'package:zenfoo_partner/services/local_storage.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/utils/app_fonts.dart';
import 'package:zenfoo_partner/utils/app_images.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class VerifyingDetailsScreen extends StatefulWidget {
  const VerifyingDetailsScreen({super.key});

  @override
  State<VerifyingDetailsScreen> createState() => _VerifyingDetailsScreenState();
}

class _VerifyingDetailsScreenState extends State<VerifyingDetailsScreen> {
  int _deliveryBoyStatus =
      0; // 0: Registered, 1: Pending, 2: Approved, 3: Rejected
  String? _remark;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final deliveryBoyData = await LocalStorage.getDeliveryBoyData();
    if (deliveryBoyData != null && mounted) {
      setState(() {
        _deliveryBoyStatus = deliveryBoyData['status'] ?? 0;
        // Use rejection_remark if available, fallback to remark
        _remark =
            deliveryBoyData['rejection_remark'] ?? deliveryBoyData['remark'];
      });

      // Load documents into DocumentProvider if available
      if (deliveryBoyData['documents'] != null && mounted) {
        final docProvider = context.read<DocumentProvider>();
        docProvider.loadDocumentsFromApi(deliveryBoyData['documents']);
      }
      _checkStatusAndNavigate();
    }
  }

  Future<void> _refreshPersonalDetails() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    final authProvider = context.read<AuthProvider>();
    await authProvider.getPersonalDetails();

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });

      if (isStatusSuccess(authProvider.getPersonalDetailsState.status)) {
        final deliveryBoyData = await LocalStorage.getDeliveryBoyData();
        if (deliveryBoyData != null) {
          final newStatus = deliveryBoyData['status'] ?? 0;
          final newRemark = deliveryBoyData['rejection_remark'] ??
              deliveryBoyData['remark'];

          setState(() {
            _deliveryBoyStatus = newStatus;
            _remark = newRemark;
          });

          // Load documents into DocumentProvider if available
          if (deliveryBoyData['documents'] != null && mounted) {
            final docProvider = context.read<DocumentProvider>();
            docProvider.loadDocumentsFromApi(deliveryBoyData['documents']);
          }

          // Show status feedback and navigate if needed
          await _handleStatusAfterRefresh(newStatus);
        }
      } else {
        // Show error message if API call failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to check status. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleStatusAfterRefresh(int status) async {
    if (!mounted) return;

    // Check if any document is rejected
    final docProvider = context.read<DocumentProvider>();
    final hasRejectedDocument = docProvider.drivingLicenseStatus == 'rejected' ||
        docProvider.rcStatus == 'rejected' ||
        docProvider.aadharStatus == 'rejected' ||
        docProvider.panStatus == 'rejected' ||
        docProvider.bankDetailsStatus == 'rejected';

    // Also check overall_status from local storage
    final deliveryBoyData = await LocalStorage.getDeliveryBoyData();
    final documents = deliveryBoyData?['documents'];
    final overallStatus = documents?['overall_status'];
    final isOverallRejected = overallStatus == 'rejected';

    if (status == 1) {
      // Approved - show message and navigate to home
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account has been approved!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _navigateToNextScreen();
      });
    } else if (status == 2 || status == 3 || hasRejectedDocument || isOverallRejected) {
      // Rejected (by status OR by document status) - show message and navigate to documents
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your documents were rejected. Please re-upload.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          // Navigate directly to documents step
          context.go(
            AppRouterName.multiStepForm,
            extra: {'initialStep': 5},
          );
        }
      });
    } else {
      // Still pending - show message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your verification is still pending. Please wait.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    if (_deliveryBoyStatus == 1) {
      // Status 1: Approved - Navigate to dashboard/home
      debugPrint('✅ Status 1 (Approved) - Going to home');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account has been approved!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      final authProvider = context.read<AuthProvider>();
      final incomingOrderProvider = context.read<IncomingOrderProvider>();
      final deliveryBoyId = authProvider.currentDeliveryBoy?.id ?? 0;

      if (deliveryBoyId > 0) {
        // Check if there's an active order in Firebase - preserve it, don't clear
        final currentOrder = await incomingOrderProvider
            .getCurrentAcceptedOrder(deliveryBoyId);
        if (currentOrder != null) {
          debugPrint(
              '📦 Found active order ${currentOrder.orderId} - preserving it');
          incomingOrderProvider.setCurrentAcceptedOrder(currentOrder);
        } else {
          // No active order - start listening for new orders
          incomingOrderProvider.startListening(deliveryBoyId);
          debugPrint('🎧 No active order - listening for new orders');
        }
      }

      if (!mounted) return;
      context.go(AppRouterName.bottomNavScreen);
    } else if (_deliveryBoyStatus == 2 || _deliveryBoyStatus == 3) {
      // Status 2 or 3: Rejected - Navigate to document step (index 5)
      debugPrint('❌ Status $_deliveryBoyStatus (Rejected) - Going to documents step');
      context.go(
        AppRouterName.multiStepForm,
        extra: {'initialStep': 5}, // Documents step is index 5
      );
    }
  }

  Future<void> _checkStatusAndNavigate() async {
    // Only navigate if status has changed to a terminal state (Approved or Rejected)
    // Status 0 (Registered/Pending) - user stays on this screen

    // Get document overall_status to check if documents are verified
    final deliveryBoyData = await LocalStorage.getDeliveryBoyData();
    final documents = deliveryBoyData?['documents'];
    final overallStatus = documents?['overall_status'];

    // Check if any document is rejected
    final docProvider = context.read<DocumentProvider>();
    final hasRejectedDocument = docProvider.drivingLicenseStatus == 'rejected' ||
        docProvider.rcStatus == 'rejected' ||
        docProvider.aadharStatus == 'rejected' ||
        docProvider.panStatus == 'rejected' ||
        docProvider.bankDetailsStatus == 'rejected';

    if (_deliveryBoyStatus == 1 && overallStatus == 'verified') {
      // Status 1 (Approved) AND documents verified - navigate to dashboard
      Future.microtask(() => _navigateToNextScreen());
    } else if (_deliveryBoyStatus == 2 || _deliveryBoyStatus == 3 || hasRejectedDocument || overallStatus == 'rejected') {
      // Rejected - give user time to see rejection message, then navigate to documents
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          context.go(
            AppRouterName.multiStepForm,
            extra: {'initialStep': 5},
          );
        }
      });
    }
    // For pending_verification or other statuses, stay on this screen
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// APP HEADER
          AppHeader(
            label: "VERIFICATION",
            title: (_deliveryBoyStatus == 2 || _deliveryBoyStatus == 3)
                ? "Verification Rejected"
                : "Verifying Details",
            showBackButton: false,
            showExitButton: true,
          ),

          SizedBox(height: AppDimensions.getHeight(2)),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshPersonalDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: AppDimensions.getHeight(10)),

                      /// VERIFICATION IMAGE
                      Image.asset(
                        AppImages.documentVerifying,
                        height: AppDimensions.getWidth(30),
                        width: AppDimensions.getWidth(30),
                      ),

                      SizedBox(height: AppDimensions.getHeight(3)),

                      /// STATUS-BASED CONTENT
                      if (_deliveryBoyStatus == 2 || _deliveryBoyStatus == 3) ...[
                        // Rejected Status
                        Container(
                          padding:
                              const EdgeInsets.all(AppDimensions.paddingMedium),
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingMedium,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                                AppDimensions.borderRadius),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.cancel_outlined,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Verification Rejected',
                                style: textTheme.headlineSmall?.copyWith(
                                  fontFamily: AppFonts.bold,
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_remark != null && _remark!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: colorScheme.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Reason for Rejection:',
                                            style:
                                                textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _remark!,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Text(
                                'Please update your documents and resubmit for verification.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Pending Status (0 or 1)
                        Text(
                          '10 - 20 Mins',
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: AppDimensions.getHeight(2)),
                        Text(
                          'We are verifying your details.',
                          style: textTheme.headlineSmall?.copyWith(
                            fontFamily: AppFonts.bold,
                            color: colorScheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppDimensions.getHeight(2)),
                        SizedBox(
                          width: AppDimensions.getWidth(80),
                          child: Text(
                            'Please wait, we\'re verifying your info… we\'ll update you soon.',
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.textSecondary,
                            ),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],

                      SizedBox(height: AppDimensions.getHeight(4)),

                      /// REFRESH BUTTON
                      if (_isRefreshing)
                        CircularProgressIndicator(
                          color: colorScheme.primary,
                        )
                      else
                        TextButton.icon(
                          onPressed: _refreshPersonalDetails,
                          icon: Icon(
                            Icons.refresh,
                            color: colorScheme.primary,
                          ),
                          label: Text(
                            'Check Status',
                            style: textTheme.titleSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
