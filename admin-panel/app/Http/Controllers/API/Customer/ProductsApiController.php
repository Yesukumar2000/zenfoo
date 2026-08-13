<?php

// namespace App\Http\Controllers\Api\Customer;
namespace App\Http\Controllers\API\Customer;

use App\Helpers\CommonHelper;
use App\Helpers\ProductHelper;
use App\Services\RatingService;
use App\Http\Controllers\Controller;
use App\Http\Repository\CategoryRepository;
use App\Http\Repository\ProductRepository;
use App\Models\Admin;
use App\Models\Bookmark;
use App\Models\Brand;
use App\Models\Cart;
use App\Models\City;
use App\Models\Category;
use App\Models\CategoryGroup;
use App\Models\CategorySubGroup;
use App\Models\Combo;
use App\Models\Favorite;
use App\Models\Slider;
use App\Models\OrderItem;
use App\Models\OrderStatusList;
use App\Models\Product;
use App\Models\ProductImages;
use App\Models\ProductVariant;
use App\Models\Section;
use App\Models\Seller;
use App\Models\Setting;
use App\Models\Tax;
use App\Models\Transaction;
use App\Models\WalletTransaction;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use function App\Models\Setting;
use App\Models\ProductRating;
use App\Models\RatingImages;
use Illuminate\Validation\Rule;
use Doctrine\Inflector\InflectorFactory;

use Response;

class ProductsApiController extends Controller
{
    public $productRepository;
    public $categoryRepository;

    public function __construct(ProductRepository $productRepository, CategoryRepository $categoryRepository)
    {
        $this->productRepository = $productRepository;
        $this->categoryRepository = $categoryRepository;
    }

