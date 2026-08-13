<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Imports\ProductsImport;
use App\Models\Seller;
use App\Models\Category;
use App\Models\Product;
use App\Models\ProductImages;
use App\Models\ProductVariant;
use App\Models\OrderItem;
use App\Models\Setting;
use App\Models\Tax;
use App\Models\Tag;
use App\Models\CategoryGroupStore;
use App\Models\CategoryGroup;
use App\Models\SubCategoryGroup;
use App\Models\Unit;
use App\Models\Store;
use App\Models\Role;
use App\Models\Section;
use App\Services\MediaUploadService;
use App\Services\SellerNotificationService;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Maatwebsite\Excel\Facades\Excel;
use Response;
use Illuminate\Support\Str;


class ProductApisController extends Controller
{
    public function getProducts(Request $request){ 
        $limit = $request->input('per_page'); // Default items per page
        $offset = (($request->input('page'))-1)*$limit; // Default page
        $filter = $request->input('filter', ''); // Filter query

        if(!isset($request->type)){
            $sellers = Seller::where('status',1)->select('id', 'name')->orderBy('id','DESC')->get()->makeHidden(['logo_url','national_identity_card_url','address_proof_url','categories_array']) ->toArray();
        }


        $categories = Category::where('status', 1)
            ->select('id', 'name') // Only select specific columns
            ->orderBy('id', 'DESC')
            ->get()
            ->makeHidden(['image_url', 'has_child', 'has_active_child']) 
            ->toArray();
        
       // Initialize an array to hold the where conditions
        $where = [];

        if (isset($request->is_approved) && $request->is_approved !== "") {
            $where[] = ['p.is_approved', '=', $request->is_approved];
        }

        if (isset($request->seller) && $request->seller !== "") {
            $where[] = ['p.seller_id', '=', $request->seller];
            // Get the assigned categories from the seller table
            $assignedCategories = Seller::where('id', $request->seller)->value('categories');

            // Convert the assigned categories into an array
            $categoryIds = explode(',', $assignedCategories);

            // Query the categories based on the assigned categories from the seller
            $categories = Category::whereIn('id', $categoryIds)->orderBy('id', 'DESC')->get()->toArray();
        }

        if (isset($request->category) && $request->category !== "") {
            $where[] = ['p.category_id', '=', $request->category];
        }




        if (isset($request->store_id) && $request->store_id !== "") {
            $where[] = ['p.store_id', '=', $request->store_id];
        }

        if (isset($request->brand_id) && $request->brand_id !== "") {
            $where[] = ['p.brand_id', '=', $request->brand_id];
        }

        // Packet products
        if (isset($request->type) && $request->type === 'packet_products') {
            $where[] = ['p.type', '=', 'packet'];
        }

        // Loose products
        if (isset($request->type) && $request->type === 'loose_products') {
            $where[] = ['p.type', '=', 'loose'];
        }

        // Sold Out
        if (isset($request->type) && $request->type === 'sold_out') {
           
           // $where[] = [DB::raw('(pv.stock <= 0      pv.status = "0")'), '=', DB::raw('0')];
             $where[] = ['pv.stock', '<=', 0];
             $where[] = ['pv.status', '=', 0];
            
            $where[] = ['p.is_unlimited_stock', '=', 0];
        }

        // Low Stock
        if (isset($request->type) && $request->type === 'low_stock') {
            $low_stock_limit = Setting::where('variable', 'low_stock_limit')->first();
            if ($low_stock_limit) {
                $where[] = ['pv.stock', '<=', $low_stock_limit['value']];
                $where[] = ['pv.status', '=', '1'];
                $where[] = ['p.is_unlimited_stock', '!=', '1'];
            }
        }

        $products  = \DB::table('products as p')->select('p.id as id','p.id as product_id', 'p.name', 'p.seller_id', 'p.status', 'p.tax_id', 'p.image', 's.name as seller_name','s.id as seller_id',
         'p.indicator', 'p.is_approved', 'p.manufacturer', 'p.made_in', 'p.return_status', 'p.cancelable_status', 'p.till_status',  'pv.id as product_variant_id', 'pv.price', 'pv.discounted_price', 'pv.measurement', 'pv.status as pv_status', 'pv.stock', 'pv.stock_unit_id', 'u.short_code', \DB::raw('(select short_code from units where units.id = pv.stock_unit_id) as stock_unit'))
        ->leftJoin('sellers as s', 'p.seller_id', '=', 's.id')
        ->join('product_variants as pv', 'p.id', '=', 'pv.product_id')
        ->join('units as u', 'pv.stock_unit_id', '=', 'u.id');

       // Add where conditions if any
        if (!empty($where)) {
            foreach ($where as $condition) {
                $products->where($condition[0], $condition[1], $condition[2]);
            }
        }

        // Filter by is_meat stores when no specific store_id is given
        if (isset($request->is_meat) && $request->is_meat == 1 && (!isset($request->store_id) || $request->store_id === "")) {
            $meatStoreIds = \DB::table('stores')->where('is_meat', 1)->pluck('id');
            $products->whereIn('p.store_id', $meatStoreIds);
        }

        // Exclude products already added to the section
        if (isset($request->section_id) && $request->section_id !== "") {
            $existingProductIds = \DB::table('customer_app_section_products')
                ->where('section_id', $request->section_id)
                ->pluck('product_id')
                ->toArray();

            if (!empty($existingProductIds)) {
                $products->whereNotIn('p.id', $existingProductIds);
            }
        }

        $products = $products->orderBy('pv.id', 'desc');

        // Apply filter to all columns in all joined tables
        if ($filter) {
            $columns = [
                'p.id', 'pv.id', 'p.name','s.name','pv.price','pv.discounted_price','pv.measurement','pv.stock',
            ];
            
            $products = $products->where(function($query) use ($filter, $columns) {
                foreach ($columns as $column) {
                    $query->orWhere($column, 'like', "%{$filter}%");
                }
            });
        }
        $total = $products->count();
        if (isset($limit)) {
            $products->limit($limit)->offset($offset);
        }
        $products = $products->get();

        if (isset($request->store_id) && $request->store_id !== "") {


            $storeId = $request->store_id;

            $categoryGroupIds = DB::table('category_group_store')
                ->where('store_id', $storeId)
                ->pluck('category_group_id')
                ->unique()
                ->toArray();


            $rawSubCategoryIds = DB::table('sub_category_groups')
                ->whereIn('category_group_id', $categoryGroupIds)
                ->pluck('subcategory_ids')
                ->toArray();


            $categoryIds = collect($rawSubCategoryIds)
                ->flatMap(fn($v) => explode(',', $v))
                ->map(fn($id) => (int) trim($id))
                ->unique()
                ->values()
                ->toArray();
            
            // dd($storeId, $categoryGroupIds, $rawSubCategoryIds, $categoryIds);
            

            $filteredCategories = array_filter($categories, function ($cat) use ($categoryIds) {
                return in_array($cat['id'], $categoryIds);
            });

            $filteredCategories = array_values($filteredCategories);

            // dd($filteredCategories);
        }
        


        $data = array(
            "categories" => $request->store_id ? $filteredCategories : $categories,
            "products" => $products,
         
        );
        if(!isset($request->type)){
            $data["sellers"] = $sellers;
        }
        
        return CommonHelper::responseWithData($data, $total);
    }

