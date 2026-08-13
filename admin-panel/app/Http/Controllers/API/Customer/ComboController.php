<?php

// namespace App\Http\Controllers\Api\Customer;
namespace App\Http\Controllers\API\Customer;

use App\Helpers\CommonHelper;
use App\Helpers\ProductHelper;
use App\Http\Controllers\Controller;
use App\Http\Repository\CategoryRepository;
use App\Http\Repository\ProductRepository;
use App\Models\Admin;
use App\Models\Bookmark;
use App\Models\Brand;
use App\Models\Cart;
use App\Models\ComboCategory;

use App\Models\City;
use App\Models\CategoryType;
use App\Models\Category;
use App\Models\CategoryGroup;
use App\Models\CategorySubGroup;
use App\Models\Combo;
use App\Models\Favorite;
use App\Models\Slider;
use App\Models\OrderItem;
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

class ComboController extends Controller
{

    public function getCombosCustomerHomePage(Request $request)
    {

        
        $user = $request->user('api-customers');

        if (!$user) {
            return response()->json([
                'status' => 0,
                'message' => 'User not found or unauthorized'
            ], 404);
        }

        $user_id = $user->id;

        $alreadyAddedComboIds = DB::table('combo_custom_cart')
            ->where('user_id', $user_id)
            ->where('is_ordered', 0)
            ->pluck('combo_id')
            ->toArray();


        $currency = Setting::get_value('currency');

        $combosQuery = Combo::with([
            'products.variants.unit',
        ]);


        if($request->store_id){

            $combosQuery->whereRaw("store_id NOT LIKE '%,%'");

            if ($request->filled('store_id')) {
                $combosQuery->where('store_id', $request->store_id);
            }
        }
        else{
            $combosQuery->whereRaw("store_id LIKE '%,%'");
        }


        $combos = $combosQuery->get();

        // dd($combos);

        $combosWithTotal = $combos->map(function ($combo) use ($currency, $alreadyAddedComboIds, $user_id) {
            $totalProductPrice = $combo->products->sum(function ($product) {
                $variant = $product->variants->firstWhere('id', $product->pivot->variant_id);

                $price = $variant
                    ? ($variant->discounted_price > 0 ? $variant->discounted_price : $variant->price)
                    : 0;

                return $price * ($product->pivot->quantity ?? 1);
            });


            $totalActualPrice = $combo->products->sum(function ($product) {
                $variant = $product->variants->firstWhere('id', $product->pivot->variant_id);


                $actual_price = $variant
                    ? ($variant->price > 0 ? $variant->price : $variant->discounted_price)
                    : 0;

                return $actual_price * ($product->pivot->quantity ?? 1);
            });

            $discountPercentage = $totalActualPrice > 0
                ? round((($totalActualPrice - $totalProductPrice) / $totalActualPrice) * 100, 2)
                : 0;


            $category_type_data = ComboCategory::where('id',$combo->category_type)->first();

            // Calculate average rating from all products in the combo
            $productIds = $combo->products->pluck('id')->toArray();
            $allRatings = [];
            $totalRatingCount = 0;

            if (!empty($productIds)) {
                foreach ($productIds as $productId) {
                    $productRatings = DB::table('order_product_ratings')
                        ->where('product_id', $productId)
                        ->pluck('rating')
                        ->toArray();

                    if (!empty($productRatings)) {
                        $allRatings = array_merge($allRatings, $productRatings);
                        $totalRatingCount += count($productRatings);
                    }
                }
            }

            // If no ratings available for any product, generate random rating between 4.0 and 4.5
            if (empty($allRatings)) {
                $avgRating = round(4.0 + (mt_rand(0, 50) / 100), 1); // Random between 4.0 and 4.5
                $ratingCount = mt_rand(10, 50); // Random count between 10 and 50
            } else {
                $avgRating = array_sum($allRatings) / count($allRatings);
                $ratingCount = $totalRatingCount;
            }

            // Check if combo is bookmarked
            $isBookmarked = Bookmark::where('user_id', $user_id)
                ->where('type', 'combo')
                ->where('bookmarkable_type', Combo::class)
                ->where('bookmarkable_id', $combo->id)
                ->exists();


            return [
                'id' => $combo->id,
                'name' => $combo->name,
                'description' => $combo->description,
                'price' => $combo->price,

                'rating' => round($avgRating, 1),
                'rating_count' => (int) $ratingCount,

                'product_count' => $combo->products->count(),
                'type' => $combo->type,
                'category_type' => $category_type_data,
                'status' => $combo->status ?? 1,
                'image_url' => $combo->image_url,
                'total_products_price' => $totalProductPrice,
                'total_actual_price' => $totalActualPrice,
                'discount_percentage' => $discountPercentage,
                'currency' => $currency,

                'is_already_added' => in_array($combo->id, $alreadyAddedComboIds) ? 1 : 0,
                'is_bookmarked' => $isBookmarked ? 1 : 0,

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
            // return CommonHelper::responseError(__('no_products_found'));
            
            return response()->json([
                'status' => 1,
                'message' => 'success',
                'data' => [],
            ]);
        }

        return response()->json([
            'status' => 1,
            'message' => 'success',
            'data' => $combosWithTotal,
        ]);
    }

    
    public function getCombosCustomerBasedOnCategoryType(Request $request)
    {


        $user = $request->user('api-customers');

        if (!$user) {
            return response()->json([
                'status' => 0,
                'message' => 'User not found or unauthorized'
            ], 404);
        }

        $user_id = $user->id;

        $alreadyAddedComboIds = DB::table('combo_custom_cart')
            ->where('user_id', $user_id)
            ->pluck('combo_id')
            ->toArray();

        $currency = Setting::get_value('currency');

        $combosQuery = Combo::with([
            'products.variants.unit',
        ]);

        $combosQuery->whereRaw("store_id LIKE '%,%'");


        $combos = $combosQuery->get();

        $combosWithTotal = $combos->map(function ($combo) use ($currency, $alreadyAddedComboIds, $user_id) {
            $totalProductPrice = $combo->products->sum(function ($product) {
                $variant = $product->variants->firstWhere('id', $product->pivot->variant_id);

                $price = $variant
                    ? ($variant->discounted_price > 0 ? $variant->discounted_price : $variant->price)
                    : 0;

                return $price * ($product->pivot->quantity ?? 1);
            });


            $totalActualPrice = $combo->products->sum(function ($product) {
                $variant = $product->variants->firstWhere('id', $product->pivot->variant_id);


                $actual_price = $variant
                    ? ($variant->price > 0 ? $variant->price : $variant->discounted_price)
                    : 0;

                return $actual_price * ($product->pivot->quantity ?? 1);
            });

            $discountPercentage = $totalActualPrice > 0
                ? round((($totalActualPrice - $totalProductPrice) / $totalActualPrice) * 100, 2)
                : 0;


            $category_type_data = ComboCategory::where('id',$combo->category_type)->first();

            // Calculate average rating from all products in the combo
            $productIds = $combo->products->pluck('id')->toArray();
            $allRatings = [];
            $totalRatingCount = 0;

            if (!empty($productIds)) {
                foreach ($productIds as $productId) {
                    $productRatings = DB::table('order_product_ratings')
                        ->where('product_id', $productId)
                        ->pluck('rating')
                        ->toArray();

                    if (!empty($productRatings)) {
                        $allRatings = array_merge($allRatings, $productRatings);
                        $totalRatingCount += count($productRatings);
                    }
                }
            }

            // If no ratings available for any product, generate random rating between 4.0 and 4.5
            if (empty($allRatings)) {
                $avgRating = round(4.0 + (mt_rand(0, 50) / 100), 1); // Random between 4.0 and 4.5
                $ratingCount = mt_rand(10, 50); // Random count between 10 and 50
            } else {
                $avgRating = array_sum($allRatings) / count($allRatings);
                $ratingCount = $totalRatingCount;
            }

            // Check if combo is bookmarked
            $isBookmarked = Bookmark::where('user_id', $user_id)
                ->where('type', 'combo')
                ->where('bookmarkable_type', Combo::class)
                ->where('bookmarkable_id', $combo->id)
                ->exists();

            return [
                'id' => $combo->id,
                'name' => $combo->name,
                'description' => $combo->description,
                'price' => $combo->price,

                'rating' => round($avgRating, 1),
                'rating_count' => (int) $ratingCount,

                'product_count' => $combo->products->count(),
                'type' => $combo->type,
                'category_type' => $category_type_data,
                'status' => $combo->status ?? 1,
                'image_url' => $combo->image_url,
                'total_products_price' => $totalProductPrice,
                'total_actual_price' => $totalActualPrice,
                'discount_percentage' => $discountPercentage,
                'currency' => $currency,

                'created_at' => $combo->created_at,

                'is_already_added' => in_array($combo->id, $alreadyAddedComboIds) ? 1 : 0,
                'is_bookmarked' => $isBookmarked ? 1 : 0,

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
            // return CommonHelper::responseError(__('no_products_found'));

            
            return response()->json([
                'status' => 1,
                'message' => 'success',
                'data' => [],
            ]);


        }


        if ($request->filled('filter')) {

            if ($request->filter === 'high_to_low') {
                $combosWithTotal = $combosWithTotal->sortByDesc('total_products_price')->values();
            }

            if ($request->filter === 'low_to_high') {
                $combosWithTotal = $combosWithTotal->sortBy('total_products_price')->values();
            }

            if ($request->filter === 'latest') {
                $combosWithTotal = $combosWithTotal
                    ->sortByDesc('created_at')
                    ->values();
            }

            if ($request->filter === 'oldest') {
                $combosWithTotal = $combosWithTotal
                    ->sortBy('created_at')
                    ->values();
            }

        }

        
        if ($request->filled('from_count') || $request->filled('to_count')) {

            $fromCount = $request->filled('from_count') ? (int) $request->from_count : 0;
            $toCount   = $request->filled('to_count') ? (int) $request->to_count : PHP_INT_MAX;

            $combosWithTotal = $combosWithTotal
                ->filter(function ($item) use ($fromCount, $toCount) {
                    return $item['product_count'] >= $fromCount &&
                        $item['product_count'] <= $toCount;
                })
                ->values();
        }


        if ($request->filled('combo_type_id')) {
            $combosWithTotal = $combosWithTotal
                ->filter(function ($item) use ($request) {
                    return isset($item['category_type']['id']) &&
                        $item['category_type']['id'] == $request->combo_type_id;
                })
                ->values();
        }


        if ($request->filled('from_price') || $request->filled('to_price')) {

            $fromPrice = $request->filled('from_price') ? (float) $request->from_price : 0;
            $toPrice   = $request->filled('to_price') ? (float) $request->to_price : INF;

            $combosWithTotal = $combosWithTotal
                ->filter(function ($item) use ($fromPrice, $toPrice) {
                    return $item['total_products_price'] >= $fromPrice &&
                        $item['total_products_price'] <= $toPrice;
                })
                ->values();
        }


        // $segregatedCombos = $combosWithTotal->groupBy(function ($item) {
        //     return $item['category_type']['name'] ?? 'Other';
        // });


        $segregatedCombos = $combosWithTotal
            ->groupBy(function ($item) {
                return $item['category_type']['name'] ?? 'Other';
            })
            ->map(function ($group, $categoryName) {
                return [
                    'name' => $categoryName,
                    'combos' => $group->values()
                ];
            })
            ->values();



        $comboTypes = $combosWithTotal
                        ->pluck('category_type')
                        ->filter()
                        ->unique('id')
                        ->values();

        return response()->json([
            'status' => 1,
            'message' => 'success',
            'data' => $segregatedCombos,
            'combo_types' => $comboTypes,
        ]);

    }


    public function getCombosCustomer(Request $request)
    {
        $currency = Setting::get_value('currency');

        $user = $request->user('api-customers');
        $user_id = $user ? $user->id : null;

        $combosQuery = Combo::with([
            'products.variants.unit',
        ]);

        if ($request->filled('store_id')) {
            $combosQuery->where('store_id', $request->store_id);
        }

        $combos = $combosQuery->get();

        $combosWithTotal = $combos->map(function ($combo) use ($currency, $user_id) {
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

            // Check if combo is bookmarked
            $isBookmarked = false;
            if ($user_id) {
                $isBookmarked = Bookmark::where('user_id', $user_id)
                    ->where('type', 'combo')
                    ->where('bookmarkable_type', Combo::class)
                    ->where('bookmarkable_id', $combo->id)
                    ->exists();
            }

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
                'is_bookmarked' => $isBookmarked ? 1 : 0,

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

    public function getSingleCombo(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'combo_id' => 'required|integer|exists:combos,id',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError(implode(', ', $validator->errors()->all()));
        }

        $currency = Setting::get_value('currency');

        $user = $request->user('api-customers');

        if (!$user) {
            return response()->json([
                'status' => 0,
                'message' => 'User not found or unauthorized'
            ], 404);
        }

        $user_id = $user->id;


        $customCart = null;
        if ($user_id) {
            $customCart = DB::table('combo_custom_cart')
                ->where('combo_id', $request->combo_id)
                ->where('user_id', $user_id)
                ->where('is_ordered', 0)
                ->first();
        }

        $combo = Combo::with([
            'products.variants.unit',
            'products.images',
            'products.store',
        ])->find($request->combo_id);

        if (!$combo) {
            return CommonHelper::responseError(__('combo_not_found'));
        }

        
        $combo->is_already_added = 0;


        if ($customCart) {
            $customProducts = DB::table('combo_custom_products')
                ->where('combo_custom_id', $customCart->id)
                ->get();

            if ($customProducts->isNotEmpty()) {
                // Load custom products with their relationships
                $productIds = $customProducts->pluck('product_id')->unique();

                $loadedProducts = Product::with([
                    'variants.unit',
                    'images',
                    'store',
                ])->whereIn('id', $productIds)->get();

                // Map custom quantities and variants to products
                $comboProducts = $loadedProducts->map(function ($product) use ($customProducts) {
                    $customProduct = $customProducts->firstWhere('product_id', $product->id);

                    // Add pivot data to mimic combo_products relationship
                    $product->pivot = (object)[
                        'variant_id' => $customProduct->variant_id,
                        'quantity' => $customProduct->quantity,
                    ];

                    return $product;
                });

                // Replace combo products with custom products
                $combo->setRelation('products', $comboProducts);
                $combo->is_already_added = 1;
            }
        }

        $totalProductPrice = $combo->products->sum(function ($product) {
            $variant = $product->variants->firstWhere('id', $product->pivot->variant_id);

            $price = $variant
                ? ($variant->discounted_price > 0 ? $variant->discounted_price : $variant->price)
                : 0;

            return $price * ($product->pivot->quantity ?? 1);
        });

        $totalActualPrice = $combo->products->sum(function ($product) {
            $variant = $product->variants->firstWhere('id', $product->pivot->variant_id);

            $actual_price = $variant
                ? ($variant->price > 0 ? $variant->price : $variant->discounted_price)
                : 0;

            return $actual_price * ($product->pivot->quantity ?? 1);
        });

        $discountPercentage = $totalActualPrice > 0
            ? round((($totalActualPrice - $totalProductPrice) / $totalActualPrice) * 100, 2)
            : 0;

        $category_type_data = ComboCategory::where('id', $combo->category_type)->first();

        $ratingData = DB::table('product_ratings')
            ->where('is_combo', 1)
            ->where('product_id', $combo->id)
            ->selectRaw('COUNT(*) as rating_count, AVG(rate) as avg_rating')
            ->first();

        $ratingCount = $ratingData->rating_count ?? 0;
        $avgRating = $ratingData->avg_rating ?? 0;

        // Check if combo is bookmarked
        $isBookmarked = Bookmark::where('user_id', $user_id)
            ->where('type', 'combo')
            ->where('bookmarkable_type', Combo::class)
            ->where('bookmarkable_id', $combo->id)
            ->exists();

        $ratings = ProductRating::where('product_id', $combo->id)
            ->where('is_combo', 1)
            ->with(['user', 'images'])
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($rating) {
                return [
                    'id' => $rating->id,
                    'user_name' => $rating->user->name ?? 'Anonymous',
                    'user_profile' => $rating->user->profile ?? null,
                    'rate' => $rating->rate,
                    'review' => $rating->review,
                    'created_at' => $rating->created_at->format('Y-m-d H:i:s'),
                    'images' => $rating->images->map(function ($image) {
                        return [
                            'id' => $image->id,
                            'image_url' => $image->image ? (str_starts_with($image->image, 'http') ? $image->image : asset('storage/' . $image->image)) : null,
                        ];
                    }),
                ];
            });

        $banner_video_url = null;
        $banner_video_duration = 0;

        if ($combo->banner_video) {
            $banner_video_url = str_starts_with($combo->banner_video, 'http') ? $combo->banner_video : asset('storage/' . $combo->banner_video);

            // Get video duration
            $videoPath = storage_path('app/public/' . $combo->banner_video);
            if (file_exists($videoPath)) {
                try {
                    // Use getID3 library to get video duration
                    $getID3 = new \getID3;
                    $fileInfo = $getID3->analyze($videoPath);

                    if (isset($fileInfo['playtime_seconds'])) {
                        $banner_video_duration = (int) round($fileInfo['playtime_seconds']);
                    }
                } catch (\Exception $e) {
                    // If getID3 fails, try ffprobe as fallback
                    $banner_video_duration = 0;
                }
            }
        }

        $comboData = [
            'id' => $combo->id,
            'is_already_added' => (int) $combo->is_already_added,
            'is_bookmarked' => $isBookmarked ? 1 : 0,
            'name' => $combo->name,
            'description' => $combo->description,
            'price' => $combo->price,
            'rating' => round($avgRating, 1),
            'rating_count' => (int) $ratingCount,
            'product_count' => $combo->products->count(),
            'type' => $combo->type,
            'category_type' => $category_type_data,
            'status' => $combo->status ?? 1,
            'image_url' => $combo->image_url,
            'banner_video_url' => $banner_video_url,
            'banner_video_duration' => $banner_video_duration,
            'total_products_price' => $totalProductPrice,
            'total_actual_price' => $totalActualPrice,
            'discount_percentage' => $discountPercentage,
            'currency' => $currency,
            'created_at' => $combo->created_at,
            'updated_at' => $combo->updated_at,
            'stores' => $combo->products->groupBy('store_id')->map(function ($storeProducts) use ($currency) {
                $store = $storeProducts->first()->store;

                return [
                    'store_id' => $store->id ?? null,
                    'store_name' => $store->name ?? 'Unknown Store',
                    'products' => $storeProducts->map(function ($product) use ($currency) {
                        $variant = $product->variants->firstWhere('id', $product->pivot->variant_id);

                        // Get product rating data (is_combo = 0 for individual products)
                        $productRatingData = DB::table('product_ratings')
                            ->where('is_combo', 0)
                            ->where('product_id', $product->id)
                            ->selectRaw('COUNT(*) as rating_count, AVG(rate) as avg_rating')
                            ->first();

                        $productRatingCount = $productRatingData->rating_count ?? 0;
                        $productAvgRating = $productRatingData->avg_rating ?? 0;

                        return [
                            'product_id' => $product->id,
                            'product_name' => $product->name,
                            'product_image' => $product->image_url ?? null,
                            'variant_id' => $product->pivot->variant_id,
                            'variant_measurement' => $variant->measurement ?? null,
                            'variant_unit' => $variant->unit->short_code ?? null,
                            'variant_stock' => $variant->stock ?? 0,
                            'price' => $variant
                                ? ($variant->discounted_price > 0 ? $variant->discounted_price : $variant->price)
                                : 0,
                            'actual_price' => $variant->price ?? 0,
                            'quantity' => $product->pivot->quantity,
                            'rating' => round($productAvgRating, 1),
                            'rating_count' => (int) $productRatingCount,
                            'currency' => $currency,
                            'images' => $product->images->map(function ($image) {
                                return [
                                    'id' => $image->id,
                                    'image_url' => $image->image ? (str_starts_with($image->image, 'http') ? $image->image : asset('storage/' . $image->image)) : null,
                                ];
                            }),
                            'variants' => $product->variants->map(function ($variantItem) use ($currency) {
                                return [
                                    'id' => $variantItem->id,
                                    'measurement' => $variantItem->measurement ?? null,
                                    'unit' => $variantItem->unit->short_code ?? null,
                                    'stock' => $variantItem->stock ?? 0,
                                    'price' => $variantItem->discounted_price > 0 ? $variantItem->discounted_price : $variantItem->price,
                                    'actual_price' => $variantItem->price ?? 0,
                                    'discounted_price' => $variantItem->discounted_price ?? 0,
                                    'currency' => $currency,
                                ];
                            }),
                        ];
                    })->values(),
                ];
            })->values(),

            'ratings' => $ratings,
        ];

        return response()->json([
            'status' => 1,
            'message' => 'success',
            'data' => $comboData,
        ]);
    }

    public function storeCustomComboCart(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'combo_id' => 'required|integer|exists:combos,id',
            'products' => 'required|array|min:1',
            'products.*.product_id' => 'required|integer|exists:products,id',
            'products.*.variant_id' => 'required|integer|exists:product_variants,id',
            'products.*.quantity' => 'required|integer|min:1',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError(implode(', ', $validator->errors()->all()));
        }

        try {

            $user = $request->user('api-customers');

            if (!$user) {
                return response()->json([
                    'status' => 0,
                    'message' => 'User not found or unauthorized'
                ], 404);
            }

            $user_id = $user->id;

            // Check if user has pre-order items in cart
            $hasPreOrderItems = DB::table('carts')
                ->join('products', 'carts.product_id', '=', 'products.id')
                ->where('carts.user_id', $user_id)
                ->where('carts.save_for_later', 0)
                ->where('products.is_pre_order_item', 1)
                ->exists();

            if ($hasPreOrderItems) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Cannot add combo when pre-order items are in your cart. Please clear your cart or complete your pre-order first.',
                    'pre_order_conflict' => 1
                ], 400);
            }

            $existingCart = DB::table('combo_custom_cart')
                ->where('combo_id', $request->combo_id)
                ->where('user_id', $user_id)
                ->where('is_ordered', 0)
                ->first();

            if ($existingCart) {
                // Update existing cart - delete old products and add new ones
                DB::table('combo_custom_products')
                    ->where('combo_custom_id', $existingCart->id)
                    ->delete();

                // Add new products
                foreach ($request->products as $product) {
                    DB::table('combo_custom_products')->insert([
                        'combo_custom_id' => $existingCart->id,
                        'product_id' => $product['product_id'],
                        'variant_id' => $product['variant_id'],
                        'quantity' => $product['quantity'],
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }

                return response()->json([
                    'status' => 1,
                    'message' => 'Custom combo cart updated successfully',
                    'data' => [
                        'combo_custom_cart_id' => $existingCart->id,
                    ],
                ]);
            }

            // Create new cart entry
            $cartId = DB::table('combo_custom_cart')->insertGetId([
                'combo_id' => $request->combo_id,
                'user_id' => $user_id,
                'is_ordered' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // Add products to cart
            foreach ($request->products as $product) {
                DB::table('combo_custom_products')->insert([
                    'combo_custom_id' => $cartId,
                    'product_id' => $product['product_id'],
                    'variant_id' => $product['variant_id'],
                    'quantity' => $product['quantity'],
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            return response()->json([
                'status' => 1,
                'message' => 'Custom combo cart created successfully',
                'data' => [
                    'combo_custom_cart_id' => $cartId,
                ],
            ]);

        } catch (\Exception $e) {
            return CommonHelper::responseError('Failed to save custom combo cart: ' . $e->getMessage());
        }
    }

    public function deleteCustomComboCart(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'combo_id' => 'required|integer|exists:combos,id',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError(implode(', ', $validator->errors()->all()));
        }

        try {
            $user = $request->user('api-customers');

            if (!$user) {
                return response()->json([
                    'status' => 0,
                    'message' => 'User not found or unauthorized'
                ], 404);
            }

            $user_id = $user->id;

            // Check if custom cart exists for this user and combo
            $customCart = DB::table('combo_custom_cart')
                ->where('combo_id', $request->combo_id)
                ->where('user_id', $user_id)
                ->where('is_ordered', 0)
                ->first();

            if (!$customCart) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Custom combo cart not found'
                ], 404);
            }

            // Delete the custom cart (cascade will delete related products)
            DB::table('combo_custom_cart')
                ->where('id', $customCart->id)
                ->delete();

            return response()->json([
                'status' => 1,
                'message' => 'Custom combo cart deleted successfully',
            ]);

        } catch (\Exception $e) {
            return CommonHelper::responseError('Failed to delete custom combo cart: ' . $e->getMessage());
        }
    }


    public function addSingleCustomComboProduct(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'combo_id'   => 'required|integer|exists:combos,id',
            'product_id'=> 'required|integer|exists:products,id',
            'variant_id'=> 'required|integer|exists:product_variants,id',
            'quantity'  => 'required|integer|min:1',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError(implode(', ', $validator->errors()->all()));
        }

        try {

            $user = $request->user('api-customers');

            if (!$user) {
                return response()->json([
                    'status' => 0,
                    'message' => 'User not found or unauthorized'
                ], 404);
            }

            $user_id = $user->id;

            // Check if user has pre-order items in cart
            $hasPreOrderItems = DB::table('carts')
                ->join('products', 'carts.product_id', '=', 'products.id')
                ->where('carts.user_id', $user_id)
                ->where('carts.save_for_later', 0)
                ->where('products.is_pre_order_item', 1)
                ->exists();

            if ($hasPreOrderItems) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Cannot add combo when pre-order items are in your cart. Please clear your cart or complete your pre-order first.',
                    'pre_order_conflict' => 1
                ], 400);
            }

            // ✅ Find existing custom cart for this combo
            $customCart = DB::table('combo_custom_cart')
                ->where('combo_id', $request->combo_id)
                ->where('user_id', $user_id)
                ->where('is_ordered', 0)
                ->first();

            // ✅ If cart does NOT exist, create it
            if (!$customCart) {
                $customCartId = DB::table('combo_custom_cart')->insertGetId([
                    'combo_id'   => $request->combo_id,
                    'user_id'    => $user_id,
                    'is_ordered'=> 0,
                    'created_at'=> now(),
                    'updated_at'=> now(),
                ]);
            } else {
                $customCartId = $customCart->id;
            }

            // ✅ Check if product already exists in custom cart
            $existingProduct = DB::table('combo_custom_products')
                ->where('combo_custom_id', $customCartId)
                ->where('product_id', $request->product_id)
                ->first();

            if ($existingProduct) {
                // ✅ UPDATE quantity & variant
                DB::table('combo_custom_products')
                    ->where('id', $existingProduct->id)
                    ->update([
                        'variant_id' => $request->variant_id,
                        'quantity'   => $request->quantity,
                        'updated_at'=> now(),
                    ]);

                $message = 'Product updated in custom combo';
            } else {
                // ✅ INSERT new product
                DB::table('combo_custom_products')->insert([
                    'combo_custom_id' => $customCartId,
                    'product_id'      => $request->product_id,
                    'variant_id'      => $request->variant_id,
                    'quantity'        => $request->quantity,
                    'created_at'      => now(),
                    'updated_at'      => now(),
                ]);

                $message = 'Product added to custom combo';
            }

            return response()->json([
                'status'  => 1,
                'message' => $message,
                'data'    => [
                    'combo_custom_cart_id' => $customCartId
                ]
            ]);

        } catch (\Exception $e) {
            return CommonHelper::responseError(
                'Failed to add product to custom combo: ' . $e->getMessage()
            );
        }
    }


