<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\Request;

class AboutContactApiController extends Controller
{
    public function index()
    {
        $variables = ['about_us', 'contact_us'];
        $data = Setting::whereIn('variable', $variables)->get();
        return CommonHelper::responseWithData($data);
    }

    public function save(Request $request)
    {
        foreach ($request->all() as $key => $value) {
            $setting = Setting::where('variable', $key)->first();
            if ($setting) {
                $setting->value = $value ?? '';
                $setting->save();
            } else {
                Setting::create([
                    'variable' => $key,
                    'value'    => $value ?? '',
                ]);
            }
        }
        return CommonHelper::responseSuccess('About Us & Contact Us saved successfully!');
    }

    public function printAboutUs()
    {
        echo Setting::get_value('about_us');
    }

    public function printContactUs()
    {
        echo Setting::get_value('contact_us');
    }
}
