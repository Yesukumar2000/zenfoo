import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/category_groups.dart';
import 'package:project/models/store_with_category_group.dart';
import 'package:project/models/category_filter_models.dart';
import 'package:project/models/combo.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class CategoriesPageProvider extends ChangeNotifier {
  int selectedStoreIdx = 0;
  // Index of the selected category group in [allGroups] (left sidebar).
  int selectedGroupIdx = 0;
  List<CategoryGroup> stores = [];
  List<StoreWithCategoryGroups> selectedStoreDetail = [];
  List<BannerItem> banners = [];
  List<Combo> combos = [];
  bool loadingStores = false;
  bool loadingCategories = false;
  bool loadingCombos = false;

  // Scroll controller and refresh controller
  late ScrollController _scrollController;
  ScrollController _leftSidebarController = ScrollController();
  RefreshController _refreshController = RefreshController();

  // Indicators
  bool _showScrollDownIndicator = false;
  bool _showScrollUpIndicator = false;
  Timer? _scrollIndicatorTimer;
  Timer? _hideIndicatorTimer;

  // Category section tracking
  Map<String, GlobalKey> _categoryKeys = {};
  int _currentCategoryIndex = -1;
  String? _nextCategoryName;
  String? _previousCategoryName;
  bool _isAutoScrolling = false;

  // Scroll completion tracking
  Timer? _scrollCompletionTimer;
  bool _scrollCompletedAtBottom = false;
  bool _scrollCompletedAtTop = false;

  // Touch-hold tracking for load more
  Timer? _holdTimer;
  bool _isHoldingAtBottom = false;
  bool _holdCompletedAtBottom = false;

  ScrollController get scrollController => _scrollController;
  ScrollController get leftSidebarController => _leftSidebarController;
  RefreshController get refreshController => _refreshController;
  bool get showScrollDownIndicator => _showScrollDownIndicator;
  bool get showScrollUpIndicator => _showScrollUpIndicator;
  String? get nextCategoryName => _nextCategoryName;
  String? get previousCategoryName => _previousCategoryName;
  bool get holdCompletedAtBottom => _holdCompletedAtBottom;

  // Store navigation helpers
  String? get nextStoreName => selectedStoreIdx < stores.length - 1
      ? stores[selectedStoreIdx + 1].name
      : null;
  String? get previousStoreName =>
      selectedStoreIdx > 0 ? stores[selectedStoreIdx - 1].name : null;
  bool get hasNextStore => selectedStoreIdx < stores.length - 1;
  bool get hasPreviousStore => selectedStoreIdx > 0;

  final BuildContext context;
  final ScrollController? _externalScrollController;

  CategoriesPageProvider(this.context, {ScrollController? scrollController})
      : _externalScrollController = scrollController {
    _scrollController = scrollController ?? ScrollController();
    try {
      _scrollController.addListener(_onScroll);
    } catch (e) {
      // ScrollController might be disposed if parent widget was disposed
      debugPrint('Warning: Could not add listener to ScrollController: $e');
    }
  }

  /// Generate keys for each category section
  void generateCategoryKeys() {
    _categoryKeys.clear();
    for (var store in selectedStoreDetail) {
      for (var cg in store.categoryGroups) {
        _categoryKeys[cg.id.toString()] = GlobalKey();
      }
    }
  }

  /// Get key for a category
  GlobalKey? getCategoryKey(String categoryId) {
    return _categoryKeys[categoryId];
  }

  /// All category groups across the loaded store(s), flattened.
  /// Drives the left sidebar in the categories page.
  List<CategoryGroup> get allGroups {
    final groups = <CategoryGroup>[];
    for (var store in selectedStoreDetail) {
      groups.addAll(store.categoryGroups);
    }
    return groups;
  }

  /// Select a category group from the left sidebar.
  void selectGroup(int idx) {
    if (idx < 0 || idx >= allGroups.length || idx == selectedGroupIdx) return;
    selectedGroupIdx = idx;
    notifyListeners();
  }

  /// Handle pull to refresh - smooth transition
  Future<void> onRefresh() async {
    if (selectedStoreIdx <= 0) {
      _refreshController.refreshCompleted();
      return;
    }

    // Reset scroll and hold completion flags
    _resetHoldState();
    _scrollCompletedAtTop = false;

    // Smooth fade-out effect
    await Future.delayed(const Duration(milliseconds: 300));

    final previousIdx = selectedStoreIdx - 1;
    await selectStore(context, previousIdx);

    // Scroll to bottom smoothly after content loads
    await Future.delayed(const Duration(milliseconds: 200));
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInCubic,
      );
    }

    _refreshController.refreshCompleted();
  }

  /// Handle load more - smooth transition
  Future<void> onLoadMore() async {
    if (selectedStoreIdx >= stores.length - 1) {
      _refreshController.loadComplete();
      return;
    }

    // Reset scroll and hold completion flags
    _resetHoldState();
    _scrollCompletedAtTop = false;

    // Smooth transition
    await Future.delayed(const Duration(milliseconds: 300));

    final nextIdx = selectedStoreIdx + 1;
    await selectStore(context, nextIdx);

    // Ensure scroll starts at top
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _refreshController.loadComplete();
  }

  /// Select store with smooth reset
  Future<void> selectStore(BuildContext context, int idx) async {
    if (stores.isEmpty || idx < 0 || idx >= stores.length) return;

    selectedStoreIdx = idx;
    loadingCategories = true;
    _hideAllIndicators();
    notifyListeners();

    // Scroll left sidebar to center the selected store
    if (_leftSidebarController.hasClients && stores.isNotEmpty) {
      // Calculate item height (approximately 72px per item based on UI)
      const double itemHeight = 72.0;
      final double targetOffset = (idx * itemHeight) -
          (_leftSidebarController.position.viewportDimension / 2) +
          (itemHeight / 2);

      // Ensure offset is within bounds
      final double maxScroll = _leftSidebarController.position.maxScrollExtent;
      final double clampedOffset = targetOffset.clamp(0.0, maxScroll);

      _leftSidebarController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    try {
      final selectedId = stores[idx].id;

      // Handle "All" stores section (ID = 0)
      if (selectedId == 0) {
        // For "All" section, load combos and categories from all available stores
        selectedStoreDetail.clear();
        banners.clear();

        final allStores = stores.where((s) => s.id != 0 && s.id != 15).toList();

        // Load combos from all stores
        List<Combo> allCombos = [];
        final nullStoreIdCombos =
            await fetchCombosHomePage(context: context, storeId: null);
        allCombos.addAll(nullStoreIdCombos);

        // If we got combos from null storeId, use those. Otherwise, fetch from individual stores
        if (allCombos.isEmpty && allStores.isNotEmpty) {
          for (final store in allStores) {
            final storeCombos =
                await fetchCombosHomePage(context: context, storeId: store.id);
            allCombos.addAll(storeCombos);
          }
        }

        combos = allCombos;
        print('DEBUG: All mode loaded ${combos.length} total combos');

        // Load categories from all stores
        if (allStores.isNotEmpty) {
          for (final store in allStores) {
            final result = await fetchStoreWithCategoryGroups(
                context: context, storeId: store.id.toString());
            if (result != null) {
              selectedStoreDetail.addAll(result.stores);
              // Only add banners from first store (to avoid duplicate banners)
              if (banners.isEmpty) {
                banners.addAll(result.banners);
              }
            }
          }
          generateCategoryKeys();
        }

        selectedGroupIdx = 0;
        loadingCategories = false;
        notifyListeners();
      } else {
        // Load specific store details
        final result = await fetchStoreWithCategoryGroups(
            context: context, storeId: selectedId.toString());

        if (result != null) {
          selectedStoreDetail.clear();
          selectedStoreDetail.addAll(result.stores);
          banners.clear();
          banners.addAll(result.banners);
          generateCategoryKeys();

          selectedGroupIdx = 0;
          _currentCategoryIndex = 0;

          // Load combos for the selected store
          await loadCombos(context, storeId: stores[idx].id);

          // Show initial indicator after content loads
          Future.delayed(const Duration(milliseconds: 600), () {
            _checkAndShowInitialIndicator();
          });
        }

        loadingCategories = false;
        notifyListeners();
      }
    } catch (e) {
      loadingCategories = false;
      notifyListeners();
      print('Error loading categories: $e');
    }
  }

  /// Main scroll listener
  void _onScroll() {
    if (!_scrollController.hasClients || _isAutoScrolling) return;

    final position = _scrollController.position;
    final pixels = position.pixels;
    final maxScroll = position.maxScrollExtent;
    final atBottom = pixels >= maxScroll - 5;

    // Check if user is trying to scroll DOWN (further) after holding at bottom
    // Only trigger if they're trying to go beyond the bottom (scroll down gesture)
    if (_holdCompletedAtBottom && hasNextStore) {
      // Check if this is a downward scroll attempt (trying to go further)
      // This happens when user is at/near bottom and tries to scroll down more
      if (atBottom) {
        // Still at bottom and trying to scroll - this is the "release" we want
        print('User trying to scroll down after hold - loading next store');
        _resetHoldState();
        onLoadMore();
        return;
      } else if (pixels < maxScroll - 10) {
        // User scrolled UP (away from bottom) - cancel the hold
        print('User scrolled up after hold - canceling load');
        _resetHoldState();
      }
    }

    // If user scrolls away from bottom before hold completes, reset
    if (_isHoldingAtBottom && !atBottom) {
      print('User scrolled away before hold completed - resetting');
      _resetHoldState();
    }

    // Cancel existing completion timer
    _scrollCompletionTimer?.cancel();

    // Cancel existing timers
    _scrollIndicatorTimer?.cancel();
    _hideIndicatorTimer?.cancel();

    // Hide indicators while scrolling
    if (_showScrollDownIndicator || _showScrollUpIndicator) {
      _showScrollDownIndicator = false;
      _showScrollUpIndicator = false;
      notifyListeners();
    }

    // Detect current category and update left sidebar
    _detectCurrentCategoryAndSync();

    // Reset completion flags if we move away from edges
    if (!atBottom && _scrollCompletedAtBottom) {
      _scrollCompletedAtBottom = false;
    }

    final atTop = pixels <= 5;
    if (!atTop && _scrollCompletedAtTop) {
      _scrollCompletedAtTop = false;
    }

    // Set a timer to detect when scrolling has stopped
    _scrollCompletionTimer = Timer(const Duration(milliseconds: 150), () {
      _onScrollComplete(pixels, maxScroll);
    });
  }

  /// Reset hold state
  void _resetHoldState() {
    _holdTimer?.cancel();
    _isHoldingAtBottom = false;
    _holdCompletedAtBottom = false;
    _scrollCompletedAtBottom = false;
  }

  /// Called when scrolling has completed (user stopped scrolling)
  void _onScrollComplete(double pixels, double maxScroll) {
    final atBottom = pixels >= maxScroll - 5;
    final atTop = pixels <= 5;

    // Start hold timer when scroll completes at bottom
    if (atBottom && !_scrollCompletedAtBottom) {
      _scrollCompletedAtBottom = true;
      _isHoldingAtBottom = true;
      _holdCompletedAtBottom = false;

      print(
          'Scroll completed at bottom - hold for 1 second to load next store');

      // Start 1-second hold timer
      _holdTimer?.cancel();
      _holdTimer = Timer(const Duration(milliseconds: 1000), () {
        if (_isHoldingAtBottom && _scrollCompletedAtBottom) {
          _holdCompletedAtBottom = true;
          print('Hold completed - release to load next store');
        }
      });
    }

    // Mark scroll completion at top
    if (atTop && !_scrollCompletedAtTop) {
      _scrollCompletedAtTop = true;
      print('Scroll completed at top');
    }

    // Show indicators after user stops scrolling (but not at edges)
    if (!atBottom && !atTop) {
      _scrollIndicatorTimer = Timer(const Duration(milliseconds: 600), () {
        _updateScrollIndicators(pixels, maxScroll);
      });
    }
  }

  /// Detect which category is currently in view
  void _detectCurrentCategoryAndSync() {
    if (selectedStoreDetail.isEmpty || !_scrollController.hasClients) return;

    final screenHeight = _scrollController.position.viewportDimension;
    final scrollOffset = _scrollController.offset;
    final triggerPoint = scrollOffset + (screenHeight * 0.3);

    int categoryIndex = 0;
    int totalCategoriesCount = 0;

    for (var store in selectedStoreDetail) {
      totalCategoriesCount += store.categoryGroups.length;
    }

    for (var store in selectedStoreDetail) {
      for (var cg in store.categoryGroups) {
        final key = _categoryKeys[cg.id.toString()];
        if (key?.currentContext != null) {
          try {
            final RenderBox box =
                key!.currentContext!.findRenderObject() as RenderBox;
            final position = box.localToGlobal(Offset.zero);
            final categoryTop = position.dy + scrollOffset;
            final categoryBottom = categoryTop + box.size.height;

            if (triggerPoint >= categoryTop && triggerPoint < categoryBottom) {
              if (_currentCategoryIndex != categoryIndex) {
                _currentCategoryIndex = categoryIndex;
                _updateCategoryNames(totalCategoriesCount, categoryIndex);
                _scrollLeftSidebarToCategory(categoryIndex);
                notifyListeners();
              }
              return;
            }
          } catch (e) {
            // Handle case where widget is not yet rendered
          }
        }
        categoryIndex++;
      }
    }
  }

  /// Scroll left sidebar to show active category
  void _scrollLeftSidebarToCategory(int categoryIndex) {
    if (!_leftSidebarController.hasClients) return;

    const itemHeight = 100.0;
    final targetOffset = categoryIndex * itemHeight - 50;
    final maxOffset = _leftSidebarController.position.maxScrollExtent;
    final clampedOffset = targetOffset.clamp(0.0, maxOffset);

    _leftSidebarController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// Update next and previous category names
  void _updateCategoryNames(int totalCategories, int currentIndex) {
    final allCategories = <String>[];
    for (var s in selectedStoreDetail) {
      for (var cg in s.categoryGroups) {
        allCategories.add(cg.name);
      }
    }

    _previousCategoryName =
        currentIndex > 0 ? allCategories[currentIndex - 1] : null;
    _nextCategoryName = currentIndex < allCategories.length - 1
        ? allCategories[currentIndex + 1]
        : null;
  }

  /// Update scroll indicators
  void _updateScrollIndicators(double pixels, double maxScroll) {
    // Don't show indicators at very top or bottom (handled by refresh/load more)
    if (pixels <= 10 || pixels >= maxScroll - 20) return;

    // Middle area - show category indicators
    if (pixels < maxScroll - 100 && _nextCategoryName != null) {
      _showScrollDownIndicator = true;
      notifyListeners();

      _hideIndicatorTimer = Timer(const Duration(seconds: 2), () {
        _showScrollDownIndicator = false;
        notifyListeners();
      });
    }

    if (pixels > 100 && _previousCategoryName != null) {
      _showScrollUpIndicator = true;
      notifyListeners();

      _hideIndicatorTimer = Timer(const Duration(seconds: 2), () {
        _showScrollUpIndicator = false;
        notifyListeners();
      });
    }
  }

  /// Load all store groups
  Future<void> loadStores(BuildContext context) async {
    loadingStores = true;
    notifyListeners();

    try {
      final allStores = await fetchStoreGroups(context);

      // Filter out store with ID 15
      final filteredStores =
          allStores.where((store) => store.id != 15 && store.id != 0).toList();

      // Add "All" store at the beginning with ID 0
      final allStore = CategoryGroup(
        id: 0,
        name: 'All',
        icon: null,
        iconUrl: null,
        color: null,
      );

      stores = [allStore, ...filteredStores];

      loadingStores = false;
      notifyListeners();

      if (stores.isNotEmpty) {
        await selectStore(context, 0);
      }
    } catch (e) {
      loadingStores = false;
      notifyListeners();
      print('Error loading stores: $e');
    }
  }

  /// Load combos for the category page based on selected store
  Future<void> loadCombos(BuildContext context, {int? storeId}) async {
    loadingCombos = true;
    notifyListeners();

    try {
      combos = await fetchCombosHomePage(
        context: context,
        storeId: storeId,
      );
      print(
          'DEBUG: loadCombos loaded ${combos.length} combos for storeId=$storeId');
      loadingCombos = false;
      notifyListeners();
    } catch (e) {
      loadingCombos = false;
      notifyListeners();
      print('Error loading combos: $e');
    }
  }

  /// Show initial indicator
  void _checkAndShowInitialIndicator() {
    if (selectedStoreDetail.isEmpty) return;

    final allCategories = <String>[];
    for (var s in selectedStoreDetail) {
      for (var cg in s.categoryGroups) {
        allCategories.add(cg.name);
      }
    }

    if (allCategories.length > 1) {
      _nextCategoryName = allCategories.length > 1 ? allCategories[1] : null;
    }
  }

  /// Scroll to next category
  Future<void> scrollToNextCategory() async {
    if (_currentCategoryIndex == -1 || selectedStoreDetail.isEmpty) return;

    int nextIndex = _currentCategoryIndex + 1;
    int totalCategories = 0;

    for (var store in selectedStoreDetail) {
      totalCategories += store.categoryGroups.length;
    }

    if (nextIndex >= totalCategories) return;

    _isAutoScrolling = true;
    _hideAllIndicators();

    int keyIndex = 0;
    for (var store in selectedStoreDetail) {
      for (var cg in store.categoryGroups) {
        if (keyIndex == nextIndex) {
          final key = _categoryKeys[cg.id.toString()];
          if (key?.currentContext != null) {
            await Scrollable.ensureVisible(
              key!.currentContext!,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              alignment: 0.15,
            );
          }
          _isAutoScrolling = false;
          return;
        }
        keyIndex++;
      }
    }
    _isAutoScrolling = false;
  }

  /// Scroll to previous category
  Future<void> scrollToPreviousCategory() async {
    if (_currentCategoryIndex <= 0 || selectedStoreDetail.isEmpty) return;

    int prevIndex = _currentCategoryIndex - 1;

    _isAutoScrolling = true;
    _hideAllIndicators();

    int keyIndex = 0;
    for (var store in selectedStoreDetail) {
      for (var cg in store.categoryGroups) {
        if (keyIndex == prevIndex) {
          final key = _categoryKeys[cg.id.toString()];
          if (key?.currentContext != null) {
            await Scrollable.ensureVisible(
              key!.currentContext!,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              alignment: 0.15,
            );
          }
          _isAutoScrolling = false;
          return;
        }
        keyIndex++;
      }
    }
    _isAutoScrolling = false;
  }

  /// Hide all indicators
  void _hideAllIndicators() {
    _scrollIndicatorTimer?.cancel();
    _hideIndicatorTimer?.cancel();
    _showScrollDownIndicator = false;
    _showScrollUpIndicator = false;
  }

  /// Manually hide indicators
  void hideScrollIndicators() {
    _hideAllIndicators();
    notifyListeners();
  }

  @override
  void dispose() {
    try {
      _scrollController.removeListener(_onScroll);
    } catch (e) {
      debugPrint('Warning: Error removing scroll listener: $e');
    }

    // Only dispose the scroll controller if we created it locally
    if (_externalScrollController == null) {
      try {
        _scrollController.dispose();
      } catch (e) {
        debugPrint('Warning: Error disposing scroll controller: $e');
      }
    }

    try {
      _leftSidebarController.dispose();
    } catch (e) {
      debugPrint('Warning: Error disposing left sidebar controller: $e');
    }

    try {
      _refreshController.dispose();
    } catch (e) {
      debugPrint('Warning: Error disposing refresh controller: $e');
    }

    _scrollIndicatorTimer?.cancel();
    _hideIndicatorTimer?.cancel();
    _scrollCompletionTimer?.cancel();
    _holdTimer?.cancel();
    super.dispose();
  }
}
