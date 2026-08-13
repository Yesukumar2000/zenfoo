<?php

namespace App\Http\Controllers\API\Admin;

use App\Http\Controllers\Controller;
use App\Models\BrandCampaign;
use App\Models\BrandCampaignProduct;
use App\Models\Product;
use App\Helpers\CommonHelper;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class BrandCampaignProductController extends Controller
{
    /**
     * Get all campaign products
     * GET /api/admin/brand-campaign-products
     */
    public function index(Request $request)
    {
        try {
            $query = BrandCampaignProduct::with([
                'campaign:id,name,brand_id',
                'campaign.brand:id,name',
                'product:id,name,image,slug,category_id',
                'product.category:id,name'
            ])->orderBy('created_at', 'desc');

            // Filter by campaign
            if ($request->filled('campaign_id')) {
                $query->where('brand_campaign_id', $request->campaign_id);
            }

            $campaignProducts = $query->get()->map(function ($cp) {
                $imageUrl = null;
                if ($cp->product && $cp->product->image) {
                    $imageUrl = $cp->product->image;
                    if (!str_starts_with($imageUrl, 'http')) {
                        $imageUrl = url('storage/' . $imageUrl);
                    }
                }

                return [
                    'id' => $cp->id,
                    'campaign_id' => $cp->brand_campaign_id,
                    'campaign_name' => $cp->campaign->name ?? null,
                    'brand_id' => $cp->campaign->brand_id ?? null,
                    'brand_name' => $cp->campaign->brand->name ?? null,
                    'product_id' => $cp->product_id,
                    'product_name' => $cp->product->name ?? null,
                    'product_image' => $cp->product->image ?? null,
                    'product_image_url' => $imageUrl,
                    'product_slug' => $cp->product->slug ?? null,
                    'category_name' => $cp->product->category->name ?? null,
                    'display_order' => $cp->display_order,
                    'created_at' => $cp->created_at?->format('Y-m-d H:i:s'),
                ];
            });

            return CommonHelper::responseWithData($campaignProducts);
        } catch (\Exception $e) {
            Log::error('Failed to fetch campaign products', ['error' => $e->getMessage()]);
            return CommonHelper::responseError('Failed to fetch campaign products');
        }
    }

    /**
     * Get products available for a campaign (based on brand)
     * GET /api/admin/brand-campaign-products/available-products
     */
    public function getAvailableProducts(Request $request)
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

            if (!$campaign->brand_id) {
                return CommonHelper::responseError('Campaign must have a brand assigned');
            }

            // Get products from the campaign's brand
            $products = Product::where('brand_id', $campaign->brand_id)
                ->select('id', 'name', 'image', 'slug', 'brand_id', 'category_id')
                ->with([
                    'category:id,name',
                    'brand:id,name'
                ])
                ->get()
                ->map(function ($product) {
                    return [
                        'id' => $product->id,
                        'name' => $product->name,
                        'image' => $product->image,
                        'image_url' => $product->image ? url('storage/' . $product->image) : null,
                        'slug' => $product->slug,
                        'category_name' => $product->category->name ?? null,
                        'brand_name' => $product->brand->name ?? null,
                    ];
                });

            return CommonHelper::responseWithData([
                'products' => $products,
                'campaign' => [
                    'id' => $campaign->id,
                    'name' => $campaign->name,
                    'brand_id' => $campaign->brand_id,
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to fetch available products', ['error' => $e->getMessage()]);
            return CommonHelper::responseError('Failed to fetch available products');
        }
    }

    /**
     * Add product to campaign
     * POST /api/admin/brand-campaign-products
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'brand_campaign_id' => 'required|exists:brand_campaigns,id',
            'product_id' => 'required|exists:products,id',
            'display_order' => 'nullable|integer|min:0',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            // Check if product already exists in campaign
            $exists = BrandCampaignProduct::where('brand_campaign_id', $request->brand_campaign_id)
                ->where('product_id', $request->product_id)
                ->exists();

            if ($exists) {
                return CommonHelper::responseError('This product is already added to the campaign');
            }

            // Verify product brand matches campaign brand
            $campaign = BrandCampaign::find($request->brand_campaign_id);
            $product = Product::find($request->product_id);

            if ($campaign->brand_id && $product->brand_id !== $campaign->brand_id) {
                return CommonHelper::responseError('Product brand does not match campaign brand');
            }

            // Get next display order if not provided
            $displayOrder = $request->display_order ?? BrandCampaignProduct::where('brand_campaign_id', $request->brand_campaign_id)->max('display_order') + 1;

            $campaignProduct = BrandCampaignProduct::create([
                'brand_campaign_id' => $request->brand_campaign_id,
                'product_id' => $request->product_id,
                'display_order' => $displayOrder,
            ]);

            return CommonHelper::responseWithData([
                'campaign_product' => $campaignProduct->load('campaign', 'product'),
                'message' => 'Product added to campaign successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to add product to campaign', ['error' => $e->getMessage()]);
            return CommonHelper::responseError('Failed to add product to campaign: ' . $e->getMessage());
        }
    }

    /**
     * Update campaign product (mainly display order)
     * PUT /api/admin/brand-campaign-products/{id}
     */
    public function update(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'display_order' => 'required|integer|min:0',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $campaignProduct = BrandCampaignProduct::findOrFail($id);
            $campaignProduct->update([
                'display_order' => $request->display_order,
            ]);

            return CommonHelper::responseWithData([
                'campaign_product' => $campaignProduct->load('campaign', 'product'),
                'message' => 'Campaign product updated successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update campaign product', ['id' => $id, 'error' => $e->getMessage()]);
            return CommonHelper::responseError('Failed to update campaign product');
        }
    }

    /**
     * Delete product from campaign
     * DELETE /api/admin/brand-campaign-products/{id}
     */
    public function destroy($id)
    {
        try {
            $campaignProduct = BrandCampaignProduct::findOrFail($id);
            $campaignProduct->delete();

            return CommonHelper::responseWithData(['message' => 'Product removed from campaign successfully']);
        } catch (\Exception $e) {
            Log::error('Failed to delete campaign product', ['id' => $id, 'error' => $e->getMessage()]);
            return CommonHelper::responseError('Failed to remove product from campaign');
        }
    }

    /**
     * Bulk update display orders
     * POST /api/admin/brand-campaign-products/reorder
     */
    public function reorder(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'items' => 'required|array|min:1',
            'items.*.id' => 'required|exists:brand_campaign_products,id',
            'items.*.display_order' => 'required|integer|min:0',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        DB::beginTransaction();
        try {
            foreach ($request->items as $item) {
                BrandCampaignProduct::where('id', $item['id'])
                    ->update(['display_order' => $item['display_order']]);
            }

            DB::commit();
            return CommonHelper::responseWithData(['message' => 'Products reordered successfully']);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Failed to reorder campaign products', ['error' => $e->getMessage()]);
            return CommonHelper::responseError('Failed to reorder products');
        }
    }

    /**
     * Delete all products from a campaign
     * DELETE /api/admin/brand-campaign-products/delete-all/{campaignId}
     */
    public function deleteAll($campaignId)
    {
        try {
            $campaign = BrandCampaign::find($campaignId);

            if (!$campaign) {
                return CommonHelper::responseError('Campaign not found');
            }

            // Delete all products for this campaign
            BrandCampaignProduct::where('brand_campaign_id', $campaignId)->delete();

            return CommonHelper::responseWithData(['message' => 'All products removed from campaign successfully']);
        } catch (\Exception $e) {
            Log::error('Failed to delete all campaign products', ['campaign_id' => $campaignId, 'error' => $e->getMessage()]);
            return CommonHelper::responseError('Failed to remove products from campaign');
        }
    }
}