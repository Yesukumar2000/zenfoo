class PerformanceEarnings {
  final String periodType;
  final DateTime date;
  final DateTime? weekStart;
  final DateTime? weekEnd;
  final String? month;
  final DateTime? monthStart;
  final DateTime? monthEnd;
  final EarningsOverview earningsOverview;
  final TodaysPerformance todaysPerformance;
  final List<EarningsBreakdownItem> earningsBreakdown;
  final AvailableDates availableDates;
  final List<DailyBreakdown>? dailyBreakdown;
  final List<WeeklyBreakdown>? weeklyBreakdown;

  PerformanceEarnings({
    required this.periodType,
    required this.date,
    this.weekStart,
    this.weekEnd,
    this.month,
    this.monthStart,
    this.monthEnd,
    required this.earningsOverview,
    required this.todaysPerformance,
    required this.earningsBreakdown,
    required this.availableDates,
    this.dailyBreakdown,
    this.weeklyBreakdown,
  });

  factory PerformanceEarnings.fromJson(Map<String, dynamic> json) {
    return PerformanceEarnings(
      periodType: json['period_type'] ?? 'daily',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      weekStart: json['week_start'] != null ? DateTime.parse(json['week_start']) : null,
      weekEnd: json['week_end'] != null ? DateTime.parse(json['week_end']) : null,
      month: json['month'],
      monthStart: json['month_start'] != null ? DateTime.parse(json['month_start']) : null,
      monthEnd: json['month_end'] != null ? DateTime.parse(json['month_end']) : null,
      earningsOverview: EarningsOverview.fromJson(json['earnings_overview'] ?? {}),
      todaysPerformance: TodaysPerformance.fromJson(json['todays_performance'] ?? {}),
      earningsBreakdown: (json['earnings_breakdown'] as List?)
              ?.map((item) => EarningsBreakdownItem.fromJson(item))
              .toList() ??
          [],
      availableDates: AvailableDates.fromJson(json['available_dates'] ?? {}),
      dailyBreakdown: (json['daily_breakdown'] as List?)
          ?.map((item) => DailyBreakdown.fromJson(item))
          .toList(),
      weeklyBreakdown: (json['weekly_breakdown'] as List?)
          ?.map((item) => WeeklyBreakdown.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period_type': periodType,
      'date': date.toIso8601String(),
      'week_start': weekStart?.toIso8601String(),
      'week_end': weekEnd?.toIso8601String(),
      'month': month,
      'month_start': monthStart?.toIso8601String(),
      'month_end': monthEnd?.toIso8601String(),
      'earnings_overview': earningsOverview.toJson(),
      'todays_performance': todaysPerformance.toJson(),
      'earnings_breakdown': earningsBreakdown.map((item) => item.toJson()).toList(),
      'available_dates': availableDates.toJson(),
      'daily_breakdown': dailyBreakdown?.map((item) => item.toJson()).toList(),
      'weekly_breakdown': weeklyBreakdown?.map((item) => item.toJson()).toList(),
    };
  }
}

class EarningsOverview {
  final double totalEarnings;
  final double orderEarnings;
  final double multiOrderEarnings;
  final double incentiveEarnings;
  final double referralBonus;
  final double tips;

  EarningsOverview({
    required this.totalEarnings,
    required this.orderEarnings,
    required this.multiOrderEarnings,
    required this.incentiveEarnings,
    required this.referralBonus,
    required this.tips,
  });

  factory EarningsOverview.fromJson(Map<String, dynamic> json) {
    return EarningsOverview(
      totalEarnings: (json['total_earnings'] ?? 0).toDouble(),
      orderEarnings: (json['order_earnings'] ?? 0).toDouble(),
      multiOrderEarnings: (json['multi_order_earnings'] ?? 0).toDouble(),
      incentiveEarnings: (json['incentive_earnings'] ?? 0).toDouble(),
      referralBonus: (json['referral_bonus'] ?? 0).toDouble(),
      tips: (json['tips'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_earnings': totalEarnings,
      'order_earnings': orderEarnings,
      'multi_order_earnings': multiOrderEarnings,
      'incentive_earnings': incentiveEarnings,
      'referral_bonus': referralBonus,
      'tips': tips,
    };
  }
}

class TodaysPerformance {
  final double distanceCovered;
  final int totalOrders;
  final int ordersCompleted;
  final int ordersCancelled;
  final String loginHours;

  TodaysPerformance({
    required this.distanceCovered,
    required this.totalOrders,
    required this.ordersCompleted,
    required this.ordersCancelled,
    required this.loginHours,
  });

  factory TodaysPerformance.fromJson(Map<String, dynamic> json) {
    return TodaysPerformance(
      distanceCovered: (json['distance_covered'] ?? 0).toDouble(),
      totalOrders: json['total_orders'] ?? 0,
      ordersCompleted: json['orders_completed'] ?? 0,
      ordersCancelled: json['orders_cancelled'] ?? 0,
      loginHours: json['login_hours'] ?? '00:00:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distance_covered': distanceCovered,
      'total_orders': totalOrders,
      'orders_completed': ordersCompleted,
      'orders_cancelled': ordersCancelled,
      'login_hours': loginHours,
    };
  }
}

class EarningsBreakdownItem {
  final String name;
  final String description;
  final double amount;
  final double percentage;
  final String icon;

  EarningsBreakdownItem({
    required this.name,
    required this.description,
    required this.amount,
    required this.percentage,
    required this.icon,
  });

  factory EarningsBreakdownItem.fromJson(Map<String, dynamic> json) {
    return EarningsBreakdownItem(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
      icon: json['icon'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'amount': amount,
      'percentage': percentage,
      'icon': icon,
    };
  }
}

class AvailableDates {
  final String type;
  final String? currentDate;
  final String? previousDate;
  final String? nextDate;
  final String? currentWeekStart;
  final String? previousWeekStart;
  final String? nextWeekStart;
  final String? currentMonth;
  final String? previousMonth;
  final String? nextMonth;
  final List<String> dates;

  AvailableDates({
    required this.type,
    this.currentDate,
    this.previousDate,
    this.nextDate,
    this.currentWeekStart,
    this.previousWeekStart,
    this.nextWeekStart,
    this.currentMonth,
    this.previousMonth,
    this.nextMonth,
    required this.dates,
  });

  factory AvailableDates.fromJson(Map<String, dynamic> json) {
    return AvailableDates(
      type: json['type'] ?? 'daily',
      currentDate: json['current_date'],
      previousDate: json['previous_date'],
      nextDate: json['next_date'],
      currentWeekStart: json['current_week_start'],
      previousWeekStart: json['previous_week_start'],
      nextWeekStart: json['next_week_start'],
      currentMonth: json['current_month'],
      previousMonth: json['previous_month'],
      nextMonth: json['next_month'],
      dates: List<String>.from(json['dates'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'current_date': currentDate,
      'previous_date': previousDate,
      'next_date': nextDate,
      'current_week_start': currentWeekStart,
      'previous_week_start': previousWeekStart,
      'next_week_start': nextWeekStart,
      'current_month': currentMonth,
      'previous_month': previousMonth,
      'next_month': nextMonth,
      'dates': dates,
    };
  }
}

class DailyBreakdown {
  final String date;
  final String dayName;
  final int dayNumber;
  final double totalEarnings;
  final double orderEarnings;
  final double multiOrderEarnings;
  final double incentiveEarnings;
  final double tips;
  final int totalOrders;
  final int ordersCompleted;
  final int ordersCancelled;
  final double distanceCovered;
  final String loginHours;

  DailyBreakdown({
    required this.date,
    required this.dayName,
    required this.dayNumber,
    required this.totalEarnings,
    required this.orderEarnings,
    required this.multiOrderEarnings,
    required this.incentiveEarnings,
    required this.tips,
    required this.totalOrders,
    required this.ordersCompleted,
    required this.ordersCancelled,
    required this.distanceCovered,
    required this.loginHours,
  });

  factory DailyBreakdown.fromJson(Map<String, dynamic> json) {
    return DailyBreakdown(
      date: json['date'] ?? '',
      dayName: json['day_name'] ?? '',
      dayNumber: json['day_number'] ?? 0,
      totalEarnings: (json['total_earnings'] ?? 0).toDouble(),
      orderEarnings: (json['order_earnings'] ?? 0).toDouble(),
      multiOrderEarnings: (json['multi_order_earnings'] ?? 0).toDouble(),
      incentiveEarnings: (json['incentive_earnings'] ?? 0).toDouble(),
      tips: (json['tips'] ?? 0).toDouble(),
      totalOrders: json['total_orders'] ?? 0,
      ordersCompleted: json['orders_completed'] ?? 0,
      ordersCancelled: json['orders_cancelled'] ?? 0,
      distanceCovered: (json['distance_covered'] ?? 0).toDouble(),
      loginHours: json['login_hours'] ?? '00:00:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'day_name': dayName,
      'day_number': dayNumber,
      'total_earnings': totalEarnings,
      'order_earnings': orderEarnings,
      'multi_order_earnings': multiOrderEarnings,
      'incentive_earnings': incentiveEarnings,
      'tips': tips,
      'total_orders': totalOrders,
      'orders_completed': ordersCompleted,
      'orders_cancelled': ordersCancelled,
      'distance_covered': distanceCovered,
      'login_hours': loginHours,
    };
  }
}

class WeeklyBreakdown {
  final String week;
  final String startDate;
  final String endDate;
  final double earnings;
  final double orderEarnings;
  final double multiOrderEarnings;
  final double incentiveEarnings;
  final double tips;
  final int orders;
  final int ordersCompleted;
  final int ordersCancelled;
  final double distance;
  final String loginHours;

  WeeklyBreakdown({
    required this.week,
    required this.startDate,
    required this.endDate,
    required this.earnings,
    required this.orderEarnings,
    required this.multiOrderEarnings,
    required this.incentiveEarnings,
    required this.tips,
    required this.orders,
    required this.ordersCompleted,
    required this.ordersCancelled,
    required this.distance,
    required this.loginHours,
  });

  factory WeeklyBreakdown.fromJson(Map<String, dynamic> json) {
    return WeeklyBreakdown(
      week: json['week'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      earnings: (json['earnings'] ?? 0).toDouble(),
      orderEarnings: (json['order_earnings'] ?? 0).toDouble(),
      multiOrderEarnings: (json['multi_order_earnings'] ?? 0).toDouble(),
      incentiveEarnings: (json['incentive_earnings'] ?? 0).toDouble(),
      tips: (json['tips'] ?? 0).toDouble(),
      orders: json['orders'] ?? 0,
      ordersCompleted: json['orders_completed'] ?? 0,
      ordersCancelled: json['orders_cancelled'] ?? 0,
      distance: (json['distance'] ?? 0).toDouble(),
      loginHours: json['login_hours'] ?? '00:00:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'week': week,
      'start_date': startDate,
      'end_date': endDate,
      'earnings': earnings,
      'order_earnings': orderEarnings,
      'multi_order_earnings': multiOrderEarnings,
      'incentive_earnings': incentiveEarnings,
      'tips': tips,
      'orders': orders,
      'orders_completed': ordersCompleted,
      'orders_cancelled': ordersCancelled,
      'distance': distance,
      'login_hours': loginHours,
    };
  }
}
