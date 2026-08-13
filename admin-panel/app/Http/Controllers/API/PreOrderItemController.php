<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Product;
use Illuminate\Support\Facades\DB;

class PreOrderItemController extends Controller
{
    /**
     * Get all pre-order items from all stores
     */
    public function getAllPreOrderItems()
    {
        try {
            // Get all products that are marked as pre-order items
            $products = Product::with(['category', 'variants.unit'])
                ->where('is_pre_order_item', 1)
                ->where('status', 1)
                ->get();

            // Format products for frontend
            $formattedProducts = $products->map(function ($product) {
                return [
                    'id' => $product->id,
                    'name' => $product->name,
                    'image' => $product->image,
                    'image_url' => $product->image_url,
                    'store_id' => $product->store_id,
                    'category_id' => $product->category_id,
                    'category_name' => $product->category->name ?? null,
                    'is_pre_order_item' => $product->is_pre_order_item ?? 0,
                    'variants' => $product->variants ?? []
                ];
            });

            return response()->json([
                'status' => 1,
                'products' => $formattedProducts
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 0,
                'message' => 'Error fetching pre-order items: ' . $e->getMessage(),
                'products' => []
            ], 500);
        }
    }

    /**
     * Get products for pre-order item selection
     * with filters for store, category group, sub category group, and category
     */
    public function getProducts(Request $request)
    {
        try {
            $storeIds = $request->input('store_ids');
            $categoryGroupId = $request->input('category_group_id');
            $subCategoryGroupId = $request->input('sub_category_group_id');
            $categoryId = $request->input('category_id');

            if (!$storeIds) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Please provide store IDs',
                    'products' => []
                ], 400);
            }

            // Convert comma-separated string to array
            $storeIdsArray = is_array($storeIds) ? $storeIds : explode(',', $storeIds);

            // Build query
            $query = Product::with(['category', 'variants.unit'])
                ->whereIn('store_id', $storeIdsArray)
                ->where('status', 1); // Only active products

            // Apply category group filter
            if ($categoryGroupId) {
                $query->where('category_group_id', $categoryGroupId);
            }

            // Apply sub category group filter
            if ($subCategoryGroupId) {
                $query->where('sub_category_group_id', $subCategoryGroupId);
            }

            // Apply category filter
            if ($categoryId) {
                $query->where('category_id', $categoryId);
            }

            $products = $query->get();

            // Format products for frontend
            $formattedProducts = $products->map(function ($product) {
                return [
                    'id' => $product->id,
                    'name' => $product->name,
                    'image' => $product->image,
                    'image_url' => $product->image_url,
                    'store_id' => $product->store_id,
                    'category_id' => $product->category_id,
                    'category_name' => $product->category->name ?? null,
                    'is_pre_order_item' => $product->is_pre_order_item ?? 0,
                    'variants' => $product->variants ?? []
                ];
            });

            return response()->json([
                'status' => 1,
                'products' => $formattedProducts
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 0,
                'message' => 'Error fetching products: ' . $e->getMessage(),
                'products' => []
            ], 500);
        }
    }

    /**
     * Save pre-order items
     * Updates is_pre_order_item column for selected products
     */
    public function savePreOrderItems(Request $request)
    {
        try {
            $productIds = $request->input('product_ids', []);
            $storeIds = $request->input('store_ids', []);

            if (empty($storeIds)) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Please select at least one store'
                ], 400);
            }

            DB::beginTransaction();

            // First, reset all products in the selected stores to non-pre-order
            Product::whereIn('store_id', $storeIds)
                ->update(['is_pre_order_item' => 0]);

            // Then set selected products as pre-order items
            if (!empty($productIds)) {
                Product::whereIn('id', $productIds)
                    ->whereIn('store_id', $storeIds)
                    ->update(['is_pre_order_item' => 1]);
            }

            DB::commit();

            return response()->json([
                'status' => 1,
                'message' => count($productIds) . ' product(s) marked as pre-order items successfully'
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'status' => 0,
                'message' => 'Error saving pre-order items: ' . $e->getMessage()
            ], 500);
        }
    }
}
