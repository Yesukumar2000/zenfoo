<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CategoryGroupStore extends Model
{
    use HasFactory;

    protected $table = 'category_group_store';

    protected $fillable = [
        'store_id',
        'category_group_id',
    ];

    public $timestamps = true;

    /**
     * Relationship: Each mapping belongs to a Store
     */
    public function store()
    {
        return $this->belongsTo(Store::class, 'store_id');
    }

    /**
     * Relationship: Each mapping belongs to a Category Group
     */
    public function categoryGroup()
    {
        return $this->belongsTo(CategoryGroup::class, 'category_group_id');
    }
}
