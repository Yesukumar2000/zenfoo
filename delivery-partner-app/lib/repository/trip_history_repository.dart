import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';
import 'package:zenfoo_partner/utils/safe_parser.dart';

class TripHistoryRepository {
  final ApiService _apiService = ApiService();

  /// Fetch trip history for a specific period
  Future<TripHistoryResponse> getTripHistory({
    required String period, // 'daily', 'weekly', 'monthly'
    String? date,
    int offset = 0,
    int limit = 10,
  }) async {
    try {
      final params = {
        'period': period,
        'offset': offset,
        'limit': limit,
      };

      if (date != null) {
        params['date'] = date;
      }

      final response = await _apiService.get(
        AppUrl.tripHistory,
        params: params,
      );

      return TripHistoryResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

class TripHistoryResponse {
  final int status;
  final String message;
  final TripHistoryData? data;

  TripHistoryResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory TripHistoryResponse.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'];
    return TripHistoryResponse(
      status: SafeParser.parseInt(json['status']),
      message: SafeParser.parseString(json['message']),
      data: dataJson != null ? TripHistoryData.fromJson(SafeParser.parseMap(dataJson)) : null,
    );
  }
}

class TripHistoryData {
  final String period;
  final String date;
  final DateRange dateRange;
  final Summary summary;
  final Pagination pagination;
  final List<Trip> trips;

  TripHistoryData({
    required this.period,
    required this.date,
    required this.dateRange,
    required this.summary,
    required this.pagination,
    required this.trips,
  });

  factory TripHistoryData.fromJson(Map<String, dynamic> json) {
    return TripHistoryData(
      period: SafeParser.parseString(json['period']),
      date: SafeParser.parseString(json['date']),
      dateRange: DateRange.fromJson(SafeParser.parseMap(json['date_range'])),
      summary: Summary.fromJson(SafeParser.parseMap(json['summary'])),
      pagination: Pagination.fromJson(SafeParser.parseMap(json['pagination'])),
      trips: SafeParser.parseList<Map<String, dynamic>>(json['trips'])
          .map((e) => Trip.fromJson(e))
          .toList(),
    );
  }
}

class DateRange {
  final String start;
  final String end;

  DateRange({
    required this.start,
    required this.end,
  });

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      start: SafeParser.parseString(json['start']),
      end: SafeParser.parseString(json['end']),
    );
  }
}

class Summary {
  final int totalTrips;
  final double totalDeliveryCharge;
  final double totalEarnings;
  final double totalDistanceKm;

  Summary({
    required this.totalTrips,
    required this.totalDeliveryCharge,
    required this.totalEarnings,
    required this.totalDistanceKm,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      totalTrips: SafeParser.parseInt(json['total_trips']),
      totalDeliveryCharge: SafeParser.parseDouble(json['total_delivery_charge']),
      totalEarnings: SafeParser.parseDouble(json['total_earnings']),
      totalDistanceKm: SafeParser.parseDouble(json['total_distance_km']),
    );
  }
}

class Pagination {
  final int total;
  final int limit;
  final int offset;
  final int remaining;

  Pagination({
    required this.total,
    required this.limit,
    required this.offset,
    required this.remaining,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: SafeParser.parseInt(json['total']),
      limit: SafeParser.parseInt(json['limit']),
      offset: SafeParser.parseInt(json['offset']),
      remaining: SafeParser.parseInt(json['remaining']),
    );
  }
}

class Trip {
  final int orderId;
  final String ordersId;
  final bool isMultiOrder;
  final double totalAmount;
  final double deliveryCharge;
  final double bonusAmount;
  final String deliveryTime;
  final String status;
  final String paymentMethod;
  final Customer customer;
  final List<Address> addresses;
  final int itemsCount;
  final EarningsDetails? earningsDetails;
  final DeductionsDetails? deductionsDetails;
  final CashHandling? cashHandling;
  final double distanceKm;
  final int durationMins;
  final double customerRating;
  final String customerReview;

