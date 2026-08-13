<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\Category;
class CategorySubGroup extends Model
{
    use HasFactory;

    protected $table = "sub_category_groups";
        protected $fillable = [
        'seller_id',
        'name',
        'image',
        'is_group',
        'category_group_id',
        'subcategory_ids',
        'is_super_mart',
        'is_children_allowed',
    ];
     protected $appends = ['image_url']; 

    // Optional: get category ids as array
    public function getSubCategoryIdsArrayAttribute()
    {
        return explode(',', $this->subcategory_ids);
    }

     public function getImageUrlAttribute()
    {
        return $this->image ? $this->image : null;
    }

    public function categoryGroup()
    {
        return $this->belongsTo(CategoryGroup::class);
    }
}
