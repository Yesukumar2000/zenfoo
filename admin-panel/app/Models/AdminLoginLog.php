<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AdminLoginLog extends Model
{
    use HasFactory;

    protected $table = 'admin_login_logs';

    protected $fillable = [
        'admin_id', 'email', 'ip_address', 'user_agent', 'device', 'location', 'is_success',
    ];

    public function admin()
    {
        return $this->belongsTo(Admin::class, 'admin_id', 'id');
    }
}
