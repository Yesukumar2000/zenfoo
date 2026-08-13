<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CustomerItemMissingReport extends Model
{
    use HasFactory;

    protected $table = 'customer_item_missing_reports';

    protected $fillable = [
        'customer_id',
        'order_id',
        'report_type',
        'selected_items',
        'selected_combo_items',
        'description',
        'is_refund_requested',
        'status',
        'admin_remarks',
        'status_change_json',
    ];

    protected $casts = [
        'selected_items' => 'array',
        'selected_combo_items' => 'array',
        'is_refund_requested' => 'boolean',
        'status_change_json' => 'array',
    ];

    // Status constants
    public static $statusPending = 0;
    public static $statusInProgress = 1;
    public static $statusResolved = 2;
    public static $statusRejected = 3;
    public static $statusDriverAssigned = 4;
    public static $statusDriverTookItem = 5;
    public static $statusDriverReturnedItem = 6;

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
            4 => 'Driver Assigned',
            5 => 'Driver Took Item',
            6 => 'Driver Returned Item',
        ];

        return $statuses[$this->status] ?? 'Unknown';
    }
}
