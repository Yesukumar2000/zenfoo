import 'dart:developer' as dev;

import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/models/store_with_category_group.dart';
import 'package:project/models/sortby_filter_model.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/screens/sweetHouseDetail/sweet_house_detail_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:velocity_x/velocity_x.dart';

class CategorySweetHousesScreen extends StatefulWidget {
  final StoreCategory category;

  const CategorySweetHousesScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategorySweetHousesScreen> createState() =>
      _CategorySweetHousesScreenState();
}

class _CategorySweetHousesScreenState extends State<CategorySweetHousesScreen> {
  late ScrollController scrollController;
  String _searchQuery = '';
  String? _selectedSort;
  String? _selectedBrand;
  bool _isVegSelected = false;
  bool _isNonVegSelected = false;
  bool _isSticked = false;

  // API data
  List<StoreSeller> sweetHouses = [];
  List<StoreSeller> filteredSweetHouses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(_onScroll);
    _loadSweetHouses();
  }

  void _onScroll() {
    final isSticked = scrollController.offset > 0;
    if (isSticked != _isSticked) {
      setState(() {
        _isSticked = isSticked;
      });
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSweetHouses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user location (default to a center point if not available)
      final latitude = Constant.session
          .getData(SessionManager.keyLatitude, defaultValue: "0.0");
      final longitude = Constant.session
          .getData(SessionManager.keyLongitude, defaultValue: "0.0");

      final Map<String, dynamic> params = {
        'category_id': widget.category.id.toString(),
        'lat': latitude,
        'lon': longitude,
        'sort_by': _selectedSort ?? 'name',
      };

      dev.log("Fetching Sweet Houses with params: $params");

      // Add search filter
      if (_searchQuery.isNotEmpty) {
        params['search'] = _searchQuery;
      }

      // Add food type filter
      if (_isVegSelected) {
        params['food_type'] = 'veg';
      } else if (_isNonVegSelected) {
        params['food_type'] = 'non_veg';
      }

      // Use categoryGroupId (which holds the store ID) for the path
      // When null, call cat_store without ID and let category_id param filter
      final String apiName = widget.category.categoryGroupId != null
          ? 'cat_store/${widget.category.categoryGroupId}'
          : 'cat_store';

      final response = await sendApiRequest(
        apiName: apiName,
        params: params,
        isPost: false,
        context: context,
      );

      if (response != null) {
        final decoded = json.decode(response);

        if (decoded['status'] == 1 && decoded['data'] != null) {
          final dataList = decoded['data'];

          final List<StoreSeller> newSellers = [];
          if (dataList is List && dataList.isNotEmpty) {
            final storeData = dataList[0];
            final sellersPagination = storeData['sellers_pagination'];
            if (sellersPagination != null && sellersPagination['data'] is List) {
              for (var seller in sellersPagination['data']) {
                newSellers.add(StoreSeller.fromJson(seller));
              }
            }
          }

          setState(() {
            sweetHouses = newSellers;
            _applyFiltersAndSort();
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      dev.log('Error loading sweet houses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    // Filter by search query
    filteredSweetHouses = sweetHouses.where((seller) {
      final nameMatch =
          seller.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false;
      final storeNameMatch = seller.storeName
              ?.toLowerCase()
              .contains(_searchQuery.toLowerCase()) ??
          false;
      return nameMatch || storeNameMatch;
    }).toList();

    // Sort based on selected sort option
    if (_selectedSort != null) {
      switch (_selectedSort) {
        case 'rating':
          filteredSweetHouses.sort((a, b) {
            final ratingA = a.rating ?? 0.0;
            final ratingB = b.rating ?? 0.0;
            return ratingB.compareTo(ratingA); // Descending
          });
          break;
        case 'delivery_time':
          filteredSweetHouses.sort((a, b) {
            final timeA = _etaMinutes(a.travelTimeMin);
            final timeB = _etaMinutes(b.travelTimeMin);
            return timeA.compareTo(timeB);
          });
          break;
        case 'distance':
        case 'relevance':
        default:
          // Keep default order (already sorted by distance/relevance from API)
          break;
      }
    }
  }

  /// `travel_time_min` arrives with its unit attached ("8 min", "1 hr 5 min"),
  /// so a plain `double.parse` on it always fails. Pull the numbers out and
  /// normalise to minutes; unknown values sort last.
  double _etaMinutes(String? travelTimeMin) {
    if (travelTimeMin == null) return double.infinity;

    final hr = RegExp(r'([\d.]+)\s*hr').firstMatch(travelTimeMin);
    final min = RegExp(r'([\d.]+)\s*min').firstMatch(travelTimeMin);
    if (hr == null && min == null) return double.infinity;

    return (double.tryParse(hr?.group(1) ?? '0') ?? 0) * 60 +
        (double.tryParse(min?.group(1) ?? '0') ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, double.maxFinite),
        child: AppHeader(
          label: 'Restaurants',
          title: widget.category.name,
          showBackButton: true,
        ),
      ),
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          // Search Bar - Using StickySearchDelegate from homeScreen
          SliverPersistentHeader(
            pinned: true,
            delegate: _CategorySearchDelegate(
              minHeight: 32,
              maxHeight: 32,
              topPadding: MediaQuery.of(context).padding.top,
              isSticked: _isSticked,
              colorScheme: colorScheme,
              onSearchChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
                _loadSweetHouses();
              },
              scrollController: scrollController,
            ),
          ),

          // Sorting Section - Using SortingsSection UI pattern from homeScreen
          SliverToBoxAdapter(
            child: _SweetHouseSortingsSection(
              selectedSort: _selectedSort,
              selectedBrand: _selectedBrand,
              isVegSelected: _isVegSelected,
              isNonVegSelected: _isNonVegSelected,
              onSortChanged: (sort) {
                setState(() {
                  _selectedSort = sort;
                });
                _loadSweetHouses();
              },
              onBrandChanged: (brand) {
                setState(() {
                  _selectedBrand = brand;
                });
              },
              onVegToggled: () {
                setState(() {
                  _isVegSelected = !_isVegSelected;
                  if (_isVegSelected) {
                    _isNonVegSelected = false;
                  }
                });
                _loadSweetHouses();
              },
              onNonVegToggled: () {
                setState(() {
                  _isNonVegSelected = !_isNonVegSelected;
                  if (_isNonVegSelected) {
                    _isVegSelected = false;
                  }
                });
                _loadSweetHouses();
              },
              sortByOptions: sortByOptions, // Pass sortByOptions
            ),
          ),

          // Sweet Houses List
          if (_isLoading)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
              ),
            )
          else if (filteredSweetHouses.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No sweet houses found',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textSecondary,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              sliver: SliverList.separated(
                itemCount: filteredSweetHouses.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final seller = filteredSweetHouses[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SweetHouseDetailScreen(
                            sellerId: seller.id.toString(),
                            foodType: _isVegSelected
                                ? 'veg'
                                : _isNonVegSelected
                                    ? 'non_veg'
                                    : null,
                          ),
                        ),
                      );
                    },
                    child: _buildSweetHouseCard(seller, colorScheme),
                  );
                },
              ),
            ),

          // Pagination Loader
          if (_isLoading)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 50),
          ),
        ],
      ),
    );
  }

  Widget _buildSweetHouseCard(StoreSeller seller, AppColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Column(
        children: [
          // Store Image Carousel with interval-based indicators
          _StoreImageCarousel(
            seller: seller,
            colorScheme: colorScheme,
          ),

          // Store Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Store name, location, delivery time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store Name
                    Text(
                      seller.storeName?.capitalized ??
                          seller.name?.capitalized ??
                          '',
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.55,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Distance + Location
                    Text(
                      '${seller.distanceKm ?? 'N/A'}, ${seller.storeLocation ?? ''}',
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        letterSpacing: -0.55,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Delivery Time with bullet
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.textPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          seller.travelTimeMin ?? 'N/A',
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            letterSpacing: -0.55,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Right: Rating Badge
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: colorScheme.buttonPrimaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          seller.rating?.toStringAsFixed(1) ?? '0.0',
                          style: GoogleFonts.inter(
                            color: colorScheme.buttonPrimaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.02,
                            letterSpacing: -0.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'By ${seller.ratingCount ?? '0'}',
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1.02,
                      letterSpacing: -0.55,
                    ),
                  ),
                ],
              ),
            ],
          ).pSymmetric(h: 16, v: 12),
        ],
      ),
    );
  }
}

