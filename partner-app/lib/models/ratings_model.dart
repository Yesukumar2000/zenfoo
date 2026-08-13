class RatingsModel {
  int? status;
  String? message;
  RatingsData? data;

  RatingsModel({this.status, this.message, this.data});

  RatingsModel.fromJson(Map<String, dynamic> json) {
    status = int.tryParse(json['status'].toString());
    message = json['message'].toString();
    data = json['data'] != null ? RatingsData.fromJson(json['data']) : null;
  }
}

class RatingsData {
  String? averageRating;
  String? totalRatings;
  StarCounts? starCounts;
  List<RatingList>? ratingList;

  RatingsData({
    this.averageRating,
    this.totalRatings,
    this.starCounts,
    this.ratingList,
  });

  RatingsData.fromJson(Map<String, dynamic> json) {
    averageRating = json['avg_rating'].toString();
    totalRatings = json['total_ratings'].toString();
    starCounts = json['star_counts'] != null
        ? StarCounts.fromJson(json['star_counts'])
        : null;
    if (json['reviews'] != null) {
      ratingList = <RatingList>[];
      json['reviews'].forEach((v) {
        ratingList!.add(RatingList.fromJson(v));
      });
    }
  }
}

class StarCounts {
  String? oneStar;
  String? twoStar;
  String? threeStar;
  String? fourStar;
  String? fiveStar;

  StarCounts(
      {this.oneStar,
      this.twoStar,
      this.threeStar,
      this.fourStar,
      this.fiveStar});

  StarCounts.fromJson(Map<String, dynamic> json) {
    oneStar = json['1_star'].toString();
    twoStar = json['2_star'].toString();
    threeStar = json['3_star'].toString();
    fourStar = json['4_star'].toString();
    fiveStar = json['5_star'].toString();
  }
}

class RatingList {
  String? id;
  String? orderId;
  String? review;
  String? customerId;
  String? customerName;
  String? customerProfile;
  String? createdAt;
  String? avgOrderRating;

  RatingList({
    this.id,
    this.orderId,
    this.review,
    this.customerId,
    this.customerName,
    this.customerProfile,
    this.createdAt,
    this.avgOrderRating,
  });

  RatingList.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    orderId = json['order_id'].toString();
    review = json['review'].toString();
    customerId = json['customer_id'].toString();
    customerName = json['customer_name'].toString();
    customerProfile = json['customer_profile']?.toString();
    createdAt = json['created_at'].toString();
    avgOrderRating = json['avg_order_rating'].toString();
  }
}

class RatingUser {
  String? id;
  String? name;
  String? profile;

  RatingUser({this.id, this.name, this.profile});

  RatingUser.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    name = json['name'].toString();
    profile = json['profile'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['profile'] = profile;
    return data;
  }
}

class RatingImages {
  String? id;
  String? productRatingId;
  String? image;
  String? imageUrl;

  RatingImages({this.id, this.productRatingId, this.image, this.imageUrl});

  RatingImages.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    productRatingId = json['product_rating_id'].toString();
    image = json['image'].toString();
    imageUrl = json['image_url'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['product_rating_id'] = productRatingId;
    data['image'] = image;
    data['image_url'] = imageUrl;
    return data;
  }
}
