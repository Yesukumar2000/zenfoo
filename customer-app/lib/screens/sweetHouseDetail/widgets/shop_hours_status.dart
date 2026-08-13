import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/helper/styles/appColorScheme.dart';

/// Live shop-hours pill for the store header card.
///
/// Answers the three questions a customer has before adding anything to the
/// cart: is this shop open, when does it close, and how long have I got. The
/// last one is a running clock rather than a static "closes at 10:30 PM",
/// because a shop closing in twelve minutes is a different decision from one
/// closing in three hours.
///
/// Renders nothing when the seller has no hours configured — an empty pill
/// would read as "unknown", which is worse than the card simply not claiming
/// anything.
class ShopHoursStatus extends StatefulWidget {
  /// Seller hours as they arrive from the API: "HH:mm:ss" or "HH:mm".
  final String? openingTime;
  final String? closingTime;

  final AppColorScheme colorScheme;

  const ShopHoursStatus({
    super.key,
    required this.openingTime,
    required this.closingTime,
    required this.colorScheme,
  });

  @override
  State<ShopHoursStatus> createState() => _ShopHoursStatusState();
}

class _ShopHoursStatusState extends State<ShopHoursStatus> {
  Timer? _ticker;

  /// Last label painted. The ticker fires every second but most seconds change
  /// nothing on screen ("Open till 10:30 PM" for three hours), so the rebuild
  /// is gated on the text actually differing.
  String? _lastLabel;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final status = _status();
      if (status?.label != _lastLabel && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status();
    if (status == null) return const SizedBox.shrink();
    _lastLabel = status.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        // Tinted rather than the neutral grey of the delivery-time pill beside
        // it: this one carries a state, and the tint is what makes "closing
        // soon" readable at a glance.
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: status.color,
                // The countdown changes width every second otherwise, which
                // makes the pill twitch.
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Null when the seller has no usable hours.
  _ShopStatus? _status() {
    final open = _secondsOfDay(widget.openingTime);
    final close = _secondsOfDay(widget.closingTime);
    if (open == null || close == null) return null;

    final colorScheme = widget.colorScheme;

    // Open == close is how the panel stores "always open".
    if (open == close) {
      return _ShopStatus(
        label: 'Open 24 hours',
        color: colorScheme.success,
        icon: Icons.check_circle_outline_rounded,
      );
    }

    final now = DateTime.now();
    final nowSec = now.hour * 3600 + now.minute * 60 + now.second;

    final isOpen = close > open
        ? (nowSec >= open && nowSec < close)
        // Overnight, e.g. 22:00 -> 06:00.
        : (nowSec >= open || nowSec < close);

    if (isOpen) {
      final untilClose = (close - nowSec) % _daySeconds;
      if (untilClose <= _closingSoonSeconds) {
        return _ShopStatus(
          label: 'Closing in ${_countdown(untilClose)}',
          color: colorScheme.warning,
          icon: Icons.timer_outlined,
        );
      }
      return _ShopStatus(
        label: 'Open till ${_clock(close)}',
        color: colorScheme.success,
        icon: Icons.check_circle_outline_rounded,
      );
    }

    final untilOpen = (open - nowSec) % _daySeconds;
    if (untilOpen <= _openingSoonSeconds) {
      return _ShopStatus(
        label: 'Opens in ${_countdown(untilOpen)}',
        color: colorScheme.info,
        icon: Icons.timer_outlined,
      );
    }
    return _ShopStatus(
      label: 'Closed · Opens ${_clock(open)}',
      color: colorScheme.error,
      icon: Icons.do_not_disturb_on_outlined,
    );
  }
}

const int _daySeconds = 24 * 60 * 60;

/// Within half an hour of closing the pill switches to a countdown. Long
/// enough to still finish an order, short enough that the urgency is real.
const int _closingSoonSeconds = 30 * 60;

/// The reverse, before opening. An hour out, "opens in 47:12" is useful; six
/// hours out only the clock time is.
const int _openingSoonSeconds = 60 * 60;

/// "09:00:00" / "09:00" -> seconds since midnight. Null if unparseable.
int? _secondsOfDay(String? time) {
  if (time == null || time.trim().isEmpty) return null;
  final parts = time.trim().split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  final second = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return hour * 3600 + minute * 60 + second;
}

/// "14:59" under an hour, "2h 40m" beyond it — seconds stop being information
/// once there are hours on the clock.
String _countdown(int seconds) {
  if (seconds >= 3600) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${rest.toString().padLeft(2, '0')}';
}

/// Seconds since midnight -> "10:30 PM".
String _clock(int seconds) {
  var hour = (seconds ~/ 3600) % 24;
  final minute = (seconds % 3600) ~/ 60;
  final period = hour >= 12 ? 'PM' : 'AM';
  if (hour > 12) hour -= 12;
  if (hour == 0) hour = 12;
  return '$hour:${minute.toString().padLeft(2, '0')} $period';
}

class _ShopStatus {
  final String label;
  final Color color;
  final IconData icon;

  const _ShopStatus({
    required this.label,
    required this.color,
    required this.icon,
  });
}
