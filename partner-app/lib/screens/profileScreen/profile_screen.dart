import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:project/helper/utils/generalImports.dart'
    hide ProductListScreen, CategoryListScreen, CategoryListProvider;
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/models/places_model.dart';
import 'package:project/provider/bank_details_provider.dart';
import 'package:project/provider/category_list_provider.dart';
import 'package:project/provider/place_proveder.dart';
import 'package:project/provider/support_contact_provider.dart';
import 'package:project/screens/categoryScreen/category_list_screen.dart';
import 'package:project/screens/categoryScreen/three_stage_stepper_screen.dart';
import 'package:project/screens/newHome/dialogs/store_relocation_dialog.dart';
import 'package:project/screens/newProductsScreen/product_list.dart'
    show ProductListScreen;
import 'package:project/screens/newProductsScreen/sweet_shop_product_list.dart';
import 'package:project/screens/ordersScreen/admin_chat.dart';
import 'package:project/screens/profileScreen/bank_details_screen.dart';
import 'package:project/screens/profileScreen/ratings.dart';
import 'package:project/screens/resgistration/food/food_registration_provider.dart';
import 'package:project/screens/profileScreen/edit_personal_profile_screen.dart';
import 'package:project/screens/profileScreen/edit_store_profile_screen.dart';
import 'package:project/screens/profileScreen/page_viewer_screen.dart';
import 'package:project/screens/resgistration/food/location_picker.dart';
import 'package:project/screens/stockManagementScreen/product_stock_management_screen.dart';
// import 'package:project/screens/walletScreen/withdrawal_requests_screen.dart';
import 'package:project/repositories/transactionApi.dart';
import 'package:project/screens/transactionScreen/transaction_screen.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
// import 'package:project/screens/profileScreen/appearance_selector_tile.dart'; // Appearance block hidden
// import 'package:project/screens/profileScreen/theme_mode_selector_sheet.dart'; // Appearance block hidden
import 'package:project/screens/profileScreen/profile_screen_shimmers.dart';
import 'package:project/helper/widgets/app_update_banner.dart';
import 'package:project/screens/notificationScreen/notification_screen.dart';
import 'package:open_file/open_file.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? sellerData;
  bool isLoading = true;
  bool isLoggingOut = false;
  bool isDeletingAccount = false;
  double walletBalance = 0.0;

  // Shop timings state
  TimeOfDay? _openingTOD;
  TimeOfDay? _closingTOD;
  bool _isLoadingTimings = false;
  bool _isUpdatingTimings = false;

  // Agreement download state
  bool _isDownloadingAgreement = false;

  @override
  void initState() {
    super.initState();
    _fetchSellerData();
    _fetchWalletBalance();
    _fetchShopTimings();
  }

  // ── Shop timings helpers ────────────────────────────────────────────────────

  TimeOfDay _parseTimeString(String? s) {
    if (s == null || s.isEmpty) return const TimeOfDay(hour: 9, minute: 0);
    final parts = s.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  String _formatTOD(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  String _displayTOD(TimeOfDay? t) {
    if (t == null) return '--:--';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  Future<void> _fetchShopTimings() async {
    setState(() => _isLoadingTimings = true);
    try {
      final response = await sendApiRequest(
        apiName: 'shop-timings',
        params: {},
        isPost: false,
      );
      if (response != null && mounted) {
        final data = json.decode(response) as Map<String, dynamic>;
        if (data['status'] == 1 && data['data'] != null) {
          setState(() {
            _openingTOD =
                _parseTimeString(data['data']['shop_opening_time']?.toString());
            _closingTOD =
                _parseTimeString(data['data']['shop_closing_time']?.toString());
          });
        }
      }
    } catch (_) {
      // silent — timings are non-critical
    } finally {
      if (mounted) setState(() => _isLoadingTimings = false);
    }
  }

  Future<void> _updateShopTimings() async {
    if (_openingTOD == null || _closingTOD == null) return;
    setState(() => _isUpdatingTimings = true);
    try {
      final response = await sendApiRequest(
        apiName: 'update-shop-timings',
        params: {
          'shop_opening_time': _formatTOD(_openingTOD!),
          'shop_closing_time': _formatTOD(_closingTOD!),
        },
        isPost: true,
      );
      if (response != null && mounted) {
        final data = json.decode(response) as Map<String, dynamic>;
        showMessage(
          context,
          data['message']?.toString() ??
              (data['status'] == 1
                  ? 'Shop timings updated'
                  : 'Failed to update'),
          data['status'] == 1 ? MessageType.success : MessageType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, 'Error: $e', MessageType.error);
      }
    } finally {
      if (mounted) setState(() => _isUpdatingTimings = false);
    }
  }

  Future<void> _pickShopTime(bool isOpening) async {
    final initial = isOpening
        ? (_openingTOD ?? const TimeOfDay(hour: 9, minute: 0))
        : (_closingTOD ?? const TimeOfDay(hour: 23, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF9AC444),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF111827),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        if (isOpening) {
          _openingTOD = picked;
        } else {
          _closingTOD = picked;
        }
      });
      await _updateShopTimings();
    }
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final response = await getTransactionsRepository(
        context: context,
        page: 1,
        perPage: 1,
      );
      if (response != null && response.data?.summary != null) {
        setState(() {
          walletBalance = response.data!.summary!.adminDueAmount ?? 0.0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching wallet balance: $e');
    }
  }

  Future<void> _downloadAgreement() async {
    if (_isDownloadingAgreement) return;
    setState(() => _isDownloadingAgreement = true);
    try {
      final dynamic result = await sendApiRequest(
        apiName: 'agreement/download-uploaded',
        params: {},
        isPost: false,
        isRequestedForInvoice: true,
      );
      if (!mounted) return;
      if (result is Uint8List && result.isNotEmpty) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/Zenfoo Seller Agreement.pdf');
        await file.writeAsBytes(result);
        await OpenFile.open(file.path);
      } else {
        showMessage(context, 'No agreement found', MessageType.error);
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, 'Error: $e', MessageType.error);
      }
    } finally {
      if (mounted) setState(() => _isDownloadingAgreement = false);
    }
  }

  Future<void> _fetchSellerData() async {
    try {
      final response = await sendApiRequest(
        apiName: 'registration-data-dev',
        params: {},
        isPost: false,
      );

      if (response != null) {
        final Map<String, dynamic> data = json.decode(response);
        if (data['status'] == 1 && data['data'] != null) {
          final seller = data['data']['seller'];

          final userId = seller['id']?.toString();

          Constant.session.setUserData(data: seller);
          Constant.session.setData(SessionManager.keyStoreId,
              safeParseString((seller['store_id'])), true);
          Constant.session
              .setData(SessionManager.keyUserId, userId ?? '', true);

          // Store FSSAI number from registration data
          if (seller['fssai_number'] != null) {
            Constant.session.setData(
              SessionManager.fssai_number,
              seller['fssai_number'].toString(),
              false,
            );
          }

          // Store store type name from registration data
          if (seller['store_type_name'] != null) {
            Constant.session.setData(
              SessionManager.store_type_name,
              seller['store_type_name'].toString(),
              false,
            );
          }

          // Safe parse booleans
          final managedByAdmin = safeParseBool(seller['managed_by_admin']);
          final isSweetHouse = safeParseBool(seller['is_sweet_house']);
          final isSuperMart = safeParseBool(seller['is_super_mart']);

          // Save store ID, managed_by_admin, is_sweet_house and is_super_mart in session
          Constant.session.setData(
            SessionManager.managedByAdmin,
            managedByAdmin ? "1" : "0",
            false,
          );

          Constant.session.setData(
            SessionManager.isSweetHouse,
            isSweetHouse ? "1" : "0",
            false,
          );

          Constant.session.setData(
            SessionManager.isSuperMart,
            isSuperMart ? "1" : "0",
            false,
          );

          setState(() {
            sellerData = seller;
            isLoading = false;
          });
        }
      }
    } catch (e, stackTrace) {
      print('Error fetching seller data: $e $stackTrace');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showLogoutDialog(BuildContext context) {
    final themeProvider = context.read<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return Consumer<LanguageProvider>(
          builder: (_, languageProvider, child) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        margin: EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: colorScheme.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          color: colorScheme.error,
                          size: 40,
                        ),
                      ),
                      SizedBox(height: 24),
                      // Title
                      Text(
                        getTranslatedValue(context, logoutLabel),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.55,
                          height: 1.02,
                        ),
                      ),
                      SizedBox(height: 12),
                      // Message
                      Text(
                        getTranslatedValue(context, areYouSureLogoutLabel),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.textSecondary,
                          letterSpacing: -0.55,
                          height: 1.02,
                        ),
                      ),
                      SizedBox(height: 32),
                      // Buttons
                      Row(
                        children: [
                          // Cancel Button
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: colorScheme.border,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  getTranslatedValue(context, cancelLabel),
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.textPrimary,
                                    letterSpacing: -0.55,
                                    height: 1.02,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          // Logout Button
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(sheetContext).pop();
                                  _performLogout(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.error,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  getTranslatedValue(context, logoutLabel),
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: -0.55,
                                    height: 1.02,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _performLogout(BuildContext context) async {
    // Set loading state
    setState(() {
      isLoggingOut = true;
    });

    // Delay to show loading state
    await Future.delayed(Duration(milliseconds: 500));

    // Check if widget is still mounted before using context
    if (mounted) {
      // Clear all local storage and navigate to login
      Constant.session.processToLogout(context);
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final themeProvider = context.read<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final reasonController = TextEditingController();
    bool isDeleting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Consumer<LanguageProvider>(
              builder: (_, languageProvider, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: colorScheme.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Handle bar
                          Container(
                            width: 40,
                            height: 4,
                            margin: EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: colorScheme.divider,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          // Icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.delete_forever_rounded,
                              color: const Color(0xFFEF4444),
                              size: 40,
                            ),
                          ),
                          SizedBox(height: 24),
                          // Title
                          Text(
                            getTranslatedValue(context, deleteAccountLabel),
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.textPrimary,
                              letterSpacing: -0.55,
                              height: 1.02,
                            ),
                          ),
                          SizedBox(height: 12),
                          // Message
                          Text(
                            'Please provide a reason for deleting your account',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.textSecondary,
                              letterSpacing: -0.55,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 24),
                          // Reason TextField
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.border,
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: reasonController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Enter reason for account deletion...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: colorScheme.textSecondary,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: colorScheme.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(height: 32),
                          // Buttons
                          Row(
                            children: [
                              // Cancel Button
                              Expanded(
                                child: SizedBox(
                                  height: 54,
                                  child: OutlinedButton(
                                    onPressed: isDeleting
                                        ? null
                                        : () => Navigator.of(sheetContext).pop(),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: colorScheme.border,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      getTranslatedValue(context, cancelLabel),
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.textPrimary,
                                        letterSpacing: -0.55,
                                        height: 1.02,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              // Delete Button
                              Expanded(
                                child: SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: isDeleting
                                        ? null
                                        : () async {
                                            final reason = reasonController.text.trim();
                                            if (reason.isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Please enter a reason'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }

                                            setSheetState(() => isDeleting = true);

                                            try {
                                              final response = await sendApiRequest(
                                                apiName: ApiAndParams.apiSellerDeleteAccount,
                                                params: {'reason': reason},
                                                isPost: true,
                                              );

                                              if (response != null) {
                                                final data = jsonDecode(response);
                                                if (data['status'] == 1) {
                                                  Navigator.of(sheetContext).pop();
                                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(data['message'] ?? 'Account deletion request submitted'),
                                                      backgroundColor: Colors.green,
                                                    ),
                                                  );
                                                  // Logout after successful deletion request
                                                  if (mounted) {
                                                    Constant.session.processToLogout(this.context);
                                                  }
                                                } else {
                                                  setSheetState(() => isDeleting = false);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(data['message'] ?? 'Failed to delete account'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              } else {
                                                setSheetState(() => isDeleting = false);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Failed to delete account'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              setSheetState(() => isDeleting = false);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: ${e.toString()}'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEF4444),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: isDeleting
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            'Delete',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: -0.55,
                                              height: 1.02,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddressBottomSheet(BuildContext context) {
    final storeLocation = sellerData?['store_location'] ?? 'No address set';
    final latLong = sellerData?['lat_long'];
    double? latitude;
    double? longitude;

    if (latLong != null && latLong.toString().isNotEmpty) {
      final latLongSplit = latLong.toString().split(',');
      if (latLongSplit.length == 2) {
        latitude = double.tryParse(latLongSplit[0].trim());
        longitude = double.tryParse(latLongSplit[1].trim());
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return _AddressBottomSheetContent(
          storeLocation: storeLocation,
          latitude: latitude,
          longitude: longitude,
          onUpdate: () {
            Navigator.pop(sheetContext);
            _handleLocationUpdate(context, latitude, longitude);
          },
        );
      },
    );
  }

  void _handleLocationUpdate(
      BuildContext context, double? latitude, double? longitude) async {
    // Show relocation confirmation dialog
    final shouldUpdate = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext dialogContext) {
        return StoreRelocationDialog(
          onConfirm: () => Navigator.pop(dialogContext, true),
          onCancel: () => Navigator.pop(dialogContext, false),
        );
      },
    );

    if (shouldUpdate == true) {
      // Open location picker
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => PlaceSuggestionsProvider()),
              ChangeNotifierProvider(create: (_) => PlaceDetailsProvider()),
            ],
            child: LocationPickerScreen(
              initialPoint: latitude != null && longitude != null
                  ? LatLng(latitude, longitude)
                  : null,
            ),
          ),
        ),
      );

      if (result != null && result is PlaceDetailsModel) {
        // Update store location via API
        await _updateStoreLocation(
          context,
          result.formattedAddress ?? '',
          result.latitude ?? 0.0,
          result.longitude ?? 0.0,
        );
      }
    }
  }

  Future<void> _updateStoreLocation(
    BuildContext context,
    String newLocation,
    double lat,
    double lng,
  ) async {
    try {
      final storeId = Constant.session.getData(SessionManager.keyStoreId);

      final response = await sendApiRequest(
        apiName: 'update-store-location-dev',
        params: {
          'store_id': storeId,
          'store_location': newLocation,
          'latitude': lat.toString(),
          'longitude': lng.toString(),
        },
        isPost: true,
      );

      final Map<String, dynamic> data = json.decode(response);

      if (data['status'] == 1) {
        showMessage(
          context,
          data['message'] ?? 'Store location updated successfully',
          MessageType.success,
        );
        // Refresh seller data
        await _fetchSellerData();
      } else {
        showMessage(
          context,
          data['message'] ?? 'Failed to update store location',
          MessageType.warning,
        );
      }
    } catch (e) {
      showMessage(
        context,
        'Error updating location: ${e.toString()}',
        MessageType.error,
      );
    }
  }

  
  void _showSupportDialog() { 
    final provider = context.read<SupportContactProvider>();
    final contact = provider.supportContact;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF9AC444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.support_agent_rounded,
                  color: Color(0xFF9AC444), size: 24),
            ),
            SizedBox(width: 12),
            Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        content: provider.state == SupportContactState.loading
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF9AC444)),
                ),
              )
            : contact != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Need help? Reach out to our support team through any of the options below.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Phone tile
                      if (contact.phone.isNotEmpty)
                        _buildContactTile(
                          icon: Icons.phone_rounded,
                          label: 'Call Us',
                          value: contact.phone,
                          onTap: () {
                            Navigator.pop(dialogContext);
                            launchUrl(Uri.parse('tel:${contact.phone}'));
                          },
                        ),
                      if (contact.phone.isNotEmpty && contact.email.isNotEmpty)
                        SizedBox(height: 12),
                      // Email tile
                      if (contact.email.isNotEmpty)
                        _buildContactTile(
                          icon: Icons.email_rounded,
                          label: 'Email Us',
                          value: contact.email,
                          onTap: () {
                            Navigator.pop(dialogContext);
                            launchUrl(Uri.parse('mailto:${contact.email}'));
                          },
                        ),
                      SizedBox(height: 12),
                      // Chat tile
                      _buildContactTile(
                        icon: Icons.chat_bubble_rounded,
                        label: 'Chat with Us',
                        value: 'Start a live chat',
                        onTap: () {
                          Navigator.pop(dialogContext);
                          final sellerId = int.tryParse(Constant.session
                                  .getData(SessionManager.keyUserId)) ??
                              0;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SellerAdminChatScreen(sellerId: sellerId),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                : Text(
                    'Unable to load support contacts. Please try again later.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Close',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9AC444),
              ),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildContactTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF9AC444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Color(0xFF9AC444), size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFF9CA3AF), size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          // Header
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return AppHeader(
                label: getTranslatedValue(context, profileLabel),
                title: getTranslatedValue(context, manageYourAccountLabel),
                showBackButton: false,
                actions: [
                 InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: _showSupportDialog,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          getTranslatedValue(context, helpUsLabel),
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            height: 1.02,
                            letterSpacing: -0.55,
                          ),
                        ),
                        SizedBox(width: 7),
                        Icon(Icons.headset_mic_rounded,
                            size: 20, color: colorScheme.iconPrimary),
                      ],
                    ),
                  ),
                )
                ],
              );
            },
          ),
          Expanded(
            child: isLoading
                ? ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Profile info shimmer
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: ProfileInfoShimmer(),
                      ),
                      // Quick actions shimmer
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: const [
                                  ActionTileShimmer(),
                                  SizedBox(height: 12),
                                  ActionTileShimmer(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              flex: 2,
                              child: ActionTileLargeShimmer(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Menu shimmer
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: MenuShimmer(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Profile info card
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                        child: _ProfileInfoCard(
                          sellerData: sellerData,
                          openingTOD: _openingTOD,
                          closingTOD: _closingTOD,
                          isLoadingTimings: _isLoadingTimings,
                          isUpdatingTimings: _isUpdatingTimings,
                          displayTOD: _displayTOD,
                          onPickOpening: () => _pickShopTime(true),
                          onPickClosing: () => _pickShopTime(false),
                        ),
                      ),

                      // Quick actions - Grid layout
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left side - 2 tiles stacked
                            Expanded(
                              flex: 3,
                              child: Consumer<LanguageProvider>(
                                builder: (context, languageProvider, child) {
                                  return Column(
                                    children: [
                                      _ActionTile(
                                        icon: HugeIcons
                                            .strokeRoundedStoreLocation02,
                                        title: getTranslatedValue(
                                            context, addressLabel),
                                        subtitle: getTranslatedValue(
                                            context, manageStoreLocationLabel),
                                        iconColor: const Color(0xFF3B82F6),
                                        iconBgColor: const Color(0xFFEFF6FF),
                                        onTap: () =>
                                            _showAddressBottomSheet(context),
                                      ),
                                      const SizedBox(height: 12),
                                      _ActionTile(
                                        icon: HugeIcons.strokeRoundedCheckList,
                                        title: getTranslatedValue(
                                            context, subscriptionPlansLabel),
                                        subtitle: getTranslatedValue(context,
                                            upgradeYourVisibilityLabel),
                                        iconColor: const Color(0xFF8B5CF6),
                                        iconBgColor: const Color(0xFFF5F3FF),
                                        onTap: () {
                                          showMessage(
                                            context,
                                            'Coming Soon',
                                            MessageType.warning,
                                          );
                                          // Navigator.push(
                                          //   context,
                                          //   MaterialPageRoute(
                                          //     builder: (context) =>
                                          //         const SubscriptionPlansScreen(),
                                          //   ),
                                          // );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Right side - 1 large tile (Withdrawal with balance)
                            Expanded(
                              flex: 2,
                              child: Consumer<LanguageProvider>(
                                builder: (context, languageProvider, child) {
                                  return _ActionTileLarge(
                                    icon: HugeIcons.strokeRoundedWallet01,
                                    label: getTranslatedValue(
                                        context, withdrawalsLabel),
                                    subtitle:
                                        '₹${walletBalance.toStringAsFixed(2)}',
                                    title: getTranslatedValue(
                                        context, availableBalanceLabel),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const TransactionScreen(),
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
                      const SizedBox(height: 16),

                      // App Update Banner
                      const AppUpdateBanner(),

                      // Appearance Selector - hidden
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 12),
                      //   child: GestureDetector(
                      //     onTap: () {
                      //       showThemeSelector(context);
                      //     },
                      //     child: Consumer<app_theme.ThemeProvider>(
                      //       builder: (context, themeProvider, _) {
                      //         return AppearanceSelectorTile(
                      //           themeProvider: themeProvider,
                      //         );
                      //       },
                      //     ),
                      //   ),
                      // ),
                      // const SizedBox(height: 16),

                      // Main menu list
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Consumer<LanguageProvider>(
                          builder: (context, languageProvider, child) {
                            return ReusableCard(
                              child: Column(
                                children: [
                                  _ProfileMenuTile(
                                    icon: HugeIcons
                                        .strokeRoundedDashboardSquare01,
                                    text: getTranslatedValue(
                                        context, categoriesLabel),
                                    onTap: () {
                                      // Check if user has access to organize feature
                                      // If not managed by admin and not a sweet house, open organize screen directly
                                      if (!Constant.session
                                              .getManagedByAdmin() &&
                                          !Constant.session.getIsSweetHouse()) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MultiProvider(
                                                providers: [
                                                  ChangeNotifierProvider(
                                                      create: (context) =>
                                                          CategoryListProvider()),
                                                ],
                                                child:
                                                    const ThreeStageCategoryStepperScreen()),
                                          ),
                                        );
                                      } else {
                                        // Otherwise, open category list screen
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MultiProvider(
                                                providers: [
                                                  ChangeNotifierProvider(
                                                      create: (context) =>
                                                          CategoryListProvider()),
                                                ],
                                                child:
                                                    const CategoryListScreen()),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  if (!Constant.session.getManagedByAdmin())
                                    _buildDivider(),
                                  // Brand Management - only for super mart sellers (is_super_mart == 1)
                                  if (Constant.session.getIsSuperMart())
                                    _ProfileMenuTile(
                                      icon: HugeIcons.strokeRoundedTag01,
                                      text: getTranslatedValue(
                                          context, brandManagementLabel),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ChangeNotifierProvider(
                                              create: (_) =>
                                                  BrandManagementProvider(),
                                              child:
                                                  const BrandManagementScreen(),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  if (Constant.session.getIsSuperMart())
                                    _buildDivider(),
                                  _ProfileMenuTile(
                                    icon: HugeIcons.strokeRoundedGoogleDoc,
                                    text: getTranslatedValue(
                                        context, productsLabel),
                                    onTap: () {
                                      final isSweetHouse =
                                          Constant.session.getIsSweetHouse();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => isSweetHouse
                                              ? SweetShopProductListScreen()
                                              : ProductListScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDivider(),
                                  if (!Constant.session.getManagedByAdmin())
                                    _ProfileMenuTile(
                                      icon: HugeIcons.strokeRoundedLayers01,
                                      text: getTranslatedValue(
                                          context, stockLabel),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProductStockManagementScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  if (!Constant.session.getManagedByAdmin())
                                    _buildDivider(),
                                  if (!Constant.session.getManagedByAdmin())
                                    _ProfileMenuTile(
                                      icon: HugeIcons.strokeRoundedFileUpload,
                                      text: getTranslatedValue(
                                          context, bulkUploadProductsLabel),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ChangeNotifierProvider<
                                                    ProductBulkOperationsProvider>(
                                              create: (context) =>
                                                  ProductBulkOperationsProvider(),
                                              child: ProductBulkUploadScreen(
                                                  from: "upload"),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  // Bulk Update Products - Commented out
                                  // if (!Constant.session.getManagedByAdmin())
                                  //   _buildDivider(),
                                  // if (!Constant.session.getManagedByAdmin())
                                  //   _ProfileMenuTile(
                                  //     icon: HugeIcons.strokeRoundedUpload05,
                                  //     text: getTranslatedValue(
                                  //         context, bulkUpdateProductsLabel),
                                  //     onTap: () {
                                  //       Navigator.push(
                                  //         context,
                                  //         MaterialPageRoute(
                                  //           builder: (context) =>
                                  //               ChangeNotifierProvider<
                                  //                   ProductBulkOperationsProvider>(
                                  //             create: (context) =>
                                  //                 ProductBulkOperationsProvider(),
                                  //             child: ProductBulkUploadScreen(
                                  //                 from: "update"),
                                  //           ),
                                  //         ),
                                  //       );
                                  //     },
                                  //   ),
                                  // if (!Constant.session.getManagedByAdmin() &&
                                  //     !Constant.session.getIsSweetHouse())
                                  _buildDivider(),
                                  _ProfileMenuTile(
                                    icon: HugeIcons.strokeRoundedBank,
                                    text: getTranslatedValue(
                                        context, bankDetailsLabel),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ChangeNotifierProvider(
                                            create: (_) =>
                                                BankDetailsProvider(),
                                            child: BankDetailsScreen(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDivider(),
                                  _ProfileMenuTile(
                                    icon: HugeIcons.strokeRoundedFileDownload,
                                    text: 'Download Agreement',
                                    isLoading: _isDownloadingAgreement,
                                    onTap: _downloadAgreement,
                                  ),
                                  _buildDivider(),
                                  _ProfileMenuTile(
                                    icon: HugeIcons.strokeRoundedNotification02,
                                    text: 'Notifications',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const NotificationScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDivider(),
                                  _ProfileMenuTile(
                                    icon: HugeIcons.strokeRoundedWallet03,
                                    text: 'Ratings',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const RatingsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  // Brand Management - only for super mart sellers (is_super_mart == 1)
                                  if (Constant.session.getIsSuperMart())
                                    _ProfileMenuTile(
                                      icon: HugeIcons.strokeRoundedTag01,
                                      text: getTranslatedValue(
                                          context, brandManagementLabel),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ChangeNotifierProvider(
                                              create: (_) =>
                                                  BrandManagementProvider(),
                                              child:
                                                  const BrandManagementScreen(),
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                  _buildDivider(),
                                  _ProfileMenuTile(
                                    icon: HugeIcons.strokeRoundedFile02,
                                    text: getTranslatedValue(
                                        context, termsOfServiceLabel),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PageViewerScreen(
                                            pageType: 'terms',
                                            title: getTranslatedValue(
                                                context, termsOfServiceLabel),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDivider(),
                                  _ProfileMenuTile(
                                    icon: HugeIcons.strokeRoundedShieldUser,
                                    text: getTranslatedValue(
                                        context, privacyPolicyLabel),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PageViewerScreen(
                                            pageType: 'privacy',
                                            title: getTranslatedValue(
                                                context, privacyPolicyLabel),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildDivider(),
                                  _ProfileMenuTile(
                                    icon: HugeIcons.strokeRoundedLogoutCircle02,
                                    text: getTranslatedValue(
                                        context, logoutLabel),
                                    onTap: isLoggingOut
                                        ? () {}
                                        : () => _showLogoutDialog(context),
                                    isLoading: isLoggingOut,
                                  ),
                                  _buildDivider(),
                                  _ProfileMenuTile(
                                    icon: HugeIcons.strokeRoundedUser02,
                                    text: getTranslatedValue(
                                        context, deleteAccountLabel),
                                    textColor: const Color(0xFFEF4444),
                                    // iconColor: const Color(0xFFEF4444),
                                    // showDivider: false,
                                    onTap: () => _showDeleteAccountDialog(context),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0xFFF3F4F6),
    );
  }
}

// Modern bottom sheet for edit profile
void _showModernEditProfileBottomSheet(BuildContext context) {
  final themeProvider = context.read<app_theme.ThemeProvider>();
  final colorScheme = themeProvider.colorScheme;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      return Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: colorScheme.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title
                    Text(
                      getTranslatedValue(context, editProfileLabel),
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      getTranslatedValue(context, chooseWhatToUpdateLabel),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.textSecondary,
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                    ),
                    SizedBox(height: 28),
                    // Personal Information Option
                    _ModernOptionTile(
                      icon: HugeIcons.strokeRoundedUser,
                      iconColor: colorScheme.primary,
                      iconBgColor: colorScheme.primary.withValues(alpha: 0.1),
                      title:
                          getTranslatedValue(context, personalInformationLabel),
                      subtitle: getTranslatedValue(
                          context, updatePersonalDetailsLabel),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider<
                                FoodRegistrationProvider>(
                              create: (context) =>
                                  FoodRegistrationProvider(context),
                              child: EditPersonalProfileScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 12),
                    // Store Information Option
                    _ModernOptionTile(
                      icon: HugeIcons.strokeRoundedStore04,
                      iconColor: colorScheme.primary,
                      iconBgColor: colorScheme.primary.withValues(alpha: 0.1),
                      title: getTranslatedValue(context, storeInformationLabel),
                      subtitle:
                          getTranslatedValue(context, updateStoreDetailsLabel),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider<
                                FoodRegistrationProvider>(
                              create: (context) =>
                                  FoodRegistrationProvider(context),
                              child: EditStoreProfileScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// Modern option tile widget for bottom sheet
class _ModernOptionTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModernOptionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.border,
            width: 1.5,
          ),
          boxShadow: colorScheme.cardShadow,
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: HugeIcon(
                  icon: icon,
                  color: iconColor,
                  size: 26,
                ),
              ),
            ),
            SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.textPrimary,
                      letterSpacing: -0.55,
                      height: 1.02,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textSecondary,
                      letterSpacing: -0.55,
                      height: 1.02,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow icon
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final Map<String, dynamic>? sellerData;
  final TimeOfDay? openingTOD;
  final TimeOfDay? closingTOD;
  final bool isLoadingTimings;
  final bool isUpdatingTimings;
  final String Function(TimeOfDay?) displayTOD;
  final VoidCallback onPickOpening;
  final VoidCallback onPickClosing;

  const _ProfileInfoCard({
    this.sellerData,
    required this.openingTOD,
    required this.closingTOD,
    required this.isLoadingTimings,
    required this.isUpdatingTimings,
    required this.displayTOD,
    required this.onPickOpening,
    required this.onPickClosing,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    final storeName = sellerData?['store_name'] ?? 'Store Name';
    final phone =
        sellerData?['mobile'] ?? sellerData?['phone'] ?? '+91 XXXXXXXXXX';
    final rating = sellerData?['rating']?.toString() ?? '5.0';
    final storeTypeName = sellerData?['store_type_name'] ?? '';
    final storeLogo = sellerData?['logo_url'] ?? '';
    final email = sellerData?['email'] ?? '';

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.border,
              width: 1,
            ),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Column(
            children: [
              // Main row with logo and info
              Row(
                children: [
                  // Store logo - more compact
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.border,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: storeLogo.isNotEmpty
                          ? setNetworkImg(
                              image: storeLogo,
                              width: 64,
                              height: 64,
                              boxFit: BoxFit.cover,
                            )
                          : Container(
                              color: colorScheme.surfaceVariant,
                              child: Icon(
                                Icons.store_rounded,
                                size: 32,
                                color: ColorsRes.appColor,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Store info - compact
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storeName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: colorScheme.textPrimary,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (storeTypeName.isNotEmpty) ...[
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: ColorsRes.appColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    storeTypeName,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Color(0xFFFBBF24), size: 14),
                                  const SizedBox(width: 3),
                                  Text(
                                    rating,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: const Color(0xFF92400E),
                                      letterSpacing: -0.2,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Edit button - compact
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (Constant.session.isSeller()) {
                          _showModernEditProfileBottomSheet(context);
                        } else {
                          Navigator.pushNamed(
                              context, editDeliveryBoyProfileScreen,
                              arguments: "");
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 14),
                        decoration: BoxDecoration(
                          color: ColorsRes.appColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_outlined,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 5),
                            Text(
                              getTranslatedValue(context, editLabel),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 13,
                                letterSpacing: -0.2,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.divider,
                ),
              ),
              // Contact info - horizontal compact layout
              Row(
                children: [
                  // Phone
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.phone_rounded,
                      color: const Color(0xFF3B82F6),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getTranslatedValue(context, phoneLabel),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.textTertiary,
                            letterSpacing: -0.2,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          phone,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: colorScheme.textPrimary,
                            letterSpacing: -0.2,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 36,
                      color: colorScheme.divider,
                    ),
                    const SizedBox(width: 12),
                    // Email
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.email_rounded,
                        color: const Color(0xFF10B981),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getTranslatedValue(context, emailLabel),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.textTertiary,
                              letterSpacing: -0.2,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: colorScheme.textPrimary,
                              letterSpacing: -0.2,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              // ── Shop Timings ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Divider(height: 1, thickness: 1, color: colorScheme.divider),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  // Opening time chip
                  Expanded(
                    child: GestureDetector(
                      onTap: isUpdatingTimings ? null : onPickOpening,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.wb_sunny_rounded,
                                color: Color(0xFFF59E0B), size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Opening',
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF92400E))),
                                  isLoadingTimings
                                      ? Container(
                                          height: 12,
                                          width: 52,
                                          margin: const EdgeInsets.only(top: 2),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFFDE68A),
                                              borderRadius:
                                                  BorderRadius.circular(4)))
                                      : Text(
                                          displayTOD(openingTOD),
                                          style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF92400E),
                                              letterSpacing: -0.2)),
                                ],
                              ),
                            ),
                            if (!isLoadingTimings)
                              const Icon(Icons.edit_rounded,
                                  size: 12, color: Color(0xFFF59E0B)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 16, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 10),
                  // Closing time chip
                  Expanded(
                    child: GestureDetector(
                      onTap: isUpdatingTimings ? null : onPickClosing,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFC7D2FE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.nights_stay_rounded,
                                color: Color(0xFF6366F1), size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Closing',
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF4338CA))),
                                  isLoadingTimings
                                      ? Container(
                                          height: 12,
                                          width: 52,
                                          margin: const EdgeInsets.only(top: 2),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFC7D2FE),
                                              borderRadius:
                                                  BorderRadius.circular(4)))
                                      : Text(
                                          displayTOD(closingTOD),
                                          style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF4338CA),
                                              letterSpacing: -0.2)),
                                ],
                              ),
                            ),
                            if (!isLoadingTimings)
                              const Icon(Icons.edit_rounded,
                                  size: 12, color: Color(0xFF6366F1)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (isUpdatingTimings)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: LinearProgressIndicator(
                    color: const Color(0xFF9AC444),
                    backgroundColor:
                        const Color(0xFF9AC444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 3,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 80,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.border,
              width: 1,
            ),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: icon,
                    color: iconColor,
                    size: 22,
                    strokeWidth: 2,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.3,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: colorScheme.textSecondary,
                        letterSpacing: -0.2,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colorScheme.iconSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTileLarge extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final String? label;
  final VoidCallback onTap;

  const _ActionTileLarge({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 172,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            border: Border.all(
              color: colorScheme.border,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: icon,
                    color: const Color(0xFF3B82F6),
                    size: 28,
                    strokeWidth: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (label != null) ...[
                Text(
                  label!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: colorScheme.textSecondary,
                    letterSpacing: -0.2,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: label != null ? 13 : 15,
                  color: colorScheme.textPrimary,
                  letterSpacing: -0.3,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontWeight: label != null ? FontWeight.w800 : FontWeight.w500,
                  fontSize: label != null ? 20 : 12,
                  color: label != null
                      ? colorScheme.textPrimary
                      : colorScheme.textSecondary,
                  letterSpacing: -0.3,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String text;
  final VoidCallback onTap;
  final Color? textColor;
  final bool isLoading;

  const _ProfileMenuTile({
    required this.icon,
    required this.text,
    required this.onTap,
    this.textColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: HugeIcon(
                  icon: icon,
                  color: colorScheme.iconSecondary,
                  size: 20,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: textColor ?? colorScheme.textPrimary,
                    fontSize: 15,
                    letterSpacing: -0.3,
                    height: 1.15,
                  ),
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(ColorsRes.appColor),
                    strokeWidth: 2.5,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: colorScheme.iconSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card with default padding and rounded corners for reuse
class ReusableCard extends StatelessWidget {
  final Widget child;
  const ReusableCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
        boxShadow: colorScheme.cardShadow,
      ),
      child: child,
    );
  }
}

// Animated Address Bottom Sheet Widget
class _AddressBottomSheetContent extends StatefulWidget {
  final String storeLocation;
  final double? latitude;
  final double? longitude;
  final VoidCallback onUpdate;

  const _AddressBottomSheetContent({
    required this.storeLocation,
    required this.latitude,
    required this.longitude,
    required this.onUpdate,
  });

  @override
  State<_AddressBottomSheetContent> createState() =>
      _AddressBottomSheetContentState();
}

class _AddressBottomSheetContentState extends State<_AddressBottomSheetContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: colorScheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Animated Icon
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Color(0xFFDCE4FF).withValues(
                              alpha: _pulseAnimation.value,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withValues(
                                  alpha: 0.2 * _pulseAnimation.value,
                                ),
                                blurRadius: 20 * _pulseAnimation.value,
                                spreadRadius: 5 * _pulseAnimation.value,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFF3B82F6),
                            size: 36,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    getTranslatedValue(context, storeAddressLabel),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.textPrimary,
                      letterSpacing: -0.5,
                      height: 1.02,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Current Address
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.border,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getTranslatedValue(context, currentLocationLabel),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.textSecondary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 18,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.storeLocation,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.textPrimary,
                                  letterSpacing: -0.2,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: widget.onUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9AC444),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit_location_outlined,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            getTranslatedValue(context, updateLocationLabel),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
