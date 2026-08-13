import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/styles/section_heading.dart';
import 'package:project/helper/styles/product_card_metrics.dart';
import 'package:project/screens/categoryProducts/widgets/product_card.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

/// Below this many products a grid looks broken — a 3-up grid holding one item
/// left two thirds of the row empty. A rail makes a short section look
/// deliberate, and matches how Combos and Buy it again already present.
const int _minProductsForGrid = 4;

class HomeSectionsWidget extends StatelessWidget {
  final List<HomeSection> sections;

  const HomeSectionsWidget({
    Key? key,
    required this.sections,   
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const SizedBox.shrink();

    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Column(
      children: sections.map((section) {
        final products = section.products ?? [];
        if (products.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
              child: Text(
                section.name ?? '',
                style: sectionHeadingStyle(colorScheme.textPrimary),
              ),
            ),
            const SizedBox(height: 12),
            if (products.length < _minProductsForGrid)
              _ProductRail(products: products)
            else
              _ProductGrid(products: products),
            const SizedBox(height: 24),
          ],
        );
      }).toList(),
    );
  }
}

/// Short sections scroll sideways, so one or two products read as a deliberate
/// shortlist rather than a grid that failed to fill.
class _ProductRail extends StatelessWidget {
  final List<dynamic> products;

  const _ProductRail({required this.products});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: productCardExtent,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: productGridPagePadding),
        physics: const ClampingScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: productGridGutter),
        itemBuilder: (context, index) => SizedBox(
          width: productRailCardWidth,
          child: MiniProductCardContainer(
            product: products[index],
            disableHero: true,
          ),
        ),
      ),
    );
  }
}

/// Two columns, not three. At three the cell was ~124dp wide and had to carry
/// an image, name, pack size, price and a call to action — so every element
/// shrank and the row height ballooned to 281dp of mostly empty space.
class _ProductGrid extends StatelessWidget {
  final List<dynamic> products;

  const _ProductGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: productGridPagePadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: productGridGutter,
          crossAxisSpacing: productGridGutter,
          // Fixed row height for the same reason the category grids got one:
          // a ratio ties card height to screen width and leaves dead space.
          mainAxisExtent: productCardExtent,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return MiniProductCardContainer(
            product: products[index],
            disableHero: true,
          );
        },
      ),
    );
  }
}
