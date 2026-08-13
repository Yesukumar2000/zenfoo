<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeliveryBoySession extends Model
{
    use HasFactory;

    protected $fillable = [
        'delivery_boy_id',
        'gig_booking_id',
        'login_at',
        'logout_at',
        'duration_minutes',
        'latitude_start',
        'longitude_start',
        'latitude_end',
        'longitude_end'
    ];

    protected $casts = [
        'login_at' => 'datetime',
        'logout_at' => 'datetime',
        'duration_minutes' => 'integer',
        'latitude_start' => 'decimal:8',
        'longitude_start' => 'decimal:8',
        'latitude_end' => 'decimal:8',
        'longitude_end' => 'decimal:8',
    ];

    public function deliveryBoy()
    {
        return $this->belongsTo(DeliveryBoy::class);
    }

    public function gigBooking()
    {
        return $this->belongsTo(DeliveryBoyGigBooking::class, 'gig_booking_id');
    }

    public function locationHistory()
    {
        return $this->hasMany(DeliveryBoyLocationHistory::class, 'session_id');
    }
}
