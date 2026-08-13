import 'package:project/helper/generalWidgets/catalogue_image.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/reorderableOrder.dart';
import 'package:project/provider/reorderProvider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

/// Products the customer has bought before, surfaced on the home feed.
///
/// Repeat purchase is most of a grocery order, so the fastest path back to a
/// previous basket belongs above the fold rather than behind the Reorder tab.
/// This is a shortcut into that tab, not a second reorder implementation —
/// tapping a tile opens Reorder, where the real add-to-cart flow lives.
class BuyItAgainRail extends StatelessWidget {
  /// Opens the Reorder tab. Passed in so this widget stays unaware of how the
  /// shell switches tabs.
  final VoidCallback onOpenReorder;

  const BuyItAgainRail({super.key, required this.onOpenReorder});

  /// Most recently ordered items first, one tile per product, in-stock only.
  ///
  /// Orders arrive newest-first, and the same staples repeat across them, so
  /// without the de-dupe the rail would be four tiles of milk.
  /// How many separate orders each product appears in.
  ///
  /// This is the one fact a buy-it-again card has that an ordinary product
  /// card does not, and it is the strongest repeat signal on the tile — "you
  /// have bought this four times" outweighs any amount of photography. Counted
  /// per order, not per line, so two bottles in one basket is still one buy.
  static Map<int, int> _countsFrom(List<ReorderableOrder> orders) {
    final counts = <int, int>{};
    for (final order in orders) {
      final seenInOrder = <int>{};
      for (final item in order.items ?? const <ReorderableItem>[]) {
        final id = item.productId;
        if (id == null || !seenInOrder.add(id)) continue;
        counts[id] = (counts[id] ?? 0) + 1;
      }
    }
    return counts;
  }

