import 'package:flutter/material.dart';
import 'package:project/models/user_offers.dart';
import 'package:project/repositories/userOffersApi.dart';

enum UserOffersState { initial, loading, loaded, error }

class UserOffersProvider extends ChangeNotifier {
  UserOffersState state = UserOffersState.initial;
  UserOffersData? offersData;
  String message = "";

  Future<void> fetchUserOffers(BuildContext context) async {
    state = UserOffersState.loading;
    notifyListeners();

    try {
      final response = await getUserOffers(context: context);

      if (response['status'] == 1) {
        final offersResponse = UserOffersResponse.fromJson(response);
        offersData = offersResponse.data;
        state = UserOffersState.loaded;
      } else {
        message = response['message'] ?? "Failed to load offers";
        state = UserOffersState.error;
      }
    } catch (e) {
      debugPrint("❌ Error fetching user offers: $e");
      message = e.toString();
      state = UserOffersState.error;
    }

    notifyListeners();
  }

  int get completedOrders => offersData?.completedOrdersCount ?? 0;

  List<Milestone> get milestones => offersData?.milestones ?? [];

  List<OfferBanner> get banners => offersData?.banners ?? [];

  String get claimableBannerUrl => offersData?.claimableBanner ?? "";

  List<ClaimedMilestone> get claimedMilestones =>
      offersData?.claimedMilestones ?? [];

  Milestone? get nextMilestone {
    final unclaimed = milestones.where((m) => !m.isClaimed!).toList();
    if (unclaimed.isEmpty) return null;
    unclaimed.sort((a, b) => a.orderCount!.compareTo(b.orderCount!));
    return unclaimed.first;
  }

  int get ordersUntilNextReward {
    final next = nextMilestone;
    if (next == null) return 0;
    return (next.orderCount! - completedOrders).clamp(0, 999);
  }
}
