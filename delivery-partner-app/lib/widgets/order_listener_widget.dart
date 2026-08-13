import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/incoming_order_provider.dart';
import 'package:zenfoo_partner/providers/session_provider.dart';
import 'package:zenfoo_partner/view/dialogs/incoming_order_dialog.dart';

/// Widget that listens for new orders and shows popup dialog
/// This widget is always active in the widget tree but only shows dialogs when online
class OrderListenerWidget extends StatefulWidget {
  final Widget child;

  const OrderListenerWidget({
    super.key,
    required this.child,
  });

  @override
  State<OrderListenerWidget> createState() => _OrderListenerWidgetState();
}

class _OrderListenerWidgetState extends State<OrderListenerWidget>
    with WidgetsBindingObserver {
  bool _isListening = false;
  bool _isDialogShowing = false;
  bool _isDeliveryInProgress = false; // Track if delivery is currently in progress
  int? _currentOrderId;
  final Set<int> _shownOrderIds = {}; // Track all orders we've shown
  final Set<int> _acceptedOrderIds = {}; // Track orders that have been accepted (never show again)
  bool _hasInitialized = false;
  int? _lastProcessedOrderId; // Track last order we queued dialog for
  bool _isOrderEventDialogShowing = false; // Admin reassignment dialog

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes, don't reinitialize listener if already listening
    if (state == AppLifecycleState.resumed && _isListening) {
      debugPrint('📱 App resumed - listener already active, skipping reinit');
      return;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only check on first initialization
    if (!_hasInitialized) {
      _hasInitialized = true;
      _checkAndToggleListener();
    }
  }

  /// Pause incoming order listener (used when delivery is in progress)
  void pauseListening() {
    if (_isListening && !_isDeliveryInProgress) {
      setState(() {
        _isDeliveryInProgress = true;
      });
      debugPrint('⏸️ Pausing order listener - delivery in progress');
    }
  }

  /// Resume incoming order listener (used when delivery is completed)
  void resumeListening() {
    if (_isListening && _isDeliveryInProgress) {
      setState(() {
        _isDeliveryInProgress = false;
      });
      debugPrint('▶️ Resuming order listener - delivery completed');
    }
  }

  /// Mark an order as accepted (so it never shows dialog again)
  void markOrderAsAccepted(int orderId) {
    setState(() {
      _acceptedOrderIds.add(orderId);
      debugPrint('✅ Order $orderId marked as accepted - will never show dialog again');
    });
  }

  /// Check if driver is online and toggle Firebase listener accordingly
  void _checkAndToggleListener() {
    try {
      final sessionProvider = context.watch<SessionProvider>();
      final authProvider = context.watch<AuthProvider>();
      final orderProvider = context.watch<IncomingOrderProvider>();

      final isOnline = sessionProvider.isOnline;
      final deliveryBoyId = authProvider.currentDeliveryBoy?.id;

      debugPrint(
          '📡 Order listener check - isOnline: $isOnline, deliveryBoyId: $deliveryBoyId, _isListening: $_isListening');

      if (isOnline && deliveryBoyId != null && !_isListening) {
        // Driver went online - start listening
        debugPrint(
            '🟢 Driver is online. Starting order listener for delivery boy $deliveryBoyId...');
        orderProvider.startListening(deliveryBoyId);
        _isListening = true;
      } else if (!isOnline && _isListening) {
        // Driver went offline - stop listening
        debugPrint('🔴 Driver is offline. Stopping order listener...');
        orderProvider.stopListening();
        _isListening = false;
      }
    } catch (e) {
      debugPrint('❌ Error in _checkAndToggleListener: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<IncomingOrderProvider, SessionProvider, AuthProvider>(
      builder: (context, orderProvider, sessionProvider, authProvider, child) {
        final isOnline = sessionProvider.isOnline;
        final deliveryBoyId = authProvider.currentDeliveryBoy?.id;

        // Check if widget is actually visible in the widget tree
        final isContextValid = context.findRenderObject() != null;


        // Handle online/offline status changes
        if (isOnline && deliveryBoyId != null && !_isListening) {
          // Driver went online - start listening
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && isContextValid) {
              debugPrint(
                  '🟢 Driver is online. Starting order listener for delivery boy $deliveryBoyId...');
              orderProvider.startListening(deliveryBoyId);
              setState(() {
                _isListening = true;
                _shownOrderIds.clear();
                _lastProcessedOrderId = null; // Reset last processed order
                debugPrint('🧹 Cleared shown orders history and last processed order for new session');
              });
            }
          });
        } else if (!isOnline && _isListening) {
          // Driver went offline - stop listening
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && isContextValid) {
              debugPrint('🔴 Driver is offline. Stopping order listener...');
              orderProvider.stopListening();
              setState(() {
                _isListening = false;
                _isDialogShowing = false;
                _currentOrderId = null;
              });
            }
          });
        }

        // Show dialog when new orders arrive (only if not already showing)
        // Remove debug print - only log when there are actual orders to process

        // Clean up shown orders that no longer exist
        final beforeCleanup = _shownOrderIds.length;
        _shownOrderIds.removeWhere((orderId) =>
            !orderProvider.incomingOrders.any((order) => order.orderId == orderId));
        final afterCleanup = _shownOrderIds.length;

        // If orders were deleted and we were showing a dialog, force reset the dialog state
        if (beforeCleanup > afterCleanup && _isDialogShowing) {
          debugPrint('⚠️ Orders were deleted while showing dialog - resetting dialog state');
          // Check if current dialog order still exists
          if (_currentOrderId != null &&
              !orderProvider.incomingOrders
                  .any((order) => order.orderId == _currentOrderId)) {
            debugPrint('🔴 Current dialog order $_currentOrderId no longer exists - forcing reset');
            // Use addPostFrameCallback to defer setState call outside of build phase
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isDialogShowing = false;
                  _currentOrderId = null;
                });
              }
            });
          }
        }

        if (orderProvider.incomingOrders.isNotEmpty &&
            !_isDialogShowing &&
            _isListening &&
            !_isDeliveryInProgress &&
            isContextValid) {
          final firstOrder = orderProvider.incomingOrders.first;
          debugPrint('🎯 Found order ${firstOrder.orderId} - already shown: ${_shownOrderIds.contains(firstOrder.orderId)}, already accepted: ${_acceptedOrderIds.contains(firstOrder.orderId)}, lastProcessed: $_lastProcessedOrderId');

          // Show if this order hasn't been shown yet AND hasn't been accepted (even if it was before and deleted orders removed it)
          if (!_shownOrderIds.contains(firstOrder.orderId) && !_acceptedOrderIds.contains(firstOrder.orderId)) {
            // Mark this order as being processed to prevent multiple callbacks
            _lastProcessedOrderId = firstOrder.orderId;

            // Set dialog showing immediately to prevent race conditions
            _isDialogShowing = true;
            debugPrint('🔔 Preparing to show dialog for order ${firstOrder.orderId}');

            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Final checks before showing dialog
              if (!_shownOrderIds.contains(firstOrder.orderId) &&
                  mounted &&
                  isContextValid &&
                  context.findRenderObject() != null) {
                // Close any existing dialog before showing new one
                if (Navigator.of(context).canPop()) {
                  debugPrint('🔙 Closing previous bottom sheet dialog');
                  Navigator.of(context).pop();
                }
                debugPrint('✅ Showing dialog for order ${firstOrder.orderId}');
                _showOrderDialog(firstOrder);
              } else {
                // If we couldn't show the dialog, reset the flag
                debugPrint('⚠️ Could not show dialog - checks failed');
                if (mounted) {
                  setState(() {
                    _isDialogShowing = false;
                  });
                }
              }
            });
          }
        }

        // Support reassigned this order to another driver. The backend has
        // already cleared current_order, so the delivery screens the driver is
        // sitting on are showing an order that is no longer theirs - explain it
        // and take them back to home instead of letting it vanish silently.
        final orderEvent = orderProvider.pendingOrderEvent;

        if (orderEvent != null && !_isOrderEventDialogShowing && isContextValid) {
          _isOrderEventDialogShowing = true;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && context.findRenderObject() != null) {
              _showOrderEventDialog(orderEvent, deliveryBoyId);
            } else {
              _isOrderEventDialogShowing = false;
            }
          });
        }

        return widget.child;
      },
    );
  }

  /// Explain why an in-progress order disappeared, then return to home.
  Future<void> _showOrderEventDialog(
    Map<String, dynamic> event,
    int? deliveryBoyId,
  ) async {
    final title = event['title'] as String? ?? 'Order Reassigned';
    final message = event['message'] as String? ??
        'This order has been reassigned to another delivery partner by support. '
            'Please take a rest - contact support if you have any questions.';

    // Pop the manually-pushed delivery screens back to GoRouter's base route,
    // the same way delivery_success_screen returns home.
    Navigator.of(context).popUntil((route) => route.isFirst);

    // The driver is free again, so incoming-order dialogs must work as usual.
    _isDeliveryInProgress = false;

    if (!mounted) {
      _isOrderEventDialogShowing = false;
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.info_outline, size: 36),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Delete the event only after it has been shown, so an app kill mid-dialog
    // replays it rather than losing it.
    if (deliveryBoyId != null && mounted) {
      await context.read<IncomingOrderProvider>().consumeOrderEvent(deliveryBoyId);
    }

    if (mounted) {
      setState(() {
        _isOrderEventDialogShowing = false;
      });
    } else {
      _isOrderEventDialogShowing = false;
    }
  }

  /// Show incoming order dialog
  void _showOrderDialog(order) {
    // Mark current order ID and track it
    setState(() {
      _currentOrderId = order.orderId;
      _shownOrderIds.add(order.orderId); // Add to shown orders set
    });

    // Calculate dimensions here before showing the sheet to avoid multiple rebuilds
    final screenHeight = MediaQuery.of(context).size.height;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final dialogHeight = screenHeight - viewInsets.top - 24; // Subtract status bar and border radius

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext builderContext) {
        // Builder should only return the widget, not recalculate dimensions
        return SizedBox(
          height: dialogHeight,
          child: IncomingOrderDialog(order: order),
        );
      },
    ).then((result) {
      // Dialog closed - reset showing state
      setState(() {
        _isDialogShowing = false;
        _currentOrderId = null;
        _lastProcessedOrderId = null; // Reset so we can process new orders

        // Check if order was accepted
        if (result is Map && result['accepted'] == true) {
          final acceptedOrderId = result['orderId'] as int?;
          if (acceptedOrderId != null) {
            // Mark as accepted so it never shows again
            _acceptedOrderIds.add(acceptedOrderId);
            debugPrint('✅ Order $acceptedOrderId marked as accepted - will never show dialog again');
          }
        } else {
          // If dialog was just closed (not accepted), allow showing again
          _shownOrderIds.remove(order.orderId);
          debugPrint('🔄 Order ${order.orderId} removed from shown list - can be shown again if it reappears');
        }
      });
    });
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Stop listening when widget is disposed
    if (_isListening) {
      final orderProvider = context.read<IncomingOrderProvider>();
      orderProvider.stopListening();
    }
    super.dispose();
  }
}
