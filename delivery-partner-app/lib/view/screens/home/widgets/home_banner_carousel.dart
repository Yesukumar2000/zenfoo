import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:zenfoo_partner/models/banner_model.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';

class HomeBannerCarousel extends StatefulWidget {
  final List<BannerSliderModel> banners;

  const HomeBannerCarousel({
    super.key,
    required this.banners,
  });

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;
  final Map<int, VideoPlayerController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    _initVideoControllers();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    if (widget.banners.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_pageController.hasClients) {
        _currentIndex = (_currentIndex + 1) % widget.banners.length;
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _initVideoControllers() {
    for (int i = 0; i < widget.banners.length; i++) {
      final banner = widget.banners[i];
      if (banner.isVideo) {
        final ctl =
            VideoPlayerController.networkUrl(Uri.parse(banner.imageUrl));
        _videoControllers[i] = ctl;
        ctl.initialize().then((_) {
          if (mounted) setState(() {});
          ctl.setLooping(true);
          ctl.setVolume(0);
          ctl.play();
        }).catchError((_) {
          if (mounted) setState(() {});
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.getHeight(14),
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.banners.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          final banner = widget.banners[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            child: banner.isVideo
                ? _buildVideoItem(index)
                : _buildImageItem(banner),
          );
        },
      ),
    );
  }

  Widget _buildVideoItem(int index) {
    final controller = _videoControllers[index];
    if (controller == null || !controller.value.isInitialized) {
      return _buildGrayPlaceholder();
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _buildImageItem(BannerSliderModel banner) {
    return Image.network(
      banner.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildGrayPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildGrayPlaceholder();
      },
    );
  }

  Widget _buildGrayPlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.image, color: Colors.grey, size: 40),
      ),
    );
  }
}
