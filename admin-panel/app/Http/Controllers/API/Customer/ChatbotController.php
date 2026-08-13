<?php

namespace App\Http\Controllers\API\Customer;

use App\Http\Controllers\Controller;
use App\Helpers\CommonHelper;
use App\Models\DeliveryBoy;
use App\Models\DeliveryBoyLocationHistory;
use App\Models\Order;
use App\Models\OrderStatusList;
use App\Models\Transaction;
use App\Services\FirestoreOrderETAService;
use App\Services\OrderItemsService;
use App\Services\PaytmRefundService;
use App\Services\PhonePeRefundService;
use App\Services\ProductOrderPolicyService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class ChatbotController extends Controller
{
    /**
     * Available chatbot questions the customer can ask about their order.
     */
    public function getQuestions(Request $request)
    {
        $questions = [
            ['key' => 'where_is_my_order', 'question' => 'Where is my order right now?'],
            ['key' => 'order_status',      'question' => 'What is the status of my order?'],
            ['key' => 'order_total',       'question' => 'What is the total amount of my order?'],
            ['key' => 'order_items',       'question' => 'What items did I order?'],
            ['key' => 'delivery_address',  'question' => 'What is the delivery address for my order?'],
            ['key' => 'driver_details',    'question' => 'Who is my delivery driver?'],
            ['key' => 'cancel_order',      'question' => 'Cancel this order'],
            ['key' => 'other',             'question' => 'Need to chat with support team?'],
        ];

        return response()->json([
            'status'  => true,
            'message' => 'Chatbot questions fetched successfully.',
            'data'    => $questions,
        ]);
    }

    /**
     * Answer a specific question about an order.
     *
     * Request params:
     *   - order_id  (required) : the order's primary key (id column)
     *   - question  (required) : one of the question keys listed above
     */
    public function getAnswer(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer|exists:orders,id',
            'question' => 'required|string|in:order_status,order_total,order_items,delivery_address,driver_details,where_is_my_order,cancel_order',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
            ], 422);
        }

        $user  = $request->user('api-customers');
        $order = Order::where('id', $request->order_id)
                      ->where('user_id', $user->id)
                      ->first();

        if (!$order) {
            return response()->json([
                'status'  => false,
                'message' => 'Order not found or does not belong to your account.',
            ], 404);
        }

        $answer = $this->resolveAnswer($request->question, $order);

        return response()->json([
            'status'   => true,
            'order_id' => $order->id,
            'question' => $request->question,
            'answer'   => $answer,
        ]);
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private function resolveAnswer(string $key, Order $order): array
    {
        switch ($key) {
            case 'order_status':
                return $this->answerOrderStatus($order);

            case 'order_total':
                return $this->answerOrderTotal($order);

            case 'order_items':
                return $this->answerOrderItems($order);

            case 'delivery_address':
                return $this->answerDeliveryAddress($order);

            case 'driver_details':
                return $this->answerDriverDetails($order);

            case 'where_is_my_order':
                return $this->answerWhereIsMyOrder($order);

            case 'cancel_order':
                return $this->answerCancelOrder($order);

            default:
                return ['text' => 'Sorry, I could not understand that question.'];
        }
    }

    private function answerOrderStatus(Order $order): array
    {
        $customerLabels = [
            OrderStatusList::$received => 'Order Placed',
        ];

        $statusRecord = OrderStatusList::where('id', $order->active_status)->first();
        $label        = $customerLabels[$order->active_status]
                        ?? ($statusRecord ? $statusRecord->status : 'Unknown');

        return [
            'text'    => "Your order #{$order->id} status is currently: {$label}.",
            'details' => [
                ['label' => 'Order ID', 'value' => (string) $order->id],
                ['label' => 'Status',   'value' => $label],
            ],
        ];
    }

    private function answerOrderTotal(Order $order): array
    {
        $meta     = $order->cart_metadata;
        $summary  = $meta['billing_summary'] ?? null;
        $snapshot = $order->order_items_snapshot;

        if (!$summary) {
            return ['text' => 'Billing details are not available for this order.', 'details' => []];
        }

        $currency = $summary['currency']      ?? '₹';
        $toBePaid = $summary['to_be_paid']    ?? 0;
        $savings  = $summary['total_savings'] ?? 0;

        $details = [];

        // 1. Regular items at net discounted price (not MRP)
        foreach ($snapshot['order_items'] ?? [] as $item) {
            $price = (float) ($item['discounted_price'] ?? $item['sub_total'] ?? $item['price'] ?? 0);
            if ($price == 0) continue;
            $details[] = [
                'label'     => ($item['product_name'] ?? 'Item') . ' × ' . ($item['quantity'] ?? 1),
                'value'     => $currency . number_format($price, 2),
                'is_total'  => false,
                'is_credit' => false,
            ];
        }

        // 2. Combos at discounted sub_total (not MRP)
        foreach ($snapshot['combo_items'] ?? [] as $combo) {
            $subTotal = (float) ($combo['sub_total'] ?? 0);
            if ($subTotal == 0) continue;
            $productNames = implode(', ', array_column($combo['products'] ?? [], 'product_name'));
            $details[] = [
                'label'     => 'Combo (' . $productNames . ')',
                'value'     => $currency . number_format($subTotal, 2),
                'is_total'  => false,
                'is_credit' => false,
            ];
        }

        // 3. Charges from billing_breakdown (delivery, multi-order, rain surcharge, tip, etc.)
        //    Skip MRP entries and the combined discount — we show net prices above instead.
        $skipTypes = ['items_subtotal', 'combo_subtotal', 'discount', 'to_be_paid'];
        foreach ($meta['billing_breakdown'] ?? [] as $entry) {
            if (in_array($entry['type'] ?? '', $skipTypes)) continue;
            if (($entry['amount'] ?? 0) == 0) continue;

            $sign      = ($entry['is_credit'] ?? false) ? '-' : '';
            $details[] = [
                'label'     => $entry['label'],
                'value'     => "{$sign}{$currency}" . number_format($entry['amount'], 2),
                'is_total'  => false,
                'is_credit' => $entry['is_credit'] ?? false,
            ];
        }

        // 4. Aggregate savings row
        if ($savings > 0) {
            $details[] = [
                'label'     => 'You Saved',
                'value'     => "-{$currency}" . number_format($savings, 2),
                'is_total'  => false,
                'is_credit' => true,
            ];
        }

        // 5. Total
        $details[] = [
            'label'     => 'Total',
            'value'     => $currency . number_format($toBePaid, 2),
            'is_total'  => true,
            'is_credit' => false,
        ];

        $text = "Your order #{$order->id} total is {$currency}" . number_format($toBePaid, 2) . ".";
        if ($savings > 0) {
            $text .= " You saved {$currency}" . number_format($savings, 2) . ".";
        }

        return [
            'text'    => $text,
            'details' => $details,
        ];
    }

    private function answerOrderItems(Order $order): array
    {
        $snapshot = $order->order_items_snapshot;

        if (empty($snapshot['order_items']) && empty($snapshot['combo_items'])) {
            return ['text' => 'No item details are available for this order.', 'details' => []];
        }

        $details = [];

        foreach ($snapshot['order_items'] ?? [] as $item) {
            $name      = $item['product_name'] ?? 'Item';
            $qty       = $item['quantity']      ?? 1;
            $price     = $item['discounted_price'] ?? $item['price'] ?? 0;
            $details[] = [
                'label' => "{$name} × {$qty}",
                'value' => '₹' . number_format($price, 2),
            ];
        }

        foreach ($snapshot['combo_items'] ?? [] as $combo) {
            $productNames = implode(', ', array_column($combo['products'] ?? [], 'product_name'));
            $details[] = [
                'label' => 'Combo (' . $productNames . ')',
                'value' => '₹' . number_format($combo['sub_total'] ?? 0, 2),
            ];
        }

        $count = count($details);
        return [
            'text'    => "Your order #{$order->id} has {$count} item(s).",
            'details' => $details,
        ];
    }

    private function answerDeliveryAddress(Order $order): array
    {
        $address = trim($order->address ?? '');

        if ($address === '') {
            return ['text' => 'No delivery address was found for this order.', 'details' => []];
        }

        return [
            'text'    => "Your order will be delivered to: {$address}",
            'details' => [
                ['label' => 'Delivery Address', 'value' => $address],
            ],
        ];
    }

    private function answerDriverDetails(Order $order): array
    {
        if (empty($order->delivery_boy_id)) {
            return ['text' => 'No driver has been assigned to your order yet.', 'details' => []];
        }

        $driver = DeliveryBoy::select('name', 'mobile')
                             ->find($order->delivery_boy_id);

        if (!$driver) {
            return ['text' => 'Driver information could not be found.', 'details' => []];
        }

        return [
            'text'    => "Your delivery driver is {$driver->name}, reachable at {$driver->mobile}.",
            'details' => [
                ['label' => 'Driver Name',   'value' => $driver->name],
                ['label' => 'Driver Mobile', 'value' => $driver->mobile],
            ],
        ];
    }

    private function answerWhereIsMyOrder(Order $order): array
    {
        if (empty($order->delivery_boy_id)) {
            return ['text' => 'No driver has been assigned to your order yet.', 'details' => []];
        }

        $location = DeliveryBoyLocationHistory::where('delivery_boy_id', $order->delivery_boy_id)
                                              ->orderByDesc('tracked_at')
                                              ->first();

        if (!$location) {
            return ['text' => 'Driver location is not available at the moment.', 'details' => []];
        }

        $lat          = (float) $location->latitude;
        $lon          = (float) $location->longitude;
        $locationName = $this->reverseGeocode($lat, $lon);
        $trackedAt    = $location->tracked_at?->format('h:i A');

        $displayLocation = $locationName ?? "{$lat}, {$lon}";
        $text = "Your driver is currently near {$displayLocation}"
              . ($trackedAt ? " (as of {$trackedAt})" : '') . '.';

        $details = [
            ['label' => 'Current Location', 'value' => $displayLocation],
        ];
        if ($trackedAt) {
            $details[] = ['label' => 'Last Updated', 'value' => $trackedAt];
        }

        return [
            'text'    => $text,
            'details' => $details,
            'meta'    => [
                'latitude'   => $lat,
                'longitude'  => $lon,
                'tracked_at' => $location->tracked_at?->toDateTimeString(),
            ],
        ];
    }

    private function answerCancelOrder(Order $order): array
    {
        try {
            $orderId = $order->id;
            $user = auth('api-customers')->user();

            Log::info('ChatbotController::answerCancelOrder - Starting cancellation check', [
                'order_id' => $orderId,
                'user_id' => $user->id,
            ]);

            // Check if already cancelled
            if ($order->active_status == 7) {
                return [
                    'text' => "This order has already been cancelled.",
                    'details' => [
                        ['label' => 'Order ID', 'value' => (string) $orderId],
                        ['label' => 'Status', 'value' => 'Cancelled'],
                    ],
                    'can_cancel' => false,
                ];
            }

            // Check if already handed to delivery partner
            $givenToDriver = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->where('status', 'given_to_delivery_partner')
                ->first();

            if ($givenToDriver) {
                Log::warning('ChatbotController::answerCancelOrder - Already handed to delivery partner', [
                    'order_id' => $orderId,
                ]);
                return [
                    'text' => "Sorry, this order cannot be cancelled as it has already been handed to the delivery partner.\n\nIf you still need assistance, please contact our support team.",
                    'details' => [
                        ['label' => 'Order ID', 'value' => (string) $orderId],
                        ['label' => 'Reason', 'value' => 'Already with delivery partner'],
                        ['label' => 'Need Help?', 'value' => 'Select "Need to chat with support team?" from the chatbot options.'],
                    ],
                    'can_cancel' => false,
                ];
            }

            // Check product-level cancel policies
            $orderItemsService = new OrderItemsService();
            $orderItemsData = $orderItemsService->getOrderItems($orderId);
            $productIds = $orderItemsData['all_product_ids'];

            $policyService = new ProductOrderPolicyService();
            foreach ($productIds as $productId) {
                $policyResult = $policyService->checkCancelPolicy(
                    (int) $productId,
                    (int) $order->active_status
                );

                if (!$policyResult['can_cancel_now']) {
                    Log::warning('ChatbotController::answerCancelOrder - Product cancel policy blocked', [
                        'order_id' => $orderId,
                        'product_id' => $productId,
                        'reason' => $policyResult['reason'],
                    ]);
                    return [
                        'text' => "Sorry, this order cannot be cancelled.\n\nReason: " . $policyResult['reason'] . "\n\nIf you need assistance, please contact our support team.",
                        'details' => [
                            ['label' => 'Order ID', 'value' => (string) $orderId],
                            ['label' => 'Product', 'value' => $policyResult['product_name'] ?? "ID:{$productId}"],
                            ['label' => 'Reason', 'value' => $policyResult['reason']],
                            ['label' => 'Need Help?', 'value' => 'Select "Need to chat with support team?" from the chatbot options.'],
                        ],
                        'can_cancel' => false,
                    ];
                }
            }

            // All checks passed - proceed with cancellation
            DB::beginTransaction();
            Log::info('ChatbotController::answerCancelOrder - All checks passed, starting cancellation', [
                'order_id' => $orderId,
            ]);

            $refundResult = null;
            $paymentMethod = strtolower($order->payment_method ?? '');

            // Process refund for non-COD orders
            if ($paymentMethod !== 'cod') {
                $transaction = Transaction::where('order_id', $orderId)
                    ->where('status', Transaction::$statusSuccess)
                    ->first();

                if ($transaction && $transaction->txn_id) {
                    $refundAmount = $transaction->amount ?? 0;

                    if ($refundAmount > 0) {
                        if (strtolower($transaction->type) === 'phonepe') {
                            $phonePeRefundService = new PhonePeRefundService();
                            $refundResult = $phonePeRefundService->initiateRefund(
                                $transaction->txn_id,
                                $refundAmount,
                                $orderId
                            );

                            if (!$refundResult['success']) {
                                DB::rollBack();
                                Log::error('ChatbotController::answerCancelOrder - PhonePe refund failed', [
                                    'order_id' => $orderId,
                                    'error' => $refundResult['error'] ?? 'Unknown error',
                                ]);
                                return [
                                    'text' => "Unable to process refund at this moment. Please contact our support team for assistance.",
                                    'details' => [
                                        ['label' => 'Order ID', 'value' => (string) $orderId],
                                        ['label' => 'Issue', 'value' => 'Refund processing failed'],
                                        ['label' => 'Need Help?', 'value' => 'Select "Need to chat with support team?" from the chatbot options.'],
                                    ],
                                    'can_cancel' => false,
                                ];
                            }

                            // Update transaction with refund details
                            $transaction->is_refunded = 1;
                            $transaction->refund_transaction_id = $refundResult['refund_transaction_id'] ?? null;
                            $transaction->refund_amount = $refundAmount;
                            $transaction->refunded_at = now();
                            $transaction->save();

                        } elseif (strtolower($transaction->type) === 'paytm') {
                            $paytmTransaction = \App\Models\PaytmTransaction::where('order_id', $orderId)
                                ->orderBy('id', 'desc')
                                ->first();

                            if (!$paytmTransaction) {
                                DB::rollBack();
                                Log::error('ChatbotController::answerCancelOrder - Paytm transaction not found', [
                                    'order_id' => $orderId,
                                ]);
                                return [
                                    'text' => "Unable to process refund at this moment. Please contact our support team for assistance.",
                                    'details' => [
                                        ['label' => 'Order ID', 'value' => (string) $orderId],
                                        ['label' => 'Issue', 'value' => 'Payment record not found'],
                                        ['label' => 'Need Help?', 'value' => 'Select "Need to chat with support team?" from the chatbot options.'],
                                    ],
                                    'can_cancel' => false,
                                ];
                            }

                            $paytmRefundService = new PaytmRefundService();
                            $refundResult = $paytmRefundService->initiateRefund(
                                $paytmTransaction->paytm_txn_id,
                                $refundAmount,
                                $orderId,
                                $paytmTransaction->txn_id
                            );

                            if (!$refundResult['success']) {
                                DB::rollBack();
                                Log::error('ChatbotController::answerCancelOrder - Paytm refund failed', [
                                    'order_id' => $orderId,
                                    'error' => $refundResult['error'] ?? 'Unknown error',
                                ]);
                                return [
                                    'text' => "Unable to process refund at this moment. Please contact our support team for assistance.",
                                    'details' => [
                                        ['label' => 'Order ID', 'value' => (string) $orderId],
                                        ['label' => 'Issue', 'value' => 'Refund processing failed'],
                                        ['label' => 'Need Help?', 'value' => 'Select "Need to chat with support team?" from the chatbot options.'],
                                    ],
                                    'can_cancel' => false,
                                ];
                            }

                            // Update transaction with refund details
                            $transaction->is_refunded = 1;
                            $transaction->refund_transaction_id = $refundResult['refund_transaction_id'] ?? null;
                            $transaction->refund_amount = $refundAmount;
                            $transaction->refunded_at = now();
                            $transaction->save();

                            // Update paytm_transactions table
                            if ($paytmTransaction) {
                                $paytmTransaction->is_refunded = 1;
                                $paytmTransaction->refund_id = $refundResult['refund_transaction_id'] ?? null;
                                $paytmTransaction->refund_amount = $refundAmount;
                                $paytmTransaction->refunded_at = now();
                                $paytmTransaction->save();
                            }
                        }
                    }
                }
            }

            // Archive and delete tracking records
            $trackingRows = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->get();

            if ($trackingRows->isNotEmpty()) {
                $now = now();
                $archive = $trackingRows->map(function ($row) use ($now) {
                    return [
                        'original_tracking_id' => $row->id,
                        'order_id' => $row->order_id,
                        'seller_id' => $row->seller_id,
                        'store_id' => $row->store_id,
                        'store_location_id' => $row->store_location_id,
                        'is_zenfoo_store' => $row->is_zenfoo_store,
                        'is_driver_picked' => $row->is_driver_picked,
                        'driver_captured_images_when_marked_as_pickup' => $row->driver_captured_images_when_marked_as_pickup,
                        'status' => $row->status,
                        'otp' => $row->otp,
                        'is_seller_started_preparing' => $row->is_seller_started_preparing,
                        'delayed_time_in_min' => $row->delayed_time_in_min,
                        'driver_arrived_at_seller' => $row->driver_arrived_at_seller,
                        'prep_time' => $row->prep_time,
                        'cancelled_by' => 'customer',
                        'cancelled_at' => $now,
                        'created_at' => $now,
                        'updated_at' => $now,
                    ];
                })->toArray();

                DB::table('cancelled_order_seller_tracking')->insert($archive);
            }

            DB::table('order_seller_status_tracking')->where('order_id', $orderId)->delete();

            // Update order status to cancelled
            $order->active_status = 7;
            $order->save();

            // Refund wallet amount if used
            if ($order->wallet_balance > 0) {
                $walletRefund = floatval($order->wallet_balance);
                $newBalance = $user->balance + $walletRefund;

                CommonHelper::updateUserWalletBalance($newBalance, $user->id);
                CommonHelper::addWalletTransaction($orderId, 0, $user->id, 'credit', $walletRefund, 'Refund - Order Cancelled', 1, $order->payment_method);

                $order->wallet_balance = 0;
                $order->save();
            }

            DB::commit();

            // Update Firestore
            try {
                FirestoreOrderETAService::updateOrderStatus(
                    $orderId,
                    'Order Cancelled',
                    'Your order has been cancelled'
                );
            } catch (\Exception $e) {
                Log::error('ChatbotController::answerCancelOrder - Firestore update failed', [
                    'order_id' => $orderId,
                    'error' => $e->getMessage(),
                ]);
            }

            Log::info('ChatbotController::answerCancelOrder - Cancellation successful', [
                'order_id' => $orderId,
                'refund_initiated' => $refundResult && $refundResult['success'] ? true : false,
            ]);

            // Build success response
            $text = "Your order has been cancelled successfully.";
            $details = [
                ['label' => 'Order ID', 'value' => (string) $orderId],
                ['label' => 'Status', 'value' => 'Cancelled'],
            ];

            if ($refundResult && $refundResult['success']) {
                $text .= "\n\nRefund has been initiated and will be credited to your account within 5-7 business days.";
                $details[] = ['label' => 'Refund Status', 'value' => 'Initiated'];
            } elseif ($paymentMethod === 'cod') {
                $text .= "\n\nNo refund needed for COD orders.";
            }

            if ($order->wallet_balance > 0) {
                $details[] = ['label' => 'Wallet Refund', 'value' => '₹' . number_format($order->wallet_balance, 2)];
            }

            return [
                'text' => $text,
                'details' => $details,
                'can_cancel' => true,
                'cancelled' => true,
            ];

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('ChatbotController::answerCancelOrder - Exception occurred', [
                'order_id' => $order->id,
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return [
                'text' => "We encountered an issue while cancelling your order. Please contact our support team for assistance.",
                'details' => [
                    ['label' => 'Order ID', 'value' => (string) $order->id],
                    ['label' => 'Issue', 'value' => 'Technical error'],
                    ['label' => 'Need Help?', 'value' => 'Select "Need to chat with support team?" from the chatbot options.'],
                ],
                'can_cancel' => false,
            ];
        }
    }

    /**
     * Reverse-geocode a lat/lon pair via the Google Maps Geocoding API.
     * Returns the formatted address of the first result, or null on failure.
     */
    private function reverseGeocode(float $lat, float $lon): ?string
    {
        try {
            $apiKey = DB::table('settings')->where('variable', 'googleMapApiKey')->value('value');
            if (empty($apiKey)) {
                $apiKey = DB::table('settings')->where('variable', 'google_map_api_key')->value('value');
            }
            if (empty($apiKey)) {
                $apiKey = DB::table('settings')->where('variable', 'google_place_api_key')->value('value');
            }

            if (empty($apiKey)) {
                Log::warning('ChatbotController::reverseGeocode - No Google Maps API key found in settings.');
                return null;
            }

            $url = 'https://maps.googleapis.com/maps/api/geocode/json?'
                 . http_build_query(['latlng' => "{$lat},{$lon}", 'key' => $apiKey]);

            $ch = curl_init();
            curl_setopt_array($ch, [
                CURLOPT_URL            => $url,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_SSL_VERIFYPEER => false,
                CURLOPT_SSL_VERIFYHOST => false,
                CURLOPT_TIMEOUT        => 10,
            ]);
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if (!$response || $httpCode !== 200) {
                Log::warning('ChatbotController::reverseGeocode - API request failed', ['http_code' => $httpCode]);
                return null;
            }

            $json = json_decode($response, true);

            if (($json['status'] ?? '') !== 'OK' || empty($json['results'])) {
                return null;
            }

            return $json['results'][0]['formatted_address'] ?? null;

        } catch (\Exception $e) {
            Log::error('ChatbotController::reverseGeocode failed', [
                'lat'   => $lat,
                'lon'   => $lon,
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }
}
