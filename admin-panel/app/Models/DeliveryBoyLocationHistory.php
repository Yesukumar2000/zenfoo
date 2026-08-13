<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeliveryBoyLocationHistory extends Model
{
    use HasFactory;

    protected $table = 'delivery_boy_location_history';

    protected $fillable = [
        'delivery_boy_id',
        'session_id',
        'latitude',
        'longitude',
        'distance_from_last_km',
        'tracked_at'
    ];

    protected $casts = [
        'latitude' => 'decimal:8',
        'longitude' => 'decimal:8',
        'distance_from_last_km' => 'decimal:2',
        'tracked_at' => 'datetime',
    ];

    public function deliveryBoy()
    {
        return $this->belongsTo(DeliveryBoy::class);
    }

    public function session()
    {
        return $this->belongsTo(DeliveryBoySession::class, 'session_id');
    }
}
