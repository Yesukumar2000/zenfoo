<?php
namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\CategoryGroup;
use App\Models\Store;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;

class StoreController extends Controller
{

    public function getCategoryGroups()
    {
        $groups = CategoryGroup::select('id', 'name')->get();
        return CommonHelper::responseWithData($groups);
    }

    public function index()
    {
        // Filter out Super Mart (id: 17) from the list
        // $stores = Store::where('id', '!=', 17)->get();
        $stores = Store::all();
        return CommonHelper::responseWithData($stores);
    }

    public function save(Request $request)
    {
        $validated = $request->validate([
            'name'                 => 'required|string|max:255',
            'category_group_ids'   => 'required|array',
            'category_group_ids.*' => 'exists:category_groups,id',
        ]);

        if ($request->hasFile('icon')) {
            $icon = MediaUploadService::upload(
                $request->file('icon'),
                'group/stores/icon'
            );
        }

        if ($request->hasFile('image')) {
            $image = MediaUploadService::upload(
                $request->file('image'),
                'group/stores/image'
            );
        }

        if ($request->hasFile('vendor_img')) {
            $vendor_img = MediaUploadService::upload(
                $request->file('vendor_img'),
                'group/stores/image'
            );
        }

        $store = Store::create([
            'name'          => $request->name,
            'description'   => $request->description,
            'icon'          => $icon ?? null,
            'image'         => $image ?? null,
            'vendor_img'    => $vendor_img ?? null,
            'color'         => $request->color,
            'managed_by_admin' => $request->managed_by_admin ?? 0,
            'is_meat'       => $request->is_meat ?? 0,
            'is_food'       => $request->is_food ?? 0,
            'is_vegetable'  => $request->is_vegetable ?? 0,
            'is_super_mart' => $request->is_super_mart ?? 0,
        ]);

        $store->categoryGroups()->sync($request->category_group_ids);

        return CommonHelper::responseSuccess("Store saved successfully!");
    }

    // 🔹 Edit (get store + selected category groups)
    public function edit($id)
    {
        $store = Store::with('categoryGroups:id,name')->find($id);
        if (! $store) {
            return CommonHelper::responseError('Store not found');
        }

        $groups = CategoryGroup::select('id', 'name')->get();
        return CommonHelper::responseWithData("Store fetched", [
            'store'           => $store,
            'category_groups' => $groups,
        ]);
    }

    public function update(Request $request, $id)
    {
        $validated = $request->validate([
            'name'                 => 'required|string|max:255',
            'category_group_ids'   => 'nullable|array',
            'category_group_ids.*' => 'exists:category_groups,id',
        ]);

        $store = Store::findOrFail($request->id);

        if ($request->hasFile('icon')) {
            $icon = MediaUploadService::upload(
                $request->file('icon'),
                'group/stores/icon',
                'public',
                $store->icon
            );
        }

        if ($request->hasFile('image')) {
            $image = MediaUploadService::upload(
                $request->file('image'),
                'group/stores/image',
                'public',
                $store->image
            );
        }

        if ($request->hasFile('vendor_img')) {
            $vendor_img = MediaUploadService::upload(
                $request->file('vendor_img'),
                'group/stores/image',
                'public',
                $store->vendor_img
            );
        }

        $data = [
            'name'  => $request->name,
            'color' => $request->color,
        ];
        if (isset($icon)) {
            $data['icon'] = $icon;
        }

        if (isset($image)) {
            $data['image'] = $image;
        }

        
        if (isset($vendor_img)) {
            $data['vendor_img'] = $vendor_img;
        }

        $data['description'] = $request->description;
        
        $data['managed_by_admin'] = $request->managed_by_admin ?? 0;
        $data['is_meat']          = $request->is_meat ?? 0;
        $data['is_food']          = $request->is_food ?? 0;
        $data['is_vegetable']     = $request->is_vegetable ?? 0;
        $data['is_super_mart']    = $request->is_super_mart ?? 0;

        $store->update($data);

        $store->categoryGroups()->sync($request->category_group_ids);

        return CommonHelper::responseSuccess("Store saved successfully!");
    }

    public function delete(Request $request)
    {
        $id = $request->id;

        if ($id) {
            $store = Store::find($id);
            if ($store) {
                $store->delete();
                return CommonHelper::responseSuccess("Store Deleted Successfully!");
            } else {
                return CommonHelper::responseSuccess("Store Already Deleted!");
            }
        }

        return CommonHelper::responseError("Invalid ID");
    }

}