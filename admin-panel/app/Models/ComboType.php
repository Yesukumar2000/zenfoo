<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class ComboType extends Model
{
    protected $table = 'combo_types';

    protected $fillable = [
        'name_of_type',
    ];

    public $timestamps = true;
}