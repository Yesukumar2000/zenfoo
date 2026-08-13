import 'package:zenfoo_partner/models/offer_tier_model.dart';
import 'package:zenfoo_partner/utils/safe_parser.dart';

class IncentiveOffer {
  final int offerId;
  final String name;
  final String description;
  final String offerType; // earnings_based, orders_based
  final DateTime startDate;
  final DateTime endDate;
  final String? bannerImageUrl;
  final bool isActive;
  final int daysLeft;
  final List<OfferTier> tiers;
  final OfferProgress myProgress;
  final DateTime createdAt;
  final OfferConditions? conditions;

  IncentiveOffer({
    required this.offerId,
    required this.name,
    required this.description,
    required this.offerType,
    required this.startDate,
    required this.endDate,
    this.bannerImageUrl,
    this.isActive = true,
    this.daysLeft = 0,
    this.tiers = const [],
    required this.myProgress,
    required this.createdAt,
    this.conditions,
  });

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  bool get isExpired => DateTime.now().isAfter(endDate);

  factory IncentiveOffer.fromJson(Map<String, dynamic> json) {
    // Parse dates using SafeParser
    final startDate = SafeParser.parseDateTime(json['start_date']);
    final endDate = SafeParser.parseDateTime(json['end_date']);
    final now = DateTime.now();
    final isActiveByDate = now.isAfter(startDate) && now.isBefore(endDate);

    // Parse tiers first
    final tiersList = SafeParser.parseList<dynamic>(json['tiers']);
    final tiers = tiersList
        .map((tier) => OfferTier.fromJson(tier as Map<String, dynamic>))
        .toList();

    // Parse progress with tier context
    final myProgress = json['my_progress'] != null
        ? OfferProgress.fromJsonWithTiers(
            SafeParser.parseMap(json['my_progress']), tiers)
        : OfferProgress.empty();

    // Parse conditions if available
    final conditions = json['conditions'] != null
        ? OfferConditions.fromJson(SafeParser.parseMap(json['conditions']))
        : null;

    return IncentiveOffer(
      offerId: SafeParser.parseInt(json['offer_id']),
      name: SafeParser.parseString(json['name']),
      description: SafeParser.parseString(json['description']),
      offerType: SafeParser.parseString(json['offer_type'],
          defaultValue: 'earnings_based'),
      startDate: startDate,
      endDate: endDate,
      bannerImageUrl: SafeParser.parseStringNullable(json['banner_image_url']),
      isActive: json['status'] != null
          ? SafeParser.parseBool(json['status'])
          : (json['is_active'] != null
              ? SafeParser.parseBool(json['is_active'])
              : isActiveByDate),
      daysLeft: SafeParser.parseInt(json['days_remaining']),
      tiers: tiers,
      myProgress: myProgress,
      createdAt: SafeParser.parseDateTime(json['created_at']),
      conditions: conditions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offer_id': offerId,
      'name': name,
      'description': description,
      'offer_type': offerType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'banner_image_url': bannerImageUrl,
      'is_active': isActive,
      'days_remaining': daysLeft,
      'tiers': tiers.map((tier) => tier.toJson()).toList(),
      'my_progress': myProgress.toJson(),
      'created_at': createdAt.toIso8601String(),
      'conditions': conditions?.toJson(),
    };
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
      minGigsRequired: SafeParser.parseInt(json['min_gigs_required']),
      maxGigsSkip: SafeParser.parseInt(json['max_gigs_skip']),
      maxOrdersCancel: SafeParser.parseInt(json['max_orders_cancel']),
      loginMandatory: SafeParser.parseBool(json['login_mandatory']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min_gigs_required': minGigsRequired,
      'max_gigs_skip': maxGigsSkip,
      'max_orders_cancel': maxOrdersCancel,
      'login_mandatory': loginMandatory,
    };
  }
}

class OfferProgress {
  final double currentEarnings;
  final int gigsCompleted;
  final int gigsSkipped;
  final int ordersCancelled;
  final bool isEligible;
  final double previousTargetAmount;
  final double currentTargetAmount;
  final double totalTargetAmount;
  final double amountNeeded;
  final double progressPercentage;
  final double overallProgressPercentage;
  final OfferTier? currentTier;
  final OfferTier? nextTier;
  final List<CreditedTier> creditedTiers;
  final double totalCreditedAmount;

  OfferProgress({
    this.currentEarnings = 0.0,
    this.gigsCompleted = 0,
    this.gigsSkipped = 0,
    this.ordersCancelled = 0,
    this.isEligible = false,
    this.previousTargetAmount = 0.0,
    this.currentTargetAmount = 0.0,
    this.totalTargetAmount = 0.0,
    this.amountNeeded = 0.0,
    this.progressPercentage = 0.0,
    this.overallProgressPercentage = 0.0,
    this.currentTier,
    this.nextTier,
    this.creditedTiers = const [],
    this.totalCreditedAmount = 0.0,
  });

  factory OfferProgress.empty() {
    return OfferProgress(
      currentEarnings: 0.0,
      gigsCompleted: 0,
      gigsSkipped: 0,
      ordersCancelled: 0,
      isEligible: false,
      previousTargetAmount: 0.0,
      currentTargetAmount: 0.0,
      totalTargetAmount: 0.0,
      amountNeeded: 0.0,
      progressPercentage: 0.0,
      overallProgressPercentage: 0.0,
      currentTier: null,
      nextTier: null,
      creditedTiers: const [],
      totalCreditedAmount: 0.0,
    );
  }

