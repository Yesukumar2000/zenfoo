import 'package:hugeicons/hugeicons.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/provider/combosProvider.dart';
import 'package:project/screens/categoryProducts/category_products_page.dart';

class CombosScreen extends StatefulWidget {
  const CombosScreen({Key? key}) : super(key: key);

  @override
  State<CombosScreen> createState() => _CombosScreenState();
}

class _CombosScreenState extends State<CombosScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {});
    });
    Future.microtask(() => context.read<CombosProvider>().fetchData(context));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;

        return Scaffold(
          backgroundColor: colorScheme.background,
          appBar: PreferredSize(
            preferredSize: Size(double.infinity, double.maxFinite),
            child: AppHeader(
              label: getTranslatedValue(context, 'deals_offers'),
              title: getTranslatedValue(context, 'combos_title'),
              showBackButton: true,
            ),
          ),
          body: Consumer<CombosProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  // Sticky Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.border,
                          width: 1,
                        ),
                        boxShadow: colorScheme.cardShadow,
                      ),
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedSearch01,
                            color: colorScheme.iconSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                provider.updateSearch(value, context);
                              },
                              decoration: InputDecoration(
                                hintText: getTranslatedValue(
                                    context, 'search_combos'),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                                hintStyle: GoogleFonts.inter(
                                  color: colorScheme.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.2,
                                  height: 1.3,
                                ),
                              ),
                              style: GoogleFonts.inter(
                                color: colorScheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.2,
                                height: 1.3,
                              ),
                              cursorColor: colorScheme.primary,
                            ),
                          ),
                          if (_searchController.text.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                provider.updateSearch('', context);
                              },
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedCancel01,
                                color: colorScheme.iconSecondary,
                                size: 20,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Sticky Filter Chip Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: FilterChipBar(
                      colorScheme: colorScheme,
                      filters: [
                        FilterChipData(
                          label: getTranslatedValue(context, 'sort_by'),
                          isSelected: provider.filterSort != 'latest',
                          onTap: () => _showUnifiedFilterSheet(
                              context, provider, colorScheme,
                              initialTab: 0),
                        ),
                        FilterChipData(
                          label: getTranslatedValue(context, 'type_filter'),
                          isSelected: provider.selectedComboTypeId != null,
                          onTap: () => _showUnifiedFilterSheet(
                              context, provider, colorScheme,
                              initialTab: 1),
                        ),
                        FilterChipData(
                          label: getTranslatedValue(context, 'price_filter'),
                          isSelected:
                              provider.priceRange.start > provider.minPrice ||
                                  provider.priceRange.end < provider.maxPrice,
                          onTap: () => _showUnifiedFilterSheet(
                              context, provider, colorScheme,
                              initialTab: 2),
                        ),
                        FilterChipData(
                          label: getTranslatedValue(context, 'items_filter'),
                          isSelected:
                              provider.countRange.start > provider.minCount ||
                                  provider.countRange.end < provider.maxCount,
                          onTap: () => _showUnifiedFilterSheet(
                              context, provider, colorScheme,
                              initialTab: 3),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (provider.state == CombosPageState.loading) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: colorScheme.primary,
                            ),
                          );
                        } else if (provider.state == CombosPageState.error) {
                          return Center(
                            child: Text(
                              getTranslatedValue(
                                  context, 'failed_to_load_combos'),
                              style: GoogleFonts.inter(
                                color: colorScheme.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        } else if (provider.state == CombosPageState.loaded &&
                            provider.combosData?.data != null) {
                          return ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            physics: const BouncingScrollPhysics(),
                            itemCount: provider.combosData!.data!.length,
                            itemBuilder: (context, index) {
                              final section = provider.combosData!.data![index];
                              if (section.combos == null ||
                                  section.combos!.isEmpty) {
                                return const SizedBox();
                              }
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: HorizontalComboSection(
                                  title: section.name ?? '',
                                  combos: section.combos!,
                                  onBookmark: (combo) async {
                                    // Toggle bookmark
                                    combo.isBookmarked = !(combo.isBookmarked ?? false);

                                    // Call API
                                    final result = await toggleComboBookmarkApi(
                                      context: context,
                                      comboId: combo.id!,
                                    );

                                    if (result != null && result['status'] == 1) {
                                      showMessage(
                                        context,
                                        result['message'] ?? 'Bookmark updated',
                                        MessageType.success,
                                      );
                                      // Refresh the combos list to update all cards
                                      context.read<CombosProvider>().fetchData(context);
                                    } else {
                                      // Revert the toggle if API call failed
                                      combo.isBookmarked = !(combo.isBookmarked ?? false);
                                      showMessage(
                                        context,
                                        result?['message'] ?? 'Failed to update bookmark',
                                        MessageType.error,
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showUnifiedFilterSheet(
    BuildContext context,
    CombosProvider provider,
    AppColorScheme colorScheme, {
    int initialTab = 0,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComboUnifiedFilterSheet(
        provider: provider,
        colorScheme: colorScheme,
        initialTabIndex: initialTab,
      ),
    ).then((_) {
      if (provider.state == CombosPageState.loaded) {
        provider.fetchData(context);
      }
    });
  }
}

// Filter Chip Bar (horizontal scrollable chips)
class FilterChipBar extends StatelessWidget {
  final AppColorScheme colorScheme;
  final List<FilterChipData> filters;

  const FilterChipBar({
    super.key,
    required this.colorScheme,
    required this.filters,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          return FilterChipButton(
            colorScheme: colorScheme,
            label: filter.label,
            isSelected: filter.isSelected,
            onTap: filter.onTap,
          );
        },
      ),
    );
  }
}

class FilterChipButton extends StatelessWidget {
  final AppColorScheme colorScheme;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterChipButton({
    super.key,
    required this.colorScheme,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected
                    ? colorScheme.buttonPrimaryText
                    : colorScheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.02,
                letterSpacing: -0.55,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isSelected
                  ? colorScheme.buttonPrimaryText
                  : colorScheme.iconSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// Unified Filter Bottom Sheet
class ComboUnifiedFilterSheet extends StatefulWidget {
  final CombosProvider provider;
  final AppColorScheme colorScheme;
  final int initialTabIndex;

  const ComboUnifiedFilterSheet({
    super.key,
    required this.provider,
    required this.colorScheme,
    required this.initialTabIndex,
  });

  @override
  State<ComboUnifiedFilterSheet> createState() =>
      _ComboUnifiedFilterSheetState();
}

class _ComboUnifiedFilterSheetState extends State<ComboUnifiedFilterSheet> {
  late int selectedTabIndex;
  late final List<String> filterTabs;

  @override
  void initState() {
    super.initState();
    selectedTabIndex = widget.initialTabIndex;
    filterTabs = [
      getTranslatedValue(context, 'sort_by'),
      getTranslatedValue(context, 'type_filter'),
      getTranslatedValue(context, 'price_filter'),
      getTranslatedValue(context, 'items_filter'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: widget.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeftSidebar(),
                  Expanded(child: _buildRightContent()),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: widget.colorScheme.border, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            getTranslatedValue(context, 'filters_title'),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: widget.colorScheme.textPrimary,
              letterSpacing: -0.55,
              height: 1.02,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 24,
              color: widget.colorScheme.iconPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar() {
    return Container(
      width: 100,
      color: widget.colorScheme.background,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: filterTabs.length,
        itemBuilder: (context, index) {
          final isSelected = selectedTabIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => selectedTabIndex = index);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? widget.colorScheme.surface
                    : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: isSelected
                        ? widget.colorScheme.primary
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                filterTabs[index],
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? widget.colorScheme.textPrimary
                      : widget.colorScheme.textSecondary,
                  letterSpacing: -0.55,
                  height: 1.02,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRightContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _getContentForTab(selectedTabIndex),
    );
  }

  Widget _getContentForTab(int index) {
    switch (index) {
      case 0:
        return _buildSortByContent();
      case 1:
        return _buildTypeContent();
      case 2:
        return _buildPriceContent();
      case 3:
        return _buildCountContent();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSortByContent() {
    final options = {
      'latest': getTranslatedValue(context, 'latest_label'),
      'oldest': getTranslatedValue(context, 'oldest_label'),
      'low_to_high': getTranslatedValue(context, 'price_low_to_high'),
      'high_to_low': getTranslatedValue(context, 'price_high_to_low'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslatedValue(context, 'sort_by_header'),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: widget.colorScheme.textSecondary,
            letterSpacing: -0.55,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 12),
        ...options.entries.map((e) {
          final isSelected = widget.provider.filterSort == e.key;
          return GestureDetector(
            onTap: () {
              widget.provider.updateSort(e.key, context);
              setState(() {});
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: widget.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.colorScheme.border,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.value,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: widget.colorScheme.textPrimary,
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? widget.colorScheme.primary
                            : widget.colorScheme.borderStrong,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.colorScheme.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTypeContent() {
    final types = widget.provider.combosData?.comboTypes ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslatedValue(context, 'type_header'),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: widget.colorScheme.textSecondary,
            letterSpacing: -0.55,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 12),
        ...types.map((type) {
          final isSelected =
              widget.provider.selectedComboTypeId == type.id.toString();
          return GestureDetector(
            onTap: () {
              widget.provider.updateComboType(
                  isSelected ? null : type.id.toString(), context);
              setState(() {});
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: widget.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.colorScheme.border,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      type.name ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: widget.colorScheme.textPrimary,
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? widget.colorScheme.primary
                          : widget.colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? widget.colorScheme.primary
                            : widget.colorScheme.borderStrong,
                        width: 1,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 14,
                            color: widget.colorScheme.buttonPrimaryText,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPriceContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslatedValue(context, 'price_header'),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: widget.colorScheme.textSecondary,
            letterSpacing: -0.55,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderThemeData(
            padding: const EdgeInsets.only(top: 16),
            trackHeight: 4,
            activeTrackColor: widget.colorScheme.primary,
            inactiveTrackColor: widget.colorScheme.border,
            thumbColor: widget.colorScheme.primary,
            overlayColor: widget.colorScheme.primary.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            rangeThumbShape:
                const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: RangeSlider(
            values: widget.provider.priceRange,
            min: widget.provider.minPrice,
            max: widget.provider.maxPrice,
            divisions: 100,
            onChanged: (values) {
              setState(() {});
              widget.provider.updatePriceRange(values, context);
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₹${widget.provider.priceRange.start.toInt()}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: widget.colorScheme.textPrimary,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
            Text(
              '₹${widget.provider.priceRange.end.toInt()}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: widget.colorScheme.textPrimary,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCountContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslatedValue(context, 'item_count_header'),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: widget.colorScheme.textSecondary,
            letterSpacing: -0.55,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderThemeData(
            padding: const EdgeInsets.only(top: 16),
            trackHeight: 4,
            activeTrackColor: widget.colorScheme.primary,
            inactiveTrackColor: widget.colorScheme.border,
            thumbColor: widget.colorScheme.primary,
            overlayColor: widget.colorScheme.primary.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            rangeThumbShape:
                const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: RangeSlider(
            values: widget.provider.countRange,
            min: widget.provider.minCount,
            max: widget.provider.maxCount,
            divisions: 20,
            onChanged: (values) {
              setState(() {});
              widget.provider.updateCountRange(values, context);
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              getTranslatedValue(context, 'items_range').replaceAll('{count}',
                  widget.provider.countRange.start.toInt().toString()),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: widget.colorScheme.textPrimary,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
            Text(
              getTranslatedValue(context, 'items_range').replaceAll(
                  '{count}', widget.provider.countRange.end.toInt().toString()),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: widget.colorScheme.textPrimary,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: widget.colorScheme.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.colorScheme.primary,
                foregroundColor: widget.colorScheme.buttonPrimaryText,
                minimumSize: const Size(double.infinity, 48),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                getTranslatedValue(context, 'apply_filters'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: widget.colorScheme.buttonPrimaryText,
                  letterSpacing: -0.55,
                  height: 1.02,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              widget.provider.clearFilters(context);
              Navigator.pop(context);
            },
            child: Text(
              getTranslatedValue(context, 'clear_filters'),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: widget.colorScheme.textSecondary,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
