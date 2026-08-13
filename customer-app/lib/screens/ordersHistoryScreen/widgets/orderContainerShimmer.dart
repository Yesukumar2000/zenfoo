import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class OrderContainerShimmer extends StatelessWidget {
  const OrderContainerShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colorScheme.cardShadowColor,
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID and Status shimmer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CustomShimmer(
                    height: 20,
                    width: 100,
                    borderRadius: 6,
                  ),
                  const CustomShimmer(
                    height: 28,
                    width: 80,
                    borderRadius: 8,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Divider
              Container(
                height: 1,
                color: colorScheme.border,
              ),
              const SizedBox(height: 16),

              // Store info shimmer
              const CustomShimmer(
                height: 64,
                width: double.infinity,
                borderRadius: 12,
              ),

              const SizedBox(height: 14),

              // First item shimmer
              Row(
                children: [
                  const CustomShimmer(
                    height: 40,
                    width: 40,
                    borderRadius: 10,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CustomShimmer(
                          height: 16,
                          width: double.infinity,
                          borderRadius: 6,
                        ),
                        const SizedBox(height: 6),
                        const CustomShimmer(
                          height: 14,
                          width: 120,
                          borderRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const CustomShimmer(
                    height: 20,
                    width: 60,
                    borderRadius: 6,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Total and Date shimmer
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const CustomShimmer(
                          height: 40,
                          width: 40,
                          borderRadius: 10,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CustomShimmer(
                                height: 14,
                                width: 60,
                                borderRadius: 6,
                              ),
                              const SizedBox(height: 4),
                              const CustomShimmer(
                                height: 18,
                                width: 80,
                                borderRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        const CustomShimmer(
                          height: 40,
                          width: 40,
                          borderRadius: 10,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CustomShimmer(
                                height: 14,
                                width: 60,
                                borderRadius: 6,
                              ),
                              const SizedBox(height: 4),
                              const CustomShimmer(
                                height: 14,
                                width: 70,
                                borderRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
