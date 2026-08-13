import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/helper/generalWidgets/widgets.dart';
import 'package:project/models/store_with_category_group.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/utils/generalMethods.dart';
import 'package:project/screens/categoryProducts/category_sweet_houses_screen.dart';

class StoreCategoriesHorizontal extends StatelessWidget {
  final List<StoreCategory> categories;
  final Function(StoreCategory)? onCategoryTap;

  const StoreCategoriesHorizontal({
    Key? key,
    required this.categories,
    this.onCategoryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            // vertical: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getTranslatedValue(context, 'what_are_you_thinking'),
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.4,
                ),
              ),
              GestureDetector(
                onTap: () => _showCategoriesBottomSheet(context, colorScheme),
                child: Container(
                  // padding: const EdgeInsets.symmetric(
                  //   horizontal: 8,
                  //   vertical: 6,
                  // ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'View All',
                    style: GoogleFonts.inter(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: categories.length >= 10 ? 10 : categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildCategoryCard(context, category, colorScheme),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
      BuildContext context, StoreCategory category, dynamic colorScheme) {
    return GestureDetector(
      onTap: () {
        onCategoryTap?.call(category);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategorySweetHousesScreen(
              category: category,
            ),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image with shadow and hover effect
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.border.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child:
                    category.imageUrl != null && category.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: category.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: const Color(0xFFE0E0E0),
                                highlightColor: const Color(0xFFF5F5F5),
                                child: Container(color: Colors.white),
                              ),
                              errorWidget: (context, url, error) => imgErrorWidget(icon: Icons.restaurant_menu_rounded, iconSize: 28),
                            ),
                          )
                        : Container(
                            color: colorScheme.surfaceVariant,
                            child: Icon(
                              Icons.fastfood_outlined,
                              size: 28,
                              color: colorScheme.iconSecondary,
                            ),
                          ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Name
          SizedBox(
            width: 90,
            child: Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoriesBottomSheet(BuildContext context, dynamic colorScheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        getTranslatedValue(context, 'what_are_you_thinking'),
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          color: colorScheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: colorScheme.border,
                  thickness: 1,
                ),
                // Grid
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          onCategoryTap?.call(category);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategorySweetHousesScreen(
                                category: category,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Image
                            Expanded(
                              flex: 2,
                              child: Container(
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                                child: category.imageUrl != null &&
                                        category.imageUrl!.isNotEmpty
                                    ? setNetworkImg(
                                        image: category.imageUrl!,
                                        boxFit: BoxFit.cover,
                                      )
                                    : Icon(
                                        Icons.fastfood_outlined,
                                        size: 28,
                                        color: colorScheme.iconDisabled,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Name
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: Text(
                                  category.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
