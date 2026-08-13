<?php

namespace App\Http\Controllers\API\Seller;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\CategoryType;
use App\Models\OrderStatusList;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\Seller;
// use App\Models\Tag; // Tags removed
use App\Models\Unit;
use App\Helpers\CommonHelper;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx as XlsxWriter;
use PhpOffice\PhpSpreadsheet\Cell\DataValidation;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\IOFactory;

class BulkProductUploadController extends Controller
{
    // ─────────────────────────────────────────────────────────────────
    // Column layout (0-based index in the Excel row array)
    //
    //  A(0)  Product Name        M(12) Total Allowed Qty
    //  B(1)  Description         N(13) Is Cancelable
    //  C(2)  Category            O(14) Till Status
    //  D(3)  Food Type           P(15) Is Returnable
    //  E(4)  Type                Q(16) Return Days
    //  F(5)  Unlimited Stock     R(17) Indicator
    //  G(6)  Measurement         S(18) [hidden] _category_id
    //  H(7)  Price               T(19) [hidden] _food_type_id
    //  I(8)  Discounted Price    U(20) [hidden] _unit_id
    //  J(9)  Stock
    //  K(10) Unit
    //  L(11) Status
    //
    //  Row 1 = headers
    //  Row 2+ = data
    // ─────────────────────────────────────────────────────────────────

    public function downloadTemplate(Request $request)
    {
        $admin = auth()->guard('api')->user();
        if (!$admin) {
            return CommonHelper::responseError("Unauthorized.");
        }

        $seller = Seller::where('admin_id', $admin->id)->first();
        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        return $this->buildTemplate($seller);
    }

    public function upload(Request $request)
    {
        $admin = auth()->guard('api')->user();
        if (!$admin) {
            return CommonHelper::responseError("Unauthorized.");
        }

        $seller = Seller::where('admin_id', $admin->id)->first();
        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        return $this->processUpload($request, $seller);
    }

    // ─────────────────────────────────────────────────────────────────
    // Shared helpers
    // ─────────────────────────────────────────────────────────────────

