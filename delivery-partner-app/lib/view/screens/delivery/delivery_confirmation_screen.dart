import 'package:flutter/material.dart';
import 'package:zenfoo_partner/utils/order_number.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:zenfoo_partner/models/incoming_order_model.dart';
import 'package:zenfoo_partner/models/seller_order_details_model.dart';
import 'package:zenfoo_partner/models/order_summary_model.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/firebase_order_service.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/custom_widgets/vendor_wait_charge_timer.dart';
import 'package:zenfoo_partner/view/custom_widgets/image_picker_bottom_sheet.dart';
import 'package:zenfoo_partner/view/custom_widgets/shimmer_skeleton.dart';
import 'package:zenfoo_partner/view/screens/delivery/otp_verification_screen.dart';
import 'package:zenfoo_partner/view/screens/delivery/delivery_success_screen.dart';
import 'package:zenfoo_partner/view/screens/chat/order_chat_screen.dart';

enum DeliveryConfirmationType { pickup, delivery }

class DeliveryConfirmationScreen extends StatefulWidget {
  final IncomingOrder order;
  final DeliveryConfirmationType confirmationType;
  final String? sellerName;
  final String? customerName;
  final int? sellerId;
  final int? storeId;

  /// The stop being confirmed. Carries details the seller API cannot supply -
  /// notably the previous driver's phone on an emergency-change handoff stop.
  final SellerVisit? seller;
  final VoidCallback onConfirmationSuccess;

  const DeliveryConfirmationScreen({
    super.key,
    required this.order,
    required this.confirmationType,
    this.sellerName,
    this.customerName,
    this.sellerId,
    this.storeId,
    this.seller,
    required this.onConfirmationSuccess,
  });

  @override
  State<DeliveryConfirmationScreen> createState() =>
      _DeliveryConfirmationScreenState();
}

