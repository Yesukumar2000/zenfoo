<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderStatus;
use App\Models\OrderStatusList;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\Setting;
use App\Models\User;
use App\Models\Seller;
use App\Models\Transaction;
use App\Models\UserAddress;
use App\Notifications\OrderNotification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Hash;
use App\Models\Admin;
use App\Models\Category;

class SellerPosController extends Controller
{
    public function getUsersList(Request $request)
    {
        try {
            $search = $request->input('search', '');
            $limit = $request->input('limit', 0);

            // Get POS users
            $posUsers = DB::table('pos_users')
                ->select('id', 'name', 'phone as mobile', DB::raw("'pos' as user_type"), DB::raw("NULL as email"));

            // Apply search if provided
            if (!empty($search)) {
                $posUsers->where(function($query) use ($search) {
                    $query->where('name', 'like', '%' . $search . '%')
                          ->orWhere('phone', 'like', '%' . $search . '%');
                });
            }

            $posUsers->orderBy('id', 'DESC');

            // Get regular users
            $regUsers = DB::table('users')
                ->select('id', 'name', 'mobile', DB::raw("'user' as user_type"), 'email');

            // Apply search if provided
            if (!empty($search)) {
                $regUsers->where(function($query) use ($search) {
                    $query->where('name', 'like', '%' . $search . '%')
                          ->orWhere('mobile', 'like', '%' . $search . '%')
                          ->orWhere('email', 'like', '%' . $search . '%');
                });
            }

            $regUsers->orderBy('id', 'DESC');

            // Combine users
            $query = $posUsers->union($regUsers);

            // Apply limit if specified
            if ($limit > 0) {
                $users = $query->limit($limit)->get();
            } else {
                $users = $query->get();
            }

            return CommonHelper::responseWithData($users);
        } catch (\Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    public function registerUser(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string',
            'mobile' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            // Check if user with the same mobile already exists
            if (!empty($request->mobile)) {
                $existingUser = DB::table('pos_users')->where('phone', $request->mobile)->first();
                if ($existingUser) {
                    return response()->json([
                        'status' => false,
                        'message' => 'User with this phone number already exists'
                    ], 422);
                }
            }

            // Create new user in pos_users table
            $userId = DB::table('pos_users')->insertGetId([
                'name' => $request->name,
                'phone' => $request->mobile ?? null,
                'created_at' => now(),
                'updated_at' => now()
            ]);

            $user = DB::table('pos_users')->find($userId);

            return response()->json([
                'status' => true,
                'message' => 'User registered successfully',
                'data' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'mobile' => $user->phone
                ]
            ]);
        } catch (\Exception $e) {
            Log::error("Error registering user: " . $e->getMessage());
            return response()->json([
                'status' => false,
                'message' => 'Something went wrong. Please try again.'
            ], 500);
        }
    }

