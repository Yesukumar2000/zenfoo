import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/helper/generalWidgets/catalogue_image.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/category_groups.dart';
import 'package:project/models/home_models.dart';
import 'package:project/models/store_with_category_group.dart';
import 'package:project/screens/categoryProducts/category_products_page.dart';
import 'package:project/screens/meatCategory/meat_category_screen.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

/// Fixed metrics for one category tile.
///
/// The tile is a fixed stack — 70dp image, gap, a two-line name — so the grid
/// is sized with `mainAxisExtent` rather than `childAspectRatio`. A ratio ties
/// row height to screen width, which is what left ~50dp of dead space under
/// every row on wider phones.
class _Cell {
  static const double image = 70;
  static const double gapAfterImage = 8;

  static const double nameLineHeight = 1.2;
  static const int maxNameLines = 2;

  static double get nameFontSize => 12.sp;

  static TextStyle nameStyle(AppColorScheme colorScheme) => GoogleFonts.inter(
        color: colorScheme.textPrimary,
        fontSize: nameFontSize,
        fontWeight: FontWeight.w500,
        height: nameLineHeight,
        letterSpacing: -0.3,
      );

  /// Height reserved for the name. Every tile in a grid reserves the same
  /// number of lines so their labels share a baseline — but the grid only
  /// reserves a second line if one of its names actually needs it, otherwise
  /// a grid of short names ("Tomato", "Onion") pays for a line it never uses.
  static double nameBlock(int lines) =>
      (nameFontSize * nameLineHeight * lines).ceilToDouble();

  static double extent(int lines) => image + gapAfterImage + nameBlock(lines);

  /// Lines the longest [names] entry needs at [tileWidth]. Measured rather
  /// than guessed from character count, since the grid is 4 columns of ~80dp
  /// and wrapping depends on the actual glyphs.
  static int linesNeeded(
    List<String> names,
    double tileWidth,
    TextStyle style,
    TextDirection direction,
  ) {
    if (tileWidth <= 0) return maxNameLines;
    for (final name in names) {
      final painter = TextPainter(
        text: TextSpan(text: name, style: style),
        maxLines: maxNameLines,
        textDirection: direction,
        textAlign: TextAlign.center,
      )..layout(maxWidth: tileWidth);
      if (painter.computeLineMetrics().length > 1) return maxNameLines;
    }
    return 1;
  }
}

/// Vertical gap between tile rows. Horizontal stays tighter so the row still
/// reads as one group.
const double _rowSpacing = 20;
const double _columnSpacing = 8;
const int _columns = 4;

/// The 4-column tile grid every category section uses. It measures its own
/// labels first so the row height is exactly the content — no dead space, and
/// no wrapped name clipped.
class _TileGrid extends StatelessWidget {
  final List<String> names;
  final AppColorScheme colorScheme;
  final Widget Function(BuildContext context, int index, int nameLines)
      itemBuilder;

  const _TileGrid({
    required this.names,
    required this.colorScheme,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth =
            (constraints.maxWidth - _columnSpacing * (_columns - 1)) / _columns;
        final lines = _Cell.linesNeeded(
          names,
          tileWidth,
          _Cell.nameStyle(colorScheme),
          Directionality.of(context),
        );

        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: names.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _columns,
            crossAxisSpacing: _columnSpacing,
            mainAxisSpacing: _rowSpacing,
            mainAxisExtent: _Cell.extent(lines),
          ),
          itemBuilder: (ctx, idx) => itemBuilder(ctx, idx, lines),
        );
      },
    );
  }
}

/// Group headings ("Groceries & Kitchen") sit one step below the page's
/// section headings, and carry the same near-neutral tracking rather than the
/// -0.55 crush they had.
TextStyle _groupHeadingStyle(AppColorScheme colorScheme) => GoogleFonts.inter(
      color: colorScheme.textPrimary,
      fontSize: 16.sp,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.2,
    );

/// "See all" beside a group heading, opening the Categories tab.
///
/// The grid below it is not truncated — every subcategory in the group is
/// already on screen — so this is a route to the fuller Categories browser
/// (rail of groups, larger cards), not a reveal of hidden tiles. It reuses the
/// boxed-chevron treatment from the Combos and Buy-it-again headings so the
/// three "see more" controls on the home feed read as one control.
///
/// Currently unused — the call site below is commented out.
// ignore: unused_element
class _SeeAllButton extends StatelessWidget {
  final AppColorScheme colorScheme;

  /// Where this rail's "View All" goes. Without it the button only switched to
  /// the Categories tab, which dropped the customer somewhere unrelated to the
  /// rail they had just tapped.
  final VoidCallback? onTap;

