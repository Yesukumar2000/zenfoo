<?php

namespace App\Http\Controllers;

use App\Models\CategoryType;
use App\Models\Category;
use App\Models\Brand;
use App\Models\Unit;
use App\Models\Seller;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\OrderItem;
use App\Models\Store;
use App\Models\Setting;
use App\Models\Bookmark;

use Illuminate\Support\Facades\Log;

use Illuminate\Validation\Rule;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use App\Helpers\CommonHelper;
use App\Models\ProductImages;
use App\Services\MediaUploadService;
use App\Services\StoreDistanceService;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CategoryTypeController extends Controller
{
    /**
     * Normalize whatever the client sends for "tags" into a short, comma-separated
     * list of tag names suitable for the products.tags VARCHAR(255) column.
     *
     * The vendor app loads the `tags` relationship (array of tag objects) and may
     * round-trip it back as the `tags` field, e.g.
     *   "[{id: 24, name: Test, created_at: ...}, {id: 25, name: product, ...}]"
     * Storing that raw string overflows the column ("Data too long for column 'tags'").
     * This extracts just the names and caps the length.
     */
    private function normalizeTags($tags): string
    {
        if (empty($tags)) {
            return "";
        }

        $names = [];

        // Already an array (e.g. tags[]=foo or array of objects).
        if (is_array($tags)) {
            foreach ($tags as $tag) {
                if (is_array($tag)) {
                    $names[] = $tag['name'] ?? '';
                } else {
                    $names[] = (string) $tag;
                }
            }
        } else {
            $value = trim((string) $tags);

            // Looks like a serialized list/object of tag objects.
            if (preg_match('/[\[{]/', $value) && str_contains($value, 'name')) {
                // Try strict JSON first.
                $decoded = json_decode($value, true);
                if (is_array($decoded)) {
                    foreach ($decoded as $tag) {
                        if (is_array($tag)) {
                            $names[] = $tag['name'] ?? '';
                        } else {
                            $names[] = (string) $tag;
                        }
                    }
                } else {
                    // Fall back to extracting "name: X" pairs from the loose
                    // (non-JSON, Dart/JS-style) string the app sends.
                    if (preg_match_all('/name:\s*([^,}\]]+)/', $value, $matches)) {
                        $names = $matches[1];
                    }
                }
            } else {
                // Plain comma-separated string of names — keep as-is.
                $names = explode(',', $value);
            }
        }

        $names = array_filter(array_map('trim', $names), fn($n) => $n !== '');
        $result = implode(',', array_unique($names));

        // Guard against any remaining overflow of the VARCHAR(255) column.
        return mb_substr($result, 0, 255);
    }

    public function getAll(Request $request)
    {

        $query = CategoryType::query();

        if ($request->has('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        $data = $this->applyPaginationAndSearch($query, $request, ['name']);

        return response()->json([
            "success" => true,
            "data" => $data,
        ]);
    }





    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'category_id' => 'required|exists:categories,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 0,
                'message' => $validator->errors()->first()
            ]);
        }

        $type = CategoryType::create([
            'name' => $request->name,
            'category_id' => $request->category_id,
        ]);

        return response()->json([
            'status' => 1,
            'message' => 'Category Type Created Successfully',
            'data' => $type
        ]);
    }

    /**
     * Update a category type
     */
    public function update(Request $request, $id)
    {
        $type = CategoryType::find($id);

        if (!$type) {
            return response()->json([
                'status' => 0,
                'message' => 'Category Type Not Found'
            ]);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'category_id' => 'required|exists:categories,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 0,
                'message' => $validator->errors()->first()
            ]);
        }

        $type->update([
            'name' => $request->name,
            'category_id' => $request->category_id
        ]);

        return response()->json([
            'status' => 1,
            'message' => 'Category Type Updated Successfully',
            'data' => $type
        ]);
    }

    /**
     * Delete a category type
     */
    public function destroy($id)
    {
        $type = CategoryType::find($id);

        if (!$type) {
            return response()->json([
                'status' => 0,
                'message' => 'Category Type Not Found'
            ]);
        }

        $type->delete();

        return response()->json([
            'status' => 1,
            'message' => 'Category Type Deleted Successfully'
        ]);
    }



    public function getAllBrands(Request $request)
    {
        $query = Brand::when(
            $request->has('category_id'),
            fn($q) => $q->whereJsonContains('category_ids', (int) $request->category_id)
        );

        $data = $this->applyPaginationAndSearch($query, $request, ['name']);

        return response()->json([
            "success" => true,
            "data" => $data,
        ]);
    }




    public function getAllUnits(Request $request)
    {
        $query = Unit::query();

        $data = $this->applyPaginationAndSearch($query, $request, ['name']);

        return response()->json([
            "success" => true,
            "data" => $data,
        ]);
    }

    private function applyPaginationAndSearch($query, Request $request, $searchFields = [])
    {
        if ($request->has('search') && $request->search !== '') {
            $search = $request->search;

            $query->where(function ($q) use ($search, $searchFields) {
                foreach ($searchFields as $field) {
                    $q->orWhere($field, 'LIKE', "%{$search}%");
                }
            });
        }

        $perPage = $request->input('per_page', 10);

        return $query->paginate($perPage);
    }



    public function saveProductSeller(Request $request)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller_data_for_id = Seller::where('admin_id', $admin->id)->first();

        // $seller_data_for_id = Seller::where('admin_id', 10)->first();

        if (!$seller_data_for_id) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        // Make category_group_id and sub_category_group_id optional for store_id 15
        $categoryGroupRules = $request->store_id == 15 ? 'nullable' : 'required';

        // Make brand_id optional for all stores
        $brandRules = 'nullable';
        $madeInRules = $request->store_id == 15 ? 'nullable|string' : 'required|string';
        $manufacturerRules = 'nullable';
        $taxRules = 'nullable';

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'store_id' => 'required|integer',
            'category_id' => 'required|integer',
            'category_group_id' => $categoryGroupRules,
            'sub_category_group_id' => $categoryGroupRules,
            'item_type_id' => 'required|integer',
            'brand_id' => $brandRules,
            'description' => 'required|string',
            'tags' => 'nullable',
            'made_in' => $madeInRules,
            'other_info' => 'nullable',
            'manufacturer' => $manufacturerRules,
            'tax' => $taxRules,
            'fssai_lic_no' => 'nullable',
            'is_unlimited_stock' => 'required|in:0,1',
            'type' => 'required|in:packet,loose',
            'return_status' => 'required|in:0,1',
            'cancelable_status' => 'required|in:0,1',
            'till_status' => [
                'nullable',
                function ($attribute, $value, $fail) use ($request) {
                    if ($request->cancelable_status == 1) {
                        if ($value === null || $value === '') {
                            $fail('Till status is required when cancelable is enabled.');
                        } elseif (!in_array((int)$value, [2, 3])) {
                            $fail('Till status must be Received (2) or Processed (3).');
                        }
                    }
                },
            ],
            'total_allowed_quantity' => 'nullable|numeric|min:1',

            'packet_measurement.*' => ['required_if:type,packet', 'numeric', Rule::notIn([0]),],
            'packet_price.*' => ['required_if:type,packet', 'numeric', 'min:0.01'],
            'discounted_price.*' => [
                'required_if:type,packet',
                'numeric',
                'min:0',
                function ($attribute, $value, $fail) use ($request) {
                    $index = explode('.', $attribute)[1];
                    $price = $request->input("packet_price.{$index}");
                    if (is_numeric($value) && is_numeric($price) && (float)$value >= (float)$price) {
                        $fail('Discounted price must be less than the price (Rs. ' . $price . ').');
                    }
                },
            ],
            'packet_status.*' => ['required_if:type,packet', 'in:0,1'],
            'packet_stock.*' => [
                'required_if:type,packet',
                'numeric',
                function ($attribute, $value, $fail) use ($request) {
                    $index = explode('.', $attribute)[1];
                    $status = $request->input("packet_status.{$index}", 1);

                    if ($request->input('is_unlimited_stock') == 0 && $value == 0 && $request->input('type') == 'packet' && $status != 0) {
                        $fail($attribute . ' must be greater than 0 when is_unlimited_stock is 0 and status is not "Sold Out".');
                    }
                },
            ],
            'packet_stock_unit_id.*' => ['required_if:type,packet', 'numeric'],

            'loose_measurement.*' => ['required_if:type,loose', 'numeric', Rule::notIn([0]),],
            'loose_price.*' => ['required_if:type,loose', 'numeric', 'min:0.01'],
            'loose_discounted_price.*' => [
                'required_if:type,loose',
                'numeric',
                'min:0',
                function ($attribute, $value, $fail) use ($request) {
                    $index = explode('.', $attribute)[1];
                    $price = $request->input("loose_price.{$index}");
                    if (is_numeric($value) && is_numeric($price) && (float)$value >= (float)$price) {
                        $fail('Discounted price must be less than the price (Rs. ' . $price . ').');
                    }
                },
            ],
            'loose_status.*' => ['required_if:type,loose', 'in:0,1'],
            'loose_stock.*' => [
                'required_if:type,loose',
                'numeric',
                function ($attribute, $value, $fail) use ($request) {
                    $index = explode('.', $attribute)[1];
                    $status = $request->input('status', $request->input("loose_status.{$index}", 1));

                    if ($request->input('is_unlimited_stock') == 0 && strval($value) === '0' && $request->input('type') == 'loose' && intval($status) !== 0) {
                        $fail($attribute . ' must be greater than 0 when is_unlimited_stock is 0 and status is not "Sold Out".');
                    }
                },
            ],
            'loose_stock_unit_id' => ['required_if:type,loose', 'nullable', 'numeric'],

            'barcode' => 'nullable|unique:products,barcode',
            'indicator' => 'nullable|integer|in:1,2',
            'return_days' => [
                'nullable',
                function ($attribute, $value, $fail) use ($request) {
                    if ($request->return_status == 1) {
                        if ($value === null || $value === '') {
                            $fail('Return days is required when returnable is enabled.');
                        } elseif (!is_numeric($value) || (int)$value <= 0) {
                            $fail('Return days must be a valid number (e.g. 7). Values like "1hr", "2hr" are not allowed.');
                        }
                    } elseif ($value !== null && $value !== '' && $value !== '0' && !is_numeric($value)) {
                        $fail('Return days must be a valid number.');
                    }
                },
            ],
        ], [
            'name.required' => 'The Product Name is required.',
            'name.max' => 'The Product Name must not exceed 255 characters.',
            'category_id.required' => 'The Category name field is required.',
            'store_id.required' => 'The Store Selection is required.',
            'sub_category_group_id.required' => 'The Sub Category Group is required.',
            'category_group_id.required' => 'The Category Group is required.',
            'is_unlimited_stock.in' => 'Unlimited stock must be 0 (No) or 1 (Yes).',
            'type.in' => 'Product type must be "packet" or "loose".',
            'return_status.required' => 'Return status is required.',
            'return_status.in' => 'Return status must be 0 (No) or 1 (Yes).',
            'cancelable_status.required' => 'Cancelable status is required.',
            'cancelable_status.in' => 'Cancelable status must be 0 (No) or 1 (Yes).',
            'total_allowed_quantity.numeric' => 'Total allowed quantity must be a number.',
            'total_allowed_quantity.min' => 'Total allowed quantity must be at least 1.',

            'packet_measurement.*.required_if' => 'The Packet Measurement is required when the type is "Packet".',
            'packet_measurement.*.numeric' => 'The Packet Measurement must be a number.',
            'packet_measurement.*.not_in' => 'The Packet Measurement must not be zero.',
            'packet_price.*.min' => 'The Packet Price must be greater than 0.',
            'packet_stock.*.required_if' => 'The Packet Stock is required when the type is "Packet".',
            'packet_stock.*.not_in' => 'The Packet Stock must not be zero.',
            'packet_stock_unit_id.*.required_if' => 'The Packet Stock Unit is required when the type is "Packet".',
            'discounted_price.*.numeric' => 'The Discounted Price must be a number.',

            'loose_measurement.*.required_if' => 'The Loose Measurement is required when the type is "Loose".',
            'loose_measurement.*.numeric' => 'The Loose Measurement must be a number.',
            'loose_measurement.*.not_in' => 'The Loose Measurement must not be zero.',
            'loose_price.*.min' => 'The Loose Price must be greater than 0.',
            'loose_discounted_price.*.numeric' => 'The Loose Discounted Price must be a number.',
            'loose_stock_unit_id.required_if' => 'The Loose Stock Unit is required when the type is "Loose".',
            'loose_stock_unit_id.numeric' => 'The Loose Stock Unit must be a number.',

        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $variations = array();
        if ($request->type == "packet") {
            foreach ($request->packet_measurement as $index => $item) {
                $data = array();
                $data['measurement'] = $request->packet_measurement[$index];
                $data['price'] = $request->packet_price[$index];
                $data['discounted_price'] = $request->discounted_price[$index];
                $data['status'] = $request->packet_status[$index];
                $data['stock'] = ($request->is_unlimited_stock == 0) ? $request->packet_stock[$index] : 0;

                $data['stock_unit_id'] = $request->packet_stock_unit_id[$index];
                $variations[] = $data;
            }
        } else {
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

        DB::beginTransaction();

        try {
            $slug = $request->slug ?: preg_replace(
                '/\s+/',
                '-',
                trim(
                    preg_replace('/[^\p{L}\p{N} ]/u', '', $request->name)
                )
            );

            $count = Product::where('slug', 'LIKE', "{$slug}%")->count();
            $row_order = Product::max('row_order') + 1;
            $product = new Product();
            $product->name = $request->name;
            $product->slug = $count ? "{$slug}-{$count}" : $slug;
            $product->row_order = $row_order;
            $product->cod_allowed = 1;
            $product->fssai_lic_no = $request->fssai_number ?? $request->fssai_lic_no ?? " ";
            $product->category_id = $request->category_id;
            // For store_id 15, category_group_id and sub_category_group_id are optional
            $product->category_group_id = $request->store_id == 15 ? ($request->category_group_id ?? null) : $request->category_group_id;
            $product->sub_category_group_id = $request->store_id == 15 ? ($request->sub_category_group_id ?? null) : $request->sub_category_group_id;
            $product->store_id = $request->store_id;
            // Fish-store (store 19) cut fields
            $product->is_cleaned = $request->is_cleaned ?? 0;
            $product->before_cleaning_weight = $request->before_cleaning_weight ?? null;
            $product->after_cleaning_weight = $request->after_cleaning_weight ?? null;
            $product->pieces = $request->pieces ?? null;
            $product->item_type_id = $request->item_type_id;
            $product->other_info = $request->other_info;
            $product->brand_id = $request->brand_id ?: null;
            $product->description = $request->description;
            $product->tags = $this->normalizeTags($request->tags);
            $product->made_in = $request->made_in ?? "";
            $product->manufacturer = $request->manufacturer ?: null;
            $product->tax = $request->tax ?: null;
            $product->seller_id = $seller_data_for_id->id;
            $product->type = $request->type;
            $product->is_unlimited_stock = $request->is_unlimited_stock ?? 0;
            $product->status = 1;
            $product->return_status = $request->return_status;
            $product->return_days = $request->return_days ?? 0;
            $product->cancelable_status = $request->cancelable_status;
            $product->till_status = $request->till_status;
            $product->total_allowed_quantity = $request->total_allowed_quantity ?? 100;
            $product->indicator = $request->indicator ?? 0;
            $product->meta_title = $request->meta_title ?? "";
            $product->meta_keywords = $request->meta_keywords ?? "";
            $product->schema_markup = $request->schema_markup ?? "";
            $product->meta_description = $request->meta_description ?? "";
            $image = '';
            if ($request->hasFile('image')) {
                try {
                    $image = MediaUploadService::uploadWithFullUrl($request->file('image'), 'products');
                } catch (\Exception $e) {
                    return CommonHelper::responseError("Image upload failed: " . $e->getMessage());
                }
            } else {
                $image = $request->image;
            }
            $product->image = $image;
            $product->save();


            if ($request->hasFile('other_images')) {
                CommonHelper::uploadProductImages($request->file('other_images'), $product->id);
            }

            /* Variants + Variant Images */
            Log::info('ADD PRODUCT - All file keys received', [
                'product_id' => $product->id,
                'file_keys' => array_keys($request->allFiles()),
            ]);

            if ($request->type == "packet") {
                foreach ($request->packet_measurement as $index => $item) {
                    $variant_id = ProductVariant::insertGetId([
                        'product_id' => $product->id,
                        'type' => $request->type,
                        'measurement' => $request->packet_measurement[$index],
                        'price' => $request->packet_price[$index],
                        'discounted_price' => $request->discounted_price[$index] ?? 0,
                        'status' => $request->packet_status[$index] ?? 1,
                        'stock' => ($request->is_unlimited_stock == 0) ? $request->packet_stock[$index] : 0,
                        'stock_unit_id' => $request->packet_stock_unit_id[$index] ?? 0,
                    ]);

                    $this->storeVariantImages($request, $product->id, $variant_id, 'packet', $index);
                }
            }

            if ($request->type == "loose") {
                foreach ($request->loose_measurement as $index => $item) {
                    $variant_id = ProductVariant::insertGetId([
                        'product_id' => $product->id,
                        'type' => $request->type,
                        'measurement' => $request->loose_measurement[$index],
                        'price' => $request->loose_price[$index],
                        'discounted_price' => $request->loose_discounted_price[$index] ?? 0,
                        'status' => $request->loose_status[$index] ?? 1,
                        'stock' => ($request->is_unlimited_stock == 0) ? $request->loose_stock[$index] : 0,
                        'stock_unit_id' => $request->loose_stock_unit_id,
                    ]);

                    $this->storeVariantImages($request, $product->id, $variant_id, 'loose', $index);
                }
            }



            $product = Product::find($product->id);

            DB::commit();
        } catch (\Exception $e) {
            Log::info("Error : " . $e->getMessage());
            DB::rollBack();
            // throw $e;
            return CommonHelper::responseError($e->getMessage());
        }

        return CommonHelper::responseSuccess("Product Saved Successfully!");
    }


    public function getSellerProducts(Request $request)
    {
        $admin = auth()->guard('api')->user();

        // dd($admin);

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = Seller::where('admin_id', $admin->id)->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        // Check if store is managed by admin
        $store = Store::where('id', $seller->store_id)->first();
        $isManagedByAdmin = $store && $store->managed_by_admin == 1;

        $productsQuery = Product::with([
            'variants.stockUnit',
            'variants.images',
            'brand',
            'categoryType',
            'category',
            'categoryGroup',
            'subCategoryGroup',
            'store',
            'images'
        ]);

        // If managed by admin, show all products in the store, otherwise show only seller's products
        if ($isManagedByAdmin) {
            $productsQuery->where('store_id', $seller->store_id);
        } else {
            $productsQuery->where('seller_id', $seller->id);
        }

        // Apply search filter (name, tags, description)
        if ($request->filled('search')) {
            $search = $request->search;
            $productsQuery->where(function ($query) use ($search) {
                $query->where('name', 'LIKE', "%{$search}%")
                    ->orWhere('tags', 'LIKE', "%{$search}%")
                    ->orWhere('description', 'LIKE', "%{$search}%");
            });
        }

        $products = $productsQuery->orderBy('id', 'desc')
            ->paginate($request->per_page ?? 10);

        return response()->json([
            'status' => 1,
            'message' => 'Seller Products Fetched Successfully',
            'data' => $products
        ]);
    }

    public function getSellerLowStockProducts(Request $request)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = Seller::where('admin_id', $admin->id)->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        $store = Store::where('id', $seller->store_id)->first();
        $isManagedByAdmin = $store && $store->managed_by_admin == 1;

        $lowStockLimit = Setting::get_value('low_stock_limit') ?: 20;

        $productsQuery = Product::with([
            'variants.stockUnit',
            'variants.images',
            'brand',
            'categoryType',
            'category',
            'categoryGroup',
            'subCategoryGroup',
            'store',
            'images'
        ])
        ->where('is_unlimited_stock', 0)
        ->whereHas('variants', function ($query) use ($lowStockLimit) {
            $query->where('stock', '>', 0)
                  ->where('stock', '<=', $lowStockLimit)
                  ->where('status', 1);
        });

        if ($isManagedByAdmin) {
            $productsQuery->where('store_id', $seller->store_id);
        } else {
            $productsQuery->where('seller_id', $seller->id);
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $productsQuery->where(function ($query) use ($search) {
                $query->where('name', 'LIKE', "%{$search}%")
                    ->orWhere('tags', 'LIKE', "%{$search}%")
                    ->orWhere('description', 'LIKE', "%{$search}%");
            });
        }

        $totalLowStockCount = $productsQuery->count();

        $products = $productsQuery->orderBy('id', 'desc')
            ->paginate($request->per_page ?? 5);

        return response()->json([
            'status' => 1,
            'message' => 'Low Stock Products Fetched Successfully',
            'total_low_stock_count' => $totalLowStockCount,
            'low_stock_limit' => (int) $lowStockLimit,
            'data' => $products
        ]);
    }

    public function getSellerSoldOutProducts(Request $request)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = Seller::where('admin_id', $admin->id)->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        $store = Store::where('id', $seller->store_id)->first();
        $isManagedByAdmin = $store && $store->managed_by_admin == 1;

        $productsQuery = Product::with([
            'variants.stockUnit',
            'variants.images',
            'brand',
            'categoryType',
            'category',
            'categoryGroup',
            'subCategoryGroup',
            'store',
            'images'
        ])
        ->where('is_unlimited_stock', 0)
        ->whereHas('variants', function ($query) {
            $query->where('stock', '<=', 0)
                  ->where('status', 0);
        });

        if ($isManagedByAdmin) {
            $productsQuery->where('store_id', $seller->store_id);
        } else {
            $productsQuery->where('seller_id', $seller->id);
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $productsQuery->where(function ($query) use ($search) {
                $query->where('name', 'LIKE', "%{$search}%")
                    ->orWhere('tags', 'LIKE', "%{$search}%")
                    ->orWhere('description', 'LIKE', "%{$search}%");
            });
        }

        $totalSoldOutCount = $productsQuery->count();

        $products = $productsQuery->orderBy('id', 'desc')
            ->paginate($request->per_page ?? 5);

        return response()->json([
            'status' => 1,
            'message' => 'Sold Out Products Fetched Successfully',
            'total_sold_out_count' => $totalSoldOutCount,
            'data' => $products
        ]);
    }

    public function getSweetshopProductsByCategory(Request $request)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = Seller::where('admin_id', $admin->id)->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        // Check if seller belongs to sweetshop (store_id = 15)
        if ($seller->store_id != 15) {
            return CommonHelper::responseError("This API is only available for sweetshop sellers.");
        }

        // Check if store is managed by admin
        $store = Store::where('id', $seller->store_id)->first();
        $isManagedByAdmin = $store && $store->managed_by_admin == 1;

        // Get all categories with types for this store
        $categoriesWithTypes = Category::where('seller_id', $seller->id)
            ->with([
                'categoryTypes' => function ($query) {
                    $query->select('id', 'name', 'category_id');
                }
            ])
            ->select('id', 'name', 'image')
            ->get()
            ->map(function ($category) {
                return [
                    'id' => $category->id,
                    'name' => $category->name,
                    'image_url' => $category->image_url,
                    'types' => $category->categoryTypes
                ];
            });

        // Get products query
        $productsQuery = Product::with([
            'variants.stockUnit',
            'variants.images',
            'brand',
            'categoryType',
            'category',
            'store',
            'images'
        ])->where('store_id', 15);

        // If managed by admin, show all products in the store, otherwise show only seller's products
        if (!$isManagedByAdmin) {
            $productsQuery->where('seller_id', $seller->id);
        }

        // Apply search filter (name, tags, description)
        if ($request->filled('search')) {
            $search = $request->search;
            $productsQuery->where(function ($query) use ($search) {
                $query->where('name', 'LIKE', "%{$search}%")
                    ->orWhere('tags', 'LIKE', "%{$search}%")
                    ->orWhere('description', 'LIKE', "%{$search}%");
            });
        }

        // Apply sorting — price_asc | price_desc | rating_asc | rating_desc | default
        $sortBy = $request->input('sort_by', 'default');

        switch ($sortBy) {
            case 'price_asc':
                $productsQuery->orderByRaw('(SELECT MIN(price) FROM product_variants WHERE product_variants.product_id = products.id) ASC');
                break;
            case 'price_desc':
                $productsQuery->orderByRaw('(SELECT MIN(price) FROM product_variants WHERE product_variants.product_id = products.id) DESC');
                break;
            case 'rating_asc':
                $productsQuery->orderByRaw('(SELECT COALESCE(AVG(rating), 0) FROM order_product_ratings WHERE order_product_ratings.product_id = products.id) ASC');
                break;
            case 'rating_desc':
                $productsQuery->orderByRaw('(SELECT COALESCE(AVG(rating), 0) FROM order_product_ratings WHERE order_product_ratings.product_id = products.id) DESC');
                break;
            default:
                $productsQuery->orderBy('category_id', 'asc')->orderBy('id', 'desc');
                break;
        }

        $products = $productsQuery->get();

        // Fetch avg ratings for all returned products in one efficient query
        $productIds = $products->pluck('id')->toArray();
        $ratingsMap = [];
        if (!empty($productIds)) {
            $ratings = \DB::table('order_product_ratings')
                ->whereIn('product_id', $productIds)
                ->select('product_id', \DB::raw('ROUND(AVG(rating), 1) as avg_rating'), \DB::raw('COUNT(*) as rating_count'))
                ->groupBy('product_id')
                ->get()
                ->keyBy('product_id');
            foreach ($ratings as $productId => $row) {
                $ratingsMap[$productId] = [
                    'avg_rating'   => (float) $row->avg_rating,
                    'rating_count' => (int)   $row->rating_count,
                ];
            }
        }

        // Group products by category
        $productsByCategory = $products->groupBy('category_id')->map(function ($categoryProducts, $categoryId) use ($sortBy, $ratingsMap) {
            $category = $categoryProducts->first()->category;

            // In-collection sort within each category group
            switch ($sortBy) {
                case 'price_asc':
                    $categoryProducts = $categoryProducts->sortBy(fn($p) => $p->variants->min('price') ?? 0);
                    break;
                case 'price_desc':
                    $categoryProducts = $categoryProducts->sortByDesc(fn($p) => $p->variants->min('price') ?? 0);
                    break;
                case 'rating_asc':
                    $categoryProducts = $categoryProducts->sortBy(fn($p) => $ratingsMap[$p->id]['avg_rating'] ?? 0);
                    break;
                case 'rating_desc':
                    $categoryProducts = $categoryProducts->sortByDesc(fn($p) => $ratingsMap[$p->id]['avg_rating'] ?? 0);
                    break;
            }

            // Attach rating info to every product
            $categoryProducts = $categoryProducts->map(function ($product) use ($ratingsMap) {
                $info = $ratingsMap[$product->id] ?? ['avg_rating' => 0.0, 'rating_count' => 0];
                $product->avg_rating   = $info['avg_rating'];
                $product->rating_count = $info['rating_count'];
                return $product;
            });

            return [
                'category_id'        => $categoryId,
                'category_name'      => $category ? $category->name : 'Unknown',
                'category_image_url' => $category ? $category->image_url : null,
                'product_count'      => $categoryProducts->count(),
                'products'           => $categoryProducts->values()
            ];
        })->values();

        return response()->json([
            'status' => 1,
            'message' => 'Sweetshop Products Fetched Successfully',
            'data' => [
                'categories_with_types' => $categoriesWithTypes,
                'products_by_category'  => $productsByCategory,
                'total_products'        => $products->count()
            ]
        ]);
    }

    public function getUserSweetshopProductsByCategory(Request $request)
    {
        $validator = \Validator::make($request->all(), [
            'seller_id' => 'required|integer|exists:sellers,id',
            'search' => 'nullable|string|max:255',
            'category_id' => 'nullable|integer|exists:categories,id',
            'category_type_id' => 'nullable|integer|exists:category_types,id',
            'sort_by' => 'nullable|string|in:name_asc,name_desc,price_asc,price_desc',
            'user_lat' => 'nullable|numeric|between:-90,90',
            'user_lon' => 'nullable|numeric|between:-180,180'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        // Get authenticated user ID for bookmark checks
        $user_id = $request->user('api-customers') ? $request->user('api-customers')->id : null;

        // Get user location for distance calculation
        $userLat = $request->input('user_lat');
        $userLon = $request->input('user_lon');

        $seller = Seller::find($request->seller_id);

        if (!$seller) {
            return CommonHelper::responseError("Seller not found.");
        }

        // Check if seller belongs to sweetshop (store_id = 15)
        if ($seller->store_id != 15) {
            return CommonHelper::responseError("This API is only available for sweetshop sellers.");
        }

        // Check if store is managed by admin
        $store = Store::where('id', $seller->store_id)->first();
        $isManagedByAdmin = $store && $store->managed_by_admin == 1;

        // Get all categories with types for this store
        $categoriesWithTypes = Category::where('seller_id', $seller->id)
            ->with([
                'categoryTypes' => function ($query) {
                    $query->select('id', 'name', 'category_id');
                }
            ])
            ->select('id', 'name', 'image')
            ->get()
            ->map(function ($category) {
                return [
                    'id' => $category->id,
                    'name' => $category->name,
                    'image_url' => $category->image_url,
                    'types' => $category->categoryTypes
                ];
            });

        // Get products query
        $productsQuery = Product::with([
            'variants.stockUnit',
            'variants.images',
            'brand',
            'categoryType',
            'category',
            'store',
            'images'
        ])
            ->where('store_id', 15)
            ->where('is_approved', 1)
            ->where('status', 1); // Only active products for users

        // If managed by admin, show all products in the store, otherwise show only seller's products
        if (!$isManagedByAdmin) {
            $productsQuery->where('seller_id', $seller->id);
        }

        // Apply search filter
        if ($request->filled('search')) {
            $search = $request->search;
            $productsQuery->where(function ($query) use ($search) {
                $query->where('name', 'LIKE', "%{$search}%")
                    ->orWhere('tags', 'LIKE', "%{$search}%")
                    ->orWhere('description', 'LIKE', "%{$search}%");
            });
        }

        // Apply category filter
        if ($request->filled('category_id')) {
            $productsQuery->where('category_id', $request->category_id);
        }

        // Apply category type filter
        if ($request->filled('category_type_id')) {
            $productsQuery->where('item_type_id', $request->category_type_id);
        }

        // Apply sorting
        $sortBy = $request->input('sort_by', 'default');

        switch ($sortBy) {
            case 'name_asc':
                $productsQuery->orderBy('name', 'asc');
                break;
            case 'name_desc':
                $productsQuery->orderBy('name', 'desc');
                break;
            case 'price_asc':
                $productsQuery->orderByRaw('(SELECT MIN(price) FROM product_variants WHERE product_variants.product_id = products.id) ASC');
                break;
            case 'price_desc':
                $productsQuery->orderByRaw('(SELECT MIN(price) FROM product_variants WHERE product_variants.product_id = products.id) DESC');
                break;
            default:
                $productsQuery->orderBy('category_id', 'asc')->orderBy('id', 'desc');
                break;
        }

        $products = $productsQuery->get();

        // Group products by category and sort within each category
        $productsByCategory = $products->groupBy('category_id')->map(function ($categoryProducts, $categoryId) use ($sortBy, $user_id) {
            $category = $categoryProducts->first()->category;

            // Sort products within this category based on sort criteria
            $sortedProducts = $categoryProducts;

            switch ($sortBy) {
                case 'name_asc':
                    $sortedProducts = $categoryProducts->sortBy('name', SORT_NATURAL | SORT_FLAG_CASE);
                    break;
                case 'name_desc':
                    $sortedProducts = $categoryProducts->sortByDesc('name', SORT_NATURAL | SORT_FLAG_CASE);
                    break;
                case 'price_asc':
                    $sortedProducts = $categoryProducts->sortBy(function ($product) {
                        return $product->variants->min('price') ?? 0;
                    });
                    break;
                case 'price_desc':
                    $sortedProducts = $categoryProducts->sortByDesc(function ($product) {
                        return $product->variants->min('price') ?? 0;
                    });
                    break;
            }

            // Add is_bookmarked status to each product
            $sortedProducts = $sortedProducts->map(function ($product) use ($user_id) {
                $product->is_bookmarked = $user_id ? $this->checkProductBookmarked($user_id, $product->id) : 0;
                return $product;
            });

            // Get the representative price for category sorting (min price of first product after sorting)
            $firstProduct = $sortedProducts->first();
            $categoryRepPrice = $firstProduct ? ($firstProduct->variants->min('price') ?? 0) : 0;

            // Convert products to array to ensure is_bookmarked is serialized
            $productsArray = $sortedProducts->map(function ($product) {
                $productArray = $product->toArray();
                $productArray['is_bookmarked'] = $product->is_bookmarked ?? 0;

                // Add ratings using CommonHelper
                $ratingData = CommonHelper::productAverageRating($product->id);
                $productArray['rating_count'] = $ratingData['rating_count'];
                $productArray['average_rating'] = $ratingData['average_rating'];

                return $productArray;
            })->values()->all();

            return [
                'category_id' => $categoryId,
                'category_name' => $category ? $category->name : 'Unknown',
                'category_image_url' => $category ? $category->image_url : null,
                'product_count' => $categoryProducts->count(),
                'category_sort_price' => $categoryRepPrice, // For sorting categories
                'products' => $productsArray
            ];
        });

        // Sort categories based on the sort criteria
        switch ($sortBy) {
            case 'name_asc':
                $productsByCategory = $productsByCategory->sortBy('category_name', SORT_NATURAL | SORT_FLAG_CASE);
                break;
            case 'name_desc':
                $productsByCategory = $productsByCategory->sortByDesc('category_name', SORT_NATURAL | SORT_FLAG_CASE);
                break;
            case 'price_asc':
                // Sort categories by their lowest priced product
                $productsByCategory = $productsByCategory->sortBy('category_sort_price');
                break;
            case 'price_desc':
                // Sort categories by their highest priced product (use min price, sorted desc)
                $productsByCategory = $productsByCategory->sortByDesc('category_sort_price');
                break;
        }

        // Remove the temporary sort field and convert to values
        $productsByCategory = $productsByCategory->map(function ($category) {
            unset($category['category_sort_price']);
            return $category;
        })->values();

        // Build applied filters for response
        $appliedFilters = [];
        if ($request->filled('search')) {
            $appliedFilters['search'] = $request->search;
        }
        if ($request->filled('category_id')) {
            $appliedFilters['category_id'] = $request->category_id;
        }
        if ($request->filled('category_type_id')) {
            $appliedFilters['category_type_id'] = $request->category_type_id;
        }
        if ($request->filled('sort_by')) {
            $appliedFilters['sort_by'] = $request->sort_by;
        }

        return response()->json([
            'status' => 1,
            'message' => 'Sweetshop Products Fetched Successfully',
            'data' => [
                'seller' => $this->formatSellerResponse($seller, $user_id, $userLat, $userLon),
                'applied_filters' => $appliedFilters,
                'available_sort_options' => [
                    ['value' => 'name_asc', 'label' => 'Name: A to Z'],
                    ['value' => 'name_desc', 'label' => 'Name: Z to A'],
                    ['value' => 'price_asc', 'label' => 'Price: Low to High'],
                    ['value' => 'price_desc', 'label' => 'Price: High to Low'],
                ],
                'categories_with_types' => $categoriesWithTypes,
                'products_by_category' => $productsByCategory,
                'total_products' => $products->count()
            ]
        ]);
    }

    public function updateProductSeller(Request $request, $product_id)
    {

        Log::info('=== UPDATE PRODUCT SELLER - START ===', [
            'product_id' => $product_id,
            'request_data' => $request->all()
        ]);

        Log::info('UPDATE PRODUCT - is_unlimited_stock from request', [
            'product_id' => $product_id,
            'is_unlimited_stock' => $request->is_unlimited_stock,
            'type' => gettype($request->is_unlimited_stock)
        ]);


        $product = Product::where('id', $product_id)
            ->first();

        if (!$product) {
            Log::error('UPDATE PRODUCT - Product not found', ['product_id' => $product_id]);
            return CommonHelper::responseError("Product not found or unauthorized.");
        }

        Log::info('UPDATE PRODUCT - Current product data', [
            'product_id' => $product_id,
            'current_is_unlimited_stock' => $product->is_unlimited_stock,
            'current_type' => $product->type,
            'current_name' => $product->name
        ]);

        // Make category_group_id and sub_category_group_id optional for store_id 15
        $categoryGroupRules = $request->store_id == 15 ? 'nullable' : 'required';

        // Make brand_id, manufacturer, made_in, and tax nullable (seller app doesn't send these)
        $brandRules = 'nullable';
        $madeInRules = 'nullable|string';
        $manufacturerRules = 'nullable';
        $taxRules = 'nullable';

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'store_id' => 'required|integer',
            'category_id' => 'required|integer',
            'category_group_id' => $categoryGroupRules,
            'sub_category_group_id' => $categoryGroupRules,
            'item_type_id' => 'required|integer',
            'brand_id' => $brandRules,
            'description' => 'required|string',
            'tags' => 'nullable',
            'fssai_lic_no' => 'nullable',
            'made_in' => $madeInRules,
            'other_info' => 'nullable',
            'manufacturer' => $manufacturerRules,
            'tax' => $taxRules,
            'is_unlimited_stock' => 'required|in:0,1',
            'type' => 'required|in:packet,loose',
            'return_status' => 'required|in:0,1',
            'cancelable_status' => 'required|in:0,1',
            'till_status' => [
                'nullable',
                function ($attribute, $value, $fail) use ($request) {
                    if ($request->cancelable_status == 1) {
                        if ($value === null || $value === '') {
                            $fail('Till status is required when cancelable is enabled.');
                        } elseif (!in_array((int)$value, [2, 3])) {
                            $fail('Till status must be Received (2) or Processed (3).');
                        }
                    }
                },
            ],
            'total_allowed_quantity' => 'nullable|numeric|min:1',

            // PACKET
            'packet_measurement.*' => ['required_if:type,packet', 'numeric', Rule::notIn([0])],
            'packet_price.*' => ['required_if:type,packet', 'numeric', 'min:0.01'],
            'discounted_price.*' => [
                'required_if:type,packet',
                'numeric',
                'min:0',
                function ($attribute, $value, $fail) use ($request) {
                    $index = explode('.', $attribute)[1];
                    $price = $request->input("packet_price.{$index}");
                    if (is_numeric($value) && is_numeric($price) && (float)$value >= (float)$price) {
                        $fail('Discounted price must be less than the price (Rs. ' . $price . ').');
                    }
                },
            ],
            'packet_status.*' => ['required_if:type,packet', 'in:0,1'],
            'packet_stock.*' => [
                'required_if:type,packet',
                'numeric',
                function ($attribute, $value, $fail) use ($request) {
                    $index = explode('.', $attribute)[1];
                    $status = $request->input("packet_status.$index", 1);

                    if ($request->is_unlimited_stock == 0 && $value == 0 && $status != 0) {
                        $fail('Stock must be greater than 0 when unlimited stock is disabled.');
                    }
                }
            ],
            'packet_stock_unit_id.*' => ['required_if:type,packet'],

            // LOOSE
            'loose_measurement.*' => ['required_if:type,loose', 'numeric', Rule::notIn([0])],
            'loose_price.*' => ['required_if:type,loose', 'numeric', 'min:0.01'],
            'loose_discounted_price.*' => [
                'required_if:type,loose',
                'numeric',
                'min:0',
                function ($attribute, $value, $fail) use ($request) {
                    $index = explode('.', $attribute)[1];
                    $price = $request->input("loose_price.{$index}");
                    if (is_numeric($value) && is_numeric($price) && (float)$value >= (float)$price) {
                        $fail('Discounted price must be less than the price (Rs. ' . $price . ').');
                    }
                },
            ],
            'loose_status.*' => ['required_if:type,loose', 'in:0,1'],
            'loose_stock.*' => [
                'required_if:type,loose',
                'numeric',
                function ($attribute, $value, $fail) use ($request) {
                    $index = explode('.', $attribute)[1];
                    $status = $request->input("loose_status.$index", 1);

                    if ($request->is_unlimited_stock == 0 && $value == 0 && $status != 0) {
                        $fail('Stock must be greater than 0 when unlimited stock is disabled.');
                    }
                }
            ],
            'loose_stock_unit_id' => ['required_if:type,loose'],

            'barcode' => 'nullable|unique:products,barcode,' . $product_id,
            'indicator' => 'nullable|integer|in:1,2',
            'return_days' => [
                'nullable',
                function ($attribute, $value, $fail) use ($request) {
                    if ($request->return_status == 1) {
                        if ($value === null || $value === '') {
                            $fail('Return days is required when returnable is enabled.');
                        } elseif (!is_numeric($value) || (int)$value <= 0) {
                            $fail('Return days must be a valid number (e.g. 7). Values like "1hr", "2hr" are not allowed.');
                        }
                    } elseif ($value !== null && $value !== '' && $value !== '0' && !is_numeric($value)) {
                        $fail('Return days must be a valid number.');
                    }
                },
            ],
        ], [
            'name.required' => 'The Product Name is required.',
            'name.max' => 'The Product Name must not exceed 255 characters.',
            'category_id.required' => 'The Category name field is required.',
            'store_id.required' => 'The Store Selection is required.',
            'sub_category_group_id.required' => 'The Sub Category Group is required.',
            'category_group_id.required' => 'The Category Group is required.',
            'is_unlimited_stock.in' => 'Unlimited stock must be 0 (No) or 1 (Yes).',
            'type.in' => 'Product type must be "packet" or "loose".',
            'return_status.required' => 'Return status is required.',
            'return_status.in' => 'Return status must be 0 (No) or 1 (Yes).',
            'cancelable_status.required' => 'Cancelable status is required.',
            'cancelable_status.in' => 'Cancelable status must be 0 (No) or 1 (Yes).',
            'total_allowed_quantity.numeric' => 'Total allowed quantity must be a number.',
            'total_allowed_quantity.min' => 'Total allowed quantity must be at least 1.',

            'packet_measurement.*.required_if' => 'The Packet Measurement is required when the type is "Packet".',
            'packet_measurement.*.numeric' => 'The Packet Measurement must be a number.',
            'packet_measurement.*.not_in' => 'The Packet Measurement must not be zero.',
            'packet_price.*.min' => 'The Packet Price must be greater than 0.',
            'packet_stock.*.required_if' => 'The Packet Stock is required when the type is "Packet".',
            'packet_stock.*.not_in' => 'The Packet Stock must not be zero.',
            'packet_stock_unit_id.*.required_if' => 'The Packet Stock Unit is required when the type is "Packet".',
            'discounted_price.*.numeric' => 'The Discounted Price must be a number.',

            'loose_measurement.*.required_if' => 'The Loose Measurement is required when the type is "Loose".',
            'loose_measurement.*.numeric' => 'The Loose Measurement must be a number.',
            'loose_measurement.*.not_in' => 'The Loose Measurement must not be zero.',
            'loose_price.*.min' => 'The Loose Price must be greater than 0.',
            'loose_discounted_price.*.numeric' => 'The Loose Discounted Price must be a number.',
            'loose_stock_unit_id.required_if' => 'The Loose Stock Unit is required when the type is "Loose".',
            'loose_stock_unit_id.numeric' => 'The Loose Stock Unit must be a number.',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $variations = [];

        if ($request->type == "packet") {
            foreach ($request->packet_measurement as $i => $item) {
                $variations[] = [
                    'original_index' => $i,
                    'measurement' => $request->packet_measurement[$i],
                    'variant_id' => $request->variant_id[$i] ?? null,
                    'price' => $request->packet_price[$i],
                    'discounted_price' => $request->discounted_price[$i] ?? 0,
                    'status' => $request->packet_status[$i],
                    'stock' => $request->is_unlimited_stock == 0 ? $request->packet_stock[$i] : 0,
                    'stock_unit_id' => $request->packet_stock_unit_id[$i],
                ];
            }
        } else {
            foreach ($request->loose_measurement as $i => $item) {
                $variations[] = [
                    'original_index' => $i,
                    'measurement' => $request->loose_measurement[$i],
                    'variant_id' => $request->variant_id[$i] ?? null,
                    'price' => $request->loose_price[$i],
                    'discounted_price' => $request->loose_discounted_price[$i] ?? 0,
                    'status' => $request->loose_status[$i] ?? 1,
                    'stock' => $request->is_unlimited_stock == 0 ? $request->loose_stock[$i] : 0,
                    'stock_unit_id' => $request->loose_stock_unit_id,
                ];
            }
        }

        if (count($variations) !== count(array_unique($variations, SORT_REGULAR))) {
            return CommonHelper::responseError("Duplicate variations are not allowed.");
        }

        DB::beginTransaction();




        try {

            if ($request->name != $product->name) {
                $slug = preg_replace('/\s+/', '-', trim(preg_replace('/[^\p{L}\p{N} ]/u', '', $request->name)));
                $count = Product::where('slug', 'LIKE', "$slug%")->where('id', '!=', $product_id)->count();
                $product->slug = $count ? "$slug-$count" : $slug;
            }

            $product->name = $request->name;
            $product->category_id = $request->category_id;
            // For store_id 15, category_group_id and sub_category_group_id are optional
            $product->category_group_id = $request->store_id == 15 ? ($request->category_group_id ?? null) : $request->category_group_id;
            $product->sub_category_group_id = $request->store_id == 15 ? ($request->sub_category_group_id ?? null) : $request->sub_category_group_id;
            $product->store_id = $request->store_id;
            // Fish-store (store 19) cut fields
            $product->is_cleaned = $request->is_cleaned ?? 0;
            $product->before_cleaning_weight = $request->before_cleaning_weight ?? null;
            $product->after_cleaning_weight = $request->after_cleaning_weight ?? null;
            $product->pieces = $request->pieces ?? null;
            $product->item_type_id = $request->item_type_id;

            $product->fssai_lic_no = $request->fssai_number ?? $request->fssai_lic_no ?? " ";

            $product->brand_id = $request->brand_id ?: null;
            $product->description = $request->description;
            $product->tags = $this->normalizeTags($request->tags);
            $product->made_in = $request->made_in ?? "";
            $product->manufacturer = $request->manufacturer ?: null;
            $product->tax = $request->tax ?: null;
            $product->other_info = $request->other_info;
            $product->type = $request->type;
            $product->is_unlimited_stock = $request->is_unlimited_stock;

            Log::info('UPDATE PRODUCT - After setting is_unlimited_stock (before save)', [
                'product_id' => $product_id,
                'is_unlimited_stock_set_to' => $product->is_unlimited_stock,
                'type' => gettype($product->is_unlimited_stock),
                'request_value' => $request->is_unlimited_stock
            ]);

            $product->return_status = $request->return_status;
            $product->return_days = $request->return_days ?? 0;
            $product->cancelable_status = $request->cancelable_status;
            $product->till_status = $request->till_status;
            $product->total_allowed_quantity = $request->total_allowed_quantity ?? 100;
            $product->indicator = $request->indicator ?? 0;

            $product->meta_title = $request->meta_title ?? "";
            $product->meta_keywords = $request->meta_keywords ?? "";
            $product->schema_markup = $request->schema_markup ?? "";
            $product->meta_description = $request->meta_description ?? "";

            if ($request->hasFile('image')) {
                try {
                    $product->image = MediaUploadService::uploadWithFullUrl($request->file('image'), 'products');
                } catch (\Exception $e) {
                    return CommonHelper::responseError("Image upload failed: " . $e->getMessage());
                }
            }

            $product->save();

            Log::info('UPDATE PRODUCT - After save()', [
                'product_id' => $product_id,
                'is_unlimited_stock' => $product->is_unlimited_stock,
                'type' => $product->type,
                'name' => $product->name
            ]);

            // Verify from database
            $productFromDb = Product::find($product_id);
            Log::info('UPDATE PRODUCT - Verified from DB after save', [
                'product_id' => $product_id,
                'is_unlimited_stock_from_db' => $productFromDb->is_unlimited_stock,
                'type_from_db' => $productFromDb->type
            ]);

            // Handle image deletions (both product-level and variant images)
            if ($request->has('deleteImageIds')) {
                $deleteImageIds = json_decode($request->deleteImageIds, true);
                if (is_array($deleteImageIds) && count($deleteImageIds) > 0) {
                    Log::info('UPDATE PRODUCT - Deleting specific images', [
                        'product_id' => $product_id,
                        'delete_image_ids' => $deleteImageIds,
                        'count' => count($deleteImageIds),
                    ]);

                    $deletedCount = ProductImages::whereIn('id', $deleteImageIds)
                        ->where('product_id', $product_id)
                        ->delete();

                    Log::info('UPDATE PRODUCT - Specific images deleted', [
                        'product_id' => $product_id,
                        'requested_delete_count' => count($deleteImageIds),
                        'actual_deleted_count' => $deletedCount,
                    ]);
                } else {
                    Log::info('UPDATE PRODUCT - No images to delete', [
                        'product_id' => $product_id,
                        'deleteImageIds_raw' => $request->deleteImageIds,
                    ]);
                }
            }

            // Upload new product-level images (adds to existing, doesn't replace)
            if ($request->hasFile('other_images')) {
                $fileCount = is_array($request->file('other_images')) ? count($request->file('other_images')) : 1;
                Log::info('UPDATE PRODUCT - Uploading product-level other_images', [
                    'product_id' => $product_id,
                    'file_count' => $fileCount,
                ]);
                CommonHelper::uploadProductImages($request->file('other_images'), $product->id);
            }

            Log::info('UPDATE PRODUCT - All file keys received', [
                'product_id' => $product_id,
                'file_keys' => array_keys($request->allFiles()),
            ]);

            Log::info('UPDATE PRODUCT - Processing variants', [
                'product_id' => $product_id,
                'variants_count' => count($variations),
            ]);

            foreach ($variations as $variantIndex => $v) {
                $variant_id_from_request = $v['variant_id'];
                $originalIndex = $v['original_index'];

                Log::info('UPDATE PRODUCT - Processing variant', [
                    'product_id' => $product_id,
                    'variant_index' => $variantIndex,
                    'variant_id_from_request' => $variant_id_from_request,
                    'original_index' => $originalIndex,
                    'measurement' => $v['measurement'],
                    'price' => $v['price'],
                ]);

                if ($variant_id_from_request) {
                    $variant = ProductVariant::find($variant_id_from_request);

                    if ($variant) {
                        Log::info('UPDATE PRODUCT - Updating existing variant', [
                            'product_id' => $product_id,
                            'variant_id' => $variant_id_from_request,
                            'old_measurement' => $variant->measurement,
                            'new_measurement' => $v['measurement'],
                            'old_price' => $variant->price,
                            'new_price' => $v['price'],
                        ]);

                        $variant->measurement = $v['measurement'];
                        $variant->price = $v['price'];
                        $variant->discounted_price = $v['discounted_price'];
                        $variant->status = $v['status'];
                        $variant->stock = $v['stock'];
                        $variant->stock_unit_id = $v['stock_unit_id'];
                        $variant->save();
                        $variant_id = $variant->id;

                        Log::info('UPDATE PRODUCT - Variant updated successfully', [
                            'product_id' => $product_id,
                            'variant_id' => $variant_id,
                        ]);
                    } else {
                        Log::warning('UPDATE PRODUCT - Variant ID from request not found, creating new variant', [
                            'product_id' => $product_id,
                            'variant_id_from_request' => $variant_id_from_request,
                        ]);

                        $variant_id = ProductVariant::insertGetId([
                            'product_id' => $product->id,
                            'type' => $request->type,
                            'measurement' => $v['measurement'],
                            'price' => $v['price'],
                            'discounted_price' => $v['discounted_price'],
                            'status' => $v['status'],
                            'stock' => $v['stock'],
                            'stock_unit_id' => $v['stock_unit_id'],
                        ]);

                        Log::info('UPDATE PRODUCT - New variant created', [
                            'product_id' => $product_id,
                            'variant_id' => $variant_id,
                        ]);
                    }
                } else {
                    Log::info('UPDATE PRODUCT - Creating new variant (no variant_id provided)', [
                        'product_id' => $product_id,
                        'original_index' => $originalIndex,
                    ]);

                    $variant_id = ProductVariant::insertGetId([
                        'product_id' => $product->id,
                        'type' => $request->type,
                        'measurement' => $v['measurement'],
                        'price' => $v['price'],
                        'discounted_price' => $v['discounted_price'],
                        'status' => $v['status'],
                        'stock' => $v['stock'],
                        'stock_unit_id' => $v['stock_unit_id'],
                    ]);

                    Log::info('UPDATE PRODUCT - New variant created', [
                        'product_id' => $product_id,
                        'variant_id' => $variant_id,
                    ]);
                }

                // Upload variant images using original request index
                Log::info('UPDATE PRODUCT - Calling storeVariantImages', [
                    'product_id' => $product_id,
                    'variant_id' => $variant_id,
                    'type' => $request->type,
                    'original_index' => $originalIndex,
                ]);

                $this->storeVariantImages($request, $product->id, $variant_id, $request->type, $originalIndex);

                Log::info('UPDATE PRODUCT - storeVariantImages completed', [
                    'product_id' => $product_id,
                    'variant_id' => $variant_id,
                ]);
            }

            Log::info('UPDATE PRODUCT - All variants processed', [
                'product_id' => $product_id,
                'processed_count' => count($variations),
            ]);


            DB::commit();

            Log::info('UPDATE PRODUCT - SUCCESS', [
                'product_id' => $product_id,
                'final_is_unlimited_stock' => $product->is_unlimited_stock,
                'message' => 'Product updated successfully'
            ]);

            Log::info('=== UPDATE PRODUCT SELLER - END (SUCCESS) ===', ['product_id' => $product_id]);

            return CommonHelper::responseSuccess("Product Updated Successfully!");

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("UPDATE PRODUCT - ERROR", [
                'product_id' => $product_id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            Log::info('=== UPDATE PRODUCT SELLER - END (ERROR) ===', ['product_id' => $product_id]);
            return CommonHelper::responseError($e->getMessage());
        }
    }


    public function singleProduct(Request $request, $id)
    {
        try {
            Log::info('=== GET SINGLE PRODUCT - START ===', ['product_id' => $id]);

            // $admin = auth()->guard('sanctum')->user();

            // if (!$admin) {
            //     return CommonHelper::responseError("Invalid token or unauthorized access.");
            // }

            // $seller = Seller::where('admin_id', $admin->id)->first();

            // if (!$seller) {
            //     return CommonHelper::responseError("Seller profile not found.");
            // }

            $product = Product::with([
                'variants.stockUnit',
                'variants.images',
                'images',
                'categoryType',
                'store',
                'category',
                'categoryGroup',
                'subCategoryGroup',
                'brand',
                'tags'
            ])
                // ->where('seller_id', $seller->id)
                ->find($id);

            if (!$product) {
                Log::warning('GET SINGLE PRODUCT - Product not found', ['product_id' => $id]);
                return CommonHelper::responseError("Product not found.");
            }

            Log::info('GET SINGLE PRODUCT - Product found from DB', [
                'product_id' => $id,
                'name' => $product->name,
                'is_unlimited_stock' => $product->is_unlimited_stock,
                'type' => $product->type,
                'store_id' => $product->store_id,
                'is_pre_order_item' => $product->is_pre_order_item ?? null
            ]);

            Log::info('GET SINGLE PRODUCT - Product variants', [
                'product_id' => $id,
                'variants_count' => $product->variants->count(),
                'variants' => $product->variants->map(function($v) {
                    return [
                        'id' => $v->id,
                        'measurement' => $v->measurement,
                        'stock' => $v->stock,
                        'status' => $v->status
                    ];
                })
            ]);

            Log::info('GET SINGLE PRODUCT - Response data attributes', [
                'product_id' => $id,
                'attributes_in_model' => array_keys($product->getAttributes()),
                'is_unlimited_stock_exists' => array_key_exists('is_unlimited_stock', $product->getAttributes()),
                'is_unlimited_stock_value' => $product->getAttributes()['is_unlimited_stock'] ?? 'NOT_FOUND'
            ]);

            $loadedTags = $product->relationLoaded('tags') ? $product->getRelation('tags') : collect();
            Log::info('GET SINGLE PRODUCT - Tags loaded', [
                'product_id'      => $id,
                'relation_loaded' => $product->relationLoaded('tags'),
                'raw_tags_column' => $product->getRawOriginal('tags') ?? null,
                'tags_count'      => $loadedTags->count(),
                'tags'            => $loadedTags->map(fn($t) => ['id' => $t->id, 'name' => $t->name]),
            ]);

            Log::info('=== GET SINGLE PRODUCT - END (SUCCESS) ===', ['product_id' => $id]);

            return CommonHelper::responseSuccessWithData("Product fetched successfully!", $product);

        } catch (\Exception $e) {
            Log::error('GET SINGLE PRODUCT - ERROR', [
                'product_id' => $id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            Log::info('=== GET SINGLE PRODUCT - END (ERROR) ===', ['product_id' => $id]);
            return CommonHelper::responseError($e->getMessage());
        }
    }


    public function deleteVariant(Request $request, $id)
    {
        if (!$id) {
            return CommonHelper::responseError("Variant ID is required.");
        }

        $variant = ProductVariant::find($id);

        if (!$variant) {
            return CommonHelper::responseError("Product Variant not found.");
        }

        $orderItemExists = OrderItem::where('product_variant_id', $variant->id)->exists();

        if ($orderItemExists) {
            return CommonHelper::responseError("This product variant cannot be deleted as it exists in orders.");
        }

        $product_id = $variant->product_id;

        $variant->delete();

        $remaining = ProductVariant::where('product_id', $product_id)->count();

        if ($remaining === 0) {
            $product = Product::find($product_id);

            if ($product) {
                $product->delete();
            }

            return CommonHelper::responseSuccess("Variant deleted. Product was also deleted because it had no more variants.");
        }


        return CommonHelper::responseSuccess("Variant Deleted Successfully!");
    }



    public function deleteProduct(Request $request, $id)
    {
        if (!$id) {
            return CommonHelper::responseError("Product ID is required.");
        }

        $product = Product::find($id);

        if (!$product) {
            return CommonHelper::responseError("Product not found.");
        }

        $variantIds = ProductVariant::where('product_id', $product->id)->pluck('id');
        $orderItemExists = OrderItem::whereIn('product_variant_id', $variantIds)->exists();

        if ($orderItemExists) {
            return CommonHelper::responseError("This product cannot be deleted because one or more variants are linked to orders.");
        }

        ProductVariant::where('product_id', $product->id)->delete();

        $product->delete();

        return CommonHelper::responseSuccess("Product Deleted Successfully!");
    }


    public function getDefaultMapsKey()
    {
        $setting = DB::table('settings')->where('id', 46)->first();

        if (!$setting) {
            return response()->json([
                'status' => 0,
                'message' => 'Setting not found',
                'data' => null
            ]);
        }

        return response()->json([
            'status' => 1,
            'message' => 'Success',
            'data' => $setting->value
        ]);
    }

    /**
     * Helper method to check if a product is bookmarked by user
     */
    private function checkProductBookmarked($user_id, $product_id)
    {
        return Bookmark::where('user_id', $user_id)
            ->where('type', 'product')
            ->where('bookmarkable_type', 'App\Models\Product')
            ->where('bookmarkable_id', $product_id)
            ->exists() ? 1 : 0;
    }

    private function checkSellerBookmarked($user_id, $seller_id)
    {
        return Bookmark::where('user_id', $user_id)
            ->where('type', 'seller')
            ->where('bookmarkable_type', 'App\Models\Seller')
            ->where('bookmarkable_id', $seller_id)
            ->exists() ? 1 : 0;
    }

    private function formatSellerResponse($seller, $user_id, $userLat = null, $userLon = null)
    {
        // Get seller's store details
        $sellerStore = Store::find($seller->store_id);
        $storeDetails = null;

        if ($sellerStore) {
            $storeDetails = [
                'id' => $sellerStore->id,
                'name' => $sellerStore->name,
                'icon' => $sellerStore->icon_url,
                'color' => $sellerStore->color,
                'image' => $sellerStore->image_url,
                'description' => $sellerStore->description,
                'managed_by_admin' => $sellerStore->managed_by_admin,
                'is_super_mart' => $sellerStore->is_super_mart,
                'is_sweet_house' => (!$sellerStore->managed_by_admin && !$sellerStore->is_super_mart),
            ];
        }

        // Initialize distance and travel time
        $distanceKm = null;
        $travelTimeMin = null;
        $latLong = $seller->lat_long;
        if (!$latLong) {
            $seller->distance_km = null;
            $seller->travel_time_min = null;
            return $seller;
        }

        list($sLat, $sLon) = explode(",", $latLong);

        // Calculate distance if user location and seller coordinates are available
        if ($userLat && $userLon && $sLat && $sLon) {
            $distanceKm = StoreDistanceService::haversine($userLat, $userLon, $sLat, $sLon);
            $travelTimeMin = StoreDistanceService::estimateTravelTimeMinutes($distanceKm);

            // Try to get Google Maps distance if available
            $google = StoreDistanceService::googleMapsDistance($userLat, $userLon, $sLat, $sLon);

            $distanceKm = StoreDistanceService::formatDistance($distanceKm);
            $travelTimeMin = StoreDistanceService::formatTime($travelTimeMin);

            if ($google) {
                $distanceKm = StoreDistanceService::formatDistance($google['distance_km']);
                $travelTimeMin = StoreDistanceService::formatTime($google['time_min']);
            }
        }

        return [
            'id' => $seller->id,
            'name' => $seller->name ?? $seller->store_name,
            'store_id' => $seller->store_id,
            'is_bookmarked' => $user_id ? $this->checkSellerBookmarked($user_id, $seller->id) : 0,
            'store_name' => $seller->store_name,
            'logo_url' => $seller->logo_url,
            'store_images' => $seller->store_images_urls ?? [],
            'store_location' => $seller->store_location,
            'distance_km' => $distanceKm,
            'store_city' => $seller->store_city,
            'travel_time_min' => $travelTimeMin,
            'mobile' => $seller->mobile,
            'fssai_number' => $seller->fssai_number,
            'lat_long' => $sLat && $sLon ? "{$sLat},{$sLon}" : null,
            // Seller's own shop hours, so the app can show "open till 10:30 PM"
            // / "closing in 12:04" on the store header. Null when the seller
            // never set them — the app then shows no hours at all.
            'shop_opening_time' => $seller->shop_opening_time,
            'shop_closing_time' => $seller->shop_closing_time,
            'store_details' => $storeDetails,
        ];
    }

    /**
     * Upload variant images using MediaUploadService and store in product_images table.
     *
     * Tries multiple file key formats to handle different client implementations:
     *  - {type}_variant_images_{index}   (e.g. packet_variant_images_0)
     *  - variant_images_{index}          (e.g. variant_images_0)
     *
     * NOTE: This method ADDS new images without deleting existing ones.
     * Image deletion is handled separately via the deleteImageIds parameter.
     */
    private function storeVariantImages($request, int $productId, int $variantId, string $type, $index): void
    {
        Log::info("=== STORE VARIANT IMAGES - START ===", [
            'product_id' => $productId,
            'variant_id' => $variantId,
            'type' => $type,
            'index' => $index,
        ]);

        $possibleKeys = [
            "{$type}_variant_images_{$index}",
            "variant_images_{$index}",
        ];

        $files = null;
        $matchedKey = null;

        // Check which key format has files
        foreach ($possibleKeys as $key) {
            if ($request->hasFile($key)) {
                $files = $request->file($key);
                $matchedKey = $key;
                Log::info("Variant images: matched key found", [
                    'product_id' => $productId,
                    'variant_id' => $variantId,
                    'matched_key' => $matchedKey,
                ]);
                break;
            }
        }

        if (!$files) {
            Log::info("Variant images: no files found - SKIP", [
                'product_id' => $productId,
                'variant_id' => $variantId,
                'type' => $type,
                'index' => $index,
                'tried_keys' => $possibleKeys,
                'all_file_keys' => array_keys($request->allFiles()),
            ]);
            return;
        }

        // Normalize single file to array
        if ($files instanceof \Illuminate\Http\UploadedFile) {
            $files = [$files];
        }

        Log::info("Variant images: files received", [
            'product_id' => $productId,
            'variant_id' => $variantId,
            'matched_key' => $matchedKey,
            'file_count' => count($files),
            'file_names' => array_map(function($file) {
                return $file->getClientOriginalName();
            }, $files),
        ]);

        // Check existing images count (for logging only, not deleting)
        $existingCount = ProductImages::where('product_id', $productId)
            ->where('product_variant_id', $variantId)
            ->count();

        Log::info("Variant images: existing images count", [
            'product_id' => $productId,
            'variant_id' => $variantId,
            'existing_count' => $existingCount,
            'note' => 'New images will be added to existing (not replaced)',
        ]);

        // Upload new variant images (ADD, don't replace)
        $uploadedCount = 0;
        $failedCount = 0;

        foreach ($files as $fileIndex => $file) {
            try {
                Log::info("Variant images: uploading file", [
                    'product_id' => $productId,
                    'variant_id' => $variantId,
                    'file_index' => $fileIndex,
                    'file_name' => $file->getClientOriginalName(),
                    'file_size' => $file->getSize(),
                    'mime_type' => $file->getMimeType(),
                ]);

                $imageUrl = MediaUploadService::uploadWithFullUrl($file, 'products');

                $img = new ProductImages();
                $img->product_id = $productId;
                $img->product_variant_id = $variantId;
                $img->image = $imageUrl;
                $img->save();

                $uploadedCount++;

                Log::info("Variant images: file uploaded successfully", [
                    'product_images_id' => $img->id,
                    'product_id' => $productId,
                    'variant_id' => $variantId,
                    'file_index' => $fileIndex,
                    'image_url' => $imageUrl,
                ]);
            } catch (\Exception $e) {
                $failedCount++;

                Log::error("Variant images: file upload failed", [
                    'product_id' => $productId,
                    'variant_id' => $variantId,
                    'file_index' => $fileIndex,
                    'file_name' => $file->getClientOriginalName(),
                    'error' => $e->getMessage(),
                    'trace' => $e->getTraceAsString(),
                ]);
            }
        }

        // Get final count
        $finalCount = ProductImages::where('product_id', $productId)
            ->where('product_variant_id', $variantId)
            ->count();

        Log::info("=== STORE VARIANT IMAGES - END ===", [
            'product_id' => $productId,
            'variant_id' => $variantId,
            'existing_before' => $existingCount,
            'new_files_received' => count($files),
            'uploaded_count' => $uploadedCount,
            'failed_count' => $failedCount,
            'final_total_count' => $finalCount,
            'success' => $failedCount === 0,
        ]);
    }

}
