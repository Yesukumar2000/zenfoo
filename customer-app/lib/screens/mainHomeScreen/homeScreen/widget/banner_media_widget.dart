import 'package:project/helper/utils/generalImports.dart';
import 'package:video_player/video_player.dart';

/// A widget that displays a banner media (image, GIF, or video).
/// Videos are played in a loop, muted, with no controls.
/// On error, falls back to an empty widget.
class BannerMediaWidget extends StatefulWidget {
  final String url;
  final String mediaType; // "image", "gif", or "video"
  final BoxFit fit;

  const BannerMediaWidget({
    super.key,
    required this.url,
    required this.mediaType,
    this.fit = BoxFit.cover,
  });

  @override
  State<BannerMediaWidget> createState() => _BannerMediaWidgetState();
}

class _BannerMediaWidgetState extends State<BannerMediaWidget> {
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    _initVideoIfNeeded();
  }

  void _initVideoIfNeeded() {
    if (widget.mediaType == "video" && widget.url.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      )..initialize().then((_) {
          if (mounted) {
            _videoController!.setLooping(true);
            _videoController!.setVolume(0);
            _videoController!.play();
            setState(() {
              _videoInitialized = true;
            });
          }
        }).catchError((e) {
          debugPrint("Banner video init error: $e");
          if (mounted) {
            setState(() {
              _videoError = true;
            });
          }
        });
    }
  }

  @override
  void didUpdateWidget(BannerMediaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.mediaType != widget.mediaType) {
      _videoController?.dispose();
      _videoController = null;
      _videoInitialized = false;
      _videoError = false;
      _initVideoIfNeeded();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Video
    if (widget.mediaType == "video") {
      if (_videoError) return const SizedBox.shrink();
      if (!_videoInitialized) {
        return Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
      return FittedBox(
        fit: widget.fit,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    // Image or GIF — CachedNetworkImage handles both natively
    return CachedNetworkImage(
      imageUrl: widget.url,
      fit: widget.fit,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => const SizedBox.shrink(),
    );
  }
}
