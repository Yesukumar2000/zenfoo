<?php

namespace App\Http\Controllers\API\Seller;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Seller;
use App\Models\Admin;
use App\Models\Role;
use App\Models\CategoryGroup;
use App\Models\SubCategoryGroup;
use App\Models\Category;
use Illuminate\Support\Facades\DB;



use App\Services\MediaUploadService;

use Validator;
use Exception;
use App\Helpers\CommonHelper;
use Illuminate\Support\Facades\Auth;

use App\Models\AdminToken;


class SubCategorySellerController extends Controller
{
    /**
     * Get all category groups for the authenticated seller
     */
    public function list(Request $request)
    {
        try {
            $seller = auth()->user()->seller;

            if (!$seller) {
                return CommonHelper::responseError('Seller not found!');
            }

            $query = SubCategoryGroup::where('seller_id', $seller->id);

            if ($request->has('is_super_mart')) {
                $query->where('is_super_mart', $request->is_super_mart);
            }

            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Search filter
            if ($request->has('search') && !empty($request->search)) {
                $search = $request->search;
                $query->where(function($q) use ($search) {
                    $q->where('name', 'like', "%$search%")
                    ->orWhere('subcategory_ids', 'like', "%$search%");
                });
            }

            $perPage = $request->input('per_page', 10);
            $page = $request->input('page', 1);

            $categoryGroups = $query->orderBy('created_at', 'desc')
                ->paginate($perPage, ['*'], 'page', $page);

            $data = [];

            foreach ($categoryGroups->items() as $group) {

                $subcategoryIds = array_filter(explode(',', $group->subcategory_ids));

                $categories = Category::whereIn('id', $subcategoryIds)
                    ->select('id', 'name')
                    ->get();

                $group->categories = $categories;

                $data[] = $group;
            }

            return CommonHelper::responseWithData([
                'total'        => $categoryGroups->total(),
                'per_page'     => $categoryGroups->perPage(),
                'current_page' => $categoryGroups->currentPage(),
                'last_page'    => $categoryGroups->lastPage(),
                'data'         => $data
            ]);

        } catch (Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }


    /**
     * Get a single category group by ID
     */
    public function show($id)
    {
        try {
            $seller = auth()->user()->seller;

            if (!$seller) {
                return CommonHelper::responseError('Seller not found!');
            }

            $categoryGroup = SubCategoryGroup::where('id', $id)
                ->where('seller_id', $seller->id)
                ->first();

            if (!$categoryGroup) {
                return CommonHelper::responseError('Category Group not found!');
            }

            return CommonHelper::responseWithData($categoryGroup);

        } catch (Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Create a new category group
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
                'category_ids' => 'nullable|string',
                'image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:5120'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $imagePath = null;
            if ($request->hasFile('image')) {
                $imagePath = MediaUploadService::upload(
                    $request->file('image'),
                    'group/categories/image',
                    'public'
                );
            }

            // Determine is_group based on category_ids
            $isGroup = 0;
            if (!empty($request->category_ids) && str_contains($request->category_ids, ',')) {
                $isGroup = 1;
            }

            $categoryGroup = SubCategoryGroup::create([
                'seller_id' => $seller->id,
                'name' => $request->name,
                'image' => $imagePath,
                'subcategory_ids' => $request->category_ids,
                'is_super_mart' => 1,
                'is_group' => $isGroup,
            ]);

            return CommonHelper::responseSuccess("Category Group created successfully!");

        } catch (Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Update an existing category group
     */
    public function update(Request $request, $id)
    {
        try {
            $seller = auth()->user()->seller;

            if (!$seller) {
                return CommonHelper::responseError('Seller not found!');
            }

            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'category_ids' => 'nullable|string',
                'image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:5120'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $categoryGroup = SubCategoryGroup::where('id', $id)
                ->where('seller_id', $seller->id)
                ->first();

            if (!$categoryGroup) {
                return CommonHelper::responseError('Category Group not found!');
            }

            // Handle image upload
            if ($request->hasFile('image')) {
                $imagePath = MediaUploadService::upload(
                    $request->file('image'),
                    'group/categories/image',
                    'public',
                    $categoryGroup->image
                );
                $categoryGroup->image = $imagePath;
            }

            // Determine is_group based on category_ids
            $isGroup = 0;
            if (!empty($request->category_ids) && str_contains($request->category_ids, ',')) {
                $isGroup = 1;
            }

            // Update other fields
            $categoryGroup->name = $request->name;
            $categoryGroup->subcategory_ids = $request->category_ids;
            $categoryGroup->is_super_mart = 1;
            $categoryGroup->is_group = $isGroup;
            $categoryGroup->save();

            return CommonHelper::responseSuccess('Category Group updated successfully!');

        } catch (Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Delete a category group
     */
    public function destroy($id)
    {
        try {
            $seller = auth()->user()->seller;

            if (!$seller) {
                return CommonHelper::responseError('Seller not found!');
            }

            $categoryGroup = SubCategoryGroup::where('id', $id)
                ->where('seller_id', $seller->id)
                ->first();

            if (!$categoryGroup) {
                return CommonHelper::responseError('Category Group not found or already deleted!');
            }

            $categoryGroup->delete();

            return CommonHelper::responseSuccess("Category Group deleted successfully!");

        } catch (Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    public function storeCategoryGroup(Request $request)
    {
        try {
            $seller = auth()->user()->seller;

            if (!$seller) {
                return CommonHelper::responseError('Seller not found!');
            }

            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'group_ids' => 'required',
                'group_ids.*' => 'integer',
                'image' => 'nullable|image|max:2048',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Upload image
            $imagePath = null;
            if ($request->hasFile('image')) {
                $imagePath = MediaUploadService::upload(
                    $request->file('image'),
                    'group/categories/image',
                    'public'
                );
            }

            // Insert category_group
            $categoryGroupId = DB::table('category_groups')->insertGetId([
                'seller_id' => $seller->id,
                'is_super_mart' => 1,
                'name' => $request->name,
                'image' => $imagePath,
            ]);

            DB::table('sub_category_groups')
                ->whereIn('id', $request->group_ids)
                ->update(['category_group_id' => $categoryGroupId]);

            return CommonHelper::responseWithData([
                'id' => $categoryGroupId,
                'message' => 'Category group created successfully.'
            ]);

        } catch (Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    public function indexCategoryGroup(Request $request)
    {
        try {
            $seller = auth()->user()->seller;

            $query = CategoryGroup::where('seller_id', $seller->id);

            // Search functionality
            if ($request->has('search') && !empty($request->search)) {
                $search = $request->search;
                $query->where('name', 'like', "%$search%");
            }

            // Filter by status if provided
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Filter by is_super_mart if provided
            if ($request->has('is_super_mart')) {
                $query->where('is_super_mart', $request->is_super_mart);
            }

            // Pagination parameters
            $perPage = $request->input('per_page', 10);
            $page = $request->input('page', 1);

            $groups = $query->orderBy('id', 'desc')
                ->paginate($perPage, ['*'], 'page', $page);

            $data = [];

            foreach ($groups->items() as $group) {
                $subGroups = SubCategoryGroup::where('category_group_id', $group->id)
                    ->select('id', 'name', 'image', 'subcategory_ids', 'is_group', 'is_super_mart')
                    ->get();

                $group->groups = $subGroups;

                $data[] = $group;
            }

            return CommonHelper::responseWithData([
                'total' => $groups->total(),
                'per_page' => $groups->perPage(),
                'current_page' => $groups->currentPage(),
                'last_page' => $groups->lastPage(),
                'data' => $data
            ]);

        } catch (Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }



    public function updateCategoryGroup(Request $request, $id)
    {
        try {
            $seller = auth()->user()->seller;

            $validator = Validator::make($request->all(), [
                'name' => 'required|string',
                'group_ids' => 'required',
                'image' => 'nullable|image|max:5048',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $group = DB::table('category_groups')
                ->where('id', $id)
                ->where('seller_id', $seller->id)
                ->first();

            if (!$group) {
                return CommonHelper::responseError('Category group not found!');
            }

            // Upload new image if present
            $imagePath = $group->image;

            if ($request->hasFile('image')) {
                $imagePath = MediaUploadService::upload(
                    $request->file('image'),
                    'group/categories/image',
                    'public'
                );
            }

            // Update main table
            DB::table('category_groups')
                ->where('id', $id)
                ->update([
                    'name' => $request->name,
                    'image' => $imagePath,
                ]);

            // Remove old mapping
            DB::table('sub_category_groups')
                ->where('category_group_id', $id)
                ->update(['category_group_id' => null]);

            // Assign new mapping
            DB::table('sub_category_groups')
                ->whereIn('id', $request->group_ids)
                ->update(['category_group_id' => $id]);

            return CommonHelper::responseSuccess('Category group updated successfully.');

        } catch (Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    public function destroyCategoryGroup($id)
    {
        try {
            $seller = auth()->user()->seller;

            DB::table('sub_category_groups')
                ->where('category_group_id', $id)
                ->update(['category_group_id' => null]);

            DB::table('category_groups')
                ->where('id', $id)
                ->where('seller_id', $seller->id)
                ->delete();

            return CommonHelper::responseSuccess('Category group deleted.');

        } catch (Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }


    
    public function GetCategoryGroupsBySellerId(Request $request)
    {
        try {
            $seller = auth()->user()->seller;

            $query = CategoryGroup::where('seller_id', $seller->id);

            if ($request->has('search') && !empty($request->search)) {
                $search = $request->search;
                $query->where('name', 'like', "%$search%");
            }

            $perPage = $request->input('per_page', 10);
            $page = $request->input('page', 1);

            $groups = $query->orderBy('id', 'desc')
                ->paginate($perPage, ['*'], 'page', $page);

            $data = [];

            foreach ($groups->items() as $group) {
                $subGroups = SubCategoryGroup::where('category_group_id', $group->id)
                    ->select('id', 'name', 'image', 'subcategory_ids', 'is_group', 'is_super_mart')
                    ->get();

                $group->groups = $subGroups;

                $data[] = $group;
            }

            return CommonHelper::responseWithData([
                'total' => $groups->total(),
                'per_page' => $groups->perPage(),
                'current_page' => $groups->currentPage(),
                'last_page' => $groups->lastPage(),
                'data' => $data
            ]);

        } catch (Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

}