class _DeliveryConfirmationScreenState
    extends State<DeliveryConfirmationScreen> {
  bool _isConfirming = false;
  bool _isLoadingDetails = false;
  final List<File> _capturedImages = [];
  late IncomingOrder _orderData;
  SellerOrderDetails? _sellerOrderDetails;
  OrderSummary? _orderSummary;
  String? _errorMessage;
  String _enteredPin = ''; // PIN entered by customer to confirm delivery
  late FocusNode _pinFocusNode; // FocusNode for PIN input field
  bool _isPinVerified = false; // Track if PIN is verified with backend

  @override
  void initState() {
    super.initState();
    _pinFocusNode = FocusNode();
    _orderData = widget.order;

    // Clear any previous captured images from previous orders
    _capturedImages.clear();
    debugPrint(
        '🧹 Cleared previous captured images for new order ${widget.order.orderId}');

    // Log widget parameters
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔧 DeliveryConfirmationScreen.initState()');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📋 Widget Parameters:');
    debugPrint('  • confirmationType: ${widget.confirmationType}');
    debugPrint('  • sellerName: ${widget.sellerName}');
    debugPrint('  • sellerId: ${widget.sellerId}');
    debugPrint('  • storeId: ${widget.storeId}');
    debugPrint('  • order_id: ${widget.order.orderId}');
    debugPrint('═══════════════════════════════════════════════════════');

    // Fetch appropriate data based on confirmation type
    if (widget.confirmationType == DeliveryConfirmationType.pickup) {
      _fetchSellerOrderDetails();
    } else {
      // For customer delivery, fetch order summary
      _fetchOrderSummary();
    }
  }

  @override
  void dispose() {
    // Clear captured images when leaving the screen
    _capturedImages.clear();
    // Dispose FocusNode
    _pinFocusNode.dispose();
    debugPrint(
        '🧹 Disposed DeliveryConfirmationScreen - cleared captured images and FocusNode');
    super.dispose();
  }

  /// Fetch seller-specific order details from API
  Future<void> _fetchSellerOrderDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoadingDetails = true;
      _errorMessage = null;
    });

    try {
      // Use provided sellerId/storeId or get from first seller
      int? currentSellerId = widget.sellerId;
      int? currentStoreId = widget.storeId;

      // If sellerId not provided, try to get from first seller
      if (currentSellerId == null) {
        final firstSeller = _orderData.sellersVisitOrder.firstOrNull;
        if (firstSeller == null) {
          debugPrint('❌ No seller found in order');
          if (mounted) {
            setState(() {
              _isLoadingDetails = false;
            });
          }
          return;
        }
      }

      debugPrint(
          '📍 Fetching details for seller - sellerId: $currentSellerId, storeId: $currentStoreId');

      // Make API call to fetch seller order details using AppUrls
      final apiService = ApiService();

      // Get current location from device
      Position? currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
      } catch (e) {
        debugPrint('⚠️ Could not get current location: $e');
        // Use default location from order if available
        currentPosition = Position(
          latitude: _orderData.driver.latitude,
          longitude: _orderData.driver.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      final response = await apiService.get(
        AppUrls.getOrderSellerData,
        params: {
          'order_id': _orderData.orderId.toString(),
          if (currentSellerId != null) 'seller_id': currentSellerId.toString(),
          'latitude': currentPosition.latitude.toString(),
          'longitude': currentPosition.longitude.toString(),
        },
      );

      if (!mounted) return;

      if (response.status == ApiStatus.success && response.data != null) {
        final jsonData = response.data as Map<String, dynamic>;
        final responseModel = SellerOrderDetailsResponse.fromJson(jsonData);

        if (responseModel.status == 1) {
          setState(() {
            _sellerOrderDetails = responseModel.data;
            _isLoadingDetails = false;
            debugPrint('✅ Seller order details fetched successfully');
            debugPrint('📦 Items: ${_sellerOrderDetails!.items.length}');
            debugPrint('🔐 OTP: ${_sellerOrderDetails!.otp}');
            debugPrint('⏱️ Prep Time: ${_sellerOrderDetails!.prepTime}');
            debugPrint('📞 Phone: ${_sellerOrderDetails!.seller.phoneNumber}');
          });
        } else {
          setState(() {
            _errorMessage = responseModel.message;
            _isLoadingDetails = false;
          });
          debugPrint('❌ Error: $_errorMessage');
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to fetch order details';
          _isLoadingDetails = false;
        });
        Navigator.pop(context);

        debugPrint('❌ Error: ${response.message}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error fetching details: $e';
        _isLoadingDetails = false;
      });
      Navigator.pop(context);
      debugPrint('❌ Exception: $e');
    }
  }

  /// Fetch order summary for customer delivery
  Future<void> _fetchOrderSummary() async {
    if (!mounted) return;

    setState(() {
      _isLoadingDetails = true;
      _errorMessage = null;
    });

    try {
      debugPrint('📍 Fetching order summary for order: ${_orderData.orderId}');

      // Make API call to fetch order summary
      final apiService = ApiService();
      final response = await apiService.get(
        AppUrls.getOrderSummary,
        params: {
          'order_id': _orderData.orderId.toString(),
        },
      );

      if (!mounted) return;

      if (response.status == ApiStatus.success && response.data != null) {
        final jsonData = response.data as Map<String, dynamic>;
        final responseModel = OrderSummaryResponse.fromJson(jsonData);

        if (responseModel.status == 1) {
          setState(() {
            _orderSummary = responseModel.data;
            _isLoadingDetails = false;
            debugPrint('✅ Order summary fetched successfully');
            debugPrint('📦 Items: ${_orderSummary!.items.length}');
            debugPrint('💰 Total: ${_orderSummary!.totalPrice}');
            debugPrint('👤 Customer: ${_orderSummary!.customer.name}');
            debugPrint('📍 Address: ${_orderSummary!.customer.address}');
          });

          // Update Firebase with checkout status for delivery
          final authProvider = context.read<AuthProvider>();
          final deliveryBoyId = authProvider.currentDeliveryBoy?.id;

          if (deliveryBoyId != null) {
            final firebaseService = FirebaseOrderService();
            await firebaseService.updateOrderStatusCheckout(
              orderId: _orderData.orderId,
              deliveryBoyId: deliveryBoyId,
            );
          }
        } else {
          setState(() {
            _errorMessage = responseModel.message;
            _isLoadingDetails = false;
          });
          debugPrint('❌ Error: $_errorMessage');
        }
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to fetch order summary';
          _isLoadingDetails = false;
        });
        debugPrint('❌ Error: ${response.message}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error fetching order summary: $e';
        _isLoadingDetails = false;
      });
      debugPrint('❌ Exception: $e');
    }
  }

  /// Show image picker bottom sheet for camera and gallery options
  void _showImagePicker() {
    final isPickup = widget.confirmationType == DeliveryConfirmationType.pickup;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    ImagePickerBottomSheet.show(
      context: context,
      colorScheme: themeProvider.colorScheme,
      // During an active order, proof photos must be taken live — camera only,
      // no gallery, to prevent reusing existing images.
      cameraOnly: true,
      onImageSelected: (file) {
        setState(() {
          _capturedImages.add(file);
        });
        HapticFeedback.lightImpact();
        debugPrint('✅ Image picked: ${file.path}');
      },
      onPermissionDenied: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Permission denied. Please enable camera or gallery access in settings.'),
            duration: Duration(seconds: 3),
          ),
        );
      },
      title: isPickup ? 'Capture Item Photos' : 'Capture Delivery Photos',
    );
  }

  /// Remove image from list
  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
    HapticFeedback.lightImpact();
  }

  /// Call the seller
  Future<void> _callSeller() async {
    var phoneNumber = _sellerOrderDetails?.seller.phoneNumber;

    // A handoff stop (emergency driver change) has no seller record behind it,
    // so the API returns nothing - the previous driver's number rides on the
    // stop itself. Fallback only; normal seller stops are unaffected.
    if (phoneNumber == null || phoneNumber.isEmpty) {
      phoneNumber = widget.seller?.sellerPhoneNumber;
    }

    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.seller?.isHandoffPoint == true
              ? 'Driver phone number not available'
              : context.watch<LanguageProvider>().getTranslatedText('phone_number_not_available')),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        debugPrint('📞 Calling seller: $phoneNumber');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.watch<LanguageProvider>().getTranslatedText('could_not_launch_dialer')),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        debugPrint('❌ Could not launch: $uri');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      debugPrint('❌ Error calling seller: $e');
    }
  }

  /// Open in-app chat with seller
  Future<void> _openChat() async {
    try {
      final sellerDetails = _sellerOrderDetails;
      if (sellerDetails == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.watch<LanguageProvider>().getTranslatedText('seller_info_not_available')),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderChatScreen(
            orderId: _orderData.orderId,
            sellerId: sellerDetails.sellerId,
            sellerName: sellerDetails.seller.storeName,
            sellerType: 'seller',
          ),
        ),
      );
      debugPrint(
          '💬 Opening in-app chat with seller: ${sellerDetails.seller.storeName}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      debugPrint('❌ Error opening seller chat: $e');
    }
  }

  /// Open chat with seller (works for both pickup and delivery)
  Future<void> _openSellerChat() async {
    if (widget.confirmationType == DeliveryConfirmationType.pickup) {
      await _openChat();
    } else {
      // For delivery, chat with the customer
      await _openCustomerChat();
    }
  }

  /// Call customer
  Future<void> _callCustomer() async {
    final phoneNumber = _orderData.customer.mobile;
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.watch<LanguageProvider>().getTranslatedText('customer_phone_not_available')),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        debugPrint('📞 Calling customer: $phoneNumber');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.watch<LanguageProvider>().getTranslatedText('could_not_launch_dialer')),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        debugPrint('❌ Could not launch: $uri');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      debugPrint('❌ Error calling customer: $e');
    }
  }

  /// Open chat with customer
  Future<void> _openCustomerChat() async {
    try {
      // Open in-app chat with customer using OrderChatScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderChatScreen(
            orderId: _orderData.orderId,
            sellerId: _orderData.customer.id ??
                0, // Use customer ID as seller ID for chat
            sellerName: _orderData.customer.name,
            sellerType: 'customer',
          ),
        ),
      );
      debugPrint(
          '💬 Opening in-app chat with customer: ${_orderData.customer.name}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      debugPrint('❌ Error opening customer chat: $e');
    }
  }

  /// Confirm order - handles both pickup (mark-picked) and delivery flows

  /// Validate customer PIN for delivery confirmation (local check)
  bool _validateCustomerPin() {
    // Check if PIN was entered
    if (_enteredPin.isEmpty) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter the customer PIN'),
          backgroundColor: Colors.orange[600],
          duration: const Duration(seconds: 2),
        ),
      );
      debugPrint('⚠️ PIN validation failed: No PIN entered');
      return false;
    }

    // Check if PIN is 4 digits
    if (_enteredPin.length != 4) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PIN must be 4 digits'),
          backgroundColor: Colors.orange[600],
          duration: const Duration(seconds: 2),
        ),
      );
      debugPrint(
          '⚠️ PIN validation failed: PIN length is ${_enteredPin.length}, expected 4');
      return false;
    }

    // Get customer PIN from order summary
    final customerPin = _orderSummary?.customerPin;

    // If customer PIN is not available, allow delivery without PIN validation
    if (customerPin == null || customerPin.isEmpty) {
      debugPrint(
          '⚠️ Customer PIN not available in order summary - allowing delivery without PIN validation');
      return true;
    }

    // Validate entered PIN against customer PIN
    if (_enteredPin != customerPin) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(context.watch<LanguageProvider>().getTranslatedText('incorrect_pin')),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 3),
        ),
      );
      debugPrint(
          '❌ PIN validation failed: Entered "$_enteredPin" does not match expected "$customerPin"');
      return false;
    }

    // PIN is valid locally
    debugPrint('✅ Local PIN validation successful: Customer PIN verified');
    HapticFeedback.lightImpact();
    return true;
  }

  /// Verify customer PIN with backend API
  Future<bool> _verifyPinWithBackend(String pin) async {
    try {
      debugPrint('🔐 Verifying customer PIN with backend...');

      final apiService = ApiService();
      final response = await apiService.post(
        AppUrls.verifyDeliveryPin,
        data: {
          'order_id': _orderData.orderId,
          'delivery_pin': pin,
        },
        isToast: false,
      );

      debugPrint('📊 PIN Verification Response:');
      debugPrint('  • Status: ${response.status}');
      debugPrint('  • Message: ${response.message}');
      debugPrint('  • Data: ${response.data}');

      if (response.status == ApiStatus.success) {
        debugPrint('✅ PIN verified successfully with backend');
        return true;
      } else {
        debugPrint('❌ PIN verification failed: ${response.message}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error verifying PIN with backend: $e');
      // Fall back to local validation if API fails
      debugPrint('⚠️ Falling back to local PIN validation');
      return true;
    }
  }

  Future<void> _confirmOrder() async {
    final isPickup = widget.confirmationType == DeliveryConfirmationType.pickup;

    // For pickup: validate photos
    if (isPickup && _capturedImages.isEmpty) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.watch<LanguageProvider>().getTranslatedText('capture_at_least_one_photo')),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isConfirming = true;
    });

    try {
      HapticFeedback.mediumImpact();

      if (isPickup) {
        // PICKUP FLOW: Mark items as picked with photos
        await _confirmPickup();
      } else {
        // DELIVERY FLOW: Check if images are captured
        if (_capturedImages.isEmpty) {
          // No images - show error
          if (mounted) {
            setState(() {
              _isConfirming = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Please capture delivery images before confirming'),
                backgroundColor: Colors.red[600],
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        // Validate customer PIN for delivery
        if (!_validateCustomerPin()) {
          if (mounted) {
            setState(() {
              _isConfirming = false;
            });
          }
          return;
        }

        // Images captured and PIN validated - Check payment method
        final paymentMethod = _orderData.paymentMethod?.toLowerCase() ?? '';

        if (paymentMethod == 'cash' || paymentMethod == 'cod') {
          // CASH PAYMENT: Navigate to OTP verification screen to collect amount
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => OTPVerificationScreen(
                  order: _orderData,
                  paymentMode: 'cash',
                  totalAmount: _orderData.totalOrderValue,
                  deliveryImages: null, // File list is not used in OTP screen
                ),
              ),
            );
          }
        } else {
          // NON-CASH PAYMENT: Call mark-delivered API
          final deliveryData = await _markDelivered();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => DeliverySuccessScreen(
                  order: _orderData,
                  deliveryData: deliveryData,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error confirming order: $e');
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });

        // Extract error message from exception
        String errorMessage = 'Something went wrong. Please try again.';
        if (e is Exception) {
          final exceptionString = e.toString();
          // Remove 'Exception: ' prefix if present
          if (exceptionString.startsWith('Exception: ')) {
            errorMessage = exceptionString.replaceFirst('Exception: ', '');
          } else {
            errorMessage = exceptionString;
          }
        } else {
          errorMessage = e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Mark items as picked with photo upload
  Future<void> _confirmPickup() async {
    try {
      // Get current seller ID from widget parameter
      // This is passed when navigating to this screen from delivery_detail_screen
      int? currentSellerId = widget.sellerId;
      int? currentStoreId = widget.storeId;

      debugPrint(
          '📍 Seller info from widget: sellerId=$currentSellerId, storeId=$currentStoreId');

      // Log all API parameters
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📤 MARK-PICKED API REQUEST');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔗 Endpoint: /api/delivery-boy/orders/mark-picked');
      debugPrint('🔤 Method: POST (multipart/form-data)');
      debugPrint('');
      debugPrint('📋 Query Parameters:');
      debugPrint('  • order_id: ${_orderData.orderId}');
      debugPrint('  • seller_id: $currentSellerId');
      debugPrint('  • store_id: $currentStoreId');
      debugPrint('');
      debugPrint('🔍 Debug Info:');
      debugPrint('  • widget.sellerId: ${widget.sellerId}');
      debugPrint('  • widget.storeId: ${widget.storeId}');
      debugPrint(
          '  • All sellers in order: ${_orderData.sellersVisitOrder.map((s) => "id=${s.sellerId},store=${s.storeId}").join(" | ")}');
      debugPrint('');
      debugPrint('📸 Images:');
      for (int i = 0; i < _capturedImages.length; i++) {
        final file = _capturedImages[i];
        final fileSizeKB = file.lengthSync() / 1024;
        debugPrint(
            '  • Image ${i + 1}: ${file.path} (${fileSizeKB.toStringAsFixed(2)} KB)');
      }
      debugPrint('  • Total images: ${_capturedImages.length}');
      debugPrint('');
      debugPrint('═══════════════════════════════════════════════════════');

      debugPrint('🔐 Headers:');
      debugPrint('  • Authorization: Bearer (managed by ApiService)');
      debugPrint('  • Accept: application/json');

      debugPrint('');
      debugPrint('🚀 Sending request via ApiService...');

      // Prepare files map for ApiService
      final files = <String, File>{};
      for (int i = 0; i < _capturedImages.length; i++) {
        files['images[$i]'] = File(_capturedImages[i].path);
      }

      // Use ApiService for the request
      final apiService = ApiService();
      final endpoint =
          '${AppUrl.baseUrl}/api/delivery-boy/orders/mark-picked?order_id=${_orderData.orderId}&store_id=$currentStoreId';

      final response = await apiService.post(
        endpoint,
        files: files,
        isToast: false, // Handle toasts manually for better control
      );

      debugPrint('');
      debugPrint('📊 API Response:');
      debugPrint('  • Status: ${response.status}');
      debugPrint('  • Message: ${response.message}');
      debugPrint('  • Data: ${response.data}');
      debugPrint('═══════════════════════════════════════════════════════');

      if (!mounted) return;

      if (response.status == ApiStatus.success) {
        debugPrint('✅ Order marked as picked successfully');

        // Update Firebase to mark first store as complete
        await _updateFirebaseStoreStatus();

        // Show success dialog with image
        if (mounted) {
          _showPickedSuccessDialog();
        }
      } else {
        throw Exception(response.message ?? 'Failed to mark order as picked');
      }
    } catch (e) {
      debugPrint('❌ Error in _confirmPickup: $e');
      rethrow;
    }
  }

  /// Show success dialog after order is picked
  void _showPickedSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success image
                Image.asset(
                  'assets/images/deliver.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green[700],
                        size: 80,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Success message
                Text(
                  'Order Picked Successfully',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Items collected and documented for delivery',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _navigateToProgress();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          context.watch<ThemeProvider>().colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Continue to Delivery',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Update Firebase to mark the first store as complete
  Future<void> _updateFirebaseStoreStatus() async {
    try {
      final firstSeller = _orderData.sellersVisitOrder.firstOrNull;
      if (firstSeller == null) return;

      debugPrint(
          '🔄 Updating Firebase: Marking store ${firstSeller.sellerId} as complete');

      // Get delivery boy ID from auth provider
      final authProvider = context.read<AuthProvider>();
      final deliveryBoyId = authProvider.currentDeliveryBoy?.id;

      if (deliveryBoyId == null) {
        debugPrint('⚠️ Could not get delivery boy ID for Firebase update');
        return;
      }

      // Calculate new step status
      // For pickup: Step 0 is completed, move to step 1
      final totalSteps = _orderData.sellersVisitOrder.length + 1;
      const currentStep = 1; // Move to next step (step 1)

      // Create step statuses: first one is completed, second one is in progress
      final List<String> stepStatuses = List.generate(totalSteps, (index) {
        if (index == 0) return 'completed';
        if (index == 1) return 'inProgress';
        return 'notStarted';
      });

      // Update Firebase delivery progress
      final firebaseService = FirebaseOrderService();
      await firebaseService.updateDeliveryProgress(
        deliveryBoyId: deliveryBoyId,
        currentStep: currentStep,
        stepStatuses: stepStatuses,
      );

      // Update order status for pickup
      final nextSeller = _orderData.sellersVisitOrder.length > 1
          ? _orderData.sellersVisitOrder[1]
          : null;

      await firebaseService.updateOrderStatusPickedUp(
        orderId: _orderData.orderId,
        deliveryBoyId: deliveryBoyId,
        sellerName: firstSeller.storeName,
        nextSellerName: nextSeller?.storeName,
      );

      debugPrint(
          '✅ Firebase update: Store ${firstSeller.storeName} marked as completed');
      debugPrint('📍 Current step: $currentStep, Step statuses: $stepStatuses');
      debugPrint(
          '🚗 Bike location ready to move to next store in delivery progress');
    } catch (e) {
      debugPrint('⚠️ Firebase update error (non-blocking): $e');
      // Don't throw - this is non-critical
    }
  }

  /// Navigate to progress screen and update firebase
  void _navigateToProgress() {
    if (!mounted) return;

    setState(() {
      _isConfirming = false;
    });

    // Call success callback which handles Firebase updates
    // This will:
    // 1. Mark first store as completed in order
    // 2. Update current store index
    // 3. Move bike icon to next store
    // 4. Update Firebase with new state
    widget.onConfirmationSuccess();

    // Navigate back to progress screen
    Navigator.pop(context);
  }

  /// Build full-screen image viewer
  Widget _buildFullScreenImage(BuildContext context, File imageFile) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(
            imageFile,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final isPickup = widget.confirmationType == DeliveryConfirmationType.pickup;
    final label = isPickup ? 'PICKUP' : 'DELIVERY';
    final title = isPickup ? 'Collect Order' : 'Deliver Order';

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// APP HEADER
          AppHeader(
            label: label,
            title: title,
            showBackButton: true,
            onBackPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            trailing: isPickup
                ? HugeIcon(
                    icon: HugeIcons.strokeRoundedStore01,
                    color: colorScheme.textPrimary,
                    size: 24,
                  )
                : HugeIcon(
                    icon: HugeIcons.strokeRoundedHome02,
                    color: colorScheme.textPrimary,
                    size: 24,
                  ),
          ),

          /// CONTENT
          Expanded(
            child: _isLoadingDetails
                ? ShimmerDeliveryConfirmation(
                    isPickup: isPickup,
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red[400],
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to Load Order Details',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: colorScheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _fetchSellerOrderDetails,
                              child: Text(
                                'Retry',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          // Dismiss PIN field focus when tapping outside
                          if (_pinFocusNode.hasFocus) {
                            _pinFocusNode.unfocus();
                            debugPrint(
                                '👆 Tapped outside PIN field - dismissed keyboard');
                          }
                        },
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Order ID and PIN Card (Performance Card Style)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: colorScheme.cardBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.cardBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order Information',
                                      style: GoogleFonts.inter(
                                        color: colorScheme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatItem(
                                            'Order ID',
                                            formatOrderNumber(_orderData.orderId),
                                            colorScheme,
                                          ),
                                        ),
                                        // Show OTP only for pickup orders
                                        if (widget.confirmationType ==
                                            DeliveryConfirmationType
                                                .pickup) ...[
                                          Container(
                                            width: 1,
                                            height: 50,
                                            color: colorScheme.border,
                                          ),
                                          Expanded(
                                            child: _buildStatItem(
                                              'PIN (OTP)',
                                              _sellerOrderDetails?.otp ?? 'N/A',
                                              colorScheme,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    // Show instruction message for pickup orders
                                    if (widget.confirmationType ==
                                        DeliveryConfirmationType.pickup) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.info
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: colorScheme.info
                                                .withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 18,
                                              color: colorScheme.info,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Share the OTP',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: colorScheme.info,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Visibility(
                                      visible: !isPickup,
                                      child: Divider(
                                        color: colorScheme.border,
                                        height: 1,
                                      ),
                                    ),
                                    Visibility(
                                      visible: !isPickup,
                                      child: const SizedBox(height: 16),
                                    ),
                                    Visibility(
                                      visible: !isPickup,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Payment Method',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            isPickup
                                                ? _orderData.orderType
                                                : _orderSummary?.paymentMode ??
                                                    'N/A',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Visibility(
                                      visible: !isPickup,
                                      child: const SizedBox(height: 12),
                                    ),
                                    Visibility(
                                      visible: !isPickup,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total Amount',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '₹${isPickup ? _orderData.totalOrderValue.toInt() : (_orderSummary?.totalPrice ?? 0)}',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Show PIN entry field only for customer delivery confirmation
                                    Visibility(
                                      visible: !isPickup,
                                      child: const SizedBox(height: 16),
                                    ),
                                    Visibility(
                                      visible: !isPickup,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Customer Delivery PIN',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.textSecondary,
                                              letterSpacing: -0.2,
                                              height: 1.02,
                                            ),
                                          ),
                                          Text(
                                            'Ask customer to enter their PIN to confirm delivery',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: colorScheme.textTertiary,
                                              letterSpacing: -0.15,
                                              height: 1.02,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Visibility(
                                      visible: !isPickup,
                                      child: const SizedBox(height: 10),
                                    ),
                                    Visibility(
                                      visible: !isPickup,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: GestureDetector(
                                          onTap: () {
                                            _pinFocusNode.requestFocus();
                                          },
                                          child: Pinput(
                                            focusNode: _pinFocusNode,
                                            length: 4,
                                            defaultPinTheme: PinTheme(
                                              width: 50,
                                              // height: 50,
                                              textStyle: GoogleFonts.inter(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 20,
                                                color: colorScheme.textPrimary,
                                                letterSpacing: -0.55,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: colorScheme.border,
                                                  width: 1.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color:
                                                    colorScheme.surfaceVariant,
                                              ),
                                            ),
                                            focusedPinTheme: PinTheme(
                                              width: 50,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                              // height: 50,
                                              textStyle: GoogleFonts.inter(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 20,
                                                color: colorScheme.textPrimary,
                                                letterSpacing: -0.55,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: colorScheme.primary,
                                                  width: 2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color:
                                                    colorScheme.surfaceVariant,
                                              ),
                                            ),
                                            submittedPinTheme: PinTheme(
                                              width: 50,
                                              // height: 50,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                              textStyle: GoogleFonts.inter(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 20,
                                                color: colorScheme.textPrimary,
                                                letterSpacing: -0.55,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: colorScheme.primary,
                                                  width: 2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color:
                                                    colorScheme.surfaceVariant,
                                              ),
                                            ),
                                            cursor: Align(
                                              alignment: Alignment.bottomCenter,
                                              child: Container(
                                                width: 2,
                                                height: 24,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                            onChanged: (String pin) {
                                              setState(() {
                                                _enteredPin = pin;
                                                // Reset verification status when PIN changes
                                                if (pin.length < 4) {
                                                  _isPinVerified = false;
                                                }
                                              });
                                            },
                                            onCompleted:
                                                (String completedPin) async {
                                              setState(() {
                                                _enteredPin = completedPin;
                                              });
                                              debugPrint(
                                                  '✅ Customer PIN entered: $completedPin');
                                              // Dismiss keyboard after PIN entry
                                              _pinFocusNode.unfocus();
                                              HapticFeedback.mediumImpact();

                                              // Verify PIN with backend API
                                              final isVerified =
                                                  await _verifyPinWithBackend(
                                                      completedPin);
                                              if (mounted) {
                                                setState(() {
                                                  _isPinVerified = isVerified;
                                                });
                                                if (!isVerified) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: const Text(
                                                          'PIN verification failed'),
                                                      backgroundColor:
                                                          Colors.red[600],
                                                      duration: const Duration(
                                                          seconds: 2),
                                                    ),
                                                  );
                                                } else {
                                                  // Show success feedback
                                                  HapticFeedback.heavyImpact();
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: const Text(
                                                          '✅ PIN Verified'),
                                                      backgroundColor:
                                                          Colors.green[600],
                                                      duration: const Duration(
                                                          seconds: 2),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // PIN Verification Status Indicator
                                    Visibility(
                                      visible:
                                          !isPickup && _enteredPin.isNotEmpty,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Row(
                                          children: [
                                            if (_isPinVerified)
                                              Icon(
                                                Icons.check_circle,
                                                color: colorScheme.success,
                                                size: 18,
                                              )
                                            else
                                              Icon(
                                                Icons.pending,
                                                color: colorScheme.warning,
                                                size: 18,
                                              ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _isPinVerified
                                                  ? 'PIN Verified ✓'
                                                  : 'Verifying PIN...',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: _isPinVerified
                                                    ? colorScheme.success
                                                    : colorScheme.warning,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              /// Seller Order Status Badge (pickup only)
                              if (isPickup && _sellerOrderDetails != null)
                                _buildSellerStatusBadge(
                                  _sellerOrderDetails!.status,
                                  colorScheme,
                                ),

                              /// Vendor Wait Charge Live Timer (pickup only)
                              if (isPickup && _sellerOrderDetails != null)
                                VendorWaitChargeTimer(
                                  details: _sellerOrderDetails!,
                                ),

                              /// Photo Capture Section
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: colorScheme.cardBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.cardBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Item Photos',
                                          style: GoogleFonts.inter(
                                            color: colorScheme.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${_capturedImages.length}',
                                          style: GoogleFonts.inter(
                                            color: colorScheme.primary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Document the items for order verification and record keeping',
                                      style: GoogleFonts.inter(
                                        color: colorScheme.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    /// Photo Grid
                                    if (_capturedImages.isNotEmpty)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3,
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 12,
                                              childAspectRatio: 0.45,
                                            ),
                                            itemCount: _capturedImages.length,
                                            itemBuilder: (context, index) {
                                              return Stack(
                                                children: [
                                                  /// Image Preview - Tappable
                                                  GestureDetector(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              _buildFullScreenImage(
                                                            context,
                                                            _capturedImages[
                                                                index],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: colorScheme
                                                            .cardBackground,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                          color: colorScheme
                                                              .border,
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        child: Image.file(
                                                          File(_capturedImages[
                                                                  index]
                                                              .path),
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  /// Delete button
                                                  Positioned(
                                                    top: 0,
                                                    right: 0,
                                                    child: GestureDetector(
                                                      onTap: () =>
                                                          _removeImage(index),
                                                      child: Container(
                                                        width: 28,
                                                        height: 28,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.red
                                                              .withValues(
                                                                  alpha: 0.9),
                                                          shape:
                                                              BoxShape.circle,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .black
                                                                  .withValues(
                                                                      alpha:
                                                                          0.2),
                                                              blurRadius: 4,
                                                              offset:
                                                                  const Offset(
                                                                      0, 2),
                                                            ),
                                                          ],
                                                        ),
                                                        child: const Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                      ),

                                    /// Add Photo Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: OutlinedButton.icon(
                                        onPressed: _showImagePicker,
                                        icon: HugeIcon(
                                          icon: HugeIcons.strokeRoundedCamera01,
                                          color: colorScheme.primary,
                                          size: 20,
                                        ),
                                        label: Text(
                                          'Capture Photo',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: colorScheme.primary,
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              /// Items Details Card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: colorScheme.cardBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.cardBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Items Details',
                                          style: GoogleFonts.inter(
                                            color: colorScheme.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Icon(
                                          Icons.expand_more,
                                          color: colorScheme.textSecondary,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Builder(
                                      builder: (context) {
                                        // Get items to display based on confirmation type
                                        final itemsToDisplay = widget
                                                    .confirmationType ==
                                                DeliveryConfirmationType.pickup
                                            ? (_sellerOrderDetails?.items ?? [])
                                            : _orderSummary?.items
                                                    .cast<dynamic>() ??
                                                [];

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${itemsToDisplay.length} ${itemsToDisplay.length == 1 ? 'Item' : 'Items'}',
                                              style: GoogleFonts.inter(
                                                color: colorScheme.textPrimary,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            if (itemsToDisplay.isEmpty)
                                              Text(
                                                'No items available',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      colorScheme.textSecondary,
                                                ),
                                              )
                                            else
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: List.generate(
                                                  itemsToDisplay.length,
                                                  (index) {
                                                    final item =
                                                        itemsToDisplay[index]
                                                            as dynamic;
                                                    return Padding(
                                                      padding: EdgeInsets.only(
                                                        bottom: index <
                                                                itemsToDisplay
                                                                        .length -
                                                                    1
                                                            ? 12
                                                            : 0,
                                                      ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        spacing: 4,
                                                        children: [
                                                          Text(
                                                            '${item.quantity}X ${item.itemName}',
                                                            style: GoogleFonts
                                                                .inter(
                                                              color: colorScheme
                                                                  .textPrimary,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              height: 1,
                                                              letterSpacing:
                                                                  -0.05,
                                                            ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          Text(
                                                            item.measurement,
                                                            style: GoogleFonts
                                                                .inter(
                                                              color: colorScheme
                                                                  .textSecondary,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              height: 1,
                                                              letterSpacing:
                                                                  -0.05,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              /// Store Details Section
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: colorScheme.cardBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.cardBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          isPickup
                                              ? 'Store Details'
                                              : 'Delivery Details',
                                          style: GoogleFonts.inter(
                                            color: colorScheme.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Icon(
                                          Icons.expand_more,
                                          color: colorScheme.textSecondary,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        /// Store/Customer Name Section
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isPickup
                                                  ? 'Store Name'
                                                  : 'Customer Name',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    colorScheme.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              isPickup
                                                  ? widget.sellerName ?? 'Store'
                                                  : widget.customerName ??
                                                      'Customer',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: colorScheme.textPrimary,
                                                height: 1.71,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        /// Address Section
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Address',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    colorScheme.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              isPickup
                                                  ? _sellerOrderDetails
                                                          ?.seller.address ??
                                                      'Store Address'
                                                  : _orderSummary
                                                          ?.customer.address ??
                                                      'Customer Address',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: colorScheme.textPrimary,
                                                height: 1.4,
                                                letterSpacing: -0.2,
                                              ),
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              /// Call and Chat buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: widget.confirmationType ==
                                              DeliveryConfirmationType.pickup
                                          ? _callSeller
                                          : _callCustomer,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        side: BorderSide(
                                          color: colorScheme.border,
                                          width: 1,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          HugeIcon(
                                            icon: HugeIcons.strokeRoundedCall,
                                            color: colorScheme.textPrimary,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            widget.confirmationType ==
                                                    DeliveryConfirmationType
                                                        .pickup
                                                ? ((widget.storeId == 12 ||
                                                        widget.storeId == 13)
                                                    ? 'Call'
                                                    : 'Call Seller')
                                                : 'Call Customer',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Hide "Chat with Seller" when picking up from a
                                  // Zenfoo store (store_id 12 or 13) — there is no
                                  // individual seller to chat with. Same for the
                                  // handoff stop of an emergency driver change:
                                  // the counterpart is the previous driver, who is
                                  // reachable by Call, not by the seller chat.
                                  if (!(widget.confirmationType ==
                                          DeliveryConfirmationType.pickup &&
                                      (widget.storeId == 12 ||
                                          widget.storeId == 13 ||
                                          widget.seller?.isHandoffPoint ==
                                              true))) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _openSellerChat,
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          side: BorderSide(
                                            color: colorScheme.border,
                                            width: 1,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            HugeIcon(
                                              icon: HugeIcons
                                                  .strokeRoundedMessage01,
                                              color: colorScheme.textPrimary,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              widget.confirmationType ==
                                                      DeliveryConfirmationType
                                                          .pickup
                                                  ? 'Chat with Seller'
                                                  : 'Chat with Customer',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
          ),

          /// Bottom action button
          Padding(
            padding: const EdgeInsets.all(16),
            child: _isLoadingDetails
                ? const ShimmerButtonSkeleton()
                : SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isConfirming ? null : _onButtonPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        disabledBackgroundColor:
                            colorScheme.primary.withValues(alpha: 0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isConfirming
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            )
                          : Text(
                              isPickup ? 'Order Picked' : _getButtonText(),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Build stat item for order ID and PIN display (matches performance card style)
  Widget _buildSellerStatusBadge(String status, AppColorScheme colorScheme) {
    final (label, accent, icon) = switch (status) {
      'assigned_to_seller' => (
          'Preparing the order',
          colorScheme.warning,
          Icons.restaurant_outlined,
        ),
      'packed_by_seller' => (
          'Packed by vendor',
          colorScheme.primary,
          Icons.inventory_2_outlined,
        ),
      'given_to_delivery_partner' => (
          'Handed to you',
          colorScheme.success,
          Icons.check_circle_outline,
        ),
      _ => (status, colorScheme.textSecondary, Icons.info_outline),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 8),
          Text(
            'Order status:',
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, AppColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: colorScheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Get button text based on payment mode for delivery
  String _getButtonText() {
    final isDelivery =
        widget.confirmationType == DeliveryConfirmationType.delivery;
    if (!isDelivery) return 'Order Delivered';

    final paymentMode = _orderSummary?.paymentMode ?? '';
    if (paymentMode.toUpperCase() == 'COD') {
      return 'Collect Cash';
    }
    return 'Order Delivered';
  }

  /// Handle button press - show payment sheet for COD or confirm order
  Future<void> _onButtonPressed() async {
    final isPickup = widget.confirmationType == DeliveryConfirmationType.pickup;

    if (isPickup) {
      // For pickup: validate photos and call mark-picked API
      _confirmOrder();
      return;
    }

    // Validate PIN and photo before proceeding
    if (_enteredPin.isEmpty || _enteredPin.length != 4) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_enteredPin.isEmpty
              ? 'Please enter the customer PIN'
              : 'PIN must be 4 digits'),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_capturedImages.isEmpty) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please capture delivery photo first'),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Images are selected and PIN validated - check payment mode
    final paymentMode = _orderSummary?.paymentMode ?? '';
    if (paymentMode.toUpperCase() == 'COD') {
      // Show payment mode selection sheet (QR or Cash)
      await _showPaymentModeSheet();
    } else {
      // For non-COD orders, proceed directly
      await _confirmOrder();
    }
  }

  /// Navigate to OTP/payment verification screen
  Future<void> _navigateToOTPScreen(String paymentMode) async {
    final totalAmount = _orderSummary != null
        ? _orderSummary!.totalPrice.toDouble()
        : _orderData.totalOrderValue;

    // Convert File list to XFile list for OTP screen
    final deliveryXFiles =
        _capturedImages.map((file) => XFile(file.path)).toList();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OTPVerificationScreen(
          order: _orderData,
          paymentMode: paymentMode,
          totalAmount: totalAmount,
          deliveryImages: deliveryXFiles.isNotEmpty ? deliveryXFiles : null,
        )
      )
    );
  }

  /// Show payment mode selection bottom sheet (for COD)
  Future<void> _showPaymentModeSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.only(
            top: 22,
            left: 17,
            right: 20,
            bottom: 44,
          ),
          decoration: const ShapeDecoration(
            color: Color(0xFFF3F4F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 14,
            children: [
              /// Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Choose Payment Mode',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 33.58,
                      height: 33,
                      decoration: const ShapeDecoration(
                        color: Color(0xFFE3E2E2),
                        shape: OvalBorder(),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),

              /// Payment Method Cards
              SizedBox(
                width: double.infinity,
                height: 180,
                child: Row(
                  spacing: 12,
                  children: [
                    /// QR Code Payment
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToOTPScreen('qr');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 15,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 93,
                                decoration: ShapeDecoration(
                                  image: const DecorationImage(
                                    image: AssetImage('assets/images/c1.png'),
                                    fit: BoxFit.cover,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 6,
                                children: [
                                  Text(
                                    'Show QR',
                                    style: GoogleFonts.inter(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Collect through qr',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF374151),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    /// Cash Payment
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(context);
                          await _navigateToOTPScreen('cash');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 15,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 92,
                                decoration: ShapeDecoration(
                                  image: const DecorationImage(
                                    image: AssetImage('assets/images/c2.png'),
                                    fit: BoxFit.cover,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 6,
                                children: [
                                  Text(
                                    'Collect Cash',
                                    style: GoogleFonts.inter(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Enter code to get Order',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF374151),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
      },
    );
  }

  /// Mark order as delivered (non-cash payment)
  Future<dynamic> _markDelivered() async {
    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('✅ MARK DELIVERED API REQUEST');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔗 Endpoint: /api/delivery-boy/orders/mark-delivered');
      debugPrint('🔤 Method: POST');
      debugPrint('');
      debugPrint('📋 Parameters:');
      debugPrint('  • order_id: ${_orderData.orderId}');
      debugPrint('  • images: ${_capturedImages.length} file(s)');
      debugPrint('');

      final apiService = ApiService();
      final endpoint =
          '${AppUrl.baseUrl}/api/delivery-boy/orders/mark-delivered?order_id=${_orderData.orderId}';

      // Prepare image files — all share 'images[]' key (same as Postman)
      List<MapEntry<String, File>>? multiFiles;
      if (_capturedImages.isNotEmpty) {
        multiFiles = _capturedImages.asMap().entries.map((e) {
          debugPrint('📸 Image ${e.key}: ${e.value.path}');
          return MapEntry('images[]', e.value);
        }).toList();
      }

      final response = await apiService.post(
        endpoint,
        multiFiles: multiFiles,
        isToast: false,
      );

      debugPrint('');
      debugPrint('📊 API Response:');
      debugPrint('  • Status: ${response.status}');
      debugPrint('  • Message: ${response.message}');
      debugPrint('  • Data: ${response.data}');
      debugPrint('═══════════════════════════════════════════════════════');

      if (response.status == ApiStatus.success) {
        debugPrint('✅ Order marked as delivered successfully');

        // Update Firebase with delivered status
        final authProvider = context.read<AuthProvider>();
        final deliveryBoyId = authProvider.currentDeliveryBoy?.id;

        if (deliveryBoyId != null) {
          final firebaseService = FirebaseOrderService();
          await firebaseService.updateOrderStatusDelivered(
            orderId: _orderData.orderId,
            deliveryBoyId: deliveryBoyId,
          );
        }

        return response.data;
      } else {
        throw Exception(response.message ?? 'Failed to mark delivery');
      }
    } catch (e) {
      debugPrint('❌ Error marking delivery: $e');
      rethrow;
    }
  }
}