    public function deleteSingleCustomComboProduct(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'combo_id' => 'required|integer|exists:combo_custom_cart,combo_id',
            'product_id'      => 'required|integer|exists:products,id',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError(implode(', ', $validator->errors()->all()));
        }

        try {

            $user = $request->user('api-customers');

            if (!$user) {
                return response()->json([
                    'status' => 0,
                    'message' => 'User not found or unauthorized'
                ], 404);
            }

            $user_id = $user->id;

            // ✅ Verify cart belongs to user & not ordered
            $customCart = DB::table('combo_custom_cart')
                ->where('combo_id', $request->combo_id)
                ->where('user_id', $user_id)
                ->where('is_ordered', 0)
                ->first();

            if (!$customCart) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Custom combo cart not found or already ordered'
                ], 404);
            }

            // ✅ Delete the product
            $deleted = DB::table('combo_custom_products')
                ->where('combo_custom_id', $customCart->id)
                ->where('product_id', $request->product_id)
                ->delete();

            if (!$deleted) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Product not found in custom combo'
                ], 404);
            }

            // ✅ CHECK IF CART IS EMPTY AFTER DELETION
            $remainingProductsCount = DB::table('combo_custom_products')
                ->where('combo_custom_id', $customCart->id)
                ->count();

            if ($remainingProductsCount == 0) {
                // ✅ Delete cart itself
                DB::table('combo_custom_cart')
                    ->where('id', $customCart->id)
                    ->delete();

                return response()->json([
                    'status'  => 1,
                    'message' => 'Product removed and empty custom combo deleted successfully',
                    'data' => [
                        'combo_deleted' => 1
                    ]
                ]);
            }

            // ✅ Normal success if cart still has products
            return response()->json([
                'status'  => 1,
                'message' => 'Product removed from custom combo successfully',
                'data' => [
                    'combo_deleted' => 0
                ]
            ]);

        } catch (\Exception $e) {
            return CommonHelper::responseError(
                'Failed to delete product from custom combo: ' . $e->getMessage()
            );
        }
    }

}
