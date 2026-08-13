<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Store extends Model
{
    use HasFactory;

    protected $fillable = ['name','icon','color','image','vendor_img','description','managed_by_admin','is_super_mart','is_active','is_meat','is_food','is_vegetable'];

     protected $appends = ['icon_url','image_url','vendor_img_url'];

     protected $casts = [
        'is_active' => 'boolean',
        'managed_by_admin' => 'boolean',
        'is_super_mart' => 'boolean',
        'is_meat' => 'boolean',
        'is_food' => 'boolean',
        'is_vegetable' => 'boolean',
     ];

    public function getIconUrlAttribute(){

        if($this->icon){
            $icon_url = $this->icon;
        }else{
            $icon_url = '';
        }
        return $icon_url;
    }

    
    public function getImageUrlAttribute(){

        if($this->image){
            $image_url = $this->image;
        }else{
            $image_url = '';
        }
        return $image_url;
    }

        
    public function getVendorImgUrlAttribute(){

        if($this->vendor_img){
            $vendor_img_url = $this->vendor_img;
        }else{
            $vendor_img_url = '';
        }
        return $vendor_img_url;
    }

    public function categoryGroups()
    {
        return $this->belongsToMany(CategoryGroup::class, 'category_group_store', 'store_id', 'category_group_id')
            ->orderBy('row_order', 'ASC');
    }
}
