import 'package:project/helper/styles/product_card_metrics.dart';
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/campaign_products_response.dart';
import 'package:project/provider/campaignProductsProvider.dart';
import 'package:project/provider/notesProvider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/screens/categoryProducts/widgets/product_card.dart';
import 'package:project/screens/notes/notesListScreen.dart';

class CampaignProductsScreen extends StatefulWidget {
  const CampaignProductsScreen({
    super.key,
    required this.campaign,
  });

  final Campaign campaign;

  @override
  State<CampaignProductsScreen> createState() => _CampaignProductsScreenState();
}

class _CampaignProductsScreenState extends State<CampaignProductsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  CampaignProductsProvider? _provider;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 220;
    if (_scrollController.position.pixels >= threshold) {
      _provider?.loadMore(context);
    }
  }

  void _handleSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      _provider?.updateSearch(context, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final campaignId = widget.campaign.id ?? 0;

    return ChangeNotifierProvider(
      create: (_) {
        _provider = CampaignProductsProvider(campaignId: campaignId)
          ..loadInitial(context);
        return _provider!;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
        backgroundColor: colorScheme.background,
        appBar: PreferredSize(
          preferredSize: const Size(double.infinity, kToolbarHeight + 36),
          child: AppHeader(
            label: getTranslatedValue(context, 'campaign'),
            title: widget.campaign.name?.trim().isNotEmpty == true
                ? widget.campaign.name!
                : getTranslatedValue(context, 'products'),
            showBackButton: true,
          ),
        ),
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              Column(
                children: [
                  _buildSearchBar(colorScheme),
                  Consumer<CampaignProductsProvider>(
                    builder: (context, provider, _) {
                      if (provider.categories.isEmpty) {
                        return const SizedBox(height: 8);
                      }

                      return _buildCategoryChips(
                        colorScheme: colorScheme,
                        categories: provider.categories,
                        selectedCategoryId: provider.selectedCategoryId,
                        onSelected: (categoryId) {
                          provider.selectCategory(context, categoryId);
                        },
                      );
                    },
                  ),
                  Expanded(
                    child: Consumer<CampaignProductsProvider>(
                      builder: (context, provider, _) {
                        return RefreshIndicator(
                          onRefresh: () => provider.refresh(context),
                          child: _buildBody(provider, colorScheme),
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (context.watch<CartProvider>().totalItemsCount > 0)
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: CartOverlay(),
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildBody(
    CampaignProductsProvider provider,
    AppColorScheme colorScheme,
  ) {
    if (provider.state == CampaignProductsState.loading) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 120),
          child: getProductListShimmer(context: context, isGrid: true),
        ),
      );
    }

    if (provider.state == CampaignProductsState.error) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        child: NoInternetConnectionScreen(
          height: context.height * 0.72,
          message: provider.message,
          callback: () {
            provider.loadInitial(context);
          },
        ),
      );
    }

    if (provider.state == CampaignProductsState.empty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        child: SizedBox(
          height: context.height * 0.72,
          child: DefaultBlankItemMessageScreen(
            title: emptyProductListMessageLabel,
            description: emptyProductListDescriptionLabel,
            image: "no_product_icon",
          ),
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          productGridPagePadding, 8, productGridPagePadding, 110),
      // Two columns, like every other product grid. At three the cell was
      // ~101dp wide and the card's own content — a two-line name, pack size,
      // price and an ADD button — had nowhere to go.
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: productGridGutter,
        crossAxisSpacing: productGridGutter,
        mainAxisExtent: productCardExtent,
      ),
      itemCount: provider.products.length + (provider.isLoadingMore ? 3 : 0),
      itemBuilder: (context, index) {
        if (index >= provider.products.length) {
          return _buildLoadingTile(colorScheme);
        }

        return MiniProductCardContainer(
          product: provider.products[index],
          disableHero: false,
        );
      },
    );
  }

  void _openVoiceSearch() {
    showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ChangeNotifierProvider<VoiceSearchProvider>(
        create: (_) => VoiceSearchProvider(),
        child: const SpeechToTextSearch(),
      ),
    ).then((value) {
      if (value != null && value.isNotEmpty) {
        _searchController.text = value;
        _handleSearchChanged(value);
        setState(() {});
      }
    });
  }

  Widget _buildSearchBar(AppColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.inputBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.inputBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Search field
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _handleSearchChanged,
                textInputAction: TextInputAction.search,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.textPrimary,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search for grocery items',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: colorScheme.inputPlaceholder,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colorScheme.iconSecondary,
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _handleSearchChanged('');
                            setState(() {});
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            color: colorScheme.iconSecondary,
                          ),
                        ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),

            // Mic button
            IconButton(
              onPressed: _openVoiceSearch,
              icon: Icon(
                Icons.mic_none_rounded,
                color: colorScheme.iconSecondary,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              constraints: const BoxConstraints(),
            ),

            // Vertical divider
            SizedBox(
              height: 22,
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: colorScheme.border,
              ),
            ),

            // Notes icon
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiProvider(
                      providers: [
                        ChangeNotifierProvider(
                          create: (context) => NotesProvider(),
                        ),
                      ],
                      child: const NotesListScreen(),
                    ),
                  ),
                );
              },
              icon: Icon(
                Icons.speaker_notes_outlined,
                color: colorScheme.iconSecondary,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips({
    required AppColorScheme colorScheme,
    required List<CampaignFilterCategory> categories,
    required int? selectedCategoryId,
    required ValueChanged<int?> onSelected,
  }) {
    final chips = <CampaignFilterCategory?>[null, ...categories];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = chips[index];
          final isAll = category == null;
          final isSelected = isAll
              ? selectedCategoryId == null
              : selectedCategoryId == category.id;

          final label = isAll
              ? 'All'
              : '${category.name} (${category.productCount})';

          return GestureDetector(
            onTap: () => onSelected(isAll ? null : category.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.border,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? colorScheme.buttonPrimaryText
                        : colorScheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingTile(AppColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