    public function getProducts_sellerapp(Request $request)
    {
        try {

            $currency = Setting::get_value('currency');
            $user_id = $request->user('api-customers') ? $request->user('api-customers')->id : '';

            $limit = ($request->limit) ?? 10;
            $offset = ($request->offset) ?? 0;

            $sort = ($request->sort) ?? 'row_order';
            $order = ($request->order) ?? 'asc';

            if ($sort == 'new') {
                $sort = 'created_at DESC';
                $price = 'MIN(discounted_price)';
                $price_sort = 'pv.discounted_price  ASC';
            } elseif ($sort == 'old') {
                $sort = 'created_at ASC';
                $price = 'MIN(discounted_price)';
                $price_sort = 'pv.discounted_price  ASC';
            } elseif ($sort == 'high') {

                $sort = 'max_price DESC';

                $price = 'MAX(if(pv.discounted_price > 0 && pv.discounted_price != 0, pv.discounted_price, pv.price))';
                $price_sort = 'if(pv.discounted_price > 0 && pv.discounted_price != 0, pv.discounted_price, pv.price) DESC';
            } elseif ($sort == 'low') {
                $sort = 'min_price ASC';

                $price = 'MIN(if(pv.discounted_price > 0 && pv.discounted_price != 0, pv.discounted_price, pv.price))';
                $price_sort = 'if(pv.discounted_price > 0 && pv.discounted_price != 0, pv.discounted_price, pv.price) ASC';
            } elseif ($sort == 'discount') {
                $sort = 'cal_discount_percentage DESC';
                $price = 'MIN(if(pv.discounted_price > 0 && pv.discounted_price != 0, pv.discounted_price, pv.price))';
                $price_sort = 'cal_discount_percentage DESC';
            } elseif ($sort == 'popular') {
                $sort = 'order_counter DESC';
                $price = 'MIN(pv.discounted_price)';
                $price_sort = 'order_counter DESC';
            } else {
                $sort = 'p.row_order ASC';
                $price = 'MIN(pv.discounted_price)';
                $price_sort = 'pv.id  ASC';
            }

            $category_id = $request->get('category_id');


            $seller_id = auth()->user()->seller->id;
            $brand_id = $request->get('brand_id');
            $seller_slug = '';
            $where = "";

            if (isset($request['search']) && $request['search'] != '') {
                $search = $request['search'];
                $where .= " AND ( p.`name` like '%" . $search . "%' OR p.`slug` like '%" . $search . "%' OR p.`tags` like '%" . $search . "%') ";
            }

            if (isset($request->section_id) && $request->section_id != "") {
                $section_id = $request->section_id;
                $section = Section::select("*")->where("id", "=", $section_id)->first();

                $product_ids = CommonHelper::getProductIdsSection($section);
                if ($product_ids !== "") {
                    $where .= "AND p.id IN  ($product_ids)";
                }
            }

            if (isset($request['seller_slug']) && !empty($request['seller_slug'])) {
                $seller_slug = $request['seller_slug'];
                if (isset($request['category_id']) && !empty($request['category_id']) && is_numeric($request['category_id'])) {
                    $seller_category = Seller::where('slug', $seller_slug)->first(['categories']);
                    if(!empty($seller_category)) {
                        $category = $seller_category['categories'];
                        $data = explode(",", $category);
                        $search = (in_array($category_id, $data, TRUE)) ? 1 : 2;
                        if ($search == 2) {
                            return CommonHelper::responseError(__('no_products_found'));
                        } else {
                            $where .= " AND s.`slug` = '$seller_slug' AND p.`category_id` IN (" . $category_id . ") ";
                        }
                    }else{
                        return CommonHelper::responseError(__('no_products_found'));
                    }
                } else {
                    $seller_category = Seller::where('slug', $seller_slug)->first(['categories']);
                    if(!empty($seller_category)) {
                        $category = $seller_category['categories'];
                        $where .= " AND s.`slug` =  '$seller_slug' AND p.category_id IN (" . $category . " )";
                    }else{
                        return CommonHelper::responseError(__('no_products_found'));
                    }
                }
            }

            if (isset($request['slug']) && !empty($request['slug'])) {
                $slug = $request['slug'];
                $where .= " AND p.`slug` =  '$slug' ";
            }

            if (isset($seller_id) && !empty($seller_id) && is_numeric($seller_id)) {
                
                if (isset($request['category_id']) && !empty($request['category_id']) && is_numeric($request['category_id'])) {
                    
                    $seller_category = Seller::where('id', $seller_id)->first(['categories']);
                    if(!empty($seller_category)) {
                        $category = $seller_category['categories'];
                        $data = explode(",", $category);
                        $search = (in_array($category_id, $data, TRUE)) ? 1 : 2;
                        if ($search == 2) {
                            return CommonHelper::responseError(__('no_products_found'));
                        } else {
                            $where .= " AND p.`seller_id` = " . $seller_id . " AND p.`category_id` IN (" . $category_id . ") ";
                        }
                    }else{
                        return CommonHelper::responseError(__('no_products_found'));
                    }
                } else {
                    
                    $seller_category = Seller::where('id', $seller_id)->first(['categories']);
                    if(!empty($seller_category)) {
                        $category = $seller_category['categories'];
                        $where .= " AND p.`seller_id` = " . $seller_id . " AND p.category_id IN (" . $category . " )";
                    }else{
                        return CommonHelper::responseError(__('no_products_found'));
                    }
                }
            }

            if (isset($request['category_id']) && !empty($request['category_id']) && is_numeric($request['category_id'])) {
                if (!isset($seller_id) && empty($seller_id) && !isset($request['seller_slug']) && empty($request['seller_slug'])) {
                    $where .= " AND p.`category_id`=" . $category_id;
                }
            }


            if (isset($request['category_id']) && !empty($request['category_id']) && is_numeric($request['category_id'])) {
                $where .= " AND p.`category_id`=" . $category_id;
            }

            if (isset($request['brand_id']) && !empty($request['brand_id']) && is_numeric($request['brand_id'])) {
                $where .= " AND p.`brand_id`=" . $brand_id;
            }

            $seller_id =  $seller_id; 

            $products = array();
            $i = 0;

             $products = Product::select('p.*','p.type as d_type', 's.store_name as seller_name','s.slug as seller_slug','s.status as seller_status')
                ->from('products as p')
                ->leftJoin('sellers as s', 'p.seller_id', '=', 's.id')
                ->leftJoin('categories as c', 'p.category_id', '=', 'c.id')
                ->whereIn('s.status', [1, 3])
                ->where('p.seller_id',$seller_id)
                
             ->groupBy("p.id");
                
                 if (isset($request->min_price) && isset($request->max_price) && intval($request->max_price)) {
                $products = $products->havingRaw(" min_price > " . intval(intval($request->min_price) - 1) . " and max_price < " . intval(intval($request->max_price) + 1));
            }
            if (isset($request->search) && $request->search != '') {
                $search = $request->search;
               
                    $products = $products->where(function($query) use ($search) {
                        $query->where('p.name', 'like', '%' . $search . '%')
                              ->orWhere('p.slug', 'like', '%' . $search . '%')
                              ->orWhere('p.tags', 'like', '%' . $search . '%');
                    });
                
            }

            if (isset($request->brand_ids) && $request->brand_ids != "") {
                $brand_ids = explode(",", $request->brand_ids);
                $products = $products->whereIn('p.brand_id', $brand_ids);
            }
            if (isset($request->sizes) && $request->sizes != "" && isset($request->unit_ids) && $request->unit_ids != "") {
                $sizes = explode(",", $request->sizes);
                $unit_ids = explode(",", $request->unit_ids);
                $products = $products->whereIn('pv.measurement', $sizes)->whereIn('pv.stock_unit_id', $unit_ids);
            }
            if (isset($request->is_approved) && $request->is_approved !== "") {
                $products = $products->where('p.is_approved', $request->is_approved);
            }

            $products_total = $products->get()->count();
           
            $products = $products->orderByRaw($sort)->skip($offset)->take($limit)->get();


            $products = $products->makeHidden(['seller_id','row_order','return_status',
                'cancelable_status','till_status','description','status','return_days','pincodes',
                'cod_allowed','pickup_location','tags','d_type','seller_name','seller_slug','seller_status',
                'created_at', 'updated_at','deleted_at','image','other_images']);

            $i = 0;

            foreach ($products as $row){

                $sql = ProductVariant::select('*',
                    DB::raw("(SELECT short_code FROM units u WHERE u.id=pv.stock_unit_id) as stock_unit_name"))
                    ->from('product_variants as pv')
                    ->where('pv.product_id','=',$row['id'])
                    ->orderBy('pv.status','ASC');
                $variants = $sql->get();
                $variants = $variants->makeHidden(['product_id','status','measurement_unit_id','stock_unit_id','deleted_at']);
                if (empty($variants)) {
                    continue;
                }

              
                CommonHelper::getProductDetails($row['id'],$user_id,false);
                $variantArray = array();
                for ($k = 0; $k < count($variants); $k++) {
                    array_push($variantArray,CommonHelper::getProductVariant($variants[$k]['id'],$user_id));
                }
                $products[$i]['variants'] = $variantArray;
                $i++;
            }

            $productSql = Product::from('products as p')->select(
                DB::raw('COUNT(p.id) AS total'),
                DB::raw('MIN((select MIN(if(discounted_price > 0, discounted_price, price)) from product_variants where product_variants.product_id = p.id)) as min_price'),
                DB::raw('MAX((select MAX(if(discounted_price > 0, discounted_price, price)) from product_variants where product_variants.product_id = p.id)) as max_price')
            )->leftJoin('product_variants as pv', 'pv.product_id', '=', 'p.id')->where('p.seller_id', $seller_id);
            
            
            if (isset($request->min_price) && isset($request->max_price) && intval($request->max_price)) {
                $productSql = $productSql->havingRaw(" min_price > " . intval(intval($request->min_price) - 1) . " and max_price < " . intval(intval($request->max_price) + 1));
            }

            if (isset($request->brand_ids) && $request->brand_ids != "") {
                $brand_ids = explode(",", $request->brand_ids);
                $productSql = $productSql->whereIn('p.brand_id', $brand_ids);
            }
            if (isset($request->sizes) && $request->sizes != "" && isset($request->unit_ids) && $request->unit_ids != "") {
                $sizes = explode(",", $request->sizes);
                $unit_ids = explode(",", $request->unit_ids);
                $productSql = $productSql->whereIn('pv.measurement', $sizes)->whereIn('pv.stock_unit_id', $unit_ids);
            }

            if ($where != "") {
                $productSql = $productSql->whereRaw(substr($where, 4));
            }
            

            $productResult = $productSql->first();
            $total_min_price = $productResult->min_price;
            $total_max_price = $productResult->max_price;
            $total =  $productResult->total;

            if (!empty($products)) {
                $brands = CommonHelper::getBrandsHavingProducts();
                $sizes = CommonHelper::getProductVariantsSize();
                //return CommonHelper::responseWithData($products,$total);
                return Response::json(array(
                    'status' => 1,
                    'message' => 'success',
                    'total' => $products_total,
                    'data' => $products
                ));
            } else {
                return CommonHelper::responseError(__('no_products_found'));
            }
        } catch (\Exception $e) {
            Log::info("Products Error : " . $e->getMessage());
            throw $e;
            return CommonHelper::responseError("Something Went Wrong!"); 
        }



    }

    
    public function getAllStores() {

        $stores = Store::all();
        return response()->json($stores);
    }

    public function dataBasedOnStoreSelection(Request $request) {

        $id = $request->store_id;
        $category_group_ids = CategoryGroupStore::where('store_id',$id)->pluck('category_group_id');

        $category_groups = CategoryGroup::whereIn('id',$category_group_ids)->get();

        return response()->json([
            "success" => true,
            // "data" => $category_group_ids,
            "data" => $category_groups,
        ]);
    }


    public function dataBasedOnCategoryGroupSelection(Request $request) {

        $id = $request->category_group_id;
        $category_groups = SubCategoryGroup::where('category_group_id',$id)->get();

        return response()->json([
            "success" => true,
            // "data" => $category_group_ids,
            "data" => $category_groups,
        ]);
    }

    public function dataBasedOnSubCategoryGroupSelection(Request $request) {

        $id = $request->sub_category_group_id;
        $category_group = SubCategoryGroup::where('id',$id)->first();

        $ids = explode(',', $category_group->subcategory_ids);
        $categories = Category::whereIn('id',$ids)->get();

        return response()->json([
            "success" => true,
            // "data" => $category_group_ids,
            "data" => $categories,
        ]);
    }


    public function getFullStoreData(Request $request)
    {
        $stores = Store::all();

        // Support multiple store IDs (comma-separated)
        $storeIds = [];
        if ($request->store_id) {
            $storeIds = array_filter(explode(',', $request->store_id));
        }

        $categoryGroups = collect([]);
        $subCategoryGroups = collect([]);
        $categories = collect([]);
        $brands = collect([]);

        if (!empty($storeIds)) {
            // Get category group IDs from all selected stores
            $category_group_ids = CategoryGroupStore::whereIn('store_id', $storeIds)
                ->pluck('category_group_id')
                ->unique();

            $categoryGroups = CategoryGroup::whereIn('id', $category_group_ids)->get();

            // Get active brands for selected stores
            $brands = \App\Models\Brand::whereIn('store_id', $storeIds)
                ->where('status', 1)
                ->get();
        }

        $categoryGroupId = $request->category_group_id;

        if ($categoryGroupId) {
            $subCategoryGroups = SubCategoryGroup::where('category_group_id', $categoryGroupId)->get();
        }

        $subCategoryGroupId = $request->sub_category_group_id;

        if ($subCategoryGroupId) {
            $subCatGroup = SubCategoryGroup::where('id', $subCategoryGroupId)->first();
            if ($subCatGroup && $subCatGroup->subcategory_ids) {
                $ids = array_filter(explode(',', $subCatGroup->subcategory_ids));
                $categories = Category::whereIn('id', $ids)->get();
            }
        }

        return response()->json([
            'success' => true,
            'store_data' => [
                'stores' => $stores,
                'categories_data' => $categoryGroups,
                'sub_category_groups_data' => $subCategoryGroups,
                'categories' => $categories,
                'brands' => $brands,
            ]
        ]);
    }



    public function getActiveProducts()
    {
       $query = \DB::table('products as p')
            ->select(
                'p.id as id',
                'p.id as product_id',
                'p.name',
                'p.seller_id',
                'p.status',
                'p.tax_id',
                'p.image',
                's.name as seller_name',
                's.id as seller_id',
                'p.indicator',
                'p.manufacturer',
                'p.made_in',
                'p.return_status',
                'p.cancelable_status',
                'p.till_status',
                'pv.id as product_variant_id',
                'pv.price',
                'pv.discounted_price',
                'pv.measurement',
                'pv.status as pv_status',
                'pv.stock',
                'pv.stock_unit_id',
                'u.short_code',
                \DB::raw('(select short_code from units where units.id = pv.stock_unit_id) as stock_unit')
            )
            ->join('sellers as s', 'p.seller_id', '=', 's.id')
            ->join('product_variants as pv', 'p.id', '=', 'pv.product_id')
            ->join('units as u', 'pv.stock_unit_id', '=', 'u.id')
            ->where('p.status', 1);

        // Check role and filter by seller if applicable
        if (auth()->user()->role_id == Role::$roleSeller) {
            $query->where('p.seller_id', auth()->user()->seller->id);
        }

        $products = $query->orderBy('p.id', 'DESC')->get();

        return CommonHelper::responseWithData($products);
    }

