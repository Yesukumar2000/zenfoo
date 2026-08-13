<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AdminSession extends Model
{
    use HasFactory;

    protected $table = 'admin_sessions';

    protected $fillable = [
        'admin_id', 'session_id', 'ip_address', 'user_agent', 'device',
        'platform', 'location', 'is_current', 'last_activity',
    ];

    protected $casts = [
        'last_activity' => 'datetime',
    ];

    public function admin()
    {
        return $this->belongsTo(Admin::class, 'admin_id', 'id');
    }
}
