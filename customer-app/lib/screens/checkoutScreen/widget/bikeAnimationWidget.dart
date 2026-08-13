import 'package:project/helper/utils/generalImports.dart';
import 'package:video_player/video_player.dart';

class BikeAnimationWidget extends StatefulWidget {
  final double width;
  final double height;

  const BikeAnimationWidget({
    super.key,
    this.width = 70,
    this.height = 70,
  });

  @override
  State<BikeAnimationWidget> createState() => _BikeAnimationWidgetState();
}

class _BikeAnimationWidgetState extends State<BikeAnimationWidget> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchAndInitVideo();
  }

  Future<void> _fetchAndInitVideo() async {
    try {
      final response = await fetchBikeAnimation(context: context);

      if (response['status'] == 1 && response['data'] != null) {
        final videoUrl = response['data']['bike_animation'];
        if (videoUrl != null && videoUrl.toString().isNotEmpty) {
          await _initVideoPlayer(videoUrl);
          return;
        }
      }
      if (mounted) setState(() => _hasError = true);
    } catch (e) {
      debugPrint("Error fetching bike animation: $e");
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _initVideoPlayer(String videoUrl) async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
    );

    try {
      await _videoController!.initialize();
      if (mounted) {
        _videoController!.setLooping(true);
        _videoController!.setVolume(0);
        _videoController!.play();
        setState(() => _isVideoInitialized = true);
      }
    } catch (e) {
      debugPrint("Video player init error: $e");
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Widget _buildFallbackImage() {
    final colorScheme = context.read<ThemeProvider>().colorScheme;
    return Image.asset(
      'assets/images/delivery_tip.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.delivery_dining_rounded,
            color: colorScheme.primary,
            size: 32,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _isVideoInitialized && !_hasError
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              )
            : _buildFallbackImage(),
      ),
    );
  }
}
