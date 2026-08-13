<?php

namespace App\Http\Controllers;

use App\Models\Seller;
use App\Models\SellerBankAccount;
use App\Helpers\CommonHelper;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class SellerBankAccountController extends Controller
{
    /**
     * Get all bank accounts for authenticated seller
     */
    public function index()
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = Seller::where('admin_id', $admin->id)->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        $bankAccounts = $seller->bankAccounts()
            ->orderBy('is_default', 'desc')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 1,
            'message' => 'Bank accounts fetched successfully',
            'data' => $bankAccounts
        ]);
    }

    /**
     * Add a new bank account
     */
    public function store(Request $request)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = Seller::where('admin_id', $admin->id)->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        $validator = Validator::make($request->all(), [
            'bank_name' => 'required|string|max:255',
            'account_number' => 'required|string|max:255',
            'ifsc_code' => 'required|string|max:11',
            'account_holder_name' => 'required|string|max:255',
            'document' => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:5120',
            'document_type' => 'nullable|in:passbook,statement,cheque',
            'is_default' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        DB::beginTransaction();

        try {
            $documentPath = null;
            if ($request->hasFile('document')) {
                $documentPath = MediaUploadService::uploadMessageAttachment(
                    $request->file('document'),
                    'seller_bank_documents'
                );
            }

            $bankAccount = new SellerBankAccount();
            $bankAccount->seller_id = $seller->id;
            $bankAccount->bank_name = $request->bank_name;
            $bankAccount->account_number = $request->account_number;
            $bankAccount->ifsc_code = strtoupper($request->ifsc_code);
            $bankAccount->account_holder_name = $request->account_holder_name;
            $bankAccount->document = $documentPath;
            $bankAccount->document_type = $request->document_type;
            $bankAccount->is_default = $request->is_default ?? false;
            $bankAccount->save();

            // If this is set as default, update other accounts
            if ($bankAccount->is_default) {
                $bankAccount->setAsDefault();
            }

            // If this is the first account, set it as default
            $accountCount = $seller->bankAccounts()->count();
            if ($accountCount == 1) {
                $bankAccount->is_default = true;
                $bankAccount->save();
            }

            DB::commit();

            return response()->json([
                'status' => 1,
                'message' => 'Bank account added successfully',
                'data' => $bankAccount
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Update bank account
     */
    public function update(Request $request, $id)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = Seller::where('admin_id', $admin->id)->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        $bankAccount = SellerBankAccount::where('id', $id)
            ->where('seller_id', $seller->id)
            ->first();

        if (!$bankAccount) {
            return CommonHelper::responseError("Bank account not found.");
        }

        $validator = Validator::make($request->all(), [
            'bank_name' => 'nullable|string|max:255',
            'account_number' => 'nullable|string|max:255',
            'ifsc_code' => 'nullable|string|max:11',
            'account_holder_name' => 'nullable|string|max:255',
            'document' => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:5120',
            'document_type' => 'nullable|in:passbook,statement,cheque',
            'is_default' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        DB::beginTransaction();

        try {
            if ($request->filled('bank_name')) {
                $bankAccount->bank_name = $request->bank_name;
            }

            if ($request->filled('account_number')) {
                $bankAccount->account_number = $request->account_number;
            }

            if ($request->filled('ifsc_code')) {
                $bankAccount->ifsc_code = strtoupper($request->ifsc_code);
            }

            if ($request->filled('account_holder_name')) {
                $bankAccount->account_holder_name = $request->account_holder_name;
            }

            if ($request->hasFile('document')) {
                $documentUrl = MediaUploadService::uploadMessageAttachment(
                    $request->file('document'),
                    'seller_bank_documents',
                    's3',
                    $bankAccount->document
                );
                $bankAccount->document = $documentUrl;
            }

            if ($request->filled('document_type')) {
                $bankAccount->document_type = $request->document_type;
            }

            if ($request->has('is_default')) {
                $bankAccount->is_default = $request->is_default;
            }

            $bankAccount->save();

            // If this is set as default, update other accounts
            if ($bankAccount->is_default) {
                $bankAccount->setAsDefault();
            }

            DB::commit();

            return response()->json([
                'status' => 1,
                'message' => 'Bank account updated successfully',
                'data' => $bankAccount
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Delete bank account
     */
    public function destroy($id)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = Seller::where('admin_id', $admin->id)->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        $bankAccount = SellerBankAccount::where('id', $id)
            ->where('seller_id', $seller->id)
            ->first();

        if (!$bankAccount) {
            return CommonHelper::responseError("Bank account not found.");
        }

        DB::beginTransaction();

        try {
            $wasDefault = $bankAccount->is_default;

            // Delete document from S3 if exists
            if ($bankAccount->document) {
                MediaUploadService::deleteByUrl($bankAccount->document);
            }

            $bankAccount->delete();

            // If deleted account was default, set another account as default
            if ($wasDefault) {
                $newDefault = $seller->bankAccounts()->first();
                if ($newDefault) {
                    $newDefault->is_default = true;
                    $newDefault->save();
                }
            }

            DB::commit();

            return response()->json([
                'status' => 1,
                'message' => 'Bank account deleted successfully'
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Set bank account as default
     */
    public function setDefault($id)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = Seller::where('admin_id', $admin->id)->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        $bankAccount = SellerBankAccount::where('id', $id)
            ->where('seller_id', $seller->id)
            ->first();

        if (!$bankAccount) {
            return CommonHelper::responseError("Bank account not found.");
        }

        DB::beginTransaction();

        try {
            $bankAccount->setAsDefault();

            DB::commit();

            return response()->json([
                'status' => 1,
                'message' => 'Bank account set as default successfully',
                'data' => $bankAccount
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return CommonHelper::responseError($e->getMessage());
        }
    }
}
