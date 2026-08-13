import 'package:zenfoo_partner/models/incentive_offer_model.dart';
import 'package:zenfoo_partner/utils/safe_parser.dart';

/// Response model for delivery_boy/all-offers API
/// Returns offers grouped by status: active, upcoming, and expired
class AllOffersResponse {
  final bool status;
  final String message;
  final List<IncentiveOffer> activeOffers;
  final List<IncentiveOffer> upcomingOffers;
  final List<IncentiveOffer> expiredOffers;

  AllOffersResponse({
    required this.status,
    required this.message,
    this.activeOffers = const [],
    this.upcomingOffers = const [],
    this.expiredOffers = const [],
  });

  factory AllOffersResponse.fromJson(Map<String, dynamic> json) {
    final data = SafeParser.parseMap(json['data']);

    // Parse offer lists using SafeParser
    final activeList = SafeParser.parseList<dynamic>(data['active']);
    final upcomingList = SafeParser.parseList<dynamic>(data['upcoming']);
    final expiredList = SafeParser.parseList<dynamic>(data['expired']);

    return AllOffersResponse(
      status: SafeParser.parseBool(json['status']),
      message: SafeParser.parseString(json['message']),
      activeOffers: activeList
          .map(
              (offer) => IncentiveOffer.fromJson(offer as Map<String, dynamic>))
          .toList(),
      upcomingOffers: upcomingList
          .map(
              (offer) => IncentiveOffer.fromJson(offer as Map<String, dynamic>))
          .toList(),
      expiredOffers: expiredList
          .map(
              (offer) => IncentiveOffer.fromJson(offer as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': {
        'active': activeOffers.map((offer) => offer.toJson()).toList(),
        'upcoming': upcomingOffers.map((offer) => offer.toJson()).toList(),
        'expired': expiredOffers.map((offer) => offer.toJson()).toList(),
      },
    };
  }

  /// Get total count of all offers
  int get totalCount =>
      activeOffers.length + upcomingOffers.length + expiredOffers.length;

  /// Check if there are any offers
  bool get hasOffers => totalCount > 0;
}
