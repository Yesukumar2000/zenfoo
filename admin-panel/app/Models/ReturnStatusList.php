<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ReturnStatusList extends Model
{
    use HasFactory;

    public $timestamps = false;

    public static $rPending = 1;
    public static $rApproved = 2;
    public static $rRejected = 3;
    public static $rDeliveryBoyAssigned = 4;
    public static $rOutForPickup = 5;
    public static $rReceivedFromCustomer = 6;
    public static $rCancelled = 7;
    public static $rReturnToSeller = 8;

    public static $requestPending = "Request Pending";
    public static $requestApproved = "Request Approved";
    public static $requestRejected = "Request Rejected";
    public static $deliveryBoyAssigned = "Delivery Boy Assigned";
    public static $outForPickup = "Out for Pickup";
    public static $receivedFromCustomer = "Received from Customer";
    public static $cancelled = "Cancelled";
    public static $returnToSeller = "Return to Seller";

    public static function getStatusName($status)
    {
        switch ($status) {
            case self::$rPending:
                return self::$requestPending;
            case self::$rApproved:
                return self::$requestApproved;
            case self::$rRejected:
                return self::$requestRejected;
            case self::$rDeliveryBoyAssigned:
                return self::$deliveryBoyAssigned;
            case self::$rOutForPickup:
                return self::$outForPickup;
            case self::$rReceivedFromCustomer:
                return self::$receivedFromCustomer;
            case self::$rCancelled:
                return self::$cancelled;
            case self::$rReturnToSeller:
                return self::$returnToSeller;
            default:
                return "Unknown Status";
        }
    }

    public static function getAllStatuses()
    {
        return [
            self::$rPending => self::$requestPending,
            self::$rDeliveryBoyAssigned => self::$deliveryBoyAssigned,
            self::$rOutForPickup => self::$outForPickup,
            self::$rReceivedFromCustomer => self::$receivedFromCustomer,
            self::$rCancelled => self::$cancelled,
            self::$rReturnToSeller => self::$returnToSeller,
            self::$rApproved => self::$requestApproved,
            self::$rRejected => self::$requestRejected,
        ];
    }

    public static function getDeliveryBoyStatuses()
    {
        return [
            self::$rOutForPickup => self::$outForPickup,
            self::$rReceivedFromCustomer => self::$receivedFromCustomer,
            self::$rCancelled => self::$cancelled,
            self::$rReturnToSeller => self::$returnToSeller,
        ];
    }
}
