<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeliveryBoyReferralTracking extends Model
{
    use HasFactory;

    protected $table = 'delivery_boy_referral_tracking';

    protected $fillable = [
        'referring_delivery_boy_id',
        'referred_delivery_boy_id',
        'completed_orders_count',
        'required_orders_count',
        'bonus_amount',
        'is_bonus_paid',
        'bonus_transaction_id',
        'bonus_paid_at'
    ];

    protected $casts = [
        'completed_orders_count' => 'integer',
        'required_orders_count' => 'integer',
        'bonus_amount' => 'decimal:2',
        'is_bonus_paid' => 'boolean',
        'bonus_paid_at' => 'datetime'
    ];

    /**
     * Get the delivery boy who made the referral
     */
    public function referringDeliveryBoy()
    {
        return $this->belongsTo(DeliveryBoy::class, 'referring_delivery_boy_id');
    }

    /**
     * Get the delivery boy who was referred
     */
    public function referredDeliveryBoy()
    {
        return $this->belongsTo(DeliveryBoy::class, 'referred_delivery_boy_id');
    }

    /**
     * Get the bonus transaction
     */
    public function bonusTransaction()
    {
        return $this->belongsTo(DeliveryBoyTransaction::class, 'bonus_transaction_id');
    }

    /**
     * Check if bonus should be paid
     */
    public function shouldPayBonus()
    {
        return !$this->is_bonus_paid &&
               $this->completed_orders_count >= $this->required_orders_count;
    }

    /**
     * Get progress percentage
     */
    public function getProgressPercentage()
    {
        if ($this->required_orders_count == 0) {
            return 100;
        }
        return min(100, ($this->completed_orders_count / $this->required_orders_count) * 100);
    }
}
