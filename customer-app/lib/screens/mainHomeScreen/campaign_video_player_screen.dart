import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';

class CampaignVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const CampaignVideoPlayerScreen({Key? key, required this.videoUrl})
      : super(key: key);

  @override
  State<CampaignVideoPlayerScreen> createState() =>
      _CampaignVideoPlayerScreenState();
}

class _CampaignVideoPlayerScreenState extends State<CampaignVideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.play();
        }
      }).catchError((e) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      });
    _controller.setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _hasError
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.white54, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load video',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : !_initialized
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : GestureDetector(
                  onTap: _toggleControls,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                      // Play/Pause overlay
                      if (_showControls)
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      // Progress bar
                      if (_showControls)
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 24,
                          child: ValueListenableBuilder<VideoPlayerValue>(
                            valueListenable: _controller,
                            builder: (context, value, _) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  VideoProgressIndicator(
                                    _controller,
                                    allowScrubbing: true,
                                    colors: const VideoProgressColors(
                                      playedColor: Colors.white,
                                      bufferedColor: Colors.white24,
                                      backgroundColor: Colors.white12,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(value.position),
                                        style: GoogleFonts.inter(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(value.duration),
                                        style: GoogleFonts.inter(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
