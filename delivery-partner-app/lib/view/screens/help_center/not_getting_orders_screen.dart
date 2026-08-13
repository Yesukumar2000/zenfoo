import 'package:flutter/material.dart' hide Step;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/providers/duty_issues_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/custom_widgets/request_sent.dart';
import 'package:zenfoo_partner/models/not_getting_orders_model.dart';
import 'package:zenfoo_partner/view/screens/help_center/driver_issues_screen.dart';

class NotGettingOrdersScreen extends StatefulWidget {
  const NotGettingOrdersScreen({super.key});

  @override
  State<NotGettingOrdersScreen> createState() => _NotGettingOrdersScreenState();
}

class _NotGettingOrdersScreenState extends State<NotGettingOrdersScreen> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    final provider = context.read<DutyIssuesProvider>();
    await provider.getNotGettingOrders();

    final url = provider.notGettingOrdersData?.videoUrl;

    if (mounted && url != null && url.trim().isNotEmpty) {
      _initializeVideo(url);
    }
  }

  void _initializeVideo(String videoUrl) {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _handleRaiseRequest() async {
    final languageProvider = context.read<LanguageProvider>();
    final dutyIssuesProvider = context.read<DutyIssuesProvider>();
    HapticFeedback.heavyImpact();

    await dutyIssuesProvider.raiseOrdersIssue();

    if (!mounted) return;

    if (isStatusSuccess(dutyIssuesProvider.ordersIssueState.status)) {
      // Reset state and navigate to RequestSent screen
      dutyIssuesProvider.resetOrdersIssueState();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RequestSent(popTwice: true),
        ),
      );
    } else if (isStatusError(dutyIssuesProvider.ordersIssueState.status)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dutyIssuesProvider.ordersIssueState.message ??
                languageProvider.getTranslatedText('something_went_wrong'),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.read<LanguageProvider>();
    final dutyIssuesProvider = context.watch<DutyIssuesProvider>();
    final isLoading =
        isStatusLoading(dutyIssuesProvider.ordersIssueState.status);
    final isFetching =
        isStatusLoading(dutyIssuesProvider.getNotGettingOrdersState.status);

    final data = dutyIssuesProvider.notGettingOrdersData;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: isFetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  AppHeader(
                    label: languageProvider.getTranslatedText('support'),
                    title: languageProvider
                        .getTranslatedText('not_getting_orders'),
                    onBackPressed: () => Navigator.pop(context),
                    showBackButton: true,
                    trailing: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DriverIssuesScreen(
                                fixedIssueType: 'not_getting_order_issue'),
                          ),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.watch<ThemeProvider>().isDarkMode
                              ? Colors.white.withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.watch<ThemeProvider>().isDarkMode
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.black,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.history,
                            color: context.watch<ThemeProvider>().isDarkMode
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 24,
                      children: [
                        // Video Banner
                        _buildVideoBanner(colorScheme, data?.videoUrl),
                        // Instructions
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 20,
                          children: [
                            Text(
                              data?.title ?? "",
                              style: GoogleFonts.inter(
                                color: colorScheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                              ),
                            ),
                            Column(
                              spacing: 18,
                              children: _buildSteps(
                                  data?.steps, colorScheme, languageProvider),
                            ),
                          ],
                        ),
                        // Raise Request Button
                        CustomButton(
                          text: isLoading
                              ? languageProvider
                                  .getTranslatedText('please_wait')
                              : languageProvider
                                  .getTranslatedText('raise_request'),
                          onPressed: isLoading ? null : _handleRaiseRequest,
                          backgroundColor: const Color(0xFF9AC444),
                          borderRadius: 12,
                          height: 52,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          isLoading: isLoading,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildVideoBanner(AppColorScheme colorScheme, String? videoUrl) {
    final hasValidVideo = videoUrl != null && videoUrl.trim().isNotEmpty;

    if (hasValidVideo &&
        _videoController != null &&
        _videoController!.value.isInitialized) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoController!),

              // Play/Pause button overlay
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                  });
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Fallback placeholder
    return Container(
      width: double.infinity,
      height: 140,
      decoration: ShapeDecoration(
        color: const Color(0xFFE5E7EB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Center(
        child: hasValidVideo
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedAlertCircle,
                    color: colorScheme.textSecondary,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "No video available",
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 14,
                    ),
                  )
                ],
              ),
      ),
    );
  }

  List<Widget> _buildSteps(
    List<Step>? steps,
    AppColorScheme colorScheme,
    LanguageProvider languageProvider,
  ) {
    if (steps != null && steps.isNotEmpty) {
      return steps.map((step) {
        return _buildInstructionStep(
          step.stepNumber ?? 0,
          step.title ?? '',
          colorScheme,
        );
      }).toList();
    }

    return [
      Text(
        languageProvider.getTranslatedText('no_steps_available'),
        style: GoogleFonts.inter(
          color: colorScheme.textSecondary,
          fontSize: 14,
        ),
      )
    ];
  }

  Widget _buildInstructionStep(
    int stepNumber,
    String instruction,
    AppColorScheme colorScheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: ShapeDecoration(
            color: const Color(0xFFF6FDE6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(
                color: Color(0xFF9AC444),
                width: 1.5,
              ),
            ),
          ),
          child: Center(
            child: Text(
              stepNumber.toString(),
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.43,
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              instruction,
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.43,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
