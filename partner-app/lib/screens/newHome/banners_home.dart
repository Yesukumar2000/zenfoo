import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/banner.dart';
import 'package:project/repositories/bannerApi.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class BannerCarousel extends StatefulWidget {
  final Duration interval;
  final int section; // 1 for first half, 2 for second half

  const BannerCarousel({
    Key? key,
    this.interval = const Duration(seconds: 4),
    this.section = 1,
  }) : super(key: key);

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel>
    with SingleTickerProviderStateMixin {
  late PageController _controller;
  int _active = 0;
  late AnimationController _aniController;
  Timer? _timer;

  List<BannerItem> _banners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _aniController = AnimationController(
      vsync: this,
      duration: widget.interval,
    );
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    setState(() {
      _isLoading = true;
    });

    final response = await getSellerBanners(context: context);

    if (response != null &&
        response.data != null &&
        response.data!.banners != null &&
        response.data!.banners!.isNotEmpty) {
      final allBanners = response.data!.banners!;

      // Split banners based on section
      List<BannerItem> sectionBanners;
      if (allBanners.length == 1) {
        // If only one banner, show it in both sections
        sectionBanners = allBanners;
      } else {
        final midpoint = (allBanners.length / 2).ceil();
        if (widget.section == 1) {
          // First half
          sectionBanners = allBanners.sublist(0, midpoint);
        } else {
          // Second half
          sectionBanners = allBanners.sublist(midpoint);
        }
      }

      setState(() {
        _banners = sectionBanners;
        _isLoading = false;
      });

      if (_banners.isNotEmpty) {
        _aniController.forward();
        _startTimer();
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    if (_banners.isEmpty) return;
    _aniController.forward(from: 0);
    _timer?.cancel();
    _timer = Timer(widget.interval, _goNext);
  }

  void _goNext() {
    if (_banners.isEmpty) return;
    int next = (_active + 1) % _banners.length;
    _controller.animateToPage(next,
        duration: Duration(milliseconds: 500), curve: Curves.ease);
  }

  Future<void> _handleBannerTap(BannerItem banner) async {
    // Try opening the app directly if installed
    final appUri = Uri.parse('android-app://com.zenfoo.customer');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
    } else {
      // App not installed — open Play Store
      final storeUri = Uri.parse(
          'https://play.google.com/store/apps/details?id=com.zenfoo.customer&pcampaignid=web_share');
      if (await canLaunchUrl(storeUri)) {
        await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _aniController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    if (_isLoading) {
      return AspectRatio(
        aspectRatio: 1.99,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Shimmer.fromColors(
            baseColor: colorScheme.surface,
            highlightColor: colorScheme.surfaceVariant,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: colorScheme.surface,
              ),
            ),
          ),
        ),
      );
    }

    if (_banners.isEmpty) {
      return SizedBox.shrink();
    }

    return AspectRatio(
      aspectRatio: 1.99,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (i) {
              setState(() => _active = i);
              _startTimer();
            },
            itemBuilder: (ctx, i) {
              final banner = _banners[i];
              return GestureDetector(
                onTap: () => _handleBannerTap(banner),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    // color: colorScheme.cardBackground,
                    boxShadow: colorScheme.cardShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: banner.imageUrl ?? '',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: colorScheme.surface,
                      highlightColor: colorScheme.surfaceVariant,
                      child: Container(color: colorScheme.surface),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: colorScheme.surface,
                    ),
                  ),
                ),
              );
            },
          ),
          if (_banners.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_banners.length, (i) {
                  bool selected = i == _active;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: AnimatedBuilder(
                      animation: _aniController,
                      builder: (context, _) => Container(
                        width: 28,
                        height: 7,
                        decoration: BoxDecoration(
                          color: selected 
                              ? colorScheme.textSecondary.withValues(alpha: 0.6)
                              : colorScheme.textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: selected
                            ? Stack(
                                children: [
                                  Positioned.fill(
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: _aniController.value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: colorScheme.textPrimary,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
