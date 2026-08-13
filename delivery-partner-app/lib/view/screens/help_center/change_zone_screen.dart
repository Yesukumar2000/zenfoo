import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/view/custom_widgets/customTextField.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import '../../../models/store_location_model.dart';
import '../../../utils/appHeader.dart';
import '../../custom_widgets/custom_button.dart';

class SelectCityStep extends StatefulWidget {
  final Function(Future<bool> Function())? onSaveCallback;

  const SelectCityStep({
    super.key,
    this.onSaveCallback,
  });

  @override
  State<SelectCityStep> createState() => _SelectCityStepState();
}

class _SelectCityStepState extends State<SelectCityStep> {
  int selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Fetch nearby cities when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().getNearbyCities();
    });

    // Register save callback
    if (widget.onSaveCallback != null) {
      widget.onSaveCallback!(_saveCitySelection);
    }

    // Add search listener with debouncing
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Cancel previous timer if exists
    _debounceTimer?.cancel();

    // Create new timer for debouncing
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        final searchText = _searchController.text.trim();
        context.read<AuthProvider>().getNearbyCities(
              search: searchText.isNotEmpty ? searchText : "",
            );
      }
    });
  }

  Future<bool> _saveCitySelection() async {
    final authProvider = context.read<AuthProvider>();
    final cities = authProvider.cities;

    if (cities.isEmpty) {
      return false;
    }

    final selectedCity = cities[selectedIndex];

    // Call update city API
    await authProvider.updateCity(cityId: selectedCity.id);

    // Return success status
    return isStatusSuccess(authProvider.updateCityState.status);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final languageProvider = context.read<LanguageProvider>();

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: languageProvider.getTranslatedText('support'),
            title: languageProvider.getTranslatedText('change_zone'),
            onBackPressed: () => Navigator.pop(context),
            showBackButton: true,
            showExitButton: false,
          ),
          Expanded(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final isLoading =
                    isStatusLoading(authProvider.getNearbyCitiesState.status);
                final cities = authProvider.cities;
                final currentCityName =
                    authProvider.currentDeliveryBoy?.cityName ?? '';

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),

                              // Title
                              Text(
                                languageProvider
                                    .getTranslatedText('select_a_zone'),
                                style: GoogleFonts.inter(
                                  color: colorScheme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),

                              const SizedBox(height: 6),

                              // Subtitle
                              Text(
                                languageProvider.getTranslatedText(
                                    'zone_change_after_6_days'),
                                style: GoogleFonts.inter(
                                  color: colorScheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Current Zone
                              if (currentCityName.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colorScheme.border
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.navigation_outlined,
                                          size: 18,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              languageProvider
                                                  .getTranslatedText(
                                                      'current_zone'),
                                              style: GoogleFonts.inter(
                                                color:
                                                    colorScheme.textSecondary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              currentCityName,
                                              style: GoogleFonts.inter(
                                                color: colorScheme.textPrimary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 16),

                              // Search Field
                              CustomTextFormField(
                                borderRadius: 40,
                                controller: _searchController,
                                hintText: languageProvider
                                    .getTranslatedText('search_zones'),
                                title: '',
                                prefixIcon: const Icon(Icons.search),
                              ),

                              const SizedBox(height: 20),

                              // Suggested zones label
                              Text(
                                languageProvider
                                    .getTranslatedText('suggested_zones'),
                                style: GoogleFonts.inter(
                                  color: colorScheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Loading State
                              if (isLoading)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: CircularProgressIndicator(),
                                  ),
                                ),

                              // Empty State
                              if (!isLoading && cities.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      languageProvider.getTranslatedText(
                                          'no_zones_found'),
                                      style: GoogleFonts.inter(
                                        color: colorScheme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),

                              // Zone List
                              if (!isLoading && cities.isNotEmpty)
                                ...List.generate(cities.length, (index) {
                                  final city = cities[index];
                                  final isSelected = index == selectedIndex;

                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      setState(() => selectedIndex = index);
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      decoration: BoxDecoration(
                                        border: index < cities.length - 1
                                            ? Border(
                                                bottom: BorderSide(
                                                  color: colorScheme.border
                                                      .withValues(alpha: 0.15),
                                                  width: 1,
                                                ),
                                              )
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          // Navigation Icon
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: colorScheme.surfaceContainer,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.navigation_outlined,
                                              size: 18,
                                              color: colorScheme.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Zone Name & Distance
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  city.name,
                                                  style: GoogleFonts.inter(
                                                    color: colorScheme
                                                        .textPrimary,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    height: 1.4,
                                                  ),
                                                ),
                                                if (city.distanceKm != null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 2),
                                                    child: Text(
                                                      '${city.distanceKm!.toStringAsFixed(1)} Kms',
                                                      style: GoogleFonts.inter(
                                                        color: colorScheme
                                                            .textTertiary,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),

                                          // Radio Button Style
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected
                                                    ? colorScheme.primary
                                                    : colorScheme.border,
                                                width: isSelected ? 2 : 1.5,
                                              ),
                                            ),
                                            child: isSelected
                                                ? Center(
                                                    child: Container(
                                                      width: 12,
                                                      height: 12,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: colorScheme
                                                            .primary,
                                                      ),
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),

                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Continue Button
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
                      child: CustomButton(
                        text: languageProvider.getTranslatedText('continue'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SelectStoreStep(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SelectStoreStep extends StatefulWidget {
  final Function(Future<bool> Function())? onSaveCallback;

  const SelectStoreStep({super.key, this.onSaveCallback});

  @override
  State<SelectStoreStep> createState() => _SelectStoreStepState();
}

class _SelectStoreStepState extends State<SelectStoreStep> {
  Set<int> selectedStoreIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();

      // Pre-select stores if already selected
      final deliveryBoy = authProvider.currentDeliveryBoy;
      if (deliveryBoy?.storeLocations != null) {
        setState(() {
          selectedStoreIds =
              deliveryBoy!.storeLocations!.map((store) => store.id).toSet();
        });
      }

      authProvider.getStoreLocations();

      // Register save callback with parent form
      if (widget.onSaveCallback != null) {
        widget.onSaveCallback!(_saveStoreSelection);
      }
    });
  }

  Future<bool> _saveStoreSelection() async {
    if (selectedStoreIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one store')),
      );
      return false;
    }

    final authProvider = context.read<AuthProvider>();
    await authProvider.selectStoreLocations(
      storeLocationIds: selectedStoreIds.toList(),
    );

    return isStatusSuccess(authProvider.selectStoreLocationsState.status);
  }

  void _toggleStoreSelection(int storeId) {
    setState(() {
      if (selectedStoreIds.contains(storeId)) {
        selectedStoreIds.remove(storeId);
      } else {
        selectedStoreIds.add(storeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: 'support',
            title: 'Change Zone',
            onBackPressed: () => Navigator.pop(context),
            showBackButton: true,
          ),
          Expanded(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final getStoreLocationsState =
                    authProvider.getStoreLocationsState;
                final stores = authProvider.storeLocations;

                return Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Select the stores you will pick orders from",
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppDimensions.paddingSmall),
                      Text(
                        "You can select multiple stores",
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingLarge),
                      if (isStatusLoading(getStoreLocationsState.status))
                        Center(
                          child: CircularProgressIndicator(
                            color: colorScheme.primary,
                          ),
                        )
                      else if (stores.isEmpty)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.store_outlined,
                                size: 64,
                                color: colorScheme.textSecondary,
                              ),
                              const SizedBox(
                                  height: AppDimensions.paddingMedium),
                              Text(
                                'No stores available',
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: stores.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(
                                    height: AppDimensions.paddingMedium),
                            itemBuilder: (context, index) {
                              final store = stores[index];
                              final isSelected =
                                  selectedStoreIds.contains(store.id);

                              return _buildStoreCard(
                                store: store,
                                isSelected: isSelected,
                                colorScheme: colorScheme,
                                textTheme: textTheme,
                              );
                            },
                          ),
                        ),
                      if (selectedStoreIds.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.paddingMedium),
                        Container(
                          padding:
                              const EdgeInsets.all(AppDimensions.paddingMedium),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                                AppDimensions.borderRadius),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: AppDimensions.paddingSmall),
                              Text(
                                '${selectedStoreIds.length} ${selectedStoreIds.length == 1 ? 'store' : 'stores'} selected',
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingLarge),
                        CustomButton(
                          text: 'Change Zone',
                          isLoading: isStatusLoading(
                              authProvider.selectStoreLocationsState.status),
                          onPressed: () async {
                            // Call the API to update store locations
                            await authProvider.selectStoreLocations(
                              storeLocationIds: selectedStoreIds.toList(),
                            );

                            if (!context.mounted) return;

                            // Check if the API call was successful
                            if (isStatusSuccess(authProvider
                                .selectStoreLocationsState.status)) {
                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Zone changed successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              // Navigate back to the previous screen
                              Navigator.pop(context);
                              Navigator.pop(context);
                            } else {
                              // Show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(authProvider
                                          .selectStoreLocationsState.message ??
                                      'Failed to change zone'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard({
    required StoreLocation store,
    required bool isSelected,
    required colorScheme,
    required TextTheme textTheme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggleStoreSelection(store.id),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.1)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Store Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.store,
                  size: 24,
                  color: isSelected ? Colors.white : colorScheme.iconSecondary,
                ),
              ),

              const SizedBox(width: AppDimensions.paddingMedium),

              /// Store Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Store Name
                    Text(
                      store.name,
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// City
                    Row(
                      children: [
                        Icon(
                          Icons.location_city,
                          size: 14,
                          color: isSelected
                              ? colorScheme.textSecondary
                              : colorScheme.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          store.cityName,
                          style: textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? colorScheme.textSecondary
                                : colorScheme.textTertiary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    /// Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: isSelected
                              ? colorScheme.textSecondary
                              : colorScheme.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            store.address,
                            style: textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? colorScheme.textSecondary
                                  : colorScheme.textTertiary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    /// Phone
                    if (store.phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: isSelected
                                ? colorScheme.textSecondary
                                : colorScheme.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            store.phone,
                            style: textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? colorScheme.textSecondary
                                  : colorScheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: AppDimensions.paddingMedium),

              /// Selection Indicator - Animated
              AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isSelected ? 1.0 : 0.0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
