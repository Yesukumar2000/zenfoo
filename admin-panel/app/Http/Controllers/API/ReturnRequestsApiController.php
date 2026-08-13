<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\ReturnRequest;
use App\Models\ReturnStatusList;
use App\Models\Role;
use App\Models\User;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderStatusList;
use App\Models\ProductVariant;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class ReturnRequestsApiController extends Controller
{
    public function index(){
        $returnRequests = ReturnRequest::select('return_requests.*','users.name',
            'order_items.product_variant_id','order_items.quantity','order_items.price','order_items.sub_total',
            'order_items.discounted_price','order_items.product_name','order_items.variant_name')
            ->leftJoin('users', 'return_requests.user_id', '=', 'users.id')
            ->leftJoin('order_items', 'return_requests.order_item_id', '=', 'order_items.id')
            ->leftJoin('product_variants', 'return_requests.product_variant_id', '=', 'product_variants.id')
            ->orderBy('return_requests.id','DESC')
            ->get();
        return CommonHelper::responseWithData($returnRequests);
    }

    public function update(Request $request){
        $user = auth()->user();
        
        if ($user->role_id == Role::$roleDeliveryBoy) {
            // Delivery Boys (role_id: 4) can only update to these specific statuses: Out for Pickup, Received from Customer, Return to Seller, Cancelled
            $allowedStatuses = [
                ReturnStatusList::$rOutForPickup,
                ReturnStatusList::$rReceivedFromCustomer,
                ReturnStatusList::$rCancelled,
                ReturnStatusList::$rReturnToSeller
            ];
            
            if (!in_array($request->status, $allowedStatuses)) {
                return CommonHelper::responseError("You don't have permission to update to this status.");
            }
            
            $returnRequest = ReturnRequest::where('id', $request->id)
                ->where('delivery_boy_id', $user->deliveryBoy->id)
                ->first();
                
            if (!$returnRequest) {
                return CommonHelper::responseError("Return request not found or not assigned to you.");
            }
        } elseif ($user->role_id == Role::$roleSeller) {
            // Sellers (role_id: 3) can only update to these specific statuses: Pending, Delivery Boy Assigned, Approve, Reject
            $allowedStatuses = [
                ReturnStatusList::$rPending,
                ReturnStatusList::$rDeliveryBoyAssigned,
                ReturnStatusList::$rApproved,
                ReturnStatusList::$rRejected
            ];
            
            if (!in_array($request->status, $allowedStatuses)) {
                return CommonHelper::responseError("You don't have permission to update to this status.");
            }
            
            $returnRequest = ReturnRequest::select('return_requests.*')
                ->leftJoin('product_variants', 'return_requests.product_variant_id', '=', 'product_variants.id')
                ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
                ->where('return_requests.id', $request->id)
                ->where('products.seller_id', $user->seller->id)
                ->first();
                
            if (!$returnRequest) {
                return CommonHelper::responseError("Return request not found or you don't have permission to update this request.");
            }
        } else {
            // All other roles (not 3 and not 4) - Admin, Super Admin, etc. can access all return requests and all statuses
            $returnRequest = ReturnRequest::find($request->id);
            if (!$returnRequest) {
                return CommonHelper::responseError("Return request not found.");
            }
        }

        // Validate status update
        $validationError = $this->validateStatusUpdate($returnRequest, $request->status);
        if ($validationError) {
            return CommonHelper::responseError($validationError);
        }

        return $this->processUpdate($request, $returnRequest, $user);
    }

    public function delete(Request $request){
        $user = auth()->user();
        
        if(isset($request->id)){
            $returnRequest = ReturnRequest::find($request->id);
            if($returnRequest){
                $returnRequest->delete();
                return CommonHelper::responseSuccess("Return Request Deleted Successfully!");
            }else{
                return CommonHelper::responseSuccess("Return Request Already Deleted!");
            }
        }
    }

    public function deliveryBoyReturnRequests(Request $request){
        $validator = Validator::make($request->all(), [
            'delivery_boy_id' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $returnRequests = ReturnRequest::select('return_requests.*','users.name',
            'order_items.product_variant_id','order_items.quantity','order_items.price','order_items.sub_total',
            'order_items.discounted_price','order_items.product_name','order_items.variant_name')
            ->leftJoin('users', 'return_requests.user_id', '=', 'users.id')
            ->leftJoin('order_items', 'return_requests.order_item_id', '=', 'order_items.id')
            ->leftJoin('product_variants', 'return_requests.product_variant_id', '=', 'product_variants.id')
            ->where('return_requests.delivery_boy_id', $request->delivery_boy_id)
            ->orderBy('return_requests.id','DESC')
            ->get();
        
        return CommonHelper::responseWithData($returnRequests);
    }

    public function sellerIndex(Request $request){
        $offset = $request->get('offset', 0);
        $limit = $request->get('limit', 10);
        $startDate = $request->get('startDate');
        $endDate = $request->get('endDate');
        $search = $request->get('search', '');
        
        if ($offset < 0) $offset = 0;
        if ($limit < 1 || $limit > 100) $limit = 10;
        try{
          
            $query = ReturnRequest::select(
                'return_requests.*',
                'users.name as customer_name',
                'users.mobile as customer_mobile',
                'order_items.product_variant_id',
                'order_items.quantity',
                'order_items.price',
                'order_items.sub_total',
                'order_items.discounted_price',
                'order_items.product_name',
                'order_items.variant_name',
                'orders.payment_method',
                'orders.final_total',
                'orders.id as order_number',
                'cities.id as city_id',
                'cities.name as city_name',
                'delivery_boys.name as delivery_boy_name',
                'delivery_boys.mobile as delivery_boy_mobile'
            )
                ->leftJoin('users', 'return_requests.user_id', '=', 'users.id')
                ->leftJoin('order_items', 'return_requests.order_item_id', '=', 'order_items.id')
                ->leftJoin('orders', 'return_requests.order_id', '=', 'orders.id')
                ->leftJoin('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->leftJoin('cities', 'user_addresses.city_id', '=', 'cities.id')
                ->leftJoin('product_variants', 'return_requests.product_variant_id', '=', 'product_variants.id')
                ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
                ->leftJoin('delivery_boys', 'return_requests.delivery_boy_id', '=', 'delivery_boys.id');

            if (auth()->user()->role_id == Role::$roleSeller) {
                $seller_id = auth()->user()->seller->id;
                $query->where('products.seller_id', $seller_id);
            }

            // Apply date filters
            if (!empty($startDate)) {
                $query->whereDate('return_requests.created_at', '>=', $startDate);
            }
            
            if (!empty($endDate)) {
                $query->whereDate('return_requests.created_at', '<=', $endDate);
            }

            // Apply search filter
            if (!empty($search) && trim($search) !== '') {
                $searchTerm = trim($search);                
                $query->where(function($q) use ($searchTerm) {
                    $q->where('return_requests.id', 'LIKE', '%' . $searchTerm . '%')
                    ->orWhere('users.name', 'LIKE', '%' . $searchTerm . '%')
                    ->orWhere('users.mobile', 'LIKE', '%' . $searchTerm . '%')
                    ->orWhere('order_items.product_name', 'LIKE', '%' . $searchTerm . '%')
                    ->orWhere('orders.payment_method', 'LIKE', '%' . $searchTerm . '%')
                    ->orWhere('delivery_boys.name', 'LIKE', '%' . $searchTerm . '%')
                    ->orWhere('cities.name', 'LIKE', '%' . $searchTerm . '%');
                });
                
            }

            $totalCount = $query->count();
            
            $returnRequests = $query->orderBy('return_requests.id','DESC')
                ->offset($offset)
                ->limit($limit)
                ->get();
                
            return CommonHelper::responseWithData(
                $returnRequests,
                $totalCount
            );
        }catch(\Exception $e){
            return CommonHelper::responseError($e->getMessage());
        }
    }

    public function sellerUpdate(Request $request){
        $user = auth()->user();
        if ($user->role_id != Role::$roleSeller) {
            return CommonHelper::responseError("Unauthorized access. Seller role required.");
        }

        $allowedStatuses = [
            ReturnStatusList::$rPending,
            ReturnStatusList::$rDeliveryBoyAssigned,
            ReturnStatusList::$rApproved,
            ReturnStatusList::$rRejected
        ];
        
        if (!in_array($request->status, $allowedStatuses)) {
            return CommonHelper::responseError("You don't have permission to update to this status.");
        }

        $returnRequest = ReturnRequest::select('return_requests.*')
            ->leftJoin('product_variants', 'return_requests.product_variant_id', '=', 'product_variants.id')
            ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
            ->where('return_requests.id', $request->id)
            ->where('products.seller_id', $user->seller->id)
            ->first();
            
        if (!$returnRequest) {
            return CommonHelper::responseError("Return request not found or you don't have permission to update this request.");
        }

        // Validate status update
        $validationError = $this->validateStatusUpdate($returnRequest, $request->status);
        if ($validationError) {
            return CommonHelper::responseError($validationError);
        }

        return $this->processUpdate($request, $returnRequest, $user);
    }

    public function sellerDelete(Request $request){
        $user = auth()->user();
        
        if ($user->role_id != Role::$roleSeller) {
            return CommonHelper::responseError("Unauthorized access. Seller role required.");
        }

        $returnRequest = ReturnRequest::select('return_requests.*')
            ->leftJoin('product_variants', 'return_requests.product_variant_id', '=', 'product_variants.id')
            ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
            ->where('return_requests.id', $request->id)
            ->where('products.seller_id', $user->seller->id)
            ->first();
            
        if (!$returnRequest) {
            return CommonHelper::responseError("Return request not found or you don't have permission to delete this request.");
        }

        if(isset($request->id)){
            $returnRequest->delete();
            return CommonHelper::responseSuccess("Return Request Deleted Successfully!");
        }
    }

    public function deliveryBoyIndex(Request $request){
        $offset = $request->get('offset', 0);
        $limit = $request->get('limit', 10);
        
        if ($offset < 0) $offset = 0;
        if ($limit < 1 || $limit > 100) $limit = 10;
        
        $delivery_boy_id = auth()->user()->deliveryBoy->id;
        
        $query = ReturnRequest::select('return_requests.*','users.name', 'users.mobile as customer_mobile',
            'order_items.product_variant_id','order_items.quantity','order_items.price','order_items.sub_total',
            'order_items.discounted_price','order_items.product_name','order_items.variant_name',
            'orders.address as delivery_address', 'orders.mobile as delivery_mobile',
            'orders.payment_method', 'orders.final_total', 'cities.id as city_id')
            ->leftJoin('users', 'return_requests.user_id', '=', 'users.id')
            ->leftJoin('order_items', 'return_requests.order_item_id', '=', 'order_items.id')
            ->leftJoin('orders', 'return_requests.order_id', '=', 'orders.id')
            ->leftJoin('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
            ->leftJoin('cities', 'user_addresses.city_id', '=', 'cities.id')
            ->leftJoin('product_variants', 'return_requests.product_variant_id', '=', 'product_variants.id')
            ->where('return_requests.delivery_boy_id', $delivery_boy_id);

        $totalCount = $query->count();
        
        $returnRequests = $query->orderBy('return_requests.id','DESC')
            ->offset($offset)
            ->limit($limit)
            ->get();

        return CommonHelper::responseWithData(
            $returnRequests,
            $totalCount
        );
    }

    public function deliveryBoyUpdate(Request $request){
        $user = auth()->user();
        
        if ($user->role_id != Role::$roleDeliveryBoy) {
            return CommonHelper::responseError("Unauthorized access. Delivery boy role required.");
        }

        $returnRequest = ReturnRequest::where('id', $request->id)
            ->where('delivery_boy_id', $user->deliveryBoy->id)
            ->first();
            
        if (!$returnRequest) {
            return CommonHelper::responseError("Return request not found or not assigned to you.");
        }

        // Validate status update
        $validationError = $this->validateStatusUpdate($returnRequest, $request->status);
        if ($validationError) {
            return CommonHelper::responseError($validationError);
        }

        $allowedStatuses = [
            ReturnStatusList::$rOutForPickup,
            ReturnStatusList::$rReceivedFromCustomer,
            ReturnStatusList::$rCancelled,
            ReturnStatusList::$rReturnToSeller
        ];
        
        if (!in_array($request->status, $allowedStatuses)) {
            return CommonHelper::responseError("You don't have permission to update to this status.");
        }

        return $this->processUpdate($request, $returnRequest, $user);
    }

    private function validateStatusUpdate($returnRequest, $requestStatus) {
        if ($returnRequest->status == ReturnStatusList::$rApproved || $returnRequest->status == ReturnStatusList::$rRejected) {
            return "Cannot update return request. Status is already " . ReturnStatusList::getStatusName($returnRequest->status) . ".";
        }
        
        if ($returnRequest->status == $requestStatus) {
            return "This return request is already " . ReturnStatusList::getStatusName($returnRequest->status) . ".";
        }
        
        $currentStatus = $returnRequest->status;
        $newStatus = $requestStatus;
        
        $statusHierarchy = [
            ReturnStatusList::$rPending => 1,
            ReturnStatusList::$rDeliveryBoyAssigned => 2,
            ReturnStatusList::$rOutForPickup => 3,
            ReturnStatusList::$rReceivedFromCustomer => 4,
            ReturnStatusList::$rReturnToSeller => 5,
            ReturnStatusList::$rApproved => 6,
            ReturnStatusList::$rRejected => 6,
            ReturnStatusList::$rCancelled => 7
        ];
        
        $specialStatuses = [
            ReturnStatusList::$rCancelled,
            ReturnStatusList::$rApproved,
            ReturnStatusList::$rRejected
        ];
        
        if (!isset($statusHierarchy[$currentStatus]) || !isset($statusHierarchy[$newStatus])) {
            return "Invalid status for return request.";
        }
        
        if ($statusHierarchy[$newStatus] < $statusHierarchy[$currentStatus]) {
            return "Cannot update status from '" . ReturnStatusList::getStatusName($currentStatus) . "' to '" . ReturnStatusList::getStatusName($newStatus) . "'";
        }
        
        if ($statusHierarchy[$newStatus] == $statusHierarchy[$currentStatus]) {
            return "This return request is already " . ReturnStatusList::getStatusName($currentStatus) . ".";
        }
        
        return null;
    }

    private function processUpdate(Request $request, $returnRequest, $user){
        $validator = Validator::make($request->all(), [
            'id' => 'required|integer|exists:return_requests,id',
            'status' => 'required',
            'delivery_boy_id' => [
                'required_if:status,' . ReturnStatusList::$rDeliveryBoyAssigned,
                'integer',
                function ($attribute, $value, $fail) use ($request) {
                    $existingRequest = ReturnRequest::where('id', $request->id)
                        ->where('status', ReturnStatusList::$rApproved)
                        ->first();

                    if ($existingRequest) {
                        $fail('This return request has already been approved.');
                    }

                    if ($request->status == ReturnStatusList::$rDeliveryBoyAssigned && $value <= 0) {
                        $fail('Please assign a delivery boy when the return request is assigned.');
                    }
                },
            ],
            'cancellation_reason' => [
                'required_if:status,' . ReturnStatusList::$rCancelled,
                'string',
                'max:500'
            ],
        ], [
            'id.required' => 'Return request ID is required.',
            'id.integer' => 'Return request ID must be a valid integer.',
            'id.exists' => 'Return request not found.',
            'delivery_boy_id.required_if' => 'Please assign a delivery boy when the return request is assigned.',
            'cancellation_reason.required_if' => 'Cancellation reason is required when status is cancelled.',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        if ($user->role_id == Role::$roleSeller) {
            if ($request->status == ReturnStatusList::$rDeliveryBoyAssigned && ($request->delivery_boy_id == 0 || empty($request->delivery_boy_id))) {
                return CommonHelper::responseError("Please assign a delivery boy when the status is 'Delivery Boy Assigned'.");
            }
            
            if ($request->status == ReturnStatusList::$rApproved && $returnRequest->delivery_boy_id == 0) {
                return CommonHelper::responseError("Cannot approve return request. Please assign a delivery boy first.");
            }
        } else {
            $statusesRequiringDeliveryBoy = [
                ReturnStatusList::$rOutForPickup,
                ReturnStatusList::$rReceivedFromCustomer,
                ReturnStatusList::$rReturnToSeller,
                ReturnStatusList::$rCancelled
            ];

            $allowedStatusesWithoutDeliveryBoy = [
                ReturnStatusList::$rPending,
                ReturnStatusList::$rRejected
            ];

            if (in_array($request->status, $statusesRequiringDeliveryBoy) && $returnRequest->delivery_boy_id == 0) {
                return CommonHelper::responseError("Cannot update to this status. Please assign a delivery boy first.");
            }

            if (in_array($request->status, $allowedStatusesWithoutDeliveryBoy) && $returnRequest->delivery_boy_id == 0) {
                return CommonHelper::responseError("Cannot update status. Please assign a delivery boy first.");
            }
            
            if ($request->status == ReturnStatusList::$rApproved && $returnRequest->delivery_boy_id == 0) {
                return CommonHelper::responseError("Cannot approve return request. Please assign a delivery boy first.");
            }
        }

        $returnRequest->remarks = $request->remark;
        $returnRequest->status = $request->status;
        
        if ($user->role_id == Role::$roleDeliveryBoy) {
        } elseif ($user->role_id == Role::$roleSeller) {
            if ($request->status == ReturnStatusList::$rDeliveryBoyAssigned) {
                $returnRequest->delivery_boy_id = $request->delivery_boy_id ?? 0;
            } elseif ($request->status == ReturnStatusList::$rPending) {
                $returnRequest->delivery_boy_id = 0;
            }
        } else {
            $returnRequest->delivery_boy_id = $request->delivery_boy_id ?? 0;
        }
        
        if($request->status == ReturnStatusList::$rCancelled) {
            $returnRequest->cancellation_reason = $request->cancellation_reason;
        }
        if($request->status == ReturnStatusList::$rPending){
            $returnRequest->delivery_boy_id = 0;
        }

        elseif($request->status == ReturnStatusList::$rApproved){
            $orderItem = OrderItem::find($returnRequest->order_item_id);

            $order = Order::select("*")->where("id", $orderItem->order_id)->first();
            $user = User::find($returnRequest->user_id);
            $currentBalance = $user->balance;
            
            $walletCreditAmount = $this->calculateWalletCreditAmount($order, $orderItem);
            
            $orderItem->refund_amount = $walletCreditAmount;
            $orderItem->save();
            
            $new_balance = $currentBalance + $walletCreditAmount;
                $itemNum = OrderItem::where("order_id", $order->id)->count();
                    $lastItemNum = 0;
                    if ($itemNum > 1) {
                        $lastItemNum = OrderItem::where("order_id", $order->id)->where('status', '!=', OrderStatusList::$cancelled)->count();
                    }
                 if ($itemNum == 1 || $lastItemNum == 1) {
                    // Calculate additional charges for single product
                    $additional_charges = json_decode($order->additional_charges, true) ?? [];
                    $additional_charges_total = array_sum(array_column($additional_charges, 'amount'));

                    if($order->wallet_balance == 0){
                        // Refund the wallet credit amount (considering promo discount)
                        $new_balance = $currentBalance + $walletCreditAmount;
                        CommonHelper::updateUserWalletBalance($new_balance, $returnRequest->user_id);
                        CommonHelper::addWalletTransaction($orderItem->order_id, $orderItem->id, $returnRequest->user_id, 'credit', $walletCreditAmount, 'Order Item Returned');
                    }
                    else{
                        // Calculate refund amount excluding additional charges and delivery charge
                        $refundable_amount = $order->final_total - $additional_charges_total - floatval($order->delivery_charge);
                        $new_balance = $currentBalance + $order->wallet_balance + $refundable_amount;
                        CommonHelper::updateUserWalletBalance($new_balance, $returnRequest->user_id);
                        CommonHelper::addWalletTransaction($orderItem->order_id, $orderItem->id, $returnRequest->user_id, 'credit', $order->wallet_balance + $refundable_amount, 'Order Item Returned');
                    }

                    $order->active_status = OrderStatusList::$returned;
                    $order->remaining_total = 0;
                    // Set both final_total and remaining_final to additional charges + delivery charge
                    $order->final_total = $additional_charges_total + floatval($order->delivery_charge);
                    $order->remaining_final = $additional_charges_total + floatval($order->delivery_charge);
                    $order->save();
                }
                else{
                    if($order->wallet_balance == 0){
                        $new_balance = $currentBalance + $walletCreditAmount;
                        CommonHelper::updateUserWalletBalance($new_balance, $returnRequest->user_id);
                        CommonHelper::addWalletTransaction($orderItem->order_id, $orderItem->id, $returnRequest->user_id, 'credit', $walletCreditAmount, 'Order Item Returned');
                    }
                    else{
                        $new_balance = $currentBalance + $walletCreditAmount;
                        CommonHelper::updateUserWalletBalance($new_balance, $returnRequest->user_id);
                        CommonHelper::addWalletTransaction($orderItem->order_id, $orderItem->id, $returnRequest->user_id, 'credit', $walletCreditAmount, 'Order Item Returned');
                    }

                    // Calculate additional charges
                    $additional_charges = json_decode($order->additional_charges, true) ?? [];
                    $additional_charges_total = array_sum(array_column($additional_charges, 'amount'));

                    // Update remaining totals for partial returns
                    $order->remaining_total = floatval($order->remaining_total) - floatval($walletCreditAmount);
                    $order->remaining_final = floatval($order->remaining_total) + $additional_charges_total + floatval($order->delivery_charge);

                    // Set final_total to match remaining_final
                    $order->final_total = $order->remaining_final;

                    $order->save();
                }
            if ($orderItem) {
                $orderItem->active_status = OrderStatusList::$returned;
                $orderItem->save();
            }
            $product_variant_id = $orderItem->product_variant_id;
            $product_variant = ProductVariant::where('id', $product_variant_id)->first();

            if ($product_variant) {
                $new_stock_value = $product_variant->stock +  $orderItem->quantity;
                $product_variant->stock = $new_stock_value;
                $product_variant->save();
            }
            if($order->wallet_balance == 0){

            }else{
                $order->wallet_balance = floatval($order->wallet_balance) - floatval($order->wallet_balance);
                $order->save();
            }
        }
        elseif($request->status == ReturnStatusList::$rRejected){
            $returnRequest->delivery_boy_id = 0;
        }
        $returnRequest->save();
        
        try {
            CommonHelper::sendReturnRequestNotification($returnRequest);
        } catch (\Exception $e) {
            Log::error("Return request notification error: " . $e->getMessage());
        }
        
        return CommonHelper::responseSuccess("Return Request Status Updated Successfully!");
    }

    private function calculateWalletCreditAmount($order, $orderItem) {
        // If no promo discount, return the original sub_total
        if ($order->promo_discount <= 0) {
            return $orderItem->sub_total;
        }
        
        // Get total number of order items in the order (excluding cancelled items)
        $totalOrderItems = OrderItem::where('order_id', $order->id)
            ->where('status', '!=', OrderStatusList::$cancelled)
            ->count();
            
        if ($totalOrderItems <= 0) {
            return $orderItem->sub_total;
        }
        
        // Calculate promo discount per item
        $promoDiscountPerItem = $order->promo_discount / $totalOrderItems;
        
        // Calculate wallet credit amount: sub_total minus the proportional promo discount
        $walletCreditAmount = $orderItem->sub_total - $promoDiscountPerItem;
        
        // Ensure wallet credit amount is not negative
        return max(0, $walletCreditAmount);
    }
}
