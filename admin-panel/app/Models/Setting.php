<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Setting extends Model
{
    use HasFactory;
    public $timestamps = false;

    protected $fillable = ['variable', 'value'];

    public static $codModeGlobal = "global";
    public static $codModeProduct = "product";


    public static function get_value($name) {
        $settings = self::where('variable', $name);
       
        if($settings->count() == 0){ return '';};

        $setting = $settings->first();
        return $setting->value;
    }

    public static $supportApps = ['customer', 'seller', 'driver'];

    /**
     * Resolve a support contact for a given app, falling back to the global value.
     * $name is the base key, e.g. 'support_number' or 'support_email'.
     * $app is one of self::$supportApps; anything else resolves to the global value.
     */
    public static function support_value($name, $app = null) {
        if (in_array($app, self::$supportApps, true)) {
            $scoped = trim((string) self::get_value($name . '_' . $app));
            if ($scoped !== '') return $scoped;
        }

        return trim((string) self::get_value($name));
    }

    public static function update_value($name, $value) {
        $settings = self::where('variable', $name);
        if($settings->count() == 0) throw new \Exception("Empty Setting for ".$name);

        $setting = $settings->first();
        $setting->value = $value;
        $setting->save();
    }
}
