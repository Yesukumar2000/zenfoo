import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/incentive_offer_model.dart';
import 'package:zenfoo_partner/repository/incentive_repository.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'dart:developer' as dev;

class IncentiveProvider with ChangeNotifier {
  final IncentiveRepository _incentiveRepository = IncentiveRepository();

  // State for active offers
  ApiResponse<List<IncentiveOffer>> activeOffersState = ApiResponse.nothing();
  List<IncentiveOffer> _activeOffers = [];
  List<IncentiveOffer> get activeOffers => _activeOffers;

  // State for all offers
  ApiResponse<List<IncentiveOffer>> allOffersState = ApiResponse.nothing();
  List<IncentiveOffer> _allOffers = [];
  List<IncentiveOffer> get allOffers => _allOffers;

  // State for single offer details
  ApiResponse<IncentiveOffer> offerDetailsState = ApiResponse.nothing();
  IncentiveOffer? _currentOfferDetails;
  IncentiveOffer? get currentOfferDetails => _currentOfferDetails;

  // State for user's offer progress
  ApiResponse<OfferProgress> offerProgressState = ApiResponse.nothing();
  OfferProgress? _currentOfferProgress;
  OfferProgress? get currentOfferProgress => _currentOfferProgress;

  // State for grouped offers (active, upcoming, expired)
  String _groupedOffersStatus = ApiStatus.nothing;
  String _groupedOffersError = '';
  List<IncentiveOffer> _groupedActiveOffers = [];
  List<IncentiveOffer> _groupedUpcomingOffers = [];
  List<IncentiveOffer> _groupedExpiredOffers = [];

  String get groupedOffersStatus => _groupedOffersStatus;
  String get groupedOffersError => _groupedOffersError;
  List<IncentiveOffer> get groupedActiveOffers => _groupedActiveOffers;
  List<IncentiveOffer> get groupedUpcomingOffers => _groupedUpcomingOffers;
  List<IncentiveOffer> get groupedExpiredOffers => _groupedExpiredOffers;
  bool get isGroupedOffersLoading => _groupedOffersStatus == ApiStatus.loading;

  /// Get all active incentive offers
  Future<void> getActiveOffers() async {
    dev.log('🔵 Starting getActiveOffers()', name: 'IncentiveProvider');
    activeOffersState = ApiResponse.loading();
    notifyListeners();

    // try {
    final response = await _incentiveRepository.getActiveOffers();
    dev.log('📥 Repository response status: ${response.status}',
        name: 'IncentiveProvider');

    if (response.status == ApiStatus.success) {
      final data = response.data;
      dev.log('📦 Response data type: ${data.runtimeType}',
          name: 'IncentiveProvider');
      dev.log('📦 Response data: ${jsonEncode(data)}',
          name: 'IncentiveProvider');

      // API response structure: { data: { offers: [...] } }
      if (data != null &&
          data['data'] != null &&
          data['data']['offers'] != null) {
        final offersList = data['data']['offers'] as List;
        dev.log('✅ Found ${offersList.length} offers in response',
            name: 'IncentiveProvider');

        _activeOffers = offersList.map((offerJson) {
          dev.log('🔄 Parsing offer: ${jsonEncode(offerJson)}',
              name: 'IncentiveProvider');
          return IncentiveOffer.fromJson(offerJson);
        }).toList();

        dev.log('✅ Successfully parsed ${_activeOffers.length} offers',
            name: 'IncentiveProvider');
        dev.log(
            '📋 First offer: ${_activeOffers.isNotEmpty ? _activeOffers.first.name : "none"}',
            name: 'IncentiveProvider');

        activeOffersState = ApiResponse.success(_activeOffers);
      } else {
        dev.log('⚠️ Response structure is invalid', name: 'IncentiveProvider');
        dev.log('  - data is null: ${data == null}', name: 'IncentiveProvider');
        dev.log(
            '  - data["data"] is null: ${data != null && data["data"] == null}',
            name: 'IncentiveProvider');
        dev.log(
            '  - data["data"]["offers"] is null: ${data != null && data["data"] != null && data["data"]["offers"] == null}',
            name: 'IncentiveProvider');

        _activeOffers = [];
        activeOffersState = ApiResponse.success(_activeOffers);
      }
    } else {
      dev.log('❌ API response error: ${response.message}',
          name: 'IncentiveProvider');
      activeOffersState =
          ApiResponse.error(response.message ?? 'Failed to load offers');
    }
    // } catch (e, stackTrace) {
    //   dev.log('💥 Exception in getActiveOffers: $e', name: 'IncentiveProvider');
    //   dev.log('Stack trace: $stackTrace', name: 'IncentiveProvider');
    //   activeOffersState = ApiResponse.error(e.toString());
    // }

    dev.log('🏁 Final state - offers count: ${_activeOffers.length}',
        name: 'IncentiveProvider');
    notifyListeners();
  }

