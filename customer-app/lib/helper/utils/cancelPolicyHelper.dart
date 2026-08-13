import 'package:project/helper/utils/generalImports.dart';

/*
  Why the "Cancel" action is not available for an order item.

  The API (OrderApiController) already collapses the product's cancel policy and
  the order's current stage into a single `cancelable_status` flag:

    cancelable_status = 1  only when  product.cancelable_status == 1
                             AND      order.active_status <= product.till_status
                             AND      order.active_status in (2,3,4,5)

  `till_status` is still sent untouched, so the two blocking reasons can be told
  apart on the app side:
    - a usable till_status that the order has already passed -> window closed
    - anything else (no till_status configured, or still inside the window
      while the flag is 0)                                   -> seller disabled
*/
enum CancelBlockReason {
  /// The seller marked this product as non-cancellable.
  sellerDisabled,

  /// The seller allowed cancellation only up to a certain order status and the
  /// order has already moved past it.
  windowClosed,
}

class ItemCancelNote {
  final CancelBlockReason reason;

  /// Order status code cancellation was allowed till. Empty for [sellerDisabled].
  final String tillStatusCode;

  const ItemCancelNote({required this.reason, this.tillStatusCode = ""});

  IconData get icon => reason == CancelBlockReason.sellerDisabled
      ? Icons.block_rounded
      : Icons.timer_off_rounded;

  Color get accentColor => reason == CancelBlockReason.sellerDisabled
      ? const Color(0xFF6F6B6B)
      : const Color(0xFFF59E0B);

  String message(BuildContext context) {
    if (reason == CancelBlockReason.sellerDisabled) {
      return getTranslatedValue(context, itemNotCancellableBySellerLabel);
    }
    final String tillStatus =
        Constant.getOrderActiveStatusLabelFromCode(tillStatusCode, context);
    return "${getTranslatedValue(context, cancellationWindowClosedLabel)} "
        "(${getTranslatedValue(context, cancellationAllowedTillLabel)} “$tillStatus”)";
  }

  /// Wording for the order-level banner, which speaks about the whole order
  /// instead of a single line item. See [resolveOrderCancelNote].
  String orderMessage(BuildContext context) {
    if (reason == CancelBlockReason.sellerDisabled) {
      return getTranslatedValue(context, orderNotCancellableBySellerLabel);
    }
    final String tillStatus =
        Constant.getOrderActiveStatusLabelFromCode(tillStatusCode, context);
    return "${getTranslatedValue(context, orderCancellationWindowClosedLabel)} "
        "(${getTranslatedValue(context, cancellationAllowedTillLabel)} “$tillStatus”)";
  }
}

String _cleanValue(String? value) {
  final String cleaned = (value ?? "").trim();
  return (cleaned.isEmpty || cleaned == "null") ? "" : cleaned;
}

/// Returns the note to show for an item whose Cancel button is hidden, or null
/// when nothing needs explaining (item still cancellable, already cancelled or
/// returned, or the order is at a stage where cancellation is never offered).
ItemCancelNote? resolveItemCancelNote({
  required String? cancelableStatus,
  required String? tillStatus,
  required String? orderActiveStatus,
  String? itemActiveStatus,
}) {
  // Cancel button is visible ("1"), or the policy is unknown for this row
  // (combo products, for instance, carry no cancel fields) - stay quiet.
  final String flag = _cleanValue(cancelableStatus);
  if (flag.isEmpty || flag == "1") return null;

  // Item is already cancelled / returned, its own status label covers it.
  final String itemStatus = _cleanValue(itemActiveStatus);
  if (itemStatus == "7" || itemStatus == "8") return null;

  final int orderStatus = int.tryParse(_cleanValue(orderActiveStatus)) ?? 0;

  // Cancellation is only ever offered between "Received" and "Out For Delivery"
  // (mirrors $cancelableStatusList in OrderApiController). Outside that range
  // the block is about the order stage, not the seller's setting, so stay quiet
  // instead of showing a misleading reason.
  if (orderStatus < 2 || orderStatus > 5) return null;

  final int tillStatusCode = int.tryParse(_cleanValue(tillStatus)) ?? 0;
  if (tillStatusCode >= 1 && orderStatus > tillStatusCode) {
    return ItemCancelNote(
      reason: CancelBlockReason.windowClosed,
      tillStatusCode: tillStatusCode.toString(),
    );
  }

  return const ItemCancelNote(reason: CancelBlockReason.sellerDisabled);
}

