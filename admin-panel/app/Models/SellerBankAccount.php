<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SellerBankAccount extends Model
{
    use HasFactory;

    protected $fillable = [
        'seller_id',
        'bank_name',
        'account_number',
        'ifsc_code',
        'account_holder_name',
        'document',
        'document_type',
        'is_default',
        'is_verified',
    ];

    protected $casts = [
        'is_default' => 'boolean',
        'is_verified' => 'boolean',
    ];

    protected $appends = ['document_url'];

    public function seller()
    {
        return $this->belongsTo(Seller::class);
    }

    public function getDocumentUrlAttribute()
    {
        if ($this->document) {
            return $this->document;
        }
        return null;
    }

    /**
     * Set only this account as default for the seller
     */
    public function setAsDefault()
    {
        // Set all other accounts for this seller as non-default
        self::where('seller_id', $this->seller_id)
            ->where('id', '!=', $this->id)
            ->update(['is_default' => false]);

        // Set this account as default
        $this->is_default = true;
        $this->save();
    }
}
