<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DriverIssueZenfoo extends Model
{
    use HasFactory;

    protected $table = 'driver_issues_zenfoo';

    protected $fillable = [
        'driver_id',
        'issue_type',
        'issue_ids',
        'description',
        'attachments',
        'amount',
        'pay_type',
        'status',
        'admin_message'
    ];

    protected $casts = [
        'issue_ids' => 'array',
        'attachments' => 'array',
        'amount' => 'decimal:2'
    ];

    /**
     * Get the delivery boy associated with this issue
     */
    public function deliveryBoy()
    {
        return $this->belongsTo(DeliveryBoy::class, 'driver_id');
    }
}