  Trip({
    required this.orderId,
    required this.ordersId,
    required this.isMultiOrder,
    required this.totalAmount,
    required this.deliveryCharge,
    required this.bonusAmount,
    required this.deliveryTime,
    required this.status,
    required this.paymentMethod,
    required this.customer,
    required this.addresses,
    required this.itemsCount,
    this.earningsDetails,
    this.deductionsDetails,
    this.cashHandling,
    this.distanceKm = 0,
    this.durationMins = 0,
    this.customerRating = 0,
    this.customerReview = '',
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      orderId: SafeParser.parseInt(json['order_id']),
      ordersId: SafeParser.parseString(json['orders_id']),
      isMultiOrder: json['is_multi_order'] == true || json['is_multi_order'] == 1,
      totalAmount: SafeParser.parseDouble(json['total_amount']),
      deliveryCharge: SafeParser.parseDouble(json['delivery_charge']),
      bonusAmount: SafeParser.parseDouble(json['bonus_amount']),
      deliveryTime: SafeParser.parseString(json['delivery_time']),
      status: SafeParser.parseString(json['status']),
      paymentMethod: SafeParser.parseString(json['payment_method']),
      customer: Customer.fromJson(SafeParser.parseMap(json['customer'])),
      addresses: SafeParser.parseList<Map<String, dynamic>>(json['addresses'])
          .map((e) => Address.fromJson(e))
          .toList(),
      itemsCount: SafeParser.parseInt(json['items_count']),
      earningsDetails: json['earnings_details'] != null
          ? EarningsDetails.fromJson(SafeParser.parseMap(json['earnings_details']))
          : null,
      deductionsDetails: json['deductions_details'] != null
          ? DeductionsDetails.fromJson(SafeParser.parseMap(json['deductions_details']))
          : null,
      cashHandling: json['cash_handling'] != null
          ? CashHandling.fromJson(SafeParser.parseMap(json['cash_handling']))
          : null,
      distanceKm: SafeParser.parseDouble(json['distance_km']),
      durationMins: SafeParser.parseInt(json['duration_mins']),
      customerRating: SafeParser.parseDouble(json['customer_rating']),
      customerReview: SafeParser.parseString(json['customer_review']),
    );
  }

  /// Calculate total earnings (delivery charge + bonus)
  double get totalEarnings => earningsDetails?.totalTripEarning ?? 0;

  /// Get trip type based on multi-order flag
  String get tripType => isMultiOrder ? 'Multi-order' : 'Single order';

  /// Get earnings formatted as currency string
  String get earningsFormatted => '₹${totalEarnings.toInt()}';

  /// Get cash collected formatted as currency string
  String get cashCollectedFormatted => '₹${(cashHandling?.cashCollected ?? 0).toInt()}';
}

class Customer {
  final String name;
  final String phone;

  Customer({
    required this.name,
    required this.phone,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      name: SafeParser.parseString(json['name']),
      phone: SafeParser.parseString(json['phone']),
    );
  }
}

class Address {
  final String type;
  final String name;
  final String address;
  final String latLong;
  final String mobile;
  final int? sellerId;

  Address({
    required this.type,
    required this.name,
    required this.address,
    required this.latLong,
    required this.mobile,
    this.sellerId,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    final sellerId = json['seller_id'];
    return Address(
      type: SafeParser.parseString(json['type']),
      name: SafeParser.parseString(json['name']),
      address: SafeParser.parseString(json['address']),
      latLong: SafeParser.parseString(json['lat_long']),
      mobile: SafeParser.parseString(json['mobile']),
      sellerId: sellerId != null ? int.tryParse(sellerId.toString()) : null,
    );
  }
}

class EarningsDetails {
  final double baseEarning;
  final double multiOrderBonus;
  final double customerTip;
  final double gigBonus;
  final double totalTripEarning;

  EarningsDetails({
    required this.baseEarning,
    required this.multiOrderBonus,
    required this.customerTip,
    required this.gigBonus,
    required this.totalTripEarning,
  });

  factory EarningsDetails.fromJson(Map<String, dynamic> json) {
    return EarningsDetails(
      baseEarning: SafeParser.parseDouble(json['base_earning']),
      multiOrderBonus: SafeParser.parseDouble(json['multi_order_bonus']),
      customerTip: SafeParser.parseDouble(json['customer_tip']),
      gigBonus: SafeParser.parseDouble(json['gig_bonus']),
      totalTripEarning: SafeParser.parseDouble(json['total_trip_earning']),
    );
  }
}

class DeductionsDetails {
  final double lateFee;
  final double orderRelatedDeductions;
  final double totalDeductions;

  DeductionsDetails({
    required this.lateFee,
    required this.orderRelatedDeductions,
    required this.totalDeductions,
  });

  factory DeductionsDetails.fromJson(Map<String, dynamic> json) {
    return DeductionsDetails(
      lateFee: SafeParser.parseDouble(json['late_fee']),
      orderRelatedDeductions: SafeParser.parseDouble(json['order_related_deductions']),
      totalDeductions: SafeParser.parseDouble(json['total_deductions']),
    );
  }
}

class CashHandling {
  final double cashCollected;
  final double cashPaidToCompany;
  final double cashBalance;

  CashHandling({
    required this.cashCollected,
    required this.cashPaidToCompany,
    required this.cashBalance,
  });

  factory CashHandling.fromJson(Map<String, dynamic> json) {
    return CashHandling(
      cashCollected: SafeParser.parseDouble(json['cash_collected']),
      cashPaidToCompany: SafeParser.parseDouble(json['cash_paid_to_company']),
      cashBalance: SafeParser.parseDouble(json['cash_balance']),
    );
  }
}
