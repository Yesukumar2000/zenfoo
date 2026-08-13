import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/seller_order_details_model.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';

/// Live timer surfaced on the pickup screen.
///
/// While the food is still being prepared it shows a cooking-time countdown
/// ("Ready in MM:SS") down to the vendor's promised-ready moment. Once that is
/// exceeded (plus the grace window) it switches to the vendor delay bonus,
/// showing how long the vendor is over and the bonus ₹ accrued so far, capped
/// per the admin settings. Hidden for Zenfoo stores and when prep time has not
/// been captured yet.
class VendorWaitChargeTimer extends StatefulWidget {
  final SellerOrderDetails details;

  const VendorWaitChargeTimer({super.key, required this.details});

  @override
  State<VendorWaitChargeTimer> createState() => _VendorWaitChargeTimerState();
}

class _VendorWaitChargeTimerState extends State<VendorWaitChargeTimer> {
  Timer? _ticker;
  Duration _overage = Duration.zero;
  Duration _remaining = Duration.zero;
  Duration _lateness = Duration.zero;

  @override
  void initState() {
    super.initState();
    _recompute();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _recompute());
  }

  @override
  void didUpdateWidget(covariant VendorWaitChargeTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recompute();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _recompute() {
    final d = widget.details;
    final setAtStr = d.firstPrepTimeSetAt;
    final prepMinutes = d.firstPrepTimeMinutes;
    final settings = d.waitChargeSettings;
    if (setAtStr == null ||
        setAtStr.isEmpty ||
        prepMinutes == null ||
        settings == null) {
      return;
    }
    final setAt = DateTime.tryParse(setAtStr);
    if (setAt == null) return;

    final now = DateTime.now().toUtc();
    final promisedReadyAt = setAt.add(Duration(minutes: prepMinutes));
    final arrivedAt = DateTime.tryParse(d.driverArrivedAtSeller ?? '');
    final effectiveStart =
        (arrivedAt != null && arrivedAt.isAfter(promisedReadyAt))
            ? arrivedAt
            : promisedReadyAt;
    final graceUntil =
        effectiveStart.add(Duration(minutes: settings.graceMinutes));

    // Cooking countdown: time left until the vendor's promised-ready moment.
    final remaining = promisedReadyAt.toUtc().difference(now);
    final clampedRemaining = remaining.isNegative ? Duration.zero : remaining;

    // Lateness: time elapsed since promised-ready. Counts up continuously the
    // instant the cooking countdown hits 0:00, so the delay timer never freezes
    // on 00:00 during the grace window.
    final lateness = now.difference(promisedReadyAt.toUtc());
    final clampedLateness = lateness.isNegative ? Duration.zero : lateness;

    // Overage: time elapsed beyond the prep + grace window (drives the bonus).
    final overage = now.difference(graceUntil.toUtc());
    final clampedOverage = overage.isNegative ? Duration.zero : overage;

    if (clampedOverage != _overage ||
        clampedRemaining != _remaining ||
        clampedLateness != _lateness) {
      setState(() {
        _overage = clampedOverage;
        _remaining = clampedRemaining;
        _lateness = clampedLateness;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.details;
    if (d.isZenfooStore ||
        d.firstPrepTimeSetAt == null ||
        d.firstPrepTimeSetAt!.isEmpty ||
        d.firstPrepTimeMinutes == null ||
        d.waitChargeSettings == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    // Once the vendor has packed the order (or handed it over), it is no
    // longer "cooking" — suppress the prep countdown even if the promised-ready
    // moment has not yet elapsed (vendor packed early). The "Packed by vendor"
    // status badge already conveys the real state.
    final vendorPacked = d.status == 'packed_by_seller' ||
        d.status == 'given_to_delivery_partner';

    // Vendor packed on time — nothing to count down and no delay accrued, so
    // there is no timer worth showing.
    if (vendorPacked && _lateness <= Duration.zero) {
      return const SizedBox.shrink();
    }

    // While the food is still being prepared, show the live cooking-time
    // countdown ("Ready in MM:SS"). The moment it hits 0:00 (cooking done),
    // we fall through to the vendor delay-bonus block below.
    if (_remaining > Duration.zero && !vendorPacked) {
      return _buildCookingCard(colorScheme);
    }

    final settings = d.waitChargeSettings!;
    final overageMinutes = _overage.inSeconds / 60.0;
    final rawCharge = overageMinutes * settings.chargePerMinute;
    final charge = rawCharge > settings.cap ? settings.cap : rawCharge;
    final atCap = rawCharge >= settings.cap && settings.cap > 0;

    // Cooking is done — always the amber delay-bonus treatment.
    const accent = Color(0xFFE07A00);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedClock01,
                color: accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vendor delay bonus',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (atCap)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'MAX',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _stat(
                  label: 'Delay',
                  value: _formatDuration(_lateness),
                  colorScheme: colorScheme,
                  accent: accent,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: colorScheme.border,
              ),
              Expanded(
                child: _stat(
                  label: 'Bonus',
                  value: '₹${charge.toStringAsFixed(2)}',
                  colorScheme: colorScheme,
                  accent: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bonus is added to your earnings when you tap Order Picked. Capped at ₹${settings.cap.toStringAsFixed(0)}.',
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// Live cooking-time countdown shown while the vendor is still preparing
  /// the order (within prep time). Displays the time left until the order is
  /// promised ready, ticking down every second.
  Widget _buildCookingCard(AppColorScheme colorScheme) {
    final accent = colorScheme.primary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedClock01,
            color: accent,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cooking time',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vendor is preparing the order',
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Ready in',
                style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDuration(_remaining),
                style: GoogleFonts.inter(
                  color: accent,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat({
    required String label,
    required String value,
    required AppColorScheme colorScheme,
    required Color accent,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              color: accent,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
