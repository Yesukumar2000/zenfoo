import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/category_groups.dart';
import 'package:project/models/category_filter_models.dart';
import 'dart:developer' as dev;

class CategoryProductProvider extends ChangeNotifier {
  int selectedCategoryIdx = 0;
  int subCategoryGroupsId;
  int? initialSelectedCategoryId; // Pre-select a specific category by ID
  List<SubCategoryGroup> categories = [];
  List<ProductListItem> products = [];

  bool loading = false;
  bool loadingMore = false;
  bool error = false;
  bool hasMore = false;
  int offset = 0;

  final int perPage = 12;

  // Filter states
  String selectedSort = 'relevance'; // relevance, high, low, new
  Set<int> selectedBrandIds = {};
  String? selectedType; // null means "All"
  Set<String> selectedSizes = {};
  Set<int> selectedUnitIds = {};
  RangeValues priceRange = const RangeValues(0, 2000);
  int totalMinPrice = 0;
  int totalMaxPrice = 2000;

  // Dynamic filter data from API
  List<CategoryType> categoryTypes = [];
  List<Brand> brands = [];
  List<BannerItem> banners = [];

  // Scroll controllers
  final ScrollController _leftSidebarController = ScrollController();

  ScrollController get leftSidebarController => _leftSidebarController;

  CategoryProductProvider(this.subCategoryGroupsId, {this.initialSelectedCategoryId}) {
    debugPrint('=== CategoryProductProvider INIT ===');
    debugPrint('subCategoryGroupsId: $subCategoryGroupsId');
    debugPrint('initialSelectedCategoryId: $initialSelectedCategoryId');
    debugPrint('====================================');
  }

  @override
  void dispose() {
    _leftSidebarController.dispose();
    super.dispose();
  }

  /// Switch to a sibling sub-category group (the top chip row) and reload.
  Future<void> switchSubGroup(BuildContext context, int newSubGroupId) async {
    if (newSubGroupId == subCategoryGroupsId) return;
    subCategoryGroupsId = newSubGroupId;
    selectedCategoryIdx = 0;
    initialSelectedCategoryId = null;
    selectedType = null;
    selectedBrandIds = {};
    selectedSizes = {};
    selectedUnitIds = {};
    products = [];
    offset = 0;
    await loadInitial(context);
  }

  Future<void> loadInitial(BuildContext context) async {
    loading = true;
    error = false;
    offset = 0;
    products.clear();
    notifyListeners();

    final latitude = double.parse(Constant.session
        .getData(SessionManager.keyLatitude, defaultValue: "0.0"));
    final longitude = double.parse(Constant.session
        .getData(SessionManager.keyLongitude, defaultValue: "0.0"));

    try {
      final resp = await getSubCategoriesAndProductsApi(
        context: context,
        subCategoryGroupsId: subCategoryGroupsId,
        latitude: latitude,
        longitude: longitude,
        limit: perPage,
        offset: 0,
      );
      if (resp['status'].toString() == "1") {
        categories = (resp['categories'] as List)
            .map((e) => SubCategoryGroup.fromJson(e))
            .toList();
        if (categories.isNotEmpty) {
          // Find the index of the category to pre-select
          int initialIdx = 0;
          debugPrint('=== CATEGORY SELECTION DEBUG ===');
          debugPrint('Total categories loaded: ${categories.length}');
          for (int i = 0; i < categories.length; i++) {
            debugPrint('  [$i] id: ${categories[i].id}, name: ${categories[i].name}');
          }
          debugPrint('initialSelectedCategoryId to find: $initialSelectedCategoryId');

          if (initialSelectedCategoryId != null) {
            final foundIdx = categories.indexWhere(
              (cat) => cat.id == initialSelectedCategoryId,
            );
            debugPrint('foundIdx: $foundIdx');
            if (foundIdx != -1) {
              initialIdx = foundIdx;
            }
          }
          debugPrint('Final initialIdx to select: $initialIdx');
          debugPrint('================================');
          await selectCategory(context, initialIdx, initial: true);
        }
        error = false;
      } else {
        error = true;
      }
    } catch (e) {
      error = true;
    }
    loading = false;
    notifyListeners();
  }

  bool isSwitchingCategory = false;