  // ignore: unused_element_parameter
  const _SeeAllButton({required this.colorScheme, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!();
            return;
          }
          context.read<HomeMainScreenProvider>().selectBottomMenu(1);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                getTranslatedValue(context, 'view_all'),
                style: GoogleFonts.inter(
                  color: colorScheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  height: 1.15,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryGroupsList extends StatelessWidget {
  final List<CategoryGroup> groups;
  final StoreSeller? supermart;
  final bool isMeat;

  /// Home screen only: show whole rows and nothing else.
  ///
  /// The grid is four across, so a rail holding 5, 9 or 10 tiles leaves three,
  /// three or two empty cells on its last row, which is what makes the home
  /// screen look unfinished. Eight or more shows eight, fewer than eight shows
  /// four, and a rail that cannot fill even one row is dropped. The full list
  /// is still there behind "View All" and on the Categories tab — this trims
  /// the display, not the data.
  final bool homeLimit;

  const CategoryGroupsList({
    required this.groups,
    this.supermart,
    this.isMeat = false,
    this.homeLimit = false,
    super.key,
  });

  /// The slice of a rail the home screen shows.
  List<T> _visible<T>(List<T> all) {
    if (!homeLimit) return all;
    return all.length >= 8 ? all.sublist(0, 8) : all.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    // Meat store: id==0 means Pre Order (backend convention) → old heading+grid style.
    // All other groups → flat 4-col grid that navigates to MeatCategoryScreen.
    if (isMeat) {
      final meatGroups = groups.where((g) => g.id != 0).toList();
      final preOrderGroups = groups.where((g) => g.id == 0).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meat groups — flat 4-col grid
          if (meatGroups.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: _TileGrid(
                names: meatGroups.map((g) => g.name).toList(),
                colorScheme: colorScheme,
                itemBuilder: (ctx, idx, lines) {
                  final group = meatGroups[idx];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    splashFactory: InkSplash.splashFactory,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MeatCategoryScreen(
                            group: group,
                            supermart: supermart,
                          ),
                        ),
                      );
                    },
                    child: _CategoryCell(
                      name: group.name,
                      imageUrl: group.imageUrl,
                      colorScheme: colorScheme,
                      nameLines: lines,
                    ),
                  );
                },
              ),
            ),

          // Pre Order groups — heading + 4-col sub-categories (old style)
          for (final group in preOrderGroups)
            if (!homeLimit || group.subCategoryGroups.length >= 4) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                group.name,
                style: _groupHeadingStyle(colorScheme),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _TileGrid(
                names: _visible(group.subCategoryGroups)
                    .map((s) => s.name)
                    .toList(),
                colorScheme: colorScheme,
                itemBuilder: (ctx, idx, lines) {
                  final sub = _visible(group.subCategoryGroups)[idx];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    splashFactory: InkSplash.splashFactory,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryProductScreen(
                            subCategoryGroupId: sub.id,
                            title: sub.name,
                            supermart: supermart,
                            siblingSubGroups: group.subCategoryGroups,
                          ),
                        ),
                      );
                    },
                    child: _CategoryCell(
                      name: sub.name,
                      imageUrl: sub.imageUrl,
                      colorScheme: colorScheme,
                      nameLines: lines,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      );
    }

    // Normal store: existing behaviour
    return ListView.builder(
      itemCount: groups.length,
      shrinkWrap: true,
      padding: EdgeInsets.all(0),
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (ctx, idx) {
        final group = groups[idx];
        final all = group.subCategoryGroups.isEmpty
            ? [
                SubCategoryGroup(
                  id: group.id,
                  name: group.name,
                  image: group.image,
                )
              ]
            : group.subCategoryGroups;

        // Cannot fill a row, so it would show one or two tiles and a gap.
        if (homeLimit && all.length < 4) {
          return const SizedBox.shrink();
        }

        final items = _visible(all);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      group.name,
                      style: _groupHeadingStyle(colorScheme),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // "View All" hidden on the group headings ("Groceries &
                  // Kitchen" and friends). Kept rather than deleted so it can
                  // be put back by uncommenting.
                  // _SeeAllButton(
                  //   colorScheme: colorScheme,
                  //   // Opens this rail's own category screen, with the FULL
                  //   // list as siblings so nothing trimmed off the home grid
                  //   // is unreachable.
                  //   onTap: () {
                  //     Navigator.push(context, MaterialPageRoute(builder: (_) {
                  //       return CategoryProductScreen(
                  //         subCategoryGroupId: all.first.id,
                  //         title: group.name,
                  //         supermart: supermart,
                  //         siblingSubGroups: all,
                  //         siblingGroups: groups,
                  //       );
                  //     }));
                  //   },
                  // ),
                ],
              ),
              12.verticalSpace,
              _TileGrid(
                names: items.map((i) => i.name).toList(),
                colorScheme: colorScheme,
                itemBuilder: (ctx, ind, lines) {
                  final item = items[ind];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    splashFactory: InkSplash.splashFactory,
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return CategoryProductScreen(
                          subCategoryGroupId: item.id,
                          title: item.name,
                          supermart: supermart,
                          siblingSubGroups: items,
                          siblingGroups: groups,
                        );
                      }));
                    },
                    child: _CategoryCell(
                      name: item.name,
                      imageUrl: item.imageUrl,
                      colorScheme: colorScheme,
                      nameLines: lines,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryCell extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final AppColorScheme colorScheme;

  /// Lines the label block reserves — shared by every tile in the grid so
  /// their labels line up. Decided by [_TileGrid] from the actual names.
  final int nameLines;

  const _CategoryCell(
      {required this.name,
      this.imageUrl,
      required this.colorScheme,
      required this.nameLines});

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _Cell.image,
            height: _Cell.image,
            // No `alignment`: with one, the Container hands the child loose
            // constraints and the image sizes to itself instead of filling.
            // Every group gets the same card. The shadow alone carried the
            // edge before, so a group that opted out of it (Fresh Meat) was
            // left as a bare image on a white page — hence the hairline
            // border, which holds the shape whatever the shadow is doing.
            decoration: ShapeDecoration(
              color: colorScheme.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
                side: BorderSide(color: colorScheme.border, width: 1),
              ),
              shadows: const [
                BoxShadow(
                  color: Color(0x23000000),
                  blurRadius: 17,
                  offset: Offset(0, 0),
                  spreadRadius: 0,
                )
              ],
            ),
            // The image fills the card rather than sitting in a fixed 58x58
            // box inside it. `contain` in that box rendered a landscape photo
            // at 58x43 — short, floating, and surrounded by dead space in a
            // tile only 70dp square to begin with, which is what made the
            // Prawns & Seafood row look like its pictures had collapsed.
            //
            // The blurred backdrop fills the corners without cropping, so the
            // whole subject still reads.
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: CatalogueImage(
                url: imageUrl,
                borderRadius: 0,
                fit: BoxFit.contain,
                fillBackdrop: true,
              ),
            ),
          ),
          SizedBox(height: _Cell.gapAfterImage),
          // Fixed-height label block: the text sits at the top of it, so a
          // one-line name lines up with the first line of a two-line one.
          SizedBox(
            height: _Cell.nameBlock(nameLines),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: _Cell.nameStyle(colorScheme),
              maxLines: nameLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
    );
  }
}

