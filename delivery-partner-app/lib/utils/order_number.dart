/// Customer facing order number helpers.
///
/// The order number is derived from the order's primary key on the server
/// (order 451 => "ZF-0451"), so any screen holding the numeric id can render
/// the same value without an extra API field.
library;

const String kOrderNumberPrefix = 'ZF-';
const int _kOrderNumberPad = 4;

/// Formats an order id as the customer facing order number.
///
/// Accepts an int or a String id. Values that are already formatted are
/// returned unchanged, and anything unparseable falls back to "#<value>" so a
/// screen never renders an empty order reference.
String formatOrderNumber(dynamic orderId) {
  if (orderId == null) return '';

  final raw = orderId.toString().trim();
  if (raw.isEmpty || raw == 'null') return '';

  if (raw.toUpperCase().startsWith(kOrderNumberPrefix)) return raw;

  final digits = int.tryParse(raw);
  if (digits == null) return '#$raw';

  // Padding is a minimum, not a cap - order 12345 becomes ZF-12345.
  return '$kOrderNumberPrefix${digits.toString().padLeft(_kOrderNumberPad, '0')}';
}
