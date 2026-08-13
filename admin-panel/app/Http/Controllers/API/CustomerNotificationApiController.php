<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Services\CustomerNotificationService;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CustomerNotificationApiController extends Controller
{
    /**
     * Send notification to a single customer
     *
     * POST /api/customer-notifications/send
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function send(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'customer_id' => 'required|integer|exists:users,id',
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'image' => 'nullable|mimes:jpeg,jpg,png,gif,webp|max:5120',
            'image_url' => 'nullable|url',
            'page_navigation' => 'nullable|string|in:category,product,order,home,offers,wallet,profile,orders,cart,url',
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

        $result = CustomerNotificationService::send(
            customerId: $request->customer_id,
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
     * Send notification to multiple customers
     *
     * POST /api/customer-notifications/send-bulk
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function sendBulk(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'customer_ids' => 'required|array|min:1',
            'customer_ids.*' => 'required|integer|exists:users,id',
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'image' => 'nullable|mimes:jpeg,jpg,png,gif,webp|max:5120',
            'image_url' => 'nullable|url',
            'page_navigation' => 'nullable|string|in:category,product,order,home,offers,wallet,profile,orders,cart,url',
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

        $result = CustomerNotificationService::sendToMultiple(
            customerIds: $request->customer_ids,
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
     * Test notification endpoint - sends a test notification
     *
     * POST /api/customer-notifications/send-test
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function sendTest(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'customer_id' => 'required|integer|exists:users,id',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $result = CustomerNotificationService::send(
            customerId: $request->customer_id,
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
}