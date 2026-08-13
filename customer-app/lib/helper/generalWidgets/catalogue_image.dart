import 'dart:ui' show ImageFilter;

import 'package:project/helper/utils/generalImports.dart';

/// One rendering rule for every catalogue image — category tiles, special
/// items, subcategory cards, past-order tiles.
///
/// The catalogue mixes photographic styles (styled plates, packshots on white,
/// the odd live animal) and no fit setting fixes that — see
/// PHASE4_ADMIN_CHECKLIST.md, which is where that gets solved. What this does
/// fix is the app's own inconsistency: the same product image was being
/// cropped with `cover` in one grid and letterboxed with `contain` in the next,
/// and each surface invented its own placeholder and error fallback.
///
/// `contain` is the rule. The admin cropper enforces square uploads, so for a
/// well-formed image it is identical to `cover`; for a legacy or mis-cropped
/// one it shows the whole product instead of slicing its edges off.
class CatalogueImage extends StatelessWidget {
  final String? url;

  /// Corner radius of the image itself. The card it sits on owns its own
  /// background, border and shadow — this only clips the picture.
  final double borderRadius;

  /// Optional fixed footprint. Left null, the image fills its parent.
  final double? width;
  final double? height;

  /// Shown when there is no URL or the fetch fails.
  final IconData fallbackIcon;

  /// Defaults to `contain`, which never crops — right for a catalogue tile
  /// where the whole product must be readable. Pass `cover` where the image
  /// fills a panel edge to edge and letterboxing would leave dead space.
  final BoxFit fit;

  /// Fills the panel behind a `contain` image with a blurred, zoomed copy of
  /// itself. `contain` never crops, but in a panel that is not the image's
  /// aspect ratio it leaves bare bands — invisible on a packshot shot on white,
  /// obvious on the food photography, which is mostly dark. This keeps the
  /// product whole and the panel full at the same time.
  final bool fillBackdrop;

  const CatalogueImage({
    super.key,
    required this.url,
    this.borderRadius = 8,
    this.width,
    this.height,
    this.fallbackIcon = Icons.image_not_supported_outlined,
    this.fit = BoxFit.contain,
    this.fillBackdrop = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: hasUrl
            ? Stack(
                fit: StackFit.passthrough,
                children: [
                  if (fillBackdrop)
                    Positioned.fill(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: CachedNetworkImage(
                          imageUrl: url!,
                          fit: BoxFit.cover,
                          // Decoration only — it must never show a shimmer or
                          // an error icon of its own behind the real image.
                          placeholder: (_, __) => const SizedBox.shrink(),
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  if (fillBackdrop)
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  CachedNetworkImage(
                    imageUrl: url!,
                    fit: fit,
                    width: width,
                    height: height,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: const Color(0xFFE0E0E0),
                      highlightColor: const Color(0xFFF5F5F5),
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (_, __, ___) => _fallback(),
                  ),
                ],
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => Center(
        child: Icon(
          fallbackIcon,
          size: 22,
          color: const Color(0xFFBDBDBD),
        ),
      );
}
