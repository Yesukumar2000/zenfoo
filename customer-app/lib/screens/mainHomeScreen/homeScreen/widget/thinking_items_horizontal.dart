import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/store_with_category_group.dart';
import 'package:project/screens/categoryProducts/category_sweet_houses_screen.dart';

class ThinkingItemsHorizontal extends StatelessWidget {
  final List<ThinkingItem> items;
  final String? sectionTitle;

  const ThinkingItemsHorizontal({
    Key? key,
    required this.items,
    this.sectionTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final displayItems = items.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  sectionTitle ?? getTranslatedValue(context, 'what_are_you_thinking'),
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              if (items.length > 4)
                GestureDetector(
                  onTap: () => _showAllItemsBottomSheet(context, colorScheme),
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
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: displayItems.map((item) {
              return Expanded(
                child: _buildItemCard(context, item, colorScheme),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _navigateToCategory(BuildContext context, ThinkingItem item) {
    if (item.categoryId == null) return;
    HapticFeedback.lightImpact();

    final category = StoreCategory(
      id: item.categoryId!,
      name: item.category?.name ?? item.name ?? '',
      imageUrl: item.category?.imageUrl,
      categoryGroupId: 15,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategorySweetHousesScreen(category: category),
      ),
    );
  }

  Widget _buildItemCard(
      BuildContext context, ThinkingItem item, dynamic colorScheme) {
    return GestureDetector(
      onTap: () => _navigateToCategory(context, item),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
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
                child: item.imgUrl != null && item.imgUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: item.imgUrl!,
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
          SizedBox(
            width: 90,
            child: Text(
              item.name ?? '',
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

  void _showAllItemsBottomSheet(BuildContext context, dynamic colorScheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Size the sheet to the content instead of a fixed 60% of the screen.
        // With six items that left a large blank area under the last row.
        const crossAxisCount = 3;
        const aspectRatio = 0.85;
        const gridHPadding = 8.0;
        const gridVPadding = 16.0;
        const crossSpacing = 8.0;
        const mainSpacing = 16.0;
        const headerHeight = 62.0;

        final media = MediaQuery.of(context);
        final rows = (items.length / crossAxisCount).ceil();
        final tileWidth = (media.size.width -
                (gridHPadding * 2) -
                (crossSpacing * (crossAxisCount - 1))) /
            crossAxisCount;
        final tileHeight = tileWidth / aspectRatio;
        final contentHeight = headerHeight +
            (gridVPadding * 2) +
            (rows * tileHeight) +
            ((rows - 1).clamp(0, rows) * mainSpacing) +
            media.padding.bottom;

        final fraction =
            (contentHeight / media.size.height).clamp(0.32, 0.9).toDouble();

        return DraggableScrollableSheet(
          initialChildSize: fraction,
          minChildSize: (fraction - 0.12).clamp(0.25, fraction).toDouble(),
          maxChildSize: fraction >= 0.9 ? 0.9 : (fraction + 0.15).clamp(fraction, 0.9).toDouble(),
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        sectionTitle ?? getTranslatedValue(context, 'what_are_you_thinking'),
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
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToCategory(context, item);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: item.imgUrl != null &&
                                        item.imgUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: item.imgUrl!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        placeholder: (context, url) => Shimmer.fromColors(
                                          baseColor: const Color(0xFFE0E0E0),
                                          highlightColor: const Color(0xFFF5F5F5),
                                          child: Container(color: Colors.white),
                                        ),
                                        errorWidget: (context, url, error) => imgErrorWidget(icon: Icons.restaurant_menu_rounded, iconSize: 28),
                                      )
                                    : Icon(
                                        Icons.fastfood_outlined,
                                        size: 28,
                                        color: colorScheme.iconDisabled,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              flex: 1,
                              child: Text(
                                item.name ?? '',
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
