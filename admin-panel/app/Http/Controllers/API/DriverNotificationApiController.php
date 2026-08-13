<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Services\DriverNotificationService;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class DriverNotificationApiController extends Controller
{
    /**
     * Send notification to a single driver
     *
     * POST /api/driver-notifications/send
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function send(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'driver_id' => 'required|integer|exists:delivery_boys,id',
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'image' => 'nullable|mimes:jpeg,jpg,png,gif,webp|max:5120',
            'image_url' => 'nullable|url',
            'type' => 'nullable|string|in:order,general,promo,category,product,home,url',
            'order_item_id' => 'nullable|integer|exists:order_items,id',
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
            Log::info("DriverNotificationApiController: Image uploaded", ['image' => $image]);
        } elseif ($request->filled('image_url')) {
            $image = $request->image_url;
            Log::info("DriverNotificationApiController: Using image_url", ['image_url' => $image]);
        }

        // Build extra data if needed
        $extraData = [];
        if ($request->filled('navigation_url')) {
            $extraData['url'] = $request->navigation_url;
        }

        Log::info("DriverNotificationApiController: Calling service with image", [
            'image_param' => $image,
            'image_empty' => empty($image),
            'image_length' => strlen($image)
        ]);

        $result = DriverNotificationService::send(
            driverId: $request->driver_id,
            title: $request->title,
            message: $request->message,
            image: $image,
            type: $request->type ?? 'general',
            orderItemId: $request->order_item_id,
            extraData: $extraData
        );

        if ($result['success']) {
            return CommonHelper::responseWithData($result, $result['message']);
        }

        return CommonHelper::responseError($result['message']);
    }

    /**
     * Send notification to multiple drivers
     *
     * POST /api/driver-notifications/send-bulk
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function sendBulk(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'driver_ids' => 'required|array|min:1',
            'driver_ids.*' => 'required|integer|exists:delivery_boys,id',
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'image' => 'nullable|mimes:jpeg,jpg,png,gif,webp|max:5120',
            'image_url' => 'nullable|url',
            'type' => 'nullable|string|in:order,general,promo,category,product,home,url',
            'order_item_id' => 'nullable|integer|exists:order_items,id',
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

        $result = DriverNotificationService::sendToMultiple(
            driverIds: $request->driver_ids,
            title: $request->title,
            message: $request->message,
            image: $image,
            type: $request->type ?? 'general',
            orderItemId: $request->order_item_id,
            extraData: $extraData
        );

        if ($result['success']) {
            return CommonHelper::responseWithData($result, $result['message']);
        }

        return CommonHelper::responseError($result['message']);
    }

    /**
     * Test notification endpoint - sends a test notification to a driver
     *
     * POST /api/driver-notifications/send-test
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function sendTest(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'driver_id' => 'required|integer|exists:delivery_boys,id',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $result = DriverNotificationService::send(
            driverId: $request->driver_id,
            title: 'Test Notification',
            message: 'This is a test notification from Zenfoo Admin Panel.',
            image: '',
            type: 'general',
            orderItemId: null
        );

        if ($result['success']) {
            return CommonHelper::responseWithData($result, 'Test notification sent successfully');
        }

        return CommonHelper::responseError($result['message']);
    }
}
