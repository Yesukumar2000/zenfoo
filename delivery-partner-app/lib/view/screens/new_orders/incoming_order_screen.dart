import 'package:flutter/material.dart';
import 'package:zenfoo_partner/utils/app_colors.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/utils/app_fonts.dart';
import 'package:zenfoo_partner/utils/app_images.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_gradient_appBar.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_gradient_scaffold.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_image_icon.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';

class IncomingOrderScreen extends StatelessWidget {
  const IncomingOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return CustomGradientScaffold(
      // appBar: SizedBox(),
      appBar: CustomGradientAppBar(
        titleWidget: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            "Sri krishna Sw...",
            style: textTheme.headlineSmall?.copyWith(fontFamily: AppFonts.bold),
          ),
        ),
        actions: const [
          CustomImageIcon(imagePath: AppImages.headPhone),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: CustomImageIcon(imagePath: AppImages.bulb),
          ),
        ],
      ),
      body: Column(
        children: [
          // const SizedBox(height: 8),
          // Row(
          //   children: [
          //     Padding(
          //       padding: const EdgeInsets.only(left: 10),
          //       child: Text(
          //         "Sri krishna Sw...",
          //         style: textTheme.headlineSmall
          //             ?.copyWith(fontFamily: AppFonts.bold),
          //       ),
          //     ),
          //    const CustomImageIcon(imagePath: AppImages.headPhone),
          //    const Padding(
          //       padding: EdgeInsets.symmetric(horizontal: 10),
          //       child: CustomImageIcon(imagePath: AppImages.bulb),
          //     ),
          //   ],
          // ),
          const SizedBox(height: 50),

          /// ================= MAP =================
          Expanded(
            child: Stack(
              children: [
                /// MAP PLACEHOLDER
                Container(
                  width: double.infinity,
                  color: AppColors.textFieldGrey,
                  child: const Center(
                    child: Text(
                      "MAP VIEW",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),

                /// REJECT BUTTON
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          "Reject",
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 6),
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.primaryColor,
                          child: Icon(
                            Icons.close,
                            size: 12,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// ================= ORDER CARD =================
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// MULTI ORDER
                Text(
                  "MULTI ORDER",
                  style:
                      textTheme.titleLarge?.copyWith(fontFamily: AppFonts.bold),
                ),

                const SizedBox(height: 8),

                /// PRICE ROW
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₹50",
                      style: textTheme.headlineMedium
                          ?.copyWith(fontFamily: AppFonts.bold),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "+ ₹20 Multi Order",
                      style: textTheme.titleMedium
                          ?.copyWith(fontFamily: AppFonts.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  "Total Distance 7.5 kms",
                  style: textTheme.bodyLarge,
                ),

                const SizedBox(height: 12),

                /// PICKUP LABEL
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Pickup location",
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// ADDRESS
                Text(
                  "Store Address",
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  "9-45/6/8, Suma apartments beside madhapur metro station, Madhapur, Hyderabad,500087",
                  style: textTheme.bodyMedium
                      ?.copyWith(fontFamily: AppFonts.semiBold),
                ),

                const SizedBox(height: 16),

                /// ACCEPT BUTTON
                CustomButton(
                  text: "Accept",
                  onPressed: () {},
                  height: 52,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ================= CIRCLE ICON =================
  Widget _circleIcon(IconData icon) {
    return Container(
      height: 36,
      width: 36,
      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18),
    );
  }
}
