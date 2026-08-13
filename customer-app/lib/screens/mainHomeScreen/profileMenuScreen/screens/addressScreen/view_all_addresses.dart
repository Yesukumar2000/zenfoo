import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/provider/placeDetailsProvider.dart';
import 'package:project/provider/placeSuggestionsProvider.dart';
import 'package:project/helper/styles/appColorScheme.dart';

class ViewAllAddressesScreen extends StatefulWidget {
  const ViewAllAddressesScreen({Key? key}) : super(key: key);

  @override
  State<ViewAllAddressesScreen> createState() => _ViewAllAddressesScreenState();
}

class _ViewAllAddressesScreenState extends State<ViewAllAddressesScreen> {
  final ScrollController _scrollController = ScrollController();
  String? selectedAddressId;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _loadAddresses();
    });
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      final provider = context.read<AddressProvider>();
      if (provider.hasMoreData &&
          provider.addressState != AddressState.loading) {
        _loadMore();
      }
    }
  }

  Future<void> _loadAddresses() async {
    final provider = context.read<AddressProvider>();
    provider.offset = 0;
    provider.addresses = [];
    await provider.getAddressProvider(context: context);
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    final provider = context.read<AddressProvider>();
    await provider.getAddressProvider(context: context);
    if (mounted) setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, double.maxFinite),
        child: AppHeader(
          label: getTranslatedValue(context, 'addresses'),
          title: getTranslatedValue(context, 'your_delivery_locations'),
          showBackButton: true,
          onBackPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: Consumer<AddressProvider>(
        builder: (context, provider, _) {
          final isLoading = provider.addressState == AddressState.loading &&
              provider.addresses.isEmpty;

          return CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Content
              if (isLoading)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildAddressShimmer(colorScheme),
                      childCount: 5,
                    ),
                  ),
                )
              else if (provider.addresses.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(colorScheme),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // Add New Address Card
                        if (index == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAddNewCard(colorScheme),
                              const SizedBox(height: 24),
                              _buildSectionHeader(
                                  provider.addresses.length, colorScheme),
                              const SizedBox(height: 12),
                            ],
                          );
                        }

                        // Address Cards
                        final addressIndex = index - 1;
                        final address = provider.addresses[addressIndex];
                        final isSelected = selectedAddressId == address.id;
                        return _buildAddressCard(
                            address, isSelected, addressIndex, colorScheme);
                      },
                      childCount: provider.addresses.length + 1,
                    ),
                  ),
                ),

              // Loading More Indicator
              if (_isLoadingMore && provider.hasMoreData)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation(colorScheme.primary),
                        ),
                      ),
                    ),
                  ),
                ),

              // Bottom Padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressShimmer(AppColorScheme colorScheme) {
    return GradientBorderCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      gradient: colorScheme.cardGradient,
      borderGradient: colorScheme.borderGradient,
      shadows: colorScheme.cardShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CustomShimmer(
                width: 44,
                height: 44,
                borderRadius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    CustomShimmer(
                      width: 100,
                      height: 16,
                      borderRadius: 4,
                    ),
                    SizedBox(height: 6),
                    CustomShimmer(
                      width: 120,
                      height: 12,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
              const CustomShimmer(
                width: 32,
                height: 32,
                borderRadius: 8,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: colorScheme.divider),
          const SizedBox(height: 12),
          const CustomShimmer(
            width: double.infinity,
            height: 14,
            borderRadius: 4,
          ),
          const SizedBox(height: 6),
          const CustomShimmer(
            width: 200,
            height: 14,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(int count, AppColorScheme colorScheme) {
    return Row(
      children: [
        Text(
          getTranslatedValue(context, 'all_addresses'),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddNewCard(AppColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider(
                        create: (_) => PlaceSuggestionsProvider()),
                    ChangeNotifierProvider(
                        create: (_) => PlaceDetailsProvider()),
                  ],
                  child: LocationPickerScreen(),
                ),
              ),
            );

            if (result != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddressDetailScreen(
                    addressProviderContext: context,
                    pickedAddressData: result,
                  ),
                ),
              ).then((_) => _loadAddresses());
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: colorScheme.iconTileGradient,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_location_alt_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getTranslatedValue(context, 'add_new_address'),
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        getTranslatedValue(
                            context, 'save_time_on_your_next_order'),
                        style: GoogleFonts.inter(
                          color: colorScheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(UserAddressData address, bool isSelected, int index,
      AppColorScheme colorScheme) {
    return GradientBorderCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 18,
      borderWidth: isSelected ? 2 : 1,
      gradient:
          isSelected ? colorScheme.heroGradient : colorScheme.cardGradient,
      borderGradient: isSelected
          ? colorScheme.borderGradientStrong
          : colorScheme.borderGradient,
      shadows: isSelected
          ? [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ]
          : colorScheme.cardShadow,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => selectedAddressId = address.id);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.1)
                            : colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getAddressIcon(address.type),
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.iconSecondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Type and Default badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                address.type ?? 'Other',
                                style: GoogleFonts.inter(
                                  color: colorScheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (address.isDefault == '1') ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    getTranslatedValue(context, 'default')
                                        .toUpperCase(),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (address.mobile != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 11,
                                  color: colorScheme.textTertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  address.mobile!,
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // More menu
                    PopupMenuButton<String>(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.more_vert,
                          color: colorScheme.iconSecondary,
                          size: 18,
                        ),
                      ),
                      offset: const Offset(0, 40),
                      color: colorScheme.surface,
                      elevation: 8,
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddressDetailScreen(
                                addressProviderContext: context,
                                address: address,
                              ),
                            ),
                          ).then((_) => _loadAddresses());
                        } else if (value == 'delete') {
                          _showDeleteDialog(address, colorScheme);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          height: 40,
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                color: colorScheme.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                getTranslatedValue(context, 'edit'),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // PopupMenuItem(
                        //   value: 'share',
                        //   height: 40,
                        //   child: Row(
                        //     children: [
                        //       Icon(
                        //         Icons.share_outlined,
                        //         color: colorScheme.iconSecondary,
                        //         size: 18,
                        //       ),
                        //       const SizedBox(width: 10),
                        //       Text(
                        //         getTranslatedValue(context, 'share'),
                        //         style: GoogleFonts.inter(
                        //           fontSize: 13,
                        //           fontWeight: FontWeight.w500,
                        //           color: colorScheme.textPrimary,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        PopupMenuItem(
                          value: 'delete',
                          height: 40,
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: colorScheme.error,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                getTranslatedValue(context, 'delete'),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Divider
                Container(height: 1, color: colorScheme.divider),
                const SizedBox(height: 12),
                // Address Text
                Text(
                  _buildFullAddress(address),
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                // Selected Badge
                if (isSelected) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          getTranslatedValue(context, 'selected_address'),
                          style: GoogleFonts.inter(
                            color: colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.1),
                    colorScheme.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_outlined,
                size: 70,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              getTranslatedValue(context, 'no_saved_addresses'),
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              getTranslatedValue(context, 'add_your_delivery_address'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                HapticFeedback.lightImpact();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MultiProvider(
                      providers: [
                        ChangeNotifierProvider(
                            create: (_) => PlaceSuggestionsProvider()),
                        ChangeNotifierProvider(
                            create: (_) => PlaceDetailsProvider()),
                      ],
                      child: LocationPickerScreen(),
                    ),
                  ),
                );

                if (result != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddressDetailScreen(
                        addressProviderContext: context,
                        pickedAddressData: result,
                      ),
                    ),
                  ).then((_) => _loadAddresses());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_circle_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    getTranslatedValue(context, 'add_your_first_address'),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAddressIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'home':
        return Icons.home_rounded;
      case 'work':
      case 'office':
        return Icons.business_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  String _buildFullAddress(UserAddressData address) {
    List<String> parts = [];
    if (address.address != null && address.address!.isNotEmpty) {
      parts.add(address.address!);
    }
    if (address.landmark != null && address.landmark!.isNotEmpty) {
      parts.add(address.landmark!);
    }
    // if (address.area != null && address.area!.isNotEmpty) {
    //   parts.add(address.area!);
    // }
    // if (address.pincode != null && address.pincode!.isNotEmpty) {
    //   parts.add(address.pincode!);
    // }
    return parts.join(', ');
  }

  void _showDeleteDialog(UserAddressData address, AppColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                getTranslatedValue(context, 'delete_address_question'),
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: colorScheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                getTranslatedValue(
                    context, 'address_will_be_permanently_removed'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: colorScheme.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        getTranslatedValue(context, 'cancel'),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _deleteAddress(address, colorScheme);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        getTranslatedValue(context, 'delete'),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteAddress(
      UserAddressData address, AppColorScheme colorScheme) async {
    try {
      final provider = context.read<AddressProvider>();
      provider.deleteAddress(context: context, address: address);
      await _loadAddresses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  getTranslatedValue(context, 'address_deleted_successfully'),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: colorScheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  getTranslatedValue(context, 'failed_to_delete_address'),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}
