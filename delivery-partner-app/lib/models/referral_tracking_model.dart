import 'package:zenfoo_partner/utils/safe_parser.dart';

class ReferralTrackingModel {
  final String myReferralCode;
  final List<ReferralItem> myReferrals;
  final int totalReferrals;
  final int bonusesEarned;
  final double totalBonusAmount;
  final WhoReferredMe? whoReferredMe;

  ReferralTrackingModel({
    required this.myReferralCode,
    required this.myReferrals,
    required this.totalReferrals,
    required this.bonusesEarned,
    required this.totalBonusAmount,
    this.whoReferredMe,
  });

  factory ReferralTrackingModel.fromJson(Map<String, dynamic> json) {
    return ReferralTrackingModel(
      myReferralCode: SafeParser.parseString(json['my_referral_code']),
      myReferrals:
          SafeParser.parseList<Map<String, dynamic>>(json['my_referrals'])
              .map((e) => ReferralItem.fromJson(e))
              .toList(),
      totalReferrals: SafeParser.parseInt(json['total_referrals']),
      bonusesEarned: SafeParser.parseInt(json['bonuses_earned']),
      totalBonusAmount:
          SafeParser.parseDouble(json['total_bonus_amount']),
      whoReferredMe: json['who_referred_me'] != null
          ? WhoReferredMe.fromJson(
              SafeParser.parseMap(json['who_referred_me']))
          : null,
    );
  }
}

class ReferralItem {
  final int referredDriverId;
  final String referredDriverName;
  final int completedOrders;
  final int requiredOrders;
  final double progressPercentage;
  final bool bonusEarned;
  final double bonusAmount;

  ReferralItem({
    required this.referredDriverId,
    required this.referredDriverName,
    required this.completedOrders,
    required this.requiredOrders,
    required this.progressPercentage,
    required this.bonusEarned,
    required this.bonusAmount,
  });

  factory ReferralItem.fromJson(Map<String, dynamic> json) {
    return ReferralItem(
      referredDriverId: SafeParser.parseInt(json['referred_driver_id']),
      referredDriverName:
          SafeParser.parseString(json['referred_driver_name']),
      completedOrders: SafeParser.parseInt(json['completed_orders']),
      requiredOrders: SafeParser.parseInt(json['required_orders']),
      progressPercentage:
          SafeParser.parseDouble(json['progress_percentage']),
      bonusEarned: SafeParser.parseBool(json['bonus_earned']),
      bonusAmount: SafeParser.parseDouble(json['bonus_amount']),
    );
  }
}

class WhoReferredMe {
  final int referringDriverId;
  final String referringDriverName;
  final int myCompletedOrders;
  final String bonusStatus;

  WhoReferredMe({
    required this.referringDriverId,
    required this.referringDriverName,
    required this.myCompletedOrders,
    required this.bonusStatus,
  });

  factory WhoReferredMe.fromJson(Map<String, dynamic> json) {
    return WhoReferredMe(
      referringDriverId: SafeParser.parseInt(json['referring_driver_id']),
      referringDriverName:
          SafeParser.parseString(json['referring_driver_name']),
      myCompletedOrders: SafeParser.parseInt(json['my_completed_orders']),
      bonusStatus: SafeParser.parseString(json['bonus_status']),
    );
  }
}