class HomeCategoryBlockGrid extends StatelessWidget {
  final List<HomeCategories> topCategories;

  const HomeCategoryBlockGrid({super.key, required this.topCategories});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    // Only categories with children
    final List<HomeCategories> parentCatsWithChildren = topCategories
        .where((cat) =>
            (cat.hasChild ?? false) &&
            (cat.catActiveChilds?.isNotEmpty ?? false))
        .toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: parentCatsWithChildren.length,
      itemBuilder: (ctx, idx) {
        final parent = parentCatsWithChildren[idx];
        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: 16.h,
            horizontal: 8.w,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Title
              Padding(
                padding: EdgeInsets.only(left: 8.w, bottom: 12.w),
                child: Text(
                  parent.name ?? '',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                    letterSpacing: -0.22,
                  ),
                ),
              ),
              // 4-column responsive grid for children
              LayoutBuilder(
                builder: (context, constraints) {
                  int colCount = 4;
                  double spacing = 8.w;
                  double itemWidth =
                      (constraints.maxWidth - (colCount - 1) * spacing) /
                          colCount;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: parent.catActiveChilds?.length ?? 0,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: colCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: 8.w,
                      childAspectRatio: .50, // Closely matches "compact" look
                    ),
                    itemBuilder: (context, ind) {
                      final sub = parent.catActiveChilds![ind];
                      return _CategoryGridCard(
                        child: sub,
                        cardWidth: itemWidth,
                        colorScheme: colorScheme,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryGridCard extends StatelessWidget {
  final CatActiveChilds child;
  final double cardWidth;
  final dynamic colorScheme;
  const _CategoryGridCard({
    required this.child,
    required this.cardWidth,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: cardWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Carded image
          Container(
            width: double.infinity,
            height: 110.h,
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 11.h),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13.r),
              boxShadow: colorScheme.cardShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: CachedNetworkImage(
                    imageUrl: child.imageUrl ?? '',
                    width: 64.w,
                    height: 72.h,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: const Color(0xFFE0E0E0),
                      highlightColor: const Color(0xFFF5F5F5),
                      child: Container(
                        width: 64.w,
                        height: 72.h,
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: cardWidth,
            child: Text(
              child.name ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                height: 1.12,
                letterSpacing: -0.55,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