    public function placeOrder(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'nullable',
            'user_type' => 'nullable|in:pos,user',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.product_variant_id' => 'required|exists:product_variants,id',
            'items.*.quantity' => 'required|numeric|min:1',
            'payment_method' => 'required|in:cash,card,upi',
            'total' => 'required|numeric',
            'final_total' => 'required|numeric',
            'discount_amount' => 'nullable|numeric',
            'discount_percentage' => 'nullable|numeric',
            'additional_charges' => 'nullable|array',
            'additional_charges.*.charge_name' => 'required_with:additional_charges',
            'additional_charges.*.amount' => 'required_with:additional_charges|numeric',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        DB::beginTransaction();
        try {
            // Get user info if provided
            $user = null;
            if ($request->user_id && $request->user_type) {
                if ($request->user_type === 'pos') {
                    $user = DB::table('pos_users')->find($request->user_id);
                } else {
                    $user = DB::table('users')->find($request->user_id);
                }
            }

            // Check if all products are available and have enough stock
            foreach ($request->items as $item) {
                $productVariant = ProductVariant::find($item['product_variant_id']);
                if (!$productVariant) {
                    return response()->json([
                        'status' => false,
                        'message' => 'Product variant not found'
                    ], 404);
                }

                $product = Product::find($item['product_id']);
                if (!$product || $product->status != 1) {
                    return response()->json([
                        'status' => false,
                        'message' => "Product '{$product->name}' is not available"
                    ], 422);
                }

                // Skip stock validation for unlimited stock products
                if (!$product->is_unlimited_stock && $productVariant->stock < $item['quantity']) {
                    return response()->json([
                        'status' => false,
                        'message' => "Not enough stock for '{$product->name}'"
                    ], 422);
                }
            }

            // Generate unique order ID
            $orders_id = 'POS' . date('YmdHis') . rand(10, 99);

            // Create order data array
            $orderData = [
                'pos_user_id' => ($request->user_type === 'pos') ? $request->user_id : null,
                'user_id' => ($request->user_type === 'user') ? $request->user_id : null,
                'store_id' => auth()->user()->seller->id,
                'total_amount' => $request->final_total,
                'discount_amount' => $request->discount_amount ?? 0,
                'discount_percentage' => $request->discount_percentage ?? 0,
                'payment_method' => $request->payment_method,
                'created_at' => now(),
                'updated_at' => now()
            ];

            // Create order in pos_orders table
            $posOrderId = DB::table('pos_orders')->insertGetId($orderData);

            // Add additional charges if provided
            if (!empty($request->additional_charges)) {
                foreach ($request->additional_charges as $charge) {
                    DB::table('pos_additional_charges')->insert([
                        'pos_order_id' => $posOrderId,
                        'charge_name' => $charge['charge_name'],
                        'amount' => $charge['amount'],
                        'created_at' => now(),
                        'updated_at' => now()
                    ]);
                }
            }

            // Add order items and update stock
            foreach ($request->items as $item) {
                $productVariant = ProductVariant::with(['product', 'unit'])->find($item['product_variant_id']);
                $product = Product::find($item['product_id']);

                // Calculate item prices
                $price = $productVariant->discounted_price > 0 ? $productVariant->discounted_price : $productVariant->price;
                $subtotal = $price * $item['quantity'];

                // Add order item to pos_order_items table
                DB::table('pos_order_items')->insert([
                    'pos_order_id' => $posOrderId,
                    'product_id' => $item['product_id'],
                    'product_variant_id' => $item['product_variant_id'],
                    'quantity' => $item['quantity'],
                    'unit_price' => $price,
                    'total_price' => $subtotal,
                    'created_at' => now(),
                    'updated_at' => now()
                ]);

                // Update product stock - using the logic from OrderApiController
                if (!$product->is_unlimited_stock) {
                    if ($product->type == 'packet') {
                        // For packet products, decrease stock by quantity
                        $stock = $productVariant->stock - $item['quantity'];
                        $productVariant->stock = $stock;
                        $productVariant->save();

                        if ($productVariant->stock <= 0) {
                            $productVariant->status = 0; // 0 = Sold Out
                            $productVariant->save();
                        }
                    } else if ($product->type == 'loose') {
                        // For loose products, decrease stock by weight
                        $stock = max(0, $productVariant->stock - ($productVariant->measurement * $item['quantity']));

                        // Update main product variant stock
                        $productVariant->stock = $stock;
                        if ($stock <= 0) {
                            $productVariant->status = 0; // 0 = Sold Out
                        }
                        $productVariant->save();

                        // Update other variants with same product and stock unit
                        ProductVariant::where("product_id", $product->id)
                            ->where("stock_unit_id", $productVariant->stock_unit_id) // Only same unit type
                            ->where("id", '!=', $productVariant->id) // Exclude current variant
                            ->update([
                                'stock' => $stock,
                                'status' => $stock <= 0 ? 0 : 1 // 0 = Sold Out, 1 = Available
                            ]);
                    }
                }
            }

            DB::commit();

            return response()->json([
                'status' => true,
                'message' => 'Order placed successfully',
                'data' => [
                    'pos_order_id' => $posOrderId,
                    'order_number' => $orders_id,
                    'status' => 'completed'
                ]
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("Error placing order: " . $e->getMessage());
            return response()->json([
                'status' => false,
                'message' => 'Something went wrong. Please try again.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function getProducts(Request $request)
    {
        try {
            $sellerId = auth()->user()->seller->id;
            $perPage = $request->per_page ?? 9;
            $page = $request->page ?? 1;

            $productQuery = Product::select('products.*')
                ->where('products.seller_id', $sellerId)
                ->where('products.status', 1)
                ->with(['variants' => function($query) {
                    $query->with('unit'); // Remove status filter to show all variants including sold out ones
                }]);

            // Apply category filter if provided
            if ($request->category_id) {
                $productQuery->where('category_id', $request->category_id);
            }

            // Apply search filter if provided
            if ($request->search) {
                $search = $request->search;
                $productQuery->where(function($query) use ($search) {
                    $query->where('products.name', 'like', '%' . $search . '%')
                          ->orWhere('products.slug', 'like', '%' . $search . '%')
                          ->orWhere('products.tags', 'like', '%' . $search . '%');
                });
            }

            $totalProducts = $productQuery->count();
            $products = $productQuery->orderBy('id', 'DESC')
                ->paginate($perPage, ['*'], 'page', $page);

            // Transform products for POS display
            $transformedProducts = $products->map(function ($product) {
                $variant = $product->variants->isNotEmpty() ? $product->variants[0] : null;

                return [
                    'id' => $product->id,
                    'name' => $product->name,
                    'description' => $product->description,
                    'image_url' => CommonHelper::getImage($product->image),
                    'is_unlimited_stock' => (bool)$product->is_unlimited_stock,
                    'variants' => $product->variants->map(function($variant) use ($product) {
                        return [
                            'id' => $variant->id,
                            'measurement' => $variant->measurement,
                            'measurement_unit_name' => $variant->unit ? $variant->unit->short_code : '',
                            'price' => $variant->price,
                            'discounted_price' => $variant->discounted_price,
                            'stock' => $variant->stock,
                            'status' => $variant->status
                        ];
                    })
                ];
            });

            $response = [
                'status' => true,
                'data' => $transformedProducts,
                'meta' => [
                    'total' => $totalProducts,
                    'current_page' => $products->currentPage(),
                    'last_page' => $products->lastPage(),
                    'per_page' => $products->perPage(),
                    'from' => $products->firstItem() ?? 0,
                    'to' => $products->lastItem() ?? 0
                ]
            ];

            return response()->json($response);

        } catch (\Exception $e) {
            Log::error("Error fetching products: " . $e->getMessage());
            return response()->json([
                'status' => false,
                'message' => 'Something went wrong while fetching products.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function getSellerCategories()
    {
        try {
            $seller = auth()->user()->seller;

            if (!$seller) {
                return response()->json([
                    'status' => false,
                    'message' => 'Seller profile not found'
                ], 404);
            }

            $categories = Category::whereIn('id', explode(",", $seller->categories))
                ->where('status', 1)
                ->orderBy('name', 'ASC')
                ->get()
                ->map(function($category) {
                    return [
                        'id' => $category->id,
                        'name' => $category->name,
                        'image' => CommonHelper::getImage($category->image)
                    ];
                });

            return response()->json([
                'status' => true,
                'data' => $categories
            ]);

        } catch (\Exception $e) {
            Log::error("Error fetching categories: " . $e->getMessage());
            return response()->json([
                'status' => false,
                'message' => 'Something went wrong while fetching categories.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function updateOrder(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|exists:pos_orders,id',
            'items' => 'required|array',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.product_variant_id' => 'required|exists:product_variants,id',
            'items.*.quantity' => 'required|numeric|min:1',
            'payment_method' => 'required|in:cash,card,upi',
            'discount_amount' => 'nullable|numeric',
            'discount_percentage' => 'nullable|numeric',
            'additional_charges' => 'nullable|array',
            'additional_charges.*.charge_name' => 'required_with:additional_charges',
            'additional_charges.*.amount' => 'required_with:additional_charges|numeric',
            'user_id' => 'nullable',
            'user_type' => 'nullable|in:pos,user',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        DB::beginTransaction();
        try {
            // Get the existing order
            $order = DB::table('pos_orders')->where('id', $request->order_id)->first();

            if (!$order) {
                return response()->json([
                    'status' => false,
                    'message' => 'Order not found'
                ], 404);
            }

            // Verify seller owns the order
            if ($order->store_id != auth()->user()->seller->id) {
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized access to this order'
                ], 403);
            }

            // Get existing order items
            $existingItems = DB::table('pos_order_items')
                ->where('pos_order_id', $request->order_id)
                ->get();

            // Create composite keys for existing and new items (product_id + variant_id)
            $existingItemsMap = [];
            foreach($existingItems as $item) {
                $key = $item->product_id . '_' . $item->product_variant_id;
                $existingItemsMap[$key] = $item;
            }

            // Create a map of new items
            $newItemsMap = [];
            foreach($request->items as $item) {
                $key = $item['product_id'] . '_' . $item['product_variant_id'];
                $newItemsMap[$key] = $item;
            }

            // Find keys to remove (in existing but not in new)
            $keysToRemove = array_diff(array_keys($existingItemsMap), array_keys($newItemsMap));

            // Step 1: Handle removed items - restore stock and delete from database
            foreach ($keysToRemove as $key) {
                $removedItem = $existingItemsMap[$key];

                // Restore stock if variant exists
                if ($removedItem->product_variant_id) {
                    $productVariant = ProductVariant::with('product')->find($removedItem->product_variant_id);

                    if ($productVariant && $productVariant->is_unlimited_stock != 1) {
                        $product = $productVariant->product;

                        if ($product) {
                            // Restore stock based on product type
                            if ($product->type == 'packet') {
                                $newStock = $productVariant->stock + $removedItem->quantity;
                                $productVariant->stock = $newStock;

                                if ($productVariant->status == 0 && $newStock > 0) {
                                    $productVariant->status = 1; // Set back to available
                                }

                                $productVariant->save();

                            } else if ($product->type == 'loose') {
                                $weightToRestore = $productVariant->measurement * $removedItem->quantity;
                                $newStock = $productVariant->stock + $weightToRestore;

                                $productVariant->stock = $newStock;

                                if ($productVariant->status == 0 && $newStock > 0) {
                                    $productVariant->status = 1; // Set back to available
                                }

                                $productVariant->save();

                                // Update other variants with same stock unit
                                ProductVariant::where("product_id", $product->id)
                                    ->where("stock_unit_id", $productVariant->stock_unit_id)
                                    ->where("id", '!=', $productVariant->id)
                                    ->update([
                                        'stock' => $newStock,
                                        'status' => $newStock <= 0 ? 0 : 1
                                    ]);
                            }
                        }
                    }
                }

                // Delete the item from the order
                $deleted = DB::table('pos_order_items')
                    ->where('id', $removedItem->id)
                    ->delete();

            }

            // Step 2: Process remaining items (update existing or add new)
            foreach ($request->items as $item) {
                $productId = $item['product_id'];
                $productVariantId = $item['product_variant_id'];
                $newQuantity = $item['quantity'];
                $compositeKey = $productId . '_' . $productVariantId;

                $productVariant = ProductVariant::with(['product'])->find($productVariantId);
                if (!$productVariant || !$productVariant->product) {
                    continue;
                }

                $product = $productVariant->product;
                $price = $productVariant->discounted_price > 0 ? $productVariant->discounted_price : $productVariant->price;
                $subtotal = $price * $newQuantity;

                // Find if this item (with same product AND variant) exists in the original order
                $existingItem = isset($existingItemsMap[$compositeKey]) ? $existingItemsMap[$compositeKey] : null;

                if ($existingItem) {
                    // Item exists, update it and adjust stock
                    $oldQuantity = $existingItem->quantity;
                    $quantityDiff = $oldQuantity - $newQuantity; // positive means stock to add back

                    // Update the item in database
                    DB::table('pos_order_items')
                        ->where('id', $existingItem->id)
                        ->update([
                            'product_variant_id' => $productVariantId,
                            'quantity' => $newQuantity,
                            'unit_price' => $price,
                            'total_price' => $subtotal,
                            'updated_at' => now()
                        ]);

                    // Adjust stock if quantity changed and not unlimited
                    if ($quantityDiff != 0 && $productVariant->is_unlimited_stock != 1) {
                        if ($product->type == 'packet') {
                            // Add stock back or remove more stock
                            $newStock = $productVariant->stock + $quantityDiff;
                            $productVariant->stock = max(0, $newStock);

                            // Update status based on stock
                            if ($newStock <= 0) {
                                $productVariant->status = 0; // Sold out
                            } else if ($productVariant->status == 0 && $newStock > 0) {
                                $productVariant->status = 1; // Available
                            }

                            $productVariant->save();
                        } else if ($product->type == 'loose') {
                            // For loose products, adjust by weight
                            $weightAdjustment = $productVariant->measurement * $quantityDiff;
                            $newStock = $productVariant->stock + $weightAdjustment;
                            $productVariant->stock = max(0, $newStock);

                            // Update status based on stock
                            if ($newStock <= 0) {
                                $productVariant->status = 0; // Sold out
                            } else if ($productVariant->status == 0 && $newStock > 0) {
                                $productVariant->status = 1; // Available
                            }

                            $productVariant->save();

                            // Update other variants with same stock unit
                            ProductVariant::where("product_id", $product->id)
                                ->where("stock_unit_id", $productVariant->stock_unit_id)
                                ->where("id", '!=', $productVariant->id)
                                ->update([
                                    'stock' => max(0, $newStock),
                                    'status' => $newStock <= 0 ? 0 : 1
                                ]);
                        }
                    }
                } else {
                    // Add new item to order
                    DB::table('pos_order_items')->insert([
                        'pos_order_id' => $request->order_id,
                        'product_id' => $productId,
                        'product_variant_id' => $productVariantId,
                        'quantity' => $newQuantity,
                        'unit_price' => $price,
                        'total_price' => $subtotal,
                        'created_at' => now(),
                        'updated_at' => now()
                    ]);

                    // Reduce stock for new item (if not unlimited)
                    if ($productVariant->is_unlimited_stock != 1) {
                        if ($product->type == 'packet') {
                            // For packet products, decrease stock by quantity
                            $newStock = max(0, $productVariant->stock - $newQuantity);
                            $productVariant->stock = $newStock;

                            if ($newStock <= 0) {
                                $productVariant->status = 0; // Sold out
                            }

                            $productVariant->save();
                        } else if ($product->type == 'loose') {
                            // For loose products, decrease stock by weight
                            $weightToReduce = $productVariant->measurement * $newQuantity;
                            $newStock = max(0, $productVariant->stock - $weightToReduce);

                            $productVariant->stock = $newStock;
                            if ($newStock <= 0) {
                                $productVariant->status = 0; // Sold out
                            }

                            $productVariant->save();

                            // Update other variants with same stock unit
                            ProductVariant::where("product_id", $product->id)
                                ->where("stock_unit_id", $productVariant->stock_unit_id)
                                ->where("id", '!=', $productVariant->id)
                                ->update([
                                    'stock' => $newStock,
                                    'status' => $newStock <= 0 ? 0 : 1
                                ]);
                        }
                    }
                }
            }

            // Update order data (discount, payment method, user, etc.)
            $updateData = [
                'total_amount' => $request->final_total,
                'discount_amount' => $request->discount_amount ?? 0,
                'discount_percentage' => $request->discount_percentage ?? 0,
                'payment_method' => $request->payment_method,
                'updated_at' => now()
            ];

            // Update user information if provided
            if ($request->has('user_id') && $request->has('user_type')) {
                if ($request->user_type === 'pos') {
                    $updateData['pos_user_id'] = $request->user_id;
                    $updateData['user_id'] = null;
                } else {
                    $updateData['user_id'] = $request->user_id;
                    $updateData['pos_user_id'] = null;
                }
            } else if ($request->has('user_id') === false && $request->has('user_type') === false) {
                // If no user is selected (cash sale), clear both user fields
                $updateData['user_id'] = null;
                $updateData['pos_user_id'] = null;
            }

            DB::table('pos_orders')
                ->where('id', $request->order_id)
                ->update($updateData);

            // Update additional charges
            DB::table('pos_additional_charges')
                ->where('pos_order_id', $request->order_id)
                ->delete();

            if (!empty($request->additional_charges)) {
                foreach ($request->additional_charges as $charge) {
                    DB::table('pos_additional_charges')->insert([
                        'pos_order_id' => $request->order_id,
                        'charge_name' => $charge['charge_name'],
                        'amount' => $charge['amount'],
                        'created_at' => now(),
                        'updated_at' => now()
                    ]);
                }
            }

            DB::commit();

            return response()->json([
                'status' => true,
                'message' => 'Order updated successfully',
                'data' => [
                    'pos_order_id' => $request->order_id
                ]
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("Error updating order: " . $e->getMessage());
            Log::error($e->getTraceAsString());
            return response()->json([
                'status' => false,
                'message' => 'Something went wrong. Please try again.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function showInvoice($id)
    {
        try {

            // Get the order
            $order = DB::table('pos_orders')
                ->select('pos_orders.*')
                ->where('pos_orders.id', $id)
                ->first();

            if (!$order) {
                Log::error("POS Order not found for ID: " . $id);
                return response()->view('errors.404', [], 404);
            }

            // Get order items
            $order_items = DB::table('pos_order_items')
                ->select(
                    'pos_order_items.*',
                    'products.name as product_name'
                )
                ->leftJoin('products', 'pos_order_items.product_id', '=', 'products.id')
                ->where('pos_order_items.pos_order_id', $id)
                ->get();

            // Add variant names to order items
            foreach($order_items as $item) {
                $variant = ProductVariant::find($item->product_variant_id);
                if ($variant) {
                    $item->variant_name = $variant->measurement . " " .
                        (($variant->unit) ? $variant->unit->short_code : "");
                } else {
                    $item->variant_name = '';
                }
            }

            // Get user details
            if ($order->user_id) {
                $user = DB::table('users')->select('id', 'name', 'email', 'mobile')->where('id', $order->user_id)->first();
                if ($user) {
                    $order->user_name = $user->name;
                    $order->user_email = $user->email;
                    $order->mobile = $user->mobile;
                }
            } elseif ($order->pos_user_id) {
                $posUser = DB::table('pos_users')->select('id', 'name', 'phone')->where('id', $order->pos_user_id)->first();
                if ($posUser) {
                    $order->user_name = $posUser->name;
                    $order->mobile = $posUser->phone;
                }
            } else {
                // If no user or POS user is associated, set as Cash Sale
                $order->user_name = "Cash Sale";
            }

            // Get seller details - using direct DB query to avoid relationship issues
            try {
                $seller = DB::table('sellers')->where('id', $order->store_id)->first();
                if ($seller) {
                    $order->store_name = $seller->name;
                    $order->seller_name = $seller->name;
                    $order->seller_email = $seller->email;
                    $order->seller_mobile = $seller->mobile;
                }
            } catch (\Exception $e) {
                Log::warning("Error getting seller details: " . $e->getMessage());
                // Continue without seller details
            }

            // Get additional charges
            $additional_charges = DB::table('pos_additional_charges')
                ->where('pos_order_id', $id)
                ->get();

            // Check if view exists
            if(!view()->exists('pos_invoice')) {
                return response()->view('errors.404', ['message' => 'Invoice template not found'], 404);
            }

            return view('pos_invoice', compact('order', 'order_items', 'additional_charges'));

        } catch (\Exception $e) {
            Log::error("Error showing POS invoice: " . $e->getMessage());
            return response()->view('errors.500', ['message' => 'Error generating invoice: ' . $e->getMessage()], 500);
        }
    }

    public function getSellerStoreName()
    {
        try {
            $userId = auth()->id();

            // Find the seller where admin_id matches the authenticated user's ID
            $seller = DB::table('sellers')
                ->where('admin_id', $userId)
                ->select('name as store_name')
                ->first();

            if (!$seller) {
                return response()->json([
                    'status' => false,
                    'message' => 'Seller not found for this user'
                ], 404);
            }

            return response()->json([
                'status' => true,
                'data' => [
                    'store_name' => $seller->store_name
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Error fetching store name: ' . $e->getMessage()
            ], 500);
        }
    }
}
