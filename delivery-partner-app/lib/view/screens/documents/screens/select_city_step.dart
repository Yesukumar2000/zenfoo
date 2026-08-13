import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/view/custom_widgets/customTextField.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final isLoading =
                isStatusLoading(authProvider.getNearbyCitiesState.status);
            final cities = authProvider.cities;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 TITLE
                Text(
                  "Pick the city where you will work.",
                  style: textTheme.titleLarge,
                ),

                const SizedBox(height: AppDimensions.paddingMedium),

                /// 🔹 SEARCH FIELD
                CustomTextFormField(
                  borderRadius: 40,
                  controller: _searchController,
                  hintText: "Search location",
                  title: '',
                  prefixIcon: const Icon(Icons.search),
                ),

                const SizedBox(height: AppDimensions.paddingLarge),

                /// 🔹 NEARBY LABEL
                Text(
                  "Nearby location",
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.textSecondary),
                ),

                const SizedBox(height: AppDimensions.paddingSmall),

                /// 🔹 LOADING STATE
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppDimensions.paddingLarge),
                      child: CircularProgressIndicator(),
                    ),
                  ),

                /// 🔹 EMPTY STATE
                if (!isLoading && cities.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                      child: Text(
                        'No cities found nearby',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.textSecondary,
                        ),
                      ),
                    ),
                  ),

                /// 🔹 CITY LIST
                if (!isLoading && cities.isNotEmpty)
                  ...List.generate(cities.length, (index) {
                    final city = cities[index];
                    final isSelected = index == selectedIndex;

                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDimensions.paddingSmall,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() => selectedIndex = index);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary.withValues(alpha: 0.1)
                                  : colorScheme.surface,
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.border,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                /// Location Icon
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    size: 20,
                                    color: isSelected
                                        ? Colors.white
                                        : colorScheme.iconSecondary,
                                  ),
                                ),

                                const SizedBox(
                                    width: AppDimensions.paddingMedium),

                                /// City Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        city.name,
                                        style: textTheme.bodyLarge?.copyWith(
                                          color: isSelected
                                              ? colorScheme.textPrimary
                                              : colorScheme.textPrimary,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      if (city.distanceKm != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(
                                            '${city.distanceKm!.toStringAsFixed(1)} km away',
                                            style:
                                                textTheme.bodySmall?.copyWith(
                                              color: isSelected
                                                  ? colorScheme.textSecondary
                                                  : colorScheme.textTertiary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                /// Check Icon
                                AnimatedScale(
                                  duration: const Duration(milliseconds: 200),
                                  scale: isSelected ? 1.0 : 0.0,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}
