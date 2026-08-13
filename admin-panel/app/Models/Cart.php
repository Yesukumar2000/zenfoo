<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Cart extends Model
{
    use HasFactory;

    protected $hidden = [];
    protected $appends = ['image_url'];

    public function images(){
        return $this->hasMany(ProductImages::class,'product_id','product_id')
            ->where('product_variant_id',0);
        //$res = $res->makeHidden(['image']);
    }
    public function products()
    {
        return $this->belongsTo(Product::class, 'product_id');
    }

    public function product()
    {
        return $this->belongsTo(Product::class, 'product_id');
    }


    // Relation to ProductVariant
    public function variants()
    {
        return $this->belongsTo(ProductVariant::class, 'product_variant_id');
    }  

    public function getImageUrlAttribute(){
        if($this->image){
            return str_starts_with($this->image, 'http') ? $this->image : url('storage/' . $this->image);
        }
        return '';
    }

}
