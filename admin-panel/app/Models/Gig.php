<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Gig extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'display_name',
        'start_time',
        'end_time',
        'duration_hours',
        'base_earnings',
        'status'
    ];

    protected $casts = [
        'base_earnings' => 'decimal:2',
        'status' => 'integer',
    ];

    public function slots()
    {
        return $this->hasMany(GigSlot::class);
    }

    public function bookings()
    {
        return $this->hasMany(DeliveryBoyGigBooking::class);
    }

    public function scopeActive($query)
    {
        return $query->where('status', 1);
    }
}
