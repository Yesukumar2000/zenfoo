<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GigSlot extends Model
{
    use HasFactory;

    protected $fillable = [
        'gig_id',
        'slot_number',
        'slot_name',
        'slot_date',
        'start_time',
        'end_time',
        'max_bookings',
        'current_bookings',
        'status'
    ];

    protected $casts = [
        'slot_date' => 'date',
        'max_bookings' => 'integer',
        'current_bookings' => 'integer',
        'status' => 'integer',
    ];

    public function gig()
    {
        return $this->belongsTo(Gig::class);
    }

    public function bookings()
    {
        return $this->hasMany(DeliveryBoyGigBooking::class);
    }

    public function scopeAvailable($query)
    {
        return $query->where('status', 1)
            ->whereColumn('current_bookings', '<', 'max_bookings');
    }

    public function scopeUpcoming($query)
    {
        return $query->where('slot_date', '>=', now()->toDateString());
    }
}
