<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Seller\BulkProductUploadController as SellerBulkUpload;
use App\Models\Seller;
use App\Helpers\CommonHelper;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class AdminBulkProductUploadController extends SellerBulkUpload
{
    /**
     * GET /api/admin/bulk-upload-template?seller_id=X
     * Admin downloads an Excel template pre-filled with the selected seller's categories.
     */
    public function downloadTemplate(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'seller_id' => 'required|integer|exists:sellers,id',
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $seller = Seller::find($request->seller_id);

        return $this->buildTemplate($seller);
    }

    /**
     * POST /api/admin/bulk-upload-products
     * Admin uploads a filled Excel sheet on behalf of a seller.
     * Requires: seller_id (form field) + file (xlsx)
     */
    public function upload(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'seller_id' => 'required|integer|exists:sellers,id',
            'file'      => 'required|file|mimes:xlsx,xls',
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $seller = Seller::find($request->seller_id);

        return $this->processUpload($request, $seller);
    }

    /**
     * GET /api/admin/sellers-list
     * Lightweight list of all active sellers for the admin dropdown.
     */
    public function sellersList()
    {
        $sellers = Seller::where('status', 1)
            ->select('id', 'name', 'store_id', 'categories')
            ->orderBy('name')
            ->get()
            ->makeHidden(['logo_url', 'national_identity_card_url', 'address_proof_url', 'categories_array']);

        return response()->json(['status' => 1, 'data' => $sellers]);
    }
}
