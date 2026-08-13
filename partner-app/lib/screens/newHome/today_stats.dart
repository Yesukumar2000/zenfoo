import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/screens/newHome/food_dashboard_provider.dart';
import 'package:project/screens/newHome/order_earnings_screen.dart';
import 'package:project/screens/ordersScreen/orders_screen.dart';

class TodaysStatisticsGrid extends StatelessWidget {
  const TodaysStatisticsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Consumer<FoodDashboardProvider>(
          builder: (context, provider, _) {
            final overview = provider.overview;

            final stats = [
              StatGridItem(
                iconBg: const Color(0xFFEFF6FF),
                imageAsset: "assets/images/order_grid.png",
                label: getTranslatedValue(context, ordersLabel),
                value: '${overview?.todayOrders ?? 0}',
                filterType: 'orders',
                statusId: 0,
              ),
              StatGridItem(
                iconBg: const Color(0xFFFFF7ED),
                imageAsset: "assets/images/earning_grid.png",
                label: getTranslatedValue(context, earningsLabel),
                value: '₹${(overview?.earnings ?? 0).toStringAsFixed(2)}',
                filterType: 'earnings',
              ),
              StatGridItem(
                iconBg: const Color(0xFFF0FDF4),
                imageAsset: "assets/images/completed.png",
                label: getTranslatedValue(context, completedOrdersLabel),
                value: '${overview?.completedOrders ?? 0}',
                filterType: 'completed',
                statusId: 6,
              ),
              StatGridItem(
                iconBg: const Color(0xFFFEF2F2),
                imageAsset: "assets/images/cancelled.png",
                label: getTranslatedValue(context, cancelledOrderLabel),
                value: '${overview?.cancelledOrders ?? 0}',
                filterType: 'cancelled',
                statusId: 7,
              ),
              StatGridItem(
                iconBg: const Color(0xFFF8F2FF),
                imageAsset: "assets/images/return.png",
                label: getTranslatedValue(context, returnOrderLabel),
                value: '${overview?.returnedOrders ?? 0}',
                filterType: 'returned',
                statusId: 8,
              ),
            ];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTranslatedValue(context, todaysStatisticsLabel),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      height: 1.02,
                      letterSpacing: -0.55,
                      color: colorScheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: stats
                        .sublist(0, 2)
                        .map((item) => Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: StatCard(item: item),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: stats
                        .sublist(2, 5)
                        .map((item) => Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: StatCard(item: item),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class StatGridItem {
  final Color iconBg;
  final String imageAsset;
  final String label;
  final String value;
  final String? filterType;
  final int? statusId;

  StatGridItem({
    required this.iconBg,
    required this.imageAsset,
    required this.label,
    required this.value,
    this.filterType,
    this.statusId,
  });
}

class StatCard extends StatelessWidget {
  final StatGridItem item;
  const StatCard({required this.item, super.key});

  Color _getAccentColor() {
    // Extract a darker color from iconBg for accent
    if (item.iconBg == const Color(0xFFEFF6FF))
      return const Color(0xFF3B82F6); // Blue
    if (item.iconBg == const Color(0xFFFFF7ED))
      return const Color(0xFFF97316); // Orange
    if (item.iconBg == const Color(0xFFF0FDF4))
      return const Color(0xFF10B981); // Green
    if (item.iconBg == const Color(0xFFFEF2F2))
      return const Color(0xFFEF4444); // Red
    if (item.iconBg == const Color(0xFFF8F2FF))
      return const Color(0xFF8B5CF6); // Purple
    return const Color(0xFF3B82F6); // Default blue
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return InkWell(
      onTap: () {
        if (item.filterType == 'earnings') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderEarningsScreen(
                title: item.label,
                totalAmount: item.value,
                accentColor: _getAccentColor(),
                filterType: item.filterType,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrdersScreen(
                initialStatusId: item.statusId,
                filterToday: true,
              ),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: colorScheme.cardShadow,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.iconBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  item.imageAsset,
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.value,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colorScheme.textPrimary,
                letterSpacing: -0.55,
                height: 0.85,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.textSecondary,
                height: 1.22,
                letterSpacing: -0.55,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
