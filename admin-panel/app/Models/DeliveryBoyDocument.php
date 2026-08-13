<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeliveryBoyDocument extends Model
{
    use HasFactory;

    protected $fillable = [
        'delivery_boy_id',
        'driving_license_number',
        'driving_license_front_path',
        'driving_license_back_path',
        'driving_license_status',
        'rc_number',
        'rc_front_path',
        'rc_back_path',
        'rc_status',
        'aadhar_number',
        'aadhar_front_path',
        'aadhar_back_path',
        'aadhar_status',
        'pan_number',
        'pan_front_path',
        'pan_back_path',
        'pan_status',
        'bank_name',
        'account_holder_name',
        'account_number',
        'ifsc_code',
        'bank_passbook_image_path',
        'bank_details_status',
    ];

    protected $casts = [
        'driving_license_status' => 'string',
        'rc_status' => 'string',
        'aadhar_status' => 'string',
        'pan_status' => 'string',
        'bank_details_status' => 'string',
    ];

    /**
     * Get the delivery boy that owns the documents
     */
    public function deliveryBoy()
    {
        return $this->belongsTo(DeliveryBoy::class, 'delivery_boy_id');
    }

    /**
     * Get overall document status
     */
    public function getOverallStatusAttribute()
    {
        $statuses = [
            $this->driving_license_status,
            $this->rc_status,
            $this->aadhar_status,
            $this->pan_status,
            $this->bank_details_status,
        ];

        if (in_array('rejected', $statuses)) {
            return 'rejected';
        }

        if (in_array('pending_verification', $statuses)) {
            return 'pending_verification';
        }

        if (in_array('not_uploaded', $statuses)) {
            return 'incomplete';
        }

        return 'verified';
    }

    /**
     * Get URL for driving license front
     */
    public function getDrivingLicenseFrontUrlAttribute()
    {
        return $this->driving_license_front_path ? $this->driving_license_front_path : null;
    }

    /**
     * Get URL for driving license back
     */
    public function getDrivingLicenseBackUrlAttribute()
    {
        return $this->driving_license_back_path ? $this->driving_license_back_path : null;
    }

    /**
     * Get URL for RC front
     */
    public function getRcFrontUrlAttribute()
    {
        return $this->rc_front_path ? $this->rc_front_path : null;
    }

    /**
     * Get URL for RC back
     */
    public function getRcBackUrlAttribute()
    {
        return $this->rc_back_path ? $this->rc_back_path : null;
    }

    /**
     * Get URL for Aadhar front
     */
    public function getAadharFrontUrlAttribute()
    {
        return $this->aadhar_front_path ? $this->aadhar_front_path : null;
    }

    /**
     * Get URL for Aadhar back
     */
    public function getAadharBackUrlAttribute()
    {
        return $this->aadhar_back_path ? $this->aadhar_back_path : null;
    }

    /**
     * Get URL for PAN front
     */
    public function getPanFrontUrlAttribute()
    {
        return $this->pan_front_path ? $this->pan_front_path : null;
    }

    /**
     * Get URL for PAN back
     */
    public function getPanBackUrlAttribute()
    {
        return $this->pan_back_path ? $this->pan_back_path : null;
    }

    /**
     * Get URL for bank passbook image
     */
    public function getBankPassbookImageUrlAttribute()
    {
        return $this->bank_passbook_image_path ? $this->bank_passbook_image_path : null;
    }
}
