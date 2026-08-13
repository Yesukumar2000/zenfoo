<?php

namespace App\Http\Controllers\API\Customer;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\UserNote;
use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

class UserNoteController extends Controller
{
    /**
     * Get all notes for authenticated user
     *
     * GET /api/customer/notes
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function index()
    {
        try {
            $user = Auth::guard('api-customers')->user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            $notes = UserNote::where('user_id', $user->id)
                ->ordered()
                ->get();

            $formattedNotes = $notes->map(function ($note) {
                return [
                    'id' => $note->id,
                    'text' => $note->note_text,
                    'is_selected' => $note->is_selected,
                    'order_index' => $note->order_index,
                    'created_at' => $note->created_at->toIso8601String(),
                    'updated_at' => $note->updated_at->toIso8601String(),
                ];
            });

            return CommonHelper::responseWithData($formattedNotes, $notes->count());
        } catch (\Exception $e) {
            Log::error('Failed to retrieve notes', [
                'error' => $e->getMessage(),
                'user_id' => Auth::guard('api-customers')->id()
            ]);
            return CommonHelper::responseError('Failed to retrieve notes');
        }
    }

    /**
     * Add a new note
     *
     * POST /api/customer/notes
     * Body: {
     *   "note_text": "Rice Bag 25 kgs",
     *   "is_selected": true (optional, defaults to true)
     * }
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'note_text' => 'required|string|max:500',
            'is_selected' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $user = Auth::guard('api-customers')->user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Get the max order_index for this user
            $maxOrder = UserNote::where('user_id', $user->id)->max('order_index') ?? -1;

            $note = UserNote::create([
                'user_id' => $user->id,
                'note_text' => $request->note_text,
                'is_selected' => $request->is_selected ?? true,
                'order_index' => $maxOrder + 1,
            ]);

            $formattedNote = [
                'id' => $note->id,
                'text' => $note->note_text,
                'is_selected' => $note->is_selected,
                'order_index' => $note->order_index,
                'created_at' => $note->created_at->toIso8601String(),
                'updated_at' => $note->updated_at->toIso8601String(),
            ];

            return CommonHelper::responseWithData($formattedNote);
        } catch (\Exception $e) {
            Log::error('Failed to add note', [
                'error' => $e->getMessage(),
                'user_id' => Auth::guard('api-customers')->id(),
                'note_text' => $request->note_text
            ]);
            return CommonHelper::responseError('Failed to add note');
        }
    }

    /**
     * Update a note
     *
     * PUT /api/customer/notes/{id}
     * Body: {
     *   "note_text": "Updated text",
     *   "is_selected": false (optional)
     * }
     *
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function update(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'note_text' => 'nullable|string|max:500',
            'is_selected' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $user = Auth::guard('api-customers')->user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            $note = UserNote::where('id', $id)
                ->where('user_id', $user->id)
                ->first();

            if (!$note) {
                return CommonHelper::responseError('Note not found');
            }

            if ($request->has('note_text')) {
                $note->note_text = $request->note_text;
            }

            if ($request->has('is_selected')) {
                $note->is_selected = $request->is_selected;
            }

            $note->save();

            $formattedNote = [
                'id' => $note->id,
                'text' => $note->note_text,
                'is_selected' => $note->is_selected,
                'order_index' => $note->order_index,
                'created_at' => $note->created_at->toIso8601String(),
                'updated_at' => $note->updated_at->toIso8601String(),
            ];

            return CommonHelper::responseWithData($formattedNote);
        } catch (\Exception $e) {
            Log::error('Failed to update note', [
                'error' => $e->getMessage(),
                'user_id' => Auth::guard('api-customers')->id(),
                'note_id' => $id
            ]);
            return CommonHelper::responseError('Failed to update note');
        }
    }

    /**
     * Delete a note
     *
     * DELETE /api/customer/notes/{id}
     *
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function destroy($id)
    {
        try {
            $user = Auth::guard('api-customers')->user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            $note = UserNote::where('id', $id)
                ->where('user_id', $user->id)
                ->first();

            if (!$note) {
                return CommonHelper::responseError('Note not found');
            }

            $note->delete();

            return CommonHelper::responseWithData(['deleted_note_id' => $id]);
        } catch (\Exception $e) {
            Log::error('Failed to delete note', [
                'error' => $e->getMessage(),
                'user_id' => Auth::guard('api-customers')->id(),
                'note_id' => $id
            ]);
            return CommonHelper::responseError('Failed to delete note');
        }
    }

    /**
     * Toggle note selection (select/unselect)
     *
     * POST /api/customer/notes/{id}/toggle-select
     * Body: {
     *   "is_selected": true/false
     * }
     *
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function toggleSelect(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'is_selected' => 'required|boolean',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $user = Auth::guard('api-customers')->user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            $note = UserNote::where('id', $id)
                ->where('user_id', $user->id)
                ->first();

            if (!$note) {
                return CommonHelper::responseError('Note not found');
            }

            $note->is_selected = $request->is_selected;
            $note->save();

            $formattedNote = [
                'id' => $note->id,
                'text' => $note->note_text,
                'is_selected' => $note->is_selected,
                'order_index' => $note->order_index,
            ];

            return CommonHelper::responseWithData($formattedNote);
        } catch (\Exception $e) {
            Log::error('Failed to toggle note selection', [
                'error' => $e->getMessage(),
                'user_id' => Auth::guard('api-customers')->id(),
                'note_id' => $id
            ]);
            return CommonHelper::responseError('Failed to toggle note selection');
        }
    }

    /**
     * Bulk update notes (for reordering or batch select/unselect)
     *
     * POST /api/customer/notes/bulk-update
     * Body: {
     *   "notes": [
     *     {"id": 1, "is_selected": true, "order_index": 0},
     *     {"id": 2, "is_selected": false, "order_index": 1}
     *   ]
     * }
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function bulkUpdate(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'notes' => 'required|array',
            'notes.*.id' => 'required|integer|exists:user_notes,id',
            'notes.*.is_selected' => 'nullable|boolean',
            'notes.*.order_index' => 'nullable|integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $user = Auth::guard('api-customers')->user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            $updatedNotes = [];

            foreach ($request->notes as $noteData) {
                $note = UserNote::where('id', $noteData['id'])
                    ->where('user_id', $user->id)
                    ->first();

                if ($note) {
                    if (isset($noteData['is_selected'])) {
                        $note->is_selected = $noteData['is_selected'];
                    }
                    if (isset($noteData['order_index'])) {
                        $note->order_index = $noteData['order_index'];
                    }
                    $note->save();

                    $updatedNotes[] = [
                        'id' => $note->id,
                        'text' => $note->note_text,
                        'is_selected' => $note->is_selected,
                        'order_index' => $note->order_index,
                    ];
                }
            }

            return CommonHelper::responseWithData($updatedNotes, count($updatedNotes));
        } catch (\Exception $e) {
            Log::error('Failed to bulk update notes', [
                'error' => $e->getMessage(),
                'user_id' => Auth::guard('api-customers')->id()
            ]);
            return CommonHelper::responseError('Failed to update notes');
        }
    }

    /**
     * Get only selected notes
     *
     * GET /api/customer/notes/selected
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function getSelected()
    {
        try {
            $user = Auth::guard('api-customers')->user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            $notes = UserNote::where('user_id', $user->id)
                ->selected()
                ->ordered()
                ->get();

            $formattedNotes = $notes->map(function ($note) {
                return [
                    'id' => $note->id,
                    'text' => $note->note_text,
                    'is_selected' => $note->is_selected,
                    'order_index' => $note->order_index,
                    'created_at' => $note->created_at->toIso8601String(),
                ];
            });

            return CommonHelper::responseWithData($formattedNotes, $notes->count());
        } catch (\Exception $e) {
            Log::error('Failed to retrieve selected notes', [
                'error' => $e->getMessage(),
                'user_id' => Auth::guard('api-customers')->id()
            ]);
            return CommonHelper::responseError('Failed to retrieve selected notes');
        }
    }

    /**
     * Get products with variants based on selected notes
     * Searches for products matching note text and returns them grouped by note
     *
     * GET /api/customer/notes/products-by-selected-notes
     *
     * Response format:
     * [
     *   {
     *     "note_id": 1,
     *     "note_text": "Cow Ghee 500 g",
     *     "products": [
     *       {
     *         "id": 123,
     *         "name": "Pure Cow Ghee",
     *         "image_url": "...",
     *         "variants": [
     *           {"id": 1, "type": "500g", "price": "450", ...}
     *         ]
     *       }
     *     ]
     *   }
     * ]
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function getProductsBySelectedNotes()
    {
        try {
            $user = Auth::guard('api-customers')->user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Get all selected notes for the user
            $selectedNotes = UserNote::where('user_id', $user->id)
                ->where('is_selected', true)
                ->ordered()
                ->get();

            if ($selectedNotes->isEmpty()) {
                return CommonHelper::responseWithData([]);
            }

            $result = [];

            foreach ($selectedNotes as $note) {
                $noteText = $note->note_text;

                // Extract potential variant info from note text (e.g., "500g", "1kg", "500 gms")
                // Common patterns: 500g, 500 g, 500gm, 500 gms, 1kg, 1 kg, 500ml, 500 ml, etc.
                preg_match('/(\d+)\s*(g|gm|gms|gram|grams|kg|kgs|kilogram|kilograms|ml|ltr|litre|litres|l|piece|pieces|pcs)?/i', $noteText, $variantMatches);
                $hasVariantInfo = !empty($variantMatches);
                $variantNumber = $hasVariantInfo ? $variantMatches[1] : null;
                $variantUnit = $hasVariantInfo && isset($variantMatches[2]) ? strtolower($variantMatches[2]) : null;

                // Extract product name (remove variant info from search)
                $productNameSearch = $hasVariantInfo
                    ? trim(preg_replace('/\d+\s*(g|gm|gms|gram|grams|kg|kgs|kilogram|kilograms|ml|ltr|litre|litres|l|piece|pieces|pcs)?/i', '', $noteText))
                    : $noteText;

                // Search for products matching the note text
                $products = Product::select(
                    'p.*',
                    'p.type as d_type',
                    'p.total_allowed_quantity',
                    's.store_name as seller_name',
                    's.slug as seller_slug',
                    's.status as seller_status',
                    'pv.price',
                    'pv.discounted_price',
                    DB::raw("if(pv.discounted_price > 0, ceil(((pv.price - pv.discounted_price)/pv.price)*100), 0) as cal_discount_percentage"),
                    DB::raw("ceil((pv.price - pv.discounted_price)) as cal_discount"),
                    'co.name as country_made_in',
                    's.longitude',
                    's.latitude',
                    'cities.max_deliverable_distance',
                    'cities.boundary_points',
                    'tx.percentage as tax_percentage',
                    DB::raw("GROUP_CONCAT(t.name) as tag_names"),
                    DB::raw("MIN(IF(pv.discounted_price > 0, pv.discounted_price, pv.price)) as min_price"),
                    DB::raw("MAX(IF(pv.discounted_price > 0, pv.discounted_price, pv.price)) as max_price")
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
                    ->where(function ($query) use ($productNameSearch) {
                        $query->where('p.name', 'LIKE', '%' . $productNameSearch . '%')
                            ->orWhere('p.description', 'LIKE', '%' . $productNameSearch . '%');
                    })
                    ->groupBy("p.id")
                    ->with([
                        'variants' => function ($query) use ($hasVariantInfo, $variantNumber, $variantUnit) {
                            $query->where('status', 1)
                                ->with(['unit', 'images']);

                            // If variant info exists in note, filter variants
                            if ($hasVariantInfo && $variantNumber) {
                                $query->where(function ($q) use ($variantNumber, $variantUnit) {
                                    // Match by measurement + type (e.g., measurement=500, type contains 'g')
                                    $q->where('measurement', $variantNumber);

                                    // Also try to match the full type field (e.g., type="500g")
                                    if ($variantUnit) {
                                        $q->orWhere('type', 'LIKE', '%' . $variantNumber . '%')
                                            ->where('type', 'LIKE', '%' . $variantUnit . '%');
                                    } else {
                                        $q->orWhere('type', 'LIKE', '%' . $variantNumber . '%');
                                    }
                                });
                            }
                        },
                        'images',
                        'brand',
                        'category',
                        'seller',
                        'tax',
                        'ratings'
                    ])
                    ->get();

                // Format products with complete details from getProducts
                $formattedProducts = $products->map(function ($product) {
                    // Get tax percentage
                    $taxPercentage = $product->tax_percentage ?? 0;

                    // Calculate average rating
                    $avgRating = 0;
                    if ($product->ratings && is_countable($product->ratings) && count($product->ratings) > 0) {
                        $avgRating = $product->ratings->avg('rate') ?? 0;
                    }

                    return [
                        'id' => $product->id,
                        'name' => $product->name,
                        'slug' => $product->slug,
                        'description' => $product->description,
                        'image_url' => $product->image_url,
                        'indicator' => $product->indicator,
                        'type' => $product->d_type,
                        'barcode' => $product->barcode,
                        'min_price' => (float) $product->min_price,
                        'max_price' => (float) $product->max_price,
                        'discount_percentage' => (int) $product->cal_discount_percentage,
                        'discount_amount' => (float) $product->cal_discount,
                        'avg_rating' => round($avgRating, 2),
                        'country_made_in' => $product->country_made_in,
                        'brand' => $product->brand ? [
                            'id' => $product->brand->id,
                            'name' => $product->brand->name,
                        ] : null,
                        'category' => $product->category ? [
                            'id' => $product->category->id,
                            'name' => $product->category->name,
                        ] : null,
                        'seller' => $product->seller ? [
                            'id' => $product->seller->id,
                            'name' => $product->seller->name,
                            'store_name' => $product->seller->store_name,
                            'slug' => $product->seller->slug,
                            'latitude' => $product->seller->latitude,
                            'longitude' => $product->seller->longitude,
                        ] : null,
                        'seller_name' => $product->seller->store_name ?? '',
                        'tax_percentage' => $taxPercentage,
                        'total_allowed_quantity' => (int) $product->total_allowed_quantity,
                        'tag_names' => $product->tag_names ? explode(',', $product->tag_names) : [],
                        'variants' => $product->variants->map(function ($variant) use ($taxPercentage) {
                            $basePrice = ($variant->discounted_price > 0 && $variant->discounted_price !== null)
                                ? $variant->discounted_price
                                : $variant->price;

                            $taxAmount = ($basePrice * $taxPercentage) / 100;
                            $finalPrice = $basePrice + $taxAmount;

                            return [
                                'id' => $variant->id,
                                'product_id' => $variant->product_id,
                                'type' => $variant->type,
                                'measurement' => $variant->measurement,
                                'price' => (string) $variant->price,
                                'discounted_price' => $variant->discounted_price ? (string) $variant->discounted_price : '0',
                                'stock' => $variant->stock,
                                'stock_unit_name' => $variant->unit ? $variant->unit->short_code : '',
                                'tax_percentage' => $taxPercentage,
                                'final_price_with_tax' => (string) round($finalPrice, 2),
                                'images' => $variant->images->map(function ($img) {
                                    return [
                                        'id' => $img->id,
                                        'image' => $img->image ? (str_starts_with($img->image, 'http') ? $img->image : asset('storage/' . $img->image)) : '',
                                    ];
                                })->toArray(),
                            ];
                        })->toArray(),
                        'images' => $product->images->map(function ($img) {
                            return [
                                'id' => $img->id,
                                'image' => $img->image ? (str_starts_with($img->image, 'http') ? $img->image : asset('storage/' . $img->image)) : '',
                            ];
                        })->toArray(),
                    ];
                })->toArray();

                $result[] = [
                    'note_id' => $note->id,
                    'note_text' => $note->note_text,
                    'order_index' => $note->order_index,
                    'products' => $formattedProducts,
                    'products_count' => count($formattedProducts),
                ];
            }

            return CommonHelper::responseWithData($result, count($result));
        } catch (\Exception $e) {
            Log::error('Failed to get products by selected notes', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::guard('api-customers')->id()
            ]);
            return CommonHelper::responseError('Failed to retrieve products for selected notes');
        }
    }
}
