import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class BrandCampaignBottomSheet extends StatelessWidget {
  const BrandCampaignBottomSheet({Key? key}) : super(key: key);

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.black;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.tryParse('0x$hex') ?? 0xFF000000);
  }

  static Future<void> show(BuildContext context) async {
    // Always fetch fresh campaign data
    final provider = context.read<BrandCampaignProvider>();
    if (provider.state != BrandCampaignState.loading) {
      await provider.fetchCampaign(context);
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const BrandCampaignBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Consumer<BrandCampaignProvider>(
      builder: (context, provider, _) {
        final campaign = provider.campaign;
        final String? imageUrl = campaign?.primaryImageUrl;
        final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
        final btnColor = _parseColor(campaign?.themeColor);

        return SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Primary Image or Placeholder
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: hasImage
                        ? SizedBox(
                            width: double.infinity,
                            height: 300,
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: colorScheme.surfaceVariant,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: colorScheme.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => imgErrorWidget(iconSize: 40),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            height: 300,
                            color: colorScheme.surfaceVariant,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.campaign_outlined,
                                  color: colorScheme.iconDisabled,
                                  size: 64,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  getTranslatedValue(
                                      context, 'campaign'),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: colorScheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Explore Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: gradientBtnWidget(
                      context,
                      16,
                      color1: btnColor,
                      color2: btnColor,
                      callback: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CampaignDetailsScreen(),
                          ),
                        );
                      },
                      otherWidgets: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            getTranslatedValue(context, 'explore'),
                            style: GoogleFonts.inter(
                              color: ThemeData.estimateBrightnessForColor(btnColor) == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.55,
                              height: 1.02,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Bottom padding for safe area
                SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
