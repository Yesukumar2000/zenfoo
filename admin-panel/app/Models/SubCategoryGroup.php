<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SubCategoryGroup extends Model
{
    use HasFactory;

    protected $table = 'sub_category_groups';

    protected $fillable = [
        'seller_id',
        'name',
        'image',
        'subcategory_ids',
        'category_group_id',
        'is_group',
        'is_super_mart',
        'store_id',
        'category_id',
        'is_special_item',
    ];

    protected $appends = ['image_url'];

    public function getImageUrlAttribute(){

        if($this->image){
            $image_url = $this->image;
        }else{
            $image_url = '';
        }
        return $image_url;
    }
    public $timestamps = true;

    public function categoryGroup()
    {
        return $this->belongsTo(CategoryGroup::class, 'category_group_id');
    }

    public function category()
    {
        return $this->belongsTo(Category::class, 'category_id');
    }

    public function subcategories()
    {
        $ids = $this->subcategory_ids
            ? array_filter(explode(',', $this->subcategory_ids))
            : [];

        return SubCategory::whereIn('id', $ids)->get();
    }

    public function subcategoryIdsArray()
    {
        return $this->subcategory_ids
            ? array_filter(explode(',', $this->subcategory_ids))
            : [];
    }

    public function seller()
    {
        return $this->belongsTo(Seller::class);
    }
}
