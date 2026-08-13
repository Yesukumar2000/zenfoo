import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/utils/locationPermissionService.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:project/models/combo.dart';
import 'package:project/models/category_groups.dart';
import 'package:project/models/store_with_category_group.dart';
import '../../../models/sortby_filter_model.dart';
import 'package:project/provider/comboDetailProvider.dart';
import 'package:project/provider/combosProvider.dart';
import 'package:project/provider/notesProvider.dart';
import 'package:project/provider/orderTrackingProvider.dart';
import 'package:project/provider/appLaunchBannerProvider.dart';
import 'package:project/provider/userOffersProvider.dart';
import 'package:project/screens/categoryProducts/category_products_page.dart';
import 'package:project/screens/categoryProducts/widgets/banners_home.dart';
import 'package:project/screens/combos/comboDetailScreen.dart';
import 'package:project/helper/utils/storeHoursService.dart';
import 'package:project/screens/combos/combosScreen.dart';
import 'package:project/screens/mainHomeScreen/homeScreen/widget/categories_grid.dart';
import 'package:project/screens/mainHomeScreen/homeScreen/widget/category_header_tab.dart';
import 'package:project/screens/mainHomeScreen/homeScreen/widget/store_categories_horizontal.dart';
import 'package:project/screens/mainHomeScreen/homeScreen/widget/banner_media_widget.dart';
import 'package:project/screens/mainHomeScreen/homeScreen/widget/store_sellers_list.dart';
import 'package:project/screens/mainHomeScreen/homeScreen/widget/milestone_rewards_bottom_sheet.dart';
import 'package:project/screens/mainHomeScreen/homeScreen/widget/thinking_items_horizontal.dart';
import 'package:project/screens/mainHomeScreen/homeScreen/widget/home_sections_widget.dart';
import 'package:project/helper/generalWidgets/catalogue_image.dart';
import 'package:project/helper/styles/section_heading.dart';
import 'package:project/screens/mainHomeScreen/homeScreen/widget/buy_it_again_rail.dart';
import 'package:project/screens/mainHomeScreen/homeScreen/widget/rewards_progress_strip.dart';
import 'package:project/provider/reorderProvider.dart';
import 'package:project/screens/notes/notesListScreen.dart';
import 'package:project/screens/supermartDetail/supermart_detail_screen.dart';
import 'package:project/screens/sweetHouseDetail/sweet_house_detail_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'dart:developer' as dev;
import 'package:project/provider/themeProvider.dart' as app_theme;

import 'package:velocity_x/velocity_x.dart';

import '../../../helper/styles/appColorScheme.dart' show AppColorScheme;

/// Vertical rhythm for the home feed. Sections are separated by [_sectionGap]
/// and every section heading sits [_headingTopGap] below the block above it
/// with [_headingBottomGap] under the text, so the whole page reads on one
/// spacing scale instead of the assorted 8/12/16s it grew.
const double _sectionGap = 24;
const double _headingTopGap = 16;
const double _headingBottomGap = 8;

/// Position of the Reorder tab in the bottom navigation — see
/// [HomeMainScreenProvider.setPages].
const int _reorderTabIndex = 3;

/// Height of the compact "delivering to" strip that appears inside the pinned
/// header. Only shown once the tall delivery header has scrolled away, so the
/// ETA and address never leave the screen.
const double _pinnedDeliveryStripHeight = 34;

/// Height of the search + tabs block that is always in the pinned header.
const double _stickyHeaderBaseHeight = 148;

/// A Special Items card carries its own label.
///
/// The label used to sit under the card in white — on the section's light
/// peach background, which is roughly a 1.5:1 contrast ratio and effectively
/// unreadable. Putting it inside the card over a dark scrim fixes that for
/// good: the label no longer depends on whatever colour the section behind it
/// happens to be, and the card stops being a plain white square with a caption
/// floating under it.
///
/// Folding the label in also removes the separate 29dp text block, so the
/// taller card costs less vertical space than the old stack.
const double _specialItemCard = 116;
const double _specialItemExtent = _specialItemCard;

/// Height of the gradient behind the label — deep enough to carry white text
/// over a pale packshot, short enough to leave the product visible.
const double _specialItemScrim = 52;

/// Section headings come from the shared style so the home feed and the
/// API-driven product sections below it stay in one voice.
TextStyle _sectionHeadingStyle(Color color) => sectionHeadingStyle(color);

class HomeScreen extends StatefulWidget {
  final ScrollController scrollController;
  const HomeScreen({Key? key, required this.scrollController})
      : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final RefreshController _refreshController = RefreshController();
  final GlobalKey _headerKey = GlobalKey();
  bool _isSticked = false;
  bool _showScrollToTop = false;
  late final ValueNotifier<double> _headerHeight = ValueNotifier<double>(0);
  HomeScreenProvider? _homeScreenProvider;
  ThinkingItemsProvider? _thinkingItemsProvider;

  void _onHomeScreenChanged() {
    if (_homeScreenProvider == null || _thinkingItemsProvider == null) return;
    if (_homeScreenProvider!.topRatedSweetHouses.isNotEmpty &&
        _thinkingItemsProvider!.state == ThinkingItemsState.initial) {
      _thinkingItemsProvider!.fetchThinkingItems(context);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.scrollController.addListener(scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _homeScreenProvider = context.read<HomeScreenProvider>();
        _thinkingItemsProvider = context.read<ThinkingItemsProvider>();
        _homeScreenProvider!.addListener(_onHomeScreenChanged);
      }
    });

