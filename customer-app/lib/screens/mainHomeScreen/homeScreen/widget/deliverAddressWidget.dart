import 'package:geolocator/geolocator.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/category_groups.dart';
import 'package:project/screens/mainHomeScreen/homeScreen/widget/category_header_tab.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:project/screens/mainHomeScreen/profileMenuScreen/screens/addressScreen/view_all_addresses.dart';
import 'package:project/screens/mainHomeScreen/profileMenuScreen/widget/zenfo_money_screen.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/screens/mainHomeScreen/homeScreen/widget/weatherAnimationWidget.dart';

class DeliveryAddressWidget extends StatefulWidget {
  const DeliveryAddressWidget({super.key});

  @override
  State<DeliveryAddressWidget> createState() => _DeliveryAddressWidgetState();
}

class _DeliveryAddressWidgetState extends State<DeliveryAddressWidget> {
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeScreenProvider>();
    final brandTitle = "Zenfoo";
    final price = "₹0";

    final addressLine =
        Constant.session.getData(SessionManager.keyAddress) ?? '';

    final selectedIdx = provider.selectedStoreIdx;

    CategoryGroup? group;
    if (selectedIdx > 0 &&
        provider.storeGroups.isNotEmpty &&
        selectedIdx - 1 < provider.storeGroups.length) {
      group = provider.storeGroups[selectedIdx];
    }

    late final Color mainColor;
    if (selectedIdx == 0) {
      mainColor = const Color(0xFF9AC444);
    } else {
      mainColor = group != null
          ? Constant.colorFromHex(group.color ?? "#FFA13B")
          : const Color(0xFFFFA13B);
    }

