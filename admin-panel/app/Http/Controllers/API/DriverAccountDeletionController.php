<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\DeliveryBoy;
use App\Services\DriverNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class DriverAccountDeletionController extends Controller
{
    /**
     * Admin soft-deletes a driver account (sets deleted_at)
     */
    public function softDeleteDriver(Request $request)
    {
        try {
            $request->validate([
                'delivery_boy_id' => 'required|integer|exists:delivery_boys,id',
            ]);

            $driver = DeliveryBoy::find($request->delivery_boy_id);

            if (!$driver) {
                return CommonHelper::responseError('Driver not found');
            }

            if ($driver->deleted_at) {
                return CommonHelper::responseError('Driver account is already deleted');
            }

            $driver->deleted_at = now();
            $driver->status = DeliveryBoy::$statusRemoved;
            $driver->save();

            // Notify driver about account deletion
            DriverNotificationService::notifyDriverAccountDeleted($driver->id);

            return CommonHelper::responseSuccess('Driver account has been deleted successfully');
        } catch (\Exception $e) {
            Log::error('DriverAccountDeletion::softDelete: ' . $e->getMessage());
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Admin restores a soft-deleted driver account (clears deleted_at, delete_reason, delete_requested_at)
     */
    public function restoreDriver(Request $request)
    {
        try {
            $request->validate([
                'delivery_boy_id' => 'required|integer|exists:delivery_boys,id',
            ]);

            $driver = DeliveryBoy::find($request->delivery_boy_id);

            if (!$driver) {
                return CommonHelper::responseError('Driver not found');
            }

            if (!$driver->deleted_at) {
                return CommonHelper::responseError('Driver account is not deleted');
            }

            $driver->deleted_at = null;
            $driver->delete_reason = null;
            $driver->delete_requested_at = null;
            $driver->status = DeliveryBoy::$statusActive;
            $driver->save();

            // Notify driver about account restoration
            DriverNotificationService::notifyDriverAccountRestored($driver->id);

            return CommonHelper::responseSuccess('Driver account has been restored successfully');
        } catch (\Exception $e) {
            Log::error('DriverAccountDeletion::restore: ' . $e->getMessage());
            return CommonHelper::responseError($e->getMessage());
        }
    }
}
