import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/store_location_model.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';

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
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final stores = authProvider.storeLocations;
        final isLoading =
            isStatusLoading(authProvider.getStoreLocationsState.status);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// SUBTITLE
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Text(
                'See the stores you will pick orders from.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.textPrimary,
                ),
              ),
            ),

            /// LOADING
            if (isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )

            /// EMPTY
            else if (stores.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No stores available',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colorScheme.textSecondary,
                    ),
                  ),
                ),
              )

            /// STORE LIST
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: stores.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final store = stores[index];
                    final isSelected = selectedStoreIds.contains(store.id);
                    return _buildStoreCard(store, isSelected, colorScheme);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStoreCard(
    StoreLocation store,
    bool isSelected,
    dynamic colorScheme,
  ) {
    return GestureDetector(
      onTap: () => _toggleStoreSelection(store.id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// Store Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Store Name
                  Text(
                    store.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// City / Area
                  Text(
                    store.cityName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 2),

                  /// Address
                  Text(
                    store.address,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.black45,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            /// Radio Circle Indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? colorScheme.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? colorScheme.primary : Colors.grey.shade400,
                  width: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
