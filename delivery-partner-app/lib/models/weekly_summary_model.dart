import 'package:zenfoo_partner/utils/safe_parser.dart';

class WeeklySummaryResponse {
  final String period;
  final String periodName;
  final String startDate;
  final String endDate;
  final WeeklySummary summary;
  final WeeklyStatistics statistics;

  WeeklySummaryResponse({
    required this.period,
    required this.periodName,
    required this.startDate,
    required this.endDate,
    required this.summary,
    required this.statistics,
  });

  factory WeeklySummaryResponse.fromJson(Map<String, dynamic> json) {
    final data = SafeParser.parseMap(json['data']);

    return WeeklySummaryResponse(
      period: SafeParser.parseString(data['period']),
      periodName: SafeParser.parseString(data['period_name']),
      startDate: SafeParser.parseString(data['start_date']),
      endDate: SafeParser.parseString(data['end_date']),
      summary: WeeklySummary.fromJson(SafeParser.parseMap(data['summary'])),
      statistics:
          WeeklyStatistics.fromJson(SafeParser.parseMap(data['statistics'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'period_name': periodName,
      'start_date': startDate,
      'end_date': endDate,
      'summary': summary.toJson(),
      'statistics': statistics.toJson(),
    };
  }
}

class WeeklySummary {
  final double totalEarnings;
  final EarningsBreakdown breakdown;
  final double floatingCashPending;
  final double grossEarnings;
  final PayoutDetails payoutDetails;

  WeeklySummary({
    required this.totalEarnings,
    required this.breakdown,
    required this.floatingCashPending,
    required this.grossEarnings,
    required this.payoutDetails,
  });

  factory WeeklySummary.fromJson(Map<String, dynamic> json) {
    return WeeklySummary(
      totalEarnings: SafeParser.parseDouble(json['total_earnings']),
      breakdown: EarningsBreakdown.fromJson(
        SafeParser.parseMap(json['breakdown']),
      ),
      floatingCashPending:
          SafeParser.parseDouble(json['floating_cash_pending']),
      grossEarnings: SafeParser.parseDouble(json['gross_earnings']),
      payoutDetails: PayoutDetails.fromJson(
        SafeParser.parseMap(json['payout_details']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_earnings': totalEarnings,
      'breakdown': breakdown.toJson(),
      'floating_cash_pending': floatingCashPending,
      'gross_earnings': grossEarnings,
      'payout_details': payoutDetails.toJson(),
    };
  }
}

class EarningsBreakdown {
  final double orderEarnings;
  final double multiOrderBonus;
  final double customerTips;
  final double incentiveEarnings;
  final double referralBonus;

  EarningsBreakdown({
    required this.orderEarnings,
    required this.multiOrderBonus,
    required this.customerTips,
    required this.incentiveEarnings,
    required this.referralBonus,
  });

  factory EarningsBreakdown.fromJson(Map<String, dynamic> json) {
    return EarningsBreakdown(
      orderEarnings: SafeParser.parseDouble(json['order_earnings']),
      multiOrderBonus: SafeParser.parseDouble(json['multi_order_bonus']),
      customerTips: SafeParser.parseDouble(json['customer_tips']),
      incentiveEarnings: SafeParser.parseDouble(json['incentive_earnings']),
      referralBonus: SafeParser.parseDouble(json['referral_bonus']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_earnings': orderEarnings,
      'multi_order_bonus': multiOrderBonus,
      'customer_tips': customerTips,
      'incentive_earnings': incentiveEarnings,
      'referral_bonus': referralBonus,
    };
  }
}

class PayoutDetails {
  final double totalPaidOut;
  final int payoutTransactions;

  PayoutDetails({
    required this.totalPaidOut,
    required this.payoutTransactions,
  });

  factory PayoutDetails.fromJson(Map<String, dynamic> json) {
    return PayoutDetails(
      totalPaidOut: SafeParser.parseDouble(json['total_paid_out']),
      payoutTransactions: SafeParser.parseInt(json['payout_transactions']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_paid_out': totalPaidOut,
      'payout_transactions': payoutTransactions,
    };
  }
}

class WeeklyStatistics {
  final int totalOrders;
  final double averageEarningPerOrder;
  final double averageTipPerOrder;
  final int totalBonusOrders;

  WeeklyStatistics({
    required this.totalOrders,
    required this.averageEarningPerOrder,
    required this.averageTipPerOrder,
    required this.totalBonusOrders,
  });

  factory WeeklyStatistics.fromJson(Map<String, dynamic> json) {
    return WeeklyStatistics(
      totalOrders: SafeParser.parseInt(json['total_orders']),
      averageEarningPerOrder:
          SafeParser.parseDouble(json['average_earning_per_order']),
      averageTipPerOrder: SafeParser.parseDouble(json['average_tip_per_order']),
      totalBonusOrders: SafeParser.parseInt(json['total_bonus_orders']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_orders': totalOrders,
      'average_earning_per_order': averageEarningPerOrder,
      'average_tip_per_order': averageTipPerOrder,
      'total_bonus_orders': totalBonusOrders,
    };
  }
}
