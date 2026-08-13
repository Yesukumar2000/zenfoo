<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Services\MediaUploadService;
use App\Services\SellerNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class SellerNotificationApiController extends Controller
{
    /**
     * Send notification to a single seller
     *
     * POST /api/seller-notifications/send
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function send(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'seller_id' => 'required|integer|exists:sellers,id',
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'image' => 'nullable|mimes:jpeg,jpg,png,gif,webp|max:5120',
            'image_url' => 'nullable|url',
            'page_navigation' => 'nullable|string|in:category,product,order,home,offers,wallet,profile,orders,new_order,url',
            'navigation_id' => 'nullable',
            'navigation_url' => 'nullable|url',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        // Handle image upload or URL
        $image = '';
        if ($request->hasFile('image')) {
            $image = MediaUploadService::upload(
                $request->file('image'),
                'notifications'
            );
            Log::info("SellerNotificationApiController: Image uploaded", ['image' => $image]);
        } elseif ($request->filled('image_url')) {
            $image = $request->image_url;
            Log::info("SellerNotificationApiController: Using image_url", ['image_url' => $image]);
        } else {
            Log::info("SellerNotificationApiController: No image provided", [
                'has_file' => $request->hasFile('image'),
                'has_image_url' => $request->has('image_url'),
                'image_url_filled' => $request->filled('image_url'),
                'all_params' => $request->all()
            ]);
        }

        // Build extra data if needed
        $extraData = [];
        if ($request->filled('navigation_url')) {
            $extraData['url'] = $request->navigation_url;
        }

        Log::info("SellerNotificationApiController: Calling service with image", [
            'image_param' => $image,
            'image_empty' => empty($image),
            'image_length' => strlen($image)
        ]);

        $result = SellerNotificationService::send(
            sellerId: $request->seller_id,
            title: $request->title,
            message: $request->message,
            image: $image,
            pageNavigation: $request->page_navigation ?? '',
            navigationId: $request->navigation_id,
            extraData: $extraData
        );

        if ($result['success']) {
            return CommonHelper::responseWithData($result, $result['message']);
        }

        return CommonHelper::responseError($result['message']);
    }

    /**
     * Send notification to multiple sellers
     *
     * POST /api/seller-notifications/send-bulk
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function sendBulk(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'seller_ids' => 'required|array|min:1',
            'seller_ids.*' => 'required|integer|exists:sellers,id',
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'image' => 'nullable|mimes:jpeg,jpg,png,gif,webp|max:5120',
            'image_url' => 'nullable|url',
            'page_navigation' => 'nullable|string|in:category,product,order,home,offers,wallet,profile,orders,new_order,url',
            'navigation_id' => 'nullable',
            'navigation_url' => 'nullable|url',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        // Handle image upload or URL
        $image = '';
        if ($request->hasFile('image')) {
            $image = MediaUploadService::upload(
                $request->file('image'),
                'notifications'
            );
        } elseif ($request->filled('image_url')) {
            $image = $request->image_url;
        }

        // Build extra data if needed
        $extraData = [];
        if ($request->filled('navigation_url')) {
            $extraData['url'] = $request->navigation_url;
        }

        $result = SellerNotificationService::sendToMultiple(
            sellerIds: $request->seller_ids,
            title: $request->title,
            message: $request->message,
            image: $image,
            pageNavigation: $request->page_navigation ?? '',
            navigationId: $request->navigation_id,
            extraData: $extraData
        );

        if ($result['success']) {
            return CommonHelper::responseWithData($result, $result['message']);
        }

        return CommonHelper::responseError($result['message']);
    }

    /**
     * Test notification endpoint - sends a test notification to a seller
     *
     * POST /api/seller-notifications/send-test
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function sendTest(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'seller_id' => 'required|integer|exists:sellers,id',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $result = SellerNotificationService::send(
            sellerId: $request->seller_id,
            title: 'Test Notification',
            message: 'This is a test notification from Zenfoo Admin Panel.',
            image: '',
            pageNavigation: 'home',
            navigationId: null
        );

        if ($result['success']) {
            return CommonHelper::responseWithData($result, 'Test notification sent successfully');
        }

        return CommonHelper::responseError($result['message']);
    }

    /**
     * Get notifications for the authenticated seller
     *
     * GET /api/seller/notifications
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        try {
            $user = auth()->user();
            if (!$user) {
                return CommonHelper::responseError('Unauthorized', 401);
            }

            // Find the seller linked to this user
            $seller = \App\Models\Seller::where('admin_id', $user->id)->first();
            if (!$seller) {
                return CommonHelper::responseError('Seller account not found', 404);
            }

            $sellerId = $seller->id;
            $perPage = $request->input('per_page', 20);

            $query = \App\Models\Notification::where('role_name', 'seller')
                ->where('user_id', $sellerId)
                ->orderBy('id', 'DESC');

            $total = $query->count();
            $notifications = $query->paginate($perPage);

            $formattedNotifications = $notifications->getCollection()->transform(function ($notification) {
                return [
                    'id' => $notification->id,
                    'title' => $notification->title,
                    'message' => $notification->message,
                    'type' => $notification->type,
                    'type_id' => $notification->type_id,
                    'image_url' => CommonHelper::getImage($notification->image),
                    'link_url' => $notification->type_link,
                    'date_sent' => $notification->date_sent,
                    'created_at' => $notification->created_at
                ];
            });

            $response = [
                'current_page' => $notifications->currentPage(),
                'last_page' => $notifications->lastPage(),
                'per_page' => $notifications->perPage(),
                'total' => $total,
                'data' => $formattedNotifications,
            ];

            return CommonHelper::responseWithData($response, $total);
        } catch (\Exception $e) {
            Log::error('SellerNotificationApiController: Error in index', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to fetch notifications');
        }
    }
}
