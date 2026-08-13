<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\ZenfooOffer;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class ZenfooOfferController extends Controller
{
    public function index()
    {
        $offers = ZenfooOffer::orderBy('id', 'DESC')->get();
        return CommonHelper::responseWithData($offers);
    }

    public function save(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'order_count' => 'required|integer|min:0',
            'amount' => 'required|numeric|min:0',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'image' => 'required|image|mimes:jpeg,png,jpg,gif,webp|max:5120',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $offer = new ZenfooOffer();
        $offer->title = $request->title;
        $offer->description = $request->description;
        $offer->order_count = $request->order_count ?? 0;
        $offer->amount = $request->amount ?? 0;
        $offer->status = 1;
        $offer->start_date = $request->start_date;
        $offer->end_date = $request->end_date;

        if ($request->hasFile('image')) {
            $result = MediaUploadService::uploadWithFullUrl($request->file('image'), 'zenfoo_offers');
            $offer->img_url = $result['url'];
        }

        $offer->save();
        return CommonHelper::responseSuccess("Offer saved successfully!");
    }

    public function update(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|exists:zenfoo_offers,id',
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'order_count' => 'required|integer|min:0',
            'amount' => 'required|numeric|min:0',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:5120',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $offer = ZenfooOffer::find($request->id);

        if (!$offer) {
            return CommonHelper::responseError("Offer not found!");
        }

        $offer->title = $request->title;
        $offer->description = $request->description;
        $offer->order_count = $request->order_count ?? 0;
        $offer->amount = $request->amount ?? 0;
        // $offer->status = $request->status ?? $offer->status;
        $offer->status = 1;
        $offer->start_date = $request->start_date;
        $offer->end_date = $request->end_date;

        if ($request->hasFile('image')) {
            // Delete old image using URL
            if ($offer->img_url) {
                MediaUploadService::deleteFileByUrl($offer->img_url);
            }
            $result = MediaUploadService::uploadWithFullUrl($request->file('image'), 'zenfoo_offers');
            $offer->img_url = $result['url'];
        }

        $offer->save();
        return CommonHelper::responseSuccess("Offer updated successfully!");
    }

    public function delete(Request $request)
    {
        if (isset($request->id)) {
            $offer = ZenfooOffer::find($request->id);

            if ($offer) {
                // Delete image using URL
                if ($offer->img_url) {
                    MediaUploadService::deleteFileByUrl($offer->img_url);
                }
                $offer->delete();
                return CommonHelper::responseSuccess("Offer deleted successfully!");
            } else {
                return CommonHelper::responseError("Offer not found!");
            }
        }

        return CommonHelper::responseError("Invalid request!");
    }
}