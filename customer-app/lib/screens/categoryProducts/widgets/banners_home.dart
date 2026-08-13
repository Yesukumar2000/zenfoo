import 'package:project/helper/utils/generalImports.dart';
import 'package:video_player/video_player.dart';

class BannerCarousel extends StatefulWidget {
  /// Single list of URLs / asset paths.
  final List<String> mediaUrls;
  final Duration interval;
  final bool autoPlayVideos;
  final void Function(String url)? onVideoTap;

  const BannerCarousel({
    Key? key,
    required this.mediaUrls,
    this.interval = const Duration(seconds: 4),
    this.autoPlayVideos = true,
    this.onVideoTap,
  }) : super(key: key);

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _aniController;
  Timer? _autoTimer;

  // One controller per video item, keyed by index
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, Timer> _videoTimers = {};

  int _active = 0;

  int get _pageCount => widget.mediaUrls.length;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _aniController = AnimationController(vsync: this, duration: widget.interval)
      ..forward();
    _startAutoTimer();
  }

  @override
  void didUpdateWidget(covariant BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.interval != oldWidget.interval) {
      _aniController.duration = widget.interval;
      _startAutoTimer();
    }
    if (widget.mediaUrls.length != oldWidget.mediaUrls.length &&
        _active >= widget.mediaUrls.length) {
      _active = 0;
      _pageController.jumpToPage(0);
      _startAutoTimer();
    }
  }

  void _restartProgress() {
    _aniController.forward(from: 0); // restart bar
    _autoTimer?.cancel();
    if (_pageCount > 1) {
      _autoTimer = Timer(widget.interval, _goNext);
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _aniController.dispose();
    _pageController.dispose();
    for (final c in _videoControllers.values) {
      c.dispose();
    }
    for (final t in _videoTimers.values) {
      t.cancel();
    }
    super.dispose();
  }

  void _startAutoTimer() {
    _aniController.forward(from: 0);
    _autoTimer?.cancel();
    if (_pageCount <= 1) return;
    _autoTimer = Timer(widget.interval, _goNext);
  }

  void _goNext() {
    if (_pageCount <= 1) return;
    final next = (_active + 1) % _pageCount;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 400),
      curve: Curves.ease,
    );
  }

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.webm');
  }

  Future<VideoPlayerController> _getVideoController(int index) async {
    if (_videoControllers[index] != null &&
        _videoControllers[index]!.value.isInitialized) {
      return _videoControllers[index]!;
    }

    final url = widget.mediaUrls[index];
    final controller = VideoPlayerController.network(url)..setVolume(0.0);
    _videoControllers[index] = controller;

    await controller.initialize();
    controller.setLooping(true);

    // Restart indicator whenever this video starts from 0 again
    controller.addListener(() {
      if (!mounted) return;
      final v = controller.value;
      if (index == _active &&
          v.isInitialized &&
          v.isPlaying &&
          v.position.inMilliseconds <= 300) {
        // near the start of the video -> new loop
        _restartProgress(); // ✅ restart progress bar
      }
    });

    if (index == _active && widget.autoPlayVideos) {
      controller.play();
    }

    _videoTimers[index]?.cancel();
    _videoTimers[index] =
        Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted && controller.value.isInitialized) {
        setState(() {});
      }
    });

    return controller;
  }

  @override
  Widget build(BuildContext context) {
    if (_pageCount == 0) return const SizedBox();

    return AspectRatio(
      aspectRatio: 1.99,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pageCount,
            onPageChanged: (i) async {
              setState(() => _active = i);
              _restartProgress();

              // Pause all videos except current, play current if video
              for (final entry in _videoControllers.entries) {
                if (entry.key == i) {
                  if (entry.value.value.isInitialized && widget.autoPlayVideos) {
                    entry.value.play();
                  }
                } else {
                  if (entry.value.value.isInitialized &&
                      entry.value.value.isPlaying) {
                    entry.value.pause();
                  }
                }
              }

              if (_isVideo(widget.mediaUrls[i])) {
                final vc = await _getVideoController(i);
                if (mounted && i == _active && widget.autoPlayVideos) {
                  vc.play();
                }
              }
            },
            itemBuilder: (ctx, index) {
              final url = widget.mediaUrls[index];
              final isVideo = _isVideo(url);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: isVideo ? _buildVideoItem(index) : _buildImageItem(url),
              );
            },
          ),

          // Middle indicators with animated progress
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pageCount, (i) {
                final selected = i == _active;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: AnimatedBuilder(
                    animation: _aniController,
                    builder: (context, _) => Container(
                      width: 28,
                      height: 7,
                      decoration: BoxDecoration(
                        color: selected ? Colors.grey[400] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: selected
                          ? FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _aniController.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
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

  Widget _buildImageItem(String url) {
    final isNetwork = url.startsWith('http');
    return isNetwork
        ? CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(color: Colors.grey[200]),
          )
        : Image.asset(
            url,
            fit: BoxFit.cover,
          );
  }

  Widget _buildVideoItem(int index) {
    final controller = _videoControllers[index];

    if (controller == null || !controller.value.isInitialized) {
      // Kick off initialization and show loader
      _getVideoController(index);
      return Container(
        color: Colors.black12,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final value = controller.value;
    final bool showCenterPlay = !widget.autoPlayVideos && !value.isPlaying;

    return GestureDetector(
      onTap: () {
        if (widget.onVideoTap != null) {
          widget.onVideoTap!(widget.mediaUrls[index]);
        } else {
          setState(() {
            if (value.isPlaying) {
              controller.pause();
            } else {
              controller.play();
            }
          });
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: value.size.width,
              height: value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
          // Centered play icon for paused videos
          if (showCenterPlay)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
        ],
      ),
    );
  }

}
