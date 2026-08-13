import 'package:project/helper/styles/product_card_metrics.dart';
import 'package:project/screens/categoryProducts/widgets/product_card.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/screens/categoryProducts/widgets/banners_home.dart';
import 'package:project/screens/mainHomeScreen/campaign_products_screen.dart';
import 'package:project/screens/mainHomeScreen/campaign_video_player_screen.dart';

class CampaignDetailsScreen extends StatefulWidget {
  const CampaignDetailsScreen({Key? key}) : super(key: key);

  @override
  State<CampaignDetailsScreen> createState() => _CampaignDetailsScreenState();
}

class _CampaignDetailsScreenState extends State<CampaignDetailsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    // Reset status bar color back to transparent when leaving this screen
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    _scrollController.dispose();
    super.dispose();
  }

  Color? _parseColor(String? hex) {
    try {
      if (hex == null || hex.isEmpty) return null;
      String hexColor = hex.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Consumer<BrandCampaignProvider>(
        builder: (context, provider, _) {
          final campaign = provider.campaign;

          if (campaign == null) {
            return Center(
              child: Text(getTranslatedValue(context, 'campaign_not_found')),
            );
          }

          final latestProducts = provider.latestProducts;
          final otherProducts = provider.otherProducts;
          final themeColor = _parseColor(campaign.themeColor) ?? Colors.white;

          final bool isLightTheme =
              ThemeData.estimateBrightnessForColor(themeColor) ==
                  Brightness.light;
          final Brightness statusBarBrightness =
              isLightTheme ? Brightness.dark : Brightness.light;

          // Carousel = video + gif banners only
          final allBanners = campaign.banners ?? [];
          final carouselUrls = allBanners
              .where((b) {
                if (b.url == null || b.url!.isEmpty) return false;
                final lower = b.url!.toLowerCase();
                return b.type == 'video' || lower.endsWith('.gif');
              })
              .map((b) => b.url!)
              .toList();
          // Static image banners (non-video, non-gif)
          final staticImageBanners = allBanners
              .where((b) {
                if (b.url == null || b.url!.isEmpty) return false;
                final lower = b.url!.toLowerCase();
                return b.type != 'video' && !lower.endsWith('.gif');
              })
              .toList();

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: themeColor,
              statusBarIconBrightness: statusBarBrightness,
              statusBarBrightness:
                  isLightTheme ? Brightness.light : Brightness.dark,
            ),
            child: Scaffold(
            backgroundColor: colorScheme.surface,
            body: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== 1. SECONDARY IMAGE (Hero Section) =====
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  if (campaign.secondaryImageUrl != null &&
                      campaign.secondaryImageUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: campaign.secondaryImageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.5,
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => const SizedBox(),
                    ),

                  // ===== 2. CAROUSEL (video + gif only) =====
                  if (carouselUrls.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: BannerCarousel(
                        mediaUrls: carouselUrls,
                        interval: const Duration(seconds: 8),
                        autoPlayVideos: true,
                        onVideoTap: (url) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CampaignVideoPlayerScreen(videoUrl: url),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // ===== 3. LATEST PRODUCTS (2-column grid) =====
                  if (latestProducts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: productGridGutter,
                          crossAxisSpacing: productGridGutter,
                          mainAxisExtent: productCardExtent,
                        ),
                        itemCount: latestProducts.length,
                        itemBuilder: (context, index) {
                          return MiniProductCardContainer(
                            product: latestProducts[index],
                          );
                        },
                      ),
                    ),
                  ],

                  // ===== 4. FIRST HALF BANNERS (side by side) =====
                  if (staticImageBanners.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          for (int i = 0;
                              i < (staticImageBanners.length / 2).ceil();
                              i++) ...[
                            if (i > 0) const SizedBox(width: 12),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: staticImageBanners[i].url!,
                                  height: 160,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(
                                      height: 160,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const SizedBox(),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // ===== 5. OTHER PRODUCTS (3-column grid) =====
                  if (otherProducts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: campaign.id == null
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CampaignProductsScreen(
                                        campaign: campaign,
                                      ),
                                    ),
                                  );
                                },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 6,
                            ),
                            foregroundColor: colorScheme.primary,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'View all',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: productGridGutter,
                          crossAxisSpacing: productGridGutter,
                          mainAxisExtent: productCardExtent,
                        ),
                        itemCount: otherProducts.length,
                        itemBuilder: (context, index) {
                          return MiniProductCardContainer(
                            product: otherProducts[index],
                          );
                        },
                      ),
                    ),
                  ],

                  // ===== 6. SECOND HALF BANNERS (side by side, at bottom) =====
                  if (staticImageBanners.length > 1) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          for (int i = (staticImageBanners.length / 2).ceil();
                              i < staticImageBanners.length;
                              i++) ...[
                            if (i > (staticImageBanners.length / 2).ceil())
                              const SizedBox(width: 12),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: staticImageBanners[i].url!,
                                  height: 160,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(
                                      height: 160,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const SizedBox(),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          );
        },
      ),
    );
  }
}
