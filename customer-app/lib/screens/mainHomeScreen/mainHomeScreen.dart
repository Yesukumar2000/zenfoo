import 'package:geolocator/geolocator.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/orderTrackingProvider.dart';
import 'package:project/provider/exploreLogoProvider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:video_player/video_player.dart';

class HomeMainScreen extends StatefulWidget {
  const HomeMainScreen({Key? key}) : super(key: key);

  @override
  State<HomeMainScreen> createState() => HomeMainScreenState();
}

class HomeMainScreenState extends State<HomeMainScreen> {
  NetworkStatus networkStatus = NetworkStatus.online;
  double _lastScrollOffset = 0;
  bool _showScrollToTop = false;
  bool _isNavBarVisible = true;

  void _handleScroll(ScrollController controller) {
    if (!controller.hasClients) return;
    // Ignore scroll events during pull-to-refresh
    if (controller.offset <= 0) {
      // Always show navbar when at top
      if (!_isNavBarVisible || _showScrollToTop) {
        setState(() {
          _isNavBarVisible = true;
          _showScrollToTop = false; // Hide scroll-to-top button at top
        });
      }
      return;
    }

    double scrollDelta = controller.offset - _lastScrollOffset;

    // Hide navbar when scrolling down, show when scrolling up
    bool shouldShowNavBar = scrollDelta < 0 || controller.offset <= 0;

    // Show "Back to top" button when scrolled down more than 300 pixels
    bool shouldShowScrollToTop = controller.offset > 300;

    if (shouldShowNavBar != _isNavBarVisible ||
        shouldShowScrollToTop != _showScrollToTop) {
      setState(() {
        _isNavBarVisible = shouldShowNavBar;
        _showScrollToTop = shouldShowScrollToTop;
        _lastScrollOffset = controller.offset;
      });
    } else {
      _lastScrollOffset = controller.offset;
    }
  }

  void _scrollToTop() {
    final homeMainScreenProvider = context.read<HomeMainScreenProvider>();
    final scrollController = homeMainScreenProvider
        .scrollController[homeMainScreenProvider.currentPage];
    scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    // ScrollControllers are disposed by the provider
    super.dispose();
  }

  @override
  void initState() {
    if (mounted) {
      context.read<HomeMainScreenProvider>().setPages();
    }
    Future.delayed(
      Duration.zero,
      () async {
        context.read<AppSettingsProvider>().getAppSettingsProvider(context);

        // Fetch explore logo for bottom nav
        context.read<ExploreLogoProvider>().fetchExploreLogo(context);

        // Fetch brand campaign
        await context.read<BrandCampaignProvider>().fetchCampaign(context);

        await LocalAwesomeNotification().init(context);

        if (Constant.session
            .getData(SessionManager.keyFCMToken)
            .trim()
            .isEmpty) {
          await FirebaseMessaging.instance.getToken().then((token) {
            Constant.session.setData(SessionManager.keyFCMToken, token!, false);

            Map<String, String> params = {
              ApiAndParams.fcmToken:
                  /* Constant.session.getData(SessionManager.keyFCMToken) */ token,
              ApiAndParams.platform: Platform.isAndroid ? "android" : "ios"
            };

            registerFcmKey(context: context, params: params);
          }).onError((e, _) {
            return;
          });
        }

        LocationPermission permission;
        permission = await Geolocator.checkPermission();

        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        } else if (permission == LocationPermission.deniedForever) {
          return Future.error('Location Not Available');
        }

        if ((Constant.session.getData(SessionManager.keyLatitude) == "" &&
                Constant.session.getData(SessionManager.keyLongitude) == "") ||
            (Constant.session.getData(SessionManager.keyLatitude) == "0" &&
                Constant.session.getData(SessionManager.keyLongitude) == "0")) {
          // Try to get current location and auto-select nearest city
          if (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse) {
            try {
              Position position = await Geolocator.getCurrentPosition(
                locationSettings: LocationSettings(
                  accuracy: LocationAccuracy.high,
                ),
              );

              // Call city API with current location
              Map<String, dynamic> cityParams = {
                ApiAndParams.latitude: position.latitude.toString(),
                ApiAndParams.longitude: position.longitude.toString(),
              };

              if (mounted) {
                await context
                    .read<CityByLatLongProvider>()
                    .getCityByLatLongApiProvider(
                      params: cityParams,
                      context: context,
                    );

                // Check if a valid city was found
                if (context.read<CityByLatLongProvider>().isDeliverable) {
                  // Location successfully set, don't navigate to confirmLocationScreen
                  debugPrint(
                      "Auto-selected nearest city based on user location");
                } else {
                  // City not found or not deliverable, show location selection screen
                  Navigator.pushNamed(context, confirmLocationScreen,
                      arguments: [null, "location"]);
                }
              }
            } catch (e) {
              debugPrint("Error getting current location: $e");
              // If auto-detection fails, navigate to location selection screen
              Navigator.pushNamed(context, confirmLocationScreen,
                  arguments: [null, "location"]);
            }
          } else {
            // Permission not granted, navigate to location selection screen
            Navigator.pushNamed(context, confirmLocationScreen,
                arguments: [null, "location"]);
          }
        } else {
          if (context.read<HomeMainScreenProvider>().getCurrentPage() == 0) {
            if (Constant.popupBannerEnabled) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return CustomDialog();
                },
              );
            }
          }

