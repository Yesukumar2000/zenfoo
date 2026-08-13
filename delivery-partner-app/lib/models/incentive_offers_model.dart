class IncentiveOffersResponse {
  final bool status;
  final String message;
  final IncentiveOffersData data;

  IncentiveOffersResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory IncentiveOffersResponse.fromJson(Map<String, dynamic> json) {
    return IncentiveOffersResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: IncentiveOffersData.fromJson(json['data'] ?? {}),
    );
  }
}

class IncentiveOffersData {
  final List<IncentiveOffer> offers;
  final int totalOffers;

  IncentiveOffersData({
    required this.offers,
    required this.totalOffers,
  });

  factory IncentiveOffersData.fromJson(Map<String, dynamic> json) {
    return IncentiveOffersData(
      offers: (json['offers'] as List<dynamic>?)
              ?.map((e) => IncentiveOffer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalOffers: json['total_offers'] ?? 0,
    );
  }
}

class IncentiveOffer {
  final int offerId;
  final String name;
  final String description;
  final String? bannerImageUrl;
  final String startDate;
  final String endDate;
  final int daysRemaining;
  final OfferConditions conditions;
  final ProgressData myProgress;
  final List<TierInfo> tiers;

  IncentiveOffer({
    required this.offerId,
    required this.name,
    required this.description,
    this.bannerImageUrl,
    required this.startDate,
    required this.endDate,
    required this.daysRemaining,
    required this.conditions,
    required this.myProgress,
    required this.tiers,
  });

  factory IncentiveOffer.fromJson(Map<String, dynamic> json) {
    return IncentiveOffer(
      offerId: json['offer_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      bannerImageUrl: json['banner_image_url'],
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      daysRemaining: json['days_remaining'] ?? 0,
      conditions: OfferConditions.fromJson(json['conditions'] ?? {}),
      myProgress: ProgressData.fromJson(json['my_progress'] ?? {}),
      tiers: (json['tiers'] as List<dynamic>?)
              ?.map((e) => TierInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class OfferConditions {
  final int minGigsRequired;
  final int maxGigsSkip;
  final int maxOrdersCancel;
  final bool loginMandatory;

  OfferConditions({
    required this.minGigsRequired,
    required this.maxGigsSkip,
    required this.maxOrdersCancel,
    required this.loginMandatory,
  });

  factory OfferConditions.fromJson(Map<String, dynamic> json) {
    return OfferConditions(
      minGigsRequired: json['min_gigs_required'] ?? 0,
      maxGigsSkip: json['max_gigs_skip'] ?? 0,
      maxOrdersCancel: json['max_orders_cancel'] ?? 0,
      loginMandatory: json['login_mandatory'] ?? false,
    );
  }
}

class ProgressData {
  final double currentEarnings;
  final int gigsCompleted;
  final int gigsSkipped;
  final int ordersCancelled;
  final bool isEligible;
  final String? currentTier;
  final TierProgress? nextTier;

  ProgressData({
    required this.currentEarnings,
    required this.gigsCompleted,
    required this.gigsSkipped,
    required this.ordersCancelled,
    required this.isEligible,
    this.currentTier,
    this.nextTier,
  });

  factory ProgressData.fromJson(Map<String, dynamic> json) {
    return ProgressData(
      currentEarnings: (json['current_earnings'] ?? 0).toDouble(),
      gigsCompleted: json['gigs_completed'] ?? 0,
      gigsSkipped: json['gigs_skipped'] ?? 0,
      ordersCancelled: json['orders_cancelled'] ?? 0,
      isEligible: json['is_eligible'] ?? false,
      currentTier: json['current_tier'],
      nextTier: json['next_tier'] != null
          ? TierProgress.fromJson(json['next_tier'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TierProgress {
  final String tierName;
  final double earningsTarget;
  final double incentiveAmount;
  final double remainingEarnings;
  final double progressPercentage;

  TierProgress({
    required this.tierName,
    required this.earningsTarget,
    required this.incentiveAmount,
    required this.remainingEarnings,
    required this.progressPercentage,
  });

  factory TierProgress.fromJson(Map<String, dynamic> json) {
    return TierProgress(
      tierName: json['tier_name'] ?? '',
      earningsTarget: (json['earnings_target'] ?? 0).toDouble(),
      incentiveAmount: (json['incentive_amount'] ?? 0).toDouble(),
      remainingEarnings: (json['remaining_earnings'] ?? 0).toDouble(),
      progressPercentage: (json['progress_percentage'] ?? 0).toDouble(),
    );
  }
}

class TierInfo {
  final String tierName;
  final double earningsTarget;
  final double incentiveAmount;
  final bool isAchieved;
  final int order;

  TierInfo({
    required this.tierName,
    required this.earningsTarget,
    required this.incentiveAmount,
    required this.isAchieved,
    required this.order,
  });

  factory TierInfo.fromJson(Map<String, dynamic> json) {
    return TierInfo(
      tierName: json['tier_name'] ?? '',
      earningsTarget: (json['earnings_target'] ?? 0).toDouble(),
      incentiveAmount: (json['incentive_amount'] ?? 0).toDouble(),
      isAchieved: json['is_achieved'] ?? false,
      order: json['order'] ?? 0,
    );
  }
}
