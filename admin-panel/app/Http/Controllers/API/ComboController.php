<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Combo;
use App\Models\ComboType;
use App\Models\ComboCategory;
use App\Models\Product;
use App\Models\Setting;
use App\Models\Unit;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class ComboController extends Controller
{
    // Fetch all combos (for listing)
    public function getCombos(Request $request)
    {
        $combos = Combo::with('products')->orderBy('id', 'desc')->get();

        $combos->transform(function($combo) {
            $combo->image_url = $combo->image ? (str_starts_with($combo->image, 'http') ? $combo->image : asset('storage/' . $combo->image)) : asset('images/no-image.png');
            $combo->products->transform(function($product) {
                $product->image_url = $product->image ? (str_starts_with($product->image, 'http') ? $product->image : asset('storage/' . $product->image)) : asset('images/no-image.png');
                $product->quantity = $product->pivot->quantity ?? 0;
                unset($product->pivot);
                return $product;
            });
            return $combo;
        });

        return response()->json($combos);
    }

     public function getCombosWithVarient(Request $request)
    {
        $currency = Setting::get_value('currency');

        $combos = Product::with('variants')->get();

        $combosWithTotal = $combos->map(function ($combo) use ($currency) {
            $totalProductPrice = $combo->products->sum(function ($product) {
                $price = $product->variants->first()->final_price ?? 0;
                return $price * ($product->pivot->quantity ?? 1);
            });

            // calculate discount percentage safely
            $discountPercentage = $totalProductPrice > 0
                ? round((($totalProductPrice - $combo->price) / $totalProductPrice) * 100, 2)
                : 0;

            return [
                'combo_id' => $combo->id,
                'combo_name' => $combo->name,
                'combo_price' => $combo->price,
                'combo_image' => $combo->image,
                'combo_type' => $combo->type,
                'total_products_price' => $totalProductPrice,
                'discount' => ceil($discountPercentage), // % discount
                'currency' => $currency,
                'products' => $combo->products->map(function ($product) use ($currency) {
                    $price = $product->variants->first()->final_price ?? 0;
                    return [
                        'product_id' => $product->id,
                        'product_name' => $product->name,
                        'price' => $price,
                        'quantity' => $product->pivot->quantity,
                    ];
                }),
            ];
        });

        if ($combosWithTotal->isNotEmpty()) {
            return response()->json([
                'status' => 1,
                'message' => 'success',
                'data' => $combosWithTotal
            ]);
        } else {
            return CommonHelper::responseError(__('no_products_found'));
        }
    }

    // public function getProductsForCombo()
    // {
    //     $products = Product::with('variants', 'variants.unit')
    //         ->get()
    //         ->map(function ($p) {
    //             $p->image_url = $p->image
    //                 ? asset('storage/' . $p->image)
    //                 : asset('images/no-image.png');
    //             return $p;
    //         });

    //     return response()->json(['products' => $products]);
    // }


    public function getProductsForCombo(Request $request)
    {
        $storeIds = [];

        if ($request->store_ids) {
            $storeIds = array_filter(explode(',', $request->store_ids));
        }

        $brandId = $request->brand_id;
        $categoryGroupId = $request->category_group_id;
        $subCategoryGroupId = $request->sub_category_group_id;
        $categoryId = $request->category_id;

        // Build category IDs array based on filters
        $categoryIds = [];

        if ($categoryId) {
            // Specific category selected
            $categoryIds = [$categoryId];
        } elseif ($subCategoryGroupId) {
            // Sub category group selected - get all categories in it
            $subCatGroup = \App\Models\SubCategoryGroup::find($subCategoryGroupId);
            if ($subCatGroup && $subCatGroup->subcategory_ids) {
                $categoryIds = array_filter(explode(',', $subCatGroup->subcategory_ids));
            }
        } elseif ($categoryGroupId) {
            // Category group selected - get all categories from all sub category groups
            $subCatGroups = \App\Models\SubCategoryGroup::where('category_group_id', $categoryGroupId)->get();
            foreach ($subCatGroups as $subCatGroup) {
                if ($subCatGroup->subcategory_ids) {
                    $ids = array_filter(explode(',', $subCatGroup->subcategory_ids));
                    $categoryIds = array_merge($categoryIds, $ids);
                }
            }
            $categoryIds = array_unique($categoryIds);
        }

        $products = Product::with('variants', 'variants.unit')
            ->when(!empty($storeIds), function ($q) use ($storeIds) {
                $q->whereIn('store_id', $storeIds);
            })
            ->when(!empty($brandId), function ($q) use ($brandId) {
                $q->where('brand_id', $brandId);
            })
            ->when(!empty($categoryIds), function ($q) use ($categoryIds) {
                $q->whereIn('category_id', $categoryIds);
            })
            ->get()
            ->map(function ($p) {
                // Check if image is already a full URL
                if ($p->image) {
                    if (filter_var($p->image, FILTER_VALIDATE_URL)) {
                        $p->image_url = $p->image;
                    } else {
                        $p->image_url = asset('storage/' . $p->image);
                    }
                } else {
                    $p->image_url = asset('images/no-image.png');
                }
                return $p;
            });

        return response()->json([
            'products' => $products
        ]);
    }


    // public function edit($id)
    // {
    //     $combo = Combo::with('products')->findOrFail($id);
    //     $allProducts = Product::all()->map(function($p) {
    //         $p->image_url = $p->image ? asset('storage/' . $p->image) : asset('images/no-image.png');
    //         return $p;
    //     });

    //     // Attach quantities to products
    //     $quantities = $combo->products->pluck('pivot.quantity', 'id');

    //     $allProducts->transform(function($p) use ($quantities) {
    //         $p->quantity = $quantities[$p->id] ?? 0;
    //         return $p;
    //     });

    //     return response()->json([
    //         'combo' => $combo,
    //         'products' => $allProducts
    //     ]);
    // }

    public function edit($id)
    {
        $combo = Combo::with('products')->findOrFail($id);

        // Add image URL
        $combo->image_url = $combo->image
            ? (str_starts_with($combo->image, 'http') ? $combo->image : asset('storage/' . $combo->image))
            : null;

        // Add video URL
        $combo->video_url = $combo->banner_video
            ? (str_starts_with($combo->banner_video, 'http') ? $combo->banner_video : asset('storage/' . $combo->banner_video))
            : null;

        $allProducts = Product::with('variants', 'variants.unit')
            ->when($combo->store_id, function ($q) use ($combo) {
                $q->where('store_id', $combo->store_id);
            })
            ->get()
            ->map(function ($p) {
                $p->image_url = $p->image
                    ? (str_starts_with($p->image, 'http') ? $p->image : asset('storage/' . $p->image))
                    : asset('images/no-image.png');
                return $p;
            });

        // Attach quantities to products
        $quantities = $combo->products->pluck('pivot.quantity', 'id');

        $allProducts->transform(function ($p) use ($quantities) {
            $p->quantity = $quantities[$p->id] ?? 0;
            return $p;
        });

        return response()->json([
            'combo'    => $combo,
            'products' => $allProducts
        ]);
    }


    
    public function save(Request $request, $id = null)
    {

        // dd($request->all());



        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'price' => 'nullable|numeric|min:0',
            'type_id' => 'required|integer|exists:combo_types,id',
            'status' => 'required|boolean',
            'description' => 'nullable|string|max:1000',
            'product_ids' => 'required|array|min:1',
            'product_ids.*' => 'integer|exists:products,id',
            'quantities' => 'required|array',
            'quantities.*' => 'required|integer|min:1',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:5120',
            'banner_video' => 'nullable|mimes:mp4,avi,mov,wmv|max:20480',
        ], [
            'name.required' => 'Combo name is required',
            'type_id.required' => 'Please select a combo type',
            'type_id.exists' => 'Selected combo type is invalid',
            'product_ids.required' => 'Please select at least one product',
            'product_ids.min' => 'Please select at least one product',
            'product_ids.*.exists' => 'One or more selected products are invalid',
            'quantities.*.min' => 'Product quantity must be at least 1',
            'image.image' => 'The file must be an image',
            'image.max' => 'Image size must not exceed 5MB',
            'banner_video.mimes' => 'Video must be mp4, avi, mov, or wmv format',
            'banner_video.max' => 'Video size must not exceed 20MB',
        ]);

        // Get existing combo if updating
        $existingCombo = $id ? Combo::find($id) : null;

        // Handle image upload using MediaUploadService
        $imagePath = null;
        if ($request->hasFile('image')) {
            try {
                $imagePath = MediaUploadService::upload(
                    $request->file('image'),
                    'combos',
                    'public',
                    $existingCombo?->image
                );
            } catch (\Exception $e) {
                return response()->json([
                    'status' => 0,
                    'message' => $e->getMessage()
                ], 400);
            }
        }

        // Handle video upload using MediaUploadService
        $videoPath = null;
        if ($request->hasFile('banner_video')) {
            try {
                $videoPath = MediaUploadService::upload(
                    $request->file('banner_video'),
                    'combos/videos',
                    'public',
                    $existingCombo?->banner_video
                );
            } catch (\Exception $e) {
                return response()->json([
                    'status' => 0,
                    'message' => $e->getMessage()
                ], 400);
            }
        }

        $type_name = ComboType::where('id', $request->type_id)->value('name_of_type');

        $combo = Combo::updateOrCreate(
            ['id' => $id],
            [
                'name' => $request->name,
                'price' => $request->price ?? 0,
                'type' => $type_name,
                'type_id' => $request->type_id,
                'category_type' => $request->category_id,
                'store_id' => $request->store_ids,
                'status' => $request->status,
                'description' => $request->description,
                'image' => $imagePath ?? $existingCombo?->image,
                'banner_video' => $videoPath ?? $existingCombo?->banner_video,
            ]
        );

        // Build pivot data
        $syncData = [];
        foreach ($request->product_ids as $pid) {
            $syncData[$pid] = [
                'variant_id' => $request->variant_ids[$pid] ?? null,
                'quantity' => $request->quantities[$pid] ?? 1,
            ];
        }

        // Sync combo products
        $combo->products()->sync($syncData);

        return response()->json([
            'status' => 1,
            'message' => $id ? 'Combo updated successfully!' : 'Combo created successfully!',
            'combo' => $combo->load('products.variants'),
        ]);
    }


    public function destroy(Request $request)
    {
        $combo = Combo::findOrFail($request->id);

        // Delete image if exists
        if ($combo->image) {
            Storage::disk('public')->delete($combo->image);
        }

        // Delete video if exists
        if ($combo->banner_video) {
            Storage::disk('public')->delete($combo->banner_video);
        }

        $combo->delete();

        return response()->json(['status' => 1, 'message' => 'Combo deleted successfully']);
    }

    // Change combo status
    public function changeStatus(Request $request)
    {
        $combo = Combo::findOrFail($request->id);
        $combo->status = $request->status;
        $combo->save();

        return response()->json(['status' => 1, 'message' => 'Status updated']);
    }

    public function editOrAddComboType(Request $request)
    {
        $name_of_type = $request->name_of_type;
        $id = $request->type_id;

        // dd($request->all());

        if($id == null){
            ComboType::create([
                'name_of_type' => $name_of_type
            ]);
        }

        ComboType::where('id',$id)->update([
            'name_of_type' => $name_of_type,
        ]);


        // return redirect()->back()->with([
        //     'status' => true, 
        //     'message' => 'Success'
        // ]);
        
        return response()->json([
            'status' => true
        ]);

    }


    public function deleteComboType(Request $request)
    {
        $id = $request->type_id;

        // dd($request->all());

        ComboType::destroy($id);
        
        return response()->json([
            'status' => true
        ]);

    }


    public function deleteComboCategory(Request $request)
    {
        $id = $request->type_id;

        // dd($request->all());

        ComboCategory::destroy($id);
        
        return response()->json([
            'status' => true
        ]);

    }


    public function editOrAddComboCatgeory(Request $request)
    {
        $name_of_type = $request->name_of_category;
        $id = $request->type_id;

        // dd($request->all());

        if($id == null){
            ComboCategory::create([
                'name' => $name_of_type
            ]);
        }

        ComboCategory::where('id',$id)->update([
            'name' => $name_of_type,
        ]);


        // return redirect()->back()->with([
        //     'status' => true, 
        //     'message' => 'Success'
        // ]);
        
        return response()->json([
            'status' => true
        ]);

    }
    

    public function getAllTypesCombos(Request $request)
    {

        $all_combo_types = ComboType::get();

        return response()->json([
            'status' => true,
            'data' => $all_combo_types
        ]);

    }

    public function getAllCategoriesCombos(Request $request)
    {

        $all_combo_categories = ComboCategory::get();

        return response()->json([
            'status' => true,
            'data' => $all_combo_categories
        ]);

    }

}
