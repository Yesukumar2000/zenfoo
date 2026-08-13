<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeliveryBoyNotification extends Model
{
    use HasFactory;

    protected $fillable = [
        'delivery_boy_id',
        'title',
        'message',
        'type',
        'order_item_id'
    ];

    public function deliveryBoy()
    {
        return $this->belongsTo(DeliveryBoy::class);
    }
}
