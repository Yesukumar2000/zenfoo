import 'package:zenfoo_partner/utils/safe_parser.dart';

class RatingsModel {
  final double averageRating;
  final int totalRatings;
  final RatingDistribution distribution;
  final List<Review> reviews;

  RatingsModel({
    required this.averageRating,
    required this.totalRatings,
    required this.distribution,
    required this.reviews,
  });

  factory RatingsModel.fromJson(Map<String, dynamic> json) {
    return RatingsModel(
      averageRating: SafeParser.parseDouble(json['avg_rating']),
      totalRatings: SafeParser.parseInt(json['total_ratings']),
      distribution:
          RatingDistribution.fromJson(SafeParser.parseMap(json['star_counts'])),
      reviews: SafeParser.parseList<Map<String, dynamic>>(json['ratings'])
          .map((e) => Review.fromJson(e))
          .toList(),
    );
  }
}

class RatingDistribution {
  final int star5;
  final int star4;
  final int star3;
  final int star2;
  final int star1;

  RatingDistribution({
    required this.star5,
    required this.star4,
    required this.star3,
    required this.star2,
    required this.star1,
  });

  factory RatingDistribution.fromJson(Map<String, dynamic> json) {
    return RatingDistribution(
      star5: SafeParser.parseInt(json['5_star']),
      star4: SafeParser.parseInt(json['4_star']),
      star3: SafeParser.parseInt(json['3_star']),
      star2: SafeParser.parseInt(json['2_star']),
      star1: SafeParser.parseInt(json['1_star']),
    );
  }
}

class Review {
  final int id;
  final int orderId;
  final String reviewerName;
  final String reviewerImage;
  final double rating;
  final String comment;
  final String date;

  Review({
    required this.id,
    required this.orderId,
    required this.reviewerName,
    required this.reviewerImage,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: SafeParser.parseInt(json['id']),
      orderId: SafeParser.parseInt(json['order_id']),
      reviewerName: SafeParser.parseString(json['customer_name']),
      reviewerImage: SafeParser.parseString(json['customer_profile']),
      rating: SafeParser.parseDouble(json['rating']),
      comment: SafeParser.parseString(json['review']),
      date: SafeParser.parseString(json['created_at']),
    );
  }
}