    public function getGroupProducts(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required',
            'longitude' => 'required',
        ], [
            'latitude.required' => 'The latitude field is required.',
            'longitude.required' => 'The longitude field is required.'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $currency = Setting::get_value('currency');
            $user_id = $request->user('api-customers') ? $request->user('api-customers')->id : '';

            $limit = ($request->limit) ?? 10;
            $offset = ($request->offset) ?? 0;

            // Sorting logic
            $sort = match ($request->sort) {
                'new' => 'p.created_at DESC',
                'old' => 'p.created_at ASC',
                'high' => 'max_price DESC',
                'low' => 'min_price ASC',
                'discount' => 'cal_discount_percentage DESC',
                'popular' => 'order_counter DESC',
                default => 'p.row_order ASC'
            };

            $seller_ids = CommonHelper::getSellerIds($request->latitude, $request->longitude);

            $where = "";
            $store_id = $request->input('store_id', '');
            $cat_id = $request->input('category_groups_id', '');
            $group_id = $request->input('sub_category_groups_id', '');
            $subcategoryIds = [];
            $categories = [];

            // 🔹 If a sub-category group is provided
            if (!empty($store_id)) {
                $categories = CategorySubGroup::where('id', $store_id)->first();
            }elseif (!empty($cat_id)) {
                $categories = CategorySubGroup::where('category_group_id', $cat_id)->first();
            }elseif (!empty($group_id)) {
                $sub_category_group = CategorySubGroup::where('id', $group_id)->first();

                if ($sub_category_group && !empty($sub_category_group->subcategory_ids)) {
                    $subcategoryIds = array_map('intval', explode(',', $sub_category_group->subcategory_ids));

                    $categoriesData = Category::select('id', 'name', 'image')
                        ->with('catActiveChilds')
                        ->whereIn('id', $subcategoryIds)
                        ->get()
                        ->keyBy('id');

                    $categories = collect($subcategoryIds)
                        ->map(function ($id) use ($categoriesData) {
                            return $categoriesData->get($id);
                        })
                        ->filter()
                        ->map(function ($cat) {
                            $cat->image_url = $cat->image ? (str_starts_with($cat->image, 'http') ? $cat->image : asset('storage/' . $cat->image)) : null;
                            return $cat;
                        })
                        ->values();

                    // Compute dynamic product_rating for child categories using order_product_ratings
                    $childCatIds = $categories->flatMap(fn($cat) => $cat->catActiveChilds->pluck('id'))->unique()->toArray();
                    $allCatIds = array_unique(array_merge($subcategoryIds, $childCatIds));

                    if (!empty($allCatIds)) {
                        $ratingMap = RatingService::getBulkCategoryRatings($allCatIds);

                        $categories->each(function ($cat) use ($ratingMap) {
                            $cat->catActiveChilds->each(function ($child) use ($ratingMap) {
                                $ratingData = $ratingMap[$child->id] ?? null;
                                $child->product_rating = $ratingData ? $ratingData['rating'] : 0;
                            });
                        });
                    }
                } else {
                    return CommonHelper::responseError('No categories found for this subcategory group.');
                }
            }

            // 🔹 Start main product query
            $products = Product::select(
                'p.*',
                'p.type as d_type',
                'p.is_pre_order_item',
                's.store_name as seller_name',
                's.slug as seller_slug',
                's.status as seller_status',
                'pv.price',
                'pv.discounted_price',
                DB::raw("if(pv.discounted_price > 0, ceil(((pv.price - pv.discounted_price)/pv.price)*100), 0) as cal_discount_percentage"),
                DB::raw("ceil((pv.price - pv.discounted_price)) as cal_discount"),
                DB::raw('count(*) as order_counter'),
                'co.name as country_made_in',
                's.longitude',
                's.latitude',
                'cities.max_deliverable_distance',
                'cities.boundary_points',
                'tx.percentage as tax_percentage',
                DB::raw("GROUP_CONCAT(t.name) as tag_names")
            )
                ->from('products as p')
                ->leftJoin('countries as co', 'p.made_in', '=', 'co.id')
                ->leftJoin('sellers as s', 'p.seller_id', '=', 's.id')
                ->leftJoin('categories as c', 'p.category_id', '=', 'c.id')
                ->leftJoin('cities', 's.city_id', '=', 'cities.id')
                ->join('product_variants as pv', 'pv.product_id', '=', 'p.id')
                ->leftJoin('product_tag as pt', 'p.id', '=', 'pt.product_id')
                ->leftJoin('tags as t', 'pt.tag_id', '=', 't.id')
                ->leftJoin('taxes as tx', 'p.tax_id', '=', 'tx.id')
                ->where('p.is_approved', 1)
                ->where('p.status', 1)
                ->where('c.status', 1)
                ->where('s.status', 1)
                ->whereIn('p.seller_id', $seller_ids)
                ->groupBy('p.id')
                ->with('ratings');

            // 🔹 Apply subcategory group filter (main part)
            if (!empty($subcategoryIds)) {
                $products->whereIn('p.category_id', $subcategoryIds);
            }

            // 🔹 Search
            if (!empty($request->search)) {
                $search = $request->search;
                $products->where(function ($query) use ($search) {
                    $query->where('p.name', 'LIKE', "%$search%")
                        ->orWhere('p.slug', 'LIKE', "%$search%")
                        ->orWhere('p.tags', 'LIKE', "%$search%");
                });
            }

            // 🔹 Price filter
            if (isset($request->min_price) && isset($request->max_price) && intval($request->max_price)) {
                $products->havingRaw("min_price > " . intval($request->min_price - 1) . " and max_price < " . intval($request->max_price + 1));
            }

            // 🔹 Brand filter
            if (!empty($request->brand_ids)) {
                $brand_ids = explode(',', $request->brand_ids);
                $products->whereIn('p.brand_id', $brand_ids);
            }

            // 🔹 Pagination
            $total = $products->count();
            $products = $products->skip($offset)->take($limit)->orderByRaw($sort)->get();

            // 🔹 Hide unneeded fields and attach variants
            foreach ($products as $i => $row) {
                $variants = ProductVariant::with(['product.tax', 'unit', 'images'])
                    ->where('product_id', $row['id'])
                    ->get();

                $variantArray = [];
                foreach ($variants as $variant) {
                    $variantArray[] = CommonHelper::getProductVariant($variant['id'], $user_id);
                }

                $products[$i]['variants'] = $variantArray;
                $products[$i]['rating_count'] = CommonHelper::productAverageRating($row['id'])['rating_count'];
                $products[$i]['average_rating'] = CommonHelper::productAverageRating($row['id'])['average_rating'];
            }

            // 🔹 Global min & max price (for filter range UI)
            $priceRange = Product::from('products as p')
                ->leftJoin('product_variants as pv', 'pv.product_id', '=', 'p.id')
                ->whereIn('p.seller_id', $seller_ids)
                ->selectRaw('MIN(IF(pv.discounted_price > 0, pv.discounted_price, pv.price)) as min_price, MAX(IF(pv.discounted_price > 0, pv.discounted_price, pv.price)) as max_price')
                ->first();

            return response()->json([
                'status' => 1,
                'message' => 'success',
                'total' => $total,
                'total_min_price' => $priceRange->min_price ?? 0,
                'total_max_price' => $priceRange->max_price ?? 0,
                'categories' => $categories, // 👈 category data added here
                'data' => $products
            ]);

        } catch (\Exception $e) {
            Log::error("Products Error: " . $e->getMessage());
            return CommonHelper::responseError("Something went wrong!");
        }
    }



    public function getProducts(Request $request)
    {

        $validator = Validator::make($request->all(), [
            'latitude' => 'required',
            'longitude' => 'required',
        ], [
            'latitude.required' => 'The latitude field is required.',
            'longitude.required' => 'The longitude field is required.'
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

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
            $seller_id = $request->get('seller_id');
            $brand_id = $request->get('brand_id');
            $country_id = $request->get('country_id');
            $seller_slug = '';
            $where = "";

            if (isset($request['search']) && $request['search'] != '') {
                $search = $request['search'];

                // Match every word in the query (e.g. voice "Amul Ghee" should
                // find "Amul Cow Ghee") instead of the whole phrase as one chunk.
                $terms = preg_split('/\s+/', trim($search), -1, PREG_SPLIT_NO_EMPTY);
                foreach ($terms as $term) {
                    $t = addslashes($term);
                    $cond = " p.`name` like '%" . $t . "%' OR p.`slug` like '%" . $t . "%' OR p.`tags` like '%" . $t . "%' ";
                    // Tolerate spelling / voice-transcription variants on longer
                    // words by also matching a prefix (e.g. "aashirwad" -> "aashi"
                    // still finds "Aashirvaad").
                    if (mb_strlen($term) >= 6) {
                        $plen = max(5, (int) floor(mb_strlen($term) * 0.6));
                        $prefix = addslashes(mb_substr($term, 0, $plen));
                        $cond .= " OR p.`name` like '%" . $prefix . "%' OR p.`tags` like '%" . $prefix . "%' ";
                    }
                    $where .= " AND ( " . $cond . " ) ";
                }
            }

            if (isset($request['seller_slug']) && !empty($request['seller_slug'])) {
                $seller_slug = $request['seller_slug'];
                if (isset($request['category_id']) && !empty($request['category_id']) && is_numeric($request['category_id'])) {
                    $seller_category = Seller::where('slug', $seller_slug)->first(['categories']);
                    if (!empty($seller_category)) {
                        $category = $seller_category['categories'];
                        $data = explode(",", $category);
                        $search = (in_array($category_id, $data, TRUE)) ? 1 : 2;
                        if ($search == 2) {
                            return CommonHelper::responseError(__('no_products_found'));
                        } else {
                            $where .= " AND s.`slug` = '$seller_slug' AND p.`category_id` IN (" . $category_id . ") ";
                        }
                    } else {
                        return CommonHelper::responseError(__('no_products_found'));
                    }
                } else {
                    $seller_category = Seller::where('slug', $seller_slug)->first(['categories']);
                    if (!empty($seller_category)) {
                        $category_ids = explode(",", $seller_category['categories']);

                        // Query categories based on the provided category IDs
                        $categories = Category::where('status', 1)
                            ->whereIn('id', $category_ids)
                            ->orderBy('id', 'ASC')
                            ->get()
                            ->toArray();

                        // Get all child category IDs
                        $ids = CommonHelper::getCategoryChildIds($categories);

                        // Convert array of category IDs to comma-separated string
                        $category_ids = implode(",", $ids);

                        $where .= " AND s.`slug` =  '$seller_slug' AND p.category_id IN (" . $category_ids . " )";
                    } else {
                        return CommonHelper::responseError(__('no_products_found'));
                    }
                }
            }

            if (isset($request['slug']) && !empty($request['slug'])) {
                $slug = $request['slug'];
                $where .= " AND p.`slug` =  '$slug' ";
            }

            if (isset($request['seller_id']) && !empty($request['seller_id']) && is_numeric($request['seller_id'])) {
                // Simply filter by seller_id - show all products from this seller
                $where .= " AND p.`seller_id` = " . $seller_id;
            }

            if (isset($request['category_id']) && !empty($request['category_id']) && is_numeric($request['category_id'])) {
                if (!isset($request['seller_id']) && empty($request['seller_id']) && !isset($request['seller_slug']) && empty($request['seller_slug'])) {
                    $where .= " AND p.`category_id`=" . $category_id;
                }
            }

            if (isset($request['category_id']) && !empty($request['category_id']) && is_numeric($request['category_id'])) {
                $where .= " AND p.`category_id`=" . $category_id;
            }

            if (isset($request['brand_id']) && !empty($request['brand_id']) && is_numeric($request['brand_id'])) {
                $where .= " AND p.`brand_id`=" . $brand_id;
            }
            if (isset($request['country_id']) && !empty($request['country_id']) && is_numeric($request['country_id'])) {
                $where .= " AND p.`made_in`=" . $country_id;
            }

            $seller_ids = CommonHelper::getSellerIds($request->latitude, $request->longitude);
            $products = array();
            $i = 0;

            $products = Product::select(
                'p.*',
                'p.type as d_type',
                'p.total_allowed_quantity',
                's.store_name as seller_name',
                's.slug as seller_slug',
                's.status as seller_status',

                'pv.price',
                'pv.discounted_price',

                DB::raw("if(pv.discounted_price > 0, ceil(((pv.price - pv.discounted_price)/pv.price)*100), 0)  as cal_discount_percentage"),

                DB::raw("ceil((pv.price - pv.discounted_price)) as cal_discount"),

                DB::raw('count(*) as order_counter'),

                //  DB::raw("(select MIN(if(discounted_price > 0, discounted_price, price)) from product_variants where product_variants.product_id = p.id) as min_price"),
                //  DB::raw("(select MAX(if(discounted_price > 0, discounted_price, price)) from product_variants where product_variants.product_id = p.id) as max_price"),
                'co.name as country_made_in',
                's.longitude',
                's.latitude',
                'cities.max_deliverable_distance',
                'cities.boundary_points',
                'tx.percentage as tax_percentage',
                DB::raw("GROUP_CONCAT(t.name) as tag_names")
                    )
                        ->from('products as p')
                        ->leftJoin("countries as co", "p.made_in", "=", "co.id")
                        ->leftJoin('sellers as s', 'p.seller_id', '=', 's.id')
                        ->leftJoin('categories as c', 'p.category_id', '=', 'c.id')
                        ->leftJoin('cities', 's.city_id', '=', 'cities.id')
                        ->Join("product_variants as pv", "pv.product_id", "=", "p.id")
                        ->leftJoin('product_tag as pt', 'p.id', '=', 'pt.product_id')
                        ->leftJoin('tags as t', 'pt.tag_id', '=', 't.id')
                        ->leftJoin('taxes as tx', 'p.tax_id', '=', 'tx.id')
                        ->where('p.is_approved', 1)
                        ->where('p.status', 1)
                        // ->where('c.status', 1)

                        // ->where('s.status', 1)
                        // ->whereIn('p.seller_id', $seller_ids)
                        ->selectRaw(
                            '
                MIN(IF(pv.discounted_price > 0, pv.discounted_price, pv.price)) as min_price,
                MAX(IF(pv.discounted_price > 0, pv.discounted_price, pv.price)) as max_price'
                        )
                        ->with('ratings');
                    if (isset($product_ids_array) && $product_ids_array != NULL) {
                        $products = $products->orderByRaw(DB::raw("FIELD(p.id, " . implode(',', $product_ids_array) . ")"));
                    }
                    $products = $products->groupBy("p.id");

                    if (isset($request->min_price) && isset($request->max_price) && intval($request->max_price)) {
                        $products = $products->havingRaw(" min_price > " . intval(intval($request->min_price) - 1) . " and max_price < " . intval(intval($request->max_price) + 1));
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
                    if (isset($request->category_ids) && !empty($request->category_ids)) {
                        // Explode the comma-separated string of category IDs into an array
                        $category_ids = explode(",", $request->category_ids);

                        // Query categories based on the provided category IDs
                        $categories = Category::where('status', 1)->whereIn('id', $category_ids)->orderBy('id', 'ASC')->get()->toArray();

                        // Get all child category IDs
                        $ids = CommonHelper::getCategoryChildIds($categories);

                        // Convert array of category IDs to comma-separated string
                        $category_ids = implode(",", $ids);
                        // dd($category_ids);
                        // Filter products based on category IDs
                        $products = $products->whereIn('p.category_id', explode(",", $category_ids));
                    }
                    if (isset($request->section_id) && $request->section_id != "") {
                        $section_id = $request->section_id;
                        $section = Section::select("*")->where("id", "=", $section_id)->first();

                        $product_ids = CommonHelper::getProductIdsSection($section);

                        // Convert product IDs into an array
                        $product_ids_array = explode(",", $product_ids);

                        // Initialize the query condition


                        if (!empty($product_ids_array)) {
                            $products = $products->whereIn('p.id', $product_ids_array);
                        }
                    }

                    if (isset($request->tag_names) && !empty($request->tag_names)) {
                        $tagsArray = explode(',', $request->tag_names);
                        $tagIds = DB::table('tags')->whereIn('name', $tagsArray)->pluck('id')->toArray();

                        //dd( $tagIds);
                        $products = $products->havingRaw("SUM(CASE WHEN pt.tag_id IN (" . implode(',', $tagIds) . ") THEN 1 ELSE 0 END) > 0")->where('p.slug', '!=', $request->tag_slug);
                    }

                    if (isset($request->barcode) && !empty($request->barcode)) {
                        $products = $products->where('p.barcode', $request->barcode);
                    }
                    if ($where != "") {
                        $products = $products->whereRaw(substr($where, 4));
                    }
                    //dd($products);
                    // $productsTotal = clone $products;
                    $total = $products->get()->count();

                    $products = $products->skip($offset)->take($limit)->orderByRaw($sort)->get();

                    $products = $products->makeHidden([
                        'row_order',
                        'return_status',
                        'cancelable_status',
                        'till_status',
                        'description',
                        'status',
                        'is_approved',
                        'return_days',
                        'pincodes',
                        'cod_allowed',
                        'pickup_location',
                        'tags',
                        'd_type',
                        // 'seller_name',
                        'seller_slug',
                        'seller_status',
                        'created_at',
                        'updated_at',
                        'deleted_at',
                        'image',
                        'other_images'
                    ]);

                    $i = 0;
                    foreach ($products as $row) {

                        $taxRate = $row->tax_percentage; // % tax

                        $variants = ProductVariant::with(['product.tax', 'unit', 'images'])
                            ->where('product_id', $row['id'])
                            ->get();

                        // Now sort using the accessor in PHP
                        if ($request->sort == 'low') {
                            $variants = $variants->sortBy('final_price_with_tax')->values();
                        } elseif ($request->sort == 'high') {
                            $variants = $variants->sortByDesc('final_price_with_tax')->values();
                        } elseif ($request->sort == 'discount') {
                            $variants = $variants->sortByDesc(function ($variant) {
                                if ($variant->discounted_price > 0 && $variant->price > 0) {
                                    return ceil((($variant->price - $variant->discounted_price) / $variant->price) * 100);
                                }
                                return 0;
                            })->values();
                        }


                        $variants = $variants->makeHidden(['product_id', 'status', 'measurement_unit_id', 'stock_unit_id', 'deleted_at']);
                        if (empty($variants)) {
                            continue;
                        }

                        CommonHelper::getProductDetails($row['id'], $user_id, false);
                        $variantArray = array();
                        for ($k = 0; $k < count($variants); $k++) {
                            array_push($variantArray, CommonHelper::getProductVariant($variants[$k]['id'], $user_id));
                        }
                        $products[$i]['variants'] = $variantArray;

                        $products[$i]->rating_count = CommonHelper::productAverageRating($row['id'])['rating_count'];
                        $products[$i]->average_rating = CommonHelper::productAverageRating($row['id'])['average_rating'];

                        // Add is_bookmarked status
                        $products[$i]->is_bookmarked = $user_id ? $this->checkProductBookmarked($user_id, $row['id']) : 0;

                        $i++;
                    }

                    $productResult = Product::from('products as p')
                        ->leftJoin('product_variants as pv', 'pv.product_id', '=', 'p.id')
                        ->whereIn('p.seller_id', $seller_ids)
                        ->selectRaw(
                            '
                MIN(IF(pv.discounted_price > 0, pv.discounted_price, pv.price)) as min_price,
                MAX(IF(pv.discounted_price > 0, pv.discounted_price, pv.price)) as max_price'
                )
                ->first();

            $total_min_price = $productResult->min_price;
            $total_max_price = $productResult->max_price;


            $banners_according_to_category = Slider::where('type', "category")->where('type_id', $request->category_id)->get();
            $category_types_according_to_category = DB::table('category_types')->where('category_id', $request->category_id)->get();
            $brands_according_to_category = Brand::whereNotNull('category_ids')
                ->whereRaw("FIND_IN_SET(?, category_ids)", [$request->category_id])
                ->get();



            
            // if (isset($request->category_type) && !empty($request->category_type)) {
            //     $type_table_data = DB::table('category_types')->where('id', $request->category_type)->value('category_id');
            // }

            if (!empty($products)) {
                $brands = CommonHelper::getBrandsHavingProducts();
                $sizes = CommonHelper::getProductVariantsSize();

                return Response::json(array(
                    'status' => 1,
                    'message' => 'success',
                    'total' => $total,
                    'total_min_price' => $total_min_price ?? 0,
                    'total_max_price' => $total_max_price ?? 0,
                    //'brands' => $brands,
                    //'sizes' => $sizes,
                    'data' => $products,
                    'banners' => $banners_according_to_category,
                    'category_types' => $category_types_according_to_category,
                    'brands_according_to_category' => $brands_according_to_category,
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

    // public function getCombos(Request $request)
    // {
    //     $currency = Setting::get_value('currency');

    //     $combos = Combo::with([
    //         'products.variants.unit', // eager-load unit too
    //     ])->get();

    //     $combosWithTotal = $combos->map(function ($combo) use ($currency) {
    //         $totalProductPrice = $combo->products->sum(function ($product) {
    //             // Get the specific variant from pivot if available
    //             $variant = $product->variants->firstWhere('id', $product->pivot->variant_id);

    //             $price = $variant
    //                 ? ($variant->discounted_price > 0 ? $variant->discounted_price : $variant->price)
    //                 : 0;

    //             return $price * ($product->pivot->quantity ?? 1);
    //         });

    //         $discountPercentage = $totalProductPrice > 0
    //             ? round((($totalProductPrice - $combo->price) / $totalProductPrice) * 100, 2)
    //             : 0;

    //         return [
    //             'id' => $combo->id,
    //             'name' => $combo->name,
    //             'description' => $combo->description,
    //             'price' => $combo->price,
    //             'type' => $combo->type,
    //             'status' => $combo->status ?? 1,
    //             'image_url' => $combo->image_url,
    //             'total_products_price' => $totalProductPrice,
    //             'discount_percentage' => ceil($discountPercentage),
    //             'currency' => $currency,

    //             'products' => $combo->products->map(function ($product) use ($currency) {
    //                 $variant = $product->variants->firstWhere('id', $product->pivot->variant_id);

    //                 return [
    //                     'product_id' => $product->id,
    //                     'product_name' => $product->name,
    //                     'variant_id' => $product->pivot->variant_id,
    //                     'variant_measurement' => $variant->measurement ?? null,
    //                     'variant_unit' => $variant->unit->short_code ?? null,
    //                     'price' => $variant
    //                         ? ($variant->discounted_price > 0 ? $variant->discounted_price : $variant->price)
    //                         : 0,
    //                     'quantity' => $product->pivot->quantity,
    //                     'currency' => $currency,
    //                 ];
    //             }),
    //         ];
    //     });

    //     if ($combosWithTotal->isEmpty()) {
    //         return CommonHelper::responseError(__('no_products_found'));
    //     }

    //     return response()->json([
    //         'status' => 1,
    //         'message' => 'success',
    //         'data' => $combosWithTotal,
    //     ]);
    // }

    public function getCombos(Request $request)
    {
        $currency = Setting::get_value('currency');

        $combosQuery = Combo::with([
            'products.variants.unit',
        ]);

        if ($request->filled('store_id')) {
            $combosQuery->where('store_id', $request->store_id);
        }

        $combos = $combosQuery->get();

        $combosWithTotal = $combos->map(function ($combo) use ($currency) {
            $totalProductPrice = $combo->products->sum(function ($product) {
                $variant = $product->variants->firstWhere('id', $product->pivot->variant_id);

                $price = $variant
                    ? ($variant->discounted_price > 0 ? $variant->discounted_price : $variant->price)
                    : 0;

                return $price * ($product->pivot->quantity ?? 1);
            });

            $discountPercentage = $totalProductPrice > 0
                ? round((($totalProductPrice - $combo->price) / $totalProductPrice) * 100, 2)
                : 0;

            return [
                'id' => $combo->id,
                'name' => $combo->name,
                'description' => $combo->description,
                'price' => $combo->price,
                'type' => $combo->type,
                'status' => $combo->status ?? 1,
                'image_url' => $combo->image_url,
                'total_products_price' => $totalProductPrice,
                'discount_percentage' => ceil($discountPercentage),
                'currency' => $currency,

                'products' => $combo->products->map(function ($product) use ($currency) {
                    $variant = $product->variants->firstWhere('id', $product->pivot->variant_id);

                    return [
                        'product_id' => $product->id,
                        'product_name' => $product->name,
                        'variant_id' => $product->pivot->variant_id,
                        'variant_measurement' => $variant->measurement ?? null,
                        'variant_unit' => $variant->unit->short_code ?? null,
                        'price' => $variant
                            ? ($variant->discounted_price > 0 ? $variant->discounted_price : $variant->price)
                            : 0,
                        'quantity' => $product->pivot->quantity,
                        'currency' => $currency,
                    ];
                }),
            ];
        });

        if ($combosWithTotal->isEmpty()) {
            return CommonHelper::responseError(__('no_products_found'));
        }

        return response()->json([
            'status' => 1,
            'message' => 'success',
            'data' => $combosWithTotal,
        ]);
    }



    public function getComboDetail(Request $records) {}


    public function getProduct(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required_without_all:slug,barcode',
            'slug' => 'required_without_all:id,barcode',
            'barcode' => 'required_without_all:id,slug',
            'latitude' => 'required',
            'longitude' => 'required'
        ], [
            'required' => 'The product :attribute field is required.',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $product_id = $request->id;
        $product_slug = $request->slug;
        $product_barcode = $request->barcode;

        $sql = Product::with(['variants' => function ($query) {
            $query->select(
                '*',
                DB::raw("(SELECT short_code FROM units as u WHERE u.id = stock_unit_id) as stock_unit_name")
            );
        }])->select(
            'p.*',
            'p.type as d_type',
            's.id as seller_id',
            's.store_name as seller_name',
            's.slug as seller_slug',
            's.status as seller_status',
            's.latitude',
            's.longitude',
            'co.name as country_made_in',
            'co.id as made_in_id',
            'cities.boundary_points',
            'cities.max_deliverable_distance',
            'c.name as category_name',
            'br.name as brand_name',
            DB::raw("GROUP_CONCAT(t.name) as tag_names")
        )
            ->from('products as p')
            ->leftJoin("countries as co", "p.made_in", "=", "co.id")
            ->leftJoin('sellers as s', 'p.seller_id', '=', 's.id')
            ->leftJoin('cities', 's.city_id', '=', 'cities.id')
            ->leftJoin('categories as c', 'p.category_id', '=', 'c.id')
            ->leftJoin('brands as br', 'p.brand_id', '=', 'br.id')
            ->leftJoin('product_tag as pt', 'p.id', '=', 'pt.product_id')
            ->leftJoin('tags as t', 'pt.tag_id', '=', 't.id')
            // ->where('s.status', 1)
            ->where('p.is_approved', 1)
            ->where(function ($query) use ($product_id, $product_slug, $product_barcode) {
                if (isset($product_id) && $product_id != null) {
                    $query->where('p.id', $product_id);
                } elseif (isset($product_slug) && $product_slug != null) {
                    $query->where('p.slug', $product_slug);
                } elseif (isset($product_barcode) && $product_barcode != null) {
                    $query->where('p.barcode', $product_barcode);
                }
            })
            ->groupBy('p.id');  // Group by product ID to handle the GROUP_CONCAT

        $product = $sql->first();

        if ($product) {

            $product = $product->makeHidden([
                'row_order',
                'pincodes',
                'pickup_location',
                'tags',
                'seller_slug',
                'seller_status',
                'created_at',
                'updated_at',
                'deleted_at',
                'image',
                'other_images',
                'boundary_points',
                'country_made_in'
            ]);

            $product->images = CommonHelper::getImages($product->id, 0, true);
            $product->made_in = $product->country_made_in ?? "";

            /*if(isset($product->boundary_points) && $product->boundary_points != "") {
                $vertices_x = $product->boundary_points ? array_column(json_decode($product->boundary_points, true), "lng") : [];    // lng x-coordinates of the vertices of the polygon
                $vertices_y = $product->boundary_points ? array_column(json_decode($product->boundary_points, true), "lat") : [];    // lat y-coordinates of the vertices of the polygon
                $points_polygon = count($vertices_x);  // number vertices - zero-based array
                if (isset($request->longitude) && CommonHelper::isInPolygon($points_polygon, $vertices_x, $vertices_y, $request->longitude, $request->latitude)) {
                    $product->is_deliverable = true;
                } else {
                    $product->is_deliverable = false;
                }
            }else{
                $product->is_deliverable = false;
            }*/

            if (isset($product->max_deliverable_distance) && $product->max_deliverable_distance != 0 && $product->max_deliverable_distance != "") {
                if (CommonHelper::isDeliverable($product->max_deliverable_distance, $product->longitude, $product->latitude, $request->longitude, $request->latitude)) {
                    $product->is_deliverable = true;
                } else {
                    $product->is_deliverable = false;
                }
            } else {
                $product->is_deliverable = false;
            }



            $user_id = $request->user('api-customers') ? $request->user('api-customers')->id : '';
            if ($user_id) {
                $fav = Favorite::where('product_id', $product->id)->where('user_id', $user_id)->first();
                $product->is_favorite = !is_null($fav) ? true : false;
            } else {
                $product->is_favorite = false;
            }
            $product->till_status = $product->till_status ?? '';
            $product->till_status_name = '';
            if ($product->till_status != '' && $product->till_status != '0') {
                if ($product->till_status == OrderStatusList::$received) {
                    $product->till_status_name = 'Order placed and not started preparing by the seller';
                } else {
                    $tillStatus = OrderStatusList::find($product->till_status);
                    $product->till_status_name = $tillStatus ? $tillStatus->status : '';
                }
            }
            $product->seller_name = $product->seller_name ?? '';
            $product->is_meat_product = $product->store_id == 19 ? 1 : 0;
            $variants = $product->variants;

            if ($variants->count() == 0) {
                return CommonHelper::responseError(__('no_items_found'));
            }
            foreach ($variants as $key => $variant) {
                $variants = $variants->makeHidden(['product_id', 'measurement_unit_id', 'stock_unit_id', 'deleted_at']);
                $variants[$key]->is_unlimited_stock = $product->is_unlimited_stock;
                if ($variants[$key]->stock <= 0 && $product->is_unlimited_stock == 0) {
                    $variants[$key]->status = 0;
                } else {
                    $variants[$key]->status = intval($variants[$key]->status) ?? 0;
                }
                if ($user_id) {
                    $cart = Cart::where('product_variant_id', $variants[$key]->id)
                        ->where('user_id', $user_id)->first();
                    if ($cart) {
                        $variants[$key]->cart_count = $cart->qty;
                    } else {
                        $variants[$key]->cart_count = 0;
                    }
                } else {
                    $variants[$key]->cart_count = 0;
                }
                $taxed = ProductHelper::getTaxableAmount($variants[$key]['id']);
                $variants[$key]['discounted_price'] = CommonHelper::doubleNumber($taxed->taxable_discounted_price ?? $variants[$key]['discounted_price']);
                $variants[$key]['price'] = CommonHelper::doubleNumber($taxed->taxable_price ?? $variants[$key]['price']);
                $variants[$key]['taxable_amount'] = CommonHelper::doubleNumber($taxed->taxable_amount);
                $variants[$key]->images = CommonHelper::getImages($variants[$key]->product_id, $variants[$key]->id);

                $variants[$key]->stock_unit_name = $variants[$key]->stock_unit_name ?? '';
            }

            $product->variants = $variants;
            $product->fssai_lic_img = CommonHelper::getFssaiLicImg();


            return CommonHelper::responseWithData($product);
        } else {
            return CommonHelper::responseError(__('no_items_found'));
        }
    }


    /* This is not using */

    public function getProductsOffline(Request $request)
    {

        $validator = Validator::make($request->all(), [
            'product_ids' => 'required',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $product_ids = $request->product_ids;
        $where = "";

        if (isset($request['slug']) && !empty($request['slug'])) {
            $slug = $request['slug'];
            $where = " AND p.`slug` =  '$slug' ";
        }

        /*$sql = "SELECT  count(p.id) as total FROM `products` p JOIN `sellers`s ON s.id=p.seller_id WHERE p.is_approved = 1 AND p.status = 1 AND s.status = 1 AND p.id IN ($product_ids) " . $where;
        $total = \DB::select(\DB::raw($sql));
        echo $where;*/

        $sql = Product::select(DB::raw('COUNT(p.id) AS total'))
            ->from('products as p')
            ->leftJoin('sellers as s', 'p.seller_id', '=', 's.id')
            ->where('p.is_approved', '=', 1)
            ->where('p.status', '=', 1)
            ->where('s.status', '=', 1)
            ->whereIn('p.id', explode(',', $product_ids));
        if ($where != "") {
            $sql = $sql->whereRaw($where);
        }
        $total = $sql->first();
        //dd($total);
        if ($total->count() > 0) {
            $total = $total->total;
        } else {
            $total = 0;
        }

        /*$sql = "SELECT p.*,s.name as seller_name,s.status as seller_status
            FROM `products` p
                JOIN `sellers`s ON s.id=p.seller_id
        WHERE p.is_approved = 1 AND p.status = 1 AND s.status = 1 AND p.id IN ($product_ids)" . $where;
        $records = \DB::select(\DB::raw($sql));
        $records = json_decode(json_encode($records), true);*/

        $sql = Product::with('images')->select('p.*', 's.name as seller_name', 's.status as seller_status')
            ->from('products as p')
            ->leftJoin('sellers as s', 's.id', '=', 'p.seller_id')
            ->where('p.is_approved', '=', 1)
            ->where('p.status', '=', 1)
            ->where('s.status', '=', 1)
            ->whereIn('p.id', explode(',', $product_ids));
        if ($where != "") {
            $sql = $sql->whereRaw($where);
        }
        $records = $sql->get()->toarray();
        //$records = json_decode(json_encode($records), true);
        //dd($records);

        $products = array();
        $i = 0;
        foreach ($records as $row) {

            /* $sql = "SELECT *,(SELECT short_code FROM units u WHERE u.id=pv.measurement_unit_id) as measurement_unit_name,
                     (SELECT short_code FROM units u WHERE u.id=pv.stock_unit_id) as stock_unit_name
                 FROM product_variants pv
                 WHERE pv.product_id=" . $row['id'] . " ORDER BY `pv`.`status` ASC";

             $variants = \DB::select(\DB::raw($sql));
             $variants = json_decode(json_encode($variants), true);*/

            $sql = ProductVariant::with('images')->select(
                '*',
                DB::raw("(SELECT short_code FROM units u WHERE u.id=pv.stock_unit_id) as stock_unit_name")
            )
                ->from('product_variants as pv')
                ->where('pv.product_id', '=', $row['id'])
                ->orderBy('pv.status', 'ASC');
            $variants = $sql->get()->toarray();

            if (empty($variants)) {
                continue;
            }

            $row['is_item_deliverable'] = true;
            unset($row['type']);
            $row['seller_name'] = !empty($row['seller_name']) ? $row['seller_name'] : "";
            $row['pincodes'] = (isset($row['pincodes']) == null) ? "" : $row['pincodes'];
            $row['is_approved'] = (isset($row['is_approved']) == null) ? "" : $row['is_approved'];
            $row['seller_id'] = (isset($row['seller_id']) == null) ? "" : $row['seller_id'];

            // Other images also taken with relation
            /*$otherImages = ProductImages::where('product_id',$row['id'])->where('product_variant_id',0)->get();
            $row['other_images'] = (empty($otherImages)) ? array() : $otherImages;
            for ($j = 0; $j < count($row['other_images']); $j++) {
                $row['other_images'][$j] = asset('storage/'.$row['other_images'][$j]['image']);
            }
            $row['image'] = asset('storage/'.$row['image']);*/

            if ($row['tax_id'] == 0) {
                $row['tax_title'] = "";
                $row['tax_percentage'] = "0";
            } else {

                $tax1 = Tax::find($row['tax_id']);
                $row['tax_title'] = (!empty($tax1['title'])) ? $tax1['title'] : "";
                $row['tax_percentage'] = (!empty($tax1['percentage'])) ? $tax1['percentage'] : "0";
            }

            $row['is_favorite'] = false;

            $products[$i] = $row;

            for ($k = 0; $k < count($variants); $k++) {

                // images also taken with relation
                /*$variantImages = ProductImages::where('product_id',$row['id'])->where('product_variant_id',$variants[$k]['id'])->get();
                $variants[$k]['images'] = (empty($variantImages)) ? array() :$variantImages;
                for ($j = 0; $j < count($variantImages); $j++) {
                    //$variants[$k]['images'][$j] = !empty(DOMAIN_URL . $variants[$k]['images'][$j]) ? DOMAIN_URL . $variants[$k]['images'][$j] : "";
                    $variants[$k]['images'][$j] = asset('storage/'.$variantImages[$j]['image']);
                }*/

                if ($variants[$k]['stock'] <= 0) {
                    $variants[$k]['status'] = 'Sold Out';
                } else {
                    $variants[$k]['status'] = $variants[$k]['status'];
                }

                $variants[$k]['cart_count'] = "0";
            }

            $products[$i]['variants'] = $variants;
            $i++;
        }

        if (!empty($products)) {
            $response['total'] = $total;
            $response['data'] = array_values($products);
            return CommonHelper::responseWithData($response);
        } else {
            return CommonHelper::responseError(__('no_items_found'));
        }
    }

    public function getVariantsOffline(Request $request)
    {

        $validator = Validator::make($request->all(), [
            'variant_ids' => 'required',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }


        $variant_ids = $request->variant_ids;
        $where = "";

        if (isset($request['slug']) && !empty($request['slug'])) {
            $slug = $request['slug'];
            $where = " AND p.`slug` = '$slug' ";
        }

        $sql = "SELECT  count(pv.id) as total FROM product_variants pv JOIN products p ON p.id=pv.product_id JOIN sellers s ON s.id=p.seller_id where pv.id IN ($variant_ids) and p.is_approved = 1 AND p.status = 1 AND s.status = 1 " . $where;
        $total = \DB::select(\DB::raw($sql));
        if (count($total) > 0) {
            $total = $total[0]->total;
        } else {
            $total = 0;
        }

        $sql = "SELECT pv.id as product_variant_id,pv.*,p.tax_id FROM product_variants pv JOIN products p ON p.id=pv.product_id where pv.id IN ($variant_ids)" . $where;
        $records = \DB::select(\DB::raw($sql));
        $records = json_decode(json_encode($records), true);
        $i = 0;
        $j = 0;


        foreach ($records as $row) {

            unset($records[$i]['images']);
            $sql = "select pv.*,p.*,s.name as seller_name,p.type as d_type,s.status as seller_status,pv.measurement,(select short_code from units u where u.id=pv.stock_unit_id) as units,(Select short_code from units su where su.id=pv.stock_unit_id) as stock_unit_name from product_variants pv left join products p on p.id=pv.product_id JOIN sellers s ON s.id=p.seller_id where pv.id=" . $row['product_variant_id'];

            $item = \DB::select(\DB::raw($sql));
            $item = json_decode(json_encode($item), true);
            $res[$i]['item'] = $item;

            for ($k = 0; $k < count($res[$i]['item']); $k++) {
                /*if (!empty($pincode_id) || $pincode_id != "") {
                    $pincodes = ($res[$i]['item'][$k]['d_type'] == "all") ? "" : $res[$i]['item'][$k]['pincodes'];

                    $pincodes = explode(',', $pincodes);
                    if ($res[$i]['item'][$k]['d_type'] == "all") {
                        $res[$i]['item'][$k]['is_item_deliverable'] = true;
                    } else if ($res[$i]['item'][$k]['d_type'] == "included") {
                        if (in_array($pincode_id, $pincodes)) {
                            $res[$i]['item'][$k]['is_item_deliverable']  = true;
                        } else {
                            $res[$i]['item'][$k]['is_item_deliverable']  = false;
                        }
                    } else if ($res[$i]['item'][$k]['d_type'] == "excluded") {

                        if (in_array($pincode_id, $pincodes)) {
                            $res[$i]['item'][$k]['is_item_deliverable']  = false;
                        } else {
                            $res[$i]['item'][$k]['is_item_deliverable']  = true;
                        }
                    }
                } else {
                    $res[$i]['item'][$k]['is_item_deliverable'] = false;
                }*/
                $res[$i]['item'][$k]['is_item_deliverable'] = true;


                $variantImages = ProductImages::where('product_id', $row['id'])->where('product_variant_id', $res[$i]['item'][$k]['id'])->get();
                $res[$i]['item'][$k]['images'] = (empty($variantImages)) ? array() : $variantImages;

                for ($j = 0; $j < count($variantImages); $j++) {
                    $res[$i]['item'][$k]['images'][$j] = str_starts_with($variantImages[$j]['image'], 'http') ? $variantImages[$j]['image'] : asset('storage/' . $variantImages[$j]['image']);
                }

                $res[$i]['item'][$k]['cart_count'] = "0";

                $otherImages = ProductImages::where('product_id', $res[$i]['item'][$k]['id'])->where('product_variant_id', 0)->get();
                //$res[$i]['item'][$k]['other_images'] = empty($otherImages) ? array() : $res[$i]['item'][$k]['other_images'];
                for ($l = 0; $l < count($otherImages); $l++) {
                    $res[$i]['item'][$k]['other_images'][$l] = str_starts_with($otherImages[$l]['image'], 'http') ? $otherImages[$l]['image'] : asset('storage/' . $otherImages[$l]['image']);
                }

                if ($row['tax_id'] == 0) {
                    $res[$i]['item'][$k]['tax_title'] = "";
                    $res[$i]['item'][$k]['tax_percentage'] = "0";
                } else {
                    $tax1 = Tax::find($row['tax_id']);
                    $row['tax_title'] = (!empty($tax1['title'])) ? $tax1['title'] : "";
                    $row['tax_percentage'] = (!empty($tax1['percentage'])) ? $tax1['percentage'] : "0";
                }
            }

            for ($j = 0; $j < count($res[$i]['item']); $j++) {
                //$res[$i]['item'][$j]['image'] = !empty($res[$i]['item'][$j]['image']) ? DOMAIN_URL . $res[$i]['item'][$j]['image'] : "";
                $res[$i]['item'][$j]['image'] = !empty($res[$i]['item'][$j]['image']) ? (str_starts_with($res[$i]['item'][$j]['image'], 'http') ? $res[$i]['item'][$j]['image'] : asset('storage/' . $res[$i]['item'][$j]['image'])) : "";
            }
            $i++;
        }
        if (!empty($res)) {
            $response['total'] = $total;
            $response['data'] = array_values($res);
            return CommonHelper::responseWithData($response);
        } else {
            return CommonHelper::responseError(__('no_items_found'));
        }
    }


    public function getSimilarProducts(Request $request)
    {

        $validator = Validator::make($request->all(), [
            'product_id' => 'required',
            'category_id' => 'required',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $user_id = $request->user('api-customers') ? $request->user('api-customers')->id : '';


        $product_id = $request['product_id'];
        $category_id = $request['category_id'];


        $limit = $request->get('limit', 6);
        $offset = 0;
        $order = "RAND()";
        $where = '';



        $sql = "SELECT count(p.id) as total FROM `products` p JOIN `sellers`s ON s.id=p.seller_id where p.id != $product_id AND p.category_id = $category_id AND p.is_approved = 1 AND p.status = 1 and s.status = 1  $where ORDER BY $order LIMIT $offset,$limit";
        $total = \DB::select(\DB::raw($sql));
        if (count($total) > 0) {
            $total = $total[0]->total;
        } else {
            $total = 0;
        }


        $rows = array();

        $sql = "SELECT p.*,s.name as seller_name,s.status as seller_status,(SELECT MIN(pv.price) FROM product_variants pv WHERE pv.product_id=p.id) as price FROM products p  JOIN sellers s on s.id=p.seller_id where p.id != $product_id and p.status=1  and p.is_approved = 1 and  s.status = 1 and category_id = $category_id $where ORDER BY $order LIMIT $offset,$limit";
        $res = \DB::select(\DB::raw($sql));
        $res = json_decode(json_encode($res), true);

        if (!empty($res)) {
            foreach ($res as $row) {
                $tempRow['id'] = $row['id'];
                $tempRow['seller_id'] = $row['seller_id'];
                $tempRow['seller_name'] = $row['seller_name'];
                $tempRow['tax_id'] = $row['tax_id'];
                $tempRow['row_order'] = $row['row_order'];
                $tempRow['name'] = $row['name'];
                $tempRow['slug'] = $row['slug'];
                $tempRow['category_id'] = $row['category_id'];

                $tempRow['indicator'] = $row['indicator'];
                $tempRow['manufacturer'] = $row['manufacturer'];
                $tempRow['made_in'] = $row['made_in'];
                $tempRow['return_status'] = $row['return_status'];
                $tempRow['cancelable_status'] = $row['cancelable_status'];
                $tempRow['till_status'] = $row['till_status'];
                $tempRow['seller_status'] = $row['seller_status'];
                $tempRow['date_added'] = $row['created_at'];
                $tempRow['price'] = $row['price'];
                $tempRow['type'] = $row['type'];
                $tempRow['pincodes'] = $row['pincodes'];
                $tempRow['is_approved'] = $row['is_approved'];
                $tempRow['return_days'] = $row['return_days'];
                $tempRow['image'] = (!empty($row['image'])) ? (str_starts_with($row['image'], 'http') ? $row['image'] : asset('storage/' . $row['image'])) : '';

                $otherImages = ProductImages::where('product_id', $row['id'])->where('product_variant_id', 0)->get();
                if (!empty($otherImages)) {
                    for ($j = 0; $j < count($otherImages); $j++) {
                        $tempRow['other_images'][$j] = str_starts_with($otherImages[$j]['image'], 'http') ? $otherImages[$j]['image'] : asset('storage/' . $otherImages[$j]['image']);
                    }
                } else {
                    $tempRow['other_images'] = array();
                }

                if ($row['tax_id'] == 0) {
                    $tempRow['tax_title'] = "";
                    $tempRow['tax_percentage'] = "0";
                } else {

                    $tax1 = Tax::find($row['tax_id']);
                    $tempRow['tax_title'] = $tax1['title'];
                    $tempRow['tax_percentage'] = $tax1['percentage'];
                }

                if ($user_id) {
                    $fav = Favorite::where('product_id', $row['id'])->where('user_id', $user_id)->first();
                    $row['is_favorite'] = !is_null($fav) ? true : false;
                } else {
                    $row['is_favorite'] = false;
                }

                $tempRow['description'] = $row['description'];
                $tempRow['status'] = $row['status'];

                $sql1 = "SELECT *,(SELECT short_code FROM units u WHERE u.id=pv.stock_unit_id) as measurement_unit_name,(SELECT short_code FROM units u WHERE u.id=pv.stock_unit_id) as stock_unit_name FROM product_variants pv WHERE pv.product_id=" . $row['id'] . " ORDER BY pv.status ASC";
                $variants = \DB::select(\DB::raw($sql1));
                $variants = json_decode(json_encode($variants), true);
                if (empty($variants)) {
                    continue;
                }
                for ($k = 0; $k < count($variants); $k++) {
                    $variantImages = ProductImages::where('product_id', $row['id'])->where('product_variant_id', $variants[$k]['id'])->get();
                    $variants[$k]['images'] = (empty($variantImages)) ? array() : $variantImages;
                    for ($j = 0; $j < count($variantImages); $j++) {
                        $variants[$k]['images'][$j] = !empty($variantImages[$j]['image']) ? (str_starts_with($variantImages[$j]['image'], 'http') ? $variantImages[$j]['image'] : asset('storage/' . $variantImages[$j]['image'])) : "";
                    }

                    $cart = Cart::where('product_variant_id', $variants[$k]['id'])->where('user_id', $user_id)->first();
                    if ($cart) {
                        $variants[$k]['cart_count'] = $cart['qty'];
                    } else {
                        $variants[$k]['cart_count'] = "0";
                    }
                }
                $tempRow['variants'] = $variants;
                $rows[] = $tempRow;
            }

            $response['total'] = $total;
            $response['data'] = $rows;
            return CommonHelper::responseWithData($response);
        } else {
            return CommonHelper::responseError(__('data_not_found'));
        }
    }

    public function getSimilarProductsFromCart(Request $request)
    {
        try {
            $currency = Setting::get_value('currency');
            $user_id = $request->user('api-customers')->id;

            // Get all cart items with their category_ids
            $cartItems = Cart::select('carts.product_id', 'products.category_id')
                ->join('products', 'carts.product_id', '=', 'products.id')
                ->where('carts.user_id', $user_id)
                ->where('carts.save_for_later', 0)
                ->get();

            if ($cartItems->isEmpty()) {
                \Log::info("SIMILAR_FROM_CART: User {$user_id} has an empty cart.");
                return CommonHelper::responseError(__('cart_is_empty'));
            }

            // Extract unique category_ids and product_ids from cart
            $category_ids = $cartItems->pluck('category_id')->unique()->toArray();
            $cart_product_ids = $cartItems->pluck('product_id')->toArray();

            \Log::info("SIMILAR_FROM_CART: User {$user_id} cart analysis", [
                'cart_items' => $cartItems->toArray(),
                'unique_category_ids' => $category_ids,
                'excluded_product_ids' => $cart_product_ids
            ]);

            // Get pagination parameters
            $limit = $request->get('limit', 10);
            $offset = $request->get('offset', 0);

            // Sorting logic (same as getGroupProducts)
            $sort = match ($request->sort) {
                'new' => 'p.created_at DESC',
                'old' => 'p.created_at ASC',
                'high' => 'max_price DESC',
                'low' => 'min_price ASC',
                'discount' => 'cal_discount_percentage DESC',
                'popular' => 'order_counter DESC',
                default => 'RAND()'
            };

            // Build query using Eloquent (similar to getGroupProducts)
            $productsQuery = Product::select(
                'p.*',
                'p.type as d_type',
                'p.is_pre_order_item',
                's.store_name as seller_name',
                's.slug as seller_slug',
                's.status as seller_status',
                'pv.price',
                'pv.discounted_price',
                DB::raw("if(pv.discounted_price > 0, ceil(((pv.price - pv.discounted_price)/pv.price)*100), 0) as cal_discount_percentage"),
                DB::raw("ceil((pv.price - pv.discounted_price)) as cal_discount"),
                DB::raw('count(*) as order_counter'),
                'co.name as country_made_in',
                's.longitude',
                's.latitude',
                'cities.max_deliverable_distance',
                'cities.boundary_points',
                'tx.percentage as tax_percentage',
                DB::raw("GROUP_CONCAT(t.name) as tag_names")
            )
                ->from('products as p')
                ->leftJoin('countries as co', 'p.made_in', '=', 'co.id')
                ->leftJoin('sellers as s', 'p.seller_id', '=', 's.id')
                ->leftJoin('categories as c', 'p.category_id', '=', 'c.id')
                ->leftJoin('cities', 's.city_id', '=', 'cities.id')
                ->join('product_variants as pv', 'pv.product_id', '=', 'p.id')
                ->leftJoin('product_tag as pt', 'p.id', '=', 'pt.product_id')
                ->leftJoin('tags as t', 'pt.tag_id', '=', 't.id')
                ->leftJoin('taxes as tx', 'p.tax_id', '=', 'tx.id')
                ->where('p.is_approved', 1)
                ->where('p.status', 1)
                ->where('c.status', 1)
                ->where(function($query) {
                    $query->where('s.status', 1)
                          ->orWhereNull('p.seller_id');
                })
                ->whereIn('p.category_id', $category_ids) // From cart categories
                ->whereNotIn('p.id', $cart_product_ids) // Exclude cart items
                ->groupBy('p.id')
                ->with('ratings');

            // Get total count
            $total = $productsQuery->get()->count();

            // Apply pagination and sorting
            $products = $productsQuery->skip($offset)->take($limit)->orderByRaw($sort)->get();

            \Log::info("SIMILAR_FROM_CART: Found total {$total} similar products. Returning " . $products->count() . " items.", [
                'similar_product_ids' => $products->pluck('id')->toArray(),
                'similar_product_names' => $products->pluck('name')->toArray()
            ]);

            // Attach variants using CommonHelper (like getGroupProducts)
            foreach ($products as $i => $row) {
                $variants = ProductVariant::with(['product.tax', 'unit', 'images'])
                    ->where('product_id', $row['id'])
                    ->get();

                $variantArray = [];
                foreach ($variants as $variant) {
                    $variantArray[] = CommonHelper::getProductVariant($variant['id'], $user_id);
                }

                $products[$i]['variants'] = $variantArray;
                $products[$i]['rating_count'] = CommonHelper::productAverageRating($row['id'])['rating_count'];
                $products[$i]['average_rating'] = CommonHelper::productAverageRating($row['id'])['average_rating'];
            }

            // Get price range for similar products
            $priceRange = Product::from('products as p')
                ->leftJoin('product_variants as pv', 'pv.product_id', '=', 'p.id')
                ->whereIn('p.category_id', $category_ids)
                ->whereNotIn('p.id', $cart_product_ids)
                ->selectRaw('MIN(IF(pv.discounted_price > 0, pv.discounted_price, pv.price)) as min_price, MAX(IF(pv.discounted_price > 0, pv.discounted_price, pv.price)) as max_price')
                ->first();

            return response()->json([
                'status' => 1,
                'message' => 'success',
                'total' => $total,
                'total_min_price' => $priceRange->min_price ?? 0,
                'total_max_price' => $priceRange->max_price ?? 0,
                'categories_count' => count($category_ids),
                'cart_items_count' => count($cart_product_ids),
                'data' => $products
            ]);

        } catch (\Exception $e) {
            \Log::error("Similar Products From Cart Error: " . $e->getMessage());
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    public function getSearchProducts(Request $request)
    {

        $validator = Validator::make($request->all(), [
            'search' => 'required',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $user_id = $request->user('api-customers') ? $request->user('api-customers')->id : '';

        $limit = $request->get('limit', 10);
        $offset = $request->get('offset', 0);

        $sort = $request->get('sort', 'id');
        $order = $request->get('order', 'DESC');

        $where = '';
        if (isset($request['search']) && $request['search'] != '') {
            $search = $request['search'];
            $search = str_replace(' ', '%', $search);
            $where = " AND (p.`id` like '%" . $search . "%' OR p.`name` like '%" . $search . "%' OR p.`image` like '%" . $search . "%' OR p.`slug` like '%" . $search . "%' OR p.`description` like '%" . $search . "%')";
        }
        /*if (isset($_POST['pincode_id']) && $_POST['pincode_id'] != "") {
            $pincode_id = $_POST['pincode_id'];
            $where .=  " AND (p.type='included' and FIND_IN_SET('$pincode_id', p.pincodes) OR (p.type='excluded' and NOT FIND_IN_SET('$pincode_id', p.pincodes)) or p.type='all')";
        }*/


        $sql = "SELECT COUNT(p.id) as total FROM `products`p JOIN `sellers` s ON s.id=p.seller_id WHERE p.is_approved = 1 AND p.status = 1 AND s.status = 1 " . $where;

        $total = \DB::select(\DB::raw($sql));
        if (count($total) > 0) {
            $total = $total[0]->total;
        } else {
            $total = 0;
        }

        $sql = "SELECT p.*,s.name as seller_name,s.status as seller_status FROM `products`p JOIN sellers s ON s.id=p.seller_id WHERE p.is_approved = 1 AND p.status = 1 AND s.status = 1 " . $where;
        $res = \DB::select(\DB::raw($sql));
        $res = json_decode(json_encode($res), true);

        $products = array();
        $i = 0;

        foreach ($res as $row) {
            $sql = "SELECT *,(SELECT short_code FROM units u WHERE u.id=pv.stock_unit_id) as measurement_unit_name,(SELECT short_code FROM units u WHERE u.id=pv.stock_unit_id) as stock_unit_name FROM product_variants pv WHERE pv.product_id=" . $row['id'] . " ORDER BY pv.status ASC";
            $variants = \DB::select(\DB::raw($sql));
            $variants = json_decode(json_encode($variants), true);
            if (empty($variants)) {
                continue;
            }

            if ($user_id) {
                $fav = Favorite::where('product_id', $row['id'])->where('user_id', $user_id)->first();
                $row['is_favorite'] = !is_null($fav) ? true : false;
            } else {
                $row['is_favorite'] = false;
            }


            $row['type'] = (isset($row['type']) == null) ? "" : $row['type'];
            $row['pincodes'] = (isset($row['pincodes']) == null) ? "" : $row['pincodes'];
            $row['is_approved'] = (isset($row['is_approved']) == null) ? "" : $row['is_approved'];
            $row['seller_id'] = (isset($row['seller_id']) == null) ? "" : $row['seller_id'];

            $otherImages = ProductImages::where('product_id', $row['id'])->where('product_variant_id', 0)->get();
            $row['other_images'] = (empty($otherImages)) ? array() : $otherImages;
            for ($j = 0; $j < count($otherImages); $j++) {
                $row['other_images'][$j] = str_starts_with($row['other_images'][$j]['image'], 'http') ? $row['other_images'][$j]['image'] : asset('storage/' . $row['other_images'][$j]['image']);
            }
            if ($row['tax_id'] == 0) {
                $row['tax_title'] = "";
                $row['tax_percentage'] = "0";
            } else {
                $tax1 = Tax::find($row['tax_id']);
                $row['tax_title'] = (!empty($tax1['title'])) ? $tax1['title'] : "";
                $row['tax_percentage'] = (!empty($tax1['percentage'])) ? $tax1['percentage'] : "0";
            }
            $row['image'] = str_starts_with($row['image'], 'http') ? $row['image'] : asset('storage/' . $row['image']);
            $product[$i] = $row;
            for ($k = 0; $k < count($variants); $k++) {
                $variantImages = ProductImages::where('product_id', $row['id'])->where('product_variant_id', $variants[$k]['id'])->get();
                $variants[$k]['images'] = (empty($variantImages)) ? array() : $variantImages;
                for ($j = 0; $j < count($variantImages); $j++) {
                    //$variants[$k]['images'][$j] = !empty(DOMAIN_URL . $variants[$k]['images'][$j]) ? DOMAIN_URL . $variants[$k]['images'][$j] : "";
                    $variants[$k]['images'][$j] = str_starts_with($variantImages[$j]['image'], 'http') ? $variantImages[$j]['image'] : asset('storage/' . $variantImages[$j]['image']);
                }

                $cart = Cart::where('product_variant_id', $variants[$k]['id'])->where('user_id', auth()->user()->id)->first();
                if ($cart) {
                    $variants[$k]['cart_count'] = $cart['qty'];
                } else {
                    $variants[$k]['cart_count'] = "0";
                }
            }
            $product[$i]['variants'] = $variants;
            $i++;
        }
        if (empty($product)) {
            return CommonHelper::responseError(__('no_products_available'));
        } else {
            $response['total'] = $total;
            $response['data'] = array_values($product);
            return CommonHelper::responseWithData($response);
        }
    }

    public function getAllProductNames(Request $request)
    {

        $sql = "SELECT p.name FROM `products` p JOIN sellers s on s.id = p.seller_id where p.is_approved = 1 AND p.status = 1 AND s.status = 1";
        $res = \DB::select(\DB::raw($sql));
        $res = json_decode(json_encode($res), true);

        $rows = $tempRow = $blog_array = $blog_array1 = array();
        foreach ($res as $row) {
            $tempRow['name'] = $row['name'];
            $rows[] = $tempRow;
        }
        $names = array_column($rows, 'name');

        $pr_names = implode(",", $names);
        $pr_name = explode(",", $pr_names);

        return CommonHelper::responseWithData($pr_name);
    }
    public function productRatingSave(Request $request)
    {
        $validator = Validator::make($request->all(), [
            // 'user_id' => 'required',
            'rate' => 'required',
            'product_id' => ['required', Rule::unique('product_ratings')->where(function ($query) use ($request) {
                return $query->where('user_id', auth()->user()->id);
            })],
            'image.*' => 'image|mimes:jpeg,png,jpg,gif,svg|max:2048'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $product_rating = new ProductRating();
        $product_rating->product_id = $request->product_id;
        $product_rating->user_id = auth()->user()->id;
        $product_rating->rate = $request->rate;
        $product_rating->review = $request->review ?? '';
        $product_rating->status = 1;
        $product_rating->save();
        if ($request->hasFile('image')) {
            CommonHelper::uploadRatingImages($request->file('image'), $product_rating->id);
        }
        $data = ProductRating::with('user', 'images')->where('id', $product_rating->id)->get();
        return CommonHelper::responseSuccessWithData("Product Rating Saved Successfully!", $data);
    }

    public function productRatingEdit(Request $request)
    {
        $id = $request->id;
        $product_rating = ProductRating::with('images')->where('id', $id)->first();
        //log::info('product edit function :=> ',[$product]);
        if (!$product_rating) {
            return CommonHelper::responseError("Product Rating Not found!");
        }
        return CommonHelper::responseWithData($product_rating);
    }

    public function productRatingUpdate(Request $request)
    {
        $validator = Validator::make($request->all(), [
            // 'user_id' => 'required',
            'rate' => 'required',
            // 'product_id' => ['required', Rule::unique('product_ratings')->where(function ($query) use ($request) {
            //     return $query->where('user_id', $request->user_id)->where('id', '!=', $request->id);
            // })],
            'image.*' => 'image|mimes:jpeg,png,jpg,gif,svg|max:2048'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        $product_image_ids = json_decode($request->deleteImageIds);
        // Check if $product_image_ids is not null and is an array or countable
        if (!is_null($product_image_ids) && (is_array($product_image_ids) || $product_image_ids instanceof Countable)) {
            // Check if $product_image_ids is not empty
            if (count($product_image_ids) !== 0) {
                foreach ($product_image_ids as $index => $product_image_id) {
                    $image = RatingImages::find($product_image_id);
                    if ($image) {
                        // Uncomment the line below if you want to delete the image file
                        // Storage::disk('s3')->delete($image->image);

                        $image->delete();
                    }
                }
            }
        }
        $product_rating = ProductRating::find($request->id);
        // $product_rating->product_id = $request->product_id;
        // $product_rating->user_id = $request->user_id;
        $product_rating->rate = $request->rate;
        $product_rating->review = $request->review ?? '';
        $product_rating->status = 1;
        $product_rating->save();
        if ($request->hasFile('image')) {
            CommonHelper::uploadRatingImages($request->file('image'), $product_rating->id);
        }
        $data = ProductRating::with('user', 'images')->where('id', $request->id)->get();
        return CommonHelper::responseSuccessWithData("Product Updated Successfully!", $data);
    }

    public function productRatingsList(Request $request)
    {
        $limit = $request->get('limit', 10);
        $offset = $request->get('offset', 0);

        $sort = $request->get('sort', 'id');
        $order = $request->get('order', 'DESC');

        $product_id = $request->product_id;
        if ($product_id != null) {
            $productRatings = ProductRating::with('user', 'images')->where('product_id', $product_id);
            $total = $productRatings->count();
            $productRatingsData['average_rating'] = CommonHelper::productAverageRating($product_id)['average_rating'];
            $productRatingsData['one_star_rating'] = CommonHelper::productAverageRating($product_id)['one_star_rating'];
            $productRatingsData['two_star_rating'] = CommonHelper::productAverageRating($product_id)['two_star_rating'];
            $productRatingsData['three_star_rating'] = CommonHelper::productAverageRating($product_id)['three_star_rating'];
            $productRatingsData['four_star_rating'] = CommonHelper::productAverageRating($product_id)['four_star_rating'];
            $productRatingsData['five_star_rating'] = CommonHelper::productAverageRating($product_id)['five_star_rating'];
            $productRatingsData['rating_list'] = $productRatings->orderBy($sort, $order)->skip($offset)->take($limit)->get();
            return CommonHelper::responseWithData($productRatingsData, $total);
        } else {
            return CommonHelper::responseError("Please select product first");
        }
    }
    public function productRatingImageList(Request $request)
    {
        $limit = $request->get('limit', 10);
        $offset = $request->get('offset', 0);

        $sort = $request->get('sort', 'id');
        $order = $request->get('order', 'DESC');

        $product_id = $request->product_id;
        if ($product_id != null) {
            $productRatingImages = ProductRating::with('images')->where('product_id', $product_id)->get();
            if ($productRatingImages->isNotEmpty()) {
                $images = $productRatingImages->pluck('images')->flatten();
                $total = $images->count();
                $images = $productRatingImages->pluck('images')->flatten()->skip($offset)->take($limit);
                $RatingImages = [];
                foreach ($images as $image) {
                    $RatingImages[] = $image->image_url;
                }
                return CommonHelper::responseWithData($RatingImages, $total);
            }
            return CommonHelper::responseError("Product not available");
        } else {
            return CommonHelper::responseError("Please select product first");
        }
    }

    public function getSeoThings(Request $request)
    {
        $slug = $request->input('slug');

        $product = Product::select('meta_title', 'meta_keywords', 'meta_description', 'schema_markup', 'image')
            ->where('slug', $slug)
            ->first();

        if (!$product) {
            return CommonHelper::responseError("Product not available");
        }
        $seoThings = [];
        $seoThings['meta_title'] = $product->meta_title;
        $seoThings['meta_keywords'] = $product->meta_keywords;
        $seoThings['meta_description'] = $product->meta_description;
        $seoThings['schema_markup'] = $product->schema_markup;
        $seoThings['og_image'] = $product->image_url;
        $favicon = Setting::get_value('favicon');
        $seoThings['favicon'] = $favicon ? (str_starts_with($favicon, 'http') ? $favicon : asset('storage/' . $favicon)) : '';

        return CommonHelper::responseWithData($seoThings);
    }

    public function getProductCategory(Request $request)
    {

        $validator = Validator::make($request->all(), [
            'latitude' => 'required',
            'longitude' => 'required',
        ], [
            'latitude.required' => 'The latitude field is required.',
            'longitude.required' => 'The longitude field is required.'
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

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
            $seller_id = $request->get('seller_id');
            $brand_id = $request->get('brand_id');
            $country_id = $request->get('country_id');
            $seller_slug = '';
            $where = "";

            if (isset($request['search']) && $request['search'] != '') {
                $search = $request['search'];

                // Match every word in the query (e.g. voice "Amul Ghee" should
                // find "Amul Cow Ghee") instead of the whole phrase as one chunk.
                $terms = preg_split('/\s+/', trim($search), -1, PREG_SPLIT_NO_EMPTY);
                foreach ($terms as $term) {
                    $t = addslashes($term);
                    $cond = " p.`name` like '%" . $t . "%' OR p.`slug` like '%" . $t . "%' OR p.`tags` like '%" . $t . "%' ";
                    // Tolerate spelling / voice-transcription variants on longer
                    // words by also matching a prefix (e.g. "aashirwad" -> "aashi"
                    // still finds "Aashirvaad").
                    if (mb_strlen($term) >= 6) {
                        $plen = max(5, (int) floor(mb_strlen($term) * 0.6));
                        $prefix = addslashes(mb_substr($term, 0, $plen));
                        $cond .= " OR p.`name` like '%" . $prefix . "%' OR p.`tags` like '%" . $prefix . "%' ";
                    }
                    $where .= " AND ( " . $cond . " ) ";
                }
            }

            if (isset($request['seller_slug']) && !empty($request['seller_slug'])) {
                $seller_slug = $request['seller_slug'];
                if (isset($request['category_id']) && !empty($request['category_id']) && is_numeric($request['category_id'])) {
                    $seller_category = Seller::where('slug', $seller_slug)->first(['categories']);
                    if (!empty($seller_category)) {
                        $category = $seller_category['categories'];
                        $data = explode(",", $category);
                        $search = (in_array($category_id, $data, TRUE)) ? 1 : 2;
                        if ($search == 2) {
                            return CommonHelper::responseError(__('no_products_found'));
                        } else {
                            $where .= " AND s.`slug` = '$seller_slug' AND p.`category_id` IN (" . $category_id . ") ";
                        }
                    } else {
                        return CommonHelper::responseError(__('no_products_found'));
                    }
                } else {
                    $seller_category = Seller::where('slug', $seller_slug)->first(['categories']);
                    if (!empty($seller_category)) {
                        $category_ids = explode(",", $seller_category['categories']);

                        // Query categories based on the provided category IDs
                        $categories = Category::where('status', 1)
                            ->whereIn('id', $category_ids)
                            ->orderBy('id', 'ASC')
                            ->get()
                            ->toArray();

                        // Get all child category IDs
                        $ids = CommonHelper::getCategoryChildIds($categories);

                        // Convert array of category IDs to comma-separated string
                        $category_ids = implode(",", $ids);

                        $where .= " AND s.`slug` =  '$seller_slug' AND p.category_id IN (" . $category_ids . " )";
                    } else {
                        return CommonHelper::responseError(__('no_products_found'));
                    }
                }
            }

            if (isset($request['slug']) && !empty($request['slug'])) {
                $slug = $request['slug'];
                $where .= " AND p.`slug` =  '$slug' ";
            }

            if (isset($request['seller_id']) && !empty($request['seller_id']) && is_numeric($request['seller_id'])) {
                // Simply filter by seller_id - show all products from this seller
                $where .= " AND p.`seller_id` = " . $seller_id;
            }

            if (isset($request['category_id']) && !empty($request['category_id']) && is_numeric($request['category_id'])) {
                if (!isset($request['seller_id']) && empty($request['seller_id']) && !isset($request['seller_slug']) && empty($request['seller_slug'])) {
                    $where .= " AND p.`category_id`=" . $category_id;
                }
            }

            if (isset($request['category_id']) && !empty($request['category_id']) && is_numeric($request['category_id'])) {
                $where .= " AND p.`category_id`=" . $category_id;
            }

            if (isset($request['brand_id']) && !empty($request['brand_id']) && is_numeric($request['brand_id'])) {
                $where .= " AND p.`brand_id`=" . $brand_id;
            }
            if (isset($request['country_id']) && !empty($request['country_id']) && is_numeric($request['country_id'])) {
                $where .= " AND p.`made_in`=" . $country_id;
            }

            $seller_ids = CommonHelper::getSellerIds($request->latitude, $request->longitude);
            $products = array();
            $i = 0;

            $products = Product::select(
                'p.*',
                'p.type as d_type',
                's.store_name as seller_name',
                's.slug as seller_slug',
                's.status as seller_status',

                'pv.price',
                'pv.discounted_price',

                DB::raw("if(pv.discounted_price > 0, ceil(((pv.price - pv.discounted_price)/pv.price)*100), 0)  as cal_discount_percentage"),

                DB::raw("ceil((pv.price - pv.discounted_price)) as cal_discount"),

                DB::raw('count(*) as order_counter'),

                //  DB::raw("(select MIN(if(discounted_price > 0, discounted_price, price)) from product_variants where product_variants.product_id = p.id) as min_price"),
                //  DB::raw("(select MAX(if(discounted_price > 0, discounted_price, price)) from product_variants where product_variants.product_id = p.id) as max_price"),
                'co.name as country_made_in',
                's.longitude',
                's.latitude',
                'cities.max_deliverable_distance',
                'cities.boundary_points',
                'tx.percentage as tax_percentage',
                DB::raw("GROUP_CONCAT(t.name) as tag_names")
            )
                ->from('products as p')
                ->leftJoin("countries as co", "p.made_in", "=", "co.id")
                ->leftJoin('sellers as s', 'p.seller_id', '=', 's.id')
                ->leftJoin('categories as c', 'p.category_id', '=', 'c.id')
                ->leftJoin('cities', 's.city_id', '=', 'cities.id')
                ->Join("product_variants as pv", "pv.product_id", "=", "p.id")
                ->leftJoin('product_tag as pt', 'p.id', '=', 'pt.product_id')
                ->leftJoin('tags as t', 'pt.tag_id', '=', 't.id')
                ->leftJoin('taxes as tx', 'p.tax_id', '=', 'tx.id')
                ->where('p.is_approved', 1)
                ->where('p.status', 1)
                ->where('c.status', 1)

                ->where('s.status', 1)
                ->whereIn('p.seller_id', $seller_ids)
                ->selectRaw(
                    '
        MIN(IF(pv.discounted_price > 0, pv.discounted_price, pv.price)) as min_price,
        MAX(IF(pv.discounted_price > 0, pv.discounted_price, pv.price)) as max_price'
                )
                ->with('ratings');
            if (isset($product_ids_array) && $product_ids_array != NULL) {
                $products = $products->orderByRaw(DB::raw("FIELD(p.id, " . implode(',', $product_ids_array) . ")"));
            }
            $products = $products->groupBy("p.id");

            if (isset($request->min_price) && isset($request->max_price) && intval($request->max_price)) {
                $products = $products->havingRaw(" min_price > " . intval(intval($request->min_price) - 1) . " and max_price < " . intval(intval($request->max_price) + 1));
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
            if (isset($request->category_ids) && !empty($request->category_ids)) {
                // Explode the comma-separated string of category IDs into an array
                $category_ids = explode(",", $request->category_ids);

                // Query categories based on the provided category IDs
                $categories = Category::where('status', 1)->whereIn('id', $category_ids)->orderBy('id', 'ASC')->get()->toArray();

                // Get all child category IDs
                $ids = CommonHelper::getCategoryChildIds($categories);

                // Convert array of category IDs to comma-separated string
                $category_ids = implode(",", $ids);
                // dd($category_ids);
                // Filter products based on category IDs
                $products = $products->whereIn('p.category_id', explode(",", $category_ids));
            }
            if (isset($request->section_id) && $request->section_id != "") {
                $section_id = $request->section_id;
                $section = Section::select("*")->where("id", "=", $section_id)->first();

                $product_ids = CommonHelper::getProductIdsSection($section);

                // Convert product IDs into an array
                $product_ids_array = explode(",", $product_ids);

                // Initialize the query condition


                if (!empty($product_ids_array)) {
                    $products = $products->whereIn('p.id', $product_ids_array);
                }
            }

            if (isset($request->tag_names) && !empty($request->tag_names)) {
                $tagsArray = explode(',', $request->tag_names);
                $tagIds = DB::table('tags')->whereIn('name', $tagsArray)->pluck('id')->toArray();

                //dd( $tagIds);
                $products = $products->havingRaw("SUM(CASE WHEN pt.tag_id IN (" . implode(',', $tagIds) . ") THEN 1 ELSE 0 END) > 0")->where('p.slug', '!=', $request->tag_slug);
            }

            if (isset($request->barcode) && !empty($request->barcode)) {
                $products = $products->where('p.barcode', $request->barcode);
            }
            if ($where != "") {
                $products = $products->whereRaw(substr($where, 4));
            }
            //dd($products);
            // $productsTotal = clone $products;
            $total = $products->get()->count();

            $products = $products->skip($offset)->take($limit)->orderByRaw($sort)->get();

            $products = $products->makeHidden([
                'row_order',
                'return_status',
                'cancelable_status',
                'till_status',
                'description',
                'status',
                'is_approved',
                'return_days',
                'pincodes',
                'cod_allowed',
                'pickup_location',
                'tags',
                'd_type',
                'seller_name',
                'seller_slug',
                'seller_status',
                'created_at',
                'updated_at',
                'deleted_at',
                'image',
                'other_images'
            ]);

            $i = 0;
            foreach ($products as $row) {

                $taxRate = $row->tax_percentage; // % tax

                $variants = ProductVariant::with(['product.tax', 'unit', 'images'])
                    ->where('product_id', $row['id'])
                    ->get();

                // Now sort using the accessor in PHP
                if ($request->sort == 'low') {
                    $variants = $variants->sortBy('final_price_with_tax')->values();
                } elseif ($request->sort == 'high') {
                    $variants = $variants->sortByDesc('final_price_with_tax')->values();
                } elseif ($request->sort == 'discount') {
                    $variants = $variants->sortByDesc(function ($variant) {
                        if ($variant->discounted_price > 0 && $variant->price > 0) {
                            return ceil((($variant->price - $variant->discounted_price) / $variant->price) * 100);
                        }
                        return 0;
                    })->values();
                }


                $variants = $variants->makeHidden(['product_id', 'status', 'measurement_unit_id', 'stock_unit_id', 'deleted_at']);
                if (empty($variants)) {
                    continue;
                }

                CommonHelper::getProductDetails($row['id'], $user_id, false);
                $variantArray = array();
                for ($k = 0; $k < count($variants); $k++) {
                    array_push($variantArray, CommonHelper::getProductVariant($variants[$k]['id'], $user_id));
                }
                $products[$i]['variants'] = $variantArray;

                $products[$i]->rating_count = CommonHelper::productAverageRating($row['id'])['rating_count'];
                $products[$i]->average_rating = CommonHelper::productAverageRating($row['id'])['average_rating'];

                $i++;
            }

            $productResult = Product::from('products as p')
                ->leftJoin('product_variants as pv', 'pv.product_id', '=', 'p.id')
                ->whereIn('p.seller_id', $seller_ids)
                ->selectRaw(
                    '
                    MIN(IF(pv.discounted_price > 0, pv.discounted_price, pv.price)) as min_price,
                    MAX(IF(pv.discounted_price > 0, pv.discounted_price, pv.price)) as max_price'
                )
                ->first();

            $total_min_price = $productResult->min_price;
            $total_max_price = $productResult->max_price;


            if (!empty($products)) {
                $brands = CommonHelper::getBrandsHavingProducts();
                $sizes = CommonHelper::getProductVariantsSize();

                return Response::json(array(
                    'status' => 1,
                    'message' => 'success',
                    'total' => $total,
                    'total_min_price' => $total_min_price ?? 0,
                    'total_max_price' => $total_max_price ?? 0,
                    //'brands' => $brands,
                    //'sizes' => $sizes,
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

    /**
     * Helper method to check if a product is bookmarked by a user
     */
    private function checkProductBookmarked($user_id, $product_id)
    {
        return Bookmark::where('user_id', $user_id)
            ->where('type', 'product')
            ->where('bookmarkable_type', 'App\Models\Product')
            ->where('bookmarkable_id', $product_id)
            ->exists() ? 1 : 0;
    }
}