  Future<void> selectCategory(BuildContext context, int idx,
      {bool initial = false}) async {
    if (isSwitchingCategory && !initial) return;
    isSwitchingCategory = true;

    try {
      selectedCategoryIdx = idx;
      offset = 0;
      products.clear();
      hasMore = true;
      loadingMore = false;
      notifyListeners();
      await loadProducts(context, initial: initial);
      dev.log("Loaded Products ${products.length}");

      // Scroll left sidebar to center the selected item
      if (_leftSidebarController.hasClients && categories.isNotEmpty) {
        // Calculate item height (approximately 72px per item based on UI)
        const double itemHeight = 72.0;
        final double targetOffset = (idx * itemHeight) -
            (_leftSidebarController.position.viewportDimension / 2) +
            (itemHeight / 2);

        // Ensure offset is within bounds
        final double maxScroll =
            _leftSidebarController.position.maxScrollExtent;
        final double clampedOffset = targetOffset.clamp(0.0, maxScroll);

        _leftSidebarController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      notifyListeners();
    } finally {
      isSwitchingCategory = false;
    }
  }

  int _requestToken = 0;

  Future<void> loadProducts(BuildContext context,
      {bool initial = false}) async {
    if (!hasMore && !initial) return;
    if (loadingMore) return;
    loadingMore = true;
    notifyListeners();

    final latitude = double.parse(Constant.session
        .getData(SessionManager.keyLatitude, defaultValue: "0.0"));
    final longitude = double.parse(Constant.session
        .getData(SessionManager.keyLongitude, defaultValue: "0.0"));
    final categoryId = categories[selectedCategoryIdx].id;

    // Prepare filter parameters
    String? sortParam = _getSortParam();
    String? brandIdsParam =
        selectedBrandIds.isNotEmpty ? selectedBrandIds.join(',') : null;
    String? sizesParam =
        selectedSizes.isNotEmpty ? selectedSizes.join(',') : null;
    String? unitIdsParam =
        selectedUnitIds.isNotEmpty ? selectedUnitIds.join(',') : null;
    int? minPriceParam = priceRange.start.toInt() > totalMinPrice
        ? priceRange.start.toInt()
        : null;
    int? maxPriceParam =
        priceRange.end.toInt() < totalMaxPrice ? priceRange.end.toInt() : null;

    try {
      final resp = await getProductsApi(
        context: context,
        categoryId: categoryId,
        latitude: latitude,
        longitude: longitude,
        limit: perPage,
        offset: offset,
        sort: sortParam,
        brandIds: brandIdsParam,
        sizes: sizesParam,
        unitIds: unitIdsParam,
        minPrice: minPriceParam,
        maxPrice: maxPriceParam,
      );
      if (resp['status'].toString() == "1") {
        final prods = (resp['data'] as List)
            .map((e) => ProductListItem.fromJson(e))
            .toList();
        products.addAll(prods);
        hasMore = prods.length == perPage;
        if (hasMore) offset += perPage;

        // Update price range from API response
        if (resp['total_min_price'] != null) {
          totalMinPrice = int.tryParse(resp['total_min_price'].toString()) ?? 0;
        }
        if (resp['total_max_price'] != null) {
          totalMaxPrice =
              int.tryParse(resp['total_max_price'].toString()) ?? 2000;
        }

        // Ensure valid range bounds (Safety check)
        if (totalMinPrice > totalMaxPrice) {
          totalMaxPrice = totalMinPrice;
        }

        // Clamp selected price range to new bounds to prevent RangeSlider assertion error
        double newStart = priceRange.start
            .clamp(totalMinPrice.toDouble(), totalMaxPrice.toDouble());
        double newEnd = priceRange.end
            .clamp(totalMinPrice.toDouble(), totalMaxPrice.toDouble());

        // Ensure start <= end logic (though clamp handles this if min<=max)
        if (newStart > newEnd) {
          newStart = newEnd;
        }

        priceRange = RangeValues(newStart, newEnd);

        // Update filter data if present in response
        if (resp['category_types'] != null) {
          categoryTypes = (resp['category_types'] as List)
              .map((e) => CategoryType.fromJson(e))
              .toList();
        }
        if (resp['brands_according_to_category'] != null) {
          brands = (resp['brands_according_to_category'] as List)
              .map((e) => Brand.fromJson(e))
              .toList();
        }
        if (resp['banners'] != null) {
          banners = (resp['banners'] as List)
              .map((e) => BannerItem.fromJson(e))
              .toList();
        }
      } else {
        hasMore = false;
      }
    } catch (e) {
      hasMore = false;
    }

    loadingMore = false;
    notifyListeners();
  }

  String? _getSortParam() {
    switch (selectedSort) {
      case 'high':
      case 'price_high_to_low':
        return 'high';
      case 'low':
      case 'price_low_to_high':
        return 'low';
      case 'new':
      case 'newest_first':
        return 'new';
      case 'discount':
        return 'discount';
      case 'popular':
        return 'popular';
      case 'distance':
        return 'distance';
      case 'rating':
        return 'rating';
      case 'name':
        return 'name';
      default:
        return (selectedSort == 'relevance' || selectedSort == 'Relevance')
            ? null
            : selectedSort; // Pass unknown sorts directly
    }
  }

  // Filter management methods
  void setSort(String sort) {
    selectedSort = sort;
    _applyFilters();
  }

  void toggleBrand(int brandId) {
    if (selectedBrandIds.contains(brandId)) {
      selectedBrandIds.remove(brandId);
    } else {
      selectedBrandIds.add(brandId);
    }
    _applyFilters();
  }

  void selectType(String? type) {
    selectedType = type; // null means "All"
    _applyFilters();
  }

  void toggleSize(String size, int unitId) {
    if (selectedSizes.contains(size)) {
      selectedSizes.remove(size);
      selectedUnitIds.remove(unitId);
    } else {
      selectedSizes.add(size);
      selectedUnitIds.add(unitId);
    }
    _applyFilters();
  }

  void setPriceRange(RangeValues range) {
    priceRange = range;
    notifyListeners();
  }

  void applyPriceFilter() {
    _applyFilters();
  }

  void clearFilters() {
    HapticFeedback.lightImpact();

    selectedSort = 'relevance';
    selectedBrandIds.clear();
    selectedType = null; // Reset to "All"
    selectedSizes.clear();
    selectedUnitIds.clear();
    priceRange =
        RangeValues(totalMinPrice.toDouble(), totalMaxPrice.toDouble());
    _applyFilters();
  }

  void _applyFilters() {
    offset = 0;
    products.clear();
    hasMore = true;
    notifyListeners();
    // Products will be reloaded automatically by the UI's Consumer listener
    // when it detects products is empty and hasMore is true
  }

  // Helper method to apply filters with context (for immediate reload)
  Future<void> applyFiltersAndReload(BuildContext context) async {
    offset = 0;
    products.clear();
    hasMore = true;

    notifyListeners();
    await loadProducts(context, initial: true);
  }
}