// Category Search Delegate - Adapted from homeScreen StickySearchDelegate
class _CategorySearchDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final double topPadding;
  final bool isSticked;
  final AppColorScheme colorScheme;
  final Function(String) onSearchChanged;
  final ScrollController scrollController;

  _CategorySearchDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.topPadding,
    required this.isSticked,
    required this.colorScheme,
    required this.onSearchChanged,
    required this.scrollController,
  });

  @override
  double get minExtent => minHeight + topPadding;

  @override
  double get maxExtent => maxHeight + topPadding;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: maxExtent,
      child: Container(
        padding: EdgeInsets.only(top: isSticked ? topPadding : 0),
        decoration: BoxDecoration(
          color: isSticked ? colorScheme.surface : null,
          boxShadow: isSticked
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                        0.05), // Corrected withValues to withOpacity
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  Icon(
                    Icons.search,
                    color: colorScheme.iconSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'Search ',
                          style: GoogleFonts.inter(
                            color: colorScheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                            height: 1.3,
                          ),
                        ),
                        Expanded(
                          child: AnimatedTextKit(
                            repeatForever: true,
                            animatedTexts: [
                              TypewriterAnimatedText(
                                'sweet houses...',
                                textStyle: GoogleFonts.inter(
                                  color: colorScheme.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.2,
                                  height: 1.3,
                                ),
                                speed: const Duration(milliseconds: 100),
                              ),
                              TypewriterAnimatedText(
                                'restaurants...',
                                textStyle: GoogleFonts.inter(
                                  color: colorScheme.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.2,
                                  height: 1.3,
                                ),
                                speed: const Duration(milliseconds: 100),
                              ),
                            ],
                            pause: const Duration(milliseconds: 1000),
                            isRepeatingAnimation: true,
                            displayFullTextOnTap: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_CategorySearchDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        topPadding != oldDelegate.topPadding ||
        isSticked != oldDelegate.isSticked ||
        colorScheme != oldDelegate.colorScheme;
  }
}

// Sweet House Sortings Section - Using SortingsSection UI pattern from homeScreen
class _SweetHouseSortingsSection extends StatefulWidget {
  final String? selectedSort;
  final String? selectedBrand;
  final bool isVegSelected;
  final bool isNonVegSelected;
  final Function(String?) onSortChanged;
  final Function(String?) onBrandChanged;
  final VoidCallback onVegToggled;
  final VoidCallback onNonVegToggled;
  final List<SortByOption> sortByOptions; // Corrected type to SortByOption

  const _SweetHouseSortingsSection({
    required this.selectedSort,
    required this.selectedBrand,
    required this.isVegSelected,
    required this.isNonVegSelected,
    required this.onSortChanged,
    required this.onBrandChanged,
    required this.onVegToggled,
    required this.onNonVegToggled,
    required this.sortByOptions, // Required sortByOptions
  });

  @override
  State<_SweetHouseSortingsSection> createState() =>
      _SweetHouseSortingsSectionState();
}

class _SweetHouseSortingsSectionState
    extends State<_SweetHouseSortingsSection> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            // Sort By
            if (index == 0) {
              String label = 'Sort By';
              String? selectedValue = widget.selectedSort;

              // Find the display label for the selected API value
              String? displayValue;
              if (selectedValue != null) {
                try {
                  displayValue = widget.sortByOptions
                      .firstWhere((o) => o.apiValue == selectedValue)
                      .label;
                } catch (_) {
                  displayValue = selectedValue;
                }
              }

              return _FilterChipButton(
                colorScheme: colorScheme,
                label: label,
                selectedValue: displayValue, // Pass displayValue
                isSelected: selectedValue != null,
                onTap: () {
                  _showFilterSheet(
                    context: context,
                    colorScheme: colorScheme,
                    title: label,
                    options: widget.sortByOptions,
                    filterIndex: index,
                  );
                },
              );
            }
            // Brand Filter
            else if (index == 1) {
              String label = 'Brand';
              String? selectedValue = widget.selectedBrand;
              List<String> options = ['Brand 1', 'Brand 2', 'Brand 3'];
              return _FilterChipButton(
                colorScheme: colorScheme,
                label: label,
                isSelected: selectedValue != null,
                onTap: () {
                  _showFilterSheet(
                    context: context,
                    colorScheme: colorScheme,
                    title: label,
                    options: options,
                    filterIndex: index,
                  );
                },
              );
            }
            // Veg Toggle
            else if (index == 2) {
              return _VegToggleChip(
                colorScheme: colorScheme,
                label: 'Veg',
                isSelected: widget.isVegSelected,
                onTap: widget.onVegToggled,
              );
            }
            // Non-Veg Toggle
            else if (index == 3) {
              return _VegToggleChip(
                colorScheme: colorScheme,
                label: 'Non-Veg',
                isSelected: widget.isNonVegSelected,
                onTap: widget.onNonVegToggled,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showFilterSheet({
    required BuildContext context,
    required AppColorScheme colorScheme,
    required String title,
    required List<dynamic> options,
    required int filterIndex,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.border,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.textPrimary,
                            letterSpacing: -0.55,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 24,
                            color: colorScheme.iconPrimary,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Options List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: options.length,
                      itemBuilder: (context, optionIndex) {
                        final option = options[optionIndex];
                        String? optionValue;
                        String optionLabel;

                        if (option is SortByOption) {
                          optionValue = option.apiValue;
                          optionLabel = option.label;
                        } else {
                          optionValue = option.toString();
                          optionLabel = option.toString();
                        }

                        bool isSelected = false;
                        if (filterIndex == 0) {
                          isSelected = widget.selectedSort == optionValue;
                        } else if (filterIndex == 1) {
                          isSelected = widget.selectedBrand == optionLabel;
                        }

                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              if (filterIndex == 0) {
                                widget.onSortChanged(
                                    isSelected ? null : optionValue);
                              } else if (filterIndex == 1) {
                                widget.onBrandChanged(
                                    isSelected ? null : optionLabel);
                              }
                            });
                            setState(() {});
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: colorScheme.cardBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.border,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    optionLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.textPrimary,
                                      letterSpacing: -0.55,
                                      height: 1.02,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.divider,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Footer with Apply button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.border,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: colorScheme.border,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Apply',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.buttonPrimaryText,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

// Filter Chip Button - Directly from homeScreen SortingsSection UI
class _FilterChipButton extends StatelessWidget {
  final AppColorScheme colorScheme;
  final String label;
  final String? selectedValue;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.colorScheme,
    required this.label,
    this.selectedValue,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              selectedValue != null ? "$label: $selectedValue" : label,
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

// Veg Toggle Chip - For Veg/Non-Veg filtering
class _VegToggleChip extends StatelessWidget {
  final AppColorScheme colorScheme;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _VegToggleChip({
    required this.colorScheme,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVeg = label == 'Veg';
    final iconPath =
        isVeg ? 'assets/images/veg.png' : 'assets/images/non-veg.png';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Veg/Non-Veg Icon from assets
          Image.asset(
            iconPath,
            width: 16,
            height: 16,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 5),
          // Label
          Text(
            label,
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.02,
              letterSpacing: -0.55,
            ),
          ),
          const SizedBox(width: 2),
          // Flutter Switch (compact)
          Transform.scale(
            scale: 0.6,
            child: Switch(
              value: isSelected,
              onChanged: (_) => onTap(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeThumbColor: Colors.white,
              activeTrackColor:
                  isVeg ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }
}

// Store Image Carousel Widget with interval-based indicators
class _StoreImageCarousel extends StatefulWidget {
  final StoreSeller seller;
  final dynamic colorScheme;

  const _StoreImageCarousel({
    Key? key,
    required this.seller,
    required this.colorScheme,
  }) : super(key: key);

  @override
  State<_StoreImageCarousel> createState() => _StoreImageCarouselState();
}

class _StoreImageCarouselState extends State<_StoreImageCarousel>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  Timer? _autoTimer;
  int _currentPage = 0;
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();

    // Parse store images
    _parseStoreImages();

    // Start auto-play timer
    _startAutoTimer();
  }

  @override
  void didUpdateWidget(covariant _StoreImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seller.id != widget.seller.id ||
        oldWidget.seller.storeImages != widget.seller.storeImages ||
        oldWidget.seller.logoUrl != widget.seller.logoUrl) {
      _currentPage = 0;
      _parseStoreImages();
      _restartProgress();
    }
  }

  void _parseStoreImages() {
    // Get images from storeImages field (comma-separated URLs)
    if (widget.seller.storeImages != null &&
        widget.seller.storeImages!.isNotEmpty) {
      _imageUrls = widget.seller.storeImages!;
    }

    // If no store images, use logo as fallback
    if (_imageUrls.isEmpty && widget.seller.logoUrl != null) {
      _imageUrls = [widget.seller.logoUrl!];
    }

    // Additional fallback from storeDetails
    if (_imageUrls.isEmpty && widget.seller.storeDetails?.image != null) {
      final detailImage = widget.seller.storeDetails!.image!.trim();
      if (detailImage.isNotEmpty &&
          detailImage.toLowerCase() != 'null' &&
          detailImage.toLowerCase().startsWith('http')) {
        _imageUrls = [detailImage];
      }
    }
  }

  void _startAutoTimer() {
    _animationController.forward(from: 0);
    _autoTimer?.cancel();
    if (_imageUrls.length <= 1) return;
    _autoTimer = Timer(const Duration(seconds: 4), _goNext);
  }

  void _goNext() {
    if (_imageUrls.length <= 1) return;
    final next = (_currentPage + 1) % _imageUrls.length;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 400),
      curve: Curves.ease,
    );
  }

  void _restartProgress() {
    _animationController.forward(from: 0);
    _autoTimer?.cancel();
    if (_imageUrls.length > 1) {
      _autoTimer = Timer(const Duration(seconds: 4), _goNext);
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_imageUrls.isEmpty) {
      // No images, show placeholder
      return Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: widget.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.store_outlined,
          size: 48,
          color: widget.colorScheme.iconDisabled,
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 180,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: widget.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Stack(
        children: [
          // PageView for images
          PageView.builder(
            controller: _pageController,
            itemCount: _imageUrls.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              _restartProgress();
            },
            itemBuilder: (context, index) {
              final url = _imageUrls[index];
              debugPrint("IMAGE URL => $url");
              return CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (context, error, stackTrace) {
                  return Container(
                    color: widget.colorScheme.surfaceVariant,
                    child: Icon(
                      Icons.store_outlined,
                      size: 48,
                      color: widget.colorScheme.iconDisabled,
                    ),
                  );
                },
              );
            },
          ),

          // Bookmark Icon (top-right)
          Positioned(
            right: 8,
            top: 10,
            child: GestureDetector(
              onTap: () {
                // Handle bookmark toggle
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: widget.colorScheme.cardShadow,
                ),
                child: Icon(
                  Icons.bookmark_border_rounded,
                  size: 18,
                  color: widget.colorScheme.iconPrimary,
                ),
              ),
            ),
          ),

          // Interval-based indicators (only show if multiple images)
          if (_imageUrls.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_imageUrls.length, (i) {
                  final isActive = i == _currentPage;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, _) => Container(
                        width: 24,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.grey[400]
                              : Colors.grey[300]?.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: isActive
                            ? FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _animationController.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
