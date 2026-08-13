import 'package:project/helper/styles/product_card_metrics.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/provider/noteProductsProvider.dart';
import 'package:project/screens/categoryProducts/widgets/product_card.dart';

class NoteSearchScreen extends StatefulWidget {
  final List<String> notesList;

  const NoteSearchScreen({
    Key? key,
    required this.notesList,
  }) : super(key: key);

  @override
  State<NoteSearchScreen> createState() => _NoteSearchScreenState();
}

class _NoteSearchScreenState extends State<NoteSearchScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero).then((_) {
      context
          .read<NoteProductsProvider>()
          .getProductsBySelectedNotes(context: context);
    });
  }

  void _viewAllForNote(String noteText) {
    HapticFeedback.lightImpact();
    // Navigate to product search screen with the note text as search query
    Navigator.pushNamed(
      context,
      productSearchScreen,
      arguments: noteText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, double.maxFinite),
        child: AppHeader(
          label: getTranslatedValue(context, 'note_search_label'),
          title: getTranslatedValue(context, 'note_list_items_title'),
          showBackButton: true,
        ),
      ),
      body: Column(
        children: [
          // Content
          Expanded(
            child: Consumer<NoteProductsProvider>(
              builder: (context, noteProductsProvider, child) {
                // Loading state
                if (noteProductsProvider.state == NoteProductsState.loading &&
                    !noteProductsProvider.isDataLoaded) {
                  return _buildLoadingShimmer(colorScheme);
                }

                // Error state
                if (noteProductsProvider.state == NoteProductsState.error &&
                    !noteProductsProvider.isDataLoaded) {
                  return _buildErrorState(
                      colorScheme, noteProductsProvider.message);
                }

                // Get groups with products
                final groupsWithProducts =
                    noteProductsProvider.getGroupsWithProducts();

                // Empty state
                if (groupsWithProducts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: colorScheme.textSecondary
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            getTranslatedValue(context, 'no_matching_products'),
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.55,
                              height: 1.02,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            getTranslatedValue(context, 'adjust_notes_message'),
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary
                                  .withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.55,
                              height: 1.02,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Product groups list
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: groupsWithProducts.length,
                  itemBuilder: (context, groupIndex) {
                    final group = groupsWithProducts[groupIndex];
                    final products = group.products ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Note header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  group.noteText ?? '',
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.55,
                                    height: 1.02,
                                  ),
                                ),
                              ),
                              if (products.isNotEmpty)
                                GestureDetector(
                                  onTap: () =>
                                      _viewAllForNote(group.noteText ?? ''),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      getTranslatedValue(
                                          context, 'view_all_link'),
                                      style: GoogleFonts.inter(
                                        color: colorScheme.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.55,
                                        height: 1.02,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Horizontal list of products
                        if (products.isNotEmpty)
                          SizedBox(
                            height: productCardExtent,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: productGridPagePadding),
                              itemCount: products.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: productGridGutter),
                              itemBuilder: (context, productIndex) {
                                final product = products[productIndex];
                                return SizedBox(
                                  width: productRailCardWidth,
                                  child: MiniProductCardContainer(
                                    product: product,
                                    disableHero: true,
                                  ),
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 24),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: CartOverlay(),
      ),
    );
  }

  Widget _buildLoadingShimmer(colorScheme) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, categoryIndex) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomShimmer(
                    height: 20,
                    width: 150,
                    borderRadius: 8,
                  ),
                  CustomShimmer(
                    height: 20,
                    width: 60,
                    borderRadius: 8,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Horizontal product list shimmer
            SizedBox(
              height: 300,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 3,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 160,
                    child: CustomShimmer(
                      height: 300,
                      width: 160,
                      borderRadius: 12,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(colorScheme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              getTranslatedValue(context, 'failed_load_products_error'),
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.55,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context
                    .read<NoteProductsProvider>()
                    .getProductsBySelectedNotes(context: context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.buttonPrimaryText,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                getTranslatedValue(context, 'retry_button'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