          if (Constant.session.isUserLoggedIn()) {
            await getAppNotificationSettingsRepository(
                    params: {}, context: context)
                .then(
              (value) async {
                if (value[ApiAndParams.status].toString() == "1") {
                  late AppNotificationSettings notificationSettings =
                      AppNotificationSettings.fromJson(value);
                  if (notificationSettings.data != null &&
                      ((notificationSettings.data?.length ?? 0) >= 1 &&
                          (notificationSettings.data?.length ?? 0) <= 11)) {
                    await updateAppNotificationSettingsRepository(params: {
                      ApiAndParams.statusIds: "1,2,3,4,5,6,7,8,9,10,11",
                      ApiAndParams.mobileStatuses: "0,1,1,1,1,1,1,1,1,1,1",
                      ApiAndParams.mailStatuses: "0,1,1,1,1,1,1,1,1,1,1"
                    }, context: context);
                  }
                }
              },
            );
          }
        }
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Consumer<HomeMainScreenProvider>(
      builder: (context, homeMainScreenProvider, child) {
        return Scaffold(
          extendBody: true,
          bottomNavigationBar: AnimatedSlide(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            offset: _isNavBarVisible ? Offset.zero : Offset(0, 1),
            child: Consumer<ExploreLogoProvider>(
                builder: (context, exploreLogo, child) => CustomBottomNavBar(
                      selectedIndex: homeMainScreenProvider.getCurrentPage(),
                      exploreMediaUrl: exploreLogo.mediaUrl,
                      exploreMediaType: exploreLogo.mediaType,
                      onTap: (idx) {
                        debugPrint("📱 Bottom nav tapped: $idx");
                        // If celebrations tab (index 4) is tapped, show campaign bottom sheet
                        if (idx == 4) {
                          debugPrint(
                              "🎭 Celebrations tab tapped - showing campaign bottom sheet");
                          BrandCampaignBottomSheet.show(context);
                          return;
                        }
                        setState(() {
                          homeMainScreenProvider.selectBottomMenu(idx);
                        });
                      },
                      staticIcons: [
                        'assets/icons/home.png',
                        'assets/icons/categories.png',
                        'assets/icons/supermart.png',
                        'assets/icons/reorder.png',
                        'assets/animations/celebrations.gif',
                      ],
                      animatedIcons: [
                        'assets/animations/home_selected.gif',
                        'assets/animations/categories_selected.gif',
                        'assets/animations/supermart_selected.gif',
                        'assets/animations/reorder_selected.gif',
                        'assets/animations/celebrations.gif', // last, with rotation
                      ],
                      labels: [
                        getTranslatedValue(context, 'home_bottom_nav_home'),
                        getTranslatedValue(
                            context, 'home_bottom_nav_categories'),
                        getTranslatedValue(
                            context, 'home_bottom_nav_super_mart'),
                        getTranslatedValue(context, 'home_bottom_nav_reorder'),
                        getTranslatedValue(context, 'explore_tab'),
                      ],
                      showScrollToTop: _showScrollToTop,
                      onScrollToTopTap: _scrollToTop,
                    )),
          ),
          body: networkStatus == NetworkStatus.online
              ? Stack(
                  children: [
                    PopScope(
                      canPop: false,
                      onPopInvokedWithResult: (didPop, _) {
                        if (didPop) {
                          return;
                        } else {
                          if (homeMainScreenProvider.currentPage == 0) {
                            if (Platform.isAndroid) {
                              SystemNavigator.pop();
                            } else if (Platform.isIOS) {
                              exit(0);
                            }
                          } else {
                            setState(() {});
                            homeMainScreenProvider.currentPage = 0;
                          }
                        }
                      },
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (scrollNotification) {
                          if (scrollNotification is ScrollUpdateNotification) {
                            final controller =
                                homeMainScreenProvider.scrollController[
                                    homeMainScreenProvider.currentPage];
                            _handleScroll(controller);
                          }
                          return false;
                        },
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: 250),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: Container(
                            key: ValueKey<int>(
                                homeMainScreenProvider.currentPage),
                            child: homeMainScreenProvider
                                .getPages()[homeMainScreenProvider.currentPage],
                          ),
                        ),
                      ),
                    ),
                    // Scroll to top button - floating above bottom nav with dynamic height
                    if (_showScrollToTop)
                      Consumer<CartProvider>(
                        builder: (context, cartProvider, child) {
                          final hasCart = cartProvider.totalItemsCount > 0;
                          final bottomOffset =
                              _isNavBarVisible ? (hasCart ? 200 : 100) : 20;

                          return AnimatedPositionedDirectional(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            bottom: bottomOffset.toDouble(),
                            end: 16,
                            child: GestureDetector(
                              onTap: _scrollToTop,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: context
                                          .watch<app_theme.ThemeProvider>()
                                          .colorScheme
                                          .primary,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.15),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 20,
                                      color: context
                                          .watch<app_theme.ThemeProvider>()
                                          .colorScheme
                                          .buttonPrimaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // The label floats over scrolling content,
                                  // so it carries its own surface instead of
                                  // printing bare colour onto whatever card
                                  // happens to be underneath it.
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context
                                          .watch<app_theme.ThemeProvider>()
                                          .colorScheme
                                          .surface,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.12),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'Back to top',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        color: context
                                            .watch<app_theme.ThemeProvider>()
                                            .colorScheme
                                            .primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                )
              : Center(
                  child: CustomTextLabel(
                    jsonKey: checkInternetLabel,
                  ),
                ),
        );
      },
    ),
    );
  }

  Widget customHomeBottomNavigation({
    required int selectedIndex,
    required Function(int) onTap,
    required List<Widget>
        icons, // Pass vector/svg/png Widgets here, matching the icon style
    required List<String> labels,
  }) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      width: double.infinity,
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(labels.length, (index) {
          return GestureDetector(
            onTap: () => onTap(index),
            child: Container(
              // Each item width can be fixed, or make responsive. Example: width: 68,
              width: index == 0 ? 46 : (index == 3 ? 57 : 68),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    child: icons[index],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: index == 0 ? 46 : (index == 3 ? 55 : 76),
                    height: 22,
                    child: Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: selectedIndex == index
                            ? colorScheme.textPrimary
                            : colorScheme.textSecondary,
                        fontSize: 12,
                        fontWeight:
                            index == 0 ? FontWeight.w700 : FontWeight.w600,
                        height: 2.83,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  homeBottomNavigation(int selectedIndex, Function selectBottomMenu,
      int totalPage, BuildContext context) {
    List lblHomeBottomMenu = [
      getTranslatedValue(
        context,
        homeBottomMenuHomeLabel,
      ),
      getTranslatedValue(
        context,
        homeBottomMenuCategoryLabel,
      ),
      getTranslatedValue(
        context,
        homeBottomMenuWishlistLabel,
      ),
      getTranslatedValue(
        context,
        homeBottomMenuProfileLabel,
      ),
    ];
    return BottomNavigationBar(
        items: List.generate(
          totalPage,
          (index) => BottomNavigationBarItem(
            backgroundColor: Theme.of(context).cardColor,
            icon: getHomeBottomNavigationBarIcons(
                isActive: selectedIndex == index)[index],
            label: lblHomeBottomMenu[index],
          ),
        ),
        type: BottomNavigationBarType.shifting,
        currentIndex: selectedIndex,
        selectedItemColor: ColorsRes.mainTextColor,
        unselectedItemColor: ColorsRes.appColorTransparent,
        onTap: (int ind) {
          selectBottomMenu(ind);
        },
        elevation: 5);
  }
}

class AnimatedBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final List<String> iconPaths; // Static icons (normal state, PNG, SVG, etc.)
  final List<String>
      animatedPaths; // Animated GIFs or Lottie JSONs for selected state
  final List<String> labels;

  const AnimatedBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
    required this.iconPaths,
    required this.animatedPaths,
    required this.labels,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(labels.length, (index) {
          // Last item: take all available space
          if (index == labels.length - 1) {
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 40, // Large icon size
                      height: 40,
                      child: selectedIndex == index
                          ? Image.asset(animatedPaths[index],
                              fit: BoxFit.contain)
                          : Image.asset(iconPaths[index], fit: BoxFit.contain),
                    ),
                  ],
                ),
              ),
            );
          }
          // Other items (compact)
          double outerWidth = [46.0, 68.0, 68.0, 57.0][index];
          double iconWidth = [24.0, 24.0, 24.0, 24.0][index];
          double iconHeight = [24.0, 24.0, 24.0, 24.0][index];
          double textWidth = [46.0, 76.0, 77.0, 55.0][index];
          double textHeight = 22.0;

          return Container(
            width: outerWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: iconWidth,
                  height: iconHeight,
                  child: selectedIndex == index
                      ? Image.asset(animatedPaths[index], fit: BoxFit.contain)
                      : Image.asset(iconPaths[index], fit: BoxFit.contain),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: textWidth,
                  height: textHeight,
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: selectedIndex == index
                          ? colorScheme.textPrimary
                          : colorScheme.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          index == 0 ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final List<String> staticIcons; // PNG or static asset
  final List<String> animatedIcons; // GIF or Lottie asset
  final List<String> labels;
  final bool showScrollToTop;
  final VoidCallback? onScrollToTopTap;
  final String? exploreMediaUrl; // Network media URL for 5th tab
  final String exploreMediaType; // "image", "gif", or "video"

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.staticIcons,
    required this.animatedIcons,
    required this.labels,
    this.showScrollToTop = false,
    this.onScrollToTopTap,
    this.exploreMediaUrl,
    this.exploreMediaType = "image",
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;
  late Animation<double> _scaleAnimation;
  int _animatingIndex = -1;

  // Video player for explore logo (5th tab)
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _videoError = false;

  // Uniform icon slot size for every bottom nav item (incl. the explore tab)
  static const double _navIconSize = 26;

  // Fixed label slot height so tabs without a label stay the same size
  static const double _navLabelHeight = 14;

  // Hugeicons for each tab
  final strokeIcons = [
    HugeIcons.strokeRoundedHome01,
    HugeIcons.strokeRoundedDashboardSquare01,
    HugeIcons.strokeRoundedStore01,
    HugeIcons.strokeRoundedRepeat,
    HugeIcons.strokeRoundedGift,
  ];

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    // Simple, fast opacity animation
    _fillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fillController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Quick scale bounce
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _fillController,
        curve: Curves.easeOutBack,
      ),
    );

    _fillController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _fillController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (mounted) {
          setState(() {
            _animatingIndex = -1;
          });
        }
      }
    });

    _initVideoIfNeeded();
  }

  void _initVideoIfNeeded() {
    if (widget.exploreMediaType == "video" &&
        widget.exploreMediaUrl != null &&
        widget.exploreMediaUrl!.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.exploreMediaUrl!),
      )..initialize().then((_) {
          if (mounted) {
            _videoController!.setLooping(true);
            _videoController!.setVolume(0);
            _videoController!.play();
            setState(() {
              _videoInitialized = true;
            });
          }
        }).catchError((e) {
          debugPrint("Video init error: $e");
          if (mounted) {
            setState(() {
              _videoError = true;
            });
          }
        });
    }
  }

  @override
  void didUpdateWidget(CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      // Trigger haptic feedback
      HapticFeedback.lightImpact();

      // Trigger one-time fill animation for newly selected tab
      setState(() {
        _animatingIndex = widget.selectedIndex;
      });
      _fillController.forward(from: 0.0);
    }

    // Re-init video if URL changed
    if (oldWidget.exploreMediaUrl != widget.exploreMediaUrl ||
        oldWidget.exploreMediaType != widget.exploreMediaType) {
      _videoController?.dispose();
      _videoController = null;
      _videoInitialized = false;
      _videoError = false;
      _initVideoIfNeeded();
    }
  }

  @override
  void dispose() {
    _fillController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  /// Builds the explore media icon for the 5th tab.
  /// Handles image/gif (via CachedNetworkImage) and video (via VideoPlayer looping).
  /// Falls back to default HugeIcon on error.
  Widget _buildExploreMediaIcon() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    if (widget.exploreMediaType == "video") {
      if (_videoError || _videoController == null) {
        return HugeIcon(
          icon: HugeIcons.strokeRoundedGift,
          strokeWidth: 2.0,
          color: colorScheme.iconSecondary,
          size: _navIconSize,
        );
      }
      if (!_videoInitialized) {
        return SizedBox(
          width: _navIconSize,
          height: _navIconSize,
          child: Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ),
        );
      }
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    // Image or GIF — CachedNetworkImage handles both
    return CachedNetworkImage(
      imageUrl: widget.exploreMediaUrl!,
      width: _navIconSize,
      height: _navIconSize,
      fit: BoxFit.contain,
      placeholder: (context, url) => SizedBox(
        width: _navIconSize,
        height: _navIconSize,
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
      ),
      errorWidget: (context, url, error) => HugeIcon(
        icon: HugeIcons.strokeRoundedGift,
        strokeWidth: 2.0,
        color: colorScheme.iconSecondary,
        size: _navIconSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Combined Cart and Order Tracking Overlay
        Consumer2(
          builder: (context, CartProvider cartProvider,
              OrderTrackingProvider trackingProvider, child) {
            final hasCart = cartProvider.totalItemsCount > 0;
            final hasActiveOrders = trackingProvider.shouldShowOverlay();

            if (!hasCart && !hasActiveOrders) {
              return const SizedBox.shrink();
            }

            return CartOverlay();
          },
        ),

        Container(
          // height: 72,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: Offset(0, -4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: Offset(0, -2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: SafeArea(
            // top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...List.generate(widget.labels.length, (idx) {
                    final isSelected = widget.selectedIndex == idx;
                    final label = widget.labels[idx];

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onTap(idx),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Top border indicator
                            AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              height: 3,
                              width: isSelected ? 40 : 0,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(2),
                                  bottomRight: Radius.circular(2),
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            // Icon with inward fill animation
                            // 5th tab (idx 4): show network media from API
                            if (idx == 4 &&
                                widget.exploreMediaUrl != null &&
                                widget.exploreMediaUrl!.isNotEmpty)
                              SizedBox(
                                width: _navIconSize,
                                height: _navIconSize,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: _buildExploreMediaIcon(),
                                ),
                              )
                            else
                              AnimatedBuilder(
                                animation: _fillController,
                                builder: (context, child) {
                                  final isAnimating = _animatingIndex == idx;
                                  final fillOpacity =
                                      isAnimating ? _fillAnimation.value : 0.0;
                                  final scale =
                                      isAnimating ? _scaleAnimation.value : 1.0;

                                  return Transform.scale(
                                    scale: scale,
                                    child: SizedBox(
                                      width: _navIconSize,
                                      height: _navIconSize,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Base stroke icon
                                          HugeIcon(
                                            icon: strokeIcons[idx],
                                            strokeWidth: 2.0,
                                            color: isSelected
                                                ? colorScheme.primary
                                                : colorScheme.iconSecondary,
                                            size: _navIconSize,
                                          ),
                                          // Single fill layer - simple and smooth
                                          if (isAnimating && fillOpacity > 0)
                                            Opacity(
                                              opacity: fillOpacity * 0.6,
                                              child: HugeIcon(
                                                icon: strokeIcons[idx],
                                                strokeWidth: 4.0,
                                                color: colorScheme.primary,
                                                size: _navIconSize,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            SizedBox(height: 4),
                            // Label — fixed-height slot so every tab keeps the
                            // same overall size even when a label is empty
                            SizedBox(
                              height: _navLabelHeight,
                              child: Center(
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: isSelected
                                        ? colorScheme.textPrimary
                                        : colorScheme.textSecondary,
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    height: 1.2,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
