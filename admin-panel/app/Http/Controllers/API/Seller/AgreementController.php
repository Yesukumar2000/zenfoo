<?php

namespace App\Http\Controllers\API\Seller;

use App\Http\Controllers\Controller;
use App\Models\Seller;
use App\Models\Setting;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Mpdf\Mpdf;

class AgreementController extends Controller
{
    /**
     * Upload signed seller agreement PDF
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function uploadAgreement(Request $request)
    {
        try {
            // Get authenticated admin (seller login)
            $admin = auth()->guard('api')->user();

            if (!$admin) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid token or unauthorized access.'
                ], 401);
            }

            // Find seller by admin_id
            $sellerData = DB::table('sellers')->where('admin_id', $admin->id)->first();

            if (!$sellerData) {
                return response()->json([
                    'success' => false,
                    'message' => 'Seller not found'
                ], 404);
            }

            // Get seller model instance
            $seller = Seller::find($sellerData->id);

            // Validate request - either a pre-rendered PDF or a signature image
            // (or both). At least one must be present.
            $request->validate([
                'agreement_pdf' => 'nullable|file|mimes:pdf|max:10240', // Max 10MB
                'agreement_signature' => 'nullable|file|mimes:png,jpg,jpeg|max:2048'
            ]);

            if (!$request->hasFile('agreement_pdf') && !$request->hasFile('agreement_signature')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Either an agreement PDF or a signature image must be provided.'
                ], 422);
            }

            // Verify the agreement_signature column exists; if the migration
            // hasn't run yet, fail with a clear message instead of a 500
            // from the underlying SQL error.
            $hasSignatureColumn = Schema::hasColumn('sellers', 'agreement_signature');

            // Get old files for deletion
            $oldFile = $seller->agreement_pdf;
            $oldSignature = $hasSignatureColumn ? $seller->agreement_signature : null;

            // Upload signature image first (if provided) so we can embed it in the PDF
            $signatureUrl = $oldSignature;
            $signatureFile = $request->file('agreement_signature');
            if ($signatureFile) {
                $signatureUrl = MediaUploadService::uploadMessageAttachment(
                    $signatureFile,
                    'seller_agreements',
                    'public',
                    $oldSignature
                );
            }

            // Determine the PDF source: when a signature is provided we always
            // re-render the official agreement template with the signature
            // embedded in the seller's signature box. PDF rendering is
            // wrapped so that a failure there (e.g. mPDF / storage) doesn't
            // discard the signature upload itself.
            $pdfUrl = $seller->agreement_pdf;
            $pdfWarning = null;
            if ($signatureFile) {
                try {
                    $pdfUrl = $this->renderSignedAgreementPdf($seller, $signatureFile, $oldFile);
                } catch (\Throwable $renderErr) {
                    Log::error('Signed agreement PDF render failed: ' . $renderErr->getMessage(), [
                        'seller_id' => $seller->id,
                        'trace' => $renderErr->getTraceAsString(),
                    ]);
                    $pdfWarning = 'Signature captured but the signed PDF could not be regenerated. Admin will be notified.';
                }
            } elseif ($request->hasFile('agreement_pdf')) {
                // Legacy path: client supplied a pre-rendered PDF directly.
                $pdfUrl = MediaUploadService::uploadMessageAttachment(
                    $request->file('agreement_pdf'),
                    'seller_agreements',
                    'public',
                    $oldFile
                );
            }

            // Update seller record
            $seller->agreement_pdf = $pdfUrl;
            if ($hasSignatureColumn) {
                $seller->agreement_signature = $signatureUrl;
            }
            $seller->agreement_status = 0; // Reset to pending when new file is uploaded
            $seller->save();

            if (!$hasSignatureColumn) {
                Log::warning('agreement_signature column missing on sellers table - run pending migration', [
                    'seller_id' => $seller->id,
                ]);
            }

            return response()->json([
                'success' => true,
                'message' => $pdfWarning ?? 'Agreement uploaded successfully. Awaiting admin verification.',
                'data' => [
                    'agreement_pdf_url' => $seller->agreement_pdf_url,
                    'agreement_signature_url' => $hasSignatureColumn ? $seller->agreement_signature_url : null,
                    'agreement_status' => $seller->agreement_status,
                    'agreement_status_text' => $this->getStatusText($seller->agreement_status)
                ]
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            Log::error('Seller Agreement Upload Error: ' . $e->getMessage(), [
                'admin_id' => auth()->guard('api')->id() ?? null,
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to upload agreement',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Download seller's uploaded agreement PDF
     *
     * @param Request $request
     * @return \Illuminate\Http\Response
     */
    public function downloadUploadedAgreement(Request $request)
    {
        try {
            // Get authenticated admin (seller login)
            $admin = auth()->guard('api')->user();

            if (!$admin) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid token or unauthorized access.'
                ], 401);
            }

            // Find seller by admin_id
            $sellerData = DB::table('sellers')->where('admin_id', $admin->id)->first();

            if (!$sellerData) {
                return response()->json([
                    'success' => false,
                    'message' => 'Seller not found'
                ], 404);
            }

            // Get seller model instance
            $seller = Seller::find($sellerData->id);

            // Check if seller has uploaded agreement
            if (!$seller->agreement_pdf) {
                return response()->json([
                    'success' => false,
                    'message' => 'No agreement found. Please upload your signed agreement first.'
                ], 404);
            }

            // Extract file path from URL
            $url = $seller->agreement_pdf;
            $baseUrl = Storage::disk('public')->url('');
            $path = str_replace($baseUrl, '', $url);
            $path = ltrim($path, '/');

            // Check if file exists
            if (!Storage::disk('public')->exists($path)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Agreement file not found on server'
                ], 404);
            }

            // Generate filename
            $filename = 'Seller_Agreement_' . $seller->id . '_Uploaded.pdf';

            // Return file download
            return Storage::disk('public')->download($path, $filename);

        } catch (\Exception $e) {
            Log::error('Seller Agreement Download Error: ' . $e->getMessage(), [
                'admin_id' => auth()->guard('api')->id() ?? null,
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to download agreement',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get seller agreement status
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getAgreementStatus(Request $request)
    {
        try {
            // Get authenticated admin (seller login)
            $admin = auth()->guard('api')->user();

            if (!$admin) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid token or unauthorized access.'
                ], 401);
            }

            // Find seller by admin_id
            $sellerData = DB::table('sellers')->where('admin_id', $admin->id)->first();

            if (!$sellerData) {
                return response()->json([
                    'success' => false,
                    'message' => 'Seller not found'
                ], 404);
            }

            // Get seller model instance
            $seller = Seller::find($sellerData->id);

            return response()->json([
                'success' => true,
                'data' => [
                    'has_agreement' => !empty($seller->agreement_pdf),
                    'agreement_pdf_url' => $seller->agreement_pdf_url,
                    'agreement_status' => $seller->agreement_status,
                    'agreement_status_text' => $this->getStatusText($seller->agreement_status)
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Get Agreement Status Error: ' . $e->getMessage(), [
                'admin_id' => auth()->guard('api')->id() ?? null,
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to get agreement status',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Resolve the seller's vendor GST category label and percent from
     * the store's category flags + admin Vendor GST Configurations.
     */
    private function resolveVendorGstForSeller($seller): array
    {
        return $this->resolveVendorCategoryForSeller($seller, [
            'is_meat'       => ['vendor_gst_chicken_meat',       'Chicken & Meat'],
            'is_food'       => ['vendor_gst_food',               'Food'],
            'is_super_mart' => ['vendor_gst_super_mart',         'Super Mart'],
            'is_vegetable'  => ['vendor_gst_vegetables_fruits',  'Vegetables & Fruits'],
        ]);
    }

    /**
     * Resolve the seller's vendor commission category label and percent
     * from the store's category flags + admin Vendor Commission
     * Configurations.
     */
    private function resolveVendorCommissionForSeller($seller): array
    {
        return $this->resolveVendorCategoryForSeller($seller, [
            'is_meat'       => ['vendor_commission_chicken_meat',       'Chicken & Meat'],
            'is_food'       => ['vendor_commission_food',               'Food'],
            'is_super_mart' => ['vendor_commission_super_mart',         'Super Mart'],
            'is_vegetable'  => ['vendor_commission_vegetables_fruits',  'Vegetables & Fruits'],
        ]);
    }

    /**
     * Shared category resolver used by both GST and commission
     * variants. $map keys are store category flag column names; values
     * are [settingsVariable, humanLabel].
     *
     * @return array{0: ?string, 1: ?float}  [category label, percent]
     */
    private function resolveVendorCategoryForSeller($seller, array $map): array
    {
        if (!$seller || !$seller->store_id) {
            return [null, null];
        }

        $store = \App\Models\Store::find($seller->store_id);
        if (!$store) {
            return [null, null];
        }

        $variable = null;
        $label = null;
        foreach ($map as $flag => [$settingKey, $humanLabel]) {
            if (!empty($store->{$flag})) {
                $variable = $settingKey;
                $label = $humanLabel;
                break;
            }
        }

        if (!$variable) {
            return [null, null];
        }

        $value = DB::table('settings')->where('variable', $variable)->value('value');
        if ($value === null || $value === '') {
            return [$label, null];
        }

        return [$label, (float) $value];
    }

    /**
     * Resolve a setting value that may hold either a storage-relative
     * path (e.g. "settings/zenfo_stamp.png") or a full URL into a
     * base64 data URI suitable for embedding in mPDF output. Returns
     * null when the setting is empty or the file cannot be read.
     */
    private function encodeImageSettingAsDataUri(?string $setting): ?string
    {
        if (empty($setting)) {
            return null;
        }

        $bytes = null;
        $mime = null;

        if (str_starts_with($setting, 'http://') || str_starts_with($setting, 'https://')) {
            $baseUrl = rtrim(Storage::disk('public')->url(''), '/');
            $relative = ltrim(str_replace($baseUrl, '', $setting), '/');
            if ($relative !== '' && Storage::disk('public')->exists($relative)) {
                $bytes = Storage::disk('public')->get($relative);
                $mime = Storage::disk('public')->mimeType($relative);
            } else {
                try {
                    $bytes = @file_get_contents($setting);
                } catch (\Throwable $e) {
                    $bytes = null;
                }
            }
        } else {
            $relative = ltrim($setting, '/');
            if (Storage::disk('public')->exists($relative)) {
                $bytes = Storage::disk('public')->get($relative);
                $mime = Storage::disk('public')->mimeType($relative);
            }
        }

        if (empty($bytes)) {
            return null;
        }

        if (empty($mime)) {
            $info = @getimagesizefromstring($bytes);
            $mime = $info['mime'] ?? 'image/png';
        }

        return 'data:' . $mime . ';base64,' . base64_encode($bytes);
    }

    /**
     * Get status text from status code
     *
     * @param int|null $status
     * @return string
     */
    private function getStatusText($status)
    {
        switch ($status) {
            case 0:
                return 'Pending Verification';
            case 1:
                return 'Approved';
            case 2:
                return 'Rejected';
            default:
                return 'Not Uploaded';
        }
    }

    /**
     * Render the official seller agreement template with the seller's
     * signature image embedded in the seller signature box, save it to
     * storage, and return the public URL.
     *
     * Uses the same blade template (pdf.seller_agreement) used by
     * SellerAgreementController::downloadAgreement so the blank-download
     * and signed-document layouts stay in sync.
     */
    private function renderSignedAgreementPdf(Seller $seller, UploadedFile $signatureFile, ?string $oldPdfPath = null): ?string
    {
        // Reload seller with relationships needed by the template
        $seller = Seller::with(['city', 'bankAccounts'])->find($seller->id);

        $settingsData = Setting::whereIn('variable', [
                'app_name',
                'support_email',
                'support_number',
                'agreement_zenfo_stamp',
            ])
            ->get()
            ->pluck('value', 'variable');

        $platformName = $settingsData['app_name'] ?? 'Zenfoo';
        $platformEmail = Setting::support_value('support_email', 'seller');
        $platformPhone = Setting::support_value('support_number', 'seller');
        $bankAccount = $seller->bankAccounts->first();

        // Encode the signature image as a data URI so mPDF can embed it
        // without needing to resolve a storage URL during rendering
        $signatureBytes = file_get_contents($signatureFile->getRealPath());
        $signatureMime = $signatureFile->getMimeType() ?: 'image/png';
        $signatureDataUri = 'data:' . $signatureMime . ';base64,' . base64_encode($signatureBytes);

        $zenfoStampDataUri = $this->encodeImageSettingAsDataUri($settingsData['agreement_zenfo_stamp'] ?? null);
        [$vendorGstCategory, $vendorGstPercent] = $this->resolveVendorGstForSeller($seller);
        [$vendorCommissionCategory, $vendorCommissionPercent] = $this->resolveVendorCommissionForSeller($seller);

        $data = [
            'seller' => $seller,
            'bank_account' => $bankAccount,
            'platform_name' => $platformName,
            'platform_email' => $platformEmail,
            'platform_phone' => $platformPhone,
            'agreement_date' => now()->format('d-m-Y'),
            'agreement_number' => 'AGR-' . str_pad($seller->id, 6, '0', STR_PAD_LEFT),
            'signature_image_data' => $signatureDataUri,
            'zenfo_stamp_data' => $zenfoStampDataUri,
            'vendor_gst_category' => $vendorGstCategory,
            'vendor_gst_percent' => $vendorGstPercent,
            'vendor_commission_category' => $vendorCommissionCategory,
            'vendor_commission_percent' => $vendorCommissionPercent,
        ];

        $html = view('pdf.seller_agreement', $data)->render();

        $mpdf = new Mpdf([
            'mode' => 'utf-8',
            'format' => 'A4',
            'margin_left' => 15,
            'margin_right' => 15,
            'margin_top' => 20,
            'margin_bottom' => 20,
            'margin_header' => 10,
            'margin_footer' => 10,
        ]);
        $mpdf->SetTitle('Seller Agreement - ' . ($seller->store_name ?? $seller->id));
        $mpdf->SetAuthor($platformName);
        $mpdf->SetHTMLFooter(
            '<div style="text-align:center; font-size:9px; color:#7f8c8d; border-top:1px solid #ecf0f1; padding-top:4px;">'
            . 'Agreement No: ' . ($data['agreement_number'] ?? '') . ' &nbsp;|&nbsp; '
            . htmlspecialchars($platformName, ENT_QUOTES, 'UTF-8') . ' &nbsp;|&nbsp; '
            . 'Page {PAGENO} of {nbpg}'
            . '</div>'
        );
        $mpdf->WriteHTML($html);

        $pdfBytes = $mpdf->Output('', 'S');

        // Delete the previous PDF file if it exists locally
        if (!empty($oldPdfPath)) {
            $relativeOld = str_replace(Storage::disk('public')->url(''), '', $oldPdfPath);
            $relativeOld = ltrim($relativeOld, '/');
            if (Storage::disk('public')->exists($relativeOld)) {
                Storage::disk('public')->delete($relativeOld);
            }
        }

        $filename = 'seller_agreements/signed_agreement_' . $seller->id . '_' . time() . '.pdf';
        Storage::disk('public')->put($filename, $pdfBytes);

        return Storage::disk('public')->url($filename);
    }
}