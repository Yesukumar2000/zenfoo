<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class PrivacyPolicySellerApiController extends Controller
{
    public function index()
    {
        $variables = array("privacy_policy_seller","terms_conditions_seller");
        $policies = Setting::whereIn('variable',$variables )->get();
        return CommonHelper::responseWithData($policies);
    }
    public function save(Request $request)
    {   
        foreach ($request->all() as $key => $value){
            $setting = Setting::where('variable', $key)->first();
            if ($setting) {
                $setting->variable = $key;
                $setting->value = $value??"";
                $setting->save();
            } else {
                $setting = new Setting();
                $setting->variable = $key;
                $setting->value = $value??"";
                $setting->save();
            }
        }
        return CommonHelper::responseSuccess("Seller Privacy Policy And Terms & Conditions Saved Successfully!");
    }
    private function renderPolicy(string $title, string $variable){
        return view('policies.show', [
            'title'   => $title,
            'content' => Setting::get_value($variable),
        ]);
    }

    public function printPrivacyPolicy(){
        return $this->renderPolicy('Privacy Policy for Zenfoo Vendor Partners', 'privacy_policy_seller');
    }
    public function printTermsConditions(){
        return $this->renderPolicy('Terms & Conditions for Zenfoo Vendor Partners', 'terms_conditions_seller');
    }
}
