<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Seller;
use App\Services\SellerNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class SellerAccountDeletionController extends Controller
{
    /**
     * Admin soft-deletes a seller account (sets deleted_at)
     */
    public function softDeleteSeller(Request $request)
    {
        try {
            $request->validate([
                'seller_id' => 'required|integer|exists:sellers,id',
            ]);

            $seller = Seller::find($request->seller_id);

            if (!$seller) {
                return CommonHelper::responseError('Seller not found');
            }

            if ($seller->deleted_at) {
                return CommonHelper::responseError('Seller account is already deleted');
            }

            $seller->deleted_at = now();
            $seller->status = Seller::$statusRemoved;
            $seller->save();

            // Notify seller about account deletion
            SellerNotificationService::notifySellerAccountDeleted($seller->id);

            return CommonHelper::responseSuccess('Seller account has been deleted successfully');
        } catch (\Exception $e) {
            Log::error('SellerAccountDeletion::softDelete: ' . $e->getMessage());
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Admin restores a soft-deleted seller account (clears deleted_at, delete_reason, delete_requested_at)
     */
    public function restoreSeller(Request $request)
    {
        try {
            $request->validate([
                'seller_id' => 'required|integer|exists:sellers,id',
            ]);

            $seller = Seller::find($request->seller_id);

            if (!$seller) {
                return CommonHelper::responseError('Seller not found');
            }

            if (!$seller->deleted_at) {
                return CommonHelper::responseError('Seller account is not deleted');
            }

            $seller->deleted_at = null;
            $seller->delete_reason = null;
            $seller->delete_requested_at = null;
            $seller->status = Seller::$statusActive;
            $seller->save();

            // Notify seller about account restoration
            SellerNotificationService::notifySellerAccountRestored($seller->id);

            return CommonHelper::responseSuccess('Seller account has been restored successfully');
        } catch (\Exception $e) {
            Log::error('SellerAccountDeletion::restore: ' . $e->getMessage());
            return CommonHelper::responseError($e->getMessage());
        }
    }
}
