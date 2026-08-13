import 'package:flutter/material.dart';
import 'package:project/utils/order_number.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/new_order.dart' as new_order;

class NewOrderContainer extends StatelessWidget {
  final new_order.OrderData order;
  final VoidCallback? onTap;

  const NewOrderContainer({
    Key? key,
    required this.order,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: ColorsRes.subTitleTextColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorsRes.appColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order ${formatOrderNumber(order.orderId)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ColorsRes.mainTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.createdAt != null
                                ? _formatDateTime(order.createdAt!)
                                : '',
                            style: TextStyle(
                              fontSize: 12,
                              color: ColorsRes.subTitleTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.statusData?.code),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.statusData?.name ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Order Details
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Info
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 18,
                          color: ColorsRes.subTitleTextColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.user?.name ??
                            order.user?.mobile ??
                            order.mobile ??
                            'Guest User',
                            style: TextStyle(
                              fontSize: 14,
                              color: ColorsRes.mainTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Items Count
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 18,
                          color: ColorsRes.subTitleTextColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_getTotalItems()} ${_getTotalItems() == 1 ? 'item' : 'items'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: ColorsRes.mainTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Payment Method
                    Row(
                      children: [
                        Icon(
                          order.paymentMethod?.toUpperCase() == 'COD'
                              ? Icons.money
                              : Icons.payment,
                          size: 18,
                          color: ColorsRes.subTitleTextColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          order.paymentMethod ?? 'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            color: ColorsRes.mainTextColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Total Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 14,
                            color: ColorsRes.subTitleTextColor,
                          ),
                        ),
                        Text(
                          '₹${order.finalTotal?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColorsRes.appColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getTotalItems() {
    int itemCount = order.items?.fold<int>(
          0,
          (sum, item) => sum + (item.quantity ?? 0),
        ) ??
        0;

    int comboCount = order.comboItems?.length ?? 0;

    return itemCount + comboCount;
  }

  String _formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  Color _getStatusColor(String? statusCode) {
    switch (statusCode) {
      case '1':
        return Colors.orange; // Payment Pending
      case '2':
        return Colors.blue; // Received
      case '3':
        return Colors.purple; // Processed
      case '4':
        return Colors.indigo; // Shipped
      case '5':
        return Colors.teal; // Out For Delivery
      case '6':
        return Colors.green; // Delivered
      case '7':
        return Colors.red; // Cancelled
      case '8':
        return Colors.brown; // Returned
      default:
        return Colors.grey;
    }
  }
}
