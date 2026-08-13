<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Brand extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'image', 'status', 'category_ids', 'seller_id', 'store_id', 'category_group_id', 'sub_category_group_id'];
    protected $appends = ['image_url', 'categories'];
    protected $hidden = [];
    protected $casts = [
        'category_ids' => 'array',
    ];
    public function getImageUrlAttribute(){
        if($this->image){
            return str_starts_with($this->image, 'http') ? $this->image : url('storage/' . $this->image);
        }
        return '';
    }
    public function products()
    {
        return $this->hasMany(Product::class, 'brand_id', 'id');
    }

    public function seller()
    {
        return $this->belongsTo(Seller::class, 'seller_id', 'id');
    }

    public function getCategoriesAttribute()
    {
        if (!$this->category_ids) {
            return [];
        }
        $ids = is_array($this->category_ids) ? $this->category_ids : explode(',', $this->category_ids);
        return Category::whereIn('id', $ids)->get();
    }

    
}
