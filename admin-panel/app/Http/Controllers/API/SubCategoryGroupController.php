<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\CategoryGroup;
use App\Models\CategorySubGroup;
use App\Models\Combo;
use App\Models\Product;
use App\Models\SpecialItem;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;

class SubCategoryGroupController extends Controller
{

    public function getGroupSubCategory(Request $request){

        $query = CategorySubGroup::query();

        // Filter by seller_id if provided (skip is_super_mart filter for seller-specific queries)
        if ($request->has('seller_id') && !empty($request->seller_id)) {
            $query->where('seller_id', $request->seller_id);
        } else {
            // Default: filter by is_super_mart only when not filtering by seller_id
            $query->where('is_super_mart', 0);

            if ($request->has('is_super_mart')) {
                $query->where('is_super_mart', $request->is_super_mart);
            }
        }

        $group_categories = $query->orderBy('row_order', 'ASC')->get();

        return CommonHelper::responseWithData($group_categories);
    }



       public function save(Request $request)
        {
            if ($request->has('subcategory_ids') && is_string($request->subcategory_ids)) {
                $request->merge([
                    'subcategory_ids' => explode(',', $request->subcategory_ids)
                ]);
            }
            $request->validate([
                'name' => 'nullable|string',
                'subcategory_ids' => 'required|array',
                'category_group_id'=>'required',
                'status' => 'required|boolean',
                'is_group' => 'required|boolean',
            ]);

            $image = null;
            if($request->hasFile('image')){
                $image = MediaUploadService::upload(
                    $request->file('image'),
                    'group/categories/image'
                );
            }

            $categoryGroup = CategorySubGroup::create([
                'name' => $request->name,
                'image' => $image,
                'subcategory_ids' => implode(',', $request->subcategory_ids),
                'category_group_id' => $request->category_group_id,
                'is_group' => $request->is_group,
                'is_children_allowed' => $request->is_children_allowed ?? 1,
                'is_super_mart' => $request->is_super_mart ?? 0,
            ]);

            return CommonHelper::responseSuccess("Sub Category Group created Successfully!");
        }

        public function update(Request $request)
        {
            $categorySubGroup = CategorySubGroup::findOrFail($request->id);

            if ($request->has('subcategory_ids') && is_string($request->subcategory_ids)) {
                $request->merge([
                    'subcategory_ids' => array_filter(explode(',', $request->subcategory_ids))
                ]);
            }

            $validated = $request->validate([
                'name' => 'nullable|string',
                'subcategory_ids' => 'required|array',
                'category_group_id'=>'required',
                'status' => 'required|boolean',
                'is_group' => 'required|boolean',
            ]);

            $imagePath = $categorySubGroup->image;

            if ($request->hasFile('image')) {
                $imagePath = MediaUploadService::upload(
                    $request->file('image'),
                    'group/categories/image',
                    'public',
                    $categorySubGroup->image
                );
            }

            // Update record
            $categorySubGroup->update([
                'name' => $validated['name'] ?? $categorySubGroup->name,
                'image' => $imagePath,
                'subcategory_ids' => implode(',', $validated['subcategory_ids']),
                'category_group_id' => $validated['category_group_id'],
                'is_children_allowed' => $request->is_children_allowed ?? 1,
                'status' => $validated['status'],
                'is_group' => $validated['is_group'],
                'is_super_mart' => $request->is_super_mart ?? $categorySubGroup->is_super_mart,
            ]);

            return CommonHelper::responseSuccess("Sub Category Group updated successfully!", [
                'data' => $categorySubGroup
            ]);
        }

        public function edit($id)
        {
            $categorySubGroup = CategorySubGroup::find($id);

            if (!$categorySubGroup) {
                return CommonHelper::responseError('Sub Category Group not found.');
            }

            return CommonHelper::responseWithData($categorySubGroup);
        }

        public function destroy(Request $request)
        {
            $categorySubGroup = CategorySubGroup::find($request->id);

            if (!$categorySubGroup) {
                return CommonHelper::responseError("Sub Category Group not found!");
            }

            // Delete image if exists
            if ($categorySubGroup->image && Storage::disk('public')->exists($categorySubGroup->image)) {
                Storage::disk('public')->delete($categorySubGroup->image);
            }

            $categorySubGroup->delete();

            return CommonHelper::responseSuccess("Sub Category Group deleted successfully!");
        }

        public function getSubCategoryGroupsByRowOrder(Request $request)
        {
            $query = CategorySubGroup::query();

            $query->where('is_super_mart', 0);

            // Filter by category_group_id if provided
            if ($request->has('category_group_id') && !empty($request->category_group_id)) {
                $query->where('category_group_id', $request->category_group_id);
            }

            $subCategoryGroups = $query->orderBy('row_order', 'ASC')->get();

            return CommonHelper::responseWithData($subCategoryGroups);
        }

        public function updateSubCategoryGroupsOrder(Request $request)
        {
            $subCategoryGroups = $request->input('sub_category_groups', []);

            foreach ($subCategoryGroups as $key => $item) {
                $data = CategorySubGroup::find($item["id"]);
                if ($data) {
                    $data->row_order = $item["row_order"];
                    $data->save();
                }
            }

            return CommonHelper::responseSuccess("Sub Category Group Order Updated Successfully!");
        }

}
