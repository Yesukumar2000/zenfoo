import 'package:flutter/material.dart';
import 'package:project/models/brand_campaign.dart';
import 'package:project/models/productListItem.dart';
import 'package:project/repositories/brandCampaignApi.dart';

enum BrandCampaignState { initial, loading, loaded, error }

class BrandCampaignProvider extends ChangeNotifier {
  BrandCampaignState state = BrandCampaignState.initial;
  BrandCampaign? campaignData;
  String message = "";

  Future<void> fetchCampaign(BuildContext context) async {
    state = BrandCampaignState.loading;
    notifyListeners();

    try {
      debugPrint("🔄 Fetching brand campaign...");
      final response = await getBrandCampaignDetails(context: context);

      debugPrint("✅ Campaign response: $response");

      if (response['status'] == 1) {
        campaignData = BrandCampaign.fromJson(response);
        state = BrandCampaignState.loaded;
        debugPrint("✅ Campaign loaded successfully: ${campaignData?.data?.campaign?.name}");
        debugPrint("🖼️ Primary image URL: ${campaignData?.data?.campaign?.primaryImageUrl}");
        debugPrint("🖼️ Secondary image URL: ${campaignData?.data?.campaign?.secondaryImageUrl}");
      } else {
        message = response['message'] ?? "Failed to load campaign";
        state = BrandCampaignState.error;
        debugPrint("❌ Campaign failed with status: ${response['status']}, message: ${response['message']}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching brand campaign: $e");
      message = e.toString();
      state = BrandCampaignState.error;
    }

    notifyListeners();
  }

  bool get hasCampaign => campaignData?.isValid ?? false;

  Campaign? get campaign => campaignData?.data?.campaign;

  List<ProductListItem> get products => campaignData?.data?.latestProducts ?? [];

  List<ProductListItem> get latestProducts =>
      campaignData?.data?.latestProducts ?? [];

  List<ProductListItem> get otherProducts =>
      campaignData?.data?.otherProducts ?? [];

  int get productsCount => campaignData?.data?.productsCount ?? 0;

  int get daysUntilExpiry => campaignData?.data?.daysUntilExpiry ?? 0;

  bool get isLoading => state == BrandCampaignState.loading;

  bool get isError => state == BrandCampaignState.error;
}
