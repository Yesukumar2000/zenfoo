<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Brand;
use App\Models\Category;
use App\Services\MediaUploadService;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class BrandsApiController extends Controller
{
    public function list(Request $request){
        $limit = $request->input('per_page', 10); // Default items per page
        $offset = (($request->input('page', 0))-1)*$limit; // Default page
        $filter = $request->input('filter', ''); // Filter query
        $categoryId = $request->input('category_id'); // Category filter

        // Fetch paginated data
        $brands = Brand::orderBy('id', 'DESC');
        if ($filter) {
            $brands = $brands->where(function($query) use ($filter) {
                $query->where('name', 'like', "%{$filter}%");
            });
        }

        // Filter by category if provided
        if ($categoryId) {
            $brands = $brands->where(function($query) use ($categoryId) {
                $query->where('category_ids', 'like', "%{$categoryId}%");
            });
        }

        $total = $brands->count();
        $brands = $brands->skip($offset)->take($limit)->get();
        return CommonHelper::responseWithData($brands, $total);
    }

    public function save(Request $request){

        $validator = Validator::make($request->all(),[
            'name' => 'required',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        $brand = new Brand();
        $brand->name = $request->name;
        $brand->status = 1;
        $brand->store_id = $request->store_id ?? null;
        $brand->category_group_id = $request->category_group_id ?? null;
        $brand->sub_category_group_id = $request->sub_category_group_id ?? null;
        $brand->category_ids = $request->category_ids ? implode(',', $request->category_ids) : null;

        if($request->hasFile('image')){
            $brand->image = MediaUploadService::upload(
                $request->file('image'),
                'brand'
            );
        }

        $brand->save();
        return CommonHelper::responseSuccess("Brands Saved Successfully!");
    }

    public function update(Request $request){

        $validator = Validator::make($request->all(),[
            'name' => 'required',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        if(isset($request->id)){

            $brand = Brand::find($request->id);
            $brand->name = $request->name;
            $brand->status = $request->status;
            $brand->store_id = $request->store_id ?? null;
            $brand->category_group_id = $request->category_group_id ?? null;
            $brand->sub_category_group_id = $request->sub_category_group_id ?? null;
            $brand->category_ids = $request->category_ids ? implode(',', $request->category_ids) : null;

            if($request->hasFile('image')){
                $brand->image = MediaUploadService::upload(
                    $request->file('image'),
                    'brand',
                    'public',
                    $brand->image
                );
            }
            $brand->save();
        }
        return CommonHelper::responseSuccess("Brands Updated Successfully!");
    }

    public function delete(Request $request){

        if(isset($request->id)){

            $brand = Brand::find($request->id);
            if($brand){
                $brand->delete();
                return CommonHelper::responseSuccess("Brands Deleted Successfully!");
            }else{
                return CommonHelper::responseSuccess("Brands Already Deleted!");
            }
        }
    }

    public function getBrands(Request $request){
        $limit      = $request->get('limit');
        $offset     = $request->get('offset');
        $storeId    = $request->get('store_id');
        $categoryId = $request->get('category_id');

        $query = Brand::orderBy('id', 'ASC')->where('status', 1);

        if ($storeId) {
            $query->where('store_id', $storeId);
        }

        if ($categoryId) {
            $query->whereRaw("FIND_IN_SET(?, category_ids) > 0", [$categoryId]);
        }

        $total = $query->count();

        if ($limit > 0) {
            $query->skip($offset)->take($limit);
        }

        $brands = $query->get();
        return CommonHelper::responseWithData($brands, $total);
    }

    public function getCategories(Request $request){
        $categories = Category::select('id', 'name')
            ->where('status', 1)
            ->orderBy('name', 'ASC')
            ->get();
        return CommonHelper::responseWithData($categories);
    }
}
