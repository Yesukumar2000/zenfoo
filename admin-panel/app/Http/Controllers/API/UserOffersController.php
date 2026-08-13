<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\UserOrderReward;
use App\Models\UserOfferBanner;
use App\Models\CustomerClaimedMilestone;
use App\Models\Setting;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class UserOffersController extends Controller
{
    // ==================== ORDER REWARDS ====================

    public function getOrderRewards()
    {
        $rewards = UserOrderReward::orderBy('order_count', 'ASC')->get();
        return CommonHelper::responseWithData($rewards);
    }

    public function saveOrderReward(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_count' => 'required|integer|min:1',
            'amount' => 'required|numeric|min:0',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        // Check if order_count already exists
        $exists = UserOrderReward::where('order_count', $request->order_count)->exists();
        if ($exists) {
            return CommonHelper::responseError("Order count {$request->order_count} already exists!");
        }

        $reward = new UserOrderReward();
        $reward->order_count = $request->order_count;
        $reward->amount = $request->amount;
        $reward->status = 1;
        $reward->save();

        return CommonHelper::responseSuccess("Order reward saved successfully!");
    }

    public function updateOrderReward(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|exists:user_order_rewards,id',
            'order_count' => 'required|integer|min:1',
            'amount' => 'required|numeric|min:0',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        // Check if order_count already exists for another record
        $exists = UserOrderReward::where('order_count', $request->order_count)
            ->where('id', '!=', $request->id)
            ->exists();
        if ($exists) {
            return CommonHelper::responseError("Order count {$request->order_count} already exists!");
        }

        $reward = UserOrderReward::find($request->id);

        if (!$reward) {
            return CommonHelper::responseError("Order reward not found!");
        }

        $reward->order_count = $request->order_count;
        $reward->amount = $request->amount;
        $reward->status = $request->status ?? $reward->status;
        $reward->save();

        return CommonHelper::responseSuccess("Order reward updated successfully!");
    }

    public function deleteOrderReward(Request $request)
    {
        if (isset($request->id)) {
            $reward = UserOrderReward::find($request->id);

            if ($reward) {
                $reward->delete();
                return CommonHelper::responseSuccess("Order reward deleted successfully!");
            } else {
                return CommonHelper::responseError("Order reward not found!");
            }
        }

        return CommonHelper::responseError("Invalid request!");
    }

    // ==================== OFFER BANNERS ====================

    public function getOfferBanners()
    {
        $banners = UserOfferBanner::orderBy('sort_order', 'ASC')->get();
        return CommonHelper::responseWithData($banners);
    }

    public function saveOfferBanner(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'nullable|string|max:255',
            'image' => 'required|image|mimes:jpeg,png,jpg,gif,webp|max:5120',
            'sort_order' => 'nullable|integer|min:0',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $banner = new UserOfferBanner();
        $banner->title = $request->title;
        $banner->sort_order = $request->sort_order ?? 0;
        $banner->status = 1;

        if ($request->hasFile('image')) {
            $result = MediaUploadService::uploadWithFullUrl($request->file('image'), 'user_offer_banners');
            $banner->image_url = $result['url'];
        }

        $banner->save();
        return CommonHelper::responseSuccess("Banner saved successfully!");
    }

    public function updateOfferBanner(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|exists:user_offer_banners,id',
            'title' => 'nullable|string|max:255',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:5120',
            'sort_order' => 'nullable|integer|min:0',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $banner = UserOfferBanner::find($request->id);

        if (!$banner) {
            return CommonHelper::responseError("Banner not found!");
        }

        $banner->title = $request->title ?? $banner->title;
        $banner->sort_order = $request->sort_order ?? $banner->sort_order;
        $banner->status = $request->status ?? $banner->status;

        if ($request->hasFile('image')) {
            // Delete old image using URL
            if ($banner->image_url) {
                MediaUploadService::deleteFileByUrl($banner->image_url);
            }
            $result = MediaUploadService::uploadWithFullUrl($request->file('image'), 'user_offer_banners');
            $banner->image_url = $result['url'];
        }

        $banner->save();
        return CommonHelper::responseSuccess("Banner updated successfully!");
    }

    public function deleteOfferBanner(Request $request)
    {
        if (isset($request->id)) {
            $banner = UserOfferBanner::find($request->id);

            if ($banner) {
                // Delete image using URL
                if ($banner->image_url) {
                    MediaUploadService::deleteFileByUrl($banner->image_url);
                }
                $banner->delete();
                return CommonHelper::responseSuccess("Banner deleted successfully!");
            } else {
                return CommonHelper::responseError("Banner not found!");
            }
        }

        return CommonHelper::responseError("Invalid request!");
    }

    // ==================== CLAIMABLE BANNER SETTING ====================

    /**
     * Get the offer claimable banner URL from settings
     */
    public function getClaimableBanner()
    {
        $bannerUrl = Setting::get_value('offer_claimable_banner');
        return CommonHelper::responseWithData([
            'offer_claimable_banner' => $bannerUrl
        ]);
    }

    /**
     * Upload and save the offer claimable banner
     */
    public function saveClaimableBanner(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'image' => 'required|image|mimes:jpeg,png,jpg,gif,webp|max:5120',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            // Get the old banner URL to delete
            $oldBannerUrl = Setting::get_value('offer_claimable_banner');

            // Delete old image if exists
            if ($oldBannerUrl) {
                MediaUploadService::deleteFileByUrl($oldBannerUrl);
            }

            // Upload new image
            $result = MediaUploadService::uploadWithFullUrl($request->file('image'), 'offer_claimable_banners');
            $newBannerUrl = $result['url'];

            // Update the setting
            Setting::update_value('offer_claimable_banner', $newBannerUrl);

            return CommonHelper::responseWithData([
                'message' => 'Claimable banner saved successfully!',
                'offer_claimable_banner' => $newBannerUrl
            ]);
        } catch (\Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Delete the offer claimable banner
     */
    public function deleteClaimableBanner()
    {
        try {
            $bannerUrl = Setting::get_value('offer_claimable_banner');

            if ($bannerUrl) {
                // Delete the image file
                MediaUploadService::deleteFileByUrl($bannerUrl);

                // Clear the setting value
                Setting::update_value('offer_claimable_banner', '');
            }

            return CommonHelper::responseSuccess("Claimable banner deleted successfully!");
        } catch (\Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    // ==================== CLAIMED MILESTONES (ADMIN VIEW) ====================

    public function getClaimedMilestones(Request $request)
    {
        $perPage = $request->per_page ?? 5;
        $page = $request->page ?? 1;

        // Get customer IDs sorted by most milestones used (status = 'used') first
        $customerIds = CustomerClaimedMilestone::select('customer_id')
            ->selectRaw("COUNT(*) as total_milestones")
            ->selectRaw("SUM(CASE WHEN status = 'used' THEN 1 ELSE 0 END) as used_count")
            ->groupBy('customer_id')
            ->orderByDesc('used_count')
            ->orderByDesc('total_milestones')
            ->paginate($perPage, ['*'], 'page', $page);

        $ids = $customerIds->pluck('customer_id')->toArray();

        // Fetch all claimed milestones for these customers
        $allClaims = CustomerClaimedMilestone::with(['milestone:id,order_count,amount'])
            ->whereIn('customer_id', $ids)
            ->orderByDesc('id')
            ->get()
            ->groupBy('customer_id');

        // Fetch customer details
        $customers = \App\Models\User::whereIn('id', $ids)->get()->keyBy('id');

        // Build grouped response maintaining the sort order
        $rows = [];
        foreach ($customerIds as $row) {
            $customerId = $row->customer_id;
            $customer = $customers->get($customerId);
            $claims = $allClaims->get($customerId, collect());

            $milestones = $claims->map(function ($claim) {
                return [
                    'id' => $claim->id,
                    'milestone_order_count' => $claim->milestone->order_count ?? '-',
                    'reward_amount' => $claim->reward_amount,
                    'status' => $claim->status,
                    'claimed_date' => $claim->claimed_date ? $claim->claimed_date->format('d M Y') : '-',
                    'used_in_order_id' => $claim->used_in_order_id,
                    'used_date' => $claim->used_date ? $claim->used_date->format('d M Y') : '-',
                ];
            })->values();

            $rows[] = [
                'customer_id' => $customerId,
                'customer_name' => $customer->name ?? 'N/A',
                'customer_mobile' => $customer->mobile ?? 'N/A',
                'total_milestones' => $claims->count(),
                'used_count' => $claims->where('status', 'used')->count(),
                'claimed_count' => $claims->where('status', 'claimed')->count(),
                'total_reward' => $claims->sum('reward_amount'),
                'milestones' => $milestones,
            ];
        }

        return CommonHelper::responseWithData([
            'rows' => $rows,
            'pagination' => [
                'current_page' => $customerIds->currentPage(),
                'last_page' => $customerIds->lastPage(),
                'per_page' => $customerIds->perPage(),
                'total' => $customerIds->total(),
            ],
        ]);
    }
}
