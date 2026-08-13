<?php

namespace App\Http\Controllers\API\Customer;

use App\Http\Controllers\Controller;
use App\Models\CustomerAppSection;
use App\Models\CustomerAppSectionProduct;
use App\Models\Product;
use App\Helpers\CommonHelper;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CustomerAppSectionController extends Controller
{
    /**
     * Get all sections with products
     * GET /api/customer/home-sections
     */
    public function index(Request $request)
    {
        try {
            $perPage = $request->input('per_page', 2); // 2 sections per page by default
            $sections = CustomerAppSection::orderBy('order', 'ASC')->paginate($perPage);

            $sectionsWithProducts = $sections->map(function ($section) {
                // Get products with their display order
                $sectionProducts = CustomerAppSectionProduct::where('section_id', $section->id)
                    ->orderBy('display_order', 'ASC')
                    ->get();

                $products = [];
                if ($sectionProducts->isNotEmpty()) {
                    // Get product IDs in order
                    $productIds = $sectionProducts->pluck('product_id')->toArray();

                    // Fetch products
                    $productModels = Product::whereIn('id', $productIds)
                        ->where('status', 1)
                        ->where('is_approved', 1)
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
                            'images:id,product_id,image'
                        ])
                        ->get()
                        ->keyBy('id'); // Key by product ID for easy lookup

                    // Sort products according to display_order
                    foreach ($productIds as $productId) {
                        if (isset($productModels[$productId])) {
                            $products[] = $this->formatProductResponse($productModels[$productId]);
                        }
                    }
                }

                return [
                    'id' => $section->id,
                    'name' => $section->name,
                    'order' => $section->order,
                    'products' => $products,
                    'products_count' => count($products),
                ];
            });

            return CommonHelper::responseWithData([
                'sections' => $sectionsWithProducts,
                'current_page' => $sections->currentPage(),
                'total_pages' => $sections->lastPage(),
                'per_page' => $sections->perPage(),
                'total_sections' => $sections->total(),
            ]);
        } catch (\Exception $e) {
            return CommonHelper::responseError('Failed to fetch sections: ' . $e->getMessage());
        }
    }

    /**
     * Get specific section with products
     * GET /api/customer/home-sections/{id}
     */
    public function show($id)
    {
        try {
            $section = CustomerAppSection::find($id);

            if (!$section) {
                return CommonHelper::responseError('Section not found');
            }

            // Get products with their display order
            $sectionProducts = CustomerAppSectionProduct::where('section_id', $section->id)
                ->orderBy('display_order', 'ASC')
                ->get();

            $products = [];
            if ($sectionProducts->isNotEmpty()) {
                // Get product IDs in order
                $productIds = $sectionProducts->pluck('product_id')->toArray();

                // Fetch products
                $productModels = Product::whereIn('id', $productIds)
                    ->where('status', 1)
                    ->where('is_approved', 1)
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
                        'images:id,product_id,image'
                    ])
                    ->get()
                    ->keyBy('id'); // Key by product ID for easy lookup

                // Sort products according to display_order
                foreach ($productIds as $productId) {
                    if (isset($productModels[$productId])) {
                        $products[] = $this->formatProductResponse($productModels[$productId]);
                    }
                }
            }

            return CommonHelper::responseWithData([
                'section' => [
                    'id' => $section->id,
                    'name' => $section->name,
                    'order' => $section->order,
                ],
                'products' => $products,
                'products_count' => count($products),
            ]);
        } catch (\Exception $e) {
            return CommonHelper::responseError('Failed to fetch section: ' . $e->getMessage());
        }
    }

    /**
     * Format product response with full details (same as BrandCampaign)
     */
    private function formatProductResponse($product): array
    {
        // Get ratings from order_product_ratings table
        $ratings = DB::table('order_product_ratings')
            ->where('product_id', $product->id)
            ->pluck('rating')
            ->map(function ($rating) {
                return (float) $rating;
            })
            ->toArray();

        // If no ratings available, generate random rating between 4.0 and 4.5
        if (empty($ratings)) {
            $averageRating = round(4.0 + (mt_rand(0, 50) / 100), 1); // Random between 4.0 and 4.5
            $ratingCount = mt_rand(10, 50); // Random count between 10 and 50
        } else {
            $averageRating = array_sum($ratings) / count($ratings);
            $ratingCount = count($ratings);
        }

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
        if ($product->tags) {
            // Check if tags is a relationship (collection) or a string
            if (is_string($product->tags)) {
                // Tags is a comma-separated string
                $tagNames = array_filter(array_map('trim', explode(',', $product->tags)));
            } elseif (is_object($product->tags) && method_exists($product->tags, 'pluck')) {
                // Tags is a relationship (collection)
                $tagNames = $product->tags->pluck('name')->toArray();
            }
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
            'average_rating' => (float) $averageRating,
            'average_rating_num' => (float) $averageRating,
            'rating_count' => $ratingCount,
            'ratings' => $ratings,
            'tag_names' => $tagNames,
            'variants' => $variants,
            'seller' => ($product->seller && is_object($product->seller)) ? ['id' => $product->seller->id, 'name' => $product->seller->name] : null,
            'store' => ($product->store && is_object($product->store)) ? ['id' => $product->store->id, 'name' => $product->store->name] : null,
            'category' => ($product->category && is_object($product->category)) ? ['id' => $product->category->id, 'name' => $product->category->name] : null,
        ];
    }
}