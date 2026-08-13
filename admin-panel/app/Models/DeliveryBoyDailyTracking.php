<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeliveryBoyDailyTracking extends Model
{
    use HasFactory;

    protected $table = 'delivery_boy_daily_tracking';

    protected $fillable = [
        'delivery_boy_id',
        'tracking_date',
        'online_status',
        'first_login_at',
        'last_activity_at',
        'total_login_minutes',
        'total_earnings',
        'total_distance_km',
        'gigs_completed',
        'orders_delivered',
        'orders_cancelled'
    ];

    protected $casts = [
        'tracking_date' => 'date',
        'first_login_at' => 'datetime',
        'last_activity_at' => 'datetime',
        'total_login_minutes' => 'integer',
        'total_earnings' => 'decimal:2',
        'total_distance_km' => 'decimal:2',
        'gigs_completed' => 'integer',
        'orders_delivered' => 'integer',
        'orders_cancelled' => 'integer',
    ];

    public function deliveryBoy()
    {
        return $this->belongsTo(DeliveryBoy::class);
    }

    /**
     * Get total login hours
     */
    public function getTotalLoginHoursAttribute()
    {
        return round($this->total_login_minutes / 60, 2);
    }
}
