<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CustomerAppSectionProduct extends Model
{
    use HasFactory;

    protected $fillable = ['product_id', 'section_id'];

    protected $casts = [
        'product_id' => 'integer',
        'section_id' => 'integer',
    ];

    /**
     * Get the product associated with this section product
     */
    public function product()
    {
        return $this->belongsTo(Product::class, 'product_id');
    }

    /**
     * Get the section associated with this section product
     */
    public function section()
    {
        return $this->belongsTo(CustomerAppSection::class, 'section_id');
    }
}