    final bgDecoration = BoxDecoration(
      gradient: LinearGradient(
        colors: [mainColor, Colors.white],
        stops: const [0, 0.7],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );

    return Container(
      width: double.infinity,
      decoration: bgDecoration,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 24,
        right: 24,
        bottom: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Title
          Text(
            brandTitle,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),

          // Dynamic: show shimmer, error, or actual content
          Builder(
            builder: (context) {
              if (provider.etaState == HomeScreenState.loading)
                return getEtaShimmer();
              if (provider.etaState == HomeScreenState.error)
                return Text(
                  getTranslatedValue(context, 'failed_to_load_eta'),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                );
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery info
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final result = await showAddressesBottomSheet(context);

                        if (result != null && result is UserAddressData) {
                          Constant.session.setData(SessionManager.keyLatitude,
                              result.latitude ?? "", false);
                          Constant.session.setData(SessionManager.keyLongitude,
                              result.longitude ?? "", false);
                          Constant.session.setData(SessionManager.keyAddress,
                              _buildAddressString(result), true);

                          final params =
                              await Constant.getProductsDefaultParams();
                          context.read<HomeScreenProvider>().loadSections(
                              params: params,
                              context: context,
                              resetStoreSelection: true);
                        }
                        setState(() {});
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.estimatedTime ??
                                getTranslatedValue(context, 'in_30_minutes'),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              height: 1.02,
                            ),
                          ),
                          // SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  addressLine.isNotEmpty
                                      ? addressLine
                                      : getTranslatedValue(
                                          context, 'tap_to_add_your_address'),
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 22,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  CartProfileWidget(price: price, iconColor: Colors.black),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Search bar
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, productSearchScreen);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Color(0xFF7C7B7B), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedTextKit(
                      repeatForever: true,
                      animatedTexts: [
                        FadeAnimatedText(
                          getTranslatedValue(
                              context, 'search_for_grocery_items'),
                          textStyle: GoogleFonts.inter(
                            color: const Color(0xFF7C7B7B),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                        FadeAnimatedText(
                          getTranslatedValue(context, 'search_snacks_bakery'),
                          textStyle: GoogleFonts.inter(
                            color: const Color(0xFF7C7B7B),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      ],
                      pause: const Duration(milliseconds: 800),
                      isRepeatingAnimation: true,
                      displayFullTextOnTap: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Image.asset(
                    "assets/icons/mic.png",
                    width: 22,
                    height: 22,
                    color: const Color(0xFF28A745),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 1,
                    height: 20,
                    color: const Color(0xFFE0E0E0),
                  ),
                  const SizedBox(width: 12),
                  Image.asset(
                    "assets/icons/note.png",
                    width: 22,
                    height: 22,
                    color: const Color(0xFF28A745),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          CategoryHeaderTabBar(
            categories: provider.storeGroups,
            selectedIndex: provider.selectedStoreIdx,
            onTap: (i) {
              provider.setSelectedStoreTab(context, i);
            },
          )
        ],
      ),
    );
  }
}

class CartProfileWidget extends StatelessWidget {
  final String price;
  final Color iconColor;
  const CartProfileWidget({
    super.key,
    required this.price,
    this.iconColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionManager>(
      builder: (context, session, _) {
        final walletBalance =
            session.getData(SessionManager.keyWalletBalance, defaultValue: "0");
        final profileImage = session.getData(SessionManager.keyUserImage);
        final userName = session.getData(SessionManager.keyUserName);

        // Format wallet balance
        String formattedBalance = "₹0";
        try {
          final balance = double.tryParse(walletBalance) ?? 0.0;
          if (balance >= 1000) {
            formattedBalance = "₹${(balance / 1000).toStringAsFixed(1)}k";
          } else {
            formattedBalance = "₹${balance.toStringAsFixed(0)}";
          }
        } catch (e) {
          formattedBalance = "₹0";
        }

        return Row(
          children: [
            WeatherAnimationWidget(
                isRaining: context.watch<HomeScreenProvider>().isRaining),
            // Wallet
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                final walletBalance = num.tryParse(Constant.session
                        .getData(SessionManager.keyWalletBalance)) ??
                    0;
                if (walletBalance == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ZenfooMoneyScreen(),
                    ),
                  );
                } else {
                  Navigator.pushNamed(context, walletHistoryListScreen);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 16,
                      child: Image.asset(
                        "assets/icons/home_wallet.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      formattedBalance,
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Profile
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return ProfileScreen(
                    scrollController: ScrollController(),
                  );
                }));
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                clipBehavior: Clip.antiAlias,
                child: profileImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: profileImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(Icons.person,
                              size: 22, color: Colors.grey.shade400),
                        ),
                        errorWidget: (context, url, error) => Container(
                          alignment: Alignment.center,
                          child: userName.isNotEmpty
                              ? Text(
                                  userName[0].toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: iconColor,
                                    letterSpacing: -0.55,
                                  ),
                                )
                              : Icon(Icons.person, size: 22, color: iconColor),
                        ),
                      )
                    : Container(
                        alignment: Alignment.center,
                        child: userName.isNotEmpty
                            ? Text(
                                userName[0].toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: iconColor,
                                  letterSpacing: -0.55,
                                ),
                              )
                            : Icon(Icons.person, size: 22, color: iconColor),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Example shimmer for ETA. Replace with your package or layout:
Widget getEtaShimmer() {
  return Container(
    height: 48,
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Container(
            width: 110,
            height: 24,
            color: Colors.white.withOpacity(0.4),
            margin: const EdgeInsets.all(8)),
        Expanded(
          child: Container(
            height: 20,
            color: Colors.white.withOpacity(0.4),
            margin: const EdgeInsets.all(8),
          ),
        )
      ],
    ),
  );
}

Future<dynamic> showAddressesBottomSheet(BuildContext context,
    {Function(UserAddressData)? onAddressSelected}) async {
  final result = await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        AddressBodyBottomSheet(onAddressSelected: onAddressSelected),
  );
  return result;
}

class AddressBodyBottomSheet extends StatefulWidget {
  final Function(UserAddressData)? onAddressSelected;

  const AddressBodyBottomSheet({super.key, this.onAddressSelected});

  @override
  State<AddressBodyBottomSheet> createState() => _AddressBodyBottomSheetState();
}

class _AddressBodyBottomSheetState extends State<AddressBodyBottomSheet> {
  bool locationPermissionDenied = false;

  String _buildAddressString(UserAddressData address) {
    final parts = <String>[];

    if (address.address != null &&
        address.address!.isNotEmpty &&
        address.address != 'null') {
      parts.add(address.address!);
    }
    // if (address.area != null &&
    //     address.area!.isNotEmpty &&
    //     address.area != 'null') {
    //   parts.add(address.area!);
    // }
    if (address.landmark != null &&
        address.landmark!.isNotEmpty &&
        address.landmark != 'null') {
      parts.add(address.landmark!);
    }
    // if (address.city != null &&
    //     address.city!.isNotEmpty &&
    //     address.city != 'null') {
    //   parts.add(address.city!);
    // }
    // if (address.state != null &&
    //     address.state!.isNotEmpty &&
    //     address.state != 'null') {
    //   parts.add(address.state!);
    // }
    // if (address.country != null &&
    //     address.country!.isNotEmpty &&
    //     address.country != 'null') {
    //   parts.add(address.country!);
    // }
    // if (address.pincode != null &&
    //     address.pincode!.isNotEmpty &&
    //     address.pincode != 'null') {
    //   parts.add(address.pincode!);
    // }

    return parts.join(', ');
  }

