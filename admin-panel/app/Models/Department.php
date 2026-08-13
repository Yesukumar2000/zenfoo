<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Department extends Model
{
    use HasFactory;

    protected $table = 'departments';

    protected $fillable = ['name', 'color', 'description', 'status'];

    public function admins()
    {
        return $this->hasMany(Admin::class, 'department_id', 'id');
    }
}
