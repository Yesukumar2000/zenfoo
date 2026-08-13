<?php

namespace App\Http\Controllers;

use App\Models\Seller;
use App\Models\SellerWalletTransaction;
use App\Models\Product;
use App\Models\OrderItem;
use App\Models\Category;
use App\Models\Slider;
use App\Models\Store;
use App\Models\CategoryGroup;
use App\Models\SubCategoryGroup;
use App\Helpers\CommonHelper;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SellerStatisticsController extends Controller
{
    /**
     * Get seller statistics for authenticated seller
     */
    public function getSellerStatistics(Request $request)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = Seller::where('admin_id', $admin->id)->with('store')->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        // Check if store is managed by admin. The flag still controls the
        // catalogue-related metrics (managed stores share product
        // listings between every seller on the store), but order /
        // revenue metrics on the partner dashboard are always
        // per-seller so a fresh seller on a managed store doesn't
        // inherit the other sellers' historical orders.
        $isManagedByAdmin = $seller->store && $seller->store->managed_by_admin == 1;

        // Get total product count (still store-wide for managed stores)
        if ($isManagedByAdmin) {
            $productCount = Product::where('store_id', $seller->store_id)->count();
        } else {
            $productCount = Product::where('seller_id', $seller->id)->count();
        }

        // Order counts are ALWAYS per-seller on the partner dashboard.
        $ordersCount = DB::table('order_seller_status_tracking')
            ->where('seller_id', $seller->id)
            ->distinct('order_id')
            ->count('order_id');

        // Get order counts by status (per-seller)
        $orderStatusCounts = $this->getOrderStatusCounts($seller->id, false, $seller->store_id);

        // Get category-wise product counts (still store-wide so the
        // catalogue distribution reflects what the seller can list)
        $categoryWiseProductCounts = $this->getCategoryWiseProductCounts($seller->id, false, $isManagedByAdmin, $seller->store_id);

        // Per-seller order / revenue numbers
        $totalRevenue = $this->getTotalRevenue($seller->id, false, $seller->store_id);
        $todayOrders = $this->getTodayOrdersCount($seller->id, false, $seller->store_id);
        $pendingOrders = $this->getPendingOrdersCount($seller->id, false, $seller->store_id);
        $completedOrders = $this->getCompletedOrdersCount($seller->id, false, $seller->store_id);
        $cancelledOrders = $this->getCancelledOrdersCount($seller->id, false, $seller->store_id);
        $returnedOrders = $this->getReturnedOrdersCount($seller->id, false, $seller->store_id);

        // Inventory metrics stay store-wide for managed stores
        $soldOutProducts = $this->getSoldOutProductsCount($seller->id, $isManagedByAdmin, $seller->store_id);
        $lowStockProducts = $this->getLowStockProductsCount($seller->id, $isManagedByAdmin, $seller->store_id);

        // Get earnings (same as total_revenue but named for clarity)
        $totalEarnings = $totalRevenue;

        return response()->json([
            'status' => 1,
            'message' => 'Seller statistics fetched successfully',
            'data' => [
                'seller_info' => [
                    'id' => $seller->id,
                    'name' => $seller->name ?? $seller->business_name,
                    'store_id' => $seller->store_id,
                    'balance' => (float) $seller->balance ?? 0,
                ],
                'overview' => [
                    'total_products' => $productCount,
                    'total_orders' => $ordersCount,
                    'completed_orders' => $completedOrders,
                    'cancelled_orders' => $cancelledOrders,
                    'returned_orders' => $returnedOrders,
                    'today_orders' => $todayOrders,
                    'pending_orders' => $pendingOrders,
                    'earnings' => (float) $totalEarnings,
                    'total_revenue' => (float) $totalRevenue,
                    'sold_out_products' => $soldOutProducts,
                    'low_stock_products' => $lowStockProducts,
                ],
                'order_status_counts' => $orderStatusCounts,
                'category_wise_products' => $categoryWiseProductCounts,
            ]
        ]);
    }

    /**
     * Get seller statistics by seller ID (for users/public)
     */
    public function getSellerStatisticsByID(Request $request)
    {
        $sellerId = $request->input('seller_id');

        if (!$sellerId) {
            return CommonHelper::responseError("Seller ID is required.");
        }

        $seller = Seller::find($sellerId);

        if (!$seller) {
            return CommonHelper::responseError("Seller not found.");
        }

        // Get only public statistics (no sensitive data like revenue, balance)
        $productCount = Product::where('seller_id', $seller->id)
            ->where('status', 1)
            ->count();

        $categoryWiseProductCounts = $this->getCategoryWiseProductCounts($seller->id, true); // Only active products

        return response()->json([
            'status' => 1,
            'message' => 'Seller statistics fetched successfully',
            'data' => [
                'seller_info' => [
                    'id' => $seller->id,
                    'name' => $seller->name ?? $seller->business_name,
                    'store_id' => $seller->store_id,
                ],
                'overview' => [
                    'total_products' => $productCount,
                ],
                'category_wise_products' => $categoryWiseProductCounts,
            ]
        ]);
    }

    /**
     * Get banners/sliders for authenticated seller based on their store
     */
    public function getSellerBanners(Request $request)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = Seller::where('admin_id', $admin->id)->with('store')->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        if (!$seller->store) {
            return CommonHelper::responseError("Store not found for this seller.");
        }

        $store = $seller->store;

        // Check if store is managed by admin
        $isManagedByAdmin = $store->managed_by_admin == 1;

        // Get sliders based on managed_by_admin status
        if ($isManagedByAdmin) {
            // For admin-managed stores, show sliders where store_id is null (global sliders)
            $sliders = Slider::whereNull('store_id')->get();
        } else {
            // For non-admin stores, show sliders matching this store_id
            $sliders = Slider::where('store_id', $store->id)->get();
        }

        return response()->json([
            'status' => 1,
            'message' => 'Banners fetched successfully',
            'data' => [
                'store_info' => [
                    'id' => $store->id,
                    'name' => $store->name,
                    'managed_by_admin' => $isManagedByAdmin,
                ],
                'banners' => $sliders,
            ]
        ]);
    }

    /**
     * Get store with category groups and categories for authenticated seller
     * For admin-managed stores, returns the store's category groups
     * For non-admin stores, returns empty category groups array
     */
    public function getSellerStoreWithCategories(Request $request)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = Seller::where('admin_id', $admin->id)->with('store')->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        if (!$seller->store) {
            return CommonHelper::responseError("Store not found for this seller.");
        }

        $store = $seller->store;

        // Check if store is managed by admin
        $isManagedByAdmin = $store->managed_by_admin == 1;

        // Get category groups based on managed_by_admin status
        $categoryGroups = [];

        if ($isManagedByAdmin) {
            // For admin-managed stores, get category groups associated with this store
            $categoryGroups = CategoryGroup::whereHas('stores', function($query) use ($store) {
                    $query->where('store_id', $store->id);
                })
                ->get()
                ->map(function($categoryGroup) {
                    // Get subcategory groups for this category group
                    $subCategoryGroups = SubCategoryGroup::where('category_group_id', $categoryGroup->id)
                        ->get()
                        ->map(function($subCategoryGroup) {
                            // Get categories for this subcategory group using subcategory_ids
                            $subcategoryIds = $subCategoryGroup->subcategory_ids
                                ? explode(',', $subCategoryGroup->subcategory_ids)
                                : [];

                            $categories = Category::whereIn('id', $subcategoryIds)->get()->map(function($category) {
                                return [
                                    'id' => $category->id,
                                    'name' => $category->name,
                                    'image_url' => $category->image_url ?? null,
                                    'parent_id' => $category->parent_id ?? null,
                                ];
                            });

                            return [
                                'id' => $subCategoryGroup->id,
                                'name' => $subCategoryGroup->name,
                                'image_url' => $subCategoryGroup->image_url ?? null,
                                'categories' => $categories,
                            ];
                        });

                    return [
                        'id' => $categoryGroup->id,
                        'name' => $categoryGroup->name,
                        'image_url' => $categoryGroup->image_url ?? null,
                        'status' => $categoryGroup->status,
                        'sub_category_groups' => $subCategoryGroups,
                    ];
                });
        }

        return response()->json([
            'status' => 1,
            'message' => 'Store data fetched successfully',
            'data' => [
                'store' => [
                    'id' => $store->id,
                    'name' => $store->name,
                    'description' => $store->description,
                    'icon_url' => $store->icon_url,
                    'image_url' => $store->image_url,
                    'vendor_img_url' => $store->vendor_img_url,
                    'managed_by_admin' => $isManagedByAdmin,
                    'is_super_mart' => $store->is_super_mart,
                    'is_active' => $store->is_active,
                ],
                'category_groups' => $categoryGroups,
            ]
        ]);
    }

    /**
     * Get products by category for authenticated seller
     * For admin-managed stores, returns products from all sellers in the store for the given category
     * For non-admin stores, returns only the seller's products for the given category
     */
    public function getSellerProductsByCategory(Request $request)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = Seller::where('admin_id', $admin->id)->with('store')->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        $categoryId = $request->input('category_id');

        if (!$categoryId) {
            return CommonHelper::responseError("Category ID is required.");
        }

        // Check if category exists
        $category = Category::find($categoryId);
        if (!$category) {
            return CommonHelper::responseError("Category not found.");
        }

        // Pagination parameters
        $perPage = $request->input('per_page', 20);
        $page = $request->input('page', 1);
        $offset = ($page - 1) * $perPage;
        $search = $request->input('search', '');

        // Check if store is managed by admin
        $isManagedByAdmin = $seller->store && $seller->store->managed_by_admin == 1;

        // Build query
        $query = Product::with(['variants', 'images', 'tax'])
            ->where('category_id', $categoryId);

        // If managed by admin, show all products in the store for this category
        // Otherwise, show only seller's products
        if ($isManagedByAdmin) {
            $query->where('store_id', $seller->store_id);
        } else {
            $query->where('seller_id', $seller->id);
        }

        // Apply search filter
        if (!empty($search)) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                  ->orWhere('slug', 'LIKE', "%{$search}%")
                  ->orWhere('description', 'LIKE', "%{$search}%");
            });
        }

        // Get total count
        $total = $query->count();

        // Get products with pagination
        $products = $query->orderBy('id', 'DESC')
            ->offset($offset)
            ->limit($perPage)
            ->get()
            ->map(function($product) {
                return [
                    'id' => $product->id,
                    'name' => $product->name,
                    'slug' => $product->slug,
                    'seller_id' => $product->seller_id,
                    'category_id' => $product->category_id,
                    'status' => $product->status,
                    'tax_id' => $product->tax_id,
                    'image' => $product->image,
                    'image_url' => $product->image ? (str_starts_with($product->image, 'http') ? $product->image : asset('storage/' . $product->image)) : null,
                    'indicator' => $product->indicator,
                    'is_approved' => $product->is_approved,
                    'manufacturer' => $product->manufacturer,
                    'made_in' => $product->made_in,
                    'type' => $product->type,
                    'description' => $product->description,
                    'created_at' => $product->created_at,
                    'variants' => $product->variants->map(function($variant) {
                        return [
                            'id' => $variant->id,
                            'product_id' => $variant->product_id,
                            'price' => (float) $variant->price,
                            'discounted_price' => (float) $variant->discounted_price,
                            'measurement' => $variant->measurement,
                            'stock' => (int) $variant->stock,
                            'stock_unit_id' => $variant->stock_unit_id,
                            'stock_unit_name' => $variant->stock_unit_name ?? null,
                            'status' => $variant->status,
                            'serve_for' => $variant->serve_for,
                            
                        ];
                    }),
                    'images' => $product->images ? $product->images->map(function($image) {
                        return [
                            'id' => $image->id,
                            'image' => $image->image,
                            'image_url' => $image->image ? (str_starts_with($image->image, 'http') ? $image->image : asset('storage/' . $image->image)) : null,
                        ];
                    }) : [],
                    'tax' => $product->tax,
                ];
            });

        return response()->json([
            'status' => 1,
            'message' => 'Products fetched successfully',
            'data' => [
                'category' => [
                    'id' => $category->id,
                    'name' => $category->name,
                    'image_url' => $category->image_url ?? null,
                ],
                'store_info' => [
                    'id' => $seller->store->id,
                    'name' => $seller->store->name,
                    'managed_by_admin' => $isManagedByAdmin,
                ],
                'products' => $products,
                'pagination' => [
                    'total' => $total,
                    'per_page' => $perPage,
                    'current_page' => $page,
                    'last_page' => ceil($total / $perPage),
                    'from' => $offset + 1,
                    'to' => min($offset + $perPage, $total),
                ]
            ]
        ]);
    }

    /**
     * Get order counts by status for a seller
     * Uses order_seller_status_tracking table for accurate seller-specific counts
     */
    private function getOrderStatusCounts($sellerId, $isManagedByAdmin = false, $storeId = null)
    {
        // Get all tracking records for this seller or store
        if ($isManagedByAdmin && $storeId) {
            // Get all orders for all sellers in this store
            $allTrackingRecords = DB::table('order_seller_status_tracking')
                ->whereIn('seller_id', function($query) use ($storeId) {
                    $query->select('id')
                          ->from('sellers')
                          ->where('store_id', $storeId);
                })
                ->get();
        } else {
            $allTrackingRecords = DB::table('order_seller_status_tracking')
                ->where('seller_id', $sellerId)
                ->get();
        }

        $sellerOrderIds = $allTrackingRecords->pluck('order_id')->toArray();

        // Count orders by mapped status
        $sellerStatusCounts = [];

        foreach ($allTrackingRecords as $tracking) {
            $mappedStatus = null;

            if ($tracking->status === 'packed_by_seller') {
                // Processed
                $mappedStatus = 3;
            } elseif ($tracking->status === 'given_to_delivery_partner') {
                // Shipped
                $mappedStatus = 4;
            } else {
                // For other statuses, use order's active_status
                $order = DB::table('orders')->where('id', $tracking->order_id)->first();
                $mappedStatus = $order ? (int) $order->active_status : null;
            }

            if ($mappedStatus !== null) {
                $sellerStatusCounts[$mappedStatus] = ($sellerStatusCounts[$mappedStatus] ?? 0) + 1;
            }
        }

        // Get order status list from database
        $orderStatusList = DB::table('order_status_lists')
            ->orderBy('id')
            ->get();

        $statusCounts = [];

        // Add total count
        $totalOrders = count($sellerOrderIds);
        $statusCounts[] = [
            'id' => 0,
            'status' => 'all',
            'status_name' => 'All Orders',
            'count' => $totalOrders,
        ];

        // Add counts for each status (excluding 1, 9, 10, 11 as per original logic)
        foreach ($orderStatusList as $statusItem) {
            if (in_array($statusItem->id, [1, 9, 10, 11])) {
                continue;
            }

            $statusCounts[] = [
                'id' => $statusItem->id,
                'status' => strtolower(str_replace(' ', '_', $statusItem->status)),
                'status_name' => $statusItem->status,
                'count' => $sellerStatusCounts[$statusItem->id] ?? 0,
            ];
        }

        return $statusCounts;
    }

    /**
     * Get category-wise product counts for a seller
     */
    private function getCategoryWiseProductCounts($sellerId, $onlyActive = false, $isManagedByAdmin = false, $storeId = null)
    {
        $query = Product::select('category_id', DB::raw('count(*) as product_count'))
            ->groupBy('category_id');

        // If managed by admin, show all products in the store, otherwise show only seller's products
        if ($isManagedByAdmin && $storeId) {
            $query->where('store_id', $storeId);
        } else {
            $query->where('seller_id', $sellerId);
        }

        if ($onlyActive) {
            $query->where('status', 1);
        }

        $categoryCounts = $query->get();

        $categoryWiseProducts = [];

        foreach ($categoryCounts as $item) {
            $category = Category::find($item->category_id);

            $categoryWiseProducts[] = [
                'category_id' => $item->category_id,
                'category_name' => $category ? $category->name : 'Unknown',
                'category_image_url' => $category ? $category->image_url : null,
                'product_count' => $item->product_count,
            ];
        }

        return $categoryWiseProducts;
    }

    /**
     * Get total revenue for a seller
     */
    private function getTotalRevenue($sellerId, $isManagedByAdmin = false, $storeId = null)
    {
        // Get total revenue from seller_wallet_transactions table (actual earnings)
        if ($isManagedByAdmin && $storeId) {
            // Get all sellers in this store
            $sellerIds = Seller::where('store_id', $storeId)->pluck('id');

            // Sum wallet transactions for all sellers in the store
            $revenue = SellerWalletTransaction::whereIn('seller_id', $sellerIds)
                ->whereIn('type', [
                    SellerWalletTransaction::TYPE_ORDER_COMMISSION,
                    SellerWalletTransaction::TYPE_CREDIT,
                    SellerWalletTransaction::TYPE_REFUND
                ])
                ->sum('amount');
        } else {
            // Sum wallet transactions for this seller
            $revenue = SellerWalletTransaction::where('seller_id', $sellerId)
                ->whereIn('type', [
                    SellerWalletTransaction::TYPE_ORDER_COMMISSION,
                    SellerWalletTransaction::TYPE_CREDIT,
                    SellerWalletTransaction::TYPE_REFUND
                ])
                ->whereDate('updated_at', today())
                ->sum('amount');
        }

        return $revenue ?? 0;
    }

    /**
     * Get today's orders count
     */
    private function getTodayOrdersCount($sellerId, $isManagedByAdmin = false, $storeId = null)
    {
        // Get order IDs from tracking table for this seller or store
        if ($isManagedByAdmin && $storeId) {
            // Get all orders for all sellers in this store
            $sellerOrderIds = DB::table('order_seller_status_tracking')
                ->whereIn('seller_id', function($query) use ($storeId) {
                    $query->select('id')
                          ->from('sellers')
                          ->where('store_id', $storeId);
                })
                ->distinct()
                ->pluck('order_id');
        } else {
            $sellerOrderIds = DB::table('order_seller_status_tracking')
                ->where('seller_id', $sellerId)
                ->distinct()
                ->pluck('order_id');
        }

        // Count orders created today
        return DB::table('orders')
            ->whereIn('id', $sellerOrderIds)
            ->whereDate('updated_at', today())
            ->count();
    }

    /**
     * Get pending orders count (payment_pending, received, processed)
     */
    private function getPendingOrdersCount($sellerId, $isManagedByAdmin = false, $storeId = null)
    {
        // Get order IDs from tracking table for this seller or store
        if ($isManagedByAdmin && $storeId) {
            // Get all orders for all sellers in this store
            $sellerOrderIds = DB::table('order_seller_status_tracking')
                ->whereIn('seller_id', function($query) use ($storeId) {
                    $query->select('id')
                          ->from('sellers')
                          ->where('store_id', $storeId);
                })
                ->distinct()
                ->pluck('order_id');
        } else {
            $sellerOrderIds = DB::table('order_seller_status_tracking')
                ->where('seller_id', $sellerId)
                ->distinct()
                ->pluck('order_id');
        }

        // Count orders with pending statuses
        return DB::table('orders')
            ->whereIn('id', $sellerOrderIds)
            ->whereIn('active_status', [1, 2, 3]) // 1 = Payment Pending, 2 = Received, 3 = Processed
            ->whereDate('created_at', today())
            ->count();
    }

    /**
     * Get completed (delivered) orders count
     */
    private function getCompletedOrdersCount($sellerId, $isManagedByAdmin = false, $storeId = null)
    {
        // Get order IDs from tracking table for this seller or store
        if ($isManagedByAdmin && $storeId) {
            // Get all orders for all sellers in this store
            $sellerOrderIds = DB::table('order_seller_status_tracking')
                ->whereIn('seller_id', function($query) use ($storeId) {
                    $query->select('id')
                          ->from('sellers')
                          ->where('store_id', $storeId);
                })
                ->distinct()
                ->pluck('order_id');
        } else {
            $sellerOrderIds = DB::table('order_seller_status_tracking')
                ->where('seller_id', $sellerId)
                ->distinct()
                ->pluck('order_id');
        }

        // Count delivered orders (status 6 = Delivered)
        return DB::table('orders')
            ->whereIn('id', $sellerOrderIds)
            ->where('active_status', 6)
            ->whereDate('updated_at', today())
            ->count();
    }

    /**
     * Get cancelled orders count
     */
    private function getCancelledOrdersCount($sellerId, $isManagedByAdmin = false, $storeId = null)
    {
        // Get order IDs from tracking table for this seller or store
        if ($isManagedByAdmin && $storeId) {
            // Get all orders for all sellers in this store
            $sellerOrderIds = DB::table('order_seller_status_tracking')
                ->whereIn('seller_id', function($query) use ($storeId) {
                    $query->select('id')
                          ->from('sellers')
                          ->where('store_id', $storeId);
                })
                ->distinct()
                ->pluck('order_id');
        } else {
            $sellerOrderIds = DB::table('order_seller_status_tracking')
                ->where('seller_id', $sellerId)
                ->distinct()
                ->pluck('order_id');
        }

        // Count cancelled orders (status 7 = Cancelled)
        return DB::table('orders')
            ->whereIn('id', $sellerOrderIds)
            ->where('active_status', 7)
            ->whereDate('updated_at', today())
            ->count();
    }

    /**
     * Get returned orders count
     */
    private function getReturnedOrdersCount($sellerId, $isManagedByAdmin = false, $storeId = null)
    {
        // Get order IDs from tracking table for this seller or store
        if ($isManagedByAdmin && $storeId) {
            // Get all orders for all sellers in this store
            $sellerOrderIds = DB::table('order_seller_status_tracking')
                ->whereIn('seller_id', function($query) use ($storeId) {
                    $query->select('id')
                          ->from('sellers')
                          ->where('store_id', $storeId);
                })
                ->distinct()
                ->pluck('order_id');
        } else {
            $sellerOrderIds = DB::table('order_seller_status_tracking')
                ->where('seller_id', $sellerId)
                ->distinct()
                ->pluck('order_id');
        }

        // Count returned orders (status 8 = Returned)
        return DB::table('orders')
            ->whereIn('id', $sellerOrderIds)
            ->where('active_status', 8)
            ->whereDate('updated_at', today())
            ->count();
    }

    /**
     * Get sold out products count (products with all variants having stock = 0)
     */
    private function getSoldOutProductsCount($sellerId, $isManagedByAdmin = false, $storeId = null)
    {
        // Get products where ALL variants have stock = 0
        $query = Product::whereDoesntHave('variants', function($query) {
                $query->where('stock', '>', 0);
            })
            ->whereHas('variants'); // Only count products that have variants

        // If managed by admin, show all products in the store, otherwise show only seller's products
        if ($isManagedByAdmin && $storeId) {
            $query->where('store_id', $storeId);
        } else {
            $query->where('seller_id', $sellerId);
        }

        return $query->count();
    }

    /**
     * Get low stock products count (products with any variant having stock <= 10 and > 0)
     */
    private function getLowStockProductsCount($sellerId, $isManagedByAdmin = false, $storeId = null)
    {
        // Get products where ANY variant has low stock (stock <= 10 and > 0)
        $query = Product::whereHas('variants', function($query) {
            $query->where('stock', '>', 0)
                  ->where('stock', '<=', 10);
        });

        // If managed by admin, show all products in the store, otherwise show only seller's products
        if ($isManagedByAdmin && $storeId) {
            $query->where('store_id', $storeId);
        } else {
            $query->where('seller_id', $sellerId);
        }

        return $query->count();
    }
}
