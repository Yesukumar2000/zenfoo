<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CustomerWrongItemReport extends Model
{
    use HasFactory;

    protected $table = 'customer_wrong_item_reports';

    protected $fillable = [
        'customer_id',
        'order_id',
        'img_url',
        'description',
        'is_refund_requested',
        'status',
        'admin_remarks',
    ];

    protected $casts = [
        'is_refund_requested' => 'boolean',
    ];

    // Status constants
    public static $statusPending = 0;
    public static $statusInProgress = 1;
    public static $statusResolved = 2;
    public static $statusRejected = 3;

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id', 'id');
    }

    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id', 'id');
    }

    public function getStatusNameAttribute()
    {
        $statuses = [
            0 => 'Pending',
            1 => 'In Progress',
            2 => 'Resolved',
            3 => 'Rejected',
        ];

        return $statuses[$this->status] ?? 'Unknown';
    }
}
