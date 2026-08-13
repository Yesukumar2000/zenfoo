import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:zenfoo_partner/providers/learning_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class TopicVideosScreen extends StatefulWidget {
  final int topicId;

  const TopicVideosScreen({super.key, required this.topicId});

  @override
  State<TopicVideosScreen> createState() => _TopicVideosScreenState();
}

class _TopicVideosScreenState extends State<TopicVideosScreen> {
  VideoPlayerController? _videoController;
  int? _playingVideoId;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTopicDetails();
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadTopicDetails() async {
    final learningProvider = context.read<LearningProvider>();
    await learningProvider.fetchTopicDetails(widget.topicId);
  }

  Future<void> _playVideo(String videoUrl, int videoId) async {
    // Dispose previous controller if exists
    if (_videoController != null) {
      await _videoController!.pause();
      await _videoController!.dispose();
    }

    setState(() {
      _playingVideoId = videoId;
      _isVideoInitialized = false;
    });

    // Initialize new controller
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
          _videoController!.play();
          _videoController!.setLooping(false);

          // Listen for completion
          _videoController!.addListener(() {
            if (_videoController!.value.position ==
                _videoController!.value.duration) {
              if (mounted) {
                setState(() {
                  // Video completed, stop playing
                });
              }
            }
          });
        }
      }).catchError((error) {
        debugPrint('Error initializing video: $error');
        if (mounted) {
          setState(() {
            _isVideoInitialized = false;
            _playingVideoId = null;
          });
        }
      });
  }

  void _stopVideo() {
    if (_videoController != null) {
      _videoController!.pause();
      setState(() {
        _playingVideoId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final learningProvider = context.watch<LearningProvider>();
    final isLoading = learningProvider.isLoadingDetails;
    final topicDetails = learningProvider.topicDetails;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// APP HEADER
          AppHeader(
            label: "LEARNING",
            title: topicDetails?.name ?? "Topic Videos",
            showBackButton: true,
            showExitButton: false,
          ),

          /// BODY
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  )
                : topicDetails == null || topicDetails.videos.isEmpty
                    ? _buildEmptyState(colorScheme)
                    : _buildVideosList(colorScheme, topicDetails),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off_outlined,
            size: 64,
            color: colorScheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No videos available',
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideosList(AppColorScheme colorScheme, topicDetails) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: topicDetails.videos.map<Widget>((video) {
          final isPlaying = _playingVideoId == video.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildVideoCard(colorScheme, video, isPlaying),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVideoCard(AppColorScheme colorScheme, video, bool isPlaying) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.border.withValues(alpha: 0.3),
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : colorScheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// VIDEO PLAYER OR THUMBNAIL
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: isPlaying && _isVideoInitialized
                  ? Stack(
                      children: [
                        VideoPlayer(_videoController!),

                        /// COMPACT PROGRESS INDICATOR
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: ValueListenableBuilder(
                            valueListenable: _videoController!,
                            builder: (context, VideoPlayerValue value, child) {
                              final progress = value.duration.inMilliseconds > 0
                                  ? value.position.inMilliseconds /
                                      value.duration.inMilliseconds
                                  : 0.0;

                              return Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: progress.clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        /// PAUSE OVERLAY
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: _stopVideo,
                            child: Container(
                              color: Colors.transparent,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.pause_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : isPlaying && !_isVideoInitialized
                      ? Container(
                          color: Colors.black,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: colorScheme.primary,
                            ),
                          ),
                        )
                      : Stack(
                          children: [
                            /// THUMBNAIL
                            video.thumbnailUrl.isNotEmpty
                                ? Image.network(
                                    video.thumbnailUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: colorScheme.surfaceElevated,
                                        child: Icon(
                                          Icons.videocam_outlined,
                                          size: 48,
                                          color: colorScheme.textSecondary,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: colorScheme.surfaceElevated,
                                    child: Icon(
                                      Icons.videocam_outlined,
                                      size: 48,
                                      color: colorScheme.textSecondary,
                                    ),
                                  ),

                            /// PLAY BUTTON OVERLAY
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: () =>
                                    _playVideo(video.videoUrl, video.id),
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: colorScheme.primary
                                                .withValues(alpha: 0.4),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.play_arrow_rounded,
                                        color: colorScheme.surface,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            /// DURATION BADGE
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  video.formattedDuration,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ),

          /// VIDEO INFO
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  video.description,
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
