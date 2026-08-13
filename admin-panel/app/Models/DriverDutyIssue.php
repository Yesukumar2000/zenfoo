<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DriverDutyIssue extends Model
{
    use HasFactory;

    protected $fillable = [
        'type',
        'delivery_boy_id',
        'date_of_issue',
        'admin_response',
    ];

    protected $casts = [
        'date_of_issue' => 'datetime',
    ];

    public function deliveryBoy()
    {
        return $this->belongsTo(DeliveryBoy::class, 'delivery_boy_id', 'id');
    }
}