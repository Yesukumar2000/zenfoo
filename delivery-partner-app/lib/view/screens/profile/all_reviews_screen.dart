import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/ratings_model.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/utils/ist_time.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class AllReviewsScreen extends StatefulWidget {
  final RatingsModel? initialRatings;

  const AllReviewsScreen({super.key, this.initialRatings});

  @override
  State<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<Review> _reviews = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialRatings != null) {
      _reviews = List.from(widget.initialRatings!.reviews);
      _isLoading = false;
      _hasMore = _reviews.length >= 50;
    } else {
      _loadRatings();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreRatings();
    }
  }

  Future<void> _loadRatings() async {
    final response = await _apiService.getRatings(page: 1, perPage: 50);

    if (response.status == ApiStatus.success && response.data != null) {
      final data = response.data['data'];
      if (data != null) {
        final ratingsModel = RatingsModel.fromJson(data);
        setState(() {
          _reviews = ratingsModel.reviews;
          _isLoading = false;
          _hasMore = _reviews.length >= 50;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreRatings() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    final response =
        await _apiService.getRatings(page: _currentPage, perPage: 50);

    if (response.status == ApiStatus.success && response.data != null) {
      final data = response.data['data'];
      if (data != null) {
        final newRatings = RatingsModel.fromJson(data);
        setState(() {
          _reviews.addAll(newRatings.reviews);
          _hasMore = newRatings.reviews.length >= 50;
          _isLoadingMore = false;
        });
      }
    } else {
      setState(() => _isLoadingMore = false);
    }
  }

  /// Group reviews by week and calculate average rating per week
  List<WeeklyRating> _getWeeklyRatings() {
    if (_reviews.isEmpty) return [];

    // Group reviews by week
    final Map<String, List<Review>> weeklyGroups = {};

    for (final review in _reviews) {
      final weekKey = _getWeekKey(review.date);
      if (!weeklyGroups.containsKey(weekKey)) {
        weeklyGroups[weekKey] = [];
      }
      weeklyGroups[weekKey]!.add(review);
    }

    // Convert to WeeklyRating list
    final List<WeeklyRating> weeklyRatings = [];
    int index = 0;

    for (final entry in weeklyGroups.entries) {
      final reviews = entry.value;
      final avgRating =
          reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

      weeklyRatings.add(WeeklyRating(
        weekLabel: _getWeekLabel(index),
        dateRange: entry.key,
        avgRating: avgRating,
        reviewCount: reviews.length,
      ));
      index++;
    }

    return weeklyRatings;
  }

  /// Get week key from date string (date range format)
  String _getWeekKey(String dateStr) {
    try {
      // IST, not UTC — a review left late in the evening is 5:30 earlier in
      // UTC and would otherwise be bucketed into the previous day's week.
      final date = parseIst(dateStr)!;
      // Get start of week (Monday)
      final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return '${startOfWeek.day} ${_getMonthName(startOfWeek.month)} - ${endOfWeek.day} ${_getMonthName(endOfWeek.month)}';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get week label (Last week, first week, etc.)
  String _getWeekLabel(int index) {
    switch (index) {
      case 0:
        return 'Last week';
      case 1:
        return 'First week';
      case 2:
        return 'Second week';
      case 3:
        return 'Third week';
      case 4:
        return 'Fourth week';
      default:
        return 'Week ${index + 1}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.watch<LanguageProvider>();

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: languageProvider.getTranslatedText('profile'),
            title: 'Ratings',
            showBackButton: true,
          ),
          if (_isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
            )
          else
            Expanded(
              child: _reviews.isEmpty
                  ? _buildEmptyState(colorScheme)
                  : _buildWeeklyRatingsList(colorScheme),
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
            Icons.star_border_rounded,
            size: 64,
            color: colorScheme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No ratings yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your weekly ratings will appear here',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colorScheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyRatingsList(AppColorScheme colorScheme) {
    final weeklyRatings = _getWeeklyRatings();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: weeklyRatings.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == weeklyRatings.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            ),
          );
        }

        final weeklyRating = weeklyRatings[index];
        final isLast = index == weeklyRatings.length - 1;

        return _buildWeeklyRatingRow(
          colorScheme: colorScheme,
          weeklyRating: weeklyRating,
          isLast: isLast,
        );
      },
    );
  }

  Widget _buildWeeklyRatingRow({
    required AppColorScheme colorScheme,
    required WeeklyRating weeklyRating,
    required bool isLast,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              // Week label
              Expanded(
                flex: 3,
                child: Text(
                  weeklyRating.weekLabel,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textPrimary,
                  ),
                ),
              ),
              // Stars and rating
              Expanded(
                flex: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(5, (index) {
                      final rating = weeklyRating.avgRating;
                      return Icon(
                        index < rating.floor()
                            ? Icons.star
                            : (index < rating ? Icons.star_half : Icons.star_border),
                        color: colorScheme.warning,
                        size: 16,
                      );
                    }),
                    const SizedBox(width: 6),
                    Text(
                      weeklyRating.avgRating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Date range
              Expanded(
                flex: 4,
                child: Text(
                  weeklyRating.dateRange,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          CustomPaint(
            painter: DashedLinePainter(
              color: colorScheme.border.withValues(alpha: 0.4),
            ),
            size: const Size(double.infinity, 1),
          ),
      ],
    );
  }
}

/// Weekly rating data model
class WeeklyRating {
  final String weekLabel;
  final String dateRange;
  final double avgRating;
  final int reviewCount;

  WeeklyRating({
    required this.weekLabel,
    required this.dateRange,
    required this.avgRating,
    required this.reviewCount,
  });
}

/// Custom painter for dashed line
class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
