<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeliveryBoyTransaction extends Model
{
    use HasFactory;
    public static $statusSuccess = "success";
    public static $statusFailed = "failed";

    public static $paymentTypeCod = "COD";

    protected $fillable = ['user_id','order_id','delivery_boy_id','type',
        'amount', 'status','message','transaction_date','settled_with_admin','partial_payment',
        'vendor_wait_charge'];

    /**
     * Get the order associated with this transaction
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class, 'order_id');
    }
}
