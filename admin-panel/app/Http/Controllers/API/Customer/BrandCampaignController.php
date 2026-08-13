<?php

namespace App\Http\Controllers\API\Customer;

use App\Http\Controllers\Controller;
use App\Models\BrandCampaign;
use App\Models\Product;
use App\Models\Category;
use App\Helpers\CommonHelper;
use Illuminate\Http\Request;

class BrandCampaignController extends Controller
{
    /**
     * Get the current active brand campaign
     * GET /api/customer/brand-campaigns
     */
    public function index(Request $request)
    {
        try {
            $campaign = BrandCampaign::current()->first();

            if (!$campaign) {
                return CommonHelper::responseWithData([
                    'campaign' => null,
                    'message' => 'No active campaign at the moment'
                ]);
            }

            return CommonHelper::responseWithData([
                'campaign' => $this->formatCampaignResponse($campaign),
            ]);
        } catch (\Exception $e) {
            return CommonHelper::responseError('Failed to fetch campaign: ' . $e->getMessage());
        }
    }

    /**
     * Get current campaign details with products
     * GET /api/customer/brand-campaigns/details
     */
    public function details(Request $request)
    {
        try {
            $campaign = BrandCampaign::current()->first();

            if (!$campaign) {
                return CommonHelper::responseWithData([
                    'campaign' => null,
                    'latest_products' => [],
                    'other_products' => [],
                    'message' => 'No active campaign at the moment'
                ]);
            }

            // Load products through pivot table with eager loading
            $allProducts = $campaign->products()
                ->with([
                    'store:id,name',
                    'seller:id,name',
                    'category:id,name',
                    'brand:id,name',
                    'tax:id,percentage',
                    'madeInCountry:id,name',
                    'variants' => function ($q) {
                        $q->where('status', '!=', 0)->orWhereNull('status');
                    },
                    'variants.images:id,product_variant_id,image',
                    'variants.stockUnit:id,short_code',
                    'images:id,product_id,image',
                    'tags:id,name'
                ])
                ->get()
                ->map(function ($product) {
                    return $this->formatProductResponse($product);
                });

            // Split products into two lists
            // Latest products: First 2 products
            $latestProducts = $allProducts->take(2)->values();

            // Other products: From 3rd to 5th product (max 3 products)
            $otherProducts = $allProducts->slice(2, 3)->values();

            return CommonHelper::responseWithData([
                'campaign' => $this->formatCampaignResponse($campaign),
                'latest_products' => $latestProducts,
                'other_products' => $otherProducts,
                'products_count' => count($allProducts),
                'days_until_expiry' => $campaign->daysUntilExpiry(),
            ]);
        } catch (\Exception $e) {
            return CommonHelper::responseError('Failed to fetch campaign details: ' . $e->getMessage());
        }
    }

    /**
     * Get campaign by specific ID
     * GET /api/customer/brand-campaigns/{id}
     */
    public function show($id)
    {
        try {
            $campaign = BrandCampaign::find($id);

            if (!$campaign) {
                return CommonHelper::responseError('Campaign not found');
            }

            if (!$campaign->isActive()) {
                return CommonHelper::responseError('This campaign is no longer active');
            }

            // Load products through pivot table with eager loading
            $allProducts = $campaign->products()
                ->with([
                    'store:id,name',
                    'seller:id,name',
                    'category:id,name',
                    'brand:id,name',
                    'tax:id,percentage',
                    'madeInCountry:id,name',
                    'variants' => function ($q) {
                        $q->where('status', '!=', 0)->orWhereNull('status');
                    },
                    'variants.images:id,product_variant_id,image',
                    'variants.stockUnit:id,short_code',
                    'images:id,product_id,image',
                    'tags:id,name'
                ])
                ->get()
                ->map(function ($product) {
                    return $this->formatProductResponse($product);
                });

            // Split products into two lists
            // Latest products: First 2 products
            $latestProducts = $allProducts->take(2)->values();

            // Other products: From 3rd to 5th product (max 3 products)
            $otherProducts = $allProducts->slice(2, 3)->values();

            return CommonHelper::responseWithData([
                'campaign' => $this->formatCampaignResponse($campaign),
                'latest_products' => $latestProducts,
                'other_products' => $otherProducts,
                'products_count' => count($allProducts),
                'days_until_expiry' => $campaign->daysUntilExpiry(),
            ]);
        } catch (\Exception $e) {
            return CommonHelper::responseError('Failed to fetch campaign: ' . $e->getMessage());
        }
    }

