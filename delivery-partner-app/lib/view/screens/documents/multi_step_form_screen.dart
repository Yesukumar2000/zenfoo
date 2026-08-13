import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/document_provider.dart';
import 'package:zenfoo_partner/router/app_router_name.dart';
import 'package:zenfoo_partner/services/local_storage.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/screens/documents/screens/document_verification/document_verification_step.dart';
import 'package:zenfoo_partner/view/screens/documents/screens/personal_detail_step.dart';
import 'package:zenfoo_partner/view/screens/documents/screens/select_city_step.dart';
import 'package:zenfoo_partner/view/screens/documents/screens/select_store_step.dart';
import 'package:zenfoo_partner/view/screens/documents/screens/select_vehicle_step.dart';
import 'package:zenfoo_partner/view/screens/documents/screens/selfie_step.dart';

class MultiStepFormScreen extends StatefulWidget {
  final int initialStep;

  const MultiStepFormScreen({
    super.key,
    this.initialStep = 0,
  });

  @override
  State<MultiStepFormScreen> createState() => _MultiStepFormScreenState();
}

class _MultiStepFormScreenState extends State<MultiStepFormScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;

  int currentIndex = 0;
  bool _isSubmittingDocuments = false;
  String? _rejectionRemark;

  // Callback functions from steps
  Future<bool> Function()? _savePersonalDetails;
  Future<bool> Function()? _saveVehicleSelection;
  Future<bool> Function()? _saveCitySelection;
  Future<bool> Function()? _saveStoreSelection;
  Future<bool> Function()? _saveSelfieSelection;

  final List<String> titles = [
    "Personal Details",
    "Select Vehicle",
    "Select City",
    "Select Store",
    "Take Selfie",
    "Documents"
  ];

  final List<String> labels = [
    "REGISTRATION",
    "REGISTRATION",
    "REGISTRATION",
    "REGISTRATION",
    "VERIFICATION",
    "VERIFICATION"
  ];

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialStep;
    _pageController = PageController(initialPage: widget.initialStep);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _progressController.forward();

    // Check if documents are already uploaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingDocuments();
    });
  }

  /// Check if documents are already uploaded and navigate to verification screen
  Future<void> _checkExistingDocuments() async {
    try {
      final deliveryBoyData = await LocalStorage.getDeliveryBoyData();

      if (deliveryBoyData != null) {
        // If details not given yet, stay on form - don't redirect
        final isDetailsGiven = deliveryBoyData['is_details_given'] ?? 0;
        if (isDetailsGiven == 0) return;

        final status = deliveryBoyData['status'] ?? 0;
        final documents = deliveryBoyData['documents'];

        // Load documents into DocumentProvider if available
        debugPrint('🔍 documents from LocalStorage: $documents');
        if (documents != null && mounted) {
          debugPrint('📥 Loading documents into DocumentProvider...');
          final docProvider = context.read<DocumentProvider>();
          docProvider.loadDocumentsFromApi(documents);
          debugPrint('✅ Documents loaded into provider');
        } else {
          debugPrint('⚠️ documents is null or not mounted');
        }

        // Status 2: Rejected - Show remark banner and stay on form
        if (status == 2 && mounted) {
          // Use rejection_remark if available, fallback to remark
          final remark =
              deliveryBoyData['rejection_remark'] ?? deliveryBoyData['remark'];
          if (remark != null && remark.toString().isNotEmpty) {
            setState(() {
              _rejectionRemark = remark.toString();
            });
          }
          return;
        }

        // Status 3: Rejected - Show remark banner and stay on form
        if (status == 3 && mounted) {
          // Use rejection_remark if available, fallback to remark
          final remark =
              deliveryBoyData['rejection_remark'] ?? deliveryBoyData['remark'];
          if (remark != null && remark.toString().isNotEmpty) {
            setState(() {
              _rejectionRemark = remark.toString();
            });
          }
          return;
        }

        // Check documents status and redirect accordingly
        if (documents != null) {
          final overallStatus = documents['overall_status'];
          final docProvider = context.read<DocumentProvider>();

          // Check if any document is rejected
          final hasRejectedDocument =
              docProvider.drivingLicenseStatus == 'rejected' ||
                  docProvider.rcStatus == 'rejected' ||
                  docProvider.aadharStatus == 'rejected' ||
                  docProvider.panStatus == 'rejected' ||
                  docProvider.bankDetailsStatus == 'rejected';

          // If documents exist, check status and navigate
          if (overallStatus != null && mounted) {
            if (hasRejectedDocument || overallStatus == 'rejected') {
              // Documents rejected - go to verifying details to show rejection
              debugPrint('📄 Documents rejected - going to verifying details');
              context.go(AppRouterName.verifyingDetails);
            } else if (overallStatus == 'pending_verification') {
              // Documents uploarded, waiting for verification
              debugPrint('📄 Documents pending verification - going to verifying details');
              context.go(AppRouterName.verifyingDetails);
            } else if (overallStatus == 'verified' && status == 1){
              // Documents verified and approved - go to home
              debugPrint('✅ Documents verified and approved - going to home');
              context.go(AppRouterName.bottomNavScreen);
            }
            // For 'incomplete', stay on this screen to allow upload
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking existing documents: $e');
    }
  }


  void _nextStep() {
    if (currentIndex < titles.length - 1) {
      setState(() {
        currentIndex++;
      });

      _progressController.forward(from: 0);

      _pageController.animateToPage(
        currentIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // FINAL SUBMIT
      debugPrint("Form Submitted");
    }
  }

  /// Submit all documents to backend
  Future<void> _submitAllDocuments() async {
    final docProvider = context.read<DocumentProvider>();

    // Check if ALL documents are complete (either uploaded locally OR exist on server)
    // Validate each document individually to show specific error messages
    if (!docProvider.isDrivingLicenseComplete) {
      final isRejected = docProvider.drivingLicenseStatus == 'rejected';
      _showErrorSnackBar(isRejected
          ? 'Please re-upload Driving License (rejected)'
          : 'Please complete Driving License details');
      return;
    }
    if (!docProvider.isRcComplete) {
      final isRejected = docProvider.rcStatus == 'rejected';
      _showErrorSnackBar(isRejected
          ? 'Please re-upload RC (rejected)'
          : 'Please complete RC details');
      return;
    }
    if (!docProvider.isAadharComplete) {
      final isRejected = docProvider.aadharStatus == 'rejected';
      _showErrorSnackBar(isRejected
          ? 'Please re-upload Aadhar (rejected)'
          : 'Please complete Aadhar details');
      return;
    }
    if (!docProvider.isPanComplete) {
      final isRejected = docProvider.panStatus == 'rejected';
      _showErrorSnackBar(isRejected
          ? 'Please re-upload PAN Card (rejected)'
          : 'Please complete PAN details');
      return;
    }
    if (!docProvider.isBankDetailsComplete) {
      final isRejected = docProvider.bankDetailsStatus == 'rejected';
      _showErrorSnackBar(isRejected
          ? 'Please re-upload Bank Details (rejected)'
          : 'Please complete Bank details');
      return;
    }

    // Set loading state
    setState(() {
      _isSubmittingDocuments = true;
    });

    try {
      debugPrint('✅ All documents collected successfully');

      // Note: Individual screens handle their own API updates when data is submitted
      // This screen just validates completion and navigates based on status

      setState(() {
        _isSubmittingDocuments = false;
      });

      if (!mounted) return;

      // Get delivery boy data from local storage to check status
      final deliveryBoyData = await LocalStorage.getDeliveryBoyData();

      if (deliveryBoyData != null) {
        final status = deliveryBoyData['status'] ?? 0;
        final documents = deliveryBoyData['documents'];
        final overallStatus = documents?['overall_status'];

        // Only navigate to home if BOTH delivery boy is approved AND documents are verified
        if (status == 1 && overallStatus == 'verified') {
          debugPrint('✅ Status 1 (Approved) & Documents verified - Going to home');
          if (mounted) {
            context.go(AppRouterName.bottomNavScreen);
          }
          return;
        }
      }

      // For all other cases - Navigate to verifying details screen
      debugPrint('📄 Documents submitted - Going to verifying details');
      if (mounted) {
        context.go(AppRouterName.verifyingDetails);
      }
    } catch (e) {
      setState(() {
        _isSubmittingDocuments = false;
      });
      debugPrint('❌ Error: $e');
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    double progressValue = (currentIndex + 1) / titles.length;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// APP HEADER
          AppHeader(
            label: labels[currentIndex],
            title: titles[currentIndex],
            showBackButton: currentIndex > 0,
            showExitButton: true,
            onBackPressed: currentIndex > 0
                ? () {
                    if (currentIndex > 0) {
                      setState(() {
                        currentIndex--;
                      });
                      _pageController.animateToPage(
                        currentIndex,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  }
                : null,
          ),

          /// REJECTION BANNER
          if (_rejectionRemark != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.cancel,
                        color: Colors.red,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Rejected',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      _rejectionRemark!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '📝 Please review the documents and resubmit with corrections',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: AppDimensions.getHeight(2)),

          /// LINEAR PROGRESS INDICATOR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, _) {
                return LinearProgressIndicator(
                  value: progressValue * _progressController.value,
                  minHeight: 6,
                  backgroundColor: colorScheme.border.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  borderRadius: BorderRadius.circular(10),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          /// PAGE VIEW CONTENT
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                PersonalDetailsStep(
                  onSaveCallback: (saveFunction) {
                    _savePersonalDetails = saveFunction;
                  },
                ),
                SelectVehicleStep(
                  onSaveCallback: (saveFunction) {
                    _saveVehicleSelection = saveFunction;
                  },
                ),
                SelectCityStep(
                  onSaveCallback: (saveFunction) {
                    _saveCitySelection = saveFunction;
                  },
                ),
                SelectStoreStep(
                  onSaveCallback: (saveFunction) {
                    _saveStoreSelection = saveFunction;
                  },
                ),
                SelectSelfieStep(
                  onSaveCallback: (saveFunction) {
                    _saveSelfieSelection = saveFunction;
                  },
                ),
                DocumentVerificationStep()
              ],
            ),
          ),

          /// CONTINUE BUTTON
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final isLoading = (currentIndex == 0 &&
                        isStatusLoading(
                            authProvider.updatePersonalDetailsState.status)) ||
                    (currentIndex == 1 &&
                        isStatusLoading(
                            authProvider.selectVehicleState.status)) ||
                    (currentIndex == 2 &&
                        isStatusLoading(authProvider.updateCityState.status)) ||
                    (currentIndex == 3 &&
                        isStatusLoading(
                            authProvider.selectStoreLocationsState.status)) ||
                    (currentIndex == 4 &&
                        isStatusLoading(
                            authProvider.updateProfileImageState.status));

                return CustomButton(
                  text: 'Continue',
                  isLoading: isLoading || _isSubmittingDocuments,
                  onPressed: () async {
                    if (currentIndex == (titles.length - 1)) {
                      // Last step (Documents) - Check and Submit all documents
                      await _submitAllDocuments();
                    } else {
                      // Handle first step (Personal Details) with API call
                      if (currentIndex == 0 && _savePersonalDetails != null) {
                        final success = await _savePersonalDetails!();
                        if (success) {
                          _nextStep();
                        }
                      }
                      // Handle second step (Vehicle Selection) with API call
                      else if (currentIndex == 1 &&
                          _saveVehicleSelection != null) {
                        final success = await _saveVehicleSelection!();
                        if (success) {
                          _nextStep();
                        }
                      }
                      // Handle third step (City Selection) with API call
                      else if (currentIndex == 2 &&
                          _saveCitySelection != null) {
                        final success = await _saveCitySelection!();
                        if (success) {
                          _nextStep();
                        }
                      }
                      // Handle fourth step (Store Selection) with API call
                      else if (currentIndex == 3 &&
                          _saveStoreSelection != null) {
                        final success = await _saveStoreSelection!();
                        if (success) {
                          _nextStep();
                        }
                      }
                      // Handle fifth step (Selfie) with API call
                      else if (currentIndex == 4 &&
                          _saveSelfieSelection != null) {
                        final success = await _saveSelfieSelection!();
                        if (success) {
                          _nextStep();
                        }
                      } else {
                        // Other steps without API calls yet
                        _nextStep();
                      }
                    }
                  },
                );
              },
            ),
          ),
          SizedBox(height: AppDimensions.getHeight(3)),
        ],
      ),
    );
  }
}
