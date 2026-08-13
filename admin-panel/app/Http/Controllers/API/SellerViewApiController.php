<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\Seller;
use App\Models\SubCategoryGroup;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SellerViewApiController extends Controller
{
    /**
     * Get seller overview data
     */
    public function getOverview($id)
    {
        $seller = Seller::with('city', 'store')->find($id);

        if (!$seller) {
            return CommonHelper::responseError('Seller not found');
        }

        $bankAccounts = DB::table('seller_bank_accounts')
            ->where('seller_id', $id)
            ->orderByDesc('is_default')
            ->orderBy('id')
            ->get();

        $sellerData = $seller->toArray();
        $sellerData['bank_accounts'] = $bankAccounts;

        return CommonHelper::responseWithData($sellerData);
    }

    /**
     * Update seller commission
     */
    public function updateCommissionValue(Request $request)
    {
        $request->validate([
            'seller_id' => 'required|exists:sellers,id',
            'commission' => 'required|numeric|min:0|max:100'
        ]);

        $seller = Seller::find($request->seller_id);

        if (!$seller) {
            return CommonHelper::responseError('Seller not found');
        }

        $seller->commission = $request->commission;
        $seller->save();

        return CommonHelper::responseSuccess('Commission updated successfully');
    }

    /**
     * Update seller's per-vendor GST snapshot (sellers.vendor_gst_percent).
     * Accepts either `vendor_gst_percent` (preferred) or the legacy `gst`
     * field for backwards-compatibility with older admin UIs.
     */
    public function updateGstValue(Request $request)
    {
        $request->validate([
            'seller_id' => 'required|exists:sellers,id',
            'vendor_gst_percent' => 'required_without:gst|numeric|min:0|max:100',
            'gst' => 'required_without:vendor_gst_percent|numeric|min:0|max:100',
        ]);

        $seller = Seller::find($request->seller_id);

        if (!$seller) {
            return CommonHelper::responseError('Seller not found');
        }

        $value = $request->input('vendor_gst_percent', $request->input('gst'));
        $seller->vendor_gst_percent = $value;
        $seller->save();

        return CommonHelper::responseSuccess('GST updated successfully');
    }

    /**
     * Get seller reviews/ratings grouped by order
     */
    public function getReviews(Request $request, $id)
    {
        $seller = Seller::find($id);

        if (!$seller) {
            return CommonHelper::responseError('Seller not found');
        }

        $storeId = $seller->store_id ? (int) $seller->store_id : null;
        $perPage = (int) ($request->per_page ?? 5);
        $page = (int) ($request->page ?? 1);

        // Overall stats (no joins, so bare column names are fine)
        $avgRating = round((float) DB::table('order_product_ratings')
            ->where(function ($q) use ($id, $storeId) {
                $q->where('order_product_ratings.seller_id', $id);
                if ($storeId) {
                    $q->orWhere('order_product_ratings.store_id', $storeId);
                }
            })
            ->avg('rating'), 1);

        $totalProductRatings = DB::table('order_product_ratings')
            ->where(function ($q) use ($id, $storeId) {
                $q->where('order_product_ratings.seller_id', $id);
                if ($storeId) {
                    $q->orWhere('order_product_ratings.store_id', $storeId);
                }
            })
            ->count();

        // Star distribution
        $starCounts = [];
        for ($i = 5; $i >= 1; $i--) {
            $starCounts[$i . '_star'] = DB::table('order_product_ratings')
                ->where(function ($q) use ($id, $storeId) {
                    $q->where('order_product_ratings.seller_id', $id);
                    if ($storeId) {
                        $q->orWhere('order_product_ratings.store_id', $storeId);
                    }
                })
                ->where('rating', $i)
                ->count();
        }

        // Get unique order IDs from both tables separately then merge
        $ratingOrderIds = DB::table('order_product_ratings')
            ->where(function ($q) use ($id, $storeId) {
                $q->where('order_product_ratings.seller_id', $id);
                if ($storeId) {
                    $q->orWhere('order_product_ratings.store_id', $storeId);
                }
            })
            ->pluck('order_id')
            ->toArray();

        $reviewOrderIds = DB::table('order_seller_reviews')
            ->where(function ($q) use ($id, $storeId) {
                $q->where('order_seller_reviews.seller_id', $id);
                if ($storeId) {
                    $q->orWhere('order_seller_reviews.store_id', $storeId);
                }
            })
            ->pluck('order_id')
            ->toArray();

        $allOrderIds = collect(array_merge($ratingOrderIds, $reviewOrderIds))
            ->unique()
            ->sortDesc()
            ->values();

        $totalOrders = $allOrderIds->count();
        $paginatedOrderIds = $allOrderIds->slice(($page - 1) * $perPage, $perPage)->values();

        // Build order-wise data
        $orders = [];
        foreach ($paginatedOrderIds as $orderId) {
            // Customer info
            $customerInfo = DB::table('order_product_ratings')
                ->leftJoin('users', 'order_product_ratings.user_id', '=', 'users.id')
                ->where('order_product_ratings.order_id', $orderId)
                ->where(function ($q) use ($id, $storeId) {
                    $q->where('order_product_ratings.seller_id', $id);
                    if ($storeId) {
                        $q->orWhere('order_product_ratings.store_id', $storeId);
                    }
                })
                ->select('users.id as user_id', 'users.name as user_name', 'users.profile as user_profile')
                ->first();

            if (!$customerInfo) {
                $customerInfo = DB::table('order_seller_reviews')
                    ->leftJoin('users', 'order_seller_reviews.user_id', '=', 'users.id')
                    ->where('order_seller_reviews.order_id', $orderId)
                    ->where(function ($q) use ($id, $storeId) {
                        $q->where('order_seller_reviews.seller_id', $id);
                        if ($storeId) {
                            $q->orWhere('order_seller_reviews.store_id', $storeId);
                        }
                    })
                    ->select('users.id as user_id', 'users.name as user_name', 'users.profile as user_profile')
                    ->first();
            }

            // Seller review for this order
            $sellerReview = DB::table('order_seller_reviews')
                ->where('order_id', $orderId)
                ->where(function ($q) use ($id, $storeId) {
                    $q->where('order_seller_reviews.seller_id', $id);
                    if ($storeId) {
                        $q->orWhere('order_seller_reviews.store_id', $storeId);
                    }
                })
                ->value('review');

            // Product ratings for this order
            $productRatings = DB::table('order_product_ratings')
                ->leftJoin('products', 'order_product_ratings.product_id', '=', 'products.id')
                ->where('order_product_ratings.order_id', $orderId)
                ->where(function ($q) use ($id, $storeId) {
                    $q->where('order_product_ratings.seller_id', $id);
                    if ($storeId) {
                        $q->orWhere('order_product_ratings.store_id', $storeId);
                    }
                })
                ->select(
                    'order_product_ratings.product_id',
                    'products.name as product_name',
                    'order_product_ratings.rating'
                )
                ->get();

            $orders[] = [
                'order_id' => (int) $orderId,
                'customer' => [
                    'id' => $customerInfo->user_id ?? null,
                    'name' => $customerInfo->user_name ?? null,
                    'profile' => $customerInfo->user_profile ?? null,
                ],
                'seller_review' => $sellerReview,
                'product_ratings' => $productRatings,
                'created_at' => DB::table('orders')->where('id', $orderId)->value('created_at'),
            ];
        }

        return CommonHelper::responseWithData([
            'orders' => $orders,
            'average_rating' => $avgRating,
            'total_product_ratings' => $totalProductRatings,
            'star_counts' => $starCounts,
            'total_orders' => $totalOrders,
            'pagination' => [
                'current_page' => $page,
                'per_page' => $perPage,
                'total' => $totalOrders,
                'last_page' => (int) ceil($totalOrders / $perPage),
            ],
        ]);
    }

    /**
     * Get all categories for a seller from the categories table.
     */
    public function getSellerCategories($id)
    {
        $categories = DB::table('categories')
            ->where('seller_id', $id)
            ->where('status', 1)
            ->select('id', 'name')
            ->orderBy('name')
            ->get();

        return CommonHelper::responseWithData($categories);
    }

    /**
     * Admin: Create a category group for a seller (same flow as seller app).
     */
    public function storeSellerCategoryGroup(Request $request)
    {
        $request->validate([
            'seller_id' => 'required|integer|exists:sellers,id',
            'name'      => 'required|string|max:255',
            'group_ids'   => 'required|array',
            'group_ids.*' => 'integer',
            'image'     => 'nullable|image|max:5120',
        ]);

        $imagePath = null;
        if ($request->hasFile('image')) {
            $imagePath = MediaUploadService::upload(
                $request->file('image'),
                'group/categories/image'
            );
        }

        $categoryGroupId = DB::table('category_groups')->insertGetId([
            'seller_id'    => $request->seller_id,
            'is_super_mart' => 1,
            'name'         => $request->name,
            'image'        => $imagePath,
            'created_at'   => now(),
            'updated_at'   => now(),
        ]);

        DB::table('sub_category_groups')
            ->whereIn('id', $request->group_ids)
            ->update(['category_group_id' => $categoryGroupId]);

        return CommonHelper::responseSuccess('Category Group created successfully!');
    }

    /**
     * Admin: Create a sub category group for a seller (same flow as seller app).
     */
    public function storeSellerSubCategoryGroup(Request $request)
    {
        $request->validate([
            'seller_id'    => 'required|integer|exists:sellers,id',
            'name'         => 'required|string|max:255',
            'category_ids' => 'nullable|string',
            'image'        => 'nullable|image|max:5120',
        ]);

        $imagePath = null;
        if ($request->hasFile('image')) {
            $imagePath = MediaUploadService::upload(
                $request->file('image'),
                'group/categories/image'
            );
        }

        $isGroup = 0;
        if (!empty($request->category_ids) && str_contains($request->category_ids, ',')) {
            $isGroup = 1;
        }

        SubCategoryGroup::create([
            'seller_id'       => $request->seller_id,
            'name'            => $request->name,
            'image'           => $imagePath,
            'subcategory_ids' => $request->category_ids,
            'is_super_mart'   => 1,
            'is_group'        => $isGroup,
        ]);

        return CommonHelper::responseSuccess('Sub Category Group created successfully!');
    }

    /**
     * Get all brands for a seller with pagination and search.
     */
    public function getSellerBrands(Request $request, $id)
    {
        $seller = Seller::find($id);

        if (!$seller) {
            return CommonHelper::responseError('Seller not found');
        }

        $query = \App\Models\Brand::where('seller_id', $seller->id);

        if ($request->has('search') && !empty($request->search)) {
            $query->where('name', 'like', '%' . $request->search . '%');
        }

        if ($request->has('status') && $request->status !== '' && $request->status !== null) {
            $query->where('status', $request->status);
        }

        $perPage = (int) ($request->per_page ?? 10);

        $brands = $query->orderBy('created_at', 'desc')->paginate($perPage);

        return CommonHelper::responseWithData([
            'brands' => $brands->items(),
            'total' => $brands->total(),
            'current_page' => $brands->currentPage(),
            'last_page' => $brands->lastPage(),
            'per_page' => $brands->perPage(),
        ]);
    }
}