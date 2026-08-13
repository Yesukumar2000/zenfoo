<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeliveryBoyEmergencyContact extends Model
{
    use HasFactory;

    protected $fillable = [
        'delivery_boy_id',
        'name',
        'mobile_number',
        'relation',
    ];

    /**
     * Get the delivery boy that owns the emergency contact
     */
    public function deliveryBoy()
    {
        return $this->belongsTo(DeliveryBoy::class, 'delivery_boy_id');
    }
}
