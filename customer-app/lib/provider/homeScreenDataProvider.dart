import 'dart:developer' as dev;

import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/category_groups.dart';
import 'package:project/models/home_models.dart';
import 'package:project/models/combo.dart';
import 'package:project/models/store_with_category_group.dart';

enum HomeScreenState { initial, loading, loaded, error }

class HomeScreenProvider extends ChangeNotifier {
  bool _isDisposed = false;

  // Sectional states
  HomeScreenState sliderState = HomeScreenState.loading;
  HomeScreenState categoriesState = HomeScreenState.loading;
  HomeScreenState etaState = HomeScreenState.loading;
  HomeScreenState weatherState = HomeScreenState.loading;

  // Data
  HomeScreenData? homeScreenData;
  List<HomeCategories> homeCategories = [];
  Map<String, List<OfferImages>> homeOfferImagesMap = {};
  String? estimatedTime;
  String message = '';

  // Nearest store / ETA (from customer/nearest-store)
  int? travelTimeMinutes;
  String? nearestStoreName;
  String? nearestStoreMessage;
  bool isServiceable = true;

  // Weather
  bool isRaining = false;

  List<ProductData> productsForCategory = [];
  bool productsLoading = false;
  String? productsError;

  List<CategoryGroup> storeGroups = [];
  int selectedStoreIdx = 0; // 0 == All
  String? selectedSortBy;
  String? selectedCategoryId;
  String? selectedFoodType;

  Future<void> loadStoreGroups(BuildContext context,
      {bool resetSelection = false}) async {
    groupState = HomeScreenState.loading;

    storeGroups = await fetchStoreGroups(context);
    groupState = HomeScreenState.loaded;

    // Reset selection only if explicitly requested, otherwise preserve current selection
    if (resetSelection) {
      selectedStoreIdx = 0;
    }

    // Ensure selectedStoreIdx is valid
    if (selectedStoreIdx >= storeGroups.length) {
      selectedStoreIdx = 0;
    }

    notifyListeners();
  }

  void setSelectedStoreTab(BuildContext context, int idx) {
    // Update UI immediately for instant feedback
    selectedStoreIdx = idx;
    notifyListeners();

    // Fetch data in background without blocking UI
    final selectedId = idx == 0 ? null : storeGroups[idx].id;
    Future.microtask(() {
      fetchProductsForStoreGroup(context, selectedId);
      fetchHomeCombos(context, storeId: selectedId);
    });
  }

  Future<void> fetchProductsForStoreGroup(
    BuildContext context,
    int? groupId, {
    bool resetPagination = true,
    String? sortBy,
    String? categoryId,
    String? foodType,
  }) async {
    if (resetPagination) {
      selectedSortBy = sortBy;
      selectedCategoryId = categoryId;
      selectedFoodType = foodType;
      storeDataState = HomeScreenState.loading;
      if (!_isDisposed) notifyListeners();
    }

    // try {
    final result = await fetchStoreWithCategoryGroups(
      context: context,
      storeId: groupId?.toString(),
      sortBy: sortBy ?? selectedSortBy,
      categoryId: categoryId ?? selectedCategoryId,
      foodType: foodType ?? selectedFoodType,
    );

    if (_isDisposed) return;

    if (result != null) {
      // Flatten all category groups from all stores
      if (resetPagination) {
        categoryGroups = [];
        storeCategories = [];
        _storeSellers = [];
        _topRatedSellers = [];
        storeSliders = [];
        isMeatStore = false;
      }

      for (final store in result.stores) {
        // A meat store only switches the screen into the flat meat grid when
        // that store is the one being viewed. The all-stores tab (groupId ==
        // null) carries every store, and the meat ones among them must not
        // reshape the whole home screen — it keeps the per-group block
        // layout: heading + its own sub-category tiles.
        if (groupId != null && store.isMeat) isMeatStore = true;
        // Add category groups with storeId set to the parent store's id
        categoryGroups.addAll(
            store.categoryGroups.map((cg) => cg.copyWithStoreId(store.id)));
        storeCategories.addAll(
            store.categories.map((c) => c.copyWith(categoryGroupId: store.id)));

        log("Categories ${store.categories}");

        // Collect sliders from all stores (only on reset)
        if (resetPagination) {
          storeSliders.addAll(store.sliders);
          // Collect top-rated sellers (only on reset)
          _topRatedSellers.addAll(store.topRatedSellers);
        }

        // Handle pagination for sellers
        if (store.sellersPagination != null) {
          sellersPagination = store.sellersPagination;
          _storeSellers.addAll(store.sellersPagination!.data);
          hasMoreSellers = store.sellersPagination!.hasMorePages;
        }
      }

      storeDataState = HomeScreenState.loaded;
      if (!_isDisposed) notifyListeners();
    } else {
      storeDataState = HomeScreenState.error;
      if (!_isDisposed) notifyListeners();
    }
    // } catch (e) {
    //   dev.log("Error fetching store data: $e");
    //   storeDataState = HomeScreenState.error;
    //   if (!_isDisposed) notifyListeners();
    // }
  }

