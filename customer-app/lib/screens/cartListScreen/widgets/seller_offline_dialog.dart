import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

/// Shows a dialog when some sellers are offline and their products
/// need to be removed from cart. Returns true if user confirms removal.
Future<bool> showSellerOfflineDialog({
  required BuildContext context,
  required List<OfflineProduct> offlineProducts,
  List<CartItem> offlineCartItems = const [],
  String? message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      final colorScheme =
          dialogContext.watch<app_theme.ThemeProvider>().colorScheme;

      // Use cart items if available, otherwise fall back to offline products
      final int itemCount = offlineCartItems.isNotEmpty
          ? offlineCartItems.length
          : offlineProducts.length;

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
                      Icons.store_outlined,
                      color: Color(0xFFE53E3E),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Seller Offline',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Explanation
              Text(
                message != null && message.isNotEmpty
                    ? message
                    : "The following products are from sellers who are currently offline. They will be removed from your cart if you proceed.",
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
                  itemCount: itemCount,
                  separatorBuilder: (_, __) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (offlineCartItems.isNotEmpty) {
                      // Show rich cart item info
                      final item = offlineCartItems[index];
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
                                    item.sellerName,
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
                    } else {
                      // Fallback: show basic offline product info
                      final product = offlineProducts[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                color: colorScheme.textSecondary,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Product #${product.productId}',
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
                                    product.sellerName,
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
                    }
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
