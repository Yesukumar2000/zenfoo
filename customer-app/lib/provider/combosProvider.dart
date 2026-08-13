import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/combo_models.dart';

enum CombosPageState { initial, loading, loaded, error }

class CombosProvider extends ChangeNotifier {
  CombosPageState state = CombosPageState.initial;
  CombosPageData? combosData;

  // Filters
  String? selectedComboTypeId;
  RangeValues priceRange = const RangeValues(0, 5000);
  RangeValues countRange = const RangeValues(1, 20);
  String filterSort = 'latest'; // latest, oldest, low_to_high, high_to_low
  String searchQuery = '';

  // Filter options constants (can also be dynamic if needed)
  final double minPrice = 0;
  final double maxPrice = 5000;
  final double minCount = 1;
  final double maxCount = 20;

  // Debounce timer for search
  Timer? _searchDebounceTimer;
  static const Duration _searchDebounceDelay = Duration(milliseconds: 500);

  Future<void> fetchData(BuildContext context) async {
    state = CombosPageState.loading;
    notifyListeners();

    try {
      final res = await fetchCombosBasedOnCategoryType(
        context: context,
        comboTypeId: selectedComboTypeId,
        fromPrice: priceRange.start > minPrice ? priceRange.start : null,
        toPrice: priceRange.end < maxPrice ? priceRange.end : null,
        fromCount:
            countRange.start > minCount ? countRange.start.toInt() : null,
        toCount: countRange.end < maxCount ? countRange.end.toInt() : null,
        filter: filterSort,
        search: searchQuery.isNotEmpty ? searchQuery : null,
      );

      if (res != null) {
        combosData = res;
        state = CombosPageState.loaded;
      } else {
        state = CombosPageState.error;
      }
    } catch (e) {
      state = CombosPageState.error;
    }
    notifyListeners();
  }

  void updateComboType(String? id, BuildContext context) {
    if (selectedComboTypeId == id) return;
    selectedComboTypeId = id;
    fetchData(context);
  }

  void updateSort(String sort, BuildContext context) {
    if (filterSort == sort) return;
    filterSort = sort;
    fetchData(context);
  }

  void updatePriceRange(RangeValues range, BuildContext context) {
    priceRange = range;
    fetchData(context);
  }

  void updateCountRange(RangeValues range, BuildContext context) {
    countRange = range;
    fetchData(context);
  }

  void updateSearch(String query, BuildContext context) {
    searchQuery = query;

    // Cancel previous timer if exists
    _searchDebounceTimer?.cancel();

    // Set new debounce timer
    _searchDebounceTimer = Timer(_searchDebounceDelay, () {
      fetchData(context);
    });
  }

  void clearFilters(BuildContext context) {
    selectedComboTypeId = null;
    priceRange = RangeValues(minPrice, maxPrice);
    countRange = RangeValues(minCount, maxCount);
    filterSort = 'latest';
    searchQuery = '';

    // Cancel any pending search debounce
    _searchDebounceTimer?.cancel();

    fetchData(context);
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}