    /**
     * Get all campaign products with pagination, search, and category filter
     * GET /api/customer/brand-campaigns/products
     *
     * Query params:
     * - campaign_id: required
     * - page: optional (default: 1)
     * - per_page: optional (default: 20)
     * - search: optional (search by product name)
     * - category_id: optional (filter by category)
     */
    public function getProducts(Request $request)
    {
        try {
            $campaignId = $request->input('campaign_id');

            if (!$campaignId) {
                return CommonHelper::responseError('Campaign ID is required');
            }

            $campaign = BrandCampaign::find($campaignId);

            if (!$campaign) {
                return CommonHelper::responseError('Campaign not found');
            }

            if (!$campaign->isActive()) {
                return CommonHelper::responseError('This campaign is no longer active');
            }

            // Get pagination params
            $perPage = (int) $request->input('per_page', 20);
            $search = $request->input('search', '');
            $categoryId = $request->input('category_id', null);

            // Build query using pivot table relationship
            $query = $campaign->products()
                ->with([
                    'store:id,name',
                    'seller:id,name',
                    'category:id,name',
                    'brand:id,name',
                    'tax:id,percentage',
                    'madeInCountry:id,name',
                    'variants' => function ($q) {
                        $q->where('status', '!=', 0)->orWhereNull('status');
                    },
                    'variants.images:id,product_variant_id,image',
                    'variants.stockUnit:id,short_code',
                    'images:id,product_id,image',
                    'tags:id,name'
                ]);

            // Apply search filter
            if (!empty($search)) {
                $query->where('name', 'like', '%' . $search . '%');
            }

            // Apply category filter
            if ($categoryId) {
                $query->where('category_id', $categoryId);
            }

            // Get paginated results
            $paginatedProducts = $query->paginate($perPage);

            // Format products
            $formattedProducts = $paginatedProducts->map(function ($product) {
                return $this->formatProductResponse($product);
            });

            // Get all categories from campaign products using pivot table
            $categoryIds = $campaign->products()
                ->distinct()
                ->pluck('category_id')
                ->filter()
                ->toArray();

            $categories = Category::whereIn('id', $categoryIds)
                ->select('id', 'name')
                ->orderBy('name', 'asc')
                ->get();

            // Group products by category for statistics using pivot table
            $productsByCategory = $campaign->products()
                ->select('category_id', \DB::raw('count(*) as count'))
                ->groupBy('category_id')
                ->get()
                ->keyBy('category_id');

            // Add product count to categories
            $categoriesWithCount = $categories->map(function ($category) use ($productsByCategory) {
                $categoryStats = $productsByCategory->get($category->id);
                return [
                    'id' => $category->id,
                    'name' => $category->name,
                    'product_count' => $categoryStats ? $categoryStats->count : 0
                ];
            });

            return CommonHelper::responseWithData([
                'products' => $formattedProducts,
                'categories' => $categoriesWithCount,
                'pagination' => [
                    'total' => $paginatedProducts->total(),
                    'per_page' => $paginatedProducts->perPage(),
                    'current_page' => $paginatedProducts->currentPage(),
                    'last_page' => $paginatedProducts->lastPage(),
                    'from' => $paginatedProducts->firstItem() ?? 0,
                    'to' => $paginatedProducts->lastItem() ?? 0,
                ]
            ]);

        } catch (\Exception $e) {
            return CommonHelper::responseError('Failed to fetch campaign products: ' . $e->getMessage());
        }
    }

