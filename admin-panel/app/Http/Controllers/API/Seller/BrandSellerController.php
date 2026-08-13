<?php

namespace App\Http\Controllers\API\Seller;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Seller;
use App\Models\Brand;
use App\Services\MediaUploadService;
use Validator;
use Exception;
use App\Helpers\CommonHelper;

class BrandSellerController extends Controller
{
    /**
     * Get all brands with pagination and search
     */
    public function getAllBrands(Request $request)
    {
        try {
            $seller = auth()->user()->seller;

            if (!$seller) {
                return CommonHelper::responseError('Seller not found!');
            }

            $query = Brand::where('seller_id', $seller->id);

            // Search functionality
            if ($request->has('search') && !empty($request->search)) {
                $search = $request->search;
                $query->where(function($q) use ($search) {
                    $q->where('name', 'like', "%$search%")
                      ->orWhere('category_ids', 'like', "%$search%");
                });
            }

            // Filter by status if provided
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filter by category_id if provided
            if ($request->has('category_id') && !empty($request->category_id)) {
                $categoryId = (int) $request->category_id;
                $query->whereJsonContains('category_ids', $categoryId);
            }

            // Pagination parameters
            $perPage = $request->input('per_page', 10);
            $page = $request->input('page', 1);

            // Get paginated results
            $brands = $query->orderBy('created_at', 'desc')
                ->paginate($perPage, ['*'], 'page', $page);

            return CommonHelper::responseWithData([
                'total' => $brands->total(),
                'per_page' => $brands->perPage(),
                'current_page' => $brands->currentPage(),
                'last_page' => $brands->lastPage(),
                'data' => $brands->items()
            ]);

        } catch (Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get a single brand by ID
     */
    public function show($id)
    {
        try {
            $seller = auth()->user()->seller;

            if (!$seller) {
                return CommonHelper::responseError('Seller not found!');
            }

            $brand = Brand::where('id', $id)
                ->where('seller_id', $seller->id)
                ->first();

            if (!$brand) {
                return CommonHelper::responseError('Brand not found or you do not have permission to view it!');
            }

            return CommonHelper::responseWithData($brand);

        } catch (Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Create a new brand
     */
    public function store(Request $request)
    {
        try {
            $seller = auth()->user()->seller;

            if (!$seller) {
                return CommonHelper::responseError('Seller not found!');
            }

            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'status' => 'required|boolean',
                'category_ids' => 'nullable|array',
                'category_ids.*' => 'integer',
                'image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:5120'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Ensure category_ids are stored as integers
            $categoryIds = $request->category_ids ? array_map('intval', $request->category_ids) : null;

            // If id is provided, update existing brand
            if ($request->has('id') && $request->id) {
                $brand = Brand::where('id', $request->id)
                    ->where('seller_id', $seller->id)
                    ->first();

                if (!$brand) {
                    return CommonHelper::responseError('Brand not found or you do not have permission to update it!');
                }

                if ($request->hasFile('image')) {
                    $brand->image = MediaUploadService::upload(
                        $request->file('image'),
                        'brands/images',
                        'public',
                        $brand->image
                    );
                }

                $brand->name = $request->name;
                $brand->category_ids = $categoryIds;
                $brand->status = $request->status;
                $brand->save();

                return CommonHelper::responseSuccess('Brand updated successfully!');
            }

            // Create new brand
            $imagePath = null;
            if ($request->hasFile('image')) {
                $imagePath = MediaUploadService::upload(
                    $request->file('image'),
                    'brands/images',
                    'public'
                );
            }

            $brand = Brand::create([
                'name' => $request->name,
                'image' => $imagePath,
                'category_ids' => $categoryIds,
                'status' => $request->status,
                'seller_id' => $seller->id,
            ]);

            return CommonHelper::responseSuccess("Brand created successfully!");

        } catch (Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Update an existing brand
     */
    public function update(Request $request, $id)
    {
        try {
            $seller = auth()->user()->seller;

            if (!$seller) {
                return CommonHelper::responseError('Seller not found!');
            }

            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255|unique:brands,name,' . $id,
                'status' => 'required|boolean',
                'category_ids' => 'nullable|array',
                'category_ids.*' => 'integer',
                'image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:5120'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $brand = Brand::where('id', $id)
                ->where('seller_id', $seller->id)
                ->first();

            if (!$brand) {
                return CommonHelper::responseError('Brand not found or you do not have permission to update it!');
            }

            // Handle image upload
            if ($request->hasFile('image')) {
                $imagePath = MediaUploadService::upload(
                    $request->file('image'),
                    'brands/images',
                    'public',
                    $brand->image
                );
                $brand->image = $imagePath;
            }

            // Update other fields
            $brand->name = $request->name;
            // Ensure category_ids are stored as integers
            $brand->category_ids = $request->category_ids ? array_map('intval', $request->category_ids) : null;
            $brand->status = $request->status;
            $brand->save();

            return CommonHelper::responseSuccess('Brand updated successfully!');

        } catch (Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Delete a brand
     */
    public function destroy($id)
    {
        try {
            $seller = auth()->user()->seller;

            if (!$seller) {
                return CommonHelper::responseError('Seller not found!');
            }

            $brand = Brand::where('id', $id)
                ->where('seller_id', $seller->id)
                ->first();

            if (!$brand) {
                return CommonHelper::responseError('Brand not found, already deleted, or you do not have permission to delete it!');
            }

            $brand->delete();

            return CommonHelper::responseSuccess("Brand deleted successfully!");

        } catch (Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }
}