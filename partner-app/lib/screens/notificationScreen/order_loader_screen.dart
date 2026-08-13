import 'package:flutter/material.dart';
import 'package:project/utils/order_number.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/new_order.dart' as new_order;
import 'package:project/repositories/newOrdersApi.dart';
import 'package:project/screens/ordersScreen/order_list_view.dart';
import 'package:project/screens/ordersScreen/order_details_screen.dart';
import 'package:project/screens/ordersScreen/seller_order_chat_screen.dart';

class OrderLoaderScreen extends StatefulWidget {
  final int orderId;

  const OrderLoaderScreen({super.key, required this.orderId});

  @override
  State<OrderLoaderScreen> createState() => _OrderLoaderScreenState();
}

class _OrderLoaderScreenState extends State<OrderLoaderScreen> {
  bool isLoading = true;
  String? errorMessage;
  new_order.OrderData? orderData;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
  }

  Future<void> _fetchOrder() async {
    try {
      final response = await getOrdersStatusTracking(
        params: {
          'order_id': widget.orderId.toString(),
        },
        context: context,
      );

      if (response[ApiAndParams.status].toString() == "1") {
        final orderResponse = new_order.NewOrderResponse.fromJson(response);
        if (orderResponse.data != null && orderResponse.data!.isNotEmpty) {
          setState(() {
            orderData = orderResponse.data!.first;
            isLoading = false;
          });
          _navigateToOrderDetails();
        } else {
          setState(() {
            errorMessage = 'Order not found';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = response[ApiAndParams.message] ?? 'Failed to load order';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading order: $e';
        isLoading = false;
      });
    }
  }

  void _navigateToOrderDetails() {
    if (orderData == null) return;

    final order = Order(
      orderData: orderData!,
      status: _getOrderStatus(orderData!.statusData?.code),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(
          order: order,
          onCall: () async {
            final phoneNumber = order.orderData.deliveryBoy is new_order.DeliveryBoy
                ? (order.orderData.deliveryBoy as new_order.DeliveryBoy).mobile
                : null;
            if (phoneNumber != null && phoneNumber.isNotEmpty) {
              try {
                final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not launch phone call')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Driver phone number not available')),
              );
            }
          },
          onChat: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SellerOrderChatScreen(
                  orderId: order.orderId ?? 0,
                  driverId: order.orderData.deliveryBoyId,
                  driverName: order.deliveryPerson.isNotEmpty
                      ? order.deliveryPerson
                      : 'Delivery Partner',
                ),
              ),
            );
          },
          onTimeChanged: (mins) {},
          onAdvance: () async {
            String newStatus = '';
            switch (order.status) {
              case OrderStatus.preparing:
                newStatus = 'packed_by_seller';
                break;
              case OrderStatus.readyForPickup:
                newStatus = 'packed_by_seller';
                break;
              default:
                return;
            }

            if (order.orderId != null) {
              final response = await updateTrackingStatus(
                orderId: order.orderId!,
                status: newStatus,
                context: context,
              );

              if (response['status'] == 1) {
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            }
          },
          onSubmitOtp: (code) async {
            if (order.orderId != null && code.length == 4) {
              final response = await verifyOtpAndUpdateStatus(
                orderId: order.orderId!,
                otp: code,
                context: context,
              );

              if (response['status'] == 1) {
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            }
          },
        ),
      ),
    );
  }

  OrderStatus _getOrderStatus(String? statusCode) {
    switch (statusCode?.toLowerCase()) {
      case 'awaiting_payment':
      case 'received':
      case 'processing':
      case 'preparing':
        return OrderStatus.preparing;
      case 'packed_by_seller':
      case 'ready':
      case 'ready_for_pickup':
        return OrderStatus.readyForPickup;
      case 'out_for_delivery':
      case 'shipped':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.preparing;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order ${formatOrderNumber(widget.orderId)}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : errorMessage != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });
                          _fetchOrder();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}
