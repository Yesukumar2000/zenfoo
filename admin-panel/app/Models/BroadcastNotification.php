<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BroadcastNotification extends Model
{
    use HasFactory;

    protected $fillable = [
        'target_type',
        'title',
        'message',
        'image',
        'total_sent',
        'total_failed',
        'results',
    ];

    protected $casts = [
        'results' => 'array',
    ];
}
