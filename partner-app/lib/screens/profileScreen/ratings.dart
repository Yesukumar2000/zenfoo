import 'package:flutter/material.dart';
import '../../helper/utils/generalImports.dart';
import '../../helper/widgets/app_header.dart';
import '../../models/ratings_model.dart';
import '../../repositories/ratingsAndReview.dart' as repo;

class RatingsScreen extends StatefulWidget {
  const RatingsScreen({super.key});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  late Future<RatingsModel?> _ratingsFuture;

  @override
  void initState() {
    super.initState();
    _ratingsFuture = fetchRatings();
  }

  Future<RatingsModel?> fetchRatings() async {
    try {
      final response = await repo.ratings(context: context);
      if (response != null && response.status == 1) {
        return response;
      }
    } catch (e) {
      debugPrint("Error fetching ratings: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsRes.appColorWhite,
      body: Column(
        children: [
          AppHeader(
            label: getTranslatedValue(context, profileLabel),
            title: getTranslatedValue(context, ratingsAndReviewsLabel),
            showBackButton: true,
          ),
          Expanded(
            child: FutureBuilder<RatingsModel?>(
              future: _ratingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || snapshot.data == null) {
                  return Center(
                      child: Text(
                          getTranslatedValue(context, noRatingsFoundLabel)));
                }

                final ratingsData = snapshot.data!.data;
                if (ratingsData == null ||
                    (ratingsData.ratingList?.isEmpty ?? true)) {
                  return Center(
                      child: Text(
                          getTranslatedValue(context, noRatingsFoundLabel)));
                }

                return ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    _buildRatingBreakdownCard(ratingsData),
                    const SizedBox(height: 40),
                    ...ratingsData.ratingList!
                        .map((review) => _buildReviewItem(review)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBreakdownCard(RatingsData data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColorsRes.appColorWhite,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: ColorsRes.appColorBlack.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded,
                      color: ColorsRes.appColorYellow, size: 45),
                  const SizedBox(width: 8),
                  Text(
                    double.tryParse(data.averageRating ?? "0.0")
                            ?.toStringAsFixed(1) ??
                        "0.0",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                      color: ColorsRes.appColorBlack,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                getTranslatedValue(context, ratingLabel),
                style: TextStyle(
                  fontSize: 16,
                  color: ColorsRes.subTitleTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              children: [
                _buildStarRow(
                    5, data.starCounts?.fiveStar, data.totalRatingsCount),
                _buildStarRow(
                    4, data.starCounts?.fourStar, data.totalRatingsCount),
                _buildStarRow(
                    3, data.starCounts?.threeStar, data.totalRatingsCount),
                _buildStarRow(
                    2, data.starCounts?.twoStar, data.totalRatingsCount),
                _buildStarRow(
                    1, data.starCounts?.oneStar, data.totalRatingsCount),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRow(int starCount, String? count, int total) {
    double progress = 0;
    if (total > 0) {
      progress = (int.tryParse(count ?? "0") ?? 0) / total;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child: Text(
              "$starCount",
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: ColorsRes.appColorBlack,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.star_rounded, color: ColorsRes.appColorYellow, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: ColorsRes.grey.shade100,
                valueColor:
                    AlwaysStoppedAnimation<Color>(ColorsRes.appColorYellow),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 20,
            child: Text(
              count ?? "0",
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: ColorsRes.appColorBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(RatingList review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorsRes.grey.shade200,
                  image: review.customerProfile != null &&
                          review.customerProfile!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(review.customerProfile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: review.customerProfile == null ||
                        review.customerProfile!.isEmpty
                    ? Icon(Icons.person, color: ColorsRes.grey, size: 32)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  review.customerName ?? "Anonymous",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorsRes.appColorBlack,
                  ),
                ),
              ),
              Icon(Icons.star_rounded,
                  color: ColorsRes.appColorYellow, size: 32),
              const SizedBox(width: 6),
              Text(
                double.tryParse(review.avgOrderRating ?? "0.0")
                        ?.toStringAsFixed(1) ??
                    "0.0",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorsRes.appColorBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 0),
            child: Text(
              review.review ?? "",
              style: TextStyle(
                fontSize: 15,
                color: ColorsRes.appColorBlack.withOpacity(0.65),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension RatingsDataExt on RatingsData {
  int get totalRatingsCount {
    return int.tryParse(totalRatings ?? "0") ?? 0;
  }
}