  void clearAllFilters(BuildContext context) {
    selectedSortBy = null;
    selectedCategoryId = null;
    selectedFoodType = null;
    final selectedId =
        selectedStoreIdx == 0 ? null : storeGroups[selectedStoreIdx].id;
    fetchProductsForStoreGroup(context, selectedId);
  }

  Future<void> loadMoreSellers(BuildContext context) async {
    // Pagination disabled for stores
    return;
  }

  Future<void> fetchWeatherData(BuildContext context) async {
    weatherState = HomeScreenState.loading;
    notifyListeners();

    try {
      final response = await fetchWeather(context);
      if (response != null && response['status'] == 1) {
        final data = response['data'];
        if (data != null) {
          final rainValue = data['is_raining_now'];
          isRaining = rainValue == true ||
              rainValue == 1 ||
              rainValue == '1' ||
              rainValue == 'true';
        } else {
          isRaining = false;
        }
        weatherState = HomeScreenState.loaded;
      } else {
        weatherState = HomeScreenState.error;
      }
    } catch (e) {
      weatherState = HomeScreenState.error;
    }
    notifyListeners();
  }

  // Parallel, non-blocking loading
  Future<void> loadSections({
    required Map<String, dynamic> params,
    required BuildContext context,
    bool resetStoreSelection = false,
  }) async {
    // Sliders are now loaded from cat_store API, no need for separate slider call
    // loadSlider(context, params);
    // loadCategories(context, params);
    // loadCategoryGroups(context);
    await loadStoreGroups(context, resetSelection: resetStoreSelection);
    // Preserve the currently selected store during refresh (unless explicitly resetting)
    final selectedId = selectedStoreIdx == 0
        ? null
        : (storeGroups.isNotEmpty && selectedStoreIdx < storeGroups.length
            ? storeGroups[selectedStoreIdx].id
            : null);
    fetchProductsForStoreGroup(context, selectedId,
        sortBy: selectedSortBy,
        categoryId: selectedCategoryId,
        foodType: selectedFoodType);
    fetchHomeCombos(context, storeId: selectedId);
    loadEta(context, params);
    fetchWeatherData(context);
  }

  HomeScreenState groupState = HomeScreenState.loading;
  HomeScreenState storeDataState = HomeScreenState.loading; // For cat_store API
  List<CategoryGroup> categoryGroups = [];
  List<StoreCategory> storeCategories = [];
  List<StoreSeller> _storeSellers = [];
  List<StoreSeller> _topRatedSellers = []; // Top-rated sellers from API
  List<StoreSlider> storeSliders = [];
  bool isMeatStore = false;

  List<StoreSeller> get storeSellers => _storeSellers;
  List<StoreSeller> get topRatedSellers => _topRatedSellers;

