import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/widgets/app_header.dart';

class ReviewsRatingsScreen extends StatefulWidget {
  const ReviewsRatingsScreen({Key? key}) : super(key: key);

  @override
  State<ReviewsRatingsScreen> createState() => _ReviewsRatingsScreenState();
}

class _ReviewsRatingsScreenState extends State<ReviewsRatingsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Review> _reviews = [];
  final Map<String, int> _ratingCounts = {
    '5': 1,
    '4': 1,
    '3': 1,
    '2': 1,
    '1': 1,
  };
  final double _averageRating = 5.0;
  final int _totalReviews = 5;

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  void _loadMockData() {
    // Mock data for UI demonstration
    _reviews = [
      Review(
        id: '1',
        userName: 'Sneha R',
        rating: 5.0,
        comment:
            'Fresh products and quick delivery! The vegetables and fruits were well-packed and super fresh. Really happy with the service.',
        dateTime: '2024-03-18T10:30:00',
        userImage: '',
      ),
      Review(
        id: '2',
        userName: 'Sneha R',
        rating: 5.0,
        comment:
            'Fresh products and quick delivery! The vegetables and fruits were well-packed and super fresh. Really happy with the service.',
        dateTime: '2024-03-17T14:20:00',
        userImage: '',
      ),
      Review(
        id: '3',
        userName: 'Sneha R',
        rating: 5.0,
        comment:
            'Fresh products and quick delivery! The vegetables and fruits were well-packed and super fresh. Really happy with the service.',
        dateTime: '2024-03-16T09:15:00',
        userImage: '',
      ),
      Review(
        id: '4',
        userName: 'Sneha R',
        rating: 5.0,
        comment:
            'Fresh products and quick delivery! The vegetables and fruits were well-packed and super fresh. Really happy with the service.',
        dateTime: '2024-03-15T16:45:00',
        userImage: '',
      ),
    ];

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchReviews() async {
    // Simulate refresh with mock data
    await Future.delayed(const Duration(milliseconds: 500));
    _loadMockData();
  }

  String _formatDateTime(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('dd MMM yyyy').format(date);
      }
    } catch (e) {
      return dateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: AppHeader(
                label: "Reviews",
                title: "Ratings & Reviews",
                showBackButton: true,
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: _fetchReviews,
          color: ColorsRes.appColor,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: ColorsRes.appColor,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Summary Card
          _buildRatingSummary(),
          const SizedBox(height: 24),
          // Reviews List
          Text(
            'Customer Reviews',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
              letterSpacing: -0.55,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 16),
          if (_reviews.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _reviews.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildReviewCard(_reviews[index]);
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF0F0F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Overall Rating
          Row(
            children: [
              // Left side - Big rating
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.star,
                          color: const Color(0xFFFBBF24),
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _averageRating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                            letterSpacing: -0.55,
                            height: 1.02,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rating',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right side - Rating bars
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildRatingBar('5', _ratingCounts['5']!),
                    const SizedBox(height: 8),
                    _buildRatingBar('4', _ratingCounts['4']!),
                    const SizedBox(height: 8),
                    _buildRatingBar('3', _ratingCounts['3']!),
                    const SizedBox(height: 8),
                    _buildRatingBar('2', _ratingCounts['2']!),
                    const SizedBox(height: 8),
                    _buildRatingBar('1', _ratingCounts['1']!),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String rating, int count) {
    final percentage = _totalReviews > 0 ? (count / _totalReviews) : 0.0;

    return Row(
      children: [
        Text(
          rating,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
            letterSpacing: -0.55,
            height: 1.02,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.star,
          color: const Color(0xFFFBBF24),
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFFFBBF24),
              ),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          count.toString(),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
            letterSpacing: -0.55,
            height: 1.02,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF0F0F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and rating
          Row(
            children: [
              // User avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.userName.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: ColorsRes.appColor,
                      letterSpacing: -0.55,
                      height: 1.02,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(review.dateTime),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF9CA3AF),
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                    ),
                  ],
                ),
              ),
              // Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      color: const Color(0xFFFBBF24),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF92400E),
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Review comment
          Text(
            review.comment,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF374151),
              letterSpacing: -0.55,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No Reviews Yet',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reviews from customers will appear here',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to Load Reviews',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchReviews,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsRes.appColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Review {
  final String id;
  final String userName;
  final double rating;
  final String comment;
  final String dateTime;
  final String userImage;

  Review({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.dateTime,
    required this.userImage,
  });
}
