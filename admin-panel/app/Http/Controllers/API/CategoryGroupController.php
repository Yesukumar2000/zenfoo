<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\CategoryGroup;
use App\Models\Combo;
use App\Models\Product;
use App\Models\SpecialItem;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;
use PhpParser\Node\Expr\FuncCall;

class CategoryGroupController extends Controller
{

    public function getGroupCategory(Request $request){

        $query = CategoryGroup::query();

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
            $request->validate([
                'name' => 'required|string',
                'status' => 'required|boolean',
            ]);

            $image = null;
            if($request->hasFile('image')){
                $image = MediaUploadService::upload(
                    $request->file('image'),
                    'group/categories/image'
                );
            }

            $categoryGroup = CategoryGroup::create([
                'name' => $request->name,
                'icon' => $icon ?? null,
                'image' => $image,
                'is_super_mart' => $request->is_super_mart ?? 0,
                'color' => $request->color,
                'status' => $request->status,
            ]);

            return CommonHelper::responseSuccess("Category Group created Successfully!");
        }

        public function update(Request $request, $id)
        {
            $request->validate([
                'name' => 'required|string',
                'status' => 'required|boolean',
            ]);

            $categoryGroup = CategoryGroup::find($id);
            if (!$categoryGroup) {
                return CommonHelper::responseError('Category Group not found.');
            }

            if ($request->hasFile('icon')) {
                $categoryGroup->icon = MediaUploadService::upload(
                    $request->file('icon'),
                    'group/categories/icon',
                    'public',
                    $categoryGroup->icon
                );
            }

            if ($request->hasFile('image')) {
                $categoryGroup->image = MediaUploadService::upload(
                    $request->file('image'),
                    'group/categories/image',
                    'public',
                    $categoryGroup->image
                );
            }

            // ✅ Update other fields
            $categoryGroup->name = $request->name;
            $categoryGroup->color = $request->color ?? $categoryGroup->color;
            $categoryGroup->status = $request->status;
            $categoryGroup->is_super_mart = $request->is_super_mart ?? 0;

            // ✅ Save changes
            $categoryGroup->save();

            return CommonHelper::responseSuccess('Category Group updated successfully!');
        }


        public function edit($id)
        {
            $categoryGroup = CategoryGroup::find($id);

            if (!$categoryGroup) {
                return CommonHelper::responseError('Category Group not found.');
            }

            return CommonHelper::responseWithData($categoryGroup);
        }

        public function destroy(Request $request) {

            if(isset($request->id)){
                $role = CategoryGroup::find($request->id);
                if($role){
                    $role->delete();
                    return CommonHelper::responseSuccess("Category Group Deleted Successfully!");
                }else{
                    return CommonHelper::responseSuccess("Category Group Already Deleted!");
                }
            }
        }

        public function getCategoryGroupsByRowOrder(Request $request)
        {
            $query = CategoryGroup::query();

            $query->where('is_super_mart', 0);

            // Filter by store_id if provided
            if ($request->has('store_id') && !empty($request->store_id)) {
                $query->whereHas('stores', function($q) use ($request) {
                    $q->where('stores.id', $request->store_id);
                });
            }

            $categoryGroups = $query->orderBy('row_order', 'ASC')->get();

            return CommonHelper::responseWithData($categoryGroups);
        }

        public function updateCategoryGroupsOrder(Request $request)
        {
            $categoryGroups = $request->input('category_groups', []);

            foreach ($categoryGroups as $key => $item) {
                $data = CategoryGroup::find($item["id"]);
                if ($data) {
                    $data->row_order = $item["row_order"];
                    $data->save();
                }
            }

            return CommonHelper::responseSuccess("Category Group Order Updated Successfully!");
        }
}