    protected function buildTemplate(Seller $seller)
    {
        // Categories
        $categories = Category::where('seller_id', $seller->id)->orderBy('name')->get();

        Log::info('[BulkUpload] buildTemplate', [
            'seller_id'          => $seller->id,
            'seller_name'        => $seller->name,
            'seller_categories'  => $seller->categories,
            'categories_by_seller_id' => $categories->pluck('name', 'id'),
        ]);

        if ($categories->isEmpty()) {
            $categoryIds = array_filter(array_map('trim', explode(',', $seller->categories ?? '')));
            Log::info('[BulkUpload] Fallback category IDs from seller.categories field', [
                'seller_id'    => $seller->id,
                'category_ids' => $categoryIds,
            ]);
            if (!empty($categoryIds)) {
                $categories = Category::whereIn('id', $categoryIds)->orderBy('name')->get();
                Log::info('[BulkUpload] Fallback categories found', [
                    'categories' => $categories->pluck('name', 'id'),
                ]);
            }
        }

        if ($categories->isEmpty()) {
            Log::warning('[BulkUpload] No categories found for seller', [
                'seller_id'         => $seller->id,
                'seller_name'       => $seller->name,
                'seller_categories' => $seller->categories,
            ]);
            return CommonHelper::responseError(
                "Seller has no categories assigned. Please create categories for this seller first."
            );
        }

        $resolvedCatIds = $categories->pluck('id')->toArray();
        $catMap         = $categories->keyBy('id'); // id => Category

        // Food types — display as "FoodTypeName - CategoryName"
        $foodTypes = CategoryType::whereIn('category_id', $resolvedCatIds)
                        ->orderBy('category_id')->orderBy('name')->get();

        $units = Unit::orderBy('name')->get();

        // Order statuses for till_status dropdown (only cancelable-relevant ones)
        $tillStatuses = OrderStatusList::whereIn('id', [2, 3])->orderBy('id')->get(); // Received, Processed

        $spreadsheet = new Spreadsheet();

        // ── Single sheet: Products ────────────────────────────────────
        // No separate Ref sheet — all reference data lives in hidden
        // columns on the same sheet so Excel dropdowns work reliably.
        $sheet = $spreadsheet->getActiveSheet()->setTitle('Products');

        // ── Headers (A–R visible) ──
        $headers = [
            'A' => 'Product Name *',
            'B' => 'Description *',
            'C' => 'Category *',
            'D' => 'Food Type *',
            'E' => 'Type * (packet/loose)',
            'F' => 'Is Unlimited Stock * (Yes/No)',
            'G' => 'Measurement *',
            'H' => 'Price (Rs.) *',
            'I' => 'Discounted Price (Rs.)',
            'J' => 'Stock *',
            'K' => 'Unit *',
            'L' => 'Status * (Active/Sold Out)',
            'M' => 'Total Allowed Qty',
            'N' => 'Is Cancelable * (Yes/No)',
            'O' => 'Till Status',
            'P' => 'Is Returnable * (Yes/No)',
            'Q' => 'Return Days',
            'R' => 'Indicator (Veg/Non-Veg)',
        ];

        foreach ($headers as $col => $label) {
            $sheet->setCellValue($col . '1', $label);
        }

        // Hidden ID-lookup columns (S, T, U)
        $sheet->setCellValue('S1', '_category_id');
        $sheet->setCellValue('T1', '_food_type_id');
        $sheet->setCellValue('U1', '_unit_id');

        // ── Hidden reference-data columns (W–AD) on the SAME sheet ──
        // W:X → Category Name | Category ID
        $sheet->setCellValue('W1', '_cat_name');
        $sheet->setCellValue('X1', '_cat_id');
        foreach ($categories as $i => $cat) {
            $r = $i + 2;
            $sheet->setCellValue('W' . $r, $cat->name);
            $sheet->setCellValue('X' . $r, $cat->id);
        }
        $catCount    = $categories->count();
        $lastCatRow  = $catCount + 1;

        // Y:Z → Food Type Display | Food Type ID
        $sheet->setCellValue('Y1', '_ft_name');
        $sheet->setCellValue('Z1', '_ft_id');
        foreach ($foodTypes as $i => $ft) {
            $r       = $i + 2;
            $catName = $catMap[$ft->category_id]->name ?? '';
            $display = $ft->name . ' - ' . $catName;
            $sheet->setCellValue('Y' . $r, $display);
            $sheet->setCellValue('Z' . $r, $ft->id);
        }
        $ftCount    = $foodTypes->count();
        $lastFtRow  = $ftCount + 1;

        // AA:AB → Unit Display | Unit ID
        $sheet->setCellValue('AA1', '_unit_name');
        $sheet->setCellValue('AB1', '_unit_id_ref');
        foreach ($units as $i => $unit) {
            $r = $i + 2;
            $sheet->setCellValue('AA' . $r, $unit->name . ' (' . $unit->short_code . ')');
            $sheet->setCellValue('AB' . $r, $unit->id);
        }
        $unitCount    = $units->count();
        $lastUnitRow  = $unitCount + 1;

        // AC:AD → Till Status Name | Till Status ID
        $sheet->setCellValue('AC1', '_till_name');
        $sheet->setCellValue('AD1', '_till_id');
        foreach ($tillStatuses as $i => $ts) {
            $r = $i + 2;
            $sheet->setCellValue('AC' . $r, $ts->status);
            $sheet->setCellValue('AD' . $r, $ts->id);
        }
        $tillCount    = $tillStatuses->count();
        $lastTillRow  = $tillCount + 1;

        // ── Header style ──
        $headerStyle = [
            'font' => ['bold' => true, 'color' => ['rgb' => 'FFFFFF']],
            'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => '444444']],
        ];
        $sheet->getStyle('A1:R1')->applyFromArray($headerStyle);

        // Column widths
        $widths = [
            'A' => 22, 'B' => 28, 'C' => 20, 'D' => 25,
            'E' => 18, 'F' => 24, 'G' => 16, 'H' => 14,
            'I' => 22, 'J' => 10, 'K' => 22, 'L' => 22,
            'M' => 18, 'N' => 22, 'O' => 28, 'P' => 22,
            'Q' => 14, 'R' => 20,
        ];
        foreach ($widths as $col => $w) {
            $sheet->getColumnDimension($col)->setWidth($w);
        }

        // Hide all helper columns (S–AD)
        foreach (['S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'AA', 'AB', 'AC', 'AD'] as $col) {
            $sheet->getColumnDimension($col)->setVisible(false)->setWidth(1);
        }

        // ── Data validation + VLOOKUP formulas (rows 2–301) ──
        for ($row = 2; $row <= 301; $row++) {
            // Category (col C) — same-sheet reference
            $v = $sheet->getCell('C' . $row)->getDataValidation();
            $v->setType(DataValidation::TYPE_LIST)->setErrorStyle(DataValidation::STYLE_INFORMATION)
              ->setAllowBlank(true)->setShowDropDown(true)->setShowInputMessage(true)->setShowErrorMessage(true)
              ->setFormula1('$W$2:$W$' . $lastCatRow);

            // Food Type (col D) — same-sheet reference
            $v = $sheet->getCell('D' . $row)->getDataValidation();
            $v->setType(DataValidation::TYPE_LIST)->setErrorStyle(DataValidation::STYLE_INFORMATION)
              ->setAllowBlank(true)->setShowDropDown(true)->setShowInputMessage(true)->setShowErrorMessage(true)
              ->setFormula1('$Y$2:$Y$' . $lastFtRow);

            // Type (col E)
            $v = $sheet->getCell('E' . $row)->getDataValidation();
            $v->setType(DataValidation::TYPE_LIST)->setErrorStyle(DataValidation::STYLE_INFORMATION)
              ->setAllowBlank(true)->setShowDropDown(true)->setShowInputMessage(true)->setShowErrorMessage(true)
              ->setFormula1('"packet,loose"');

            // Unlimited Stock (col F)
            $v = $sheet->getCell('F' . $row)->getDataValidation();
            $v->setType(DataValidation::TYPE_LIST)->setErrorStyle(DataValidation::STYLE_INFORMATION)
              ->setAllowBlank(true)->setShowDropDown(true)->setShowInputMessage(true)->setShowErrorMessage(true)
              ->setFormula1('"Yes,No"');

            // Unit (col K) — same-sheet reference
            $v = $sheet->getCell('K' . $row)->getDataValidation();
            $v->setType(DataValidation::TYPE_LIST)->setErrorStyle(DataValidation::STYLE_INFORMATION)
              ->setAllowBlank(true)->setShowDropDown(true)->setShowInputMessage(true)->setShowErrorMessage(true)
              ->setFormula1('$AA$2:$AA$' . $lastUnitRow);

            // Status (col L)
            $v = $sheet->getCell('L' . $row)->getDataValidation();
            $v->setType(DataValidation::TYPE_LIST)->setErrorStyle(DataValidation::STYLE_INFORMATION)
              ->setAllowBlank(true)->setShowDropDown(true)->setShowInputMessage(true)->setShowErrorMessage(true)
              ->setFormula1('"Active,Sold Out"');

            // Is Cancelable (col N)
            $v = $sheet->getCell('N' . $row)->getDataValidation();
            $v->setType(DataValidation::TYPE_LIST)->setErrorStyle(DataValidation::STYLE_INFORMATION)
              ->setAllowBlank(true)->setShowDropDown(true)->setShowInputMessage(true)->setShowErrorMessage(true)
              ->setFormula1('"Yes,No"');

            // Till Status (col O) — same-sheet reference
            $v = $sheet->getCell('O' . $row)->getDataValidation();
            $v->setType(DataValidation::TYPE_LIST)->setErrorStyle(DataValidation::STYLE_INFORMATION)
              ->setAllowBlank(true)->setShowDropDown(true)->setShowInputMessage(true)->setShowErrorMessage(true)
              ->setFormula1('$AC$2:$AC$' . $lastTillRow);

            // Is Returnable (col P)
            $v = $sheet->getCell('P' . $row)->getDataValidation();
            $v->setType(DataValidation::TYPE_LIST)->setErrorStyle(DataValidation::STYLE_INFORMATION)
              ->setAllowBlank(true)->setShowDropDown(true)->setShowInputMessage(true)->setShowErrorMessage(true)
              ->setFormula1('"Yes,No"');

            // Indicator (col R)
            $v = $sheet->getCell('R' . $row)->getDataValidation();
            $v->setType(DataValidation::TYPE_LIST)->setErrorStyle(DataValidation::STYLE_INFORMATION)
              ->setAllowBlank(true)->setShowDropDown(true)->setShowInputMessage(true)->setShowErrorMessage(true)
              ->setFormula1('"Veg,Non-Veg"');

            // Hidden: Category ID (S) — VLOOKUP against same-sheet cols W:X
            $sheet->setCellValue('S' . $row,
                '=IFERROR(VLOOKUP(C' . $row . ',$W:$X,2,0),"")');

            // Hidden: Food Type ID (T) — VLOOKUP against same-sheet cols Y:Z
            $sheet->setCellValue('T' . $row,
                '=IFERROR(VLOOKUP(D' . $row . ',$Y:$Z,2,0),0)');

            // Hidden: Unit ID (U) — VLOOKUP against same-sheet cols AA:AB
            $sheet->setCellValue('U' . $row,
                '=IFERROR(VLOOKUP(K' . $row . ',$AA:$AB,2,0),"")');
        }

        $sheet->freezePane('A2');

        // ── Instructions & Examples sheet ─────────────────────────────
        $instrSheet = $spreadsheet->createSheet()->setTitle('Instructions & Examples');

        // Title
        $instrSheet->setCellValue('A1', 'BULK PRODUCT UPLOAD — INSTRUCTIONS & EXAMPLES');
        $instrSheet->mergeCells('A1:F1');
        $instrSheet->getStyle('A1')->applyFromArray([
            'font' => ['bold' => true, 'size' => 16, 'color' => ['rgb' => 'FFFFFF']],
            'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => '2E7D32']],
        ]);
        $instrSheet->getRowDimension(1)->setRowHeight(30);

        // ── General Instructions ──
        $instrSheet->setCellValue('A3', 'GENERAL INSTRUCTIONS');
        $instrSheet->getStyle('A3')->applyFromArray([
            'font' => ['bold' => true, 'size' => 13, 'color' => ['rgb' => '1B5E20']],
        ]);

        $instructions = [
            ['1.', 'Fill product data ONLY in the "Products" sheet. This "Instructions & Examples" sheet is for reference only.'],
            ['2.', 'All fields are required, except Till Status (Col O) and Return Days (Col Q) — these depend on Is Cancelable and Is Returnable values.'],
            ['3.', 'Each row represents ONE product with ONE variant.'],
            ['4.', 'Use the dropdown menus wherever available — do NOT type values manually for Category, Food Type, Unit, Till Status, etc.'],
            ['5.', 'Do NOT modify, delete, or unhide any hidden columns (S onwards). They contain formulas for internal processing.'],
            ['6.', 'Do NOT rename or delete the "Products" sheet.'],
            ['7.', 'If any row has errors, the ENTIRE file will be rejected. Fix all errors and re-upload.'],
            ['8.', 'Discounted Price (Col I) must be LESS than Price (Col H).'],
            ['9.', 'When "Is Unlimited Stock" (Col F) is "Yes", set Stock (Col J) to 0.'],
            ['10.', 'When "Is Cancelable" (Col N) is "Yes", you MUST select a Till Status (Col O) — e.g. Received or Processed.'],
            ['11.', 'When "Is Returnable" (Col P) is "Yes", you MUST enter Return Days (Col Q) — e.g. 7.'],
        ];

        $instrRow = 4;
        foreach ($instructions as $instr) {
            $instrSheet->setCellValue('A' . $instrRow, $instr[0]);
            $instrSheet->setCellValue('B' . $instrRow, $instr[1]);
            $instrSheet->getStyle('A' . $instrRow)->getFont()->setBold(true);
            $instrRow++;
        }

        // ── Column-by-Column Explanation ──
        $instrRow += 1;
        $instrSheet->setCellValue('A' . $instrRow, 'COLUMN-BY-COLUMN EXPLANATION');
        $instrSheet->getStyle('A' . $instrRow)->applyFromArray([
            'font' => ['bold' => true, 'size' => 13, 'color' => ['rgb' => '1B5E20']],
        ]);
        $instrRow++;

        $columnExplanationHeaders = ['Column', 'Header', 'Required?', 'Description', 'Allowed Values', 'Example'];
        $colLetters = ['A', 'B', 'C', 'D', 'E', 'F'];
        foreach ($columnExplanationHeaders as $ci => $ch) {
            $instrSheet->setCellValue($colLetters[$ci] . $instrRow, $ch);
        }
        $instrSheet->getStyle('A' . $instrRow . ':F' . $instrRow)->applyFromArray([
            'font' => ['bold' => true, 'color' => ['rgb' => 'FFFFFF']],
            'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => '444444']],
        ]);
        $instrRow++;

        $columnExplanations = [
            ['A', 'Product Name', 'Yes', 'Name of the product.', 'Any text', 'Basmati Rice'],
            ['B', 'Description', 'Yes', 'Short description of the product.', 'Any text', 'Premium long-grain basmati rice, aged 2 years.'],
            ['C', 'Category', 'Yes', 'Select from dropdown. Must be a category assigned to your shop.', 'Dropdown list', 'Groceries'],
            ['D', 'Food Type', 'Yes', 'Select from dropdown. Must belong to the selected category.', 'Dropdown list (format: "TypeName - CategoryName")', 'Rice - Groceries'],
            ['E', 'Type', 'Yes', 'Product packaging type.', 'packet / loose', 'packet'],
            ['F', 'Is Unlimited Stock', 'Yes', 'Whether the product has unlimited stock.', 'Yes / No', 'No'],
            ['G', 'Measurement', 'Yes', 'Numeric value for the unit measurement.', 'Number > 0 (e.g. 1, 250, 0.5)', '1'],
            ['H', 'Price (Rs.)', 'Yes', 'Selling price in rupees.', 'Number > 0', '150'],
            ['I', 'Discounted Price (Rs.)', 'Yes', 'Discounted price. Must be less than Price.', 'Number < Price', '120'],
            ['J', 'Stock', 'Yes', 'Stock quantity. Set to 0 if unlimited stock is "Yes".', 'Number >= 0', '50'],
            ['K', 'Unit', 'Yes', 'Select from dropdown. The measurement unit for the product.', 'Dropdown list (e.g. "Kilogram (kg)")', 'Kilogram (kg)'],
            ['L', 'Status', 'Yes', 'Product availability status.', 'Active / Sold Out', 'Active'],
            ['M', 'Total Allowed Qty', 'Yes', 'Max quantity a customer can order.', 'Number', '10'],
            ['N', 'Is Cancelable', 'Yes', 'Whether the order can be canceled.', 'Yes / No', 'Yes'],
            ['O', 'Till Status', 'Required if Cancelable = Yes', 'The order stage until which cancellation is allowed. Leave empty if Is Cancelable is "No".', 'Dropdown: Received / Processed', 'Received'],
            ['P', 'Is Returnable', 'Yes', 'Whether the product can be returned.', 'Yes / No', 'No'],
            ['Q', 'Return Days', 'Required if Returnable = Yes', 'Number of days within which return is allowed. Leave empty if Is Returnable is "No".', 'Number > 0', '7'],
            ['R', 'Indicator', 'Yes', 'Veg or Non-Veg indicator.', 'Veg / Non-Veg', 'Veg'],
        ];

        foreach ($columnExplanations as $ce) {
            foreach ($ce as $ci => $cv) {
                $instrSheet->setCellValue($colLetters[$ci] . $instrRow, $cv);
            }
            $instrRow++;
        }

        // ── Sample Data ──
        $instrRow += 1;
        $instrSheet->setCellValue('A' . $instrRow, 'SAMPLE PRODUCT ROWS');
        $instrSheet->getStyle('A' . $instrRow)->applyFromArray([
            'font' => ['bold' => true, 'size' => 13, 'color' => ['rgb' => '1B5E20']],
        ]);
        $instrRow++;

        $instrSheet->setCellValue('A' . $instrRow, 'Below are example rows showing how to fill in the "Products" sheet. Do NOT copy these — they are only for reference.');
        $instrSheet->mergeCells('A' . $instrRow . ':F' . $instrRow);
        $instrSheet->getStyle('A' . $instrRow)->getFont()->setItalic(true);
        $instrRow += 2;

        // Sample headers (matching Products sheet)
        $sampleHeaders = [
            'A' => 'Product Name', 'B' => 'Description', 'C' => 'Category', 'D' => 'Food Type',
            'E' => 'Type', 'F' => 'Unlimited Stock', 'G' => 'Measurement', 'H' => 'Price',
            'I' => 'Disc. Price', 'J' => 'Stock', 'K' => 'Unit', 'L' => 'Status',
            'M' => 'Total Qty', 'N' => 'Cancelable', 'O' => 'Till Status', 'P' => 'Returnable',
            'Q' => 'Return Days', 'R' => 'Indicator',
        ];
        foreach ($sampleHeaders as $col => $label) {
            $instrSheet->setCellValue($col . $instrRow, $label);
        }
        $instrSheet->getStyle('A' . $instrRow . ':R' . $instrRow)->applyFromArray([
            'font' => ['bold' => true, 'color' => ['rgb' => 'FFFFFF']],
            'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => '1565C0']],
        ]);
        $instrRow++;

        // Sample row 1 — cancelable=Yes (so Till Status filled), returnable=No (so Return Days empty)
        $sample1 = [
            'A' => 'Basmati Rice Premium', 'B' => 'Long-grain aged basmati rice, 2 years aged',
            'C' => '(Your Category)', 'D' => '(Your Food Type - Category)',
            'E' => 'packet', 'F' => 'No', 'G' => '1', 'H' => '250',
            'I' => '199', 'J' => '100', 'K' => 'Kilogram (kg)', 'L' => 'Active',
            'M' => '5', 'N' => 'Yes', 'O' => 'Received', 'P' => 'No',
            'Q' => '', 'R' => 'Veg',
        ];
        foreach ($sample1 as $col => $val) {
            $instrSheet->setCellValue($col . $instrRow, $val);
        }
        $instrSheet->getStyle('A' . $instrRow . ':R' . $instrRow)->applyFromArray([
            'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => 'E8F5E9']],
        ]);
        $instrRow++;

        // Sample row 2 — cancelable=No (so Till Status empty), returnable=Yes (so Return Days filled)
        $sample2 = [
            'A' => 'Fresh Paneer', 'B' => 'Soft and fresh cottage cheese',
            'C' => '(Your Category)', 'D' => '(Your Food Type - Category)',
            'E' => 'packet', 'F' => 'Yes', 'G' => '200', 'H' => '80',
            'I' => '65', 'J' => '0', 'K' => 'Gram (gm)', 'L' => 'Active',
            'M' => '3', 'N' => 'No', 'O' => '', 'P' => 'Yes',
            'Q' => '7', 'R' => 'Veg',
        ];
        foreach ($sample2 as $col => $val) {
            $instrSheet->setCellValue($col . $instrRow, $val);
        }
        $instrSheet->getStyle('A' . $instrRow . ':R' . $instrRow)->applyFromArray([
            'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => 'FFF3E0']],
        ]);
        $instrRow++;

        // Sample row 3 — cancelable=Yes + returnable=No
        $sample3 = [
            'A' => 'Chicken Breast', 'B' => 'Boneless chicken breast, fresh cut',
            'C' => '(Your Category)', 'D' => '(Your Food Type - Category)',
            'E' => 'loose', 'F' => 'No', 'G' => '500', 'H' => '180',
            'I' => '160', 'J' => '30', 'K' => 'Gram (gm)', 'L' => 'Active',
            'M' => '2', 'N' => 'Yes', 'O' => 'Processed', 'P' => 'No',
            'Q' => '', 'R' => 'Non-Veg',
        ];
        foreach ($sample3 as $col => $val) {
            $instrSheet->setCellValue($col . $instrRow, $val);
        }
        $instrSheet->getStyle('A' . $instrRow . ':R' . $instrRow)->applyFromArray([
            'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => 'FFEBEE']],
        ]);

        // ── Notes section ──
        $instrRow += 2;
        $instrSheet->setCellValue('A' . $instrRow, 'IMPORTANT NOTES');
        $instrSheet->getStyle('A' . $instrRow)->applyFromArray([
            'font' => ['bold' => true, 'size' => 13, 'color' => ['rgb' => 'C62828']],
        ]);
        $instrRow++;

        $notes = [
            ['•', 'All columns are required, except Till Status (Col O) and Return Days (Col Q) — these depend on Is Cancelable and Is Returnable.'],
            ['•', 'Category and Food Type values in the sample above are placeholders. Use the dropdowns in the "Products" sheet — they are pre-filled with your shop\'s actual categories.'],
            ['•', 'If Stock is 0 and Status is "Active", the upload will be rejected. Either set Status to "Sold Out" or increase Stock.'],
            ['•', 'Discounted Price must be strictly LESS than Price. If they are equal or Discounted Price is higher, the upload will fail.'],
            ['•', 'You can leave rows blank — blank rows are automatically skipped.'],
            ['•', 'After uploading, products will be created with status based on your shop\'s approval settings.'],
        ];

        foreach ($notes as $note) {
            $instrSheet->setCellValue('A' . $instrRow, $note[0]);
            $instrSheet->setCellValue('B' . $instrRow, $note[1]);
            $instrSheet->getStyle('A' . $instrRow)->getFont()->setBold(true);
            $instrRow++;
        }

        // Column widths for Instructions sheet
        $instrSheet->getColumnDimension('A')->setWidth(16);
        $instrSheet->getColumnDimension('B')->setWidth(55);
        $instrSheet->getColumnDimension('C')->setWidth(22);
        $instrSheet->getColumnDimension('D')->setWidth(35);
        $instrSheet->getColumnDimension('E')->setWidth(25);
        $instrSheet->getColumnDimension('F')->setWidth(30);

        // Set "Products" as the active/default sheet when file opens
        $spreadsheet->setActiveSheetIndex(0);

        $writer   = new XlsxWriter($spreadsheet);
        $filename = 'bulk_product_upload_template.xlsx';

        return response()->stream(function () use ($writer) {
            $writer->save('php://output');
        }, 200, [
            'Content-Type'        => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'Content-Disposition' => 'attachment; filename="' . $filename . '"',
            'Cache-Control'       => 'max-age=0',
        ]);
    }

    protected function processUpload(Request $request, Seller $seller)
    {
        $validator = Validator::make($request->all(), [
            'file' => 'required|file|mimes:xlsx,xls',
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $storeId       = $seller->store_id;
        $sellerId      = $seller->id;
        $isAutoApprove = isset($seller->require_products_approval) && $seller->require_products_approval == 0 ? 1 : 0;

        // Build valid category IDs for this seller
        $sellerCats = Category::where('seller_id', $seller->id)->pluck('id')->toArray();
        if (empty($sellerCats)) {
            $catStr     = array_filter(array_map('trim', explode(',', $seller->categories ?? '')));
            $sellerCats = array_map('intval', $catStr);
        }
        if (empty($sellerCats)) {
            return CommonHelper::responseError(
                "Seller has no categories assigned. Please create categories for this seller first."
            );
        }

        try {
            $spreadsheet = IOFactory::load($request->file('file')->getRealPath());
            $sheet       = $spreadsheet->getSheetByName('Products');
            if (!$sheet) {
                return CommonHelper::responseError("Invalid file. Sheet 'Products' not found.");
            }
        } catch (\Exception $e) {
            return CommonHelper::responseError("Failed to read file: " . $e->getMessage());
        }

        // Skip header row (0) → data starts at index 1
        $rows     = $sheet->toArray(null, false, true, false);
        $dataRows = array_slice($rows, 1);

        if (empty($dataRows)) {
            return CommonHelper::responseError("No data rows found in the file.");
        }

        $errors    = [];
        $products  = [];
        $excelRow  = 2; // data starts at Excel row 2

        foreach ($dataRows as $row) {
            // Column mapping (0-based, Tags column removed):
            // A(0) Product Name   B(1) Description
            // C(2) Category       D(3) Food Type      E(4) Type
            // F(5) Unlimited      G(6) Measurement    H(7) Price
            // I(8) Disc Price     J(9) Stock           K(10) Unit
            // L(11) Status        M(12) Total Qty      N(13) Cancelable
            // O(14) Till Status   P(15) Returnable     Q(16) Return Days
            // R(17) Indicator
            $productName   = trim($row[0]  ?? '');
            $description   = trim($row[1]  ?? '');
            // $tags       = trim($row[2]  ?? ''); // Tags removed
            $categoryName  = trim($row[2]  ?? '');
            $foodTypeDisp  = trim($row[3]  ?? '');
            $type          = strtolower(trim($row[4]  ?? ''));
            $isUnlimited   = strtolower(trim($row[5]  ?? ''));
            $measurement   = trim($row[6]  ?? '');
            $price         = trim($row[7]  ?? '');
            $discPrice     = trim($row[8]  ?? '');
            $stock         = trim($row[9]  ?? '');
            $unitDisp      = trim($row[10] ?? '');
            $variantStatus = trim($row[11] ?? '');
            $totalQty      = trim($row[12] ?? '');
            $isCancelable  = strtolower(trim($row[13] ?? ''));
            $tillStatusRaw = trim($row[14] ?? '');
            $isReturnable  = strtolower(trim($row[15] ?? ''));
            $returnDays    = trim($row[16] ?? '');
            $indicator     = trim($row[17] ?? '');

            // Skip completely blank rows
            if ($productName === '' && $measurement === '' && $price === '') {
                $excelRow++;
                continue;
            }

            $rowErrors     = [];
            $resolvedCatId = null;
            $resolvedFtId  = null;
            $resolvedUnitId = null;

            // ── Multi-variant continuation rows commented out ──
            // Previously, if Col A (Product Name) was blank, the row was treated
            // as an additional variant of the previous product. This is no longer
            // supported — every row must have a Product Name.
            // $isNewProduct = $productName !== '';
            // if (!$isNewProduct && $currentProductFailed) { $excelRow++; continue; }

            // Every row must have a product name
            if (empty($productName)) {
                $rowErrors[] = 'Col A (Product Name): Empty — every row must have a product name.';
            }

            // ── Product-level validations ──
            if (empty($description)) {
                $rowErrors[] = 'Col B (Description): Empty — please enter a product description.';
            }
            if (empty($categoryName)) {
                $rowErrors[] = 'Col C (Category): Empty — please select a category from the dropdown.';
            } else {
                $cat = Category::whereIn('id', $sellerCats)
                               ->where('name', $categoryName)
                               ->first();
                if (!$cat) {
                    $rowErrors[] = 'Col C (Category): "' . $categoryName . '" is not assigned to this seller — pick a valid option from the dropdown.';
                } else {
                    $resolvedCatId = $cat->id;
                }
            }

            // ── Food Type lookup (name-based) ──
            if (!empty($foodTypeDisp)) {
                $ftNamePart = trim(explode(' - ', $foodTypeDisp)[0]);

                if ($resolvedCatId) {
                    $ft = CategoryType::where('name', $ftNamePart)
                                      ->where('category_id', $resolvedCatId)
                                      ->first();
                    if (!$ft) {
                        $rowErrors[] = 'Col D (Food Type): "' . $foodTypeDisp . '" does not belong to the selected category — pick a matching food type from the dropdown.';
                    } else {
                        $resolvedFtId = $ft->id;
                    }
                }
            }

            // ── Product-level field validations ──
            if (empty($type) || !in_array($type, ['packet', 'loose'], true)) {
                $found = $type !== '' ? '"' . $type . '"' : 'empty';
                $rowErrors[] = 'Col E (Type): ' . $found . ' is invalid — put "packet" or "loose".';
            }
            if (!in_array($isUnlimited, ['yes', 'no'], true)) {
                $found = $isUnlimited !== '' ? '"' . $isUnlimited . '"' : 'empty';
                $rowErrors[] = 'Col F (Is Unlimited Stock): ' . $found . ' is invalid — put "Yes" or "No".';
            }

            // Stock validation
            if ($isUnlimited === 'no' && ($stock === '' || !is_numeric($stock) || (int)$stock < 0)) {
                $found = $stock !== '' ? '"' . $stock . '"' : 'empty';
                $rowErrors[] = 'Col J (Stock): ' . $found . ' is invalid — put the stock quantity (0 or more). If unlimited, set Col F to "Yes" and Col J to 0.';
            } elseif ($isUnlimited === 'no' && is_numeric($stock) && (int)$stock === 0 && $variantStatus === 'Active') {
                $rowErrors[] = 'Col J (Stock): 0 is not allowed when Status (Col L) is "Active" — enter a quantity, or set Status to "Sold Out".';
            }

            // Unlimited stock cannot be "Sold Out"
            if ($isUnlimited === 'yes' && $variantStatus === 'Sold Out') {
                $rowErrors[] = 'Col L (Status): "Sold Out" is not allowed when Is Unlimited Stock (Col F) is "Yes" — set Status to "Active" or change Unlimited Stock to "No".';
            }

            // ── Variant-level validations (every row) ──
            if ($measurement === '' || !is_numeric($measurement) || (float)$measurement <= 0) {
                $found = $measurement !== '' ? '"' . $measurement . '"' : 'empty';
                $rowErrors[] = 'Col G (Measurement): ' . $found . ' is invalid — put a number greater than 0 (e.g. 1, 250, 0.5).';
            }
            if ($price === '' || !is_numeric($price) || (float)$price <= 0) {
                $found = $price !== '' ? '"' . $price . '"' : 'empty';
                $rowErrors[] = 'Col H (Price): ' . $found . ' is invalid — put a number greater than 0.';
            }
            if ($discPrice !== '' && (!is_numeric($discPrice) || (float)$discPrice < 0)) {
                $rowErrors[] = 'Col I (Discounted Price): "' . $discPrice . '" is invalid — put a valid number or leave it empty.';
            } elseif ($discPrice !== '' && is_numeric($discPrice) && is_numeric($price) && (float)$discPrice > 0 && (float)$discPrice >= (float)$price) {
                $rowErrors[] = 'Col I (Discounted Price): "' . $discPrice . '" must be less than Price (Col H = ' . $price . ').';
            }

            // Unit lookup
            if (empty($unitDisp)) {
                $rowErrors[] = 'Col K (Unit): Empty — please select a unit from the dropdown.';
            } else {
                $unit = Unit::whereRaw("CONCAT(name, ' (', short_code, ')') = ?", [$unitDisp])->first();
                if (!$unit) {
                    $unit = Unit::where('name', $unitDisp)->first();
                }
                if (!$unit) {
                    $rowErrors[] = 'Col K (Unit): "' . $unitDisp . '" not found — select a unit from the dropdown (e.g. "Kilogram (kg)").';
                } else {
                    $resolvedUnitId = $unit->id;
                }
            }

            if (!in_array($variantStatus, ['Active', 'Sold Out'], true)) {
                $found = $variantStatus !== '' ? '"' . $variantStatus . '"' : 'empty';
                $rowErrors[] = 'Col L (Status): ' . $found . ' is invalid — put "Active" or "Sold Out".';
            }
            if (!empty($isCancelable) && !in_array($isCancelable, ['yes', 'no'], true)) {
                $rowErrors[] = 'Col N (Is Cancelable): "' . $isCancelable . '" is invalid — put "Yes" or "No".';
            }

            // Till Status — look up ID from order_status_lists by name
            $resolvedTillStatusId = null;
            if ($isCancelable === 'yes') {
                if (empty($tillStatusRaw)) {
                    $rowErrors[] = 'Col O (Till Status): Empty — required when Is Cancelable (Col N) is "Yes". Pick "Received" or "Processed".';
                } else {
                    $tillStatusRecord = OrderStatusList::whereRaw('LOWER(status) = ?', [strtolower($tillStatusRaw)])->first();
                    if (!$tillStatusRecord) {
                        $rowErrors[] = 'Col O (Till Status): "' . $tillStatusRaw . '" not found — pick "Received" or "Processed" from the dropdown.';
                    } else {
                        $resolvedTillStatusId = $tillStatusRecord->id;
                    }
                }
            }
            if (!empty($isReturnable) && !in_array($isReturnable, ['yes', 'no'], true)) {
                $rowErrors[] = 'Col P (Is Returnable): "' . $isReturnable . '" is invalid — put "Yes" or "No".';
            }
            if ($isReturnable === 'yes' && ($returnDays === '' || !is_numeric($returnDays) || (int)$returnDays <= 0)) {
                $found = $returnDays !== '' ? '"' . $returnDays . '"' : 'empty';
                $rowErrors[] = 'Col Q (Return Days): ' . $found . ' is invalid — put the number of return days (e.g. 7) when Is Returnable (Col P) is "Yes".';
            } elseif ($isReturnable === 'no' && $returnDays !== '' && $returnDays !== '0') {
                $rowErrors[] = 'Col Q (Return Days): Should be empty when Is Returnable (Col P) is "No" — remove the value or set Is Returnable to "Yes".';
            }

            if (!empty($rowErrors)) {
                foreach ($rowErrors as $errMsg) {
                    $errors[] = ['row' => $excelRow, 'product' => $productName, 'message' => $errMsg];
                }
                $excelRow++;
                continue;
            }

            // ── Build product with single variant ──
            $indicatorMap = ['Veg' => 1, 'Non-Veg' => 2];
            $products[] = [
                'name'                   => $productName,
                'description'            => $description,
                // 'tags_raw'            => $tags, // Tags removed
                'category_id'            => $resolvedCatId,
                'item_type_id'           => $resolvedFtId,
                'type'                   => $type,
                'is_unlimited_stock'     => $isUnlimited === 'yes' ? 1 : 0,
                'fssai_lic_no'           => ' ',
                'total_allowed_quantity' => $totalQty !== '' ? (int)$totalQty : 100,
                'cancelable_status'      => $isCancelable === 'yes' ? 1 : 0,
                'till_status'            => $resolvedTillStatusId,
                'return_status'          => $isReturnable === 'yes' ? 1 : 0,
                'return_days'            => $returnDays !== '' ? (int)$returnDays : 0,
                'indicator'              => $indicatorMap[$indicator] ?? 0,
                'variant' => [
                    'type'             => $type,
                    'measurement'      => (float)$measurement,
                    'price'            => (float)$price,
                    'discounted_price' => $discPrice !== '' ? (float)$discPrice : 0,
                    'stock'            => $isUnlimited === 'yes' ? 0 : (int)$stock,
                    'stock_unit_id'    => $resolvedUnitId,
                    'status'           => $variantStatus === 'Active' ? 1 : 0,
                ],
            ];

            $excelRow++;
        }

        // Return all validation errors — no partial saves
        if (!empty($errors)) {
            return response()->json([
                'status'  => 0,
                'message' => 'Please fix the ' . count($errors) . ' issue(s) below and re-upload.',
                'errors'  => $errors,
            ]);
        }

        if (empty($products)) {
            return CommonHelper::responseError("No valid products found in the file.");
        }

        DB::beginTransaction();
        try {
            $savedCount   = 0;
            $variantCount = 0;

            foreach ($products as $pd) {
                $slug      = preg_replace('/\s+/', '-', trim(preg_replace('/[^\p{L}\p{N} ]/u', '', $pd['name'])));
                $slugCount = Product::where('slug', 'LIKE', "{$slug}%")->count();
                $rowOrder  = Product::max('row_order') + 1;

                $productData = [
                    'name'                   => $pd['name'],
                    'slug'                   => $slugCount ? "{$slug}-{$slugCount}" : $slug,
                    'row_order'              => $rowOrder,
                    'description'            => $pd['description'],
                    'category_id'            => $pd['category_id'],
                    'item_type_id'           => $pd['item_type_id'],
                    'store_id'               => $storeId,
                    'seller_id'              => $sellerId,
                    'type'                   => $pd['type'],
                    'is_unlimited_stock'     => $pd['is_unlimited_stock'],
                    'fssai_lic_no'           => $pd['fssai_lic_no'],
                    'total_allowed_quantity' => $pd['total_allowed_quantity'],
                    'cancelable_status'      => $pd['cancelable_status'],
                    'till_status'            => $pd['till_status'],
                    'return_status'          => $pd['return_status'],
                    'return_days'            => $pd['return_days'],
                    'indicator'              => $pd['indicator'],
                    'is_approved'            => $isAutoApprove,
                    'status'                 => 1,
                    'cod_allowed'            => 1,
                    'image'                  => '',
                ];

                Log::info('[BulkUpload] Saving product', $productData);

                $product = new Product();
                $product->name                   = $productData['name'];
                $product->slug                   = $productData['slug'];
                $product->row_order              = $productData['row_order'];
                $product->description            = $productData['description'];
                $product->category_id            = $productData['category_id'];
                $product->item_type_id           = $productData['item_type_id'];
                $product->store_id               = $productData['store_id'];
                $product->seller_id              = $productData['seller_id'];
                $product->type                   = $productData['type'];
                $product->is_unlimited_stock     = $productData['is_unlimited_stock'];
                $product->fssai_lic_no           = $productData['fssai_lic_no'];
                $product->total_allowed_quantity = $productData['total_allowed_quantity'];
                $product->cancelable_status      = $productData['cancelable_status'];
                $product->till_status            = $productData['till_status'];
                $product->return_status          = $productData['return_status'];
                $product->return_days            = $productData['return_days'];
                $product->indicator              = $productData['indicator'];
                $product->is_approved            = $productData['is_approved'];
                $product->status                 = $productData['status'];
                $product->cod_allowed            = $productData['cod_allowed'];
                $product->image                  = $productData['image'];
                $product->save();

                // Tags syncing removed
                // if (!empty($pd['tags_raw'])) {
                //     $tagNames  = array_filter(array_map('trim', explode(',', $pd['tags_raw'])));
                //     $tagIds    = [];
                //     foreach ($tagNames as $tagName) {
                //         $tag      = Tag::firstOrCreate(['name' => $tagName]);
                //         $tagIds[] = $tag->id;
                //     }
                //     $product->tags()->sync($tagIds);
                //     Log::info('[BulkUpload] Tags synced', ['product_id' => $product->id, 'tag_ids' => $tagIds]);
                // }

                Log::info('[BulkUpload] Product saved', ['product_id' => $product->id, 'name' => $product->name, 'till_status_id' => $product->till_status]);

                // Single variant per product (multi-variant loop removed)
                $vd = $pd['variant'];
                $variantData = [
                    'product_id'       => $product->id,
                    'type'             => $vd['type'],
                    'measurement'      => $vd['measurement'],
                    'price'            => $vd['price'],
                    'discounted_price' => $vd['discounted_price'],
                    'stock'            => $vd['stock'],
                    'stock_unit_id'    => $vd['stock_unit_id'],
                    'status'           => $vd['status'],
                ];

                Log::info('[BulkUpload] Saving variant', $variantData);

                $variant                   = new ProductVariant();
                $variant->product_id       = $variantData['product_id'];
                $variant->type             = $variantData['type'];
                $variant->measurement      = $variantData['measurement'];
                $variant->price            = $variantData['price'];
                $variant->discounted_price = $variantData['discounted_price'];
                $variant->stock            = $variantData['stock'];
                $variant->stock_unit_id    = $variantData['stock_unit_id'];
                $variant->status           = $variantData['status'];
                $variant->save();

                Log::info('[BulkUpload] Variant saved', ['variant_id' => $variant->id, 'product_id' => $product->id]);

                $variantCount++;
                $savedCount++;
            }

            DB::commit();

            Log::info('Seller bulk product upload success', [
                'seller_id'      => $sellerId,
                'products_saved' => $savedCount,
                'variants_saved' => $variantCount,
            ]);

            return CommonHelper::responseSuccess(
                "{$savedCount} product(s) uploaded successfully."
            );

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Seller bulk product upload failed', [
                'seller_id' => $sellerId,
                'error'     => $e->getMessage(),
            ]);
            return CommonHelper::responseError("Upload failed: " . $e->getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // Public: Step-by-step instructions for the seller Flutter app UI
    // No auth required
    // ─────────────────────────────────────────────────────────────────

    public function bulkUploadInstructions()
    {
        return response()->json([
            'status'  => 1,
            'message' => 'Bulk product upload instructions.',
            'data'    => [
                'title' => 'Bulk Product Upload',
                'subtitle' => 'Upload multiple products at once using an Excel file.',
                'steps' => [
                    [
                        'step'  => 1,
                        'title' => 'Download the Template',
                        'description' => 'Tap the "Download Template" button to get an Excel file (.xlsx) pre-filled with your shop\'s categories, food types, and units as dropdown options.',
                        'icon' => 'download',
                    ],
                    [
                        'step'  => 2,
                        'title' => 'Read the Instructions Sheet',
                        'description' => 'The downloaded file has two sheets — "Products" (where you fill data) and "Instructions & Examples" (reference guide). Open the "Instructions & Examples" sheet first to understand each column, what values are allowed, and see sample product rows.',
                        'icon' => 'info',
                    ],
                    [
                        'step'  => 3,
                        'title' => 'Fill Your Product Data',
                        'description' => 'Go to the "Products" sheet and fill in your product details row by row. Use the dropdown menus for Category, Food Type, Unit, Status, etc. — do NOT type values manually. Fields marked with * are mandatory.',
                        'icon' => 'edit',
                    ],
                    [
                        'step'  => 4,
                        'title' => 'Save & Upload the File',
                        'description' => 'Once you have filled in all products, save the Excel file and come back here. Tap "Upload File" and select your saved file. The system will validate all rows before saving.',
                        'icon' => 'upload',
                    ],
                    [
                        'step'  => 5,
                        'title' => 'Review Errors (if any)',
                        'description' => 'If there are any errors, the entire file will be rejected — no partial uploads. You will see a list of errors with the exact row number, column, and what went wrong. Fix all the issues in your Excel file and re-upload.',
                        'icon' => 'error',
                    ],
                    [
                        'step'  => 6,
                        'title' => 'Done!',
                        'description' => 'Once all rows pass validation, your products will be created automatically. They will appear in your product list based on your shop\'s approval settings.',
                        'icon' => 'check_circle',
                    ],
                ],
                'tips' => [
                    'All columns are required, except Till Status and Return Days — these depend on Is Cancelable and Is Returnable.',
                    'Each row = one product with one variant.',
                    'Do NOT rename or delete the "Products" sheet.',
                    'Do NOT modify or unhide hidden columns (S onwards) — they contain internal formulas.',
                    'Discounted Price must be less than Price.',
                    'If "Is Unlimited Stock" is Yes, set Stock to 0.',
                    'If "Is Cancelable" is Yes, you must select a Till Status (Received / Processed).',
                    'If "Is Returnable" is Yes, you must enter Return Days (e.g. 7).',
                    'Blank rows are automatically skipped — no need to delete them.',
                ],
                'columns' => [
                    ['column' => 'A', 'header' => 'Product Name', 'required' => true, 'description' => 'Name of the product.'],
                    ['column' => 'B', 'header' => 'Description', 'required' => true, 'description' => 'Short description of the product.'],
                    ['column' => 'C', 'header' => 'Category', 'required' => true, 'description' => 'Select from dropdown. Must be assigned to your shop.'],
                    ['column' => 'D', 'header' => 'Food Type', 'required' => true, 'description' => 'Select from dropdown. Must belong to the selected category.'],
                    ['column' => 'E', 'header' => 'Type', 'required' => true, 'description' => 'Product type: "packet" or "loose".'],
                    ['column' => 'F', 'header' => 'Is Unlimited Stock', 'required' => true, 'description' => '"Yes" or "No".'],
                    ['column' => 'G', 'header' => 'Measurement', 'required' => true, 'description' => 'Numeric value for unit measurement (e.g. 1, 250, 0.5).'],
                    ['column' => 'H', 'header' => 'Price (Rs.)', 'required' => true, 'description' => 'Selling price. Must be greater than 0.'],
                    ['column' => 'I', 'header' => 'Discounted Price (Rs.)', 'required' => true, 'description' => 'Discounted price. Must be less than Price.'],
                    ['column' => 'J', 'header' => 'Stock', 'required' => true, 'description' => 'Stock quantity. Set to 0 if unlimited stock.'],
                    ['column' => 'K', 'header' => 'Unit', 'required' => true, 'description' => 'Select from dropdown (e.g. "Kilogram (kg)").'],
                    ['column' => 'L', 'header' => 'Status', 'required' => true, 'description' => '"Active" or "Sold Out".'],
                    ['column' => 'M', 'header' => 'Total Allowed Qty', 'required' => true, 'description' => 'Max quantity a customer can order.'],
                    ['column' => 'N', 'header' => 'Is Cancelable', 'required' => true, 'description' => '"Yes" or "No".'],
                    ['column' => 'O', 'header' => 'Till Status', 'required' => false, 'description' => 'Required if Is Cancelable is "Yes". Options: Received / Processed. Leave empty if "No".'],
                    ['column' => 'P', 'header' => 'Is Returnable', 'required' => true, 'description' => '"Yes" or "No".'],
                    ['column' => 'Q', 'header' => 'Return Days', 'required' => false, 'description' => 'Required if Is Returnable is "Yes". Number of days (e.g. 7). Leave empty if "No".'],
                    ['column' => 'R', 'header' => 'Indicator', 'required' => true, 'description' => '"Veg" or "Non-Veg".'],
                ],
            ],
        ]);
    }
}