/// Same as [resolveItemCancelNote] for the raw item maps used by the tracking
/// screen and the orders list card.
ItemCancelNote? resolveItemCancelNoteFromMap(
  Map<String, dynamic> item,
  String? orderActiveStatus,
) {
  return resolveItemCancelNote(
    cancelableStatus: item['cancelable_status']?.toString(),
    tillStatus: item['till_status']?.toString(),
    orderActiveStatus: orderActiveStatus,
    itemActiveStatus: item['active_status']?.toString(),
  );
}

/// Picks the blocking reason for one item, given the stage the order is at.
ItemCancelNote _blockedNote(String? tillStatus, int orderStatus) {
  final int tillStatusCode = int.tryParse(_cleanValue(tillStatus)) ?? 0;
  if (tillStatusCode >= 1 && orderStatus > tillStatusCode) {
    return ItemCancelNote(
      reason: CancelBlockReason.windowClosed,
      tillStatusCode: tillStatusCode.toString(),
    );
  }
  return const ItemCancelNote(reason: CancelBlockReason.sellerDisabled);
}

/// Order-level counterpart of [resolveItemCancelNote]: the single note shown
/// once per order (above the customer-support card) rather than once per item.
///
/// Returns null while at least one item is still cancellable - the customer has
/// a Cancel option, so there is nothing to explain - and for orders that are
/// already cancelled. Unlike the per-item note it is NOT limited to the
/// statuses where a Cancel button would have been offered: "why was there never
/// a cancel option?" is just as fair a question on a delivered order.
ItemCancelNote? resolveOrderCancelNote(Order? order) {
  if (order == null) return null;

  final String orderStatusText = _cleanValue(order.activeStatus);
  if (orderStatusText == "7") return null;
  final int orderStatus = int.tryParse(orderStatusText) ?? 0;

  bool anyCancellable = false;
  ItemCancelNote? blocked;

  void inspect(String? cancelableStatus, String? tillStatus, String? itemStatus) {
    // Policy unknown for this row (combo products carry no cancel fields).
    final String flag = _cleanValue(cancelableStatus);
    if (flag.isEmpty) return;

    // Already cancelled / returned - its own status label covers it.
    final String status = _cleanValue(itemStatus);
    if (status == "7" || status == "8") return;

    if (flag == "1") {
      anyCancellable = true;
      return;
    }
    // First blocked item wins, except that a seller-disabled item outranks a
    // closed window: it is the reason that holds no matter when you ask.
    if (blocked == null || blocked!.reason == CancelBlockReason.windowClosed) {
      blocked = _blockedNote(tillStatus, orderStatus);
    }
  }

  for (final item in order.items ?? <OrderItem>[]) {
    inspect(item.cancelableStatus, item.tillStatus, item.activeStatus);
  }

  void inspectRaw(List<dynamic>? items) {
    for (final item in items ?? []) {
      if (item is Map<String, dynamic>) {
        inspect(
          item['cancelable_status']?.toString(),
          item['till_status']?.toString(),
          item['active_status']?.toString(),
        );
      }
    }
  }

  for (final store in order.groupedByStore ?? []) {
    inspectRaw(store.items);
    for (final seller in store.sellers ?? []) {
      inspectRaw(seller.items);
    }
  }

  return anyCancellable ? null : blocked;
}

/// Collects the notes of every blocked item of an order, walking the
/// `grouped_by_store` structure. Used by the ongoing orders list card, which
/// only previews one item but should still flag the whole order.
List<ItemCancelNote> collectOrderCancelNotes(Order order) {
  final List<ItemCancelNote> notes = [];

  void addFrom(List<dynamic>? items) {
    for (final item in items ?? []) {
      if (item is Map<String, dynamic>) {
        final ItemCancelNote? note =
            resolveItemCancelNoteFromMap(item, order.activeStatus);
        if (note != null) notes.add(note);
      }
    }
  }

  for (final store in order.groupedByStore ?? []) {
    addFrom(store.items);
    for (final seller in store.sellers ?? []) {
      addFrom(seller.items);
    }
  }

  return notes;
}

/// Single line shown under an item (or under an order card) explaining why the
/// item cannot be cancelled. Colors default to the note's own accent so it fits
/// both the legacy [ColorsRes] screens and the themed [AppColorScheme] ones.
class ItemCancelNoteRow extends StatelessWidget {
  final ItemCancelNote note;
  final String? overrideText;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double fontSize;
  final EdgeInsetsGeometry? margin;

  const ItemCancelNoteRow({
    super.key,
    required this.note,
    this.overrideText,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
    this.fontSize = 11.5,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = textColor ?? note.accentColor;
    return Container(
      width: double.infinity,
      margin: margin ?? const EdgeInsetsDirectional.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? note.accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor ?? note.accentColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(note.icon, size: fontSize + 2.5, color: accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              overrideText ?? note.message(context),
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: accent,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
