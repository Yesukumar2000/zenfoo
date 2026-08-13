<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AdminKyc extends Model
{
    use HasFactory;

    protected $table = 'admin_kyc';

    protected $fillable = [
        'admin_id', 'document_type', 'document_number', 'document_file',
        'status', 'remarks', 'verified_by', 'verified_at',
    ];

    protected $casts = [
        'verified_at' => 'datetime',
    ];

    public function admin()
    {
        return $this->belongsTo(Admin::class, 'admin_id', 'id');
    }
}