  // Sellers pagination
  SellersPagination? sellersPagination;
  bool isLoadingMoreSellers = false;
  bool hasMoreSellers = false;

  // Getter for sweet houses (filtered from storeSellers)
  List<StoreSeller> get sweetHouses {
    Iterable<StoreSeller> filtered = storeSellers.where((seller) =>
        seller.storeDetails?.isSweetHouse == true ||
        seller.storeDetails?.isSweetHouse == 1);

    return filtered.take(6).toList();
  }

  // Getter for top-rated sweet houses (filtered from topRatedSellers)
  List<StoreSeller> get topRatedSweetHouses {
    Iterable<StoreSeller> filtered = topRatedSellers.where((seller) =>
        seller.storeDetails?.isSweetHouse == true ||
        seller.storeDetails?.isSweetHouse == 1);

    return filtered.toList();
  }

  Future<void> loadCategoryGroups(BuildContext context) async {
    groupState = HomeScreenState.loading;
    notifyListeners();
    try {
      categoryGroups = await fetchCategoryGroups(context);
      groupState = HomeScreenState.loaded;
      notifyListeners();
    } catch (e) {
      groupState = HomeScreenState.error;
      notifyListeners();
    }
  }

  // Combos data
  List<Combo> homeCombos = [];
  HomeScreenState combosState = HomeScreenState.loading;

  Future<void> fetchHomeCombos(
    BuildContext context, {
    int? storeId,
  }) async {
    combosState = HomeScreenState.loading;
    notifyListeners();

    try {
      // storeId parameter is the actual store ID (or null for all stores)
      // Don't pass selectedStoreIdx as it's an index, not a store ID
      homeCombos = await fetchCombosHomePage(
        context: context,
        storeId: storeId,
      );
      combosState = HomeScreenState.loaded;
    } catch (e) {
      combosState = HomeScreenState.error;
    }
    notifyListeners();
  }

  // Each loads independently
  Future<void> loadSlider(
      BuildContext context, Map<String, dynamic> params) async {
    try {
      sliderState = HomeScreenState.loading;
      notifyListeners();
      final data = await getHomeScreenDataApi(context: context, params: params);
      if (data[ApiAndParams.status].toString() == "1") {
        homeScreenData = HomeScreenData.fromJson(data[ApiAndParams.data]);
        getSliderImages(homeScreenData?.offers);
        sliderState = HomeScreenState.loaded;
      } else {
        sliderState = HomeScreenState.error;
      }
      notifyListeners();
    } catch (e) {
      sliderState = HomeScreenState.error;
      notifyListeners();
    }
  }

  Future<void> loadCategories(
      BuildContext context, Map<String, dynamic> params) async {
    try {
      categoriesState = HomeScreenState.loading;
      notifyListeners();
      final data = await getHomeCategories(context: context, params: params);
      if (data[ApiAndParams.status].toString() == "1") {
        homeCategories = (data[ApiAndParams.data] as List<dynamic>)
            .map((e) => HomeCategories.fromJson(e))
            .toList();
        categoriesState = HomeScreenState.loaded;
      } else {
        categoriesState = HomeScreenState.error;
      }
      notifyListeners();
    } catch (e) {
      categoriesState = HomeScreenState.error;
      notifyListeners();
    }
  }

