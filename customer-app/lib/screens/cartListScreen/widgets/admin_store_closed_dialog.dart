import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/utils/storeHoursService.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

/// Shows a dialog when the store is closed and the cart contains
/// admin_managed_store items. Returns true if the user confirms removal.
Future<bool> showAdminStoreClosedDialog({
  required BuildContext context,
  required List<CartItem> adminManagedItems,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      final colorScheme =
          dialogContext.watch<app_theme.ThemeProvider>().colorScheme;
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          constraints: BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.storefront_outlined,
                      color: Color(0xFFE53E3E),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getTranslatedValue(context, 'store_closed'),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "${getTranslatedValue(context, 'will_open_at')} ${StoreHoursService().formattedOpeningTime}",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Explanation
              Text(
                "The following items are from our store and cannot be ordered while the store is closed. They will be removed from your cart.",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.textSecondary,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 16),

              // Items list
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: adminManagedItems.length,
                  separatorBuilder: (_, __) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = adminManagedItems[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: setNetworkImg(
                                image: item.imageUrl,
                                width: 48,
                                height: 48,
                                boxFit: BoxFit.contain,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "${item.measurement} x ${item.qty}",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: colorScheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side:
                              BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "OK, Proceed",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}
