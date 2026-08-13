<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\CustomerNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class UserAccountDeletionController extends Controller
{
    /**
     * Admin soft-deletes a user account (sets deleted_at)
     */
    public function softDeleteUser(Request $request)
    {
        try {
            $request->validate([
                'user_id' => 'required|integer|exists:users,id',
            ]);

            $user = User::withTrashed()->find($request->user_id);

            if (!$user) {
                return CommonHelper::responseError('User not found');
            }

            if ($user->deleted_at) {
                return CommonHelper::responseError('User account is already deleted');
            }

            $user->delete(); // Soft delete

            // Notify user about account deletion
            CustomerNotificationService::notifyUserAccountDeleted($user->id);

            return CommonHelper::responseSuccess('User account has been deleted successfully');
        } catch (\Exception $e) {
            Log::error('UserAccountDeletion::softDelete: ' . $e->getMessage());
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Admin restores a soft-deleted user account (clears deleted_at, delete_reason, delete_requested_at)
     */
    public function restoreUser(Request $request)
    {
        try {
            $request->validate([
                'user_id' => 'required|integer|exists:users,id',
            ]);

            $user = User::withTrashed()->find($request->user_id);

            if (!$user) {
                return CommonHelper::responseError('User not found');
            }

            if (!$user->deleted_at) {
                return CommonHelper::responseError('User account is not deleted');
            }

            $user->delete_reason = null;
            $user->delete_requested_at = null;
            $user->restore(); // Restore soft delete

            // Notify user about account restoration
            CustomerNotificationService::notifyUserAccountRestored($user->id);

            return CommonHelper::responseSuccess('User account has been restored successfully');
        } catch (\Exception $e) {
            Log::error('UserAccountDeletion::restore: ' . $e->getMessage());
            return CommonHelper::responseError($e->getMessage());
        }
    }
}