<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Bookmark;
use App\Models\Product;
use App\Models\Seller;
use App\Models\Combo;
use App\Services\CustomerNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class WishlistsApiController extends Controller
{
    public function index()
    {
        // Get all bookmarks with user and bookmarkable relationships
        $bookmarks = Bookmark::with(['user', 'bookmarkable'])
            ->orderBy('id', 'DESC')
            ->get();

        // Format the bookmarks to include type-specific data
        $wishlists = $bookmarks->map(function ($bookmark) {
            $data = [
                'id' => $bookmark->id,
                'user_id' => $bookmark->user_id,
                'user_name' => $bookmark->user?->name ?? 'N/A',
                'type' => $bookmark->type, // product, seller, combo
                'bookmarkable_type' => $bookmark->bookmarkable_type,
                'bookmarkable_id' => $bookmark->bookmarkable_id,
                'created_at' => $bookmark->created_at,
                'updated_at' => $bookmark->updated_at,
            ];

            // Add type-specific details
            if ($bookmark->bookmarkable) {
                switch ($bookmark->type) {
                    case 'product':
                        $product = $bookmark->bookmarkable;
                        $data['item_name'] = $product->name ?? 'N/A';
                        $data['item_image'] = $product->image ?? null;
                        $data['seller_name'] = $product->seller?->name ?? 'N/A';
                        $data['seller_id'] = $product->seller_id ?? null;
                        break;

                    case 'seller':
                        $seller = $bookmark->bookmarkable;
                        $data['item_name'] = $seller->name ?? 'N/A';
                        $data['item_image'] = $seller->logo ?? null;
                        $data['seller_name'] = $seller->name ?? 'N/A'; // For consistency
                        $data['seller_id'] = $seller->id ?? null;
                        $data['store_id'] = $seller->store_id ?? null;
                        break;

                    case 'combo':
                        $combo = $bookmark->bookmarkable;
                        $data['item_name'] = $combo->name ?? 'N/A';
                        $data['item_image'] = $combo->image ?? null;
                        $data['combo_price'] = $combo->price ?? null;
                        $data['seller_name'] = 'N/A'; // Combos don't have direct sellers
                        $data['seller_id'] = null;
                        break;
                }
            } else {
                // If bookmarkable item was deleted
                $data['item_name'] = 'Deleted Item';
                $data['item_image'] = null;
                $data['seller_name'] = 'N/A';
                $data['seller_id'] = null;
            }

            return $data;
        });

        // Get statistics
        $stats = [
            'total_bookmarks' => $bookmarks->count(),
            'products_count' => $bookmarks->where('type', 'product')->count(),
            'sellers_count' => $bookmarks->where('type', 'seller')->count(),
            'combos_count' => $bookmarks->where('type', 'combo')->count(),
        ];

        return CommonHelper::responseWithData([
            'wishlists' => $wishlists->values(),
            'stats' => $stats,
        ]);
    }

    /**
     * Send notification to customers who bookmarked a specific item
     * Use this to notify customers about sales, new offers, or availability
     *
     * POST /api/wishlists/send-notification
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function sendNotification(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'type' => 'required|in:product,seller,combo',
            'item_id' => 'required|integer',
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'image' => 'nullable|url',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $type = $request->type;
            $itemId = $request->item_id;

            // Get bookmarkable type
            $bookmarkableType = $this->getBookmarkableType($type);
            if (!$bookmarkableType) {
                return CommonHelper::responseError('Invalid bookmark type');
            }

            // Verify item exists
            $item = $bookmarkableType::find($itemId);
            if (!$item) {
                return CommonHelper::responseError("Item not found for type: {$type}");
            }

            // Get all users who bookmarked this item
            $bookmarks = Bookmark::where('bookmarkable_type', $bookmarkableType)
                ->where('bookmarkable_id', $itemId)
                ->with('user')
                ->get();

            if ($bookmarks->isEmpty()) {
                return CommonHelper::responseError('No customers have bookmarked this item');
            }

            $customerIds = $bookmarks->pluck('user_id')->unique()->toArray();

            Log::info("WishlistNotification: Sending notification to bookmarked users", [
                'type' => $type,
                'item_id' => $itemId,
                'customer_count' => count($customerIds)
            ]);

            // Determine navigation type and ID
            $pageNavigation = $type; // 'product', 'seller', or 'combo'
            $navigationId = $itemId;

            // If type is combo, we need to handle it differently
            // as the app might not have direct combo navigation
            if ($type === 'combo') {
                $pageNavigation = 'product'; // Navigate to first product in combo
                // Get first product from combo if available
                $firstProduct = $item->products()->first();
                if ($firstProduct) {
                    $navigationId = $firstProduct->id;
                }
            }

            // Send notification to all customers
            $result = CustomerNotificationService::sendToMultiple(
                customerIds: $customerIds,
                title: $request->title,
                message: $request->message,
                image: $request->image ?? '',
                pageNavigation: $pageNavigation,
                navigationId: $navigationId,
                extraData: [
                    'bookmark_type' => $type,
                    'bookmark_item_id' => $itemId,
                    'bookmark_item_name' => $item->name ?? 'Item',
                ]
            );

            return CommonHelper::responseWithData([
                'result' => $result,
                'item' => [
                    'type' => $type,
                    'id' => $itemId,
                    'name' => $item->name ?? 'N/A',
                ],
                'customers_notified' => count($customerIds),
            ], "Notification sent successfully to {$result['success_count']} customers");

        } catch (\Exception $e) {
            Log::error("WishlistNotification: Error sending notification", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to send notification: " . $e->getMessage());
        }
    }

    /**
     * Send notification to specific users from wishlist
     * Use this to send targeted notifications to specific customers
     *
     * POST /api/wishlists/send-notification-to-users
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function sendNotificationToUsers(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'bookmark_ids' => 'required|array|min:1',
            'bookmark_ids.*' => 'integer',
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'image' => 'nullable|url',
            'page_navigation' => 'nullable|string|in:category,product,order,home,offers,wallet,profile,orders,cart,url',
            'navigation_id' => 'nullable',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            // Get bookmarks by IDs
            $bookmarks = Bookmark::whereIn('id', $request->bookmark_ids)
                ->with(['user', 'bookmarkable'])
                ->get();

            if ($bookmarks->isEmpty()) {
                return CommonHelper::responseError('No bookmarks found with the provided IDs');
            }

            // Get unique customer IDs
            $customerIds = $bookmarks->pluck('user_id')->unique()->toArray();

            Log::info("WishlistNotification: Sending notification to selected users", [
                'bookmark_ids' => $request->bookmark_ids,
                'customer_count' => count($customerIds)
            ]);

            // Send notification to all selected customers
            $result = CustomerNotificationService::sendToMultiple(
                customerIds: $customerIds,
                title: $request->title,
                message: $request->message,
                image: $request->image ?? '',
                pageNavigation: $request->page_navigation ?? 'home',
                navigationId: $request->navigation_id,
                extraData: [
                    'source' => 'wishlist_admin',
                    'bookmark_ids' => $request->bookmark_ids,
                ]
            );

            return CommonHelper::responseWithData([
                'result' => $result,
                'customers_notified' => count($customerIds),
                'bookmarks_count' => $bookmarks->count(),
            ], "Notification sent successfully to {$result['success_count']} customers");

        } catch (\Exception $e) {
            Log::error("WishlistNotification: Error sending notification to users", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to send notification: " . $e->getMessage());
        }
    }

    /**
     * Map bookmark type to model class name
     */
    private function getBookmarkableType($type)
    {
        $mapping = [
            'product' => Product::class,
            'seller' => Seller::class,
            'combo' => Combo::class,
        ];

        return $mapping[$type] ?? null;
    }
}
