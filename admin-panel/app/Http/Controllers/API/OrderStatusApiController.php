<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\OrderStatusList;
use App\Models\ReturnStatusList;
use Illuminate\Http\Request;

class OrderStatusApiController extends Controller
{
    public function getOrderStatus(Request $request = null){
        if (!$request) {
            $request = new Request();
        }
        $orderStatuses = OrderStatusList::whereNotIn('id', [
            OrderStatusList::$paymentPending, // Exclude Payment Pending
            OrderStatusList::$selfPickupPending,
            OrderStatusList::$selfPickupReady,
            OrderStatusList::$selfPickupPicked
        ])->orderBy('id','ASC')->get();
        
        $returnStatuses = [];
        
        $isDeliveryBoyRoute = false;
        $isSellerRoute = false;
        
        $backtrace = debug_backtrace(DEBUG_BACKTRACE_IGNORE_ARGS, 2);
        if (isset($backtrace[1]['class'])) {
            $callerClass = $backtrace[1]['class'];
            $isDeliveryBoyRoute = $callerClass === 'App\\Http\\Controllers\\DeliveryBoyController';
            $isSellerRoute = $callerClass === 'App\\Http\\Controllers\\SellerController';
        }
        
        if ($isDeliveryBoyRoute) {
            $returnStatuses = [
                [
                    'id' => ReturnStatusList::$rOutForPickup,
                    'status' => ReturnStatusList::$outForPickup
                ],
                [
                    'id' => ReturnStatusList::$rReceivedFromCustomer,
                    'status' => ReturnStatusList::$receivedFromCustomer
                ],
                [
                    'id' => ReturnStatusList::$rCancelled,
                    'status' => ReturnStatusList::$cancelled
                ],
                [
                    'id' => ReturnStatusList::$rReturnToSeller,
                    'status' => ReturnStatusList::$returnToSeller
                ]
            ];
        } elseif ($isSellerRoute) {
            $returnStatuses = [
                [
                    'id' => ReturnStatusList::$rPending,
                    'status' => ReturnStatusList::$requestPending
                ],
                [
                    'id' => ReturnStatusList::$rDeliveryBoyAssigned,
                    'status' => ReturnStatusList::$deliveryBoyAssigned
                ],
                [
                    'id' => ReturnStatusList::$rApproved,
                    'status' => ReturnStatusList::$requestApproved
                ],
                [
                    'id' => ReturnStatusList::$rRejected,
                    'status' => ReturnStatusList::$requestRejected
                ]
            ];
        } else {
            $returnStatuses = [
                [
                    'id' => ReturnStatusList::$rPending,
                    'status' => ReturnStatusList::$requestPending
                ],
                [
                    'id' => ReturnStatusList::$rApproved,
                    'status' => ReturnStatusList::$requestApproved
                ],
                [
                    'id' => ReturnStatusList::$rRejected,
                    'status' => ReturnStatusList::$requestRejected
                ],
                [
                    'id' => ReturnStatusList::$rDeliveryBoyAssigned,
                    'status' => ReturnStatusList::$deliveryBoyAssigned
                ],
                [
                    'id' => ReturnStatusList::$rOutForPickup,
                    'status' => ReturnStatusList::$outForPickup
                ],
                [
                    'id' => ReturnStatusList::$rReceivedFromCustomer,
                    'status' => ReturnStatusList::$receivedFromCustomer
                ],
                [
                    'id' => ReturnStatusList::$rCancelled,
                    'status' => ReturnStatusList::$cancelled
                ],
                [
                    'id' => ReturnStatusList::$rReturnToSeller,
                    'status' => ReturnStatusList::$returnToSeller
                ]
            ];
        }
        
        if(!empty($orderStatuses)){
            return response()->json([
                'status' => 1,
                'message' => 'success',
                'data' => $orderStatuses,
                'return_statuses' => $returnStatuses
            ]);
        }else{
            return CommonHelper::responseError('Status not found.');
        }
    }

    public function getProcessingOrderStatus(){
        $orderStatuses = OrderStatusList::whereIn('id', [
            OrderStatusList::$received,
            OrderStatusList::$processed,
        ])->orderBy('id', 'ASC')->get();

        if (!empty($orderStatuses)) {
            return response()->json([
                'status' => 1,
                'message' => 'success',
                'data' => $orderStatuses,
            ]);
        } else {
            return CommonHelper::responseError('Status not found.');
        }
    }

    public function getSelfPickupOrderStatus(Request $request = null){
        $selfPickupStatuses = [
            [
                'id' => OrderStatusList::$paymentPending,
                'status' => OrderStatusList::$orderPaymentPending
            ],
            [
                'id' => OrderStatusList::$selfPickupPending,
                'status' => OrderStatusList::$orderSelfPickupPending
            ],
            [
                'id' => OrderStatusList::$selfPickupReady,
                'status' => OrderStatusList::$orderSelfPickupReady
            ],
            [
                'id' => OrderStatusList::$selfPickupPicked,
                'status' => OrderStatusList::$orderSelfPickupPicked
            ],
            [
                'id' => OrderStatusList::$cancelled,
                'status' => OrderStatusList::$orderCancelled
            ],
            [
                'id' => OrderStatusList::$returned,
                'status' => OrderStatusList::$orderReturned
            ]
        ];

        return response()->json([
            'status' => 1,
            'message' => 'success',
            'data' => $selfPickupStatuses
        ]);
    }
}