    Future.delayed(Duration.zero).then((_) async {
      // Request location permission on app launch
      await _requestLocationPermission();
      if (!mounted) return;

      await getAppSettings(context: context); // Custom function
      if (!mounted) return;

      // Fetch app launch banner
      await context.read<AppLaunchBannerProvider>().fetchBanner(context);
      if (!mounted) return;

      // Load saved addresses early so the default address's lat/long
      // are synced to session BEFORE getProductsDefaultParams reads them.
      if (Constant.session.isUserLoggedIn()) {
        final addressProvider = context.read<AddressProvider>();
        addressProvider.offset = 0;
        addressProvider.addresses = [];
        await addressProvider.getAddressProvider(context: context);
        if (!mounted) return;
      }

      // Fetch home sections
      context.read<HomeSectionsProvider>().fetchHomeSections(context);

      final params = await Constant.getProductsDefaultParams();
      if (!mounted) return;

      context
          .read<HomeScreenProvider>()
          .loadSections(params: params, context: context);
      await context
          .read<ProductListProvider>()
          .getProductListProvider(context: context, params: params);
      if (!mounted) return;

      if (Constant.session.isUserLoggedIn()) {
        await context
            .read<CartProvider>()
            .getCartListProvider(context: context);
        if (!mounted) return;

        await context
            .read<CartListProvider>()
            .getAllCartItems(context: context);
        if (!mounted) return;

        final userDetail = await getUserDetail(context: context);
        if (!mounted) return;
        if (userDetail[ApiAndParams.status].toString() == "1") {
          context
              .read<UserProfileProvider>()
              .updateUserDataInSession(userDetail, context);
        }

        // Fetch active order for tracking overlay
        await context
            .read<OrderTrackingProvider>()
            .fetchActiveOrder(context: context);
        if (!mounted) return;

        // Fetch user offers/rewards data
        await context.read<UserOffersProvider>().fetchUserOffers(context);
        if (!mounted) return;

        // Past orders, for the "Buy it again" rail. Deliberately not awaited:
        // the rail is a Consumer and fills itself in when this lands, so it
        // must not sit in front of anything else in the startup chain.
        context.read<ReorderProvider>().getReorderableOrders(context: context);

        // Show milestone rewards bottom sheet once
        _showMilestoneBottomSheetIfNeeded();
      } else {
        context.read<CartListProvider>().setGuestCartItems();
        if (context.read<CartListProvider>().cartList.isNotEmpty) {
          await context
              .read<CartProvider>()
              .getGuestCartListProvider(context: context);
        }
      }
    });
  }

  void _showMilestoneBottomSheetIfNeeded() {
    if (mounted) {
      // Wait for the build to complete, then show the bottom sheet
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          final provider = context.read<UserOffersProvider>();
          // Only show if user has active milestones and not all are claimed
          if (provider.milestones.isNotEmpty &&
              provider.nextMilestone != null) {
            MilestoneRewardsBottomSheet.show(context);
          }
        }
      });
    }
  }

  scrollListener() async {
    if (!mounted) return;
    // Check if header is sticked
    if (_headerKey.currentContext != null) {
      final RenderBox? renderBox =
          _headerKey.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final headerHeight = renderBox.size.height;
        // Subtract a small buffer (e.g. 5) to ensure smooth transition
        final isSticked = widget.scrollController.offset >= headerHeight - 5;
        if (isSticked != _isSticked) {
          setState(() {
            _isSticked = isSticked;
          });
        }
      }
    }

    // Show scroll-to-top button when scrolled down more than 300 pixels
    final shouldShowButton = widget.scrollController.offset > 300;
    if (shouldShowButton != _showScrollToTop) {
      setState(() {
        _showScrollToTop = shouldShowButton;
      });
    }

    var nextPageTrigger =
        0.7 * widget.scrollController.position.maxScrollExtent;
    if (widget.scrollController.position.pixels > nextPageTrigger) {
      if (mounted) {
        if (context.read<ProductListProvider>().hasMoreData &&
            context.read<ProductListProvider>().productState !=
                ProductState.loadingMore) {
          Map<String, String> params =
              await Constant.getProductsDefaultParams();
          if (!mounted) return;
          await context
              .read<ProductListProvider>()
              .getProductListProvider(context: context, params: params);
        }

        // Load more home sections — only on the "all stores" tab
        // (i.e. when cat_store is called without /id)
        if (!mounted) return;
        if (context.read<HomeScreenProvider>().selectedStoreIdx == 0) {
          final homeSectionsProvider = context.read<HomeSectionsProvider>();
          if (homeSectionsProvider.hasMore &&
              !homeSectionsProvider.isLoadingMore) {
            homeSectionsProvider.loadMore(context);
          }
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // App came back from background/screen lock
      // Refresh active order overlay
      if (Constant.session.isUserLoggedIn() && mounted) {
        context
            .read<OrderTrackingProvider>()
            .fetchActiveOrder(context: context);
      }
    }
  }

  @override
  void dispose() {
    _homeScreenProvider?.removeListener(_onHomeScreenChanged);
    _homeScreenProvider = null;
    _thinkingItemsProvider = null;
    WidgetsBinding.instance.removeObserver(this);
    widget.scrollController.removeListener(scrollListener);
    _headerHeight.dispose();
    super.dispose();
  }

  Future<void> refreshList() async {
    final params = await Constant.getProductsDefaultParams();
    if (!mounted) return;

    context
        .read<HomeScreenProvider>()
        .loadSections(params: params, context: context);
    await getAppSettings(context: context);
    if (!mounted) return;

    // Refresh app launch banner
    await context.read<AppLaunchBannerProvider>().fetchBanner(context);
    if (!mounted) return;

    await context
        .read<ProductListProvider>()
        .getProductListProvider(context: context, params: params);
    if (!mounted) return;

    if (Constant.session.isUserLoggedIn()) {
      // Refresh cart with new address (for delivery charges update)
      await context
          .read<CartProvider>()
          .refreshCart(context: context, silent: true);
      if (!mounted) return;

      await context.read<CartListProvider>().getAllCartItems(context: context);
      if (!mounted) return;

      final userDetail = await getUserDetail(context: context);
      if (!mounted) return;
      if (userDetail[ApiAndParams.status].toString() == "1") {
        context
            .read<UserProfileProvider>()
            .updateUserDataInSession(userDetail, context);
      }

      // Refresh active order for tracking overlay
      await context
          .read<OrderTrackingProvider>()
          .fetchActiveOrder(context: context);
    } else {
      context.read<CartListProvider>().setGuestCartItems();
      if (context.read<CartListProvider>().cartList.isNotEmpty) {
        await context
            .read<CartProvider>()
            .getGuestCartListProvider(context: context);
      }
    }
    _refreshController.refreshCompleted();
  }

  Future<void> onAddressSelected(UserAddressData address) async {
    // Build address string
    final addressString = _buildAddressString(address);

    // Update session with new address
    Constant.session.setData(
      SessionManager.keyAddress,
      addressString,
      true,
    );
    Constant.session.setData(
      SessionManager.keyAddressObject,
      address.type ?? "Home",
      true,
    );

    // Update contact details from address
    if (address.name != null && address.name!.isNotEmpty) {
      Constant.session.setData(
        SessionManager.keyUserName,
        address.name!,
        true,
      );
    }
    if (address.mobile != null && address.mobile!.isNotEmpty) {
      Constant.session.setData(
        SessionManager.keyPhone,
        address.mobile!,
        true,
      );
    }

    // Update cart provider contact details
    final cartProvider = context.read<CartProvider>();
    if (address.name != null && address.name!.isNotEmpty) {
      cartProvider.updateUserName(address.name!);
    }
    if (address.mobile != null && address.mobile!.isNotEmpty) {
      cartProvider.updateUserPhone(address.mobile!);
    }

    // Save cart metadata with updated contact details
    await cartProvider.saveCartMetadata(
      context: context,
      contactName: address.name,
      contactPhone: address.mobile,
    );

    // Update the address to be default on backend
    await updateAddressApi(
      context: context,
      params: {
        ApiAndParams.id: address.id,
        ApiAndParams.name: address.name,
        ApiAndParams.mobile: address.mobile,
        ApiAndParams.alternateMobile: address.alternateMobile ?? "",
        ApiAndParams.address: address.address,
        ApiAndParams.landmark: address.landmark ?? "",
        ApiAndParams.area: address.area ?? "",
        ApiAndParams.pinCode: address.pincode,
        ApiAndParams.city: address.city,
        ApiAndParams.state: address.state,
        ApiAndParams.country: address.country,
        ApiAndParams.latitude: address.latitude,
        ApiAndParams.longitude: address.longitude,
        ApiAndParams.type: address.type,
        ApiAndParams.isDefault: "1",
      },
    );

    // Refresh the home screen with new address
    await refreshList();
  }

  String _buildAddressString(UserAddressData address) {
    final parts = <String>[];

    if (address.address != null &&
        address.address!.isNotEmpty &&
        address.address != 'null') {
      parts.add(address.address!);
    }
    if (address.area != null &&
        address.area!.isNotEmpty &&
        address.area != 'null') {
      parts.add(address.area!);
    }
    if (address.landmark != null &&
        address.landmark!.isNotEmpty &&
        address.landmark != 'null') {
      parts.add(address.landmark!);
    }
    if (address.city != null &&
        address.city!.isNotEmpty &&
        address.city != 'null') {
      parts.add(address.city!);
    }
    if (address.state != null &&
        address.state!.isNotEmpty &&
        address.state != 'null') {
      parts.add(address.state!);
    }
    if (address.country != null &&
        address.country!.isNotEmpty &&
        address.country != 'null') {
      parts.add(address.country!);
    }
    if (address.pincode != null &&
        address.pincode!.isNotEmpty &&
        address.pincode != 'null') {
      parts.add(address.pincode!);
    }

    return parts.join(', ');
  }

  Future<void> _requestLocationPermission() async {
    if (!mounted) return;

    final isGranted =
        await LocationPermissionService.requestLocationPermissionWithDialog(
      context,
      title: getTranslatedValue(context, 'location_permission_title'),
      message: getTranslatedValue(context, 'location_permission_message'),
    );

    if (isGranted && mounted) {
      dev.log('Location permission granted');
      await _autoSetCurrentLocation();
    } else if (mounted) {
      dev.log('Location permission denied');
      _showAddAddressManuallyDialog();
    }
  }

  void _showAddAddressManuallyDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_rounded,
                  size: 56, color: ColorsRes.appColor),
              const SizedBox(height: 12),
              Text(
                'Location access needed',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We use your location to show nearby stores and deliver to you. You can also add an address manually.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsRes.appColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  showAddressesBottomSheet(context);
                },
                child: Text(
                  'Add Address Manually',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Maybe later',
                style: GoogleFonts.inter(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _autoSetCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      Constant.session.setData(
          SessionManager.keyLatitude, position.latitude.toString(), false);
      Constant.session.setData(
          SessionManager.keyLongitude, position.longitude.toString(), false);

      final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.subLocality?.isNotEmpty == true) parts.add(place.subLocality!);
        if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
        if (place.administrativeArea?.isNotEmpty == true) parts.add(place.administrativeArea!);
        final addressString =
            parts.isNotEmpty ? parts.join(', ') : 'Current Location';

        Constant.session.setData(SessionManager.keyAddress, addressString, true);
        dev.log('Auto-location set: $addressString');
      }
    } catch (e) {
      dev.log('Auto-location failed: $e');
    }
  }

  /// Pinned, the header clears the status bar and gains the delivery strip.
  double _stickyHeaderHeight(BuildContext context) => _isSticked
      ? _stickyHeaderBaseHeight +
          _pinnedDeliveryStripHeight +
          MediaQuery.of(context).padding.top
      : _stickyHeaderBaseHeight;

  @override
  Widget build(BuildContext context) {
    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;

        return Scaffold(
          backgroundColor: colorScheme.background,
          body: Stack(
            children: [
              Consumer<HomeScreenProvider>(
                builder: (context, provider, _) {
                  final isLoading =
                      provider.etaState == HomeScreenState.loading ||
                          provider.groupState == HomeScreenState.loading ||
                          provider.storeDataState == HomeScreenState.loading;
                  // The branded full-screen loader is for the cold start only.
                  // Once there is anything to show, a refresh or a tab switch
                  // keeps the page in place and leans on the per-section
                  // loading states below — blanking the whole home screen on
                  // every reload made the app feel like it was restarting.
                  final hasContent = provider.storeGroups.isNotEmpty ||
                      provider.categoryGroups.isNotEmpty;
                  if (isLoading && !hasContent) {
                    return const HomeLoadingScreen();
                  }

                  final groups = provider.categoryGroups;
                  dev.log("Displaying ${groups.length} category groups");
                  // Use sliders from cat_store API instead of separate slider API
                  final sliders = provider.getConvertedSliders();

                  // Show category groups with sliders shown after all groups of a store
                  List<Widget> sectionWidgets = [];
                  Set<int> shownStoreSliders =
                      {}; // Track which store's sliders we've shown
                  // True once at least one real category grid is queued, so the
                  // "Shop by Category" heading is never shown over sliders alone.
                  bool hasCategoryGrid = false;

                  if (provider.isMeatStore) {
                    // Meat store: render all CategoryGroups as a single flat grid
                    sectionWidgets.add(
                      CategoryGroupsList(
                        groups: groups,
                        isMeat: true,
                        homeLimit: true,
                      ),
                    );
                    hasCategoryGrid = groups.isNotEmpty;
                    // Still show store sliders below the grid
                    for (final group in groups) {
                      final storeId = group.storeId;
                      if (storeId != null &&
                          !shownStoreSliders.contains(storeId)) {
                        final filteredSliders = sliders.where((slider) {
                          return int.tryParse(slider.storeId ?? '') == storeId;
                        }).toList();
                        if (filteredSliders.isNotEmpty) {
                          sectionWidgets.add(Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              child: RepaintBoundary(
                                child: ChangeNotifierProvider<
                                    SliderImagesProvider>(
                                  create: (_) => SliderImagesProvider(),
                                  child: SliderImageWidget(
                                      sliders: filteredSliders),
                                ),
                              )));
                        }
                        shownStoreSliders.add(storeId);
                      }
                    }
                  } else {
                    for (int i = 0; i < groups.length; i++) {
                      final currentStoreId = groups[i].storeId;
                      // Skip groups that carry no sub-category tiles. The grid
                      // would otherwise fall back to rendering the group itself
                      // as a lone tile, repeating the heading right below it.
                      if (groups[i].subCategoryGroups.isNotEmpty) {
                        sectionWidgets
                            .add(CategoryGroupsList(
                                groups: [groups[i]], homeLimit: true));
                        hasCategoryGrid = true;
                      }

                      final isLastGroupOfStore = i == groups.length - 1 ||
                          groups[i + 1].storeId != currentStoreId;

                      if (isLastGroupOfStore &&
                          currentStoreId != null &&
                          !shownStoreSliders.contains(currentStoreId)) {
                        final filteredSliders = sliders.where((slider) {
                          final sliderStoreId =
                              int.tryParse(slider.storeId ?? '');
                          return sliderStoreId == currentStoreId;
                        }).toList();

                        if (filteredSliders.isNotEmpty) {
                          sectionWidgets.add(Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              child: RepaintBoundary(
                                child: ChangeNotifierProvider<
                                    SliderImagesProvider>(
                                  create: (_) => SliderImagesProvider(),
                                  child: SliderImageWidget(
                                      sliders: filteredSliders),
                                ),
                              )));
                        }
                        shownStoreSliders.add(currentStoreId);
                      }
                    }
                  }
                  // If any sliders left, append to end
                  // while (sliderIdx < sliders.length) {
                  //   sectionWidgets.add(
                  //     Padding(
                  //       padding: const EdgeInsets.symmetric(vertical: 12),
                  //       child: RepaintBoundary(
                  //         child: ChangeNotifierProvider<SliderImagesProvider>(
                  //           create: (_) => SliderImagesProvider(),
                  //           child: SliderImageWidget(
                  //               sliders: [sliders[sliderIdx]]),
                  //         ),
                  //       ),
                  //     ),
                  //   );
                  //   sliderIdx++;
                  // }

                  return SmartRefresher(
                    controller: _refreshController,
                    onRefresh: refreshList,
                    enablePullDown: true,
                    enablePullUp: false,
                    child: CustomScrollView(
                      controller: widget.scrollController,
                      slivers: [
                        // Scrollable header section (brand + delivery info)
                        SliverToBoxAdapter(
                          child: Container(
                            key: _headerKey,
                            child: DeliveryAddressHeaderWidget(
                              onAddressChanged: refreshList,
                              onAddressSelected: onAddressSelected,
                            ),
                          ),
                        ),

                        // Sticky search and category tabs
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: StickySearchDelegate(
                            // Pinned, the header also carries the delivery
                            // strip, so it is that much taller.
                            minHeight: _stickyHeaderHeight(context),
                            maxHeight: _stickyHeaderHeight(context),
                            topPadding: MediaQuery.of(context).padding.top,
                            selectedIdx: provider.selectedStoreIdx,
                            isSticked: _isSticked,
                            scrollController: widget.scrollController,
                            onAddressSelected: onAddressSelected,
                            onTabSelected: () {
                              if (mounted && _isSticked) {
                                setState(() => _isSticked = false);
                              }
                            },
                          ),
                        ),
                        // SliverToBoxAdapter(
                        //   child: SizedBox(
                        //     height: 16,
                        //   ),
                        // ),

                        // App Launch Banner (only shown for "All" store)
                        Consumer<AppLaunchBannerProvider>(
                          builder: (context, bannerProvider, _) {
                            final selectedIdx = provider.selectedStoreIdx;
                            final showBanner =
                                selectedIdx == 0 && bannerProvider.hasBanner;

                            if (!showBanner)
                              return const SliverToBoxAdapter(
                                  child: SizedBox.shrink());

                            return SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  // Banner image with aspect ratio
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: bannerProvider.bannerColor,
                                    ),
                                    child: AspectRatio(
                                      aspectRatio:
                                          bannerProvider.bannerAspectRatio,
                                      child: BannerMediaWidget(
                                        url: bannerProvider.bannerUrl,
                                        mediaType:
                                            bannerProvider.bannerMediaType,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  // Special items grid
                                  if (bannerProvider
                                      .specialItems.isNotEmpty) ...[
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: bannerProvider.bannerColor,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Full width so the heading sits left
                                          // like every other section heading,
                                          // instead of centring itself in the
                                          // column.
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              _headingTopGap,
                                              16,
                                              _headingBottomGap,
                                            ),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: Text(
                                                'Special Items',
                                                // Sits directly on the banner
                                                // color, same as the header
                                                // above it.
                                                style: _sectionHeadingStyle(
                                                  _readableOn(bannerProvider
                                                      .bannerColor),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Items Grid
                                          GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              0,
                                              16,
                                              16,
                                            ),
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3,
                                              mainAxisSpacing: 16,
                                              crossAxisSpacing: 12,
                                              // Fixed row height: the card is a
                                              // fixed stack, so tying it to
                                              // width left ~30dp of dead space
                                              // under every row.
                                              mainAxisExtent:
                                                  _specialItemExtent,
                                            ),
                                            itemCount: bannerProvider
                                                .specialItems.length,
                                            itemBuilder: (context, index) {
                                              final item = bannerProvider
                                                  .specialItems[index];
                                              return _buildSpecialItemCard(
                                                context,
                                                item,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),

                        const SliverToBoxAdapter(
                          child: SizedBox(height: _sectionGap),
                        ),

                        // Rewards progress — small, so it sits above the
                        // heavier rails rather than interrupting them.
                        const SliverToBoxAdapter(
                          child: RewardsProgressStrip(),
                        ),

                        // Buy it again — repeat purchase is most of a grocery
                        // order, so previously bought items come before the
                        // browse-oriented sections below.
                        //
                        // "All" only (idx 0): past orders span every store, so
                        // inside a single store tab the rail would show items
                        // that tab does not sell.
                        if (provider.selectedStoreIdx == 0)
                          SliverToBoxAdapter(
                            child: BuyItAgainRail(
                              onOpenReorder: () {
                                context
                                    .read<HomeMainScreenProvider>()
                                    .selectBottomMenu(_reorderTabIndex);
                              },
                            ),
                          ),

                        if (provider.homeCombos.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: HorizontalComboSection(
                              title: getTranslatedValue(context, 'combos'),
                              combos: provider.homeCombos,
                              onViewAll: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CombosScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: _sectionGap),
                          ),
                        ],
                        // Sweet House Sliders (Above Top Rated Restaurants)
                        if (provider.sweetHouseSliders.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: BannerCarousel(
                              mediaUrls: provider.sweetHouseSliders
                                  .map((slider) => slider.imageUrl ?? '')
                                  .where((url) => url.isNotEmpty)
                                  .toList(),
                              interval: const Duration(seconds: 5),
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: _sectionGap),
                          ),
                        ],

                        // Loading indicator for store content when switching tabs

                        if (provider.storeDataState == HomeScreenState.loading)
                          // A skeleton in the shape of the grid that is coming,
                          // rather than a spinner over 120dp of blank page —
                          // the layout stays still when the data lands.
                          SliverToBoxAdapter(
                            child: getCategoriesShimmer(colorScheme),
                          )
                        else ...[
                          // Thinking Items Horizontal — only for food/sweet house context
                          if (provider.topRatedSweetHouses.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Consumer<ThinkingItemsProvider>(
                                builder: (context, thinkingProvider, _) {
                                  if (!thinkingProvider.hasItems) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: ThinkingItemsHorizontal(
                                      items: thinkingProvider.items,
                                      sectionTitle: thinkingProvider.sectionTitle,
                                    ),
                                  );
                                },
                              ),
                            ),

                          // Top Rated Sweet Houses Section
                          if (provider.topRatedSweetHouses.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: TopRatedSweetHousesSection(
                                sweetHouses: provider.topRatedSweetHouses,
                                title: 'Top Rated Restaurants',
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: _sectionGap),
                            ),
                          ],

                          // Store Sellers List
                          if (provider.storeSellers.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: StoreSellersListWidget(
                                sellers: provider.storeSellers,
                                hasMore: provider.hasMoreSellers,
                                isLoadingMore: provider.isLoadingMoreSellers,
                                scrollController: widget.scrollController,
                                onLoadMore: () {
                                  provider.loadMoreSellers(context);
                                },
                                onSellerTap: (seller) {
                                  // Check if seller is a sweet house
                                  if (seller.storeDetails?.isSweetHouse == 1 ||
                                      seller.storeDetails?.isSweetHouse ==
                                          true) {
                                    final foodType = context.read<HomeScreenProvider>().selectedFoodType;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SweetHouseDetailScreen(
                                          sellerId: seller.id.toString(),
                                          foodType: foodType,
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SupermartDetailScreen(
                                          sellerId: seller.id,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: _sectionGap),
                            ),
                          ],
                        ],

                        // Content sections
                        if (provider.groupState == HomeScreenState.loading)
                          SliverToBoxAdapter(
                              child: getCategoriesShimmer(colorScheme)),
                        if (provider.groupState == HomeScreenState.error)
                          SliverToBoxAdapter(
                            child: _sectionErrorState(
                              colorScheme,
                              getTranslatedValue(
                                context,
                                'failed_to_load_category_grid',
                              ),
                              'Check your connection and try again',
                              onRetry: refreshList,
                            ),
                          ),
                        if (hasCategoryGrid)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                _headingTopGap,
                                16,
                                _headingBottomGap,
                              ),
                              child: Text(
                                'Shop by Category',
                                style: _sectionHeadingStyle(
                                    colorScheme.textPrimary),
                              ),
                            ),
                          ),
                        ...sectionWidgets
                            .map((w) => SliverToBoxAdapter(child: w)),

                        // Home Sections (paginated)
                        // Only shown on the "all stores" tab — i.e. when
                        // cat_store is called without /id. When a specific
                        // store tab is selected, home sections are hidden.
                        SliverToBoxAdapter(
                          child: Consumer2<HomeScreenProvider,
                              HomeSectionsProvider>(
                            builder: (context, homeScreenProvider,
                                homeSectionsProvider, _) {
                              if (homeScreenProvider.selectedStoreIdx != 0) {
                                return const SizedBox.shrink();
                              }
                              if (!homeSectionsProvider.hasSections &&
                                  !homeSectionsProvider.isLoading) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                children: [
                                  HomeSectionsWidget(
                                    sections: homeSectionsProvider.sections,
                                  ),
                                  if (homeSectionsProvider.isLoadingMore)
                                    const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),

                        // Bottom padding for cart overlay
                        SliverToBoxAdapter(
                          child: SizedBox(height: 100),
                        ),
                      ],
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

  /// A section that failed to load. Reads as a deliberate state — icon,
  /// headline, and what to do about it — rather than a stray line of grey text
  /// floating in the feed. Recovery is the page's existing pull-to-refresh, so
  /// this stays presentational.
  Widget _sectionErrorState(
    dynamic colorScheme,
    String title,
    String hint, {
    VoidCallback? onRetry,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 28,
            color: colorScheme.iconSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
              height: 1.3,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            // Recovery in reach, rather than relying on the customer knowing
            // the page can be pulled down.
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onRetry();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Try again',
                    style: GoogleFonts.inter(
                      color: colorScheme.buttonPrimaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget getEtaShimmer(dynamic colorScheme) {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: colorScheme.shimmerBase,
        highlightColor: colorScheme.shimmerHighlight,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 16, color: colorScheme.surface),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: double.infinity,
                      color: colorScheme.surface,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getCategoriesShimmer(dynamic colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Shimmer.fromColors(
        baseColor: colorScheme.shimmerBase,
        highlightColor: colorScheme.shimmerHighlight,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 8,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: .55,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            return Column(
              children: [
                Container(
                  width: 70,
                  height: 90,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.border,
                      width: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget getSliderShimmer(dynamic colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Shimmer.fromColors(
        baseColor: colorScheme.shimmerBase,
        highlightColor: colorScheme.shimmerHighlight,
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.border,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialItemCard(BuildContext context, dynamic item) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return CategoryProductScreen(
                subCategoryGroupId: item.id,
                title: item.name,
                supermart: null,
              );
            },
          ),
        );
      },
      child: Container(
        height: _specialItemCard,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // `contain` with the blurred fill, not `cover`: these are packshots
            // and cropping a whole chicken to fill a tile looks like a mistake.
            CatalogueImage(
              url: item.imageUrl,
              borderRadius: 0,
              fit: BoxFit.contain,
              fillBackdrop: true,
            ),
            // The scrim is what makes the label readable over any photo —
            // pale packshot or dark food shot alike.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _specialItemScrim,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.72),
                      Colors.black.withValues(alpha: 0.34),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              start: 8,
              end: 8,
              bottom: 8,
              child: Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  letterSpacing: -0.2,
                  shadows: const [
                    Shadow(color: Colors.black45, blurRadius: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiagonalLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  DiagonalLinePainter({required this.color, this.strokeWidth = 2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw diagonal line from bottom-left to top-right
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, 0),
      paint,
    );
  }

  @override
  bool shouldRepaint(DiagonalLinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

class HomeLoadingScreen extends StatelessWidget {
  const HomeLoadingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      color: colorScheme.background,
      alignment: Alignment.center,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation/GIF
          SizedBox(
            width: 184,
            height: 184,
            child: Image.asset(
              "assets/animations/home.gif",
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              getTranslatedValue(context, 'bringing_daily_essentials'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Black or white, whichever stays readable on [background].
///
/// The home header is painted with the App Launch Banner color, which is set
/// in the admin panel and can be anything — a near-black banner needs white
/// text, a pale one needs black. Luminance decides it rather than the app's
/// light/dark theme, because the banner does not follow the theme.
Color _readableOn(Color background) =>
    background.computeLuminance() < 0.5 ? Colors.white : Colors.black;

// Scrollable header section (brand + delivery info + cart/profile)
class DeliveryAddressHeaderWidget extends StatefulWidget {
  final VoidCallback? onAddressChanged;
  final Function(UserAddressData)? onAddressSelected;

  const DeliveryAddressHeaderWidget({
    super.key,
    this.onAddressChanged,
    this.onAddressSelected,
  });

  @override
  State<DeliveryAddressHeaderWidget> createState() =>
      _DeliveryAddressHeaderWidgetState();
}

class _DeliveryAddressHeaderWidgetState
    extends State<DeliveryAddressHeaderWidget> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeScreenProvider>();
    final bannerProvider = context.watch<AppLaunchBannerProvider>();
    final brandTitle = getTranslatedValue(context, 'app_brand_name');
    final price = getTranslatedValue(context, 'price_zero');

    final addressLine = Constant.session.getData(SessionManager.keyAddress);

    final selectedIdx = provider.selectedStoreIdx;

    CategoryGroup? group;
    if (selectedIdx > 0 &&
        provider.storeGroups.isNotEmpty &&
        selectedIdx < provider.storeGroups.length) {
      group = provider.storeGroups[selectedIdx];
    }

    // Check if we should show banner (only for "All" store)
    final showBanner = selectedIdx == 0 && bannerProvider.hasBanner;

    late final Color mainColor;
    if (selectedIdx == 0) {
      // Use banner color if available, otherwise default color
      mainColor =
          showBanner ? bannerProvider.bannerColor : const Color(0xFF9AC444);
    } else {
      mainColor = group != null
          ? Constant.colorFromHex(group.color ?? "#FFA13B")
          : const Color(0xFFFFA13B);
    }

    final bgDecoration = BoxDecoration(
      // Use solid color when banner is present, gradient otherwise
      color: showBanner ? mainColor : null,
      gradient: showBanner
          ? null
          : LinearGradient(
              colors: [mainColor, mainColor.withValues(alpha: 0.2)],
              stops: const [0, 1],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
    );

    // The whole header block — brand title, delivery line, address — contrasts
    // against whatever the banner is painting behind it: white on a dark
    // banner, black on a light one. The banner color is admin-set, so a fixed
    // color would be unreadable half the time. Every store tab, Grocery &
    // Kitchen and the rest, keeps the original white-on-color treatment.
    final infoColor = selectedIdx == 0
        ? _readableOn(mainColor)
        : Colors.white;

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        decoration: bgDecoration,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          left: 16,
          right: 16,
          // bottom: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand Title
            Text(
              brandTitle,
              style: GoogleFonts.inter(
                color: infoColor,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                height: 1.02,
              ),
            ),
            // const SizedBox(height: 16),

            // Dynamic: show shimmer, error, or actual content
            Builder(
              builder: (context) {
                final colorScheme =
                    context.watch<app_theme.ThemeProvider>().colorScheme;
                if (provider.etaState == HomeScreenState.loading)
                  return getEtaShimmer(colorScheme);
                // if (provider.etaState == HomeScreenState.error)
                //   return Text(
                //     "Failed to load ETA",
                //     style: GoogleFonts.inter(
                //       color: Colors.white,
                //       fontSize: 13,
                //       fontWeight: FontWeight.w500,
                //       letterSpacing: -0.2,
                //       height: 1.15,
                //     ),
                //   );
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Delivery info
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final result = await showAddressesBottomSheet(
                            context,
                            onAddressSelected: widget.onAddressSelected,
                          );

                          // If an address was selected, fetch estimated time without waiting
                          if (result != null && mounted) {
                            final homeProvider =
                                context.read<HomeScreenProvider>();
                            // Don't await - load in background for smooth UI
                            homeProvider.loadEta(context);
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListenableBuilder(
                              listenable: StoreHoursService(),
                              builder: (context, _) {
                                final storeHours = StoreHoursService();
                                final isClosed = storeHours.isLoaded &&
                                    !storeHours.isStoreOpen;
                                final isClosingSoon = storeHours.isClosingSoon;

                                // Start countdown timer when closing soon
                                if (isClosingSoon) {
                                  storeHours.startCountdownTimer();
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isClosed)
                                      Text(
                                        getTranslatedValue(
                                            context, 'store_closed'),
                                        style: GoogleFonts.inter(
                                          color: Colors.red,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.6,
                                          height: 1.02,
                                        ),
                                      )
                                    else if (isClosingSoon)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 6),
                                        child: Text(
                                          "Closes in ${storeHours.closingCountdown}",
                                          style: GoogleFonts.inter(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.1,
                                            height: 1.1,
                                          ),
                                        ),
                                      )
                                    else
                                      SizedBox(height: 8),
                                    if (isClosed)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          "${getTranslatedValue(context, 'will_open_at')} ${storeHours.formattedOpeningTime}",
                                          style: GoogleFonts.inter(
                                            // Same banner-aware color as the
                                            // delivery line it replaces.
                                            color: infoColor
                                                .withValues(alpha: 0.9),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            height: 1.2,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            // Zepto-style ETA / serviceability row
                            if (provider.etaState == HomeScreenState.loaded)
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 6, bottom: 4),
                                child: provider.isServiceable
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Delivery in ${provider.travelTimeMinutes ?? 0} mins",
                                            style: GoogleFonts.inter(
                                              color: infoColor,
                                              fontSize: 19,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.5,
                                              height: 1.05,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        provider.nearestStoreMessage ??
                                            "Sorry, we are not available in your area.",
                                        style: GoogleFonts.inter(
                                          color: Colors.red,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                          height: 1.1,
                                        ),
                                      ),
                              ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    addressLine.isNotEmpty
                                        ? addressLine
                                        : "Tap to add your address",
                                    style: GoogleFonts.inter(
                                      color: infoColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.35,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  // Sits inline with the address, so it takes
                                  // the same color rather than staying white
                                  // beside black text.
                                  color: infoColor,
                                  size: 24,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    RepaintBoundary(
                      child: CartProfileWidget(
                          price: price, iconColor: Colors.black),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget getEtaShimmer(dynamic colorScheme) {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.white.withValues(alpha: 0.3),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Row(
          children: [
            Container(
                width: 50,
                height: 50,
                color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            Expanded(
                child: Container(
                    height: 16, color: Colors.white.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }
}

// Sticky search bar and category tabs delegate
class StickySearchDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final double topPadding;
  final int selectedIdx;
  final bool isSticked;
  final ScrollController scrollController;
  // Called when a tab is tapped, so the parent can clear the stale "sticked"
  // state before scrolling back to the top (otherwise the pinned-style deep
  // background can flash as a band below the delivery header).
  final VoidCallback? onTabSelected;

  /// Forwarded to the address sheet opened from the pinned delivery strip, so
  /// changing the address there behaves exactly as it does in the tall header.
  final Function(UserAddressData)? onAddressSelected;

  StickySearchDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.topPadding,
    required this.selectedIdx,
    required this.isSticked,
    required this.scrollController,
    this.onTabSelected,
    this.onAddressSelected,
  });

  /// Compact "12 min · Kondapur" line shown only while the header is pinned.
  /// It restates what the tall delivery header says at the top of the page —
  /// the two are never on screen together.
  Widget _deliveryStrip(
    BuildContext context,
    HomeScreenProvider provider,
    Color headerColor,
  ) {
    final address = Constant.session.getData(SessionManager.keyAddress);
    final eta = provider.estimatedTime;

    // Matches the tall header this strip replaces on scroll: contrast against
    // the banner behind it on the home tab, white on every store tab.
    final infoColor =
        selectedIdx == 0 ? _readableOn(headerColor) : Colors.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        HapticFeedback.lightImpact();
        final result = await showAddressesBottomSheet(
          context,
          onAddressSelected: onAddressSelected,
        );
        if (result != null && context.mounted) {
          context.read<HomeScreenProvider>().loadEta(context);
        }
      },
      child: SizedBox(
        height: _pinnedDeliveryStripHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (eta != null && eta.isNotEmpty) ...[
                Icon(
                  Icons.bolt_rounded,
                  size: 16,
                  color: infoColor,
                ),
                const SizedBox(width: 2),
                Text(
                  eta,
                  style: GoogleFonts.inter(
                    color: infoColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                ),
                Container(
                  width: 3,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: infoColor.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              Expanded(
                child: Text(
                  address.isNotEmpty
                      ? address
                      : getTranslatedValue(context, tapAddAddressLabel),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: infoColor.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: infoColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final provider = context.watch<HomeScreenProvider>();
    final bannerProvider = context.watch<AppLaunchBannerProvider>();
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final selectedIdx = provider.selectedStoreIdx;

    CategoryGroup? group;
    if (selectedIdx > 0 &&
        provider.storeGroups.isNotEmpty &&
        selectedIdx < provider.storeGroups.length) {
      group = provider.storeGroups[selectedIdx];
    }

    // Check if we should use banner color
    final showBanner = selectedIdx == 0 && bannerProvider.hasBanner;

    late final Color mainColor;
    if (selectedIdx == 0) {
      // Use banner color if available, otherwise use theme primary
      mainColor = showBanner ? bannerProvider.bannerColor : colorScheme.primary;
    } else {
      mainColor = group != null
          ? Constant.colorFromHex(group.color ?? "#FFA13B")
          : const Color(0xFFFFA13B);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      // Keep the same background whether the header is pinned or not, so the
      // app-bar color/gradient stays visible while scrolling. The gradient
      // stops are fully opaque (tint -> surface) instead of fading to
      // transparent, so that once the header is pinned the content scrolling
      // underneath it does not bleed through.
      decoration: BoxDecoration(
        color: showBanner ? mainColor : null,
        // Store tabs: when pinned, show the SAME strong top-to-light gradient
        // the delivery header shows at the top of the page, so the app bar
        // looks the same before and after scrolling. When not pinned, use the
        // lighter tail of that fade so the search/tabs sitting just below the
        // delivery header read as one continuous gradient. Both stops are
        // opaque so pinned content does not bleed through.
        // (Banner / "All" tab keeps its solid color in both states.)
        gradient: showBanner
            ? null
            : LinearGradient(
                colors: isSticked
                    ? [
                        mainColor,
                        Color.lerp(colorScheme.surface, mainColor, 0.2) ??
                            mainColor,
                      ]
                    : [
                        Color.lerp(colorScheme.surface, mainColor, 0.2) ??
                            mainColor,
                        colorScheme.surface,
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        // Only the shadow differs between states: fade it in (alpha 0 -> 0.05)
        // when the header pins, to separate it from the scrolling content.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isSticked ? 0.05 : 0.0),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(top: isSticked ? topPadding : 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Delivery ETA + address — only while pinned, since the tall header
          // above owns this information when the page is scrolled to the top.
          if (isSticked) _deliveryStrip(context, provider, mainColor),
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, productSearchScreen);
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            getTranslatedValue(context, 'search_for'),
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
                                  getTranslatedValue(
                                      context, productsSearchLabel),
                                  textStyle: GoogleFonts.inter(
                                    color: colorScheme.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.2,
                                    height: 1.3,
                                  ),
                                  speed: const Duration(milliseconds: 100),
                                  // Default cursor is '_', which reads as a
                                  // stray character in a placeholder.
                                  cursor: '',
                                ),
                                TypewriterAnimatedText(
                                  getTranslatedValue(
                                      context, groceriesSearchLabel),
                                  textStyle: GoogleFonts.inter(
                                    color: colorScheme.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.2,
                                    height: 1.3,
                                  ),
                                  speed: const Duration(milliseconds: 100),
                                  // Default cursor is '_', which reads as a
                                  // stray character in a placeholder.
                                  cursor: '',
                                ),
                                TypewriterAnimatedText(
                                  getTranslatedValue(
                                      context, snacksSearchLabel),
                                  textStyle: GoogleFonts.inter(
                                    color: colorScheme.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.2,
                                    height: 1.3,
                                  ),
                                  speed: const Duration(milliseconds: 100),
                                  // Default cursor is '_', which reads as a
                                  // stray character in a placeholder.
                                  cursor: '',
                                ),
                                TypewriterAnimatedText(
                                  getTranslatedValue(
                                      context, vegetablesSearchLabel),
                                  textStyle: GoogleFonts.inter(
                                    color: colorScheme.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.2,
                                    height: 1.3,
                                  ),
                                  speed: const Duration(milliseconds: 100),
                                  // Default cursor is '_', which reads as a
                                  // stray character in a placeholder.
                                  cursor: '',
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
                    const SizedBox(width: 12),
                    Image.asset(
                      "assets/icons/mic.png",
                      width: 22,
                      height: 22,
                      color: colorScheme.iconPrimary,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 20,
                      color: colorScheme.iconPrimary,
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MultiProvider(providers: [
                              ChangeNotifierProvider(
                                  create: (context) => NotesProvider()),
                            ], child: NotesListScreen()),
                          ),
                        );
                      },
                      child: Image.asset(
                        "assets/icons/note.png",
                        width: 22,
                        height: 22,
                        color: colorScheme.iconPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Category tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: CategoryHeaderTabBar(
              categories: provider.storeGroups,
              selectedIndex: provider.selectedStoreIdx,
              onTap: (i) {
                // Clear the sticked state first so the header repaints in its
                // unpinned (light) style, then scroll to the top. Without this,
                // if the new tab's content is short the scroll position snaps
                // to 0 without firing the scroll listener and `_isSticked`
                // stays true, leaving a deep band below the delivery header.
                onTabSelected?.call();
                provider.setSelectedStoreTab(context, i);
                // Scroll to top when tab is tapped
                scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
            ).h(80),
          ),
          // const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(StickySearchDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        selectedIdx != oldDelegate.selectedIdx ||
        topPadding != oldDelegate.topPadding ||
        isSticked != oldDelegate.isSticked ||
        scrollController != oldDelegate.scrollController;
  }
}

class HorizontalComboSection extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  final List<Combo> combos;
  final Future<void> Function(Combo combo)? onBookmark;

  const HorizontalComboSection({
    super.key,
    required this.title,
    this.onViewAll,
    required this.combos,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: _sectionHeadingStyle(colorScheme.textPrimary),
              ),
              if (onViewAll != null)
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onViewAll?.call();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            getTranslatedValue(context, 'view_all'),
                            style: GoogleFonts.inter(
                              color: colorScheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.15,
                              letterSpacing: -0.2,
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
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Horizontal list
        SizedBox(
          height: 290,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            physics: const ClampingScrollPhysics(),
            itemCount: combos.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final combo = combos[index];
              return ComboProductCard(
                combo: combo,
                onView: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MultiProvider(
                        providers: [
                          ChangeNotifierProvider<ComboDetailProvider>(
                            create: (_) => ComboDetailProvider(),
                          ),
                        ],
                        child: ComboDetailScreen(
                          comboId: combo.id!,
                        ),
                      ),
                    ),
                  );
                },
                onBookmark: onBookmark != null
                    ? () async {
                        await onBookmark!(combo);
                      }
                    : () async {
                        // Default behavior for home screen
                        // Toggle bookmark
                        combo.isBookmarked = !(combo.isBookmarked ?? false);

                        // Call API
                        final result = await toggleComboBookmarkApi(
                          context: context,
                          comboId: combo.id!,
                        );

                        if (result != null && result['status'] == 1) {
                          FocusScope.of(context).unfocus();
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                    result['message'] ?? 'Bookmark updated'),
                                backgroundColor: ColorsRes.appColorGreen,
                              ),
                            );
                          // Refresh the combos list to update all cards
                          context
                              .read<HomeScreenProvider>()
                              .fetchHomeCombos(context);
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
              );
            },
          ),
        ),
      ],
    );
  }
}

// Top Rated Sweet Houses Section
class TopRatedSweetHousesSection extends StatelessWidget {
  final List<StoreSeller> sweetHouses;
  final String? title;

  const TopRatedSweetHousesSection({
    super.key,
    required this.sweetHouses,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    if (sweetHouses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left-aligned Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title ?? getTranslatedValue(context, 'top_rated_sweet_houses'),
            style: _sectionHeadingStyle(colorScheme.textPrimary),
          ),
        ),

        const SizedBox(height: 12),

        // Horizontal list of sweet houses
        SizedBox(
          height: 180,
          child: _HorizontalSweetHousesList(
            sweetHouses: sweetHouses,
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }
}

// Horizontal Sweet Houses List Widget with Parallax
class _HorizontalSweetHousesList extends StatefulWidget {
  final List<StoreSeller> sweetHouses;
  final AppColorScheme colorScheme;

  const _HorizontalSweetHousesList({
    required this.sweetHouses,
    required this.colorScheme,
  });

  @override
  State<_HorizontalSweetHousesList> createState() =>
      _HorizontalSweetHousesListState();
}

class _HorizontalSweetHousesListState
    extends State<_HorizontalSweetHousesList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: widget.sweetHouses.length,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final seller = widget.sweetHouses[index];
        return SweetHouseCard(
          seller: seller,
          colorScheme: widget.colorScheme,
          scrollController: _scrollController,
          onTap: () {
            if (seller.isShopOpen == false) {
              showMessage(
                context,
                seller.shopStatusMessage ?? 'Shop is currently closed',
                MessageType.warning,
              );
              return;
            }
            HapticFeedback.lightImpact();
            final foodType = context.read<HomeScreenProvider>().selectedFoodType;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SweetHouseDetailScreen(
                  sellerId: seller.id.toString(),
                  foodType: foodType,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Sweet House Card Widget
class SweetHouseCard extends StatefulWidget {
  final StoreSeller seller;
  final AppColorScheme colorScheme;
  final VoidCallback? onTap;
  final ScrollController? scrollController;

  const SweetHouseCard({
    super.key,
    required this.seller,
    required this.colorScheme,
    this.onTap,
    this.scrollController,
  });

  @override
  State<SweetHouseCard> createState() => _SweetHouseCardState();
}

class _SweetHouseCardState extends State<SweetHouseCard> {
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = widget.scrollController?.offset ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final seller = widget.seller;
    final colorScheme = widget.colorScheme;
    final isShopClosed = seller.isShopOpen == false;
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 117,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section with Stack for overlays
            Container(
              width: 120,
              height: 120,
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadows: [
                  BoxShadow(
                    color: const Color(0x23000000),
                    blurRadius: 22,
                    offset: const Offset(0, 0),
                    spreadRadius: 0,
                  )
                ],
              ),
              child: Stack(
                children: [
                  // Image background with parallax effect
                  Positioned.fill(
                    child: isShopClosed
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Opacity(
                                opacity: 0.35,
                                child: CachedNetworkImage(
                                  imageUrl: (seller.storeImages?.isNotEmpty ??
                                          false)
                                      ? seller.storeImages!.first
                                      : 'https://via.placeholder.com/127x140?text=Sweet+House',
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey.shade200,
                                  ),
                                  errorWidget: (context, url, error) => imgErrorWidget(icon: Icons.storefront_rounded, iconSize: 32),
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.55),
                                ),
                              ),
                              Center(
                                child: Text(
                                  'Closed',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : CachedNetworkImage(
                            imageUrl: (seller.storeImages?.isNotEmpty ?? false)
                                ? seller.storeImages!.first
                                : 'https://via.placeholder.com/127x140?text=Sweet+House',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => imgErrorWidget(icon: Icons.storefront_rounded, iconSize: 32),
                          ),
                  ),
                  // Rating badge (bottom left)
                  if (!isShopClosed)
                    Positioned(
                      left: 7,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF28A745),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              seller.rating?.toStringAsFixed(1) ?? '0.0',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Bookmark button (top right)
                  if (!isShopClosed)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: GestureDetector(
                        onTap: () async {
                          // Toggle bookmark
                          seller.isBookmarked = !(seller.isBookmarked ?? false);

                          // Call API
                          final result = await toggleSellerBookmarkApi(
                            context: context,
                            sellerId: seller.id!,
                          );

                          if (result != null && result['status'] == 1) {
                            showMessage(
                              context,
                              result['message'] ?? 'Bookmark updated',
                              MessageType.success,
                            );
                          } else {
                            // Revert the toggle if API call failed
                            seller.isBookmarked =
                                !(seller.isBookmarked ?? false);
                            showMessage(
                              context,
                              result?['message'] ?? 'Failed to update bookmark',
                              MessageType.error,
                            );
                          }
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            shadows: [
                              BoxShadow(
                                color: const Color(0x23000000),
                                blurRadius: 8,
                                offset: const Offset(0, 1),
                              )
                            ],
                          ),
                          child: Icon(
                            seller.isBookmarked == true
                                ? Icons.bookmark
                                : Icons.bookmark_border_rounded,
                            size: 12,
                            color: seller.isBookmarked == true
                                ? const Color(0xFFE8B000)
                                : colorScheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  // Store name badge (top left)
                  // Positioned(
                  //   left: 7,
                  //   top: 8,
                  //   child: Container(
                  //     constraints: const BoxConstraints(maxWidth: 95),
                  //     padding: const EdgeInsets.symmetric(
                  //         horizontal: 6, vertical: 3),
                  //     decoration: ShapeDecoration(
                  //       color: Colors.black.withValues(alpha: 0.8),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(10),
                  //       ),
                  //     ),
                  //     child: Text(
                  //       seller.storeName ?? 'Sweet House',
                  //       maxLines: 1,
                  //       overflow: TextOverflow.ellipsis,
                  //       style: GoogleFonts.inter(
                  //         color: Colors.white,
                  //         fontSize: 9,
                  //         fontWeight: FontWeight.w600,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
            // Store info section
            const SizedBox(height: 8),
            Text(
              seller.storeName ?? 'Sweet House',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.02,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              // travel_time_min already carries its unit ("8 min") — don't
              // append another one.
              seller.travelTimeMin ?? '',
              style: GoogleFonts.inter(
                color: const Color(0xFFACA3A3),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SortingsSection extends StatefulWidget {
  const SortingsSection({super.key});

  @override
  State<SortingsSection> createState() => _SortingsSectionState();
}

class _SortingsSectionState extends State<SortingsSection> {
  // String? selectedSort; // Use provider's state instead
  // bool isVegSelected = false; // Sync with provider
  // bool isNonVegSelected = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              final homeProvider = context.watch<HomeScreenProvider>();
              bool isVegSelected = homeProvider.selectedFoodType == 'veg';

              // Veg toggle
              return _VegToggleChip(
                colorScheme: colorScheme,
                label: 'Veg',
                isSelected: isVegSelected,
                onTap: () {
                  final provider = context.read<HomeScreenProvider>();
                  final selectedId = provider.selectedStoreIdx == 0
                      ? null
                      : provider.storeGroups[provider.selectedStoreIdx].id;

                  provider.fetchProductsForStoreGroup(
                    context,
                    selectedId,
                    foodType: isVegSelected ? null : 'veg',
                  );
                },
              );
            } else if (index == 1) {
              final homeProvider = context.watch<HomeScreenProvider>();
              bool isNonVegSelected =
                  homeProvider.selectedFoodType == 'non_veg';

              // Non-Veg toggle
              return _VegToggleChip(
                colorScheme: colorScheme,
                label: 'Non-Veg',
                isSelected: isNonVegSelected,
                onTap: () {
                  final provider = context.read<HomeScreenProvider>();
                  final selectedId = provider.selectedStoreIdx == 0
                      ? null
                      : provider.storeGroups[provider.selectedStoreIdx].id;

                  provider.fetchProductsForStoreGroup(
                    context,
                    selectedId,
                    foodType: isNonVegSelected ? null : 'non_veg',
                  );
                },
              );
            } else if (index == 2) {
              final homeProvider = context.read<HomeScreenProvider>();
              String label = getTranslatedValue(context, 'sort_by');
              String? selectedValue = homeProvider.selectedSortBy;

              return _FilterChipButton(
                colorScheme: colorScheme,
                label: label,
                isSelected: selectedValue != null,
                onTap: () {
                  _showFilterSheet(
                    context: context,
                    colorScheme: colorScheme,
                    title: label,
                    options: sortByOptions,
                    filterIndex: 0,
                  );
                },
              );
            } else {
              final homeProvider = context.read<HomeScreenProvider>();
              String label = getTranslatedValue(context, 'category_label');
              String? selectedValue = homeProvider.selectedCategoryId;

              return _FilterChipButton(
                colorScheme: colorScheme,
                label: label,
                isSelected: selectedValue != null,
                onTap: () {
                  _showFilterSheet(
                    context: context,
                    colorScheme: colorScheme,
                    title: label,
                    options: homeProvider.storeCategories,
                    filterIndex: 1,
                  );
                },
              );
            }
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
                        String? optionImage;

                        if (option is SortByOption) {
                          optionValue = option.apiValue;
                          optionLabel = option.label;
                        } else if (option is StoreCategory) {
                          optionValue = option.id.toString();
                          optionLabel = option.name;
                          optionImage = option.imageUrl ?? option.image;
                        } else {
                          optionValue = option.toString();
                          optionLabel = option.toString();
                        }

                        final homeProvider =
                            context.watch<HomeScreenProvider>();
                        bool isSelected = false;
                        if (filterIndex == 0) {
                          isSelected =
                              homeProvider.selectedSortBy == optionValue;
                        } else {
                          // Category filtering on Home Screen uses id
                          if (option is StoreCategory) {
                            isSelected = homeProvider.selectedCategoryId ==
                                option.id.toString();
                          }
                        }

                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              final provider =
                                  context.read<HomeScreenProvider>();
                              if (filterIndex == 0) {
                                final selectedId = provider.selectedStoreIdx ==
                                        0
                                    ? null
                                    : provider
                                        .storeGroups[provider.selectedStoreIdx]
                                        .id;

                                provider.fetchProductsForStoreGroup(
                                  context,
                                  selectedId,
                                  sortBy: isSelected ? null : optionValue,
                                );
                              } else {
                                final selectedId = provider.selectedStoreIdx ==
                                        0
                                    ? null
                                    : provider
                                        .storeGroups[provider.selectedStoreIdx]
                                        .id;

                                String? catId;
                                if (option is StoreCategory) {
                                  catId = option.id.toString();
                                }

                                provider.fetchProductsForStoreGroup(
                                  context,
                                  selectedId,
                                  categoryId: isSelected ? null : catId,
                                );
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
                                if (filterIndex == 2 && option is StoreCategory)
                                  Container(
                                    width: 48,
                                    height: 48,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: colorScheme.surfaceVariant,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: setNetworkImg(
                                        image: optionImage ?? '',
                                        boxFit: BoxFit.cover,
                                        height: 48,
                                        width: 48,
                                      ),
                                    ),
                                  ),
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
                              final provider =
                                  context.read<HomeScreenProvider>();
                              provider.clearAllFilters(context);
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
                              'Clear Filter',
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
                              elevation: 0,
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
    final dotColor =
        isVeg ? const Color(0xFF4CAF50) : const Color(0xFFF44336);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? dotColor.withValues(alpha: 0.12) : colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? dotColor : colorScheme.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact veg/non-veg color dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
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
          ],
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final AppColorScheme colorScheme;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipButton({
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

class ComboBottomSheet extends StatefulWidget {
  final ProductListItem product;

  const ComboBottomSheet({super.key, required this.product});

  @override
  State<ComboBottomSheet> createState() => _ComboBottomSheetState();
}

class _ComboBottomSheetState extends State<ComboBottomSheet> {
  late List<Variants> variants;
  final Map<String, int> _qty = {};

  @override
  void initState() {
    super.initState();
    variants = widget.product.variants ?? [];
    for (final v in variants) {
      _qty[v.id!] = int.tryParse(v.cartCount ?? '0') ?? 0;
    }
  }

  void _increment(Variants v) {
    setState(() => _qty[v.id!] = (_qty[v.id!] ?? 0) + 1);
  }

  void _decrement(Variants v) {
    final current = _qty[v.id!] ?? 0;
    if (current > 0) {
      setState(() => _qty[v.id!] = current - 1);
    }
  }

  num get _comboTotal {
    num total = 0;
    for (final v in variants) {
      final q = _qty[v.id!] ?? 0;
      if (q == 0) continue;
      final priceStr = (v.discountedPrice != null &&
              v.discountedPrice!.isNotEmpty &&
              v.discountedPrice != '0')
          ? v.discountedPrice
          : v.price;
      final p = num.tryParse(priceStr ?? '0') ?? 0;
      total += p * q;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final media = MediaQuery.of(context);
    final rating = p.averageRatingNum ?? 0;
    final ratingCount = p.ratingCount ?? 0;

    // Initialize categories with translations
    final categories = [
      getTranslatedValue(context, 'grocery_essentials'),
      getTranslatedValue(context, 'vegetables_fruits_essentials'),
      getTranslatedValue(context, 'chicken_meat'),
      getTranslatedValue(context, 'beauty_personal_care')
    ];

    // Group variants by index for demo (2 items per category)
    final groupedVariants = <String, List<Variants>>{};
    for (int i = 0; i < variants.length; i++) {
      final categoryIndex = i ~/ 2; // 2 items per category
      final category = categories[categoryIndex % categories.length];
      groupedVariants.putIfAbsent(category, () => []).add(variants[i]);
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Close button
          Align(
            alignment: Alignment.topCenter,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  color: const Color(0xFF221F1F),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: media.size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top combo card
                        _buildHeaderCard(p, rating, ratingCount),
                        const SizedBox(height: 12),

                        // Offer banner
                        _buildOfferBanner(),
                        const SizedBox(height: 16),

                        // Combo essentials header
                        Row(
                          children: [
                            const Icon(Icons.spa_rounded,
                                size: 18, color: Color(0xFF9AC444)),
                            const SizedBox(width: 6),
                            Text(
                              getTranslatedValue(context, 'combo_essentials'),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF221F1F),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                minimumSize: const Size(0, 0),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                side: const BorderSide(
                                  color: Color(0xFF9AC444),
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                getTranslatedValue(context, 'edit_label'),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF9AC444),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Grouped variants
                        ...groupedVariants.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4A4A4A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...entry.value.map((v) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _buildVariantRow(v),
                                  )),
                              const SizedBox(height: 8),
                            ],
                          );
                        }),

                        // Note
                        Text(
                          getTranslatedValue(context, 'combo_customize_note'),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4F80FF),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Bottom buttons
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFEFEFEF), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF9AC444),
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          icon: const Icon(Icons.add_circle_outline,
                              size: 18, color: Color(0xFF9AC444)),
                          label: Text(
                            getTranslatedValue(context, 'add_extra_items'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF9AC444),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9AC444),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            getTranslatedValue(context, 'add_to_cart_button')
                                .replaceAll(
                                    '{total}', _comboTotal.toStringAsFixed(0)),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(ProductListItem p, num rating, int ratingCount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 110,
              height: 90,
              color: const Color(0xFFF2F2F2),
              child: (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: p.imageUrl!,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      ),
                      errorWidget: (context, url, error) => imgErrorWidget(icon: Icons.restaurant_menu_rounded, iconSize: 32),
                    )
                  : const Icon(Icons.fastfood_outlined,
                      size: 40, color: Color(0xFFD0D0D0)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF221F1F),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star_rounded,
                        size: 14, color: const Color(0xFFFFC107)),
                    const SizedBox(width: 2),
                    Text(
                      rating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF221F1F),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '• $ratingCount ratings',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8A8A8A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${variants.length} items',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '₹${(p.discountedPrice ?? p.price ?? 0)}',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF221F1F),
                      ),
                    ),
                    if (p.discountedPrice != null &&
                        p.discountedPrice != 0 &&
                        p.price != null &&
                        p.price != p.discountedPrice)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          '₹${p.price}',
                          style: GoogleFonts.instrumentSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF9D9898),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        color: const Color(0xFFEFF6E9),
        child: Stack(
          children: [
            Positioned.fill(
              child: const SizedBox.shrink(),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '20% OFF on your first grocery order!',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantRow(Variants v) {
    final qty = _qty[v.id!] ?? 0;
    final priceStr = (v.discountedPrice != null &&
            v.discountedPrice!.isNotEmpty &&
            v.discountedPrice != '0')
        ? v.discountedPrice
        : v.price;
    final originalPrice =
        (v.discountedPrice != null && v.discountedPrice != '0')
            ? v.price
            : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 52,
            height: 52,
            color: const Color(0xFFF4F4F4),
            child: (v.images != null && v.images!.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: v.images!.first,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                    ),
                    errorWidget: (context, url, error) => imgErrorWidget(iconSize: 20),
                  )
                : const Icon(Icons.shopping_bag_outlined,
                    size: 24, color: Color(0xFFD0D0D0)),
          ),
        ),
        const SizedBox(width: 10),

        // Name + variant info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF221F1F),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFD0D7FF),
                    width: 0.7,
                  ),
                ),
                child: Text(
                  getTranslatedValue(context, 'quantity_format')
                      .replaceAll('{measurement}', v.measurement ?? '')
                      .replaceAll('{unit}', v.stockUnitName ?? ''),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4B5A8A),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Price + qty stepper
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Text(
                  '₹$priceStr',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF221F1F),
                  ),
                ),
                if (originalPrice != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '₹$originalPrice',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9D9898),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FFEB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF9AC444),
                  width: 0.9,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 26, minHeight: 26),
                    iconSize: 16,
                    icon: const Icon(Icons.remove, color: Color(0xFF9AC444)),
                    onPressed: () => _decrement(v),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      qty.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF221F1F),
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 26, minHeight: 26),
                    iconSize: 16,
                    icon: const Icon(Icons.add, color: Color(0xFF9AC444)),
                    onPressed: () => _increment(v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ComboProductCard extends StatefulWidget {
  final Combo combo;
  final VoidCallback? onView;
  final VoidCallback? onBookmark;

  const ComboProductCard({
    super.key,
    required this.combo,
    this.onView,
    this.onBookmark,
  });

  @override
  State<ComboProductCard> createState() => _ComboProductCardState();
}

class _ComboProductCardState extends State<ComboProductCard> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final isInCart = widget.combo.isAlreadyAdded == 1;

    return GestureDetector(
      onTap: widget.onView,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.border,
            width: 1,
          ),
          boxShadow: colorScheme.cardShadow,
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with bookmark
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    color: const Color(0xFFF5F5F5),
                    child: CachedNetworkImage(
                      imageUrl: widget.combo.imageUrl ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      ),
                      errorWidget: (context, url, error) => imgErrorWidget(iconSize: 32),
                    ),
                  ),
                ),
                // Bookmark button
                Positioned(
                  right: 2,
                  top: 2,
                  child: GestureDetector(
                    onTap: widget.onBookmark,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x1A000000),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.combo.isBookmarked == true
                            ? Icons.bookmark
                            : Icons.bookmark_border_rounded,
                        size: 16,
                        color: widget.combo.isBookmarked == true
                            ? const Color(0xFFE8B000)
                            : const Color(0xFF221F1F),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.combo.name ?? '',
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    // Subtitle
                    Text(
                      widget.combo.type ?? '',
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.15,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Rating row
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(
                              index < (widget.combo.rating?.floor() ?? 0)
                                  ? Icons.star_rounded
                                  : (index < (widget.combo.rating ?? 0)
                                      ? Icons.star_half_rounded
                                      : Icons.star_outline_rounded),
                              size: 14,
                              color: const Color(0xFFFFC107),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          (widget.combo.ratingCount ?? 0).toString(),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF757575),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    // Item count
                    Text(
                      '${widget.combo.productCount ?? 0} items',
                      style: GoogleFonts.inter(
                        color: colorScheme.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                    ),

                    const Spacer(),

                    // Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${widget.combo.currency}${(widget.combo.totalProductsPrice ?? 0).toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if ((widget.combo.totalActualPrice ?? 0) >
                            (widget.combo.totalProductsPrice ?? 0)) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${widget.combo.currency}${(widget.combo.totalActualPrice ?? 0).toStringAsFixed(0)}',
                            style: GoogleFonts.instrumentSans(
                              color: const Color(0xFF9E9E9E),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              letterSpacing: -0.3,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: const Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (widget.combo.discountPercentage != null &&
                        widget.combo.discountPercentage! > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${widget.combo.discountPercentage!.toStringAsFixed(0)}% OFF',
                        style: GoogleFonts.instrumentSans(
                          color: const Color(0xFF1F5AF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),

                    // Action buttons (View & Add/Quantity)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // View button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onView?.call();
                          },
                          child: Text(
                            getTranslatedValue(context, 'view_label'),
                            style: GoogleFonts.inter(
                              color: colorScheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),

                        // Add button OR Quantity counter
                        if (!isInCart)
                          _buildAddButton(context)
                        else
                          _buildRemoveButton(
                            context,
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        final provider = context.read<ComboDetailProvider>();
        await context
            .read<ComboDetailProvider>()
            .fetchDetails(context, widget.combo.id!);
        await provider.addComboToCartWithComboId(context, widget.combo.id!);
        await context
            .read<CartListProvider>()
            .getAllCartItems(context: context);

        if (Constant.session.isUserLoggedIn()) {
          final comboProvider = context.read<CombosProvider>();
          comboProvider.fetchData(context);

          await context.read<CartProvider>().refreshCart(context: context);

          // Refresh home screen combos to update isAlreadyAdded status
          final homeScreenProvider = context.read<HomeScreenProvider>();
          await homeScreenProvider.fetchHomeCombos(context);

          final combos =
              context.read<CartProvider>().cartData?.data.customCombos ?? [];
          if (combos.isNotEmpty) {
            context.read<ComboDetailProvider>().initFromCartCombos(combos);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FFEB),
          border: Border.all(
            color: const Color(0xFF9AC444),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              getTranslatedValue(context, 'add_label'),
              style: GoogleFonts.inter(
                color: const Color(0xFF9AC444),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.55,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.add,
              size: 12,
              color: Color(0xFF9AC444),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoveButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        final provider = context.read<ComboDetailProvider>();
        await provider.deleteComboFromCartWithComboId(
            context, widget.combo.id!);

        if (Constant.session.isUserLoggedIn()) {
          final comboProvider = context.read<CombosProvider>();
          comboProvider.fetchData(context);

          // Refresh home screen combos to update isAlreadyAdded status
          final homeScreenProvider = context.read<HomeScreenProvider>();
          await homeScreenProvider.fetchHomeCombos(context);

          provider.refreshCartStatus(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          border: Border.all(
            color: const Color(0xFFFF4444),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              getTranslatedValue(context, 'remove_label'),
              style: GoogleFonts.inter(
                color: const Color(0xFFFF4444),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.55,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.remove_circle_outline,
              size: 12,
              color: Color(0xFFFF4444),
            ),
          ],
        ),
      ),
    );
  }
}
