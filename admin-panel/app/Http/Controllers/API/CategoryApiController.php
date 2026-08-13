<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Product;
use App\Models\Seller;
use App\Models\Setting;
use App\Models\CategoryType;
use App\Models\Store;
use App\Models\SubCategoryGroup;
use App\Models\SellerRegistrationHelper;
use App\Services\MediaUploadService;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class CategoryApiController extends Controller
{

    public function getAllCategories() {
        $categories = Category::where('parent_id',0)->where('status',1)->get();
        return CommonHelper::responseWithData($categories);
    }

    public function getCategories(Request $request){
        if(isset(auth()->user()->seller->id) && auth()->user()->seller->id != null && auth()->user()->role_id == 3){
            $limit = $request->input('limit');
            $offset = $request->input('offset', 0);
            $filter = $request->input('filter', '');

            $category_id = $request->get('category_id', 0);
            $category_slug = $request->get('slug');

            $seller = auth()->user()->seller;
            $sellerCategoryIds = explode(",", $seller->categories);
            
            if(isset($category_slug) && !empty($category_slug)){
                $category = Category::where('status', 1)->where('slug', $category_slug)->whereIn('id', $sellerCategoryIds)->first();
                if(!$category) {
                    return CommonHelper::responseError(__('no_category_found'));
                }
                $categories = Category::where('status', 1)->where('parent_id', $category->id);
            } else {
                if($category_id > 0) {
                    $hasAccess = false;
                    
                    if(in_array($category_id, $sellerCategoryIds)) {
                        $hasAccess = true;
                    } else {
                        $currentCategory = Category::find($category_id);
                        while($currentCategory && $currentCategory->parent_id != 0) {
                            $currentCategory = Category::find($currentCategory->parent_id);
                            if($currentCategory && in_array($currentCategory->id, $sellerCategoryIds)) {
                                $hasAccess = true;
                                break;
                            }
                        }
                    }
                    
                    if(!$hasAccess) {
                        return CommonHelper::responseError(__('no_category_found'));
                    }
                    $categories = Category::where('status', 1)->where('parent_id', $category_id);
                } else {
                    $categories = Category::where('status', 1)->whereIn('id', $sellerCategoryIds);
                }
            }

            if ($filter) {
                $categories = $categories->where(function($query) use ($filter) {
                    $query->where('name', 'like', "%{$filter}%")
                          ->orWhere('subtitle', 'like', "%{$filter}%");
                });
            }

            $total = $categories->count();
            
            if(isset($limit) && $limit > 0){
                $categories = $categories->orderBy('row_order', 'ASC')->offset($offset)->limit($limit)->get(['id','name','subtitle','slug','image']);
            } else {
                $categories = $categories->orderBy('row_order', 'ASC')->get(['id','name','subtitle','slug','image']);
            }
            
            $categories = $categories->makeHidden(['image']);

            if(count($categories) > 0){
                return CommonHelper::responseWithData($categories, $total);
            } else {
                return CommonHelper::responseError(__('no_category_found'));
            }
        } else {
            $limit = $request->input('limit');
            $offset = (($request->input('offset'))-1)*$limit;
            $filter = $request->input('filter', '');

            $categoriesQuery = Category::orderBy('id', 'DESC');

            if ($filter) {
                $categoriesQuery = $categoriesQuery->where(function($query) use ($filter) {
                    $query->where('name', 'like', "%{$filter}%")
                          ->orWhere('subtitle', 'like', "%{$filter}%");
                });
            }

            // Filter by seller_id if provided (skip is_super_mart filter for seller-specific queries)
            if ($request->has('seller_id') && !empty($request->seller_id)) {
                $categoriesQuery->where('seller_id', $request->seller_id);
            } else {
                // Default: filter by is_super_mart only when not filtering by seller_id
                $categoriesQuery->where('is_super_mart', 0);

                if ($request->filled('is_super_mart') && $request->is_super_mart == 1) {
                    $categoriesQuery->where('is_super_mart', 1);
                }
            }

            $total = $categoriesQuery->count();

            if (isset($limit) && !is_null($limit)) {
                $categories = $categoriesQuery->orderBy('id', 'desc')->skip($offset)->take($limit)->get();
            } else {
                $categories = $categoriesQuery->orderBy('id', 'desc')->get();
            }

            if($categories->isEmpty()){
                return CommonHelper::responseError('Category not found.');
            }

            // dd($request->is_super_mart);


            return CommonHelper::responseWithData($categories, $total);
        }
    }

    public function getActiveCategories(){
        $categories = Category::where('status', 1)->orderBy('id','ASC')->get()->toArray();
        return CommonHelper::responseWithData($categories);
    }
    public function getMainCategories(Request $request){
        $categories = CommonHelper::getMainCategories($request);
        $total = $categories->count();
        if(empty($categories)){
            return  CommonHelper::responseError('Category not found.');
        }
        return CommonHelper::responseWithData($categories,$total);
    }
    public function getCategoriesByRowOrder(Request $request){
        // Filter by sub_category_group_id if provided
        if ($request->has('sub_category_group_id') && !empty($request->sub_category_group_id)) {
            $subCategoryGroup = SubCategoryGroup::where('id', $request->sub_category_group_id)->first();

            if ($subCategoryGroup && $subCategoryGroup->subcategory_ids) {
                $ids = explode(',', $subCategoryGroup->subcategory_ids);
                // Fetch categories
                $categoriesCollection = Category::whereIn('id', $ids)->get()->keyBy('id');

                // Order categories by their position in subcategory_ids string
                $categories = collect([]);
                foreach ($ids as $index => $id) {
                    if ($categoriesCollection->has($id)) {
                        $category = $categoriesCollection->get($id);
                        $category->row_order = $index + 1; // Set row_order based on position
                        $categories->push($category);
                    }
                }
            } else {
                $categories = collect([]);
            }
        } else {
            $categories = Category::where('parent_id', 0)->orderBy('row_order', 'ASC')->get();
        }

        return CommonHelper::responseWithData($categories);
    }
    public function save(Request $request){
        $validator = Validator::make($request->all(),[
            'name' => 'required',
            'subtitle' => 'required',
            'image' => 'required|mimes:jpeg,jpg,png,gif',
            'types'       => 'array',
            'types.*'     => 'string'
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $slug = preg_replace('/\s+/', '-', trim(
            preg_replace('/[^A-Za-z0-9 ]/', '', $request->name)
        ));

        $count = Category::where('slug', $slug)->count();
        if ($count > 0) {
            $slug .= '-' . ($count + 1);
        }

        $category = new Category();
        $category->name = $request->name;
        $category->subtitle = $request->subtitle;
        $category->slug = $slug;

        if($request->hasFile('image')){
            $category->image = MediaUploadService::upload(
                $request->file('image'),
                'categories'
            );
        } else {
            $category->image = '';
        }
        $category->web_image = '';
        $category->status = 1;

        // Determine is_super_mart based on authenticated user's store
        $isSuperMart = 0;
        if (auth()->check() && auth()->user()->seller) {
            $seller = auth()->user()->seller;
            // Get the seller_registration_helper using seller's store_id
            $helper = SellerRegistrationHelper::where('stores', $seller->store_id)->first();
            if ($helper ) {
                // Get the actual store using the stores field
                $store = Store::find($helper->stores);
                if ($store) {
                    $isSuperMart = $store->is_super_mart == 1 ? 1 : 0;
                }
            }
        }
        $category->is_super_mart = $isSuperMart;

        $category->parent_id = $request->parent_id;
        $category->meta_title = $request->meta_title ?? "";
        $category->meta_keywords = $request->meta_keywords ?? "";
        $category->schema_markup = $request->schema_markup ?? "";
        $category->meta_description = $request->meta_description ?? "";

        
        $category->save();

        
        if (!empty($request->types) && is_array($request->types)) {
            foreach ($request->types as $typeName) {
                CategoryType::create([
                    'name'        => $typeName,
                    'category_id' => $category->id,
                ]);
            }
        }

        
        return CommonHelper::responseSuccess("Category Saved Successfully!");
    }
    public function update(Request $request){
        $validator = Validator::make($request->all(),[
            'name' => 'required',
            'subtitle' => 'required',
            'types'       => 'array',
            'types.*'     => 'string'
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        if(isset($request->id)){ 
            $category = Category::find($request->id);
            $newSlug = preg_replace('/\s+/', '-', trim(
                preg_replace('/[^A-Za-z0-9 ]/', '', $request->name)
            ));
            $count = Category::where('slug', $newSlug)->where('id', '!=', $category->id) ->count();

            if ($count > 0) {
                $newSlug .= '-' . ($count + 1);
            }

            $category->name = $request->name;
            $category->subtitle = $request->subtitle;
            $category->status = $request->status;
            $category->slug = $newSlug;
            $category->parent_id = $request->parent_id ?? $category->parent_id ?? 0;
            $category->meta_title = $request->meta_title ?? "";
            $category->meta_keywords = $request->meta_keywords ?? "";
            $category->schema_markup = $request->schema_markup ?? "";
            $category->meta_description = $request->meta_description ?? "";
            if($request->hasFile('image')){
                $category->image = MediaUploadService::upload(
                    $request->file('image'),
                    'categories',
                    'public',
                    $category->image
                );
            }
            $category->save();

            // Sync sub_category_groups entry that was created alongside this category
            $subGroup = SubCategoryGroup::where('seller_id', $category->seller_id)
                ->where('subcategory_ids', (string) $category->id)
                ->first();
            if ($subGroup) {
                $subGroup->name = $category->name;
                if ($request->hasFile('image')) {
                    $subGroup->image = $category->image;
                }
                $subGroup->save();
            }

            if (!empty($request->types) && is_array($request->types)) {
                foreach ($request->types as $typeName) {
                    CategoryType::create([
                        'name'        => $typeName,
                        'category_id' => $category->id,
                    ]);
                }
            }

        }

        return CommonHelper::responseSuccess("Category Updated Successfully!");
    }
    public function delete(Request $request){
        if(isset($request->id)){
            $category = Category::find($request->id);
            if($category){
                // Count products associated with this category
                $productCount = Product::where('category_id', $request->id)->count();

                // Update products to set category_id to null
                if($productCount > 0) {
                    Product::where('category_id', $request->id)->update(['category_id' => null]);
                }

                // Delete matching sub_category_groups entry
                SubCategoryGroup::where('seller_id', $category->seller_id)
                    ->where('subcategory_ids', (string) $category->id)
                    ->delete();

                @Storage::disk('public')->delete($category->image);
                $category->delete();

                // Return message with product count info
                if($productCount > 0) {
                    return CommonHelper::responseSuccess("Category deleted successfully! {$productCount} product(s) were unlinked from this category and are no longer visible in customer app.");
                } else {
                    return CommonHelper::responseSuccess("Category Deleted Successfully!");
                }
            }else{
                return CommonHelper::responseSuccess("Category Already Deleted!");
            }
        }
    }


    public function getOptions(Request  $request){
        echo"<option value='0' selected >Select Category</option>";
        $options = CommonHelper::categoryTree(0,'',null,array(), false,array(),$request->exclude_id,0);
    }

    public function updateCategoriesOrder(Request $request){
        $categories = $request->input('categories', []);
        $subCategoryGroupId = $request->input('sub_category_group_id');

        // If sub_category_group_id is provided, update the subcategory_ids order in sub_category_groups table
        if ($subCategoryGroupId) {
            // Sort categories by row_order
            usort($categories, function($a, $b) {
                return $a['row_order'] - $b['row_order'];
            });

            // Extract category IDs in new order
            $newOrderIds = array_column($categories, 'id');
            $newSubcategoryIds = implode(',', $newOrderIds);

            // Update the sub_category_groups table
            SubCategoryGroup::where('id', $subCategoryGroupId)->update([
                'subcategory_ids' => $newSubcategoryIds
            ]);

            return CommonHelper::responseSuccess("Category Order Updated Successfully!");
        }

        // Fallback: Update row_order in categories table (for backward compatibility)
        foreach ($categories as $key => $category){
            $data = Category::find($category["id"]);
            if ($data) {
                $data->row_order = $category["row_order"];
                $data->save();
            }
        }
        return CommonHelper::responseSuccess("Category Order Updated Successfully!");
    }
    public function countProductCategoryWise(){
        $categories = Category::select('id','name',DB::raw('(SELECT count(id) from `products` WHERE products.category_id = categories.id) AS product_count'))
            ->orderBy('id','ASC')->get();
        return CommonHelper::responseWithData($categories);
    }

    public function getSellerCategories(Request $request){

        CommonHelper::categoryTree(0,'',null,array(), true,array(),'', $request->seller_id);
    }
    public function checkSlug(Request $request, $slug)
    {
        try {
            // Query the database to count the documents that match the slug pattern
            $existingDocumentCount = Category::where('slug', 'like', $slug . '%')->count();

            // Construct the response data
            $responseData = [
                'unique' => $existingDocumentCount === 0,
                'count' => $existingDocumentCount
            ];

            return response()->json($responseData);
        } catch (\Exception $e) {
            \Log::error('Error checking slug uniqueness: ' . $e->getMessage());
            return response()->json(['error' => 'An error occurred while checking slug uniqueness'], 500);
        }
    }

    public function getCategoryTypesByCategoryId(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'category_id' => 'required|integer'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $categoryTypes = CategoryType::where('category_id', $request->category_id)
            ->select('id', 'name')
            ->get();

        return CommonHelper::responseWithData($categoryTypes);
    }

    /**
     * Admin: Create a category for a seller.
     * Same flow as seller app's storeSellerSweetHouseCategory —
     * inserts into categories + sub_category_groups (for food store).
     */
    public function storeSellerCategory(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name'      => 'required|string|max:255',
            'subtitle'  => 'required|string|max:255',
            'seller_id' => 'required|integer|exists:sellers,id',
            'image'     => 'required|mimes:jpeg,jpg,png,gif,webp',
            'types'     => 'array',
            'types.*'   => 'string',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $seller = Seller::find($request->seller_id);

        DB::beginTransaction();

        try {
            $imagePath = MediaUploadService::upload(
                $request->file('image'),
                'categories'
            );

            $categoryId = DB::table('categories')->insertGetId([
                'name'                 => $request->name,
                'subtitle'             => $request->subtitle,
                'image'                => $imagePath,
                'is_added_by_seller'   => 1,
                'is_sweet_house_store' => 1,
                'seller_id'            => $seller->id,
                'status'               => 1,
                'created_at'           => now(),
                'updated_at'           => now(),
            ]);

            // For food store (store_id = 15), also insert into sub_category_groups
            if ($seller->store_id == 15) {
                DB::table('sub_category_groups')->insert([
                    'name'            => $request->name,
                    'is_group'        => 0,
                    'is_super_mart'   => 0,
                    'seller_id'       => $seller->id,
                    'subcategory_ids' => $categoryId,
                    'image'           => $imagePath,
                    'created_at'      => now(),
                    'updated_at'      => now(),
                ]);
            }

            if (!empty($request->types) && is_array($request->types)) {
                foreach ($request->types as $typeName) {
                    CategoryType::create([
                        'name'        => $typeName,
                        'category_id' => $categoryId,
                    ]);
                }
            }

            DB::commit();

            return CommonHelper::responseSuccess("Category created successfully!");

        } catch (\Exception $e) {
            DB::rollBack();
            return CommonHelper::responseError($e->getMessage());
        }
    }

}
