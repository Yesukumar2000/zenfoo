<?php

namespace App\Http\Controllers\API\Customer;

use App\Http\Controllers\Controller;
use App\Models\Bookmark;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\Seller;
use App\Models\Combo;
use App\Models\ComboCategory;
use App\Models\Store;
use App\Models\Cart;
use App\Models\Setting;
use App\Helpers\CommonHelper;
use App\Services\StoreDistanceService;
use App\Services\RatingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class BookmarkController extends Controller
{
    /**
     * Get all bookmarks for authenticated user
     * Supports filtering by type
     */
    public function index(Request $request)
    {
        try {
            $user_id = Auth::user()->id;
            $limit = $request->limit ?? 10;
            $offset = $request->offset ?? 0;
            $type = $request->type ?? null; // product, seller, combo
            $sort_by = $request->sort_by ?? 'created_at'; // created_at
            $sort_order = $request->sort_order ?? 'desc';

            $query = Bookmark::with('bookmarkable')
                ->byUser($user_id);

            // Apply type filter if provided
            if ($type) {
                if (!in_array($type, ['product', 'seller', 'combo'])) {
                    return CommonHelper::responseError(__('invalid_bookmark_type'));
                }
                $query->byType($type);
            }

            // Count total before pagination
            $total = $query->count();

            // Apply sorting and pagination
            $bookmarks = $query->orderBy($sort_by, $sort_order)
                ->skip($offset)
                ->take($limit)
                ->get();

            if ($bookmarks->isEmpty()) {
                return CommonHelper::responseError(__('no_items_found'));
            }

            $bookmarkData = $this->formatBookmarks($bookmarks, $user_id);

            return CommonHelper::responseWithData($bookmarkData, $total);
        } catch (\Exception $e) {
            Log::error("Bookmarks Error: " . $e->getMessage());
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    /**
     * Get single bookmark details
     */
    public function show($id)
    {
        try {
            $user_id = Auth::user()->id;

            $bookmark = Bookmark::with('bookmarkable')
                ->where('id', $id)
                ->where('user_id', $user_id)
                ->first();

            if (!$bookmark) {
                return CommonHelper::responseError(__('bookmark_not_found'));
            }

            $data = $this->formatSingleBookmark($bookmark, $user_id);

            return CommonHelper::responseWithData($data);
        } catch (\Exception $e) {
            Log::error("Bookmark show error: " . $e->getMessage());
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    /**
     * Create a new bookmark
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'type' => 'required|in:product,seller,combo',
            'item_id' => 'required|integer', // product_id, seller_id, or combo_id depending on type
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $user_id = Auth::user()->id;
            $type = $request->type;
            $itemId = $request->item_id;

            // Map type to model class
            $bookmarkableType = $this->getBookmarkableType($type);
            if (!$bookmarkableType) {
                return CommonHelper::responseError(__('invalid_bookmark_type'));
            }

            // Verify item exists
            $itemModel = $bookmarkableType::find($itemId);
            if (!$itemModel) {
                return CommonHelper::responseError("Item not found for type: {$type}");
            }

            // Check if bookmark already exists
            $existingBookmark = Bookmark::where('user_id', $user_id)
                ->where('bookmarkable_type', $bookmarkableType)
                ->where('bookmarkable_id', $itemId)
                ->first();

            if ($existingBookmark) {
                return CommonHelper::responseError(__('bookmark_already_exists'));
            }

            // Create bookmark
            $bookmark = new Bookmark();
            $bookmark->user_id = $user_id;
            $bookmark->bookmarkable_type = $bookmarkableType;
            $bookmark->bookmarkable_id = $itemId;
            $bookmark->type = $type;
            $bookmark->save();

            $bookmark->load('bookmarkable');
            $data = $this->formatSingleBookmark($bookmark, $user_id);

            return CommonHelper::responseWithData($data, null, __('bookmark_created_successfully'));
        } catch (\Exception $e) {
            Log::error("Bookmark create error: " . $e->getMessage());
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    /**
     * Toggle bookmark (add if not exists, remove if exists)
     * Perfect for mobile apps - no need to track bookmark_id
     */
    public function toggle(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'type' => 'required|in:product,seller,combo',
            'item_id' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $user_id = Auth::user()->id;
            $type = $request->type;
            $itemId = $request->item_id;

            // Map type to model class
            $bookmarkableType = $this->getBookmarkableType($type);
            if (!$bookmarkableType) {
                return CommonHelper::responseError(__('invalid_bookmark_type'));
            }

            // Check if bookmark exists
            $existingBookmark = Bookmark::where('user_id', $user_id)
                ->where('bookmarkable_type', $bookmarkableType)
                ->where('bookmarkable_id', $itemId)
                ->first();

            if ($existingBookmark) {
                // Remove bookmark
                $existingBookmark->delete();

                return CommonHelper::responseWithData([
                    'is_bookmarked' => false,
                    'action' => 'removed',
                    'type' => $type,
                    'item_id' => $itemId,
                ], null, __('bookmark_removed_successfully'));
            } else {
                // Add bookmark
                // Verify item exists
                $itemModel = $bookmarkableType::find($itemId);
                if (!$itemModel) {
                    return CommonHelper::responseError("Item not found for type: {$type}");
                }

                $bookmark = new Bookmark();
                $bookmark->user_id = $user_id;
                $bookmark->bookmarkable_type = $bookmarkableType;
                $bookmark->bookmarkable_id = $itemId;
                $bookmark->type = $type;
                $bookmark->save();

                $bookmark->load('bookmarkable');
                $data = $this->formatSingleBookmark($bookmark, $user_id);
                $data['action'] = 'added';
                $data['is_bookmarked'] = true;

                return CommonHelper::responseWithData($data, null, __('bookmark_created_successfully'));
            }
        } catch (\Exception $e) {
            Log::error("Bookmark toggle error: " . $e->getMessage());
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    /**
     * Delete a bookmark
     */
    public function destroy($id)
    {
        try {
            $user_id = Auth::user()->id;

            $bookmark = Bookmark::where('id', $id)
                ->where('user_id', $user_id)
                ->first();

            if (!$bookmark) {
                return CommonHelper::responseError(__('bookmark_not_found'));
            }

            $bookmark->delete();

            return CommonHelper::responseSuccess(__('bookmark_deleted_successfully'));
        } catch (\Exception $e) {
            Log::error("Bookmark delete error: " . $e->getMessage());
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    /**
     * Bulk delete bookmarks
     */
    public function bulkDelete(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'bookmark_ids' => 'required|array|min:1',
            'bookmark_ids.*' => 'integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $user_id = Auth::user()->id;

            $deleted = Bookmark::where('user_id', $user_id)
                ->whereIn('id', $request->bookmark_ids)
                ->delete();

            return CommonHelper::responseSuccess(__('bookmarks_deleted_successfully'), ['deleted_count' => $deleted]);
        } catch (\Exception $e) {
            Log::error("Bulk delete bookmarks error: " . $e->getMessage());
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    /**
     * Get bookmarks by type (product, seller, combo)
     */
    public function getByType(Request $request, $type)
    {
        if (!in_array($type, ['product', 'seller', 'combo'])) {
            return CommonHelper::responseError(__('invalid_bookmark_type'));
        }

        try {
            $user_id = Auth::user()->id;
            $limit = $request->limit ?? 10;
            $offset = $request->offset ?? 0;

            $query = Bookmark::with('bookmarkable')
                ->byUser($user_id)
                ->byType($type);

            $total = $query->count();

            $bookmarks = $query->orderBy('created_at', 'desc')
                ->skip($offset)
                ->take($limit)
                ->get();

            if ($bookmarks->isEmpty()) {
                return CommonHelper::responseError(__('no_items_found'));
            }

            $bookmarkData = $this->formatBookmarks($bookmarks, $user_id);

            return CommonHelper::responseWithData($bookmarkData, $total);
        } catch (\Exception $e) {
            Log::error("Get bookmarks by type error: " . $e->getMessage());
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    /**
     * Check if an item is bookmarked
     */
    public function checkBookmarked(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'type' => 'required|in:product,seller,combo',
            'item_id' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $user_id = Auth::user()->id;
            $type = $request->type;
            $itemId = $request->item_id;

            $bookmarkableType = $this->getBookmarkableType($type);
            if (!$bookmarkableType) {
                return CommonHelper::responseError(__('invalid_bookmark_type'));
            }

            $isBookmarked = Bookmark::where('user_id', $user_id)
                ->where('type', $type)
                ->where('bookmarkable_type', $bookmarkableType)
                ->where('bookmarkable_id', $itemId)
                ->exists();

            return CommonHelper::responseWithData([
                'is_bookmarked' => $isBookmarked,
                'type' => $type,
                'item_id' => $itemId,
            ]);
        } catch (\Exception $e) {
            Log::error("Check bookmarked error: " . $e->getMessage());
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    /**
     * Get list of all bookmark tabs (stores, combos, sellers) with IDs
     * API 1 - Returns tab structure for UI
     */
    public function getBookmarkTabs(Request $request)
    {
        try {
            $user_id = Auth::user()->id;

            // Get combo count
            $comboCount = Bookmark::where('user_id', $user_id)
                ->where('type', 'combo')
                ->count();

            // Fetch all active stores managed by admin
            $stores = Store::where('is_active', true)
                ->where('managed_by_admin', true)
                ->get(['id', 'name', 'image']);

            $tabs = [];

            // Add stores tab
            if ($stores->count() > 0) {
                $tabs[] = [
                    'tab_type' => 'stores',
                    'name' => 'Stores',
                    'count' => $stores->count(),
                    'items' => $stores->map(function ($store) {
                        return [
                            'id' => $store->id,
                            'name' => $store->name,
                            'image' => $store->image
                        ];
                    })->toArray()
                ];
            }

            // Add combos tab - show stores with combos at index 0
            if ($comboCount > 0) {
                // Start with "All Combos" item at index 0
                $comboItems = [
                    [
                        'id' => 0,
                        'name' => 'All Combos',
                        'image' => null
                    ]
                ];

                // Add stores from admin-managed stores
                foreach ($stores as $store) {
                    $comboItems[] = [
                        'id' => $store->id,
                        'name' => $store->name,
                        'image' => $store->image
                    ];
                }

                $tabs[] = [
                    'tab_type' => 'combos',
                    'name' => 'Combos',
                    'count' => $comboCount,
                    'items' => $comboItems
                ];
            }

            // Add sellers tab - stores NOT managed by admin
            $sellerStores = Store::where('managed_by_admin', false)
                ->get(['id', 'name', 'image', 'is_super_mart']);

            if ($sellerStores->count() > 0) {
                $tabs[] = [
                    'tab_type' => 'sellers',
                    'name' => 'Sellers',
                    'count' => $sellerStores->count(),
                    'items' => $sellerStores->map(function ($store) {
                        return [
                            'id' => $store->id,
                            'name' => $store->name,
                            'image' => $store->image,
                            'is_super_mart' => (bool) $store->is_super_mart,
                        ];
                    })->toArray()
                ];
            }

            if (empty($tabs)) {
                return CommonHelper::responseError(__('no_items_found'));
            }

            return CommonHelper::responseWithData($tabs, count($tabs));
        } catch (\Exception $e) {
            Log::error("Get bookmark tabs error: " . $e->getMessage());
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    /**
     * Get detailed data for a specific bookmark tab
     * API 2 - Takes tab_type and id, returns products/sellers data
     * Returns data in same format as getProducts() and getCombos() APIs
     */
    public function getBookmarkTabData(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'tab_type' => 'required|in:stores,combos,sellers',
            'id' => 'required|integer'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $user_id = Auth::user()->id;
            $tab_type = $request->tab_type;
            $id = $request->id;

            if ($tab_type === 'stores') {
                // Get bookmarked products from the specified store (active, managed by admin)
                $store = Store::find($id);
                if (!$store || !$store->is_active || !$store->managed_by_admin) {
                    return CommonHelper::responseError(__('no_items_found'));
                }

                // Get user's bookmarked products from this store
                $productBookmarks = Bookmark::where('user_id', $user_id)
                    ->where('type', 'product')
                    ->with(['bookmarkable' => function ($query) use ($id) {
                        $query->where('store_id', $id);
                    }])
                    ->get()
                    ->filter(function ($bookmark) {
                        return $bookmark->bookmarkable !== null;
                    });

                if ($productBookmarks->isEmpty()) {
                    return CommonHelper::responseError(__('no_items_found'));
                }

                // Format products using same logic as getProducts endpoint
                $data = [];
                foreach ($productBookmarks as $bookmark) {
                    $product = $bookmark->bookmarkable;
                    $variants = ProductVariant::with(['product.tax', 'unit', 'images'])
                        ->where('product_id', $product->id)
                        ->get();

                    if ($variants->isEmpty()) {
                        continue;
                    }

                    $variants = $variants->makeHidden(['product_id', 'status', 'measurement_unit_id', 'stock_unit_id', 'deleted_at']);
                    $variantArray = [];
                    foreach ($variants as $variant) {
                        $variantArray[] = CommonHelper::getProductVariant($variant->id, $user_id);
                    }

                    $productData = $product->toArray();
                    $productData['variants'] = $variantArray;
                    $productData['rating_count'] = CommonHelper::productAverageRating($product->id)['rating_count'];
                    $productData['average_rating'] = CommonHelper::productAverageRating($product->id)['average_rating'];
                    $productData['is_bookmarked'] = true; // All items here are bookmarked

                    $data[] = $productData;
                }

                return CommonHelper::responseWithData($data, count($data));

            } elseif ($tab_type === 'combos') {
                // Get combo bookmarks in same format as getCombos()
                // Get all combo bookmark IDs for the user
                Log::info('Combos Tab Data - Start', [
                    'user_id' => $user_id,
                    'tab_type' => $tab_type,
                    'id' => $id
                ]);

                $comboBookmarkIds = Bookmark::where('user_id', $user_id)
                    ->where('type', 'combo')
                    ->pluck('bookmarkable_id')
                    ->toArray();

                Log::info('Combo Bookmark IDs Retrieved', [
                    'count' => count($comboBookmarkIds),
                    'ids' => $comboBookmarkIds
                ]);

                if (empty($comboBookmarkIds)) {
                    Log::warning('No combo bookmarks found for user', ['user_id' => $user_id]);
                    return CommonHelper::responseError(__('no_items_found'));
                }

                // If id is 0, get all bookmarked combos regardless of store_id
                // Otherwise, get combos from the specified store_id
                if ($id == 0) {
                    Log::info('Fetching all bookmarked combos (no store filter)');
                    // Get all combos from the bookmark IDs - no store_id filter
                    $combos = Combo::whereIn('id', $comboBookmarkIds)
                        ->with(['products.variants.unit'])
                        ->get();
                    Log::info('All combos fetched', ['count' => $combos->count()]);
                } else {
                    Log::info('Fetching combos for specific store', ['store_id' => $id]);
                    // Get combos from the specified store_id
                    $combos = Combo::whereIn('id', $comboBookmarkIds)
                        ->where('store_id', $id)
                        ->with(['products.variants.unit'])
                        ->get();
                    Log::info('Store combos fetched', ['count' => $combos->count(), 'store_id' => $id]);
                }

                if ($combos->isEmpty()) {
                    Log::warning('No combos found after filtering', [
                        'bookmark_ids' => $comboBookmarkIds,
                        'store_id' => $id
                    ]);
                    return CommonHelper::responseError(__('no_items_found'));
                }

                Log::info('Formatting combos for response', ['count' => $combos->count()]);
                $data = $combos->map(function ($combo) use ($user_id) {
                    return $this->formatComboForResponse($combo, $user_id);
                })->values()->toArray();

                Log::info('Combos tab data complete', ['final_count' => count($data)]);
                return CommonHelper::responseWithData($data, count($data));

            } elseif ($tab_type === 'sellers') {
                // Get bookmarked sellers from the specified non-admin-managed store
                $store = Store::find($id);
                if (!$store || !$store->is_active || $store->managed_by_admin) {
                    return CommonHelper::responseError(__('no_items_found'));
                }

                // Get user's bookmarked sellers from this store
                $sellerBookmarks = Bookmark::where('user_id', $user_id)
                    ->where('type', 'seller')
                    ->with(['bookmarkable' => function ($query) use ($id) {
                        $query->where('store_id', $id)->with('store:id,is_super_mart');
                    }])
                    ->get()
                    ->filter(function ($bookmark) {
                        return $bookmark->bookmarkable !== null;
                    });

                if ($sellerBookmarks->isEmpty()) {
                    return CommonHelper::responseError(__('no_items_found'));
                }

                $data = $sellerBookmarks->map(function ($bookmark) use ($user_id) {
                    return $this->formatSellerForResponse($bookmark->bookmarkable, $user_id);
                })->values()->toArray();

                return CommonHelper::responseWithData($data, count($data));
            }

            return CommonHelper::responseError('Invalid tab type');
        } catch (\Exception $e) {
            Log::error("Get bookmark tab data error: " . $e->getMessage());
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    /**
     * Format product for response in same format as getProducts() API
     */
    private function formatProductForResponse($product, $user_id)
    {
        $variant = $product->variants?->first();

        return [
            'id' => $product->id,
            'name' => $product->name,
            'category_id' => $product->category_id,
            'image' => $product->image_url,
            'seller_id' => $product->seller_id,
            'seller_name' => $product->seller?->name,
            'price' => $variant?->price ?? 0,
            'discounted_price' => $variant?->discounted_price ?? 0,
            'tax' => $product->tax?->name ?? null,
            'is_bookmarked' => $this->checkIfBookmarked($product->id, 'product', $user_id),
            'is_already_added' => $this->checkIfInCart($product->id, $user_id),
        ];
    }

    /**
     * Format combo for response in same format as getCombosCustomerHomePage() API
     */
    private function formatComboForResponse($combo, $user_id)
    {
        $totalProductPrice = $combo->products->sum(function ($product) {
            $variant = $product->variants->firstWhere('id', $product->pivot->variant_id);
            $price = $variant
                ? ($variant->discounted_price > 0 ? $variant->discounted_price : $variant->price)
                : 0;
            return $price * ($product->pivot->quantity ?? 1);
        });

        $totalActualPrice = $combo->products->sum(function ($product) {
            $variant = $product->variants->firstWhere('id', $product->pivot->variant_id);
            $actual_price = $variant
                ? ($variant->price > 0 ? $variant->price : $variant->discounted_price)
                : 0;
            return $actual_price * ($product->pivot->quantity ?? 1);
        });

        $discountPercentage = $totalActualPrice > 0
            ? round((($totalActualPrice - $totalProductPrice) / $totalActualPrice) * 100, 2)
            : 0;

        $ratingData = DB::table('product_ratings')
            ->where('is_combo', 1)
            ->where('product_id', $combo->id)
            ->selectRaw('COUNT(*) as rating_count, AVG(rate) as avg_rating')
            ->first();

        $categoryTypeData = ComboCategory::where('id', $combo->category_type)->first();
        $currency = Setting::get_value('currency');

        return [
            'id' => $combo->id,
            'name' => $combo->name,
            'description' => $combo->description,
            'price' => $combo->price,
            'rating' => round($ratingData?->avg_rating ?? 0, 1),
            'rating_count' => (int) ($ratingData?->rating_count ?? 0),
            'product_count' => $combo->products->count(),
            'type' => $combo->type,
            'category_type' => $categoryTypeData,
            'status' => $combo->status ?? 1,
            'image_url' => $combo->image_url,
            'total_products_price' => $totalProductPrice,
            'total_actual_price' => round($totalActualPrice, 2),
            'discount_percentage' => $discountPercentage,
            'currency' => $currency,
            'is_already_added' => $this->checkIfComboInCart($combo->id, $user_id) ? 1 : 0,
            'is_bookmarked' => $this->checkIfBookmarked($combo->id, 'combo', $user_id) ? 1 : 0,
            'products' => $combo->products->map(function ($product) use ($currency) {
                $variant = $product->variants->firstWhere('id', $product->pivot->variant_id);
                return [
                    'product_id' => $product->id,
                    'product_name' => $product->name,
                    'variant_id' => $product->pivot->variant_id,
                    'variant_measurement' => $variant->measurement ?? null,
                    'variant_unit' => $variant->unit->short_code ?? null,
                    'price' => $variant
                        ? ($variant->discounted_price > 0 ? $variant->discounted_price : $variant->price)
                        : 0,
                    'quantity' => $product->pivot->quantity,
                    'currency' => $currency,
                ];
            }),
        ];
    }

    /**
     * Format seller for response in same format as getSweetHouseSellers/getSuperMartSellers APIs
     */
    private function formatSellerForResponse($seller, $user_id)
    {
        // Get dynamic rating from RatingService
        $ratingData = RatingService::getSellerRating($seller->id, $seller->store_id);
        $rating = $ratingData['rating'];
        $rating_count = $ratingData['rating_count'];

        return [
            'id' => $seller->id,
            'name' => $seller->name,
            'logo_url' => $seller->logo_url ?? null,
            'rating' => $rating,
            'rating_count' => $rating_count,
            'distance_km' => null,
            'travel_time_min' => null,
            'lat_long' => $seller->lat_long ?? null,
            'is_bookmarked' => $this->checkIfBookmarked($seller->id, 'seller', $user_id),
            'store_id' => $seller->store_id,
            'is_super_mart' => (bool) ($seller->store->is_super_mart ?? false),
        ];
    }

    /**
     * Check if item is bookmarked
     */
    private function checkIfBookmarked($item_id, $type, $user_id)
    {
        $bookmarkableType = $this->getBookmarkableType($type);
        return Bookmark::where('user_id', $user_id)
            ->where('type', $type)
            ->where('bookmarkable_type', $bookmarkableType)
            ->where('bookmarkable_id', $item_id)
            ->exists();
    }

    /**
     * Check if product is in cart
     */
    private function checkIfInCart($product_id, $user_id)
    {
        return Cart::where('user_id', $user_id)
            ->where('product_id', $product_id)
            ->exists();
    }

    /**
     * Check if combo is in cart
     */
    private function checkIfComboInCart($combo_id, $user_id)
    {
        return DB::table('combo_custom_cart')
            ->where('user_id', $user_id)
            ->where('combo_id', $combo_id)
            ->exists();
    }

    /**
     * Get bookmarked stores with their products
     * Stores Tab - All bookmarked stores with products listed
     */
    public function getBookmarkedStores(Request $request)
    {
        try {
            $user_id = Auth::user()->id;

            // Get product bookmarks and group by store
            $productBookmarks = Bookmark::where('user_id', $user_id)
                ->where('type', 'product')
                ->with('bookmarkable')
                ->get();

            if ($productBookmarks->isEmpty()) {
                return CommonHelper::responseError(__('no_items_found'));
            }

            $store_ids = [];
            $stores = [];

            // First pass: collect store IDs and products
            foreach ($productBookmarks as $bookmark) {
                $product = $bookmark->bookmarkable;
                if ($product && $product->seller && $product->seller->store) {
                    $store_id = $product->seller->store->id;
                    $store_ids[] = $store_id;

                    if (!isset($stores[$store_id])) {
                        $stores[$store_id] = [
                            'store_id' => $store_id,
                            'data' => []
                        ];
                    }

                    $stores[$store_id]['data'][] = [
                        'id' => $product->id,
                        'type' => 'product',
                        'name' => $product->name,
                        'image' => $product->image_url ?? null,
                        'price' => $product->variants ? $product->variants->first()?->price : null,
                    ];
                }
            }

            // Fetch all store details based on collected store IDs
            $storeDetails = Store::whereIn('id', array_unique($store_ids))->get()->keyBy('id');

            // Second pass: add store details to response
            $result = [];
            foreach ($stores as $store_id => $store_data) {
                $storeModel = $storeDetails->get($store_id);
                if ($storeModel) {
                    $result[] = [
                        'id' => $storeModel->id,
                        'name' => $storeModel->name ?? null,
                        'image' => $storeModel->image_url ?? null,
                        'icon' => $storeModel->icon_url ?? null,
                        'description' => $storeModel->description ?? null,
                        'data' => $store_data['data']
                    ];
                }
            }

            return CommonHelper::responseWithData($result, count($result));
        } catch (\Exception $e) {
            Log::error("Get bookmarked stores error: " . $e->getMessage());
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    /**
     * Get bookmarked combos
     * Combos Tab - All bookmarked combos
     */
    public function getBookmarkedCombos(Request $request)
    {
        try {
            $user_id = Auth::user()->id;

            $comboBookmarks = Bookmark::where('user_id', $user_id)
                ->where('type', 'combo')
                ->with('bookmarkable')
                ->get();

            if ($comboBookmarks->isEmpty()) {
                return CommonHelper::responseError(__('no_items_found'));
            }

            $combos = [];
            foreach ($comboBookmarks as $bookmark) {
                $combo = $bookmark->bookmarkable;
                if ($combo) {
                    $combos[] = [
                        'id' => $combo->id,
                        'type' => 'combo',
                        'name' => $combo->name,
                        'image' => $combo->image_url ?? null,
                        'price' => $combo->price,
                    ];
                }
            }

            return CommonHelper::responseWithData($combos, count($combos));
        } catch (\Exception $e) {
            Log::error("Get bookmarked combos error: " . $e->getMessage());
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    /**
     * Get bookmarked sellers organized by stores
     * Sellers Tab - All bookmarked sellers organized by their stores
     */
    public function getBookmarkedSellers(Request $request)
    {
        try {
            $user_id = Auth::user()->id;

            $sellerBookmarks = Bookmark::where('user_id', $user_id)
                ->where('type', 'seller')
                ->with('bookmarkable')
                ->get();

            if ($sellerBookmarks->isEmpty()) {
                return CommonHelper::responseError(__('no_items_found'));
            }

            $store_ids = [];
            $stores = [];

            // First pass: collect store IDs and sellers
            foreach ($sellerBookmarks as $bookmark) {
                $seller = $bookmark->bookmarkable;
                if ($seller && $seller->store) {
                    $store_id = $seller->store->id;
                    $store_ids[] = $store_id;

                    if (!isset($stores[$store_id])) {
                        $stores[$store_id] = [
                            'store_id' => $store_id,
                            'data' => []
                        ];
                    }

                    $stores[$store_id]['data'][] = [
                        'id' => $seller->id,
                        'type' => 'seller',
                        'name' => $seller->name,
                        'image' => $seller->logo_url ?? null,
                    ];
                }
            }

            // Fetch all store details based on collected store IDs
            $storeDetails = Store::whereIn('id', array_unique($store_ids))->get()->keyBy('id');

            // Second pass: add store details to response
            $result = [];
            foreach ($stores as $store_id => $store_data) {
                $storeModel = $storeDetails->get($store_id);
                if ($storeModel) {
                    $result[] = [
                        'id' => $storeModel->id,
                        'name' => $storeModel->name ?? null,
                        'image' => $storeModel->image_url ?? null,
                        'icon' => $storeModel->icon_url ?? null,
                        'description' => $storeModel->description ?? null,
                        'data' => $store_data['data']
                    ];
                }
            }

            return CommonHelper::responseWithData($result, count($result));
        } catch (\Exception $e) {
            Log::error("Get bookmarked sellers error: " . $e->getMessage());
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    /**
     * Helper Methods
     */

    /**
     * Map bookmark type to model class name
     */
    private function getBookmarkableType($type)
    {
        $mapping = [
            'product' => Product::class,
            'seller' => Seller::class,
            'combo' => Combo::class,
        ];

        return $mapping[$type] ?? null;
    }

    /**
     * Format multiple bookmarks for response
     */
    private function formatBookmarks($bookmarks, $userId)
    {
        return $bookmarks->map(function ($bookmark) use ($userId) {
            return $this->formatSingleBookmark($bookmark, $userId);
        })->toArray();
    }

    /**
     * Format single bookmark for response
     */
    private function formatSingleBookmark($bookmark, $userId)
    {
        $itemDetails = null;

        if ($bookmark->bookmarkable) {
            $bookmarkable = $bookmark->bookmarkable;

            if ($bookmark->type === 'product') {
                // Use CommonHelper to get full product details with pricing and tax
                $itemDetails = CommonHelper::getProductDetails($bookmarkable->id, $userId, false, null);
            } else {
                // For seller and combo, return basic details
                $itemDetails = [
                    'id' => $bookmarkable->id,
                    'name' => $bookmarkable->name ?? null,
                    'image' => $bookmarkable->image ?? null,
                    'type' => $bookmark->type,
                ];
            }
        }

        return [
            'id' => $bookmark->id,
            'type' => $bookmark->type,
            'bookmarkable_type' => $bookmark->bookmarkable_type,
            'bookmarkable_id' => $bookmark->bookmarkable_id,
            'item' => $itemDetails,
            'created_at' => $bookmark->created_at,
            'updated_at' => $bookmark->updated_at,
        ];
    }
}