    /**
     * Format product response with full details
     */
    private function formatProductResponse($product): array
    {
        // Get comprehensive rating data using CommonHelper
        $ratingData = \App\Helpers\CommonHelper::productAverageRating($product->id);

        $variants = [];
        if ($product->variants && is_countable($product->variants) && count($product->variants) > 0) {
            $variants = $product->variants->map(function ($variant) {
                $variantImages = [];
                if ($variant->images && is_countable($variant->images) && count($variant->images) > 0) {
                    $variantImages = $variant->images->pluck('image')->toArray();
                }
                return [
                    'id' => $variant->id,
                    'type' => $variant->type,
                    'measurement' => $variant->measurement,
                    'price' => (int) $variant->price,
                    'discounted_price' => (int) ($variant->discounted_price ?? 0),
                    'stock' => (int) $variant->stock,
                    'status' => (int) ($variant->status ?? 1),
                    'stock_unit_name' => ($variant->stockUnit && is_object($variant->stockUnit)) ? $variant->stockUnit->short_code : null,
                    'images' => $variantImages,
                ];
            })->toArray();
        }

        $images = [];
        if ($product->images && is_countable($product->images) && count($product->images) > 0) {
            $images = $product->images->pluck('image')->toArray();
        }

        $tagNames = [];
        if ($product->tags && is_countable($product->tags) && count($product->tags) > 0) {
            $tagNames = $product->tags->pluck('name')->toArray();
        }

        return [
            'id' => $product->id,
            'name' => $product->name,
            'slug' => $product->slug,
            'description' => $product->description,
            'image' => $product->image,
            'image_url' => $product->image_url,
            'images' => $images,
            'seller_id' => $product->seller_id,
            'seller_name' => ($product->seller && is_object($product->seller)) ? $product->seller->name : null,
            'category_id' => $product->category_id,
            'category_name' => ($product->category && is_object($product->category)) ? $product->category->name : null,
            'brand_id' => $product->brand_id,
            'brand_name' => ($product->brand && is_object($product->brand)) ? $product->brand->name : null,
            'tax_id' => $product->tax_id,
            'tax_percentage' => ($product->tax && is_object($product->tax)) ? (int) $product->tax->percentage : 0,
            'indicator' => $product->indicator,
            'manufacturer' => $product->manufacturer,
            'made_in' => $product->made_in,
            'made_in_country' => ($product->madeInCountry && is_object($product->madeInCountry)) ? $product->madeInCountry->name : null,
            'status' => $product->status,
            'is_approved' => (bool) $product->is_approved,
            'return_status' => (bool) $product->return_status,
            'cancelable_status' => (bool) $product->cancelable_status,
            'till_status' => (bool) $product->till_status,
            'return_days' => (int) ($product->return_days ?? 0),
            'fssai_lic_no' => $product->fssai_lic_no,
            'barcode' => $product->barcode,
            'meta_title' => $product->meta_title,
            'meta_description' => $product->meta_description,
            'meta_keyword' => $product->meta_keyword,
            'schema_markup' => $product->schema_markup,
            'average_rating' => (float) $ratingData['average_rating'],
            'rating_count' => (int) $ratingData['rating_count'],
            'one_star_rating' => (int) $ratingData['one_star_rating'],
            'two_star_rating' => (int) $ratingData['two_star_rating'],
            'three_star_rating' => (int) $ratingData['three_star_rating'],
            'four_star_rating' => (int) $ratingData['four_star_rating'],
            'five_star_rating' => (int) $ratingData['five_star_rating'],
            'tag_names' => $tagNames,
            'variants' => $variants,
            'seller' => ($product->seller && is_object($product->seller)) ? ['id' => $product->seller->id, 'name' => $product->seller->name] : null,
            'store' => ($product->store && is_object($product->store)) ? ['id' => $product->store->id, 'name' => $product->store->name] : null,
            'category' => ($product->category && is_object($product->category)) ? ['id' => $product->category->id, 'name' => $product->category->name] : null,
        ];
    }

    /**
     * Format campaign response
     */
    private function formatCampaignResponse($campaign): array
    {
        return [
            'id' => $campaign->id,
            'name' => $campaign->name,
            'description' => $campaign->description,
            'primary_image_url' => $campaign->primary_image_url,
            'secondary_image_url' => $campaign->secondary_image_url,
            'banners' => $campaign->banners ?? [],
            'brand_id' => $campaign->brand_id,
            'brand_name' => $campaign->brand ? $campaign->brand->name : null,
            'product_ids' => $campaign->product_ids ?? [],
            'category_ids' => $campaign->category_ids ?? [],
            'campaign_type' => $campaign->campaign_type,
            'theme_color' => $campaign->theme_color,
            'start_date' => $campaign->start_date->format('Y-m-d H:i:s'),
            'end_date' => $campaign->end_date->format('Y-m-d H:i:s'),
            'expired_at' => $campaign->expired_at ? $campaign->expired_at->format('Y-m-d H:i:s') : null,
            'is_active' => $campaign->isActive(),
            'is_expired' => $campaign->isExpired(),
            'is_featured' => (bool) $campaign->is_featured,
            'display_order' => $campaign->display_order,
            'days_until_expiry' => $campaign->daysUntilExpiry(),
            'metadata' => $campaign->metadata ?? [],
        ];
    }
}
