<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CategoryGroup extends Model
{
    use HasFactory;

     protected $fillable = [
        'seller_id',
        'name',
        'image',
        'category_ids',
        'status',
        'is_super_mart',
    ];

    protected $appends = ['image_url']; 


    // Optional: get category ids as array
    public function getCategoryIdsArrayAttribute()
    {
        return explode(',', $this->category_ids);
    }

    public function subCategoryGroups(){
         return $this->hasMany(CategorySubGroup::class)->orderBy('row_order', 'ASC');
    }

     public function getImageUrlAttribute(){

        if($this->image){
            $image_url = $this->image;
        }else{
            $image_url = '';
        }
        return $image_url;
    }
    

    public function stores()
    {
        return $this->belongsToMany(Store::class, 'category_group_store');
    }

    public function seller()
    {
        return $this->belongsTo(Seller::class);
    }
}