  Future<void> loadEta(BuildContext context,
      [Map<String, dynamic> params = const {}]) async {
    try {
      etaState = HomeScreenState.loading;
      notifyListeners();
      final latitude = double.parse(params[ApiAndParams.latitude] ??
          Constant.session
              .getData(SessionManager.keyLatitude, defaultValue: "0.0"));
      final longitude = double.parse(params[ApiAndParams.longitude] ??
          Constant.session
              .getData(SessionManager.keyLongitude, defaultValue: "0.0"));
      estimatedTime = await fetchEstimatedTime(
          latitude: latitude, longitude: longitude, context: context);

      if (estimatedTime == null) {
        // Fallback to Madhapur, Hyderabad if ETA fails
        Constant.session.setData(SessionManager.keyLatitude, "17.4483", false);
        Constant.session.setData(SessionManager.keyLongitude, "78.3915", false);
        Constant.session.setData(SessionManager.keyAddress,
            "Madhapur, Hyderabad, Telangana, India", false);
        etaState = HomeScreenState.error;
      } else {
        etaState = HomeScreenState.loaded;
      }
      notifyListeners();
    } catch (e) {
      // Fallback on catch as well
      Constant.session.setData(SessionManager.keyLatitude, "17.4483", false);
      Constant.session.setData(SessionManager.keyLongitude, "78.3915", false);
      Constant.session.setData(SessionManager.keyAddress,
          "Madhapur, Hyderabad, Telangana, India", false);
      etaState = HomeScreenState.error;
      notifyListeners();
    }
  }

  Future<String?> fetchEstimatedTime({
    required double latitude,
    required double longitude,
    required BuildContext context,
  }) async {
    try {
      String apiName = 'nearest-store';
      Map<String, dynamic> params = {
        'latitude': latitude,
        'longitude': longitude,
      };

      final response = await sendApiRequest(
        apiName: apiName,
        params: params,
        isPost: false,
        context: context,
      );

      if (response != null) {
        final data = json.decode(response);
        nearestStoreMessage = data['message']?.toString();

        if (data['status'] == true && data['data'] != null) {
          final storeData = data['data'] as Map<String, dynamic>;
          final mins = storeData['travel_time_minutes'];
          final parsedMins = mins is int
              ? mins
              : int.tryParse(mins?.toString() ?? '') ?? 0;

          travelTimeMinutes = parsedMins;
          nearestStoreName = storeData['store_name']?.toString();
          isServiceable = true;

          final formatted = "In $parsedMins Minutes";
          Constant.session
              .setData(SessionManager.keyMinutes, formatted, true);
          return formatted;
        } else {
          // Not serviceable in this area
          travelTimeMinutes = null;
          nearestStoreName = null;
          isServiceable = false;
          return null;
        }
      }
      return null;
    } catch (e) {
      dev.log("Error fetching estimated time: $e");
      return null;
    }
  }

  void getSliderImages(List<OfferImages>? offerImages) {
    homeOfferImagesMap = {};
    if (offerImages != null) {
      for (final offerImage in offerImages) {
        final key = offerImage.position ?? '';
        homeOfferImagesMap.putIfAbsent(key, () => []).add(offerImage);
      }
    }
    notifyListeners();
  }

  // Convert StoreSliders to Sliders format for compatibility
  List<Sliders> getConvertedSliders() {
    return storeSliders
        .map((storeSlider) => Sliders.fromJson(storeSlider.toSlidersJson()))
        .toList();
  }

  // Getter for sweet house sliders (first slider from each sweet house store)
  List<Sliders> get sweetHouseSliders {
    // Map to store first slider for each sweet house store
    final Map<String?, StoreSlider> firstSliderPerStore = {};

    // Get sliders grouped by type_id (keeping only the first one per store)
    for (final slider in storeSliders) {
      if (slider.typeId != null &&
          !firstSliderPerStore.containsKey(slider.typeId)) {
        firstSliderPerStore[slider.typeId] = slider;
      }
    }

    // Get IDs of all sweet house stores
    final sweetHouseStoreIds = topRatedSweetHouses
        .map((seller) => seller.storeId?.toString())
        .where((id) => id != null)
        .toSet();

    // Filter to get only first sliders from sweet house stores
    return firstSliderPerStore.entries
        .where((entry) => sweetHouseStoreIds.contains(entry.key))
        .map((entry) => Sliders.fromJson(entry.value.toSlidersJson()))
        .toList();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
