<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Seller;
use App\Models\Setting;
use Illuminate\Http\Request;
use Mpdf\Mpdf;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class SellerAgreementController extends Controller
{
    /**
     * Generate and download seller agreement PDF
     *
     * @param Request $request
     * @return \Illuminate\Http\Response
     */
    public function downloadAgreement(Request $request)
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

            // Fetch seller details with relationships
            $seller = Seller::with(['city', 'bankAccounts'])->find($sellerData->id);

            // Get platform settings (key-value pair structure)
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

            // Get primary bank account (first one if multiple exist)
            $bankAccount = $seller->bankAccounts->first();

            $zenfoStampDataUri = $this->encodeImageSettingAsDataUri($settingsData['agreement_zenfo_stamp'] ?? null);
            [$vendorGstCategory, $vendorGstPercent] = $this->resolveVendorGstForSeller($seller);
            [$vendorCommissionCategory, $vendorCommissionPercent] = $this->resolveVendorCommissionForSeller($seller);

            // Prepare data for the agreement
            $data = [
                'seller' => $seller,
                'bank_account' => $bankAccount,
                'platform_name' => $platformName,
                'platform_email' => $platformEmail,
                'platform_phone' => $platformPhone,
                'agreement_date' => now()->format('d-m-Y'),
                'agreement_number' => 'AGR-' . str_pad($seller->id, 6, '0', STR_PAD_LEFT),
                'zenfo_stamp_data' => $zenfoStampDataUri,
                'vendor_gst_category' => $vendorGstCategory,
                'vendor_gst_percent' => $vendorGstPercent,
                'vendor_commission_category' => $vendorCommissionCategory,
                'vendor_commission_percent' => $vendorCommissionPercent,
            ];

            // Generate HTML from view
            $html = view('pdf.seller_agreement', $data)->render();

            // Initialize mPDF
            $mpdf = new Mpdf([
                'mode' => 'utf-8',
                'format' => 'A4',
                'margin_left' => 15,
                'margin_right' => 15,
                'margin_top' => 20,
                'margin_bottom' => 20,
                'margin_header' => 10,
                'margin_footer' => 10
            ]);

            // Set document properties
            $mpdf->SetTitle('Seller Agreement - ' . $seller->store_name);
            $mpdf->SetAuthor($platformName);
            $mpdf->SetHTMLFooter(
                '<div style="text-align:center; font-size:9px; color:#7f8c8d; border-top:1px solid #ecf0f1; padding-top:4px;">'
                . 'Agreement No: ' . ($data['agreement_number'] ?? '') . ' &nbsp;|&nbsp; '
                . htmlspecialchars($platformName, ENT_QUOTES, 'UTF-8') . ' &nbsp;|&nbsp; '
                . 'Page {PAGENO} of {nbpg}'
                . '</div>'
            );

            // Write HTML to PDF
            $mpdf->WriteHTML($html);

            // Generate filename
            $filename = 'Seller_Agreement_' . $seller->id . '_' . date('Y-m-d') . '.pdf';

            // Output PDF as download
            return response($mpdf->Output($filename, 'S'), 200)
                ->header('Content-Type', 'application/pdf')
                ->header('Content-Disposition', 'attachment; filename="' . $filename . '"');

        } catch (\Exception $e) {
            Log::error('Seller Agreement PDF Generation Error: ' . $e->getMessage(), [
                'admin_id' => auth()->guard('api')->id() ?? null,
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to generate agreement PDF',
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
     * Shared resolver: $map keys are store category flag columns;
     * values are [settingsVariable, humanLabel].
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
}