import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/providers/learning_provider.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class LearningScreen extends StatefulWidget {
  final bool fromBottomNav;

  const LearningScreen({
    super.key,
    this.fromBottomNav = false,
  });

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  int? _selectedTopicId;

  // Video controllers
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, ChewieController> _chewieControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTopics();
    });
  }

  @override
  void dispose() {
    // Dispose all Chewie controllers first
    for (final controller in _chewieControllers.values) {
      controller.dispose();
    }
    _chewieControllers.clear();

    // Then dispose video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();

    super.dispose();
  }

  Future<void> _loadTopics() async {
    final learningProvider = context.read<LearningProvider>();
    await learningProvider.fetchLearningTopics();

    // Auto-select first topic if available
    if (learningProvider.topics.isNotEmpty && _selectedTopicId == null) {
      final firstTopic = learningProvider.topics.first;
      _selectTopic(firstTopic.id);
    }
  }

  Future<void> _refreshTopics() async {
    await _loadTopics();
  }

  void _selectTopic(int topicId) async {
    if (_selectedTopicId == topicId) return;

    HapticFeedback.lightImpact();
    setState(() {
      _selectedTopicId = topicId;
    });

    // Dispose all Chewie controllers first
    for (final controller in _chewieControllers.values) {
      controller.pause();
      controller.dispose();
    }
    _chewieControllers.clear();

    // Then dispose video controllers
    for (final controller in _videoControllers.values) {
      await controller.pause();
      await controller.dispose();
    }
    _videoControllers.clear();

    final learningProvider = context.read<LearningProvider>();
    await learningProvider.fetchTopicDetails(topicId);
  }

  Future<ChewieController?> _getChewieController(int index) async {
    if (_chewieControllers[index] != null) {
      return _chewieControllers[index]!;
    }

    final learningProvider = context.read<LearningProvider>();
    final videos = learningProvider.topicDetails?.videos ?? [];
    if (index >= videos.length) {
      throw Exception('Invalid video index');
    }

    final video = videos[index];

    try {
      debugPrint('🎬 Initializing video $index: ${video.videoUrl}');
      debugPrint('   Type: ${video.videoType}');

      // Validate video URL
      if (video.videoUrl.isEmpty) {
        throw Exception('Video URL is empty');
      }

      // Validate URL format
      try {
        Uri.parse(video.videoUrl);
      } catch (e) {
        throw Exception('Invalid video URL format: ${video.videoUrl}');
      }

      debugPrint('⏳ Starting video initialization (timeout: 30 seconds)...');

      // Create video player controller with HTTP client configuration
      final videoController = VideoPlayerController.networkUrl(
        Uri.parse(video.videoUrl),
        httpHeaders: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          'Accept-Ranges': 'bytes',
        },
      );

      _videoControllers[index] = videoController;

      // Increase timeout to 30 seconds and log progress
      try {
        await videoController.initialize().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint('⚠️ Video initialization timed out after 30 seconds');
            debugPrint('   URL: ${video.videoUrl}');
            debugPrint('   Type: ${video.videoType}');
            throw Exception(
                'Video takes too long to load - server may be slow or URL unreachable');
          },
        );
        debugPrint('✅ Video initialization completed');
      } catch (timeoutError) {
        debugPrint('❌ Initialization error: $timeoutError');
        rethrow;
      }

      if (!mounted) {
        videoController.dispose();
        return null;
      }

      // Verify video is playable
      final duration = videoController.value.duration;
      if (duration.inMilliseconds <= 0) {
        throw Exception(
            'Invalid video duration - file may be corrupted or unsupported format');
      }

      // Create Chewie controller with custom settings
      final chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: true,
        looping: false,
        showControls: true,
        showControlsOnInitialize: true,
        aspectRatio: 16 / 9,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        progressIndicatorDelay: const Duration(milliseconds: 300),
        hideControlsTimer: const Duration(seconds: 3),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          debugPrint('🎥 Chewie error: $errorMessage');
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context
                        .watch<LanguageProvider>()
                        .getTranslatedText('unable_play_video'),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${context.watch<LanguageProvider>().getTranslatedText('format')}: ${video.videoType}',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );

      _chewieControllers[index] = chewieController;

      setState(() {}); // Refresh UI after initialization
      debugPrint('✅ Video $index initialized successfully');
      debugPrint(
          '   Duration: ${duration.inSeconds}s | Format: ${video.videoType}');

      return chewieController;
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing video $index: $e');
      debugPrint('   Stack: $stackTrace');

      // Remove failed controllers
      _chewieControllers.remove(index);
      _videoControllers.remove(index);

      if (mounted) {
        setState(() {});

        // Show detailed error message
        final errorMsg = e.toString();
        String displayError = 'Unable to load video';

        if (errorMsg.contains('timeout')) {
          displayError = 'Video loading timeout - network may be slow';
        } else if (errorMsg.contains('URL')) {
          displayError = 'Invalid video URL';
        } else if (errorMsg.contains('duration')) {
          displayError = 'Video format not supported';
        } else if (errorMsg.contains('connection')) {
          displayError = 'No internet connection';
        } else {
          displayError = errorMsg.length > 100
              ? errorMsg.substring(0, 100) + '...'
              : errorMsg;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayError,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context
                      .read<LanguageProvider>()
                      .getTranslatedText('retry_check_connection'),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label:
                  context.read<LanguageProvider>().getTranslatedText('retry'),
              textColor: Colors.white,
              onPressed: () async {
                // Retry loading the video
                debugPrint('🔄 Retrying video load for index $index...');
                await _getChewieController(index);
              },
            ),
          ),
        );
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final learningProvider = context.watch<LearningProvider>();
    final isLoadingTopics = learningProvider.isLoadingTopics;
    final isLoadingDetails = learningProvider.isLoadingDetails;
    final topics = learningProvider.topics;
    final topicDetails = learningProvider.topicDetails;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// APP HEADER
          AppHeader(
            label: context
                .watch<LanguageProvider>()
                .getTranslatedText('learn_grow'),
            title: context
                .watch<LanguageProvider>()
                .getTranslatedText('zenfoo_learnings'),
            showBackButton: !widget.fromBottomNav,
            showExitButton: false,
          ),

          /// BODY
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshTopics,
              child: isLoadingTopics
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    )
                  : topics.isEmpty
                      ? _buildEmptyState(colorScheme)
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),

                              /// HORIZONTAL TOPICS
                              _buildHorizontalTopics(colorScheme, topics),

                              const SizedBox(height: 16),

                              /// VIDEOS SECTION
                              if (_selectedTopicId != null)
                                _buildVideosSection(
                                  colorScheme,
                                  isLoadingDetails,
                                  topicDetails,
                                ),
                            ],
                          ),
                        ),
            ),
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
            Icons.school_outlined,
            size: 64,
            color: colorScheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            context
                .watch<LanguageProvider>()
                .getTranslatedText('no_learning_topics'),
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

  Widget _buildHorizontalTopics(AppColorScheme colorScheme, topics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            context.watch<LanguageProvider>().getTranslatedText('topics'),
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              final isSelected = _selectedTopicId == topic.id;
              return Padding(
                padding:
                    EdgeInsets.only(right: index < topics.length - 1 ? 12 : 0),
                child: GestureDetector(
                  onTap: () => _selectTopic(topic.id),
                  child: AnimatedScale(
                    scale: isSelected ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: SizedBox(
                      width: 90,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary.withValues(alpha: 0.12)
                                  : colorScheme.surfaceElevated
                                      .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.border
                                        .withValues(alpha: 0.15),
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            padding: const EdgeInsets.all(12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: topic.imageUrl.isNotEmpty
                                  ? Image.network(
                                      topic.imageUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: colorScheme.surfaceElevated,
                                          child: Icon(
                                            Icons.school_outlined,
                                            size: 28,
                                            color: colorScheme.textSecondary,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: colorScheme.surfaceElevated,
                                      child: Icon(
                                        Icons.school_outlined,
                                        size: 28,
                                        color: colorScheme.textSecondary,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            topic.name,
                            style: GoogleFonts.inter(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.textPrimary,
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideosSection(
    AppColorScheme colorScheme,
    bool isLoading,
    topicDetails,
  ) {
    if (isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ),
      );
    }

    if (topicDetails == null || topicDetails.videos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            context
                .watch<LanguageProvider>()
                .getTranslatedText('no_videos_available'),
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final videos = topicDetails.videos;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.watch<LanguageProvider>().getTranslatedText('videos'),
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          ...videos.asMap().entries.map((entry) {
            final index = entry.key;
            final video = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildVideoItem(colorScheme, index, video),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildVideoItem(AppColorScheme colorScheme, int index, video) {
    final chewieController = _chewieControllers[index];
    final isInitialized = chewieController != null;

    // DEBUG: Show video URL
    debugPrint('🔍 Building video item $index:');
    debugPrint('   URL: ${video.videoUrl}');
    debugPrint('   Type: ${video.videoType}');
    debugPrint('   Initialized: $isInitialized');

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.border.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// VIDEO PLAYER
          AspectRatio(
            aspectRatio: 2.2,
            child: Container(
              color: Colors.black,
              child: isInitialized
                  ? Chewie(controller: chewieController)
                  : GestureDetector(
                      onTap: () async {
                        debugPrint('🎬 Loading video $index...');
                        await _getChewieController(index);
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Thumbnail
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
                                        size: 56,
                                        color: colorScheme.textSecondary,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: colorScheme.surfaceElevated,
                                  child: Icon(
                                    Icons.videocam_outlined,
                                    size: 56,
                                    color: colorScheme.textSecondary,
                                  ),
                                ),

                          // Play button overlay
                          Container(
                            color: Colors.black.withValues(alpha: 0.25),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),

                          // Duration badge
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                video.formattedDuration,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

        ],
      ),
    );
  }
}