  static List<ReorderableItem> _itemsFrom(List<ReorderableOrder> orders) {
    final seen = <int>{};
    final items = <ReorderableItem>[];
    for (final order in orders) {
      for (final item in order.items ?? const <ReorderableItem>[]) {
        if (!item.isAvailable) continue;
        final id = item.productId;
        if (id == null || !seen.add(id)) continue;
        items.add(item);
        if (items.length == 12) return items;
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    // Same ETA the delivery header shows: one address, one basket, one time.
    final eta = _etaRange(
      context.watch<HomeScreenProvider>().travelTimeMinutes,
    );

    return Consumer<ReorderProvider>(
      builder: (context, provider, _) {
        final items = _itemsFrom(provider.orders);
        if (items.isEmpty) return const SizedBox.shrink();
        final counts = _countsFrom(provider.orders);

        // The trailing gap belongs to this widget, so an empty rail collapses
        // to nothing rather than leaving a hole in the feed.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // The delivery window states itself once here rather than on
                  // every card: it is one address and one basket, so the
                  // figure was identical across the whole rail.
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'Buy it again',
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            height: 1.2,
                          ),
                        ),
                        if (eta.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              eta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: colorScheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.1,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onOpenReorder();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              getTranslatedValue(context, 'view_all'),
                              style: GoogleFonts.inter(
                                color: colorScheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Same boxed chevron the Combos section uses, so
                            // the two "View all" affordances on one screen
                            // don't read as two different controls.
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: _tileExtent,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const ClampingScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _BuyItAgainTile(
                  item: items[index],
                  colorScheme: colorScheme,
                  eta: eta,
                  boughtCount: counts[items[index].productId] ?? 1,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onOpenReorder();
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

/// A recall card, not a discovery card.
///
/// In a browse grid the photo does the persuading, so it earns the space. Here
/// the customer has already bought the thing — recognition is instant and the
/// picture only has to confirm it. So the image gives up a third of its height
/// to the two things that actually drive a repeat: how often they have bought
/// it, and what it costs now versus then.
///
/// Every block is a fixed height, so the rail's row height is the content
/// rather than a guess, and a one-line name still lines up with a two-line one.
const double _tileWidth = 150;
const double _tileImage = 96;
const double _tilePad = 10;
const double _tileNameBlock = 32;
const double _tileMetaBlock = 14;
const double _tilePriceBlock = 20;

/// The action is full width and 44 high — the platform minimum for a tap
/// target, which the old 30dp pill sat under.
const double _tileActionBlock = 44;

/// Slack for sub-pixel rounding across the stacked text blocks. Summing the
/// nominal heights alone came out a couple of pixels short of what renders.
const double _tileSlack = 4;

const double _tileExtent = _tileImage +
    _tilePad +
    _tileNameBlock +
    2 +
    _tileMetaBlock +
    4 +
    _tilePriceBlock +
    8 +
    _tileActionBlock +
    _tilePad +
    _tileSlack;

/// Width of the delivery window, in minutes.
///
/// The ETA endpoint returns a single `travel_time_minutes`, not a window, so
/// the upper bound is derived: a delivery estimate reads as a promise, and a
/// range sets a realistic expectation where one number invites a stopwatch.
/// If the backend ever returns a real window, use it directly and delete this.
const int _etaWindowMinutes = 6;

/// "10 - 16 mins" from the single figure the ETA API provides. Empty when
/// there is no estimate — the address may not be serviceable yet.
String _etaRange(int? minutes) {
  if (minutes == null || minutes <= 0) return '';
  return '$minutes - ${minutes + _etaWindowMinutes} mins';
}

class _BuyItAgainTile extends StatelessWidget {
  final ReorderableItem item;
  final dynamic colorScheme;
  final VoidCallback onTap;

  /// Delivery estimate for the current address, already compacted. The reorder
  /// API carries no per-product time, so every card in the rail shows the same
  /// figure — which is accurate, since it is the same basket and address.
  final String eta;

  /// Orders this product appears in. 1 means "bought once" — no chip.
  final int boughtCount;

  const _BuyItAgainTile({
    required this.item,
    required this.colorScheme,
    required this.onTap,
    required this.eta,
    required this.boughtCount,
  });

  /// "500 g", "1 kg", "2 pcs" — the pack the customer actually bought.
  String get _pack {
    final m = item.measurement;
    final u = item.unit?.trim();
    if (m == null || m <= 0 || u == null || u.isEmpty) return '';
    return '$m $u';
  }

  /// Percent off, but only where the price genuinely dropped since the order.
  /// priceChangePercentage is signed, and a rise is not a saving.
  int? get _dropPercent {
    final raw = item.priceChangePercentage;
    if (raw == null || raw.trim().isEmpty) return null;
    final v = double.tryParse(raw.replaceAll('%', '').trim());
    if (v == null || v >= 0) return null;
    final pct = v.abs().round();
    return pct > 0 ? pct : null;
  }

  @override
  Widget build(BuildContext context) {
    final price = item.currentPrice;
    final was = item.orderedPrice;
    final drop = _dropPercent;
    final showWas = drop != null && was != null && was.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _tileWidth,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _tileWidth,
              height: _tileImage,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CatalogueImage(
                      url: item.productImage,
                      fit: BoxFit.contain,
                      borderRadius: 0,
                      // The catalogue mixes square packshots with landscape
                      // food photography, so `contain` on its own left bare
                      // bands across half these cards. The blurred backdrop
                      // fills the panel without cropping the product.
                      fillBackdrop: true,
                    ),
                  ),
                  // The repeat count, not the discount, sits on the image:
                  // it is the one thing this card knows that a normal product
                  // card does not. The discount moved down beside the price,
                  // where the comparison it belongs to actually happens.
                  if (boughtCount > 1)
                    PositionedDirectional(
                      top: 8,
                      start: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Bought $boughtCount×',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(_tilePad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: _tileNameBlock,
                    child: Text(
                      item.productName ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Pack size, then the saving where there is one. The ETA
                  // used to live here, but it is the same figure on every card
                  // in the rail — one address, one basket — so twelve copies
                  // of it earned nothing. It belongs in the section heading.
                  SizedBox(
                    height: _tileMetaBlock,
                    child: Row(
                      children: [
                        if (_pack.isNotEmpty)
                          Flexible(
                            child: Text(
                              _pack,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: colorScheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.1,
                                height: 1.2,
                              ),
                            ),
                          ),
                        if (_pack.isNotEmpty && drop != null)
                          Text(
                            '  ·  ',
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 11,
                              height: 1.2,
                            ),
                          ),
                        if (drop != null)
                          Text(
                            '$drop% off',
                            maxLines: 1,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF1E8E3E),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                              height: 1.2,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Price, old price and saving on one baseline, so the
                  // comparison reads left to right in a single glance.
                  SizedBox(
                    height: _tilePriceBlock,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            (price != null && price.isNotEmpty)
                                ? price.currency
                                : '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: colorScheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (showWas) ...[
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              was.currency,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: colorScheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Full width and 44 high — the platform minimum tap target,
                  // which the old pill missed by 14dp on the card's primary
                  // action. Labelled for what it does: this opens Reorder,
                  // where variants and stock checks live, so calling it "ADD"
                  // promised a +1 that never happened.
                  SizedBox(
                    height: _tileActionBlock,
                    width: double.infinity,
                    child: Material(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onTap,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: 15,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Reorder',
                              style: GoogleFonts.inter(
                                color: colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
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
}
