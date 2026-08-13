import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/incoming_order_model.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/services/firebase_order_service.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_images.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_image_icon.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/screens/delivery/chat_with_admin_screen.dart';
import 'package:zenfoo_partner/view/screens/delivery/delivery_detail_screen.dart';
import 'package:zenfoo_partner/view/screens/emergency/emergency_support_screen.dart';

/// Step status enum for tracking delivery progress
enum StepStatus { notStarted, inProgress, completed }

class DeliveryProgressScreen extends StatefulWidget {
  final IncomingOrder order;

  const DeliveryProgressScreen({
    super.key,
    required this.order,
  });

  @override
  State<DeliveryProgressScreen> createState() => _DeliveryProgressScreenState();
}

class _DeliveryProgressScreenState extends State<DeliveryProgressScreen> {
  int _currentStep = 0; // 0 = first seller, increments as delivery progresses
  late List<StepStatus> _stepStatuses; // Track status of each step
  final FirebaseOrderService _firebaseService = FirebaseOrderService();
  bool _isLoading = true;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final totalSteps = widget.order.sellersVisitOrder.length + 1;
    _stepStatuses = List.generate(totalSteps, (_) => StepStatus.notStarted);
    _loadProgressFromFirebase();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Load delivery progress from Firebase
  Future<void> _loadProgressFromFirebase() async {
    final authProvider = context.read<AuthProvider>();
    final deliveryBoyId = authProvider.currentDeliveryBoy?.id;

    if (deliveryBoyId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final progress = await _firebaseService.getDeliveryProgress(deliveryBoyId);

    if (progress != null) {
      final currentStep = progress['current_step'] as int? ?? 0;
      final statusStrings = (progress['step_statuses'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();

      if (statusStrings != null &&
          statusStrings.length == _stepStatuses.length) {
        setState(() {
          _currentStep = currentStep;
          _stepStatuses = statusStrings.map((s) {
            switch (s) {
              case 'inProgress':
                return StepStatus.inProgress;
              case 'completed':
                return StepStatus.completed;
              default:
                return StepStatus.notStarted;
            }
          }).toList();
          _isLoading = false;
        });
        debugPrint(
            '✅ Loaded delivery progress: step $_currentStep, statuses: $statusStrings');
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  /// Save delivery progress to Firebase
  Future<void> _saveProgressToFirebase() async {
    final authProvider = context.read<AuthProvider>();
    final deliveryBoyId = authProvider.currentDeliveryBoy?.id;

    if (deliveryBoyId == null) return;

    final statusStrings = _stepStatuses.map((s) {
      switch (s) {
        case StepStatus.inProgress:
          return 'inProgress';
        case StepStatus.completed:
          return 'completed';
        default:
          return 'notStarted';
      }
    }).toList();

    await _firebaseService.updateDeliveryProgress(
      deliveryBoyId: deliveryBoyId,
      currentStep: _currentStep,
      stepStatuses: statusStrings,
    );
  }

  /// Scroll to the current step with smooth animation
  Future<void> _scrollToCurrentStep() async {
    // Add a small delay to ensure the widget is fully rendered
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted || _scrollController.positions.isEmpty) return;

    // Calculate the offset - each step card takes approximately 120 pixels + margins
    final double offset = _currentStep * 120.0;

    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final totalSteps =
        widget.order.sellersVisitOrder.length + 1; // sellers + customer

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : Column(
              children: [
                /// APP HEADER
                AppHeader(
                  label: 'DELIVERY',
                  title: 'Delivery Progress',
                  showBackButton: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatWithAdminScreen(
                                orderId: widget.order.orderId,
                              ),
                            ),
                          );
                        },
                        child: const CustomImageIcon(imagePath: AppImages.headPhone),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EmergencySupportScreen(),
                            ),
                          );
                        },
                        child: const CustomImageIcon(imagePath: AppImages.bulb),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),

                /// DIVIDER
                Container(
                  height: 1,
                  color: colorScheme.border.withValues(alpha: 0.3),
                ),

                /// DELIVERY STEPS LIST
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: Column(
                      children: List.generate(totalSteps, (index) {
                        final isLastStep = index == totalSteps - 1;
                        final isCurrentStep = index == _currentStep;
                        final isCompleted =
                            _stepStatuses[index] == StepStatus.completed;
                        final isInProgress =
                            _stepStatuses[index] == StepStatus.inProgress;

                        if (isLastStep) {
                          // Customer delivery step
                          return _buildCustomerStep(
                            colorScheme: colorScheme,
                            stepNumber: index + 1,
                            stepIndex: index,
                            isCurrentStep: isCurrentStep,
                            isCompleted: isCompleted,
                            isInProgress: isInProgress,
                            isLastStep: true,
                          );
                        } else {
                          // Seller pickup step
                          final seller = widget.order.sellersVisitOrder[index];
                          return _buildSellerStep(
                            colorScheme: colorScheme,
                            seller: seller,
                            stepNumber: index + 1,
                            stepIndex: index,
                            isCurrentStep: isCurrentStep,
                            isCompleted: isCompleted,
                            isInProgress: isInProgress,
                            isLastStep: false,
                            distanceKm: seller.distanceFromPreviousKm,
                            sellerAddress: seller.sellerAddress,
                          );
                        }
                      }),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Build seller pickup step
  Widget _buildSellerStep({
    required AppColorScheme colorScheme,
    required SellerVisit seller,
    required int stepNumber,
    required int stepIndex,
    required bool isCurrentStep,
    required bool isCompleted,
    required bool isInProgress,
    required bool isLastStep,
    required double distanceKm,
    required String sellerAddress,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// LEFT SIDE - Icon, bike, distance, and connecting line
        SizedBox(
          width: 80,
          child: Column(
            children: [
              /// Step icon
              _buildStepIcon(
                colorScheme: colorScheme,
                isCurrentStep: isCurrentStep,
                isCompleted: isCompleted,
                isInProgress: isInProgress,
                isCustomer: false,
              ),

              /// Bike icon (only for current step or in-progress step) - rotated 180 degrees to point down
              if (isCurrentStep || isInProgress) ...[
                const SizedBox(height: 4),
                Transform.rotate(
                  angle: 3.14159, // 180 degrees in radians
                  child: Image.asset(
                    AppImages.bikeMap,
                    width: 28,
                    height: 28,
                  ),
                ),
              ],

              /// Distance and connecting line
              if (!isLastStep) ...[
                const SizedBox(height: 8),
                Text(
                  '${distanceKm.toStringAsFixed(1)} km',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 2,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        isCompleted ? colorScheme.primary : colorScheme.border,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),

        /// RIGHT SIDE - Store details card
        Expanded(
          child: _buildStepCard(
            colorScheme: colorScheme,
            label: 'Store Name',
            name: seller.storeName,
            addressLabel: 'Store Address',
            address: sellerAddress,
            stepNumber: stepNumber,
            stepIndex: stepIndex,
            isCurrentStep: isCurrentStep,
            isCompleted: isCompleted,
            isInProgress: isInProgress,
            isCustomer: false,
            seller: seller,
          ),
        ),
      ],
    );
  }

  /// Build customer delivery step
  Widget _buildCustomerStep({
    required AppColorScheme colorScheme,
    required int stepNumber,
    required int stepIndex,
    required bool isCurrentStep,
    required bool isCompleted,
    required bool isInProgress,
    required bool isLastStep,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// LEFT SIDE - Icon
        SizedBox(
          width: 80,
          child: Column(
            children: [
              _buildStepIcon(
                colorScheme: colorScheme,
                isCurrentStep: isCurrentStep,
                isCompleted: isCompleted,
                isInProgress: isInProgress,
                isCustomer: true,
              ),

              /// Bike icon (only for current step or in-progress step) - rotated 180 degrees to point down
              if (isCurrentStep || isInProgress) ...[
                const SizedBox(height: 4),
                Transform.rotate(
                  angle: 3.14159, // 180 degrees in radians
                  child: Image.asset(
                    AppImages.bikeMap,
                    width: 28,
                    height: 28,
                  ),
                ),
              ],
            ],
          ),
        ),

        /// RIGHT SIDE - Customer details card
        Expanded(
          child: _buildStepCard(
            colorScheme: colorScheme,
            label: 'Customer',
            name: widget.order.customer.displayName,
            addressLabel: 'Customer Address',
            address: widget.order.customer.address,
            stepNumber: stepNumber,
            stepIndex: stepIndex,
            isCurrentStep: isCurrentStep,
            isCompleted: isCompleted,
            isInProgress: isInProgress,
            isCustomer: true,
            seller: null,
          ),
        ),
      ],
    );
  }

  /// Build step icon (circle with icon inside)
  Widget _buildStepIcon({
    required AppColorScheme colorScheme,
    required bool isCurrentStep,
    required bool isCompleted,
    required bool isInProgress,
    required bool isCustomer,
  }) {
    Color bgColor;
    Color iconColor;
    IconData icon;

    if (isCompleted) {
      bgColor = colorScheme.success;
      iconColor = Colors.white;
      icon = Icons.check;
    } else if (isCurrentStep || isInProgress) {
      bgColor = colorScheme.primary;
      iconColor = Colors.white;
      icon = isCustomer ? Icons.home_rounded : Icons.storefront_rounded;
    } else {
      bgColor = colorScheme.surfaceElevated;
      iconColor = colorScheme.textSecondary;
      icon = isCustomer ? Icons.home_rounded : Icons.storefront_rounded;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: (isCurrentStep || isInProgress)
              ? colorScheme.primary
              : colorScheme.border,
          width: 2,
        ),
        boxShadow: (isCurrentStep || isInProgress)
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 22,
      ),
    );
  }

  /// Build step card with details
  Widget _buildStepCard({
    required AppColorScheme colorScheme,
    required String label,
    required String name,
    required String addressLabel,
    required String address,
    required int stepNumber,
    required int stepIndex,
    required bool isCurrentStep,
    required bool isCompleted,
    required bool isInProgress,
    required bool isCustomer,
    required SellerVisit? seller,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isCurrentStep || isInProgress)
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.border.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Step number
          Text(
            '$stepNumber',
            style: GoogleFonts.inter(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: colorScheme.textTertiary.withValues(alpha: 0.3),
              height: 1,
            ),
          ),
          const SizedBox(width: 12),

          /// Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Label (smaller, secondary)
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textTertiary,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),

                /// Name (larger, primary, wrappable)
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.textPrimary,
                    letterSpacing: -0.3,
                    height: 1.03,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),

                /// Address label (smaller, tertiary)
                Text(
                  addressLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textTertiary,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),

                /// Address (wrappable)
                Text(
                  address,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textSecondary,
                    letterSpacing: -0.2,
                    height: 1.1,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          /// Start/View button
          if (!isCompleted)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (isInProgress) {
                  // View - open detail screen
                  _openDetailScreen(stepIndex, isCustomer, seller);
                } else if (isCurrentStep) {
                  // Start - mark as in progress and open detail screen
                  _handleStartStep(stepIndex, isCustomer, seller);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isInProgress
                      ? colorScheme.success
                      : isCurrentStep
                          ? colorScheme.primary
                          : colorScheme.textPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isInProgress ? 'View' : 'Start',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          /// Completed check
          if (isCompleted)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  /// Handle start step action - mark as in progress, save to Firebase, and open detail screen
  void _handleStartStep(int stepIndex, bool isCustomer, SellerVisit? seller) {
    setState(() {
      _stepStatuses[stepIndex] = StepStatus.inProgress;
      _currentStep = stepIndex;
    });
    // Save progress to Firebase so it persists
    _saveProgressToFirebase();

    // Update order status in Firebase
    _updateOrderStatus(isCustomer, seller);

    // Scroll to current step with animation
    _scrollToCurrentStep();
    _openDetailScreen(stepIndex, isCustomer, seller);
  }

  /// Update order status in Firebase when delivery partner starts delivery
  Future<void> _updateOrderStatus(bool isCustomer, SellerVisit? seller) async {
    final authProvider = context.read<AuthProvider>();
    final deliveryBoyId = authProvider.currentDeliveryBoy?.id;

    if (deliveryBoyId == null) {
      debugPrint('❌ Cannot update order status: Delivery boy ID is null');
      return;
    }

    String orderStatus = 'Partner Assigned';
    String orderStatusDesc = 'On the way';

    if (!isCustomer && seller != null) {
      // Pickup step - on the way to seller
      orderStatusDesc = 'On the way to ${seller.storeName}';
    } else {
      // Delivery step - on the way to customer; show the last visited
      // seller's name (customer step has no seller of its own).
      final lastSellerName = widget.order.sellersVisitOrder.isNotEmpty
          ? widget.order.sellersVisitOrder.last.storeName
          : null;
      orderStatus = lastSellerName != null
          ? 'Arriving from $lastSellerName'
          : 'Out for delivery';
      orderStatusDesc = 'On the way to customer';
    }

    // Update order_eta with delivery boy status fields
    await _firebaseService.updateOrderEtaWithDeliveryBoyStatus(
      orderId: widget.order.orderId,
      deliveryBoyId: deliveryBoyId,
      orderStatus: orderStatus,
      orderStatusDesc: orderStatusDesc,
      sellerName: !isCustomer ? seller?.storeName : null,
    );
  }

  /// Update order status after step completion based on next step type
  Future<void> _updateOrderStatusAfterCompletion({
    required int stepIndex,
    required bool isCustomer,
    required SellerVisit? seller,
    required int totalSteps,
  }) async {
    final authProvider = context.read<AuthProvider>();
    final deliveryBoyId = authProvider.currentDeliveryBoy?.id;

    if (deliveryBoyId == null) {
      debugPrint('❌ Cannot update order status: Delivery boy ID is null');
      return;
    }

    // Determine if we're at a pickup step or moving to next pickup or customer
    if (!isCustomer && seller != null) {
      // Just completed a pickup, check if there are more sellers
      final nextSellerIndex = stepIndex + 1;
      if (nextSellerIndex < widget.order.sellersVisitOrder.length) {
        // More sellers exist, heading to next seller
        final nextSeller = widget.order.sellersVisitOrder[nextSellerIndex];
        await _firebaseService.updateOrderStatusHeadingTo(
          orderId: widget.order.orderId,
          deliveryBoyId: deliveryBoyId,
          fromSellerName: seller.storeName,
          toSellerName: nextSeller.storeName,
        );
      } else {
        // No more sellers, heading to customer
        await _firebaseService.updateOrderStatusHeadingToCustomer(
          orderId: widget.order.orderId,
          deliveryBoyId: deliveryBoyId,
          lastSellerName: seller.storeName,
        );
      }
    } else if (isCustomer) {
      // Just completed customer delivery - this is the final step
      // Status will be updated to checkout or delivered in the confirmation screen
      debugPrint('✅ Customer delivery completed');
    }
  }

  /// Open delivery detail screen
  void _openDetailScreen(int stepIndex, bool isCustomer, SellerVisit? seller) {
    final totalSteps = widget.order.sellersVisitOrder.length + 1;

    // Log the navigation parameters
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔄 _openDetailScreen() called');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📋 Navigation Parameters:');
    debugPrint('  • stepIndex: $stepIndex');
    debugPrint('  • isCustomer: $isCustomer');
    debugPrint('  • totalSteps: $totalSteps');
    if (!isCustomer && seller != null) {
      debugPrint('  • seller.sellerId: ${seller.sellerId}');
      debugPrint('  • seller.storeName: ${seller.storeName}');
      debugPrint('  • seller.storeId: ${seller.storeId}');
    }
    debugPrint('═══════════════════════════════════════════════════════');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryDetailScreen(
          order: widget.order,
          currentStepIndex: stepIndex,
          totalSteps: totalSteps,
          stepType:
              isCustomer ? DeliveryStepType.delivery : DeliveryStepType.pickup,
          seller: seller,
          onActionComplete: () {
            // Mark current step as completed and move to next
            setState(() {
              _stepStatuses[stepIndex] = StepStatus.completed;
              if (_currentStep == stepIndex && _currentStep < totalSteps - 1) {
                _currentStep++;
              }
            });
            // Save progress to Firebase
            _saveProgressToFirebase();

            // Update order status based on next step
            _updateOrderStatusAfterCompletion(
              stepIndex: stepIndex,
              isCustomer: isCustomer,
              seller: seller,
              totalSteps: totalSteps,
            );

            // Scroll to next step with animation after a short delay
            Future.delayed(const Duration(milliseconds: 200), () {
              _scrollToCurrentStep();
            });
          },
        ),
      ),
    );
  }
}
