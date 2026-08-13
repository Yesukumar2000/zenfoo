<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\ProductImages;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ProductImagesApiController extends Controller
{
    /**
     * Get product image URLs for Flutter app lazy loading
     * Returns images in a paginated format optimized for scrollable animations
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getProductImages(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'limit' => 'nullable|integer|min:1|max:100',
            'offset' => 'nullable|integer|min:0',
            'product_id' => 'nullable|integer',
            'status' => 'nullable|integer|in:0,1',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $limit = $request->input('limit', 100);
        $offset = $request->input('offset', 0);
        $productId = $request->input('product_id');
        $status = $request->input('status', 1);

        $query = Product::query()
            ->select('id', 'name', 'slug', 'image', 'other_images')
            ->where('status', $status);

        // Filter by specific product ID if provided
        if ($productId) {
            $query->where('id', $productId);
        }

        // Only get products that have images
        $query->where(function($q) {
            $q->where('image', '!=', '')
              ->orWhereNotNull('other_images');
        });

        // Get total count
        $total = $query->count();

        // Get products with pagination
        $products = $query->orderBy('id', 'DESC')
            ->offset($offset)
            ->limit($limit)
            ->get();

        if ($products->isEmpty()) {
            return CommonHelper::responseError('No products with images found.');
        }

        // Format the response for Flutter
        $imageData = [];

        foreach ($products as $product) {
            $productImages = [];

            // Add main product image
            if (!empty($product->image)) {
                $imageUrl = str_starts_with($product->image, 'http')
                    ? $product->image
                    : url('storage/' . $product->image);

                $productImages[] = [
                    'url' => $imageUrl,
                    'type' => 'main',
                    'alt_text' => $product->name,
                ];
            }

            // Add other images if available
            if (!empty($product->other_images)) {
                $otherImages = is_string($product->other_images)
                    ? json_decode($product->other_images, true)
                    : $product->other_images;

                if (is_array($otherImages)) {
                    foreach ($otherImages as $index => $otherImage) {
                        $imageUrl = str_starts_with($otherImage, 'http')
                            ? $otherImage
                            : url('storage/' . $otherImage);

                        $productImages[] = [
                            'url' => $imageUrl,
                            'type' => 'gallery',
                            'alt_text' => $product->name . ' - Image ' . ($index + 1),
                        ];
                    }
                }
            }

            // Add product variant images if available
            $variantImages = ProductImages::where('product_id', $product->id)
                ->select('image')
                ->get();

            foreach ($variantImages as $variantImage) {
                if (!empty($variantImage->image)) {
                    $imageUrl = str_starts_with($variantImage->image, 'http')
                        ? $variantImage->image
                        : url('storage/' . $variantImage->image);

                    $productImages[] = [
                        'url' => $imageUrl,
                        'type' => 'variant',
                        'alt_text' => $product->name . ' - Variant',
                    ];
                }
            }

            // Only add product to response if it has images
            if (!empty($productImages)) {
                $imageData[] = [
                    'product_id' => $product->id,
                    'product_name' => $product->name,
                    'product_slug' => $product->slug,
                    'images' => $productImages,
                    'image_count' => count($productImages),
                ];
            }
        }

        // Response format optimized for Flutter lazy loading
        $response = [
            'status' => 1,
            'message' => 'Product images fetched successfully',
            'data' => $imageData,
            'total' => $total,
            'limit' => $limit,
            'offset' => $offset,
            'has_more' => ($offset + $limit) < $total,
        ];

        return response()->json($response);
    }

    /**
     * Get all image URLs in a flat array format
     * Useful for simple image galleries and preloading
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getFlatImageUrls(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'limit' => 'nullable|integer|min:1|max:100',
            'offset' => 'nullable|integer|min:0',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $limit = $request->input('limit', 100);
        $offset = $request->input('offset', 0);

        $products = Product::select('id', 'name', 'image')
            ->where('status', 1)
            ->where('image', '!=', '')
            ->orderBy('id', 'DESC')
            ->offset($offset)
            ->limit($limit)
            ->get();

        $imageUrls = [];

        foreach ($products as $product) {
            if (!empty($product->image)) {
                $imageUrl = str_starts_with($product->image, 'http')
                    ? $product->image
                    : url('storage/' . $product->image);

                $imageUrls[] = [
                    'product_id' => $product->id,
                    'url' => $imageUrl,
                    'name' => $product->name,
                ];
            }
        }

        $response = [
            'status' => 1,
            'message' => 'Image URLs fetched successfully',
            'data' => $imageUrls,
            'count' => count($imageUrls),
        ];

        return response()->json($response);
    }
}
