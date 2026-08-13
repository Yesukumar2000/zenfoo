import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/screens/newHome/food_dashboard_provider.dart';

class ProductCategoryPieChart extends StatefulWidget {
  const ProductCategoryPieChart({super.key});

  @override
  State<ProductCategoryPieChart> createState() =>
      _ProductCategoryPieChartState();
}

class _ProductCategoryPieChartState extends State<ProductCategoryPieChart> {
  int touchedIndex = -1;

  // Predefined colors for categories
  final List<Color> categoryColors = [
    const Color(0xFFFF9F43), // Vibrant Orange
    const Color(0xFFFFD32A), // Warm Yellow
    const Color(0xFF0FB9B1), // Teal Green
    const Color(0xFF20BF6B), // Fresh Green
    const Color(0xFFEB3B5A), // Soft Red
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFF3B82F6), // Blue
    const Color(0xFFF97316), // Orange-Red
    const Color(0xFF10B981), // Green
    const Color(0xFFEF4444), // Red
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Consumer<FoodDashboardProvider>(
          builder: (context, provider, _) {
            final categoryWiseProducts = provider.categoryWiseProducts ?? [];

            // Convert API data to chart categories
            final categories = categoryWiseProducts.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              return _Category(
                category.categoryName ?? 'Unknown',
                category.productCount ?? 0,
                categoryColors[index % categoryColors.length],
              );
            }).toList();

            // If no data, show empty state
            if (categories.isEmpty) {
              return Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: colorScheme.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: colorScheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslatedValue(context, productCategoryCountLabel),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: colorScheme.textPrimary,
                        height: 1.02,
                        letterSpacing: -0.55,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        getTranslatedValue(context, noCategoriesAvailableLabel),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: colorScheme.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final total = categories.fold<int>(0, (sum, e) => sum + e.count);

            return Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: colorScheme.cardBackground,
                borderRadius: BorderRadius.circular(24),
                boxShadow: colorScheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        getTranslatedValue(context, productCategoryCountLabel),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: colorScheme.textPrimary,
                          height: 1.02,
                          letterSpacing: -0.55,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Pie Chart
                      Expanded(
                        flex: 5,
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Stack(
                            children: [
                              PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback:
                                        (FlTouchEvent event, pieTouchResponse) {
                                      setState(() {
                                        if (!event.isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection ==
                                                null) {
                                          touchedIndex = -1;
                                          return;
                                        }
                                        touchedIndex = pieTouchResponse
                                            .touchedSection!.touchedSectionIndex;
                                      });
                                    },
                                  ),
                                  startDegreeOffset: -90,
                                  sectionsSpace: 0,
                                  centerSpaceRadius: 45,
                                  sections: List.generate(categories.length, (i) {
                                    final isTouched = i == touchedIndex;
                                    final fontSize = isTouched ? 16.0 : 13.0;
                                    final radius = isTouched ? 60.0 : 50.0;
                                    final cat = categories[i];
                                    final percentage = (cat.count / total * 100)
                                        .toStringAsFixed(0);

                                    return PieChartSectionData(
                                      color: cat.color,
                                      value: cat.count.toDouble(),
                                      radius: radius,
                                      showTitle: true,
                                      title: '$percentage%',
                                      titleStyle: GoogleFonts.inter(
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1.02,
                                        letterSpacing: -0.55,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.2),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      borderSide: BorderSide(
                                        color: colorScheme.surface,
                                        width: 2,
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              // Inner text for total count
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      touchedIndex != -1
                                          ? categories[touchedIndex]
                                              .count
                                              .toString()
                                          : total.toString(),
                                      style: GoogleFonts.inter(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: colorScheme.textPrimary,
                                        height: 1.02,
                                        letterSpacing: -0.55,
                                      ),
                                    ),
                                    Text(
                                      touchedIndex != -1 ? "Items" : "Total",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.textTertiary,
                                        height: 1.02,
                                        letterSpacing: -0.55,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Legend
                      Expanded(
                        flex: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: categories.asMap().entries.map((entry) {
                            final index = entry.key;
                            final cat = entry.value;
                            final isTouched = index == touchedIndex;
                            final percentage =
                                (cat.count / total * 100).toStringAsFixed(1);

                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: touchedIndex == -1 || isTouched ? 1.0 : 0.3,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: _LegendItem(
                                  cat.name,
                                  count: cat.count,
                                  percentage: percentage,
                                  color: cat.color,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
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

class _Category {
  final String name;
  final int count;
  final Color color;
  _Category(this.name, this.count, this.color);
}

class _LegendItem extends StatelessWidget {
  final String label;
  final int count;
  final String percentage;
  final Color color;

  const _LegendItem(
    this.label, {
    required this.count,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 0.85,
                  letterSpacing: -0.55,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '$count items',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.textTertiary,
                  fontWeight: FontWeight.w500,
                  height: 1.02,
                  letterSpacing: -0.55,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
