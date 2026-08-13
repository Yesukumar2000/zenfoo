import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/main.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';

class SelectVehicleStep extends StatefulWidget {
  final Function(Future<bool> Function())? onSaveCallback;

  const SelectVehicleStep({
    super.key,
    this.onSaveCallback,
  });

  @override
  State<SelectVehicleStep> createState() => _SelectVehicleStepState();
}

class _SelectVehicleStepState extends State<SelectVehicleStep> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch vehicles when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().getVehicles();
    });

    // Register save callback
    if (widget.onSaveCallback != null) {
      widget.onSaveCallback!(_saveVehicleSelection);
    }
  }

  Future<bool> _saveVehicleSelection() async {
    final authProvider = context.read<AuthProvider>();
    final vehicles = authProvider.vehicles;

    if (vehicles.isEmpty) {
      return false;
    }

    final selectedVehicle = vehicles[selectedIndex];

    // Call select vehicle API
    await authProvider.selectVehicle(vehicleId: selectedVehicle.id);

    // Return success status
    return isStatusSuccess(authProvider.selectVehicleState.status);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          const SizedBox(height: 24),

          /// 🔹 CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Instruction
                  Text(
                    "Choose the vehicle you use for\nDeliveries.",
                    style: text.headlineSmall?.copyWith(
                      color: colorScheme.textPrimary,
                    ),
                  ),

                  SizedBox(height: AppDimensions.getHeight(2)),

                  /// Vehicle List
                  Expanded(
                    child: Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        final isLoading = isStatusLoading(
                            authProvider.getVehiclesState.status);
                        final vehicles = authProvider.vehicles;

                        if (isLoading) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation(colorScheme.primary),
                            ),
                          );
                        }

                        if (vehicles.isEmpty) {
                          return Center(
                            child: Text(
                              'No vehicles available',
                              style: text.bodyMedium?.copyWith(
                                color: colorScheme.textSecondary,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: vehicles.length,
                          itemBuilder: (context, index) {
                            final vehicle = vehicles[index];
                            final isSelected = index == selectedIndex;

                            return GestureDetector(
                              onTap: () {
                                setState(() => selectedIndex = index);
                              },
                              child: Container(
                                height: screenHeight * .15,
                                margin: const EdgeInsets.only(bottom: 14),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.primary
                                          .withValues(alpha: 0.1)
                                      : colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.border,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    /// Vehicle Name
                                    SizedBox(
                                      width: screenWidth * .3,
                                      child: Text(
                                        vehicle.name,
                                        style: text.bodyLarge?.copyWith(
                                          color: colorScheme.textPrimary,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),

                                    /// Vehicle Image
                                    if (vehicle.imageUrl != null &&
                                        vehicle.imageUrl!.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          vehicle.imageUrl!,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                color: colorScheme.border
                                                    .withValues(alpha: 0.3),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.directions_bike,
                                                size: 40,
                                                color:
                                                    colorScheme.textSecondary,
                                              ),
                                            );
                                          },
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Container(
                                              width: 80,
                                              height: 80,
                                              alignment: Alignment.center,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                        colorScheme.primary),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: colorScheme.border
                                              .withValues(alpha: 0.3),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.directions_bike,
                                          size: 40,
                                          color: colorScheme.textSecondary,
                                        ),
                                      ),

                                    const Expanded(
                                        child:  SizedBox(width: 16)),

                                    /// Selection Dot
                                    Container(
                                      height: 24,
                                      width: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? colorScheme.primary
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? colorScheme.primary
                                              : colorScheme.border,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? Icon(
                                              Icons.check,
                                              size: 16,
                                              color:
                                                  colorScheme.buttonPrimaryText,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