  factory OfferProgress.fromJson(Map<String, dynamic> json) {
    // Parse credited tiers
    final creditedTiersList = SafeParser.parseList<dynamic>(json['credited_tiers']);
    final creditedTiers = creditedTiersList
        .map((tier) => CreditedTier.fromJson(tier as Map<String, dynamic>))
        .toList();

    return OfferProgress(
      currentEarnings: SafeParser.parseDouble(json['current_earnings']),
      gigsCompleted: SafeParser.parseInt(json['gigs_completed']),
      gigsSkipped: SafeParser.parseInt(json['gigs_skipped']),
      ordersCancelled: SafeParser.parseInt(json['orders_cancelled']),
      isEligible: SafeParser.parseBool(json['is_eligible']),
      previousTargetAmount: SafeParser.parseDouble(json['previous_target_amount']),
      currentTargetAmount: SafeParser.parseDouble(json['current_target_amount']),
      totalTargetAmount: SafeParser.parseDouble(json['total_target_amount']),
      amountNeeded: SafeParser.parseDouble(json['amount_needed']),
      progressPercentage: SafeParser.parseDouble(json['progress_percentage']),
      overallProgressPercentage: SafeParser.parseDouble(json['overall_progress_percentage']),
      currentTier: json['current_tier'] != null
          ? OfferTier.fromJson(SafeParser.parseMap(json['current_tier']))
          : null,
      nextTier: json['next_tier'] != null
          ? OfferTier.fromJson(SafeParser.parseMap(json['next_tier']))
          : null,
      creditedTiers: creditedTiers,
      totalCreditedAmount: SafeParser.parseDouble(json['total_credited_amount']),
    );
  }

  /// Create OfferProgress from JSON with tier calculation
  factory OfferProgress.fromJsonWithTiers(
      Map<String, dynamic> json, List<OfferTier> tiers) {
    final currentEarnings = SafeParser.parseDouble(json['current_earnings']);
    final gigsCompleted = SafeParser.parseInt(json['gigs_completed']);
    final gigsSkipped = SafeParser.parseInt(json['gigs_skipped']);
    final ordersCancelled = SafeParser.parseInt(json['orders_cancelled']);
    final isEligible = SafeParser.parseBool(json['is_eligible']);
    final previousTargetAmount = SafeParser.parseDouble(json['previous_target_amount']);
    final currentTargetAmount = SafeParser.parseDouble(json['current_target_amount']);
    final totalTargetAmount = SafeParser.parseDouble(json['total_target_amount']);
    final amountNeeded = SafeParser.parseDouble(json['amount_needed']);
    final progressPercentage = SafeParser.parseDouble(json['progress_percentage']);
    final overallProgressPercentage = SafeParser.parseDouble(json['overall_progress_percentage']);

    // Parse credited tiers
    final creditedTiersList = SafeParser.parseList<dynamic>(json['credited_tiers']);
    final creditedTiers = creditedTiersList
        .map((tier) => CreditedTier.fromJson(tier as Map<String, dynamic>))
        .toList();

    // Sort tiers by earnings target (ascending)
    final sortedTiers = List<OfferTier>.from(tiers)
      ..sort((a, b) => a.minEarnings.compareTo(b.minEarnings));

    // Find current tier (highest tier that user has achieved)
    OfferTier? currentTier;
    for (var tier in sortedTiers) {
      if (currentEarnings >= tier.minEarnings) {
        currentTier = tier;
      } else {
        break;
      }
    }

    // Find next tier (first tier that user hasn't achieved yet)
    OfferTier? nextTier;
    for (var tier in sortedTiers) {
      if (currentEarnings < tier.minEarnings) {
        nextTier = tier;
        break;
      }
    }

    return OfferProgress(
      currentEarnings: currentEarnings,
      gigsCompleted: gigsCompleted,
      gigsSkipped: gigsSkipped,
      ordersCancelled: ordersCancelled,
      isEligible: isEligible,
      previousTargetAmount: previousTargetAmount,
      currentTargetAmount: currentTargetAmount,
      totalTargetAmount: totalTargetAmount,
      amountNeeded: amountNeeded,
      progressPercentage: progressPercentage,
      overallProgressPercentage: overallProgressPercentage,
      currentTier: currentTier,
      nextTier: nextTier,
      creditedTiers: creditedTiers,
      totalCreditedAmount: SafeParser.parseDouble(json['total_credited_amount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_earnings': currentEarnings,
      'gigs_completed': gigsCompleted,
      'gigs_skipped': gigsSkipped,
      'orders_cancelled': ordersCancelled,
      'is_eligible': isEligible,
      'previous_target_amount': previousTargetAmount,
      'current_target_amount': currentTargetAmount,
      'total_target_amount': totalTargetAmount,
      'amount_needed': amountNeeded,
      'progress_percentage': progressPercentage,
      'overall_progress_percentage': overallProgressPercentage,
      'current_tier': currentTier?.toJson(),
      'next_tier': nextTier?.toJson(),
      'credited_tiers': creditedTiers.map((tier) => tier.toJson()).toList(),
      'total_credited_amount': totalCreditedAmount,
    };
  }
}

class CreditedTier {
  final int tierId;
  final double incentiveAmount;
  final DateTime creditedAt;
  final int transactionId;

  CreditedTier({
    required this.tierId,
    required this.incentiveAmount,
    required this.creditedAt,
    required this.transactionId,
  });

  factory CreditedTier.fromJson(Map<String, dynamic> json) {
    return CreditedTier(
      tierId: SafeParser.parseInt(json['tier_id']),
      incentiveAmount: SafeParser.parseDouble(json['incentive_amount']),
      creditedAt: SafeParser.parseDateTime(json['credited_at']),
      transactionId: SafeParser.parseInt(json['transaction_id']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier_id': tierId,
      'incentive_amount': incentiveAmount,
      'credited_at': creditedAt.toIso8601String(),
      'transaction_id': transactionId,
    };
  }
}
