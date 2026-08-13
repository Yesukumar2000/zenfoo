import 'package:project/helper/utils/generalImports.dart';


class OrderInformationWidget extends StatelessWidget {
  final Order order;

  OrderInformationWidget({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // OTP Section (if exists and not selfpickup)
        if (order.otp.toString() != "0" && order.otp.toString() != "null" && order.orderType != "selfpickup")
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextLabel(
                    jsonKey: orderOtpLabel,
                    softWrap: true,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.02,
                      letterSpacing: -0.55,
                      color: Color(0xFF757575),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF9AC444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: CustomTextLabel(
                    text: "${order.otp}",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.02,
                      letterSpacing: -0.55,
                      color: Color(0xFF9AC444),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Order Placed Date
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF9AC444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Color(0xFF9AC444),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextLabel(
                    jsonKey: orderPlacedOnLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 2),
                  CustomTextLabel(
                    text: order.date.toString().formatDate(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Track Order Button
        if (order.activeStatus.toString() != "1")
          TrackMyOrderButton(
            status: order.status ?? [],
          ),

        const SizedBox(height: 24),
      ],
    );
  }
}
