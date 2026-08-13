<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Casts\Attribute;

class Order extends Model
{
    use HasFactory, SoftDeletes;
    protected $hidden = [];
    //protected $appends = ['active_status_name'];

    /**
     * order_number is not a column - it is the customer facing order number
     * (ZF-0451) held in orders_id, exposed under a clearer name and appended to
     * every order payload so the apps and panel can render it directly.
     */
    protected $appends = ['order_number'];

    public function getOrderNumberAttribute()
    {
        $stored = $this->orders_id;
        $prefix = \App\Helpers\CommonHelper::ORDER_NUMBER_PREFIX;

        if (is_string($stored) && stripos($stored, $prefix) === 0) {
            return $stored;
        }

        // Orders placed before order numbers existed hold a random value here,
        // and demo orders hold a ZFDEMO marker. Neither is customer facing, so
        // derive the number from the id - the same value the backfill writes.
        return \App\Helpers\CommonHelper::formatOrderNumber($this->id);
    }



    public static $activeType = 1;
    public static $previousType = 0;

    /**
     * Reasons an admin can pick when cancelling an order.
     * Key = value stored in orders.cancellation_reason, value = label for the panel.
     */
    public static $cancelReasons = [
        'driver_issue'      => 'Driver issue (phone dead / unreachable / not delivering)',
        'store_issue'       => 'Store issue (closed / cannot prepare)',
        'item_unavailable'  => 'Item not available',
        'customer_request'  => 'Customer requested cancellation',
        'other'             => 'Other',
    ];

    /**
     * Reasons that are allowed even after the food is already handed to the driver.
     */
    public static $cancelReasonsAllowedAfterHandover = ['driver_issue'];

    /**
     * Reasons that must be refunded to the customer wallet instead of the payment gateway.
     */
    public static $cancelReasonsRefundedToWallet = ['driver_issue'];
    protected $casts = [
        'additional_charges' => 'array',
        'cart_metadata' => 'array',
        'delivery_time_before_images' => 'array',
        'locations_json' => 'array',
        'order_items_snapshot' => 'array',
    ];

    public static $previousTypeStatus = 0;

    public static function boot()
    {
        parent::boot();
        static::deleting(function ($data) { // before delete() method call this
            $data->items()->delete();
        });
    }

    function getActiveStatusNameAttribute()
    {

    }

    public function items()
    {
        return $this->hasMany(OrderItem::class, 'order_id', 'id');
    }

    public function comboItems()
    {
        return $this->hasMany(OrderComboItem::class, 'order_id', 'id');
    }

    public function user()
    {
        return $this->hasOne(User::class, 'id', 'user_id');
    }

    public function orderStatus()
    {
        return $this->hasMany(OrderStatus::class, 'order_id', 'id');
    }

    public function deliveryBoy()
    {
        return $this->belongsTo(DeliveryBoy::class, 'delivery_boy_id', 'id');
    }

    public function setDeliveryBoyBonusDetailsAttribute($value)
    {
        $this->attributes['delivery_boy_bonus_details'] = json_encode($value);
    }

    public function getDeliveryBoyBonusDetailsAttribute($value)
    {
        return json_decode($value, true);
    }

}
