import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

/// Circular avatar for the assigned delivery partner.
///
/// Renders the driver's profile photo when available, falling back to the
/// first letter of their name on a coloured circle (and again if the network
/// image fails to load). Used across the order list cards and order details
/// so the avatar behaves the same everywhere.
class DriverAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final app_theme.AppColorScheme colorScheme;

  const DriverAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.colorScheme,
    this.size = 54,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';

    Widget fallback() => Container(
          color: colorScheme.primary,
          alignment: Alignment.center,
          child: Text(
            initial,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: size * 0.37,
              color: Colors.white,
            ),
          ),
        );

    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback(),
              )
            : fallback(),
      ),
    );
  }
}
