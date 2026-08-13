<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Seller Agreement - {{ $seller->store_name }}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'DejaVu Sans', sans-serif;
            font-size: 11px;
            color: #333;
            line-height: 1.6;
            padding: 20px;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 15px;
            border-bottom: 3px solid #2ecc71;
        }
        .header h1 {
            font-size: 28px;
            color: #2c3e50;
            margin-bottom: 5px;
        }
        .header .subtitle {
            font-size: 14px;
            color: #7f8c8d;
            font-weight: bold;
        }
        .agreement-number {
            text-align: right;
            margin-bottom: 20px;
            font-size: 12px;
            color: #555;
        }
        .section-title {
            font-size: 16px;
            font-weight: bold;
            color: #2c3e50;
            margin-top: 20px;
            margin-bottom: 10px;
            padding-bottom: 5px;
            border-bottom: 2px solid #ecf0f1;
        }
        .info-table {
            width: 100%;
            margin-bottom: 20px;
            border-collapse: collapse;
        }
        .info-table td {
            padding: 8px;
            border: 1px solid #ddd;
        }
        .info-table td.label {
            background-color: #f8f9fa;
            font-weight: bold;
            width: 40%;
        }
        .terms-list {
            margin-left: 20px;
            margin-bottom: 15px;
        }
        .terms-list li {
            margin-bottom: 10px;
            text-align: justify;
        }
        .signature-section {
            margin-top: 40px;
            width: 100%;
            table-layout: fixed;
        }
        .signature-section td.signature-box {
            width: 50%;
            vertical-align: top;
            padding: 15px;
            border: 1px solid #ddd;
        }
        .signature-spacer {
            width: 2%;
        }
        .signature-space {
            margin-top: 50px;
            border-top: 1px solid #333;
            padding-top: 5px;
            text-align: center;
            font-weight: bold;
        }
        .footer {
            margin-top: 30px;
            padding-top: 15px;
            border-top: 2px solid #ecf0f1;
            text-align: center;
            font-size: 10px;
            color: #7f8c8d;
        }
        .important-note {
            background-color: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 10px;
            margin: 15px 0;
            font-size: 10px;
        }
        .party-name {
            font-weight: bold;
            color: #2c3e50;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>{{ $platform_name }}</h1>
        <div class="subtitle">SELLER PARTNERSHIP AGREEMENT</div>
    </div>

    <div class="agreement-number">
        <strong>Agreement No:</strong> {{ $agreement_number }}<br>
        <strong>Date:</strong> {{ $agreement_date }}
    </div>

    <div style="text-align: justify; margin-bottom: 20px;">
        This Seller Partnership Agreement ("Agreement") is entered into on <strong>{{ $agreement_date }}</strong> between:
    </div>

    <div style="margin-bottom: 15px;">
        <div style="margin-bottom: 10px;">
            <strong>PARTY 1 (Platform):</strong><br>
            <span class="party-name">{{ $platform_name ?? 'N/A' }}</span><br>
            Email: {{ $platform_email ?: 'N/A' }}<br>
            Phone: {{ $platform_phone ?: 'N/A' }}<br>
            (Hereinafter referred to as "Platform" or "{{ $platform_name }}")
        </div>

        <div style="margin-top: 15px;">
            <strong>PARTY 2 (Seller):</strong><br>
            <span class="party-name">{{ $seller->store_name }}</span>
        </div>
    </div>

    <div class="section-title">1. SELLER DETAILS</div>
    <table class="info-table">
        <tr>
            <td class="label">Store Name</td>
            <td>{{ $seller->store_name ?? 'N/A' }}</td>
        </tr>
        <tr>
            <td class="label">Owner Name</td>
            <td>{{ $seller->name ?? 'N/A' }}</td>
        </tr>
        <tr>
            <td class="label">Email</td>
            <td>{{ $seller->email ?? 'N/A' }}</td>
        </tr>
        <tr>
            <td class="label">Mobile</td>
            <td>{{ $seller->mobile ?? 'N/A' }}</td>
        </tr>
        <tr>
            <td class="label">PAN Number</td>
            <td>{{ $seller->pan_number ?? 'N/A' }}</td>
        </tr>
        <tr>
            <td class="label">GST Number</td>
            <td>{{ $seller->tax_number ?? 'N/A' }}</td>
        </tr>
        <tr>
            <td class="label">FSSAI Number</td>
            <td>{{ $seller->fssai_number ?? 'N/A' }}</td>
        </tr>
        <tr>
            <td class="label">Aadhar Number</td>
            <td>{{ $seller->aadhar_number ?? 'N/A' }}</td>
        </tr>
        <tr>
            <td class="label">Store Address</td>
            <td>
                @php
                    // Prefer the full store_location address string (typically
                    // a Google-Maps formatted address) when present; fall back
                    // to assembling whatever address parts we do have.
                    if (!empty($seller->store_location)) {
                        $full_address = $seller->store_location;
                    } else {
                        $address_parts = array_filter([
                            $seller->store_city,
                            optional($seller->city)->name,
                        ]);
                        $full_address = !empty($address_parts) ? implode(', ', $address_parts) : 'N/A';
                    }
                @endphp
                {{ $full_address }}
            </td>
        </tr>
    </table>

    @php
        $categoryNounMap = [
            'Vegetables & Fruits' => 'fresh fruits, vegetables and produce',
            'Chicken & Meat'      => 'chicken, mutton, fish, seafood and other meat products',
            'Food'                => 'cooked meals, bakery items, beverages and prepared food products',
            'Super Mart'          => 'groceries, staples, dairy, packaged goods and other FMCG items',
        ];
        $perishableClauseMap = [
            'Vegetables & Fruits' => 'For fresh produce, the Seller must ensure items are harvested, cleaned and dispatched within their natural shelf life, and that no overripe or damaged stock is listed.',
            'Chicken & Meat'      => 'For meat, fish and seafood items, the Seller must maintain the cold chain end-to-end and ensure each batch is dispatched well within its safe-consumption window.',
            'Food'                => 'For cooked / ready-to-eat items, the Seller must dispatch food within the prescribed hot- or cold-holding window and clearly mention expiry / consume-by times on listings.',
            'Super Mart'          => 'For dairy, frozen and perishable packaged goods, the Seller must respect manufacturer storage instructions and never list items past their printed expiry date.',
        ];
        $categoryNoun = $vendor_gst_category && isset($categoryNounMap[$vendor_gst_category])
            ? $categoryNounMap[$vendor_gst_category]
            : 'groceries, meat, fruits, vegetables, and other Fast-Moving Consumer Goods (FMCG)';
        $perishableClause = $vendor_gst_category && isset($perishableClauseMap[$vendor_gst_category])
            ? $perishableClauseMap[$vendor_gst_category]
            : 'For perishable items (meat, fruits, vegetables), the Seller must ensure products meet quality standards and expiry dates are clearly mentioned.';
    @endphp

    <div class="section-title">2. PURPOSE OF AGREEMENT</div>
    <div style="text-align: justify; margin-bottom: 15px;">
        This Agreement establishes the terms and conditions under which the Seller agrees to list, sell, and deliver {{ $categoryNoun }} through the {{ $platform_name }} platform.
    </div>

    <div class="section-title">3. SCOPE OF SERVICES</div>
    <ol class="terms-list">
        <li>The Seller agrees to offer {{ $categoryNoun }} for sale through the {{ $platform_name }} platform, ensuring quality, freshness, and compliance with food safety standards.</li>
        <li>{{ $platform_name }} will provide the technology platform, payment gateway, customer support, and delivery logistics (where applicable) to facilitate transactions.</li>
        <li>The Seller shall maintain adequate inventory levels and update product availability in real-time on the platform.</li>
        <li>{{ $perishableClause }}</li>
    </ol>

    <div class="section-title">4. SELLER OBLIGATIONS</div>
    <ol class="terms-list">
        <li><strong>Product Quality:</strong> The Seller warrants that all products listed are genuine, properly stored, and comply with applicable food safety regulations including FSSAI guidelines.</li>
        <li><strong>Pricing:</strong> The Seller shall set competitive prices and update them regularly. Any price changes must be reflected on the platform within 24 hours.</li>
        <li><strong>Order Fulfillment:</strong> The Seller agrees to process orders within the committed timeframe and ensure timely dispatch/handover to delivery partners.</li>
        <li><strong>Licenses & Permits:</strong> The Seller shall maintain all necessary licenses including FSSAI license, GST registration, trade license, and any other statutory requirements.</li>
        <li><strong>Hygiene Standards:</strong> For food items, the Seller must maintain strict hygiene standards in storage, handling, and packaging of products.</li>
        <li><strong>Returns & Refunds:</strong> The Seller agrees to accept returns for defective, expired, or incorrect products as per the platform's return policy.</li>
    </ol>

    <div class="section-title">5. PLATFORM OBLIGATIONS</div>
    <ol class="terms-list">
        <li>{{ $platform_name }} will provide a user-friendly platform for listing products and managing orders.</li>
        <li>Facilitate secure payment processing and timely settlement of dues to the Seller.</li>
        <li>Provide customer support for order-related queries and disputes.</li>
        <li>Coordinate delivery logistics (where applicable) to ensure timely product delivery to customers.</li>
        <li>Market and promote the platform to increase customer reach and sales opportunities for sellers.</li>
    </ol>

    <div class="section-title">6. COMMISSION & PAYMENT TERMS</div>
    @php
        $appliedCommission = !empty($vendor_commission_category) && $vendor_commission_percent !== null
            ? (float) $vendor_commission_percent
            : (isset($seller->commission) ? (float) $seller->commission : 0);
        $commissionLabel = rtrim(rtrim(number_format($appliedCommission, 2, '.', ''), '0'), '.');
    @endphp
    <ol class="terms-list">
        @if(!empty($vendor_commission_category) && $vendor_commission_percent !== null)
            <li>
                As the Seller is registered under the
                <strong>{{ $vendor_commission_category }}</strong> vendor category,
                the Platform shall charge a commission of
                <strong>{{ $commissionLabel }}%</strong>
                on each successful transaction (excluding taxes and delivery charges). Rates are set by the Platform under its Vendor Commission Configurations and may be revised with prior notice.
            </li>
        @else
            <li>The Platform shall charge a commission of <strong>{{ $commissionLabel }}%</strong> on each successful transaction (excluding taxes and delivery charges).</li>
        @endif
        @if(!empty($vendor_gst_category) && $vendor_gst_percent !== null)
            <li>
                The applicable platform GST for the
                <strong>{{ $vendor_gst_category }}</strong> category is
                <strong>{{ rtrim(rtrim(number_format((float) $vendor_gst_percent, 2, '.', ''), '0'), '.') }}%</strong>,
                deducted from gross transactions in addition to the commission above. Rates are set by the Platform under its Vendor GST Configurations and may be revised with prior notice.
            </li>
        @endif
        <li>Payment settlements will be processed on a weekly/bi-weekly basis to the Seller's registered bank account.</li>
        <li>The Seller is responsible for all applicable taxes on their earnings, including GST, income tax, etc.</li>
    </ol>

    <div class="section-title">7. PRODUCT CATEGORIES COVERED</div>
    <div style="text-align: justify; margin-bottom: 15px;">
        @if(!empty($vendor_gst_category))
            This agreement covers the sale of <strong>{{ $vendor_gst_category }}</strong> products by the Seller through the {{ $platform_name }} platform. Permitted items include:
            <ul style="margin-left: 30px; margin-top: 10px;">
                @switch($vendor_gst_category)
                    @case('Vegetables & Fruits')
                        <li>Fresh fruits</li>
                        <li>Fresh vegetables and leafy greens</li>
                        <li>Cut, cleaned, or pre-packaged produce</li>
                        @break
                    @case('Chicken & Meat')
                        <li>Chicken (fresh, frozen, processed)</li>
                        <li>Mutton, lamb, and other red meats</li>
                        <li>Fish and seafood</li>
                        <li>Speciality meats as mutually agreed upon</li>
                        @break
                    @case('Food')
                        <li>Cooked meals and ready-to-eat food items</li>
                        <li>Bakery products and baked goods</li>
                        <li>Beverages prepared by the Seller</li>
                        <li>Snacks and packaged food items</li>
                        @break
                    @case('Super Mart')
                        <li>Groceries and staples</li>
                        <li>Dairy products</li>
                        <li>Packaged foods and beverages</li>
                        <li>Personal care and household products</li>
                        <li>Any other FMCG items as mutually agreed upon</li>
                        @break
                    @default
                        <li>Items within the {{ $vendor_gst_category }} category as mutually agreed upon</li>
                @endswitch
            </ul>
            Sale of items outside the Seller's registered category requires prior written approval from the Platform.
        @else
            This agreement covers the sale of the following product categories through the {{ $platform_name }} platform:
            <ul style="margin-left: 30px; margin-top: 10px;">
                <li>Fresh Fruits and Vegetables</li>
                <li>Meat and Seafood (Fresh, Frozen, and Processed)</li>
                <li>Groceries and Staples</li>
                <li>Dairy Products</li>
                <li>Bakery Items</li>
                <li>Packaged Foods and Beverages</li>
                <li>Personal Care and Household Products</li>
                <li>Any other FMCG items as mutually agreed upon</li>
            </ul>
        @endif
    </div>

    <div class="section-title">8. QUALITY STANDARDS</div>
    <ol class="terms-list">
        @switch($vendor_gst_category ?? null)
            @case('Vegetables & Fruits')
                <li><strong>Freshness:</strong> Fruits and vegetables must be freshly harvested, free from rot, mould or pests, and delivered within the agreed shelf-life window.</li>
                <li><strong>Cleaning &amp; Pesticide Limits:</strong> Produce must be properly cleaned and remain free from pesticide residues beyond the limits prescribed by FSSAI.</li>
                <li><strong>Sorting &amp; Grading:</strong> Items must be sorted and graded; spoiled, damaged or undersized produce must not be listed for sale.</li>
                <li><strong>Cold Chain (where applicable):</strong> Leafy greens, herbs, and other temperature-sensitive items must be stored and dispatched under appropriate refrigeration.</li>
                @break

            @case('Chicken & Meat')
                <li><strong>Sourcing:</strong> Chicken, mutton, lamb, fish and seafood must be sourced only from FSSAI-licensed slaughterhouses or suppliers.</li>
                <li><strong>Cold Chain &amp; Temperature:</strong> Items must be stored, processed and dispatched at the temperatures mandated by FSSAI for the respective category (fresh, frozen, or processed).</li>
                <li><strong>Hygiene &amp; Handling:</strong> Cutting, cleaning, deboning and packaging must follow food-safety norms; gloves, masks and sanitised surfaces are mandatory.</li>
                <li><strong>Traceability:</strong> The Seller shall maintain batch / lot records that allow each delivered item to be traced back to its source supplier.</li>
                <li><strong>Packaging:</strong> Each unit must be sealed in food-grade, leak-proof packaging and clearly labelled with weight, type and packed-on date.</li>
                @break

            @case('Food')
                <li><strong>Kitchen Hygiene:</strong> Preparation areas must comply with FSSAI hygiene norms; staff handling food must hold valid food-handler health certificates.</li>
                <li><strong>Ingredients:</strong> Only food-grade, in-date ingredients may be used; allergens must be clearly disclosed on listing pages.</li>
                <li><strong>Hot &amp; Cold Holding:</strong> Cooked food must be packed at safe holding temperatures and dispatched within the prescribed time window.</li>
                <li><strong>Packaging:</strong> Tamper-evident, food-grade containers are mandatory; items must be labelled with date, time of preparation and expiry where applicable.</li>
                <li><strong>Allergens &amp; Dietary Labels:</strong> Veg / non-veg, contains-nuts, contains-dairy and similar labels must accurately reflect the contents.</li>
                @break

            @case('Super Mart')
                <li><strong>Sealed Packaging:</strong> All packaged products must be received and sold with manufacturer seals intact.</li>
                <li><strong>Expiry &amp; Shelf-Life:</strong> Items nearing expiry must be flagged or removed from sale; expired stock must never be dispatched.</li>
                <li><strong>Storage Conditions:</strong> Dairy, frozen and chilled items must be stored at the temperatures specified by the manufacturer.</li>
                <li><strong>Batch Records:</strong> Maintain inward-stock records to trace any batch in case of a recall.</li>
                <li><strong>Packaging Integrity:</strong> Damaged, leaking or pest-affected items must be discarded and not listed.</li>
                @break

            @default
                <li><strong>Fresh Produce:</strong> Fruits and vegetables must be fresh, properly cleaned, and free from pesticides beyond permissible limits.</li>
                <li><strong>Meat &amp; Seafood:</strong> Must be sourced from licensed slaughterhouses/suppliers, stored at appropriate temperatures, and handled following food safety norms.</li>
                <li><strong>Dairy Products:</strong> Must be stored under proper refrigeration and sold within expiry dates.</li>
                <li><strong>Packaging:</strong> All perishable items must be properly packaged to prevent contamination and maintain freshness during transit.</li>
        @endswitch
    </ol>

    <div class="section-title">9. INTELLECTUAL PROPERTY</div>
    <ol class="terms-list">
        <li>The Seller grants {{ $platform_name }} a non-exclusive license to use product images, descriptions, and branding for marketing purposes on the platform.</li>
        <li>{{ $platform_name }} retains all rights to its brand, logo, and platform technology.</li>
        <li>Neither party shall use the other's intellectual property without prior written consent.</li>
    </ol>

    <div class="section-title">10. CONFIDENTIALITY</div>
    <div style="text-align: justify; margin-bottom: 15px;">
        Both parties agree to maintain confidentiality of business information, customer data, and trade secrets shared during the course of this partnership.
    </div>

    <div class="section-title">11. DISPUTE RESOLUTION</div>
    <ol class="terms-list">
        <li>Any disputes arising from this Agreement shall first be attempted to be resolved through mutual discussion and negotiation.</li>
        <li>If unresolved, disputes shall be subject to arbitration as per the Arbitration and Conciliation Act, 1996.</li>
        <li>The jurisdiction for legal matters shall be the courts of the city where {{ $platform_name }} is registered.</li>
    </ol>

    <div class="section-title">12. TERMINATION</div>
    <ol class="terms-list">
        <li>Either party may terminate this Agreement by providing 30 days written notice to the other party.</li>
        <li>{{ $platform_name }} reserves the right to immediately suspend or terminate the Seller's account in case of:
            <ul style="margin-top: 5px;">
                <li>Violation of food safety regulations or quality standards</li>
                <li>Fraudulent activities or misrepresentation</li>
                <li>Consistent poor customer feedback or ratings</li>
                <li>Non-compliance with platform policies</li>
            </ul>
        </li>
        <li>Upon termination, all pending payments shall be settled within 15 working days.</li>
    </ol>

    <div class="section-title">13. INDEMNIFICATION</div>
    <div style="text-align: justify; margin-bottom: 15px;">
        The Seller agrees to indemnify and hold {{ $platform_name }} harmless from any claims, damages, or legal actions arising from product quality issues, food safety violations, intellectual property infringement, or breach of statutory regulations.
    </div>

    <div class="section-title">14. MISCELLANEOUS</div>
    <ol class="terms-list">
        <li><strong>Entire Agreement:</strong> This Agreement constitutes the entire understanding between the parties and supersedes all prior agreements.</li>
        <li><strong>Amendment:</strong> Any amendments to this Agreement must be made in writing and signed by both parties.</li>
        <li><strong>Governing Law:</strong> This Agreement shall be governed by the laws of India.</li>
        <li><strong>Force Majeure:</strong> Neither party shall be liable for delays or failures in performance due to circumstances beyond their reasonable control.</li>
    </ol>

    <div class="important-note">
        <strong>Important Notice:</strong> This agreement is subject to compliance with all applicable laws including the Food Safety and Standards Act, 2006, Consumer Protection Act, 2019, GST laws, and other relevant regulations. The Seller acknowledges their responsibility to maintain all required licenses and permits.
    </div>

    <table class="signature-section" width="100%" cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td class="signature-box" width="49%" valign="top" style="width:49%; vertical-align:top; padding:15px; border:1px solid #ddd;">
                <strong>FOR {{ strtoupper($platform_name) }}</strong><br>
                (Platform Representative)<br>
                @if(!empty($zenfo_stamp_data))
                    <div style="margin-top: 20px; text-align: center;">
                        <img src="{{ $zenfo_stamp_data }}" alt="{{ $platform_name }} Stamp" style="max-height: 90px; max-width: 220px;">
                    </div>
                @else
                    <div class="signature-space">
                        Authorized Signature
                    </div>
                @endif
                <div style="margin-top: 10px; font-size: 10px;">
                    Date: {{ !empty($zenfo_stamp_data) ? ($agreement_date ?? '_______________') : '_______________' }}<br>
                    Name: {{ $platform_name ?? '_______________' }}<br>
                    Designation: Authorized Representative
                </div>
            </td>
            <td class="signature-spacer" width="2%" style="width:2%;">&nbsp;</td>
            <td class="signature-box" width="49%" valign="top" style="width:49%; vertical-align:top; padding:15px; border:1px solid #ddd;">
                <strong>FOR {{ strtoupper($seller->store_name ?? 'N/A') }}</strong><br>
                (Seller/Proprietor)<br>
                @if(!empty($signature_image_data))
                    <div style="margin-top: 20px; text-align: center;">
                        <img src="{{ $signature_image_data }}" alt="Signature" style="max-height: 60px; max-width: 200px;">
                    </div>
                    <div style="border-top: 1px solid #333; padding-top: 5px; text-align: center; font-weight: bold; margin-top: 4px;">
                        Authorized Signature
                    </div>
                @else
                    <div class="signature-space">
                        Authorized Signature
                    </div>
                @endif
                <div style="margin-top: 10px; font-size: 10px;">
                    Date: {{ !empty($signature_image_data) ? ($agreement_date ?? '_______________') : '_______________' }}<br>
                    Name: {{ $seller->name ?? 'N/A' }}<br>
                    PAN: {{ $seller->pan_number ?? 'N/A' }}
                </div>
            </td>
        </tr>
    </table>

    <div class="footer">
        This is a system-generated agreement document.<br>
        For queries, please contact {{ $platform_email ?: 'N/A' }} or call {{ $platform_phone ?: 'N/A' }}<br>
        <strong>{{ $platform_name }}</strong> - Connecting Quality Sellers with Customers
    </div>
</body>
</html>