  @override
  void initState() {
    super.initState();
    checkLocationPermission();
    Future.delayed(Duration.zero, () {
      if (!Constant.session.isUserLoggedIn()) return;
      final provider = context.read<AddressProvider>();
      provider.offset = 0;
      provider.addresses = [];
      provider.getAddressProvider(context: context).then((_) {
        _storeDefaultAddressInSession(provider.addresses);
      });
    });
  }

  void _storeDefaultAddressInSession(List<UserAddressData> addresses) {
    if (addresses.isEmpty) return;

    // Find default address or use first address
    UserAddressData? addressToStore;
    for (var address in addresses) {
      if (address.isDefault == '1') {
        addressToStore = address;
        break;
      }
    }
    addressToStore ??= addresses.first;

    // Store address details in session
    final addressString = _buildAddressString(addressToStore);
    Constant.session.setData(
      SessionManager.keyAddress,
      addressString,
      false,
    );

    if (addressToStore.latitude != null &&
        addressToStore.latitude!.isNotEmpty) {
      Constant.session.setData(
        SessionManager.keyLatitude,
        addressToStore.latitude!,
        false,
      );
    }
    if (addressToStore.longitude != null &&
        addressToStore.longitude!.isNotEmpty) {
      Constant.session.setData(
        SessionManager.keyLongitude,
        addressToStore.longitude!,
        false,
      );
    }

    if (addressToStore.id != null) {
      Constant.session.setData(
        'selectedAddressId',
        addressToStore.id!,
        false,
      );
    }
    if (addressToStore.name != null) {
      Constant.session.setData(
        'selectedAddressName',
        addressToStore.name!,
        false,
      );
    }
    if (addressToStore.mobile != null) {
      Constant.session.setData(
        'selectedAddressPhone',
        addressToStore.mobile!,
        false,
      );
    }
    if (addressToStore.type != null) {
      Constant.session.setData(
        'selectedAddressType',
        addressToStore.type!,
        false,
      );
    }
  }

  Future<void> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    setState(() {
      locationPermissionDenied = !serviceEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever;
    });
  }

  Future<void> requestLocationPermission() async {
    await Geolocator.requestPermission();
    checkLocationPermission();
  }

