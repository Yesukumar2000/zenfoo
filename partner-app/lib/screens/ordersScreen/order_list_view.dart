import 'package:flutter/material.dart';
import 'package:project/models/new_order.dart' as api;
import 'package:project/screens/ordersScreen/order_details_screen.dart';

enum OrderStatus {
  preparing,
  readyForPickup,
  otp,
  picked,
  outForDelivery,
  delivered,
  cancelled
}

// Simple Order wrapper that uses API models directly
class Order {
  final api.OrderData orderData;
  final OrderStatus status;
  final int minutes; // For local state management

  Order({
    required this.orderData,
    required this.status,
    this.minutes = 15,
  });

  // Convenience getters that delegate to orderData
  String get id => orderData.ordersId ?? orderData.orderId.toString();
  int? get orderId => orderData.orderId;

  // Get items directly from products array
  List<api.ProductDetail> get items => orderData.products ?? [];

  double get total => (orderData.finalTotal ?? 0).toDouble();
  double get commission => 0.0; // Calculate if needed
  double get payable =>
      (orderData.sellerTotal ?? orderData.finalTotal ?? 0).toDouble();
  String get instruction => orderData.orderNote ?? '';
  String get notes => orderData.notes ?? '';
  String? get dateString => orderData.createdAt;
  List<api.SettlementItem>? get settlementInfo => orderData.settlementInfo;

  // Delivery partner info
  String get deliveryPerson {
    final deliveryBoy = orderData.deliveryBoy;
    if (deliveryBoy is api.DeliveryBoy) {
      return deliveryBoy.name ?? '';
    }
    return '';
  }

  String get deliveryPersonSubtitle {
    final deliveryBoy = orderData.deliveryBoy;
    if (deliveryBoy is api.DeliveryBoy) {
      return deliveryBoy.mobile ?? 'Delivery Partner';
    }
    return 'Delivery Partner';
  }

  String? get deliveryPersonImage {
    final deliveryBoy = orderData.deliveryBoy;
    if (deliveryBoy is api.DeliveryBoy) {
      return deliveryBoy.imageUrl;
    }
    return null;
  }

  // Prep time info
  String? get prepTime => orderData.trackingInfo?.prepTime;
  String? get prepTimeString => orderData.trackingInfo?.prepTimeString;
  int? get prepTimeMinutes => orderData.trackingInfo?.prepTimeMinutes;

  // Calculate remaining minutes based on prep time
  int getRemainingMinutes() {
    if (prepTimeString == null || prepTimeMinutes == null) {
      return minutes;
    }

    try {
      // Parse the time string (e.g., "12:29 PM")
      final timeParts = prepTimeString!.split(' ');
      if (timeParts.length != 2) return minutes;

      final hourMin = timeParts[0].split(':');
      if (hourMin.length != 2) return minutes;

      int hour = int.parse(hourMin[0]);
      final minute = int.parse(hourMin[1]);
      final isPM = timeParts[1].toUpperCase() == 'PM';

      // Convert to 24-hour format
      if (isPM && hour != 12) {
        hour += 12;
      } else if (!isPM && hour == 12) {
        hour = 0;
      }

      // Create DateTime for prep start time (using today's date)
      final now = DateTime.now();
      final prepStartTime =
          DateTime(now.year, now.month, now.day, hour, minute);

      // Calculate end time
      final prepEndTime =
          prepStartTime.add(Duration(minutes: prepTimeMinutes!));

      // Calculate remaining time
      final remaining = prepEndTime.difference(now);

      if (remaining.isNegative) {
        return 0; // Time's up
      }

      return remaining.inMinutes;
    } catch (e) {
      return minutes;
    }
  }

  // Calculate remaining time in seconds
  Duration getRemainingDuration() {
    if (prepTimeString == null || prepTimeMinutes == null) {
      return Duration(minutes: minutes);
    }

    try {
      // Parse the time string (e.g., "12:29 PM")
      final timeParts = prepTimeString!.split(' ');
      if (timeParts.length != 2) return Duration(minutes: minutes);

      final hourMin = timeParts[0].split(':');
      if (hourMin.length != 2) return Duration(minutes: minutes);

      int hour = int.parse(hourMin[0]);
      final minute = int.parse(hourMin[1]);
      final isPM = timeParts[1].toUpperCase() == 'PM';

      // Convert to 24-hour format
      if (isPM && hour != 12) {
        hour += 12;
      } else if (!isPM && hour == 12) {
        hour = 0;
      }

      // Create DateTime for prep start time (using today's date)
      final now = DateTime.now();
      final prepStartTime =
          DateTime(now.year, now.month, now.day, hour, minute);

      // Calculate end time
      final prepEndTime =
          prepStartTime.add(Duration(minutes: prepTimeMinutes!));

      // Calculate remaining time
      final remaining = prepEndTime.difference(now);

      if (remaining.isNegative) {
        return Duration.zero;
      }

      return remaining;
    } catch (e) {
      return Duration(minutes: minutes);
    }
  }
}

class OrdersList extends StatefulWidget {
  final List<Order> orders;
  const OrdersList({super.key, required this.orders});
  @override
  State<OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends State<OrdersList> {
  late List<Order> _orders;
  @override
  void initState() {
    super.initState();
    _orders = widget.orders;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) => OrderCard(
        order: _orders[i],
        onTimeChanged: (mins) {
          setState(() =>
              _orders[i] = _orders[i].copyWith(minutes: mins.clamp(5, 120)));
        },
        onAdvance: () {
          setState(() => _orders[i] = _advanceStatus(_orders[i]));
        },
      ),
    );
  }

  Order _advanceStatus(Order order) {
    switch (order.status) {
      case OrderStatus.preparing:
        return order.copyWith(status: OrderStatus.readyForPickup);
      case OrderStatus.readyForPickup:
        return order.copyWith(status: OrderStatus.otp);
      case OrderStatus.otp:
        return order.copyWith(status: OrderStatus.picked);
      default:
        return order;
    }
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  final ValueChanged<int> onTimeChanged;
  final VoidCallback onAdvance;

  const OrderCard({
    required this.order,
    required this.onTimeChanged,
    required this.onAdvance,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(
              order: order, onCall: () {}, // handle call
              onChat: () {}, // handle chat
              onTimeChanged: (min) {}, // handle time changes
              onAdvance: () {}, // handle status advance
              onSubmitOtp: (code) {}, // handle OTP submit
            ),
          ),
        );
      },
      child: OrderDetailsScreen(
        order: order,
        onTimeChanged: (int value) {},
        onAdvance: () {},
        // onConfirmOtp: () {},
        onCall: () {},
        onChat: () {},
      ),
    );
  }
}

extension OrderCopy on Order {
  Order copyWith({
    OrderStatus? status,
    int? minutes,
  }) {
    return Order(
      orderData: orderData,
      status: status ?? this.status,
      minutes: minutes ?? this.minutes,
    );
  }
}
