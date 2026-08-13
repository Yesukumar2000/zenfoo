<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Setting;
use App\Models\SubCategory;
use App\Services\MediaUploadService;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class SubCategoryApiController extends Controller
{

    public function getSubcategory(Request $request) {
        $query = Category::where('status', 1);

        $query->where('is_super_mart', 0);

        if ($request->has('is_super_mart')) {
            $query->where('is_super_mart', $request->is_super_mart);
        }

        $subCategories = $query->get();
        return CommonHelper::responseWithData($subCategories);
    }



    public function index($id = null){


        $subCategories = SubCategory::with('category');
        if($id){
            $subCategories->where('category_id',$id);
        }
        $subCategories = $subCategories->orderBy('id','DESC')->get();

        return CommonHelper::responseWithData($subCategories);
    }

    public function save(Request $request){

        $validator = Validator::make($request->all(),[
            'category_id' => 'required',
            'name' => 'required',
            'subtitle' => 'required',
            'image' => 'required|mimes:jpeg,jpg,png,gif'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $category = new SubCategory();
        $category->category_id = $request->category_id;
        $category->name = $request->name;
        $category->subtitle = $request->subtitle;
        $category->slug = '';

        if($request->hasFile('image')){
            $category->image = MediaUploadService::upload(
                $request->file('image'),
                'subcategories'
            );
        } else {
            $category->image = '';
        }

        $category->save();

        return CommonHelper::responseSuccess("Subcategory Saved Successfully!");
    }

    public function update(Request $request){

        $validator = Validator::make($request->all(),[
            'category_id' => 'required',
            'name' => 'required',
            'subtitle' => 'required',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        if(isset($request->id)){

            $category = SubCategory::find($request->id);
            $category->category_id = $request->category_id;
            $category->name = $request->name;
            $category->subtitle = $request->subtitle;
            if($request->hasFile('image')){
                $category->image = MediaUploadService::upload(
                    $request->file('image'),
                    'subcategories',
                    'public',
                    $category->image
                );
            }
            $category->save();
        }


        return CommonHelper::responseSuccess("Subcategory Updated Successfully!");
    }

    public function delete(Request $request){

        if(isset($request->id)){

            $category = SubCategory::find($request->id);
            if($category){
                @Storage::disk('public')->delete($category->image);
                $category->delete();
                return CommonHelper::responseSuccess("Subcategory Deleted Successfully!");
            }else{
                return CommonHelper::responseSuccess("Subcategory Already Deleted!");
            }
        }
    }
}