  Future<void> _useCurrentLocation(
    BuildContext context,
    dynamic colorScheme,
  ) async {
    try {
      // Check location permission first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await requestLocationPermission();
        permission = await Geolocator.checkPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location permission is required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ),
      );

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );

      // Create a temporary address object with current location
      final tempAddress = UserAddressData(
        id: '0',
        type: 'other',
        name: 'Current Location',
        mobile: '',
        address: 'Current Location',
        landmark: '',
        area: '',
        city: '',
        state: '',
        country: '',
        pincode: '',
        latitude: position.latitude.toString(),
        longitude: position.longitude.toString(),
        isDefault: '0',
      );

      // Save current location to session
      Constant.session.setData(
        SessionManager.keyAddress,
        'Current Location',
        false,
      );

      // Store latitude and longitude
      Constant.session.setData(
        SessionManager.keyLatitude,
        position.latitude.toString(),
        false,
      );

      Constant.session.setData(
        SessionManager.keyLongitude,
        position.longitude.toString(),
        false,
      );

      // Store address details for current location
      Constant.session.setData(
        'selectedAddressName',
        'Current Location',
        false,
      );

      Constant.session.setData(
        'selectedAddressType',
        'current_location',
        false,
      );

      Constant.session.setData(
        'selectedAddressId',
        '0',
        false,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Call the onAddressSelected callback if provided
      if (widget.onAddressSelected != null && mounted) {
        await widget.onAddressSelected!(tempAddress);
      }

      // Fetch estimated time for the current location
      if (mounted) {
        final homeProvider = context.read<HomeScreenProvider>();
        await homeProvider.loadEta(context);
      }

      // Close the bottom sheet
      if (mounted) {
        Navigator.pop(context, tempAddress);
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
      if (mounted) {
        // Close loading dialog if still open
        Navigator.of(context, rootNavigator: true).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get current location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar with improved styling
            Container(
              margin: EdgeInsets.only(top: 16, bottom: 16),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: colorScheme.border.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modern Header with Icon Background
                    Container(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              color: colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  getTranslatedValue(
                                      context, 'select_delivery_location'),
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Choose where to deliver',
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    height: 1.3,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),

                    // Location Permission Banner
                    if (locationPermissionDenied)
                      Container(
                        margin: EdgeInsets.only(bottom: 20),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF9AC444), Color(0xFF88B03A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x1A9AC444),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_off_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getTranslatedValue(
                                        context, 'location_access_required'),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      height: 1.3,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    getTranslatedValue(context,
                                        'enable_location_for_accurate_delivery'),
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                            GestureDetector(
                              onTap: requestLocationPermission,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x1A000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  getTranslatedValue(context, 'enable'),
                                  style: GoogleFonts.inter(
                                    color: Color(0xFF9AC444),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Saved Addresses Header with Modern Styling
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getTranslatedValue(context, 'saved_addresses'),
                                style: GoogleFonts.inter(
                                  color: colorScheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Quick access to your addresses',
                                style: GoogleFonts.inter(
                                  color: colorScheme.textTertiary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  height: 1.3,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ViewAllAddressesScreen()),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                getTranslatedValue(context, 'view_all'),
                                style: GoogleFonts.inter(
                                  color: colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: colorScheme.border,
                      height: 1,
                      thickness: 1,
                    ),
                    SizedBox(height: 16),

                    // Address List
                    Consumer<AddressProvider>(
                      builder: (context, provider, _) {
                        if (provider.addressState == AddressState.loading) {
                          return Container(
                            height: 120,
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                              color: colorScheme.primary,
                              strokeWidth: 2.5,
                            ),
                          );
                        } else if (provider.addresses.isEmpty ||
                            provider.addressState == AddressState.error) {
                          return Container(
                            padding: EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    colorScheme.border.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.location_on_outlined,
                                    size: 32,
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  getTranslatedValue(
                                      context, 'no_saved_addresses_yet'),
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  getTranslatedValue(context,
                                      'add_a_new_address_to_get_started'),
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    height: 1.4,
                                    letterSpacing: -0.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 24),
                                // Use Current Location Button
                                SizedBox(
                                  width: double.infinity,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                ViewAllAddressesScreen()),
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colorScheme.primary
                                                .withValues(alpha: 0.25),
                                            blurRadius: 12,
                                            offset: Offset(0, 4),
                                          ),
                                          BoxShadow(
                                            color: colorScheme.primary
                                                .withValues(alpha: 0.08),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.location_searching_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Use Current Location',
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              height: 1.2,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final currentSavedAddress =
                            Constant.session.getData(SessionManager.keyAddress)
                                    as String? ??
                                '';

                        return Column(
                          children: List.generate(
                            provider.addresses.length,
                            (index) {
                              final address = provider.addresses[index];
                              final isLast =
                                  index == (provider.addresses.length - 1);
                              final addressString =
                                  _buildAddressString(address);
                              final isCurrentlySelected =
                                  currentSavedAddress == addressString;

                              return GestureDetector(
                                onTap: () async {
                                  // Store address details in session
                                  final addressString =
                                      _buildAddressString(address);
                                  Constant.session.setData(
                                    SessionManager.keyAddress,
                                    addressString,
                                    false,
                                  );

                                  // Store latitude and longitude for location-based operations
                                  if (address.latitude != null &&
                                      address.latitude!.isNotEmpty) {
                                    Constant.session.setData(
                                      SessionManager.keyLatitude,
                                      address.latitude!,
                                      false,
                                    );
                                  }
                                  if (address.longitude != null &&
                                      address.longitude!.isNotEmpty) {
                                    Constant.session.setData(
                                      SessionManager.keyLongitude,
                                      address.longitude!,
                                      false,
                                    );
                                  }

                                  // Store full address details for detailed view
                                  if (address.id != null) {
                                    Constant.session.setData(
                                      'selectedAddressId',
                                      address.id!,
                                      false,
                                    );
                                  }
                                  if (address.name != null) {
                                    Constant.session.setData(
                                      'selectedAddressName',
                                      address.name!,
                                      false,
                                    );
                                  }
                                  if (address.mobile != null) {
                                    Constant.session.setData(
                                      'selectedAddressPhone',
                                      address.mobile!,
                                      false,
                                    );
                                  }
                                  if (address.type != null) {
                                    Constant.session.setData(
                                      'selectedAddressType',
                                      address.type!,
                                      false,
                                    );
                                  }

                                  // Close the bottom sheet first
                                  Navigator.pop(context, address);

                                  // Call the callback from parent to handle all address logic
                                  if (widget.onAddressSelected != null) {
                                    await widget.onAddressSelected!(address);
                                  }
                                },
                                child: Stack(
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(
                                          bottom: isLast ? 0 : 14),
                                      padding: EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: isCurrentlySelected
                                            ? colorScheme.primary
                                                .withValues(alpha: 0.1)
                                            : (address.isDefault == '1'
                                                ? colorScheme.primary
                                                    .withValues(alpha: 0.05)
                                                : colorScheme.surfaceVariant),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isCurrentlySelected
                                              ? colorScheme.primary
                                              : (address.isDefault == '1'
                                                  ? colorScheme.primary
                                                      .withValues(alpha: 0.35)
                                                  : colorScheme.border),
                                          width: isCurrentlySelected ? 2 : 1.2,
                                        ),
                                        boxShadow: isCurrentlySelected
                                            ? [
                                                BoxShadow(
                                                  color: colorScheme.primary
                                                      .withValues(alpha: 0.12),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 6),
                                                ),
                                                BoxShadow(
                                                  color: colorScheme.primary
                                                      .withValues(alpha: 0.05),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                )
                                              ]
                                            : [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.04),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                )
                                              ],
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: isCurrentlySelected
                                                  ? colorScheme.primary
                                                      .withValues(alpha: 0.2)
                                                  : (address.isDefault == '1'
                                                      ? colorScheme.primary
                                                          .withValues(
                                                              alpha: 0.15)
                                                      : colorScheme.primary
                                                          .withValues(
                                                              alpha: 0.1)),
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                            ),
                                            child: Icon(
                                              address.type?.toLowerCase() ==
                                                      'home'
                                                  ? Icons.home_rounded
                                                  : address.type
                                                              ?.toLowerCase() ==
                                                          'office'
                                                      ? Icons.business_rounded
                                                      : Icons
                                                          .location_on_rounded,
                                              color: isCurrentlySelected
                                                  ? colorScheme.primary
                                                  : colorScheme.primary,
                                              size: 24,
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        address.type ?? 'Other',
                                                        style:
                                                            GoogleFonts.inter(
                                                          color: colorScheme
                                                              .textPrimary,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          height: 1.0,
                                                          letterSpacing: -0.3,
                                                        ),
                                                      ),
                                                    ),
                                                    if (address.isDefault ==
                                                        '1') ...[
                                                      SizedBox(width: 8),
                                                      Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 10,
                                                                vertical: 4),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: colorScheme
                                                              .primary,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: Text(
                                                          'Default',
                                                          style:
                                                              GoogleFonts.inter(
                                                            color: Colors.white,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            height: 1.0,
                                                            letterSpacing: -0.2,
                                                          ),
                                                        ),
                                                      ),
                                                    ]
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  _buildAddressString(address),
                                                  style: GoogleFonts.inter(
                                                    color: colorScheme
                                                        .textSecondary,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    height: 1.4,
                                                    letterSpacing: -0.3,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isCurrentlySelected) ...[
                                            SizedBox(width: 12),
                                            Padding(
                                              padding: EdgeInsets.only(top: 2),
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.check_rounded,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ]
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 8),
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

// import 'package:project/helper/utils/generalImports.dart';

// class DeliveryAddressWidget extends StatelessWidget {
//   const DeliveryAddressWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.pushNamed(context, confirmLocationScreen,
//             arguments: [null, "location"]).then((value) async {
//           if (value is bool) {
//             if (value == true) {
//               Map<String, String> params =
//                   await Constant.getProductsDefaultParams();
//               await context
//                   .read<HomeScreenProvider>()
//                   .getHomeScreenApiProvider(context: context, params: params);
//             }
//           }
//         });
//       },
//       child: ListTile(
//         contentPadding: EdgeInsetsDirectional.zero,
//         horizontalTitleGap: 0,
//         leading: getDarkLightIcon(
//           image: "home_map",
//           height: 35,
//           width: 35,
//           padding: EdgeInsetsDirectional.only(
//             top: Constant.size10,
//             bottom: Constant.size10,
//             end: Constant.size10,
//           ),
//         ),
//         title: CustomTextLabel(
//           jsonKey: deliveryToLabel,
//           softWrap: true,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//           style: TextStyle(
//               fontSize: 15,
//               color: ColorsRes.mainTextColor,
//               fontWeight: FontWeight.w500),
//         ),
//         subtitle: Constant.session.getData(SessionManager.keyAddress).isNotEmpty
//             ? CustomTextLabel(
//                 text: Constant.session.getData(SessionManager.keyAddress),
//                 maxLines: 1,
//                 softWrap: true,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                     fontSize: 12, color: ColorsRes.subTitleMainTextColor),
//               )
//             : CustomTextLabel(
//                 jsonKey: addNewAddressLabel,
//                 softWrap: true,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                     fontSize: 12, color: ColorsRes.subTitleMainTextColor),
//               ),
//       ),
//     );
//   }
// }
