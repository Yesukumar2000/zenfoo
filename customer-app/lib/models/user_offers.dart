class UserOffersResponse {
  int? status;
  String? message;
  int? total;
  UserOffersData? data;

  UserOffersResponse({this.status, this.message, this.total, this.data});

  UserOffersResponse.fromJson(Map<String, dynamic> json) {
    status = int.tryParse(json['status']?.toString() ?? '') ?? 0;
    message = json['message']?.toString() ?? '';
    total = int.tryParse(json['total']?.toString() ?? '') ?? 0;
    data = json['data'] != null ? UserOffersData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    data['total'] = total;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class UserOffersData {
  int? completedOrdersCount;
  Milestone? lastMilestone;
  List<Milestone>? milestones;
  List<OfferBanner>? banners;
  String? claimableBanner;
  List<ClaimedMilestone>? claimedMilestones;

  UserOffersData({
    this.completedOrdersCount,
    this.lastMilestone,
    this.milestones,
    this.banners,
    this.claimableBanner,
    this.claimedMilestones,
  });

  UserOffersData.fromJson(Map<String, dynamic> json) {
    completedOrdersCount = int.tryParse(json['completed_orders_count']?.toString() ?? '') ?? 0;
    lastMilestone = json['last_milestone'] != null
        ? Milestone.fromJson(json['last_milestone'])
        : null;
    if (json['milestones'] != null) {
      milestones = <Milestone>[];
      json['milestones'].forEach((v) {
        milestones!.add(Milestone.fromJson(v));
      });
    }
    if (json['banners'] != null) {
      banners = <OfferBanner>[];
      json['banners'].forEach((v) {
        banners!.add(OfferBanner.fromJson(v));
      });
    }
    claimableBanner = json['claimable_banner']?.toString() ?? "";
    if (json['claimed_milestones'] != null) {
      claimedMilestones = <ClaimedMilestone>[];
      json['claimed_milestones'].forEach((v) {
        claimedMilestones!.add(ClaimedMilestone.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['completed_orders_count'] = completedOrdersCount;
    if (lastMilestone != null) {
      data['last_milestone'] = lastMilestone!.toJson();
    }
    if (milestones != null) {
      data['milestones'] = milestones!.map((v) => v.toJson()).toList();
    }
    if (banners != null) {
      data['banners'] = banners!.map((v) => v.toJson()).toList();
    }
    data['claimable_banner'] = claimableBanner;
    if (claimedMilestones != null) {
      data['claimed_milestones'] =
          claimedMilestones!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Milestone {
  int? id;
  int? orderCount;
  String? amount;
  bool? isEligible;
  bool? isClaimed;
  bool? canClaim;

  Milestone({
    this.id,
    this.orderCount,
    this.amount,
    this.isEligible,
    this.isClaimed,
    this.canClaim,
  });

  Milestone.fromJson(Map<String, dynamic> json) {
    id = int.tryParse(json['id']?.toString() ?? '') ?? 0;
    orderCount = int.tryParse(json['order_count']?.toString() ?? '') ?? 0;
    amount = json['amount']?.toString() ?? "0";
    isEligible = _parseBool(json['is_eligible']);
    isClaimed = _parseBool(json['is_claimed']);
    canClaim = _parseBool(json['can_claim']);
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == '1' || normalized == 'true';
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['order_count'] = orderCount;
    data['amount'] = amount;
    data['is_eligible'] = isEligible;
    data['is_claimed'] = isClaimed;
    data['can_claim'] = canClaim;
    return data;
  }
}

class OfferBanner {
  int? id;
  String? title;
  String? imageUrl;
  int? sortOrder;
  bool? status;
  String? createdAt;
  String? updatedAt;

  OfferBanner({
    this.id,
    this.title,
    this.imageUrl,
    this.sortOrder,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  OfferBanner.fromJson(Map<String, dynamic> json) {
    id = int.tryParse(json['id']?.toString() ?? '') ?? 0;
    title = json['title']?.toString() ?? "";
    imageUrl = json['image_url']?.toString() ?? "";
    sortOrder = int.tryParse(json['sort_order']?.toString() ?? '') ?? 0;
    status = json['status'] == true || json['status']?.toString() == '1';
    createdAt = json['created_at']?.toString() ?? "";
    updatedAt = json['updated_at']?.toString() ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['image_url'] = imageUrl;
    data['sort_order'] = sortOrder;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class ClaimedMilestone {
  int? id;
  int? customerId;
  int? milestoneId;
  Map<String, dynamic>? milestoneMetaData;
  String? claimedDate;
  String? rewardAmount;
  String? status;
  int? usedInOrderId;
  String? usedDate;
  String? createdAt;
  String? updatedAt;

  ClaimedMilestone({
    this.id,
    this.customerId,
    this.milestoneId,
    this.milestoneMetaData,
    this.claimedDate,
    this.rewardAmount,
    this.status,
    this.usedInOrderId,
    this.usedDate,
    this.createdAt,
    this.updatedAt,
  });

  ClaimedMilestone.fromJson(Map<String, dynamic> json) {
    id = int.tryParse(json['id']?.toString() ?? '') ?? 0;
    customerId = int.tryParse(json['customer_id']?.toString() ?? '') ?? 0;
    milestoneId = int.tryParse(json['milestone_id']?.toString() ?? '') ?? 0;
    milestoneMetaData = json['milestone_meta_data'] is Map<String, dynamic>
        ? json['milestone_meta_data']
        : null;
    claimedDate = json['claimed_date']?.toString() ?? "";
    rewardAmount = json['reward_amount']?.toString() ?? "0";
    status = json['status']?.toString() ?? "";
    usedInOrderId = int.tryParse(json['used_in_order_id']?.toString() ?? '');
    usedDate = json['used_date']?.toString() ?? "";
    createdAt = json['created_at']?.toString() ?? "";
    updatedAt = json['updated_at']?.toString() ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['customer_id'] = customerId;
    data['milestone_id'] = milestoneId;
    data['milestone_meta_data'] = milestoneMetaData;
    data['claimed_date'] = claimedDate;
    data['reward_amount'] = rewardAmount;
    data['status'] = status;
    data['used_in_order_id'] = usedInOrderId;
    data['used_date'] = usedDate;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }

  // Helper to get order count from metadata
  int get orderCountAtClaim =>
      int.tryParse(milestoneMetaData?['claimed_at_orders_count']?.toString() ?? '') ?? 0;

  // Helper to get milestone order count from metadata
  int get milestoneOrderCount =>
      int.tryParse(milestoneMetaData?['order_count']?.toString() ?? '') ?? 0;
}
