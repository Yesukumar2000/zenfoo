import 'package:flutter/material.dart';
import 'package:project/utils/order_number.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/new_order.dart' as new_order;

class OrderDetailScreen extends StatelessWidget {
  final new_order.OrderData order;

  const OrderDetailScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order ${formatOrderNumber(order.orderId)}'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Status Section
            _buildStatusSection(context),
            const SizedBox(height: 10),

            // Customer Details Section
            _buildCustomerSection(context),
            const SizedBox(height: 10),

            // Order Items Section
            _buildOrderItemsSection(context),
            const SizedBox(height: 10),

            // Billing Summary Section
            _buildBillingSummarySection(context),
            const SizedBox(height: 10),

            // Additional Info Section
            _buildAdditionalInfoSection(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorsRes.mainTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _getStatusColor(order.statusData?.code),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(order.statusData?.code),
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    order.statusData?.name ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (order.orderStatusHistory != null &&
              order.orderStatusHistory!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Status History',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorsRes.mainTextColor,
              ),
            ),
            const SizedBox(height: 8),
            ...order.orderStatusHistory!.map(
              (history) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ColorsRes.appColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        history.displayDateTime ?? history.createdAt ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: ColorsRes.subTitleTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorsRes.mainTextColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.person_outline,
            'Name',
            order.user?.name ?? order.cartMetadata?.cartInfo?.contactName ?? 'N/A',
          ),
          _buildInfoRow(
            Icons.phone_outlined,
            'Phone',
            order.user?.mobile ?? order.mobile ?? 'N/A',
          ),
          if (order.user?.email != null && order.user!.email!.isNotEmpty)
            _buildInfoRow(
              Icons.email_outlined,
              'Email',
              order.user!.email!,
            ),
          if (order.address != null && order.address!.isNotEmpty)
            _buildInfoRow(
              Icons.location_on_outlined,
              'Address',
              order.address!,
            ),
          if (order.cartMetadata?.cartInfo?.deliveryInstructions != null &&
              order.cartMetadata!.cartInfo!.deliveryInstructions!.isNotEmpty)
            _buildInfoRow(
              Icons.note_outlined,
              'Delivery Instructions',
              order.cartMetadata!.cartInfo!.deliveryInstructions!,
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorsRes.mainTextColor,
            ),
          ),
          const SizedBox(height: 12),
          if (order.items != null && order.items!.isNotEmpty)
            ...order.items!.map((item) => _buildOrderItem(item)),
          if (order.comboItems != null && order.comboItems!.isNotEmpty)
            ...order.comboItems!.map((combo) => _buildComboItem(combo)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(new_order.OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: ColorsRes.subTitleTextColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.productVariant?.product?.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.productVariant!.product!.imageUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: ColorsRes.subTitleTextColor.withOpacity(0.1),
                    child: Icon(
                      Icons.image_not_supported,
                      color: ColorsRes.subTitleTextColor,
                    ),
                  );
                },
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? 'Unknown Product',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorsRes.mainTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.variantName ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorsRes.subTitleTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity ?? 0}',
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorsRes.subTitleTextColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.price != item.discountedPrice && item.price != null)
                Text(
                  '₹${item.price}',
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorsRes.subTitleTextColor,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                '₹${item.discountedPrice ?? item.price ?? 0}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorsRes.mainTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComboItem(dynamic combo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: ColorsRes.appColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: ColorsRes.appColor.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Icon(
            Icons.restaurant_menu,
            color: ColorsRes.appColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Combo Item',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorsRes.mainTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingSummarySection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Billing Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorsRes.mainTextColor,
            ),
          ),
          const SizedBox(height: 12),
          if (order.billingBreakdown != null && order.billingBreakdown!.isNotEmpty)
            ...order.billingBreakdown!.map((breakdown) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        breakdown.label ?? '',
                        style: TextStyle(
                          fontSize: breakdown.isTotal == true ? 16 : 14,
                          fontWeight: breakdown.isTotal == true
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: breakdown.isTotal == true
                              ? ColorsRes.mainTextColor
                              : ColorsRes.subTitleTextColor,
                        ),
                      ),
                    ),
                    Text(
                      '${breakdown.isCredit == true ? '-' : ''}${breakdown.currency ?? '₹'}${breakdown.amount?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        fontSize: breakdown.isTotal == true ? 16 : 14,
                        fontWeight: breakdown.isTotal == true
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: breakdown.isTotal == true
                            ? ColorsRes.appColor
                            : breakdown.isCredit == true
                                ? Colors.green
                                : ColorsRes.mainTextColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Final Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorsRes.mainTextColor,
                ),
              ),
              Text(
                '₹${order.finalTotal?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ColorsRes.appColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorsRes.mainTextColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.payment,
            'Payment Method',
            order.paymentMethod ?? 'N/A',
          ),
          if (order.orderNote != null && order.orderNote!.isNotEmpty)
            _buildInfoRow(
              Icons.note,
              'Order Note',
              order.orderNote!,
            ),
          if (order.cartMetadata?.cartInfo?.deliveryTip != null)
            _buildInfoRow(
              Icons.tips_and_updates,
              'Delivery Tip',
              '₹${order.cartMetadata!.cartInfo!.deliveryTip}',
            ),
          _buildInfoRow(
            Icons.calendar_today,
            'Order Date',
            order.createdAt != null ? _formatDateTime(order.createdAt!) : 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: ColorsRes.subTitleTextColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorsRes.subTitleTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: ColorsRes.mainTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        return Colors.orange;
      case '2':
        return Colors.blue;
      case '3':
        return Colors.purple;
      case '4':
        return Colors.indigo;
      case '5':
        return Colors.teal;
      case '6':
        return Colors.green;
      case '7':
        return Colors.red;
      case '8':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? statusCode) {
    switch (statusCode) {
      case '1':
        return Icons.payment;
      case '2':
        return Icons.check_circle_outline;
      case '3':
        return Icons.sync;
      case '4':
        return Icons.local_shipping;
      case '5':
        return Icons.delivery_dining;
      case '6':
        return Icons.done_all;
      case '7':
        return Icons.cancel;
      case '8':
        return Icons.keyboard_return;
      default:
        return Icons.info_outline;
    }
  }
}
