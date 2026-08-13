import 'package:intl/intl.dart';

/// Indian Standard Time helpers.
///
/// The backend runs on `Asia/Kolkata`, but any Carbon instance the API puts in
/// a response is serialized by Carbon's own `jsonSerialize()`, which converts
/// to Zulu — `2026-07-29T06:09:00.000000Z` for what was 11:39 AM IST. Dart
/// parses that into a UTC `DateTime`, and `DateFormat.format()` prints a
/// `DateTime`'s raw fields without shifting zones, so the screen ends up
/// showing 06:09 AM: IST minus 5:30.
///
/// Endpoints that build their strings by hand (`now()->toDateTimeString()`)
/// send `2026-07-29 11:39:00` with no zone marker instead, which Dart already
/// reads as local time. Both shapes reach the same widgets, so the conversion
/// has to key off whether the parsed value is actually UTC rather than blindly
/// adding an offset — otherwise the hand-built ones get shifted twice.
const Duration _istOffset = Duration(hours: 5, minutes: 30);

/// Shifts a UTC [DateTime] onto the IST wall clock. Values that are not UTC
/// are already IST (the server's local time) and pass through untouched.
///
/// The result is only meant for formatting — its fields read as IST.
DateTime toIst(DateTime dateTime) {
  if (!dateTime.isUtc) {
    return dateTime;
  }
  return dateTime.add(_istOffset);
}

/// Parses an API timestamp and returns it on the IST wall clock.
///
/// Returns null for null, empty or unparseable input so callers can fall back
/// to whatever they showed before rather than crashing on bad data.
DateTime? parseIst(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return null;
  }

  return toIst(parsed);
}

/// Formats an API timestamp in IST using [pattern].
///
/// Falls back to the raw string when the value cannot be parsed, matching the
/// existing `try/catch { return dateStr; }` behaviour across the screens.
String formatIst(String? value, String pattern) {
  final date = parseIst(value);
  if (date == null) {
    return value ?? '';
  }
  return DateFormat(pattern).format(date);
}
