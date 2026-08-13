import 'package:flutter/material.dart';
import 'package:zenfoo_partner/utils/app_colors.dart';

class CustomLocationCard extends StatelessWidget {
  final String pickupText;
  final String dropText;
  final TextTheme text;

  final String? pickupLabel; // optional: "Pickup"
  final String? dropLabel; // optional: "Drop location"
  final String? pickupTime; // optional: "19 Nov, 05:30 AM"
  final String? dropTime; // optional: time
  final bool? isElevation;

  const CustomLocationCard({
    super.key,
    required this.pickupText,
    required this.dropText,
    required this.text,
    this.pickupLabel,
    this.dropLabel,
    this.pickupTime,
    this.dropTime,
    this.isElevation = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: !(isElevation ?? true)
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ---------------- LEFT SIDE DOTS ----------------
              Column(
                children: [
                  // Pickup Dot
                  Container(
                    height: 16,
                    width: 16,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Line

                  Container(
                    height:
                        (pickupLabel != null || pickupTime != null) ? 65 : 35,
                    width: 2,
                    color: Colors.black,
                  ),

                  const SizedBox(height: 4),

                  // Drop Dot
                  Container(
                    height: 16,
                    width: 16,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 14),

              // ---------------- RIGHT SIDE ----------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ========= PICKUP LABEL + TIME =========
                    if (pickupLabel != null || pickupTime != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (pickupLabel != null)
                            Text(
                              pickupLabel!,
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w700),
                              maxLines: 1,
                            ),
                          if (pickupTime != null)
                            Text(
                              pickupTime!,
                              style: text.bodySmall!.copyWith(
                                color: AppColors.grey,
                              ),
                              maxLines: 1,
                            ),
                        ],
                      ),

                    const SizedBox(height: 4),

                    // Pickup Text
                    Text(
                      pickupText,
                      style: text.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 10),

                    // Divider
                    Container(
                        height: 1,
                        width: double.infinity,
                        color: Colors.grey.shade300),

                    const SizedBox(height: 10),

                    // ========= DROP LABEL + TIME =========
                    if (dropLabel != null || dropTime != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (dropLabel != null)
                            Text(
                              dropLabel!,
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                            ),
                          if (dropTime != null)
                            Text(
                              dropTime!,
                              style: text.bodySmall!.copyWith(
                                color: AppColors.grey,
                              ),
                              maxLines: 1,
                            ),
                        ],
                      ),

                    const SizedBox(height: 4),

                    // Drop Text
                    Text(
                      dropText,
                      style: text.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