    public function save(Request $request){

        // dd($request->all());


        $validator = Validator::make($request->all(),[
            // 'name' => [ 'required',
            //             Rule::unique('products')->where(function($query) use ($request) {
            //                 $query->where('seller_id', $request->seller_id);
            //             })
            //     ],
            'name' => 'required',
            'seller_id' => 'nullable',
           
            'id' => 'nullable|integer',
            'image' => $request->id ? 'nullable' : 'required|image|mimes:jpeg,png,jpg,gif',
            'description' => 'required',
            
            'type' => 'required',
            'is_unlimited_stock' => 'required',

            'packet_measurement.*' =>  ['required_if:type,packet','numeric', Rule::notIn([0]),],
            'packet_price.*' =>  ['required_if:type,packet','numeric'],
            'packet_stock.*' =>  ['required_if:type,packet,is_unlimited_stock,0','numeric',
                function ($attribute, $value, $fail) use ($request) {
                    $index = explode('.', $attribute)[1];
                    $status = $request->input("packet_status.{$index}", 1);

                    if ($request->input('is_unlimited_stock') == 0 && $value == 0 && $request->input('type') == 'packet' && $status != 0) {
                        $fail($attribute.' must be greater than 0 when is_unlimited_stock is 0 and status is not "Sold Out".');
                    }
                },],
            'packet_stock_unit_id.*' =>  ['required_if:type,packet','numeric'],

            'loose_measurement.*' =>  ['required_if:type,loose','numeric', Rule::notIn([0]),],
            'loose_price.*' =>  ['required_if:type,loose','numeric'],
            'loose_stock.*' =>  ['required_if:type,loose,is_unlimited_stock,0','numeric',
                function ($attribute, $value, $fail) use ($request) {
                    $index = explode('.', $attribute)[1];
                    $status = $request->input('status', $request->input("loose_status.{$index}", 1));

                    if ($request->input('is_unlimited_stock') == 0 && strval($value) === '0' && $request->input('type') == 'loose' && intval($status) !== 0) {
                        $fail($attribute.' must be greater than 0 when is_unlimited_stock is 0 and status is not "Sold Out".');
                    }
                },],
            'loose_stock_unit_id.*' => ['required_if:type,loose','nullable','numeric'],
            'loose_status.*' => ['required_if:type,loose','nullable'],
            'category_id' => 'required',

            'category_group_id' => 'required',
            'sub_category_group_id' => 'required',

            'barcode' => 'nullable|unique:products,barcode',
        ],[
            'name.unique' => 'The product name has already been taken.',
            'is_unlimited_stock.required' => 'The Stock Limit field is required.',
            'category_id.required' => 'The Category name field is required.',
            
            'sub_category_group_id.required' => 'The Sub Category Group is required.',
            'category_group_id.required' => 'The Category Group is required.',

            'packet_measurement.*.required_if' => 'The Packet Measurement is required when the type is "Packet".',
            'packet_measurement.*.numeric' => 'The Packet Measurement  must be a number.',
            'packet_measurement.*.not_in' => 'The Packet Measurement must not be zero.',
            'packet_stock.*.required_if' => 'The Packet Stock is required when the type is "Packet" and stock is limited.',
            'packet_stock.*.not_in' => 'The Packet Stock must not be zero.',
            'packet_stock_unit_id.*.required_if' => 'The Packet Stock Unit is required when the type is "Packet".',

            'loose_measurement.*.required_if' => 'The Loose Measurement is required when the type is "Loose".',
            'loose_measurement.*.numeric' => 'The Loose Measurement  must be a number.',
            'loose_measurement.*.not_in' => 'The Loose Measurement must not be zero.',
            'loose_stock_unit_id.required_if' => 'The Loose Stock Unit is required when the type is "Loose".',
            'loose_stock_unit_id.numeric' => 'The Loose Stock Unit must be a number.',

        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $variations = array();
        if($request->type == "packet") {
            foreach ($request->packet_measurement as $index => $item) {
                $data = array();
                $data['measurement'] = $request->packet_measurement[$index];
                $data['price'] = $request->packet_price[$index];
                $data['discounted_price'] = $request->discounted_price[$index];
                $data['status'] = $request->packet_status[$index];
                $data['stock'] = ($request->is_unlimited_stock == 0)?$request->packet_stock[$index]:0;
                
                $data['stock_unit_id'] = $request->packet_stock_unit_id[$index];
                $variations[] = $data;

            }

        }else{
            foreach ($request->loose_measurement as $index => $item) {
                $data = array();
                $data['measurement'] = $request->loose_measurement[$index];
                $data['price'] = $request->loose_price[$index];
                $data['discounted_price'] = $request->loose_discounted_price[$index];
                $variations[] = $data;
            }
        }
        if (count($variations) !== count(array_unique($variations, SORT_REGULAR))) {
            return CommonHelper::responseError("Variations are duplicate!");
        }

        
        if($request->max_allowed_quantity == "" || $request->max_allowed_quantity == 0 ){
            $max_allowed_quantity = Setting::get_value('max_cart_items_count');
            if($max_allowed_quantity == "" || $max_allowed_quantity == 0 ){
                return CommonHelper::responseError("Maximum items allowed in cart in empty in store settings.");
            }
        }else{
            $max_allowed_quantity = $request->max_allowed_quantity;
        }

        DB::beginTransaction();
        
        try {
            $slug = $request->slug ?: preg_replace(
                '/\s+/', '-', trim(
                    preg_replace('/[^\p{L}\p{N} ]/u', '', $request->name)
                )
            );
            
            $count = Product::where('slug', 'LIKE', "{$slug}%")->count();
         
            $row_order = Product::max('row_order') + 1;
            $product = new Product();
            $product->name = $request->name;
            $product->slug = $count ? "{$slug}-{$count}" : $slug;
            $product->row_order = $row_order;
            $product->tax_id = $request->tax_id ?? "";
            $product->brand_id = $request->brand_id ?? "";

            if($request->seller_id == 0){
                $seller_id_for_product = null;
                $store_id_for_product = $request->store_id;
            }
            else{
                $seller = Seller::find($request->seller_id);
                if (!$seller) {
                    return CommonHelper::responseError("Seller not found");
                }
                
                $seller_id_for_product = $request->seller_id;
                $store_id_for_product = $seller->store_id;
            }

            $product->seller_id = $seller_id_for_product;
            $product->store_id = $store_id_for_product;
            $product->tags = $request->tags ?? "";
            $product->type = $request->type;
            $product->category_id = $request->category_id;

            $product->category_group_id = $request->category_group_id;
            $product->sub_category_group_id = $request->sub_category_group_id;      
            
            $product->indicator = $request->product_type;
            $product->manufacturer = $request->manufacturer;
            $product->made_in = $request->made_in;
            $product->tax_included_in_price = $request->tax_included_in_price;
            $product->return_status = $request->return_status;
            $product->return_days = $request->return_days;
            $product->cancelable_status = $request->cancelable_status;
            $product->till_status = $request->till_status;
            $product->cod_allowed = $request->cod_allowed_status;
            $product->total_allowed_quantity = $max_allowed_quantity;
            $product->description = $request->description;
            $product->is_unlimited_stock = $request->is_unlimited_stock;
            $product->is_skinned_one = $request->is_skinned_one ?? 0;
            $product->is_cleaned = $request->is_cleaned ?? 0;
            $product->before_cleaning_weight = $request->before_cleaning_weight ?? null;
            $product->after_cleaning_weight = $request->after_cleaning_weight ?? null;
            $product->pieces = $request->pieces ?? null;

            // Handle video upload
            if ($request->hasFile('video')) {
                $allowedExtensions = ['mp4', 'mov', 'avi', 'webm'];
                $extension = $request->file('video')->getClientOriginalExtension();
                if (in_array(strtolower($extension), $allowedExtensions)) {
                    $videoPath = \App\Services\MediaUploadService::uploadWithFullUrl(
                        $request->file('video'),
                        'products/videos'
                    );
                    $product->video_url = $videoPath;
                }
            } else {
                $product->video_url = $request->existing_video_url ?? null;
            }

            $require_products_approval = Seller::where('id', $product->seller_id)->pluck('require_products_approval')->first();
            if ($require_products_approval == 1) {
                $product->is_approved = 0;
            }elseif($require_products_approval == 0){
                $product->is_approved = 1;
            }
            $product->status = 1;
            $product->brand_id = $request->brand_id;
            $product->fssai_lic_no = $request->fssai_lic_no ?? "";
            if($request->fssai_lic_no != null){
                $pattern = '/^[0-9]{14}$/';
                // Check if the FSSAI number matches the pattern
                if (preg_match($pattern, $request->fssai_lic_no)) {
                
                } else {
                    return CommonHelper::responseError("Please enter valid FSSAI no.");
                }
            }
            $product->barcode = $request->barcode ?? "";
            if($request->barcode != null){
                $pattern = '/^[a-zA-Z0-9-]+$/';
                // Check if the FSSAI number matches the pattern
                if (preg_match($pattern, $request->barcode)) {
                
                } else {
                    return CommonHelper::responseError("Please enter valid Barcode");
                }
            }
            $product->meta_title = $request->meta_title ?? "";
            $product->meta_keywords = $request->meta_keywords ?? "";
            $product->schema_markup = $request->schema_markup ?? "";
            $product->meta_description = $request->meta_description ?? "";
            $image = '';
            if($request->hasFile('image')){
                $image = MediaUploadService::upload(
                    $request->file('image'),
                    'products'
                );
            }else{
                $image = $request->image; //for clonoing product
            }
            $product->image = $image;
            $product->save();

            if($request->hasFile('other_images')){
                CommonHelper::uploadProductImages($request->file('other_images'),$product->id);
            }

            /*Variance*/
            if($request->type == "packet"){

                foreach ($request->packet_measurement as $index => $item){

                    $data = array();
                    $data['product_id'] = $product->id;
                    $data['type'] = $request->type;
                    $data['measurement'] = $request->packet_measurement[$index];
                    $data['price'] = $request->packet_price[$index];
                    $data['discounted_price'] = isset($request->discounted_price[$index]) ? $request->discounted_price[$index] : 0;
                    $data['status'] = $request->packet_status[$index] ?? 1;
                    $data['stock'] = ($request->is_unlimited_stock == 0)?$request->packet_stock[$index]:0;
                    $data['stock_unit_id'] = isset($request->packet_stock_unit_id[$index]) ? $request->packet_stock_unit_id[$index] : 0;

                    ProductVariant::insert($data);
                    $variant_id = DB::getPdo()->lastInsertId();
                    if($request->hasFile('packet_variant_images_'.$index)){
                        CommonHelper::uploadProductImages($request->file('packet_variant_images_'.$index),$product->id, $variant_id);
                    }
                }
            }

            if($request->type == "loose"){
                foreach ($request->loose_measurement as $index => $item){

                    $data = array();
                    $data['product_id'] = $product->id;
                    $data['type'] = $request->type;
                    $data['stock'] = ($request->is_unlimited_stock == 0)?$request->loose_stock[$index]:0;
                    $data['stock_unit_id'] = $request->loose_stock_unit_id[$index];
                    $data['status'] = $request->loose_status[$index] ?? 1;
                    $data['measurement'] = $request->loose_measurement[$index];
                    $data['price'] = $request->loose_price[$index];

                    $data['discounted_price'] = isset($request->loose_discounted_price[$index]) ? $request->loose_discounted_price[$index] : 0;

                    ProductVariant::insert($data);
                    $variant_id = DB::getPdo()->lastInsertId();
                    if($request->hasFile('loose_variant_images_'.$index)){
                        CommonHelper::uploadProductImages($request->file('loose_variant_images_'.$index),$product->id, $variant_id);
                    }
                }
            }
            $tagIds = array_filter(array_map('trim', explode(',', $request->tag_ids)), function($value) {
                return $value !== '';
            });
            
            $product = Product::find($product->id);
            
            if ($product) {
                $existingTagIds = [];
                $newTagNames = [];
            
                // Separate integer IDs (existing tags) from string names (new tags)
                foreach ($tagIds as $tagId) {
                    if (is_numeric($tagId)) {
                        $existingTagIds[] = (int)$tagId;
                    } else {
                        $newTagNames[] = $tagId;
                    }
                }
            
                // Create new tags and get their IDs
                $newTagIds = [];
                foreach ($newTagNames as $tagName) {
                    $newTag = Tag::firstOrCreate(['name' => $tagName]);
                    $newTagIds[] = $newTag->id;
                }
            
                // Combine existing and new tag IDs
                $allTagIds = array_merge($existingTagIds, $newTagIds);
            
                // Sync the tags with the product
                $product->tags()->sync($allTagIds);
            }

            DB::commit();
        } catch (\Exception $e) {
            Log::info("Error : ".$e->getMessage());
            DB::rollBack();
            // throw $e;
            return CommonHelper::responseError($e->getMessage());
        }

        // return CommonHelper::responseSuccess("Product Saved Successfully!");
        return response()->json([
            "status" => 1,
            "message" => "Product Created Successfully!",
            "store_id" => $product->store_id
        ]);
    }

    public function edit($id){
        $product = Product::with('seller','images','variants.images', 'variants.unit','category', 'tax','madeInCountry','tags')
            ->where('id',$id)->first();
        if(!$product){
            return CommonHelper::responseError("Product Not found!");
        }
        return CommonHelper::responseWithData($product);
    }

    public function update(Request $request){

        // Get seller to determine store_id - same logic as save method
        if(empty($request->seller_id) || $request->seller_id == 0 || $request->seller_id == "" || $request->seller_id == "null"){
            $seller_id_for_product = null;
            $store_id_for_product = $request->store_id;
            $seller = null;
        }
        else{
            $seller = Seller::find($request->seller_id);
            if (!$seller) {
                return CommonHelper::responseError("Seller not found");
            }
            $seller_id_for_product = $request->seller_id;
            $store_id_for_product = $seller->store_id;
        }

        // Make category_group_id and sub_category_group_id optional for store_id 15
        $categoryGroupRules = $store_id_for_product == 15 ? 'nullable' : 'required';

        $validator = Validator::make($request->all(),[
            // 'name' =>[ 'required',
            //     Rule::unique('products')->where(function($query) use ($request) {
            //         $query->where('seller_id', $request->seller_id)->where('id', '!=', $request->id);
            //     })
            // ],

            'seller_id' => 'nullable',
            'description' => 'required',

            'type' => 'required',
            'is_unlimited_stock' => 'required',

            'packet_measurement.*' =>  ['required_if:type,packet','numeric', Rule::notIn([0]),],
            'packet_price.*' =>  ['required_if:type,packet','numeric'],
            'packet_stock.*' => [
                'required_if:type,packet,is_unlimited_stock,0',
                'numeric',
                function ($attribute, $value, $fail) use ($request) {
                    $index = explode('.', $attribute)[1];
                    $status = $request->input("packet_status.{$index}", 1);

                    if ($request->input('type') === 'packet' && $request->input('is_unlimited_stock') == 0 && $value == 0 && $status != 0) {
                        $fail('The Packet Stock must be greater than 0 when Limited Stock Limit and status is not "Sold Out".');
                    }
                },
            ],
            'packet_stock_unit_id.*' =>  ['required_if:type,packet','numeric'],

            'loose_measurement.*' =>  ['required_if:type,loose','numeric', Rule::notIn([0]),],
            'loose_price.*' =>  ['required_if:type,loose','numeric'],
            'loose_stock.*' =>  ['required_if:type,loose,is_unlimited_stock,0','numeric',
                function ($attribute, $value, $fail) use ($request) {
                    $index = explode('.', $attribute)[1];
                    $status = $request->input('status', $request->input("loose_status.{$index}", 1));

                    if ($request->input('is_unlimited_stock') == 0 && strval($value) === '0' && $request->input('type') == 'loose' && intval($status) !== 0) {
                        $fail($attribute.' must be greater than 0 when is_unlimited_stock is 0 and status is not "Sold Out".');
                    }
                },],
            'loose_stock_unit_id.*' => ['required_if:type,loose','nullable','numeric'],
            'loose_status.*' => ['required_if:type,loose','nullable'],

            'category_id' => 'required',


            'category_group_id' => $categoryGroupRules,
            'sub_category_group_id' => $categoryGroupRules,

        ],[
            // 'name.unique' => 'The product name has already been taken.',
            // 'seller_id.required' => 'The seller name field is required.',
            'is_unlimited_stock.required' => 'The Stock Limit field is required.',
            'category_id.required' => 'The Category name field is required.',

            'sub_category_group_id.required' => 'The Sub Category Group is required.',
            'category_group_id.required' => 'The Category Group is required.',


            'packet_measurement.*.required_if' => 'The Packet Measurement is required when the type is "Packet".',
            'packet_measurement.*.numeric' => 'The Packet Measurement  must be a number.',
            'packet_measurement.*.not_in' => 'The Packet Measurement must not be zero.',
            'packet_stock.*.required_if' => 'The Packet Stock is required when the type is "Packet" and stock is limited.',
            'packet_stock.*.not_in' => 'The Packet Stock must not be zero.',
            'packet_stock_unit_id.*.required_if' => 'The Packet Stock Unit is required when the type is "Packet".',

            'loose_measurement.*.required_if' => 'The Loose Measurement is required when the type is "Loose".',
            'loose_measurement.*.numeric' => 'The Loose Measurement  must be a number.',
            'loose_measurement.*.not_in' => 'The Loose Measurement must not be zero.',
            'loose_stock_unit_id.required_if' => 'The Loose Stock Unit is required when the type is "Loose".',
            'loose_stock_unit_id.numeric' => 'The Loose Stock Unit must be a number.',
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        $variations = array();
        if($request->type == "packet") {
            foreach ($request->packet_measurement as $index => $item) {
                $data = array();
                $data['measurement'] = $request->packet_measurement[$index];
                $data['price'] = $request->packet_price[$index];
                $data['discounted_price'] = $request->discounted_price[$index];
                $data['status'] = $request->packet_status[$index];
                $data['stock'] = $request->packet_stock[$index];
                $data['stock_unit_id'] = $request->packet_stock_unit_id[$index];
                $variations[] = $data;
            }
        }else{
            foreach ($request->loose_measurement as $index => $item) {
                $data = array();
                $data['measurement'] = $request->loose_measurement[$index];
                $data['price'] = $request->loose_price[$index];
                $data['discounted_price'] = $request->loose_discounted_price[$index];
                $variations[] = $data;
            }
        }
        if (count($variations) !== count(array_unique($variations, SORT_REGULAR))) {
            return CommonHelper::responseError("Variations are duplicate!");
        }

        if($request->max_allowed_quantity == "" || $request->max_allowed_quantity == 0 ){
            $max_allowed_quantity = Setting::get_value('max_cart_items_count');
            if($max_allowed_quantity == " " || $max_allowed_quantity == 0 ){
                return CommonHelper::responseError("Maximum items allowed in cart in empty in store settings.");
            }
        }else{
            $max_allowed_quantity = $request->max_allowed_quantity;
        }

        DB::beginTransaction();
        try {
            $product_image_ids = json_decode($request->deleteImageIds);
            if(count($product_image_ids) !==0){
                foreach ($product_image_ids as $index => $product_image_id){
                    $image = ProductImages::find($product_image_id);
                    if($image){
                        $image->delete();
                    }
                }
            }

            $product = Product::find($request->id);
            $row_order = Product::max('row_order') + 1;
            
            if ($product->name !== $request->name) {
                $slug = $request->slug ?: preg_replace(
                    '/\s+/', '-', trim(
                        preg_replace('/[^\p{L}\p{N} ]/u', '', $request->name)
                    )
                );            
                $count = Product::where('slug', 'LIKE', "{$slug}%")->where('id', '!=', $request->id)->count();
                $product->slug = $count ? "{$slug}-{$count}" : $slug;
            }
            
            $product->name = $request->name;

            $product->row_order = $row_order;
            $product->tax_id = $request->tax_id;
            $product->brand_id = ($request->brand_id === 'null' || $request->brand_id === '' || $request->brand_id === null) ? null : $request->brand_id;
            $product->seller_id = $seller_id_for_product;
            $product->type = $request->type;
            $product->category_id = $request->category_id;

            // Get store_id from seller or request (same logic as save method)
            $product->store_id = $store_id_for_product;

            // For store_id 15, category_group_id and sub_category_group_id are optional
            // Handle string 'null' values from frontend - convert to actual null
            $categoryGroupId = ($request->category_group_id === 'null' || $request->category_group_id === '' || $request->category_group_id === null) ? null : $request->category_group_id;
            $subCategoryGroupId = ($request->sub_category_group_id === 'null' || $request->sub_category_group_id === '' || $request->sub_category_group_id === null) ? null : $request->sub_category_group_id;
            $product->category_group_id = $store_id_for_product == 15 ? $categoryGroupId : $categoryGroupId;
            $product->sub_category_group_id = $store_id_for_product == 15 ? $subCategoryGroupId : $subCategoryGroupId;


            $product->indicator = $request->product_type;
            $product->manufacturer = ($request->manufacturer === 'null' || $request->manufacturer === '' || $request->manufacturer === null) ? null : $request->manufacturer;
            $product->made_in = ($request->made_in === 'null' || $request->made_in === '' || $request->made_in === null) ? null : $request->made_in;
            $product->tax_included_in_price = $request->tax_included_in_price;
            $product->return_status = $request->return_status;
            $product->return_days = $request->return_days;
            $product->cancelable_status = $request->cancelable_status;
            $product->till_status = $request->till_status;
            $product->cod_allowed = $request->cod_allowed_status;
            $product->total_allowed_quantity = $max_allowed_quantity;
            $product->description = $request->description;
            $product->is_unlimited_stock = $request->is_unlimited_stock;
            $product->is_skinned_one = $request->is_skinned_one ?? 0;
            $product->is_cleaned = $request->is_cleaned ?? 0;
            $product->before_cleaning_weight = $request->before_cleaning_weight ?? null;
            $product->after_cleaning_weight = $request->after_cleaning_weight ?? null;
            $product->pieces = $request->pieces ?? null;

            // Handle video upload
            if ($request->hasFile('video')) {
                $allowedExtensions = ['mp4', 'mov', 'avi', 'webm'];
                $extension = $request->file('video')->getClientOriginalExtension();
                if (in_array(strtolower($extension), $allowedExtensions)) {
                    $videoPath = \App\Services\MediaUploadService::uploadWithFullUrl(
                        $request->file('video'),
                        'products/videos'
                    );
                    $product->video_url = $videoPath;
                }
            } else {
                // Keep existing video or set to null if removed
                $product->video_url = $request->existing_video_url ?? null;
            }

            if (isset($request->is_approved)) {
                $product->is_approved = $request->is_approved ?? 1;
            }
            $product->fssai_lic_no = ($request->fssai_lic_no === 'null' || $request->fssai_lic_no === '' || $request->fssai_lic_no === null) ? "" : $request->fssai_lic_no;
            if($request->fssai_lic_no != null && $request->fssai_lic_no !== 'null' && $request->fssai_lic_no !== ''){
                $pattern = '/^[0-9]{14}$/';
                // Check if the FSSAI number matches the pattern
                if (preg_match($pattern, $request->fssai_lic_no)) {

                } else {
                    return CommonHelper::responseError("Please enter valid FSSAI no.");
                }
            }
            $product->barcode = ($request->barcode === 'null' || $request->barcode === '' || $request->barcode === null) ? null : $request->barcode;
            if($request->barcode != null && $request->barcode !== 'null' && $request->barcode !== ''){
                $pattern = '/^[a-zA-Z0-9-]+$/';
                // Check if the FSSAI number matches the pattern
                if (preg_match($pattern, $request->barcode)) {
                
                } else {
                    return CommonHelper::responseError("Please enter valid Barcode");
                }
            }
            $product->meta_title = $request->meta_title ?? "";
            $product->meta_keywords = $request->meta_keywords ?? "";
            $product->schema_markup = $request->schema_markup ?? "";
            $product->meta_description = $request->meta_description ?? "";

            if($request->hasFile('image')){
                $product->image = MediaUploadService::upload(
                    $request->file('image'),
                    'products',
                    'public',
                    $product->image
                );
            }
            if($request->hasFile('other_images')){
                CommonHelper::uploadProductImages($request->file('other_images'),$request->id);
            }
            
                   
           
        if($request->type == 'loose'){
            $looseStatuses = array_map('intval', $request->loose_status ?? []);
            $product->status = in_array(1, $looseStatuses) ? 1 : 0;
        }
            
            $product->save();

            //Variance
            if($request->type == "packet"){
                foreach ($request->packet_measurement as $index => $item){
                    $variant = ProductVariant::find($request->variant_id[$index]);
                    if(!$variant){
                        $variant = new ProductVariant();
                    }
                    $variant->product_id = $product->id;
                    $variant->type = $request->type;
                    $variant->measurement = $request->packet_measurement[$index];
                    $variant->price = $request->packet_price[$index];
                    $variant->discounted_price = isset($request->discounted_price[$index]) ? $request->discounted_price[$index] : 0;
                    $variant->status = $request->packet_status[$index];
                    $variant->stock = ($request->is_unlimited_stock == 0)?$request->packet_stock[$index]:0;
                    $variant->stock_unit_id = isset($request->packet_stock_unit_id[$index]) ? $request->packet_stock_unit_id[$index] : 0;
                    $variant->save();
                    if($request->hasFile('packet_variant_images_'.$index)){
                        CommonHelper::uploadProductImages($request->file('packet_variant_images_'.$index),$product->id, $variant->id);
                    }
                }
            }

            if($request->type == "loose"){
                foreach ($request->loose_measurement as $index => $item){
                    $variant = ProductVariant::find($request->variant_id[$index]);
                    if(!$variant){
                        $variant = new ProductVariant();
                    }
                    $variant->product_id = $product->id;
                    $variant->type = $request->type;
                    $variant->stock = ($request->is_unlimited_stock == 0) ? $request->loose_stock[$index] : 0;
                    $variant->stock_unit_id = $request->loose_stock_unit_id[$index];
                    $variant->status = $request->loose_status[$index] ?? 1;
                    $variant->measurement = $request->loose_measurement[$index];
                    $variant->price = $request->loose_price[$index];
                    $variant->discounted_price = isset($request->loose_discounted_price[$index]) ? $request->loose_discounted_price[$index] : 0;
                    $variant->save();
                    if($request->hasFile('loose_variant_images_'.$index)){
                        CommonHelper::uploadProductImages($request->file('loose_variant_images_'.$index),$product->id, $variant->id);
                    }
                }
            }
            $tagIds = array_filter(array_map('trim', explode(',', $request->tag_ids)), function($value) {
                return $value !== '';
            });
            
            $product = Product::find($product->id);
            
            if ($product) {
                $existingTagIds = [];
                $newTagNames = [];
            
                // Separate integer IDs (existing tags) from string names (new tags)
                foreach ($tagIds as $tagId) {
                    if (is_numeric($tagId)) {
                        $existingTagIds[] = (int)$tagId;
                    } else {
                        $newTagNames[] = $tagId;
                    }
                }
            
                // Create new tags and get their IDs
                $newTagIds = [];
                foreach ($newTagNames as $tagName) {
                    $newTag = Tag::firstOrCreate(['name' => $tagName]);
                    $newTagIds[] = $newTag->id;
                }
            
                // Combine existing and new tag IDs
                $allTagIds = array_merge($existingTagIds, $newTagIds);
            
                // Sync the tags with the product
                $product->tags()->sync($allTagIds);
            }
            DB::commit();

            // Send notification to seller if product has seller_id
            if (!empty($product->seller_id)) {
                try {
                    $notificationResult = SellerNotificationService::send(
                        $product->seller_id,
                        'Product Updated',
                        "Your product '{$product->name}' has been updated successfully.",
                        $product->image ? url('/storage') . "/" . $product->image : '',
                        'product',
                        $product->id,
                        [
                            'product_name' => $product->name,
                            'product_slug' => $product->slug,
                            'updated_at' => now()->toDateTimeString()
                        ]
                    );

                    Log::info("Product update notification sent to seller", [
                        'product_id' => $product->id,
                        'seller_id' => $product->seller_id,
                        'notification_result' => $notificationResult
                    ]);
                } catch (\Exception $e) {
                    // Don't fail the whole request if notification fails
                    Log::error("Failed to send product update notification to seller", [
                        'product_id' => $product->id,
                        'seller_id' => $product->seller_id,
                        'error' => $e->getMessage()
                    ]);
                }
            }

        } catch (\Exception $e) {
            DB::rollBack();
            Log::info("Error : ".$e->getMessage());
            throw $e;
            return CommonHelper::responseError("Something Went Wrong!");
        }
        // return CommonHelper::responseSuccess("Product Updated Successfully!");
        return response()->json([
            "status" => 1,
            "message" => "Product Updated Successfully!",
            "store_id" => $product->store_id
        ]);

    }

    public function delete(Request $request)
    {
        if (isset($request->id)) {
            $productVariant = ProductVariant::find($request->id);
    
            if ($productVariant) {
                // Check if the product variant exists in order_items
                $orderItemExists = OrderItem::where('product_variant_id', $productVariant->id)->exists();
    
                if ($orderItemExists) {
                    return CommonHelper::responseError("This product variant cannot be deleted as it exists in orders.");
                }
    
                $product_id = $productVariant->product_id;
    
                $variantDeleteStatus = $productVariant->delete();
                $variants = ProductVariant::where('product_id', $product_id)->get();
    
                if ($variantDeleteStatus == true && $variants->count() == 0) {
                    $product = Product::find($product_id);
                    if ($product) {
                        $product->delete();
                    }
                }
    
                return CommonHelper::responseSuccess("Product Deleted Successfully!");
            } else {
                return CommonHelper::responseError("Product Already Deleted!");
            }
        }
    
        return CommonHelper::responseError("Invalid request!");
    }
    

    public function multipleDelete(Request $request){
        if(isset($request->ids)){
            $ids = explode(',' , $request->ids);
            $productVariants = ProductVariant::with('images')->whereIn('id',$ids)->get();
            foreach($productVariants as $productVariant) {
                $product_id = $productVariant->product_id;
                foreach ($productVariant->images as $image){
                    MediaUploadService::deleteByUrl($image->image);
                    $image->delete();
                }
                $productVariant->delete();

                //If All variant deleted remove main product
                $product = Product::with('variants','images')->where('id',$product_id)->first();
                if($product && is_countable($product->variants) && count($product->variants)==0){
                    foreach ($productVariant->images as $image){
                        MediaUploadService::deleteByUrl($image->image);
                        $image->delete();
                    }
                    MediaUploadService::deleteByUrl($product->image);
                    $product->delete();
                }
            }
            return CommonHelper::responseSuccess("Selected all Product Deleted Successfully!");
        }
    }

    public function changeStatus(Request $request){
        if(isset($request->id)){
            $product = Product::find($request->id);
            if($product){
                $product->status = ($product->status == 1)?0:1;
                $product->save();
                return CommonHelper::responseSuccess("Products Status Updated Successfully!");
            }else{
                return CommonHelper::responseSuccess("Products Record not found!");
            }

        }
    }

    public function changeApproveStatus(Request $request){
        if(isset($request->id)){
            $product = Product::find($request->id);
            if($product){
                $product->is_approved = ($product->is_approved == 1) ? 0 : 1;
                $product->save();
                return CommonHelper::responseSuccess("Product Approval Status Updated Successfully!");
            }else{
                return CommonHelper::responseSuccess("Products Record not found!");
            }
        }
    }

    public function getProductsOrderList(Request $request){

        $validator = Validator::make($request->all(), [
            'category_id' => 'required',
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $products = Product::where('category_id',$request->category_id)->orderBy('row_order','ASC')->get();
        return CommonHelper::responseWithData($products);
    }
    public function updateProductsOrder(Request $request){
        $products = $request->all();
        foreach ($products as $key => $product){
            $data = Product::find($product["id"]);
            $data->row_order = $product["row_order"];
            $data->save();
        }
        return CommonHelper::responseSuccess("Product Order Updated Successfully!");
    }

    public function bulkUpload(Request $request){
        try {
            DB::beginTransaction();
            $validator = Validator::make($request->all(),[
                'file' => 'required'
            ]);
            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $filename = $_FILES["file"]["tmp_name"];
            $allowed_status = array("received", "processed", "shipped");
            if ($_FILES["file"]["size"] > 0 ) {
                $errors = [];
                $file = fopen($filename, "r");
                $count = 0;
                while (($products = fgetcsv($file, 10000, ",")) !== FALSE) {
                    if($count!=0) {
                        $rowErrors = [];
                        if (empty($products[0])) {
                            $rowErrors[] = 'Product Name is empty';
                        }
                        if (empty($products[1])) {
                            $rowErrors[] = 'Category ID is empty or invalid';
                        }
                        if (empty($products[11])) {
                            $rowErrors[] = 'Seller ID is empty or invalid';
                        }
                        if (!empty($products[11])) {
                            $seller = Seller::select('name','categories','require_products_approval')->where('id',$products[11])->first();
                            if (empty($seller)) {
                                $rowErrors[] = 'Seller does not exist (check seller_id)';
                            } else {
                                if (!empty($products[1]) && strpos((string)$seller->categories, (string)$products[1]) === false) {
                                    $rowErrors[] = 'Category ID is not assigned to seller';
                                }
                            }
                        }
                        if ($products[6] !== '' && $products[6] !== null && !in_array((int)$products[6], [0,1], true)) {
                            $rowErrors[] = 'Is Returnable must be 0 or 1';
                        }
                        if ($products[7] !== '' && $products[7] !== null && !in_array((int)$products[7], [0,1], true)) {
                            $rowErrors[] = 'Is cancel-able must be 0 or 1';
                        }
                        if (!empty($products[7]) && (int)$products[7] === 1 && (empty($products[8]) || !in_array(strtolower($products[8]), $allowed_status))) {
                            $rowErrors[] = 'Till status is empty or invalid (received|processed|shipped)';
                        }
                        if (empty($products[7]) && !empty($products[8])) {
                            $rowErrors[] = 'Till status provided but Is cancel-able is empty';
                        }
                        if (empty($products[9])) {
                            $rowErrors[] = 'Description is empty';
                        }
                        if (empty($products[10])) {
                            $rowErrors[] = 'Image is empty';
                        }
                        else {
                            $imgPathOriginal = trim($products[10]);
                            // Normalize the same way as used while inserting
                            $imgPathNormalized = str_replace(' ', '-', strtolower($imgPathOriginal));
                            // If absolute URL, skip existence check
                            $isUrl = preg_match('/^https?:\/\//i', $imgPathNormalized);
                            if (!$isUrl) {
                                $existsOnDisk = Storage::disk('public')->exists($imgPathNormalized);
                                $existsInPublic = file_exists(public_path('storage/' . ltrim($imgPathNormalized, '/')));
                                if (!$existsOnDisk && !$existsInPublic) {
                                    $rowErrors[] = 'Image file not found: ' . $imgPathOriginal;
                                }
                            }
                        }
                        if (!empty($products[16])) {
                            $tax = Tax::where('id',$products[16])->first();
                            if (empty($tax)) {
                                $rowErrors[] = 'Tax ID is invalid';
                            }
                        }

                        // Count variants starting from column 19 (0-based index)
                        $index1 = 19;
                        $total_variants = 0;
                        for ($j = 0; $j < 50; $j++) {
                            if (isset($products[$index1]) && $products[$index1] !== '') {
                                $total_variants++;
                            }
                            $index1 = $index1 + 8;
                        }
                        if ($total_variants == 0) {
                            $rowErrors[] = 'At least one variant required';
                        }

                        $ids = Unit::select('id')->orderBy('id','ASC')->get();
                        $validUnitIds = $ids->pluck('id')->all();
                        $index1 = 19;
                        for ($z = 0; $z < $total_variants; $z++) {
                            // type
                            if (empty($products[$index1]) || ($products[$index1] != 'packet' && $products[$index1] != 'loose')) {
                                $rowErrors[] = 'Variant '.($z+1).': Type is empty or invalid';
                            }
                            $index1 = $index1 + 1;
                            // measurement
                            if (!isset($products[$index1]) || $products[$index1] === '' || !is_numeric($products[$index1])) {
                                $rowErrors[] = 'Variant '.($z+1).': Measurement is empty or invalid';
                            }
                            $index1 = $index1 + 1;
                            // measurement unit id
                            if (!isset($products[$index1]) || $products[$index1] === '' || !in_array((int)$products[$index1], $validUnitIds, true)) {
                                $rowErrors[] = 'Variant '.($z+1).': Measurement Unit ID is empty or invalid';
                            }
                            $index1 = $index1 + 1;
                            // price
                            if (!isset($products[$index1]) || $products[$index1] === '' || !is_numeric($products[$index1])) {
                                $rowErrors[] = 'Variant '.($z+1).': Price is empty or invalid';
                            }
                            $index1 = $index1 + 1;
                            // discounted price
                            if (!isset($products[$index1]) || $products[$index1] === '' || !is_numeric($products[$index1])) {
                                $rowErrors[] = 'Variant '.($z+1).': Discounted Price is empty or invalid';
                            }
                            $index1 = $index1 + 1;
                            // serve_for / status: expecting 'Available' or 'Sold Out'
                            if (!isset($products[$index1]) || ($products[$index1] != 0 && $products[$index1] != 1)) {
                                $rowErrors[] = 'Variant '.($z+1).': Serve For is empty or invalid (Available|Sold Out)';
                            }
                            $index1 = $index1 + 1;
                            // stock
                            if (!isset($products[$index1]) || $products[$index1] === '' || !is_numeric($products[$index1])) {
                                $rowErrors[] = 'Variant '.($z+1).': Stock is empty or invalid';
                            }
                            $index1 = $index1 + 1;
                            // stock unit id
                            if (!isset($products[$index1]) || $products[$index1] === '' || !in_array((int)$products[$index1], $validUnitIds, true)) {
                                $rowErrors[] = 'Variant '.($z+1).': Stock Unit ID is empty or invalid';
                            }
                            $index1 = $index1 + 1;
                        }

                        if (!empty($rowErrors)) {
                            $errors[] = [
                                'row' => $count,
                                'errors' => $rowErrors
                            ];
                        }
                    }
                    $count++;
                }
                fclose($file);

                // If any validation errors, return them all at once
                if (!empty($errors)) {
                    return CommonHelper::responseErrorWithData('Validation failed for some rows.', $errors);
                }

                // Proceed with insert when no errors
                $file = fopen($filename, "r");
                $count1 = 0;
                while (($emapData = fgetcsv($file, 10000, ",")) !== FALSE) {
                    if ($count1 != 0) {
                        $seller = Seller::select('name','categories','require_products_approval')->where('id',$emapData[11])->first();
                        $is_approved_by_seller = isset($seller->require_products_approval) && $seller->require_products_approval == 0 ? 1 : 0;

                        $product_name = $emapData[0];
                        $category_id = $emapData[1];
                        $indicator = $emapData[3];
                        $manufacturer = $emapData[4];
                        $made_in = $emapData[5];
                        $return_status = !empty($emapData[6]) ? $emapData[6] : 0;
                        $cancel_status = !empty($emapData[7]) ? $emapData[7] : 0;
                        $till_status = $emapData[8];
                        $description = $emapData[9];
                        $image = str_replace(' ', '-', strtolower($emapData[10]));
                        $seller_id = $emapData[11];
                        $is_approved = (!empty($emapData[12]) && $emapData[12] != "") ? $emapData[12] : $is_approved_by_seller;
                        $brand_id = (!empty($emapData[14]) && $emapData[14] != "") ? $emapData[14] : 0;
                        $return_days = (!empty($emapData[15]) && $emapData[15] != "") ? $emapData[15] : "0";
                        $tax_id = (!empty($emapData[16]) && $emapData[16] != "") ? $emapData[16] : "0";
                        $fssai_lic_no = (!empty($emapData[17]) && $emapData[17] != "") ? $emapData[17] : "";
                        $barcode = (!empty($emapData[18]) && $emapData[18] != "") ? $emapData[18] : "";
                        $type = (!empty($emapData[19]) && $emapData[19] != "") ? $emapData[19] : "";

                        $row_order = Product::max('row_order') + 1;

                        $product = new Product();
                        $product->name = $product_name;
                        $product->row_order = $row_order;
                        $slug = preg_replace(
                            '/\s+/', '-', trim(
                                preg_replace('/[^\p{L}\p{N} ]/u', '', $emapData[0])
                            )
                        );                        
                        $count = Product::where('slug', 'LIKE', "{$slug}%")->count();
                        $product->slug = $count ? "{$slug}-{$count}" : $slug;
                        $product->tags = $emapData[0];
                        $product->status = 1;
                        $product->cod_allowed = 1;
                        $product->total_allowed_quantity = 3;
                        $product->category_id = $category_id;
                        $product->indicator = $indicator;
                        $product->manufacturer = $manufacturer;
                        $product->made_in = $made_in;
                        $product->return_status = $return_status;
                        $product->cancelable_status = $cancel_status;
                        $product->till_status = $till_status;
                        $product->description = $description;
                        $product->image = $image;
                        $product->seller_id = $seller_id;
                        $product->is_approved = $is_approved;
                        $product->brand_id = $brand_id;
                        $product->return_days = $return_days;
                        $product->tax_id = $tax_id;
                        $product->fssai_lic_no = $fssai_lic_no;
                        $product->barcode = $barcode;
                        $product->type = $type;
                        $product->save();

                        // Calculate total variants
                        $index1 = 19;
                        $total_variants = 0;
                        for ($j = 0; $j < 50; $j++) {
                            if (!empty($emapData[$index1])) {
                                $total_variants++;
                            }
                            $index1 = $index1 + 8;
                        }

                        // Insert variants
                        $index = 19;
                        for ($i = 0; $i < $total_variants; $i++) {
                            $variant = new ProductVariant();
                            $variant->product_id = $product->id;
                            $variant->type = $emapData[$index];
                            $index++;
                            $variant->measurement = $emapData[$index];
                            $index++;
                            $index++; // skip measurement unit id column in CSV
                            $variant->price = $emapData[$index];
                            $index++;
                            $variant->discounted_price = $emapData[$index];
                            $index++;
                            $variant->status = $emapData[$index];
                            $index++;
                            $variant->stock = $emapData[$index];
                            $index++;
                            $variant->stock_unit_id = $emapData[$index];
                            $index++;

                            $variant->save();
                        }
                    }
                    $count1++;
                }
                fclose($file);
                // commit transaction
                DB::commit();
                return CommonHelper::responseSuccess("All Products Imported Successfully!");
            }
        } catch(\Exception $e){
            DB::rollBack();
            return CommonHelper::responseError($e->getMessage());
        }
    }
    public function getProduct(Request $request){
        $validator = Validator::make($request->all(),[ 
            'product_id' => 'required',
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        $product_id=$request->product_id;
        $product = Product::with('seller','images','variants.images', 'variants.unit','category', 'tax','madeInCountry','brand','tags')->where('id',$product_id)->first();
        if(!$product){
            return CommonHelper::responseError("Product Not found!");
        }
        return CommonHelper::responseWithData($product);
    }

    public function downloadProductDataExcel(Request $request){
        $products = Product::with('variants')->get();
        if(auth()->user()->role_id == Role::$roleSeller ){
            $products = Product::with('variants')->where('seller_id', auth()->user()->seller->id)->get();
        }
        $csvData = [];

        // Base header fields
        $header =  ['ID','Product Name','Category ID','Indicator', 'Manufacturer', 'Made in','Is Returnable?','Is cancel-able','Till which status','Description','image','Seller_id','Is_approved?','Brand_id','return_days','tax_id','Fssai No','Barcode'];

        // Determine the maximum number of variants across all products
        $maxVariants = $products->map(function($product) {
            return $product->variants->count();
        })->max();

        // Generate dynamic headers for variants
        for ($i = 1; $i <= $maxVariants; $i++) {
            $header[] = "Product Variant ID $i";
            $header[] = "Type $i";
            $header[] = "Measurement $i";
            $header[] = "Price $i";
            $header[] = "Discounted Price $i";
            $header[] = "Stock $i";
            $header[] = "Stock Unit ID $i";
        }

        // Add the header to CSV data
        $csvData[] = $header;

        // Generate rows for each product
        foreach ($products as $product) {
            $description = str_replace(["\r", "\n"], ' ', $product->description);
            $row = [
                $product->id,
                $product->name,
                $product->category_id,
                $product->indicator,
                $product->manufacturer,
                $product->made_in,
                $product->return_status,
                $product->cancelable_status,
                $product->till_status,
                $description,
                $product->image,
                $product->seller_id,
                $product->is_approved,
                $product->brand_id,
                $product->return_days,
                $product->tax_id,
                $product->fssai_lic_no,
                $product->barcode,
            ];

            // Add variant data to the row
            foreach ($product->variants as $variant) {
                $row[] = $variant->id;
                $row[] = $variant->type;
                $row[] = $variant->measurement;
                $row[] = $variant->price;
                $row[] = $variant->discounted_price;
                $row[] = $variant->stock;
                $row[] = $variant->stock_unit_id;
            }

           // Fill in the remaining columns for products with fewer variants than maxVariants
            $remainingColumns = $maxVariants - $product->variants->count();
            for ($i = 0; $i < $remainingColumns; $i++) {
                $row[] = '';
                $row[] = '';
                $row[] = '';
                $row[] = '';
                $row[] = '';
                $row[] = '';
                $row[] = '';
            }

            // Add the row to CSV data
            $csvData[] = $row;
        }

        // Set headers to prompt file download
        $filename = "products.csv";
        $headers = [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => "attachment; filename=\"$filename\"",
        ];

        // Create a callback to write the CSV data
        $callback = function() use ($csvData) {
            $output = fopen('php://output', 'w');
            foreach ($csvData as $row) {
                fputcsv($output, $row);
            }
            fclose($output);
        };

        // Return the response as a stream
        return response()->stream($callback, 200, $headers);
    }
    public function bulkUpdate(Request $request) {
        $request->validate([
            'file' => 'required|file|mimes:csv,txt'
        ]);
    
        $path = $request->file('file')->getRealPath();
        $data = array_map('str_getcsv', file($path));
    
        // Get headers from the first row
        $headers = array_shift($data);
    
        // Begin a transaction
        DB::beginTransaction();
    
        try {
            foreach ($data as $row) {
                if (count($headers) !== count($row)) {
                    // If they don't match, skip this row or handle the error accordingly
                    continue;
                }
                $rowData = array_combine($headers, $row);
    
                // Update product data
                $product = Product::updateOrCreate(
                    ['id' => $rowData['ID']],
                    [
                        'name' => $rowData['Product Name'],
                        'category_id' => $rowData['Category ID'],
                        'indicator' => !empty($rowData['Indicator']) ? $rowData['Indicator'] : 0, // Set to 0 if empty
                        'manufacturer' => $rowData['Manufacturer'],
                        'made_in' => $rowData['Made in'],
                        'return_status' => $rowData['Is Returnable?'],
                        'cancelable_status' => $rowData['Is cancel-able'],
                        'till_status' => $rowData['Till which status'],
                        'description' => $rowData['Description'],
                        'image' => $rowData['image'],
                        'seller_id' => $rowData['Seller_id'],
                        'is_approved' => $rowData['Is_approved?'] ?? 0,
                        'brand_id' => $rowData['Brand_id'],
                        'return_days' => $rowData['return_days'],
                        'tax_id' => $rowData['tax_id'],
                        'fssai_lic_no' => $rowData['Fssai No'],
                        'barcode' => $rowData['Barcode'],
                    ]
                );
     
                // Update product variants
                $variantsData = [];
                $variantIndex = 1;

                while (isset($rowData["Product Variant ID {$variantIndex}"])) {
                    // Fetch the variant data from $rowData and assign default values if necessary
                    $id = isset($rowData["Product Variant ID {$variantIndex}"]) ? (int)$rowData["Product Variant ID {$variantIndex}"] : null;
                    $type = isset($rowData["Type {$variantIndex}"]) ? $rowData["Type {$variantIndex}"] : '';
                    $measurement = isset($rowData["Measurement {$variantIndex}"]) ? $rowData["Measurement {$variantIndex}"] : '';
                    $price = isset($rowData["Price {$variantIndex}"]) ? (float)$rowData["Price {$variantIndex}"] : 0;
                    $discounted_price = isset($rowData["Discounted Price {$variantIndex}"]) ? (float)$rowData["Discounted Price {$variantIndex}"] : 0;
                    $stock = isset($rowData["Stock {$variantIndex}"]) ? (int)$rowData["Stock {$variantIndex}"] : 0;
                    $stock_unit_id = isset($rowData["Stock Unit ID {$variantIndex}"]) ? (int)$rowData["Stock Unit ID {$variantIndex}"] : 1; // Assuming 1 is a valid default unit ID

                    // Skip if ID is null or invalid
                    if ($id === null || $id <= 0) {
                        $variantIndex++;
                        continue;
                    }

                    // Add the validated data to the variantsData array
                    $variantsData[] = [
                        'id' => $id,
                        'product_id' => $product->id,
                        'type' => $type,
                        'measurement' => $measurement,
                        'price' => $price,
                        'discounted_price' => $discounted_price,
                        'stock' => $stock,
                        'stock_unit_id' => $stock_unit_id,
                    ];

                    $variantIndex++;
                }

                foreach ($variantsData as $variantData) {
                    ProductVariant::updateOrCreate(
                        ['id' => $variantData['id']],
                        $variantData
                    );
                }
            }
    
            DB::commit();
            return CommonHelper::responseSuccess("Products and variants updated successfully!");
        } catch (\Exception $e) {
            // Rollback transaction on error
            DB::rollBack();
    
            return CommonHelper::responseError("Products and variants not updated! Error: " . $e->getMessage());
        }
    }
    public function getProductVariants(Request $request)
    {
        // Set default values for pagination
        $limit = $request->input('per_page', 10); // Default to 10 items per page if not provided
        $page = $request->input('page', 1); // Default to the first page if not provided
        $offset = ($page - 1) * $limit; // Calculate offset

        if($request->has('limit')){
            $limit = $request->limit;
            $offset = $request->offset;
        }

        // Step 1: Query the database and retrieve the raw data
        $rawProducts = \DB::table('products as p')
            ->select(
                'p.id as id',
                'p.id as product_id', 
                'p.name', 
                'p.seller_id', 
                'p.status', 
                'p.tax_id', 
                'p.image', 
                's.name as seller_name',
                's.id as seller_id',
                'p.indicator', 
                'p.manufacturer', 
                'p.made_in',  
                'pv.id as product_variant_id', 
                'pv.type',
                'pv.price', 
                'pv.discounted_price', 
                'pv.measurement', 
                'pv.status as pv_status', 
                'pv.stock', 
                'pv.stock_unit_id', 
                'u.short_code', 
                \DB::raw('(select short_code from units where units.id = pv.stock_unit_id) as stock_unit')
            )
            ->join('sellers as s', 'p.seller_id', '=', 's.id')
            ->join('product_variants as pv', 'p.id', '=', 'pv.product_id')
            ->join('units as u', 'pv.stock_unit_id', '=', 'u.id')
            ->where('p.is_unlimited_stock', 0);

            if ($request->filled('store_id')) {
                $rawProducts = $rawProducts->where('p.store_id', $request->store_id);
            }

            if ($request->filled('category_group_id')) {
                $rawProducts = $rawProducts->where('p.category_group_id', $request->category_group_id);
            }

            if ($request->filled('sub_category_group_id')) {
                $rawProducts = $rawProducts->where('p.sub_category_group_id', $request->sub_category_group_id);
            }

            if ($request->filled('category_id')) {
                $rawProducts = $rawProducts->where('p.category_id', $request->category_id);
            }


        if ($request->has('search')) {
            $search = $request->input('search');
            $rawProducts = $rawProducts->where(function($query) use ($search) {
                $query->where('p.name', 'LIKE', "%$search%") ->$query->where('p.description', 'LIKE', "%$search%") ->orWhere('s.name', 'LIKE', "%$search%")->orWhere('pv.id', 'LIKE', "%$search%")->orWhere('pv.stock', 'LIKE', "%$search%");
            });
        }

        if (auth()->user()->role_id == Role::$roleSeller) {
            $rawProducts = $rawProducts->where('p.seller_id', auth()->user()->seller->id);
        }

        $rawProducts = $rawProducts->orderBy('id', 'DESC')
            ->get()
            ->toArray();

        // Step 2: Group the products and handle loose variants
        $groupedProducts = [];
        foreach ($rawProducts as $product) {
            // Manually append the image_url using the product model accessor
            $productModel = Product::find($product->product_id); // Fetch the product model
            $product->image_url = $productModel->image_url;

            if ($product->type == 'loose') {
                // Group loose type products into a single entry
                if (isset($groupedProducts[$product->product_id])) {
                    // Concatenate fields for loose products
                    $groupedProducts[$product->product_id]['measurement'] .= ', ' . $product->measurement . ' ' . $product->stock_unit;
                    $groupedProducts[$product->product_id]['price'] .= ',' . $product->price;
                    $groupedProducts[$product->product_id]['discounted_price'] .= ',' . $product->discounted_price;
                    $groupedProducts[$product->product_id]['stock_unit_id'] .= ',' . $product->stock_unit_id;
                } else {
                    // Initialize the first loose variant entry
                    $groupedProducts[$product->product_id] = [
                        'id' => $product->id,
                        'product_id' => $product->product_id,
                        'name' => $product->name,
                        'seller_id' => $product->seller_id,
                        'seller_name' => $product->seller_name,
                        'status' => $product->status,
                        'tax_id' => $product->tax_id,
                        'image' => $product->image,
                        'image_url' => $product->image_url,
                        'indicator' => $product->indicator,
                        'manufacturer' => $product->manufacturer,
                        'made_in' => $product->made_in,
                        'product_variant_id' => $product->product_variant_id,
                        'type' => $product->type,
                        'price' => $product->price,
                        'discounted_price' => $product->discounted_price,
                        'measurement' => $product->measurement . ' ' . $product->stock_unit, // Proper format
                        'pv_status' => $product->pv_status,
                        'stock' => $product->stock,
                        'stock_unit_id' => $product->stock_unit_id,
                        'short_code' => $product->short_code,
                        'stock_unit' => $product->stock_unit
                    ];
                }
            }
            else {
                // For non-loose variants, add them as they are
                $groupedProducts[$product->product_variant_id] = [
                    'id' => $product->id,
                    'product_id' => $product->product_id,
                    'name' => $product->name,
                    'seller_id' => $product->seller_id,
                    'seller_name' => $product->seller_name,
                    'status' => $product->status,
                    'tax_id' => $product->tax_id,
                    'image' => $product->image,
                    'image_url' => $product->image_url, // Add image_url here
                    'indicator' => $product->indicator,
                    'manufacturer' => $product->manufacturer,
                    'made_in' => $product->made_in,
                    'product_variant_id' => $product->product_variant_id,
                    'type' => $product->type, 
                    'price' => $product->price,
                    'discounted_price' => $product->discounted_price,
                    'measurement' => $product->measurement .' '.$product->stock_unit ,
                    'pv_status' => $product->pv_status,
                    'stock' => $product->stock,
                    'stock_unit_id' => $product->stock_unit_id,
                    'short_code' => $product->short_code,
                    'stock_unit' => $product->stock_unit
                ];
            }
        }

        // Step 3: Apply limit and offset after grouping
        $groupedProducts = array_values($groupedProducts); // Ensure it's indexed
        $totalCount = count($groupedProducts); // Get the total count

        // Apply pagination (limit and offset)
        $groupedProducts = array_slice($groupedProducts, $offset, $limit);

        return CommonHelper::responseWithData($groupedProducts, $totalCount);
    }

    public function getProductsBySeller(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'seller_id' => 'required|integer|exists:sellers,id',
                'per_page' => 'nullable|integer|min:1|max:100',
                'page' => 'nullable|integer|min:1',
                'search' => 'nullable|string|max:255',
                'category_id' => 'nullable|integer',
            ], [
                'seller_id.required' => 'The seller ID is required.',
                'seller_id.integer' => 'The seller ID must be a valid integer.',
                'seller_id.exists' => 'The selected seller does not exist.',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $sellerId = $request->seller_id;
            $perPage = $request->input('per_page', 10);
            $page = $request->input('page', 1);
            $offset = ($page - 1) * $perPage;
            $search = $request->input('search', '');

            // Get seller info with store details
            $seller = Seller::select('id', 'name', 'store_name', 'status', 'store_id')
                ->where('id', $sellerId)
                ->first();

            // Check if seller's store is managed by admin
            $store = Store::find($seller->store_id);
            $isManagedByAdmin = $store && $store->managed_by_admin == 1;

            $query = DB::table('products as p')
                ->select(
                    'p.id as id',
                    'p.id as product_id',
                    'p.name',
                    'p.slug',
                    'p.seller_id',
                    'p.store_id',
                    'p.status',
                    'p.tax_id',
                    'p.image',
                    'p.category_id',
                    'p.indicator',
                    'p.is_approved',
                    'p.manufacturer',
                    'p.made_in',
                    'p.type',
                    'p.description',
                    'p.created_at',
                    's.name as seller_name',
                    'c.name as category_name',
                    'pv.id as product_variant_id',
                    'pv.price',
                    'pv.discounted_price',
                    'pv.measurement',
                    'pv.status as variant_status',
                    'pv.stock',
                    'pv.stock_unit_id',
                    DB::raw('(SELECT short_code FROM units WHERE units.id = pv.stock_unit_id) as stock_unit')
                )
                ->leftJoin('sellers as s', 'p.seller_id', '=', 's.id')
                ->join('product_variants as pv', 'p.id', '=', 'pv.product_id')
                ->leftJoin('categories as c', 'p.category_id', '=', 'c.id');

            // Filter by store_id if managed by admin, otherwise filter by seller_id
            if ($isManagedByAdmin) {
                $query->where('p.store_id', $seller->store_id);
            } else {
                $query->where('p.seller_id', $sellerId);
            }

            // Apply category filter
            if ($request->filled('category_id')) {
                $query->where('p.category_id', $request->category_id);
            }

            // Apply search filter
            if (!empty($search)) {
                $query->where(function ($q) use ($search) {
                    $q->where('p.name', 'LIKE', "%{$search}%")
                      ->orWhere('p.slug', 'LIKE', "%{$search}%")
                      ->orWhere('p.description', 'LIKE', "%{$search}%")
                      ->orWhere('c.name', 'LIKE', "%{$search}%")
                      ->orWhere('pv.id', 'LIKE', "%{$search}%");
                });
            }

            // Get total count before pagination
            $total = $query->count();

            // Apply pagination and ordering
            $products = $query->orderBy('p.id', 'DESC')
                ->offset($offset)
                ->limit($perPage)
                ->get();

            // Get distinct categories for this seller's products
            $categoriesQuery = DB::table('products as p')
                ->join('categories as c', 'p.category_id', '=', 'c.id');
            if ($isManagedByAdmin) {
                $categoriesQuery->where('p.store_id', $seller->store_id);
            } else {
                $categoriesQuery->where('p.seller_id', $sellerId);
            }
            $categories = $categoriesQuery
                ->select('c.id', 'c.name')
                ->distinct()
                ->orderBy('c.name')
                ->get();

            $data = [
                'seller' => $seller,
                'products' => $products,
                'categories' => $categories,
                'is_managed_by_admin' => $isManagedByAdmin,
            ];

            return CommonHelper::responseWithData($data, $total);

        } catch (\Exception $e) {
            Log::error("getProductsBySeller Error: " . $e->getMessage());
            return CommonHelper::responseError("Something went wrong while fetching products.");
        }
    }

    public function updateVariantStock(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|integer|exists:product_variants,id',
            'stock' => 'required|integer|min:0|max:100000',
        ],[
            'id.required' => 'The product variant ID is required.',
            'id.integer' => 'The product variant ID must be a valid integer.',
            'id.exists' => 'The selected product variant does not exist.',
            
            'stock.required' => 'The stock quantity must be a valid integer.',
            'stock.integer' => 'The stock quantity must be a valid integer.',
            'stock.min' => 'The stock quantity cannot be less than 0.'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

            $variant = ProductVariant::findOrFail($request->id);
            if ($variant->type == 'packet') {
        
                $variant->stock = $request->stock;
                $variant->save();

                if ($variant->stock <= 0) {
                    $variant->status = 0; // here status 0 => "Sold Out" & 1 => "Available"
                    $variant->save();
                }else{
                    $variant->status = 1; // here status 0 => "Sold Out" & 1 => "Available"
                    $variant->save();
                }
            }
            else if ($variant->type == 'loose') {
                // Update stock value
                $product_id = $variant->product_id;
                $product = Product::find($product_id); // Use find() for a single record
            
                // Check if product is found
                if ($product) {
                    // Update product status based on request stock
                    $product->status = $request->stock <= 0 ? 0 : 1; // 0 => "Sold Out", 1 => "Available"
                    $product->save(); // Save the product status
            
                    // Fetch all loose variants for the product
                    $loose_variants = ProductVariant::where('product_id', $product_id)->get();
            
                    foreach ($loose_variants as $loose_variant) {
                        // Update stock for each loose variant
                        $loose_variant->stock = $request->stock;
                        $loose_variant->status = $request->stock <= 0 ? 0 : 1; // Set status based on stock
                        $loose_variant->save(); // Save each loose variant
                    }
                }
            }
    
            return CommonHelper::responseSuccess('Stock updated successfully');

    }

    /**
     * Get product ratings list from order_product_ratings table
     */
    public function productRatingsList(Request $request)
    {
        $storeId  = $request->input('store_id');
        $sellerId = $request->input('seller_id');
        $cityId   = $request->input('city_id');
        $page     = (int) $request->input('page', 1);
        $perPage  = (int) $request->input('per_page', 10);

        // ---------------------------------------------------------------
        // Zone filter — resolve seller IDs in the requested city boundary
        // ---------------------------------------------------------------
        $sellerIdsInZone = null;

        if ($cityId) {
            $allSellers = \App\Models\Seller::where('status', 1)
                ->select('id', 'lat_long')
                ->get();

            if ($cityId === 'other') {
                $allCities       = \App\Models\City::all();
                $sellerIdsInZone = $allSellers->filter(function ($seller) use ($allCities) {
                    return !$this->isInAnyCity($seller, $allCities);
                })->pluck('id')->toArray();
            } else {
                $city = \App\Models\City::find($cityId);
                if ($city) {
                    $sellerIdsInZone = $allSellers->filter(function ($seller) use ($city) {
                        return $this->isSellerInCity($seller, $city);
                    })->pluck('id')->toArray();
                }
            }
        }

        $query = DB::table('order_product_ratings')
            ->leftJoin('products', 'order_product_ratings.product_id', '=', 'products.id')
            ->leftJoin('sellers', 'order_product_ratings.seller_id', '=', 'sellers.id')
            ->leftJoin('stores', 'sellers.store_id', '=', 'stores.id')
            ->select(
                'order_product_ratings.product_id',
                'products.name as product_name',
                'products.image as product_image',
                DB::raw('ROUND(AVG(order_product_ratings.rating), 1) as avg_rating'),
                DB::raw('COUNT(order_product_ratings.id) as total_ratings'),
                DB::raw('SUM(CASE WHEN order_product_ratings.rating = 5 THEN 1 ELSE 0 END) as five_star'),
                DB::raw('SUM(CASE WHEN order_product_ratings.rating = 4 THEN 1 ELSE 0 END) as four_star'),
                DB::raw('SUM(CASE WHEN order_product_ratings.rating = 3 THEN 1 ELSE 0 END) as three_star'),
                DB::raw('SUM(CASE WHEN order_product_ratings.rating = 2 THEN 1 ELSE 0 END) as two_star'),
                DB::raw('SUM(CASE WHEN order_product_ratings.rating = 1 THEN 1 ELSE 0 END) as one_star'),
                'sellers.name as seller_name',
                'stores.name as store_name'
            )
            ->groupBy(
                'order_product_ratings.product_id',
                'products.name',
                'products.image',
                'sellers.name',
                'stores.name'
            )
            ->orderByDesc('avg_rating');

        if ($sellerIdsInZone !== null) {
            $query->whereIn('order_product_ratings.seller_id', $sellerIdsInZone);
        }

        if ($storeId) {
            $query->where('order_product_ratings.store_id', $storeId);
        }

        if ($sellerId) {
            $query->where('order_product_ratings.seller_id', $sellerId);
        }

        $total = DB::table(DB::raw("({$query->toSql()}) as sub"))
            ->mergeBindings($query)
            ->count();

        $ratings = $query
            ->offset(($page - 1) * $perPage)
            ->limit($perPage)
            ->get();

        return response()->json([
            'status' => 1,
            'data' => [
                'ratings' => $ratings,
                'pagination' => [
                    'current_page' => $page,
                    'per_page' => $perPage,
                    'total' => $total,
                    'last_page' => (int) ceil($total / $perPage),
                ]
            ]
        ]);
    }

    // -----------------------------------------------------------------------
    // Geo helpers (same logic as FoodProductsController / SellerApiController)
    // -----------------------------------------------------------------------

    private function isSellerInCity($seller, $city): bool
    {
        if (empty($seller->lat_long)) return false;

        $parts = explode(',', $seller->lat_long);
        if (count($parts) < 2) return false;

        $lat = floatval(trim($parts[0]));
        $lng = floatval(trim($parts[1]));

        if ($city->geolocation_type === 'polygon') {
            $polygon = is_string($city->boundary_points)
                ? json_decode($city->boundary_points, true)
                : $city->boundary_points;

            if (empty($polygon) || !is_array($polygon)) return false;

            return $this->isPointInPolygon($lat, $lng, $polygon);

        } elseif ($city->geolocation_type === 'radius') {
            $distance = $this->haversineDistance(
                $lat, $lng,
                floatval($city->latitude),
                floatval($city->longitude)
            );
            return $distance <= floatval($city->radius);
        }

        return false;
    }

    private function isInAnyCity($seller, $allCities): bool
    {
        if (empty($seller->lat_long)) return false;

        foreach ($allCities as $city) {
            if ($this->isSellerInCity($seller, $city)) return true;
        }

        return false;
    }

    private function haversineDistance(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $R    = 6371;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a    = sin($dLat / 2) ** 2
              + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;
        return $R * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }

    private function isPointInPolygon(float $lat, float $lng, array $polygon): bool
    {
        $count  = count($polygon);
        $inside = false;
        $j      = $count - 1;

        for ($i = 0; $i < $count; $j = $i++) {
            $xi = floatval($polygon[$i]['lat']);
            $yi = floatval($polygon[$i]['lng']);
            $xj = floatval($polygon[$j]['lat']);
            $yj = floatval($polygon[$j]['lng']);

            if ((($yi > $lng) !== ($yj > $lng)) &&
                ($lat < ($xj - $xi) * ($lng - $yi) / ($yj - $yi) + $xi)) {
                $inside = !$inside;
            }
        }

        return $inside;
    }
}