  /// Get details of a specific offer
  Future<void> getOfferDetails({required int offerId}) async {
    dev.log('🔵 Starting getOfferDetails for offer $offerId',
        name: 'IncentiveProvider');
    offerDetailsState = ApiResponse.loading();
    notifyListeners();

    try {
      final response =
          await _incentiveRepository.getOfferDetails(offerId: offerId);

      dev.log('📥 Offer details response status: ${response.status}',
          name: 'IncentiveProvider');

      if (response.status == ApiStatus.success) {
        final data = response.data;
        dev.log('📦 Offer details data: ${jsonEncode(data)}',
            name: 'IncentiveProvider');

        // API response structure: { data: { offer_id, name, tiers, my_progress, ... } }
        if (data != null && data['data'] != null) {
          final offerData = data['data'];
          dev.log('✅ Found offer data, parsing...', name: 'IncentiveProvider');

          _currentOfferDetails = IncentiveOffer.fromJson(offerData);
          offerDetailsState = ApiResponse.success(_currentOfferDetails);

          dev.log('✅ Offer parsed: ${_currentOfferDetails!.name}',
              name: 'IncentiveProvider');
        } else {
          dev.log('⚠️ Offer data not found in response',
              name: 'IncentiveProvider');
          offerDetailsState = ApiResponse.error('Offer not found');
        }
      } else {
        dev.log('❌ API error: ${response.message}', name: 'IncentiveProvider');
        offerDetailsState = ApiResponse.error(
            response.message ?? 'Failed to load offer details');
      }
    } catch (e, stackTrace) {
      dev.log('💥 Exception in getOfferDetails: $e', name: 'IncentiveProvider');
      dev.log('Stack trace: $stackTrace', name: 'IncentiveProvider');
      offerDetailsState = ApiResponse.error(e.toString());
    }

    notifyListeners();
  }

  /// Get user's progress for a specific offer
  Future<void> getMyOfferProgress({required int offerId}) async {
    dev.log('🔵 Starting getMyOfferProgress for offer $offerId',
        name: 'IncentiveProvider');
    offerProgressState = ApiResponse.loading();
    notifyListeners();

    try {
      final response =
          await _incentiveRepository.getMyOfferProgress(offerId: offerId);

      dev.log('📥 Progress response status: ${response.status}',
          name: 'IncentiveProvider');

      if (response.status == ApiStatus.success) {
        final data = response.data;
        dev.log('📦 Progress data: ${jsonEncode(data)}',
            name: 'IncentiveProvider');

        // API response structure: { data: { my_progress: { ... } } }
        if (data != null &&
            data['data'] != null &&
            data['data']['my_progress'] != null) {
          _currentOfferProgress =
              OfferProgress.fromJson(data['data']['my_progress']);
          offerProgressState = ApiResponse.success(_currentOfferProgress);

          dev.log(
              '✅ Progress parsed: ${_currentOfferProgress!.currentEarnings} earnings',
              name: 'IncentiveProvider');
        } else {
          dev.log('⚠️ Progress data not found in response',
              name: 'IncentiveProvider');
          offerProgressState = ApiResponse.error('Progress data not found');
        }
      } else {
        dev.log('❌ API error: ${response.message}', name: 'IncentiveProvider');
        offerProgressState =
            ApiResponse.error(response.message ?? 'Failed to load progress');
      }
    } catch (e, stackTrace) {
      dev.log('💥 Exception in getMyOfferProgress: $e',
          name: 'IncentiveProvider');
      dev.log('Stack trace: $stackTrace', name: 'IncentiveProvider');
      offerProgressState = ApiResponse.error(e.toString());
    }

    notifyListeners();
  }

