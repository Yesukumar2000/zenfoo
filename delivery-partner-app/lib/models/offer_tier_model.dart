import 'package:zenfoo_partner/utils/safe_parser.dart';

class OfferTier {
  final int tierId;
  final int offerId;
  final int tierLevel;
  final String tierName;
  final double minEarnings;
  final int minOrders;
  final double incentiveAmount;
  final double progressPercentage;
  final double remainingEarnings;
  final int remainingOrders;
  final bool isAchieved;
  final double tierPercentage;

  OfferTier({
    required this.tierId,
    required this.offerId,
    required this.tierLevel,
    required this.tierName,
    required this.minEarnings,
    required this.minOrders,
    required this.incentiveAmount,
    this.progressPercentage = 0.0,
    this.remainingEarnings = 0.0,
    this.remainingOrders = 0,
    this.isAchieved = false,
    this.tierPercentage = 0.0,
  });

  bool get isUnlocked => progressPercentage >= 100;

  factory OfferTier.fromJson(Map<String, dynamic> json) {
    // Handle both API response formats
    // Format 1: tier_level, min_earnings (detail API)
    // Format 2: order, earnings_target (list API)

    // Parse tier level from either tier_level or order field
    final tierLevel = json['tier_level'] != null
        ? SafeParser.parseInt(json['tier_level'], defaultValue: 1)
        : SafeParser.parseInt(json['order'], defaultValue: 1);

    // Parse min earnings from either min_earnings or earnings_target field
    final minEarnings = json['min_earnings'] != null
        ? SafeParser.parseDouble(json['min_earnings'])
        : SafeParser.parseDouble(json['earnings_target']);

    return OfferTier(
      tierId: SafeParser.parseInt(json['tier_id']),
      offerId: SafeParser.parseInt(json['offer_id']),
      tierLevel: tierLevel,
      tierName: SafeParser.parseString(json['tier_name']),
      minEarnings: minEarnings,
      minOrders: SafeParser.parseInt(json['min_orders']),
      incentiveAmount: SafeParser.parseDouble(json['incentive_amount']),
      progressPercentage: SafeParser.parseDouble(json['progress_percentage']),
      remainingEarnings: SafeParser.parseDouble(json['remaining_earnings']),
      remainingOrders: SafeParser.parseInt(json['remaining_orders']),
      isAchieved: SafeParser.parseBool(json['is_achieved']),
      tierPercentage: SafeParser.parseDouble(json['percentage']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier_id': tierId,
      'offer_id': offerId,
      'tier_level': tierLevel,
      'tier_name': tierName,
      'min_earnings': minEarnings,
      'min_orders': minOrders,
      'incentive_amount': incentiveAmount,
      'progress_percentage': progressPercentage,
      'remaining_earnings': remainingEarnings,
      'remaining_orders': remainingOrders,
      'is_achieved': isAchieved,
      'percentage': tierPercentage,
    };
  }
}
