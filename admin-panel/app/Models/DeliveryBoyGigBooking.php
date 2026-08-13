<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeliveryBoyGigBooking extends Model
{
    use HasFactory;

    protected $fillable = [
        'delivery_boy_id',
        'gig_slot_id',
        'booking_status',
        'booked_at',
        'started_at',
        'completed_at',
        'cancelled_at',
        'ended_at',
        'earnings',
        'earnings_amount',
        'orders_completed',
        'orders_cancelled',
        'distance_km',
        'actual_login_hours',
        'cancellation_reason'
    ];

    protected $casts = [
        'booked_at' => 'datetime',
        'started_at' => 'datetime',
        'completed_at' => 'datetime',
        'cancelled_at' => 'datetime',
        'ended_at' => 'datetime',
        'earnings' => 'decimal:2',
        'earnings_amount' => 'decimal:2',
        'distance_km' => 'decimal:2',
        'actual_login_hours' => 'decimal:2',
        'orders_completed' => 'integer',
        'orders_cancelled' => 'integer',
    ];

    public function deliveryBoy()
    {
        return $this->belongsTo(DeliveryBoy::class);
    }

    public function gigSlot()
    {
        return $this->belongsTo(GigSlot::class);
    }

    public function sessions()
    {
        return $this->hasMany(DeliveryBoySession::class, 'gig_booking_id');
    }
}