  /// Get all offers (active + expired)
  Future<void> getAllOffers({bool includeExpired = false}) async {
    allOffersState = ApiResponse.loading();
    notifyListeners();

    try {
      final response = await _incentiveRepository.getAllOffers(
        includeExpired: includeExpired,
      );

      if (response.status == ApiStatus.success) {
        final data = response.data;
        if (data != null && data['offers'] != null) {
          _allOffers = (data['offers'] as List)
              .map((offerJson) => IncentiveOffer.fromJson(offerJson))
              .toList();
          allOffersState = ApiResponse.success(_allOffers);
        } else {
          _allOffers = [];
          allOffersState = ApiResponse.success(_allOffers);
        }
      } else {
        allOffersState =
            ApiResponse.error(response.message ?? 'Failed to load all offers');
      }
    } catch (e) {
      allOffersState = ApiResponse.error(e.toString());
    }

    notifyListeners();
  }

  // Current filter for grouped offers
  String? _currentFilter;
  String? _currentFilterDate;
  String? get currentFilter => _currentFilter;
  String? get currentFilterDate => _currentFilterDate;

  /// Get all offers grouped by status (active, upcoming, expired)
  /// Returns offers already categorized by the API
  /// Parameters:
  /// - filter: Optional filter (daily, weekly, monthly)
  /// - date: Optional specific date (yyyy-MM-dd)
  Future<void> getAllOffersGrouped({String? filter, String? date}) async {
    dev.log('🔵 Starting getAllOffersGrouped(filter: $filter, date: $date)',
        name: 'IncentiveProvider');
    _groupedOffersStatus = ApiStatus.loading;
    _groupedOffersError = '';
    _currentFilter = filter;
    _currentFilterDate = date;
    notifyListeners();

    try {
      final response = await _incentiveRepository.getAllOffersGrouped(
        filter: filter,
        date: date,
      );
      dev.log('📥 Repository response received', name: 'IncentiveProvider');
      dev.log(
          '✅ Active: ${response.activeOffers.length}, Upcoming: ${response.upcomingOffers.length}, Expired: ${response.expiredOffers.length}',
          name: 'IncentiveProvider');

      _groupedActiveOffers = response.activeOffers;
      _groupedUpcomingOffers = response.upcomingOffers;
      _groupedExpiredOffers = response.expiredOffers;
      _groupedOffersStatus = ApiStatus.success;
    } catch (e, stackTrace) {
      dev.log('💥 Exception in getAllOffersGrouped: $e',
          name: 'IncentiveProvider');
      dev.log('Stack trace: $stackTrace', name: 'IncentiveProvider');
      _groupedOffersStatus = ApiStatus.error;
      _groupedOffersError = e.toString();
    }

    dev.log('🏁 Final state - status: $_groupedOffersStatus',
        name: 'IncentiveProvider');
    notifyListeners();
  }

  /// Reset all states
  void resetStates() {
    activeOffersState = ApiResponse.nothing();
    allOffersState = ApiResponse.nothing();
    offerDetailsState = ApiResponse.nothing();
    offerProgressState = ApiResponse.nothing();

    _activeOffers = [];
    _allOffers = [];
    _currentOfferDetails = null;
    _currentOfferProgress = null;

    _groupedOffersStatus = ApiStatus.nothing;
    _groupedOffersError = '';
    _groupedActiveOffers = [];
    _groupedUpcomingOffers = [];
    _groupedExpiredOffers = [];

    notifyListeners();
  }
}
