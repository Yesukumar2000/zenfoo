@php
    $appName = \App\Models\Setting::get_value('app_name') ?: 'ZENFOO';
    $supportEmail = \App\Models\Setting::get_value('support_email') ?: '';
    $supportNumber = \App\Models\Setting::get_value('support_number') ?: '';
    $logo = \App\Models\Setting::get_value('logo') ?? "";
    $logo_full_path = $logo !== "" ? url('/').'/storage/'.$logo : asset('images/favicon.png');
    $currency = \App\Models\Setting::get_value('currency') ?? '₹';

    // Parse cart_metadata for billing summary if available
    $cartMetadata = $order->cart_metadata;
    if (is_string($cartMetadata)) {
        $cartMetadata = json_decode($cartMetadata, true);
    }
    $cartInfo = $cartMetadata['cart_info'] ?? null;
    $billingSummary = $cartMetadata['billing_summary'] ?? null;
    $deliveryInstructions = $cartInfo['delivery_instructions'] ?? null;
@endphp
<html>
<head>
    <title>Invoice {{ $order->order_number }} - {{ $appName }}</title>
    <style>
        body {
            font-family: 'Courier New', Courier, monospace;
            font-size: 11px;
            color: #000;
            line-height: 1.4;
            margin: 0;
            padding: 20px;
        }
        .header {
            text-align: center;
            margin-bottom: 20px;
        }
        .header h1 {
            font-size: 24px;
            margin: 0;
            letter-spacing: 2px;
        }
        .divider {
            border-top: 1px dashed #000;
            margin: 10px 0;
        }
        .double-divider {
            border-top: 1px solid #000;
            border-bottom: 1px solid #000;
            height: 2px;
            margin: 10px 0;
        }
        .section-title {
            font-weight: bold;
            text-transform: uppercase;
            margin: 10px 0 5px 0;
            font-size: 12px;
        }
        .row {
            clear: both;
            width: 100%;
            margin-bottom: 2px;
        }
        .label {
            float: left;
            width: 40%;
            font-weight: bold;
        }
        .value {
            float: right;
            width: 58%;
            text-align: right;
        }
        .item-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }
        .item-table th {
            text-align: left;
            border-bottom: 1px solid #000;
            padding: 5px 0;
            font-weight: bold;
        }
        .item-table td {
            padding: 5px 0;
            vertical-align: top;
        }
        .text-right {
            text-align: right;
        }
        .bold {
            font-weight: bold;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            font-size: 10px;
        }
        .store-name {
            font-weight: bold;
            margin-top: 10px;
            border-bottom: 1px solid #eee;
            padding-bottom: 2px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>{{ strtoupper($appName) }}</h1>
        <div class="divider"></div>
        <div class="bold">RETAIL INVOICE</div>
    </div>

    <div class="row">
        <span class="label">Order ID:</span>
        <span class="value bold">{{ $order->order_number }}</span>
    </div>
    <div class="row">
        <span class="label">Date:</span>
        <span class="value">{{ \Carbon\Carbon::parse($order->created_at)->format('d M Y, h:i A') }}</span>
    </div>
    <div class="row">
        <span class="label">Status:</span>
        <span class="value">{{ $order->status_name }}</span>
    </div>
    <div class="row">
        <span class="label">Payment:</span>
        <span class="value">{{ $order->payment_method }}</span>
    </div>

    <div class="divider"></div>

    <div class="section-title">Customer Details</div>
    <div class="bold">{{ $order->user_name }}</div>
    <div>{{ $order->user_mobile }}</div>
    @if($order->user_email)
        <div>{{ $order->user_email }}</div>
    @endif

    <div class="section-title">Delivery Address</div>
    <div>{{ $order->order_address }}</div>

    @if($delivery_boy_details)
        <div style="margin-top: 5px;">
            <span class="bold">Driver:</span> {{ $delivery_boy_details['name'] }}
        </div>
    @endif

    <div class="divider"></div>

    <div class="section-title">Order Items</div>
    
    @foreach($store_wise_items as $store)
        <div class="store-name">{{ $store['store_name'] }}</div>
        <table class="item-table">
            <thead>
                <tr>
                    <th width="60%">Item</th>
                    <th width="15%" class="text-right">Qty</th>
                    <th width="25%" class="text-right">Price</th>
                </tr>
            </thead>
            <tbody>
                @php $storeTotal = 0; @endphp
                @foreach($store['items'] as $item)
                    <tr>
                        <td>
                            {{ $item['product_name'] }}
                            @if($item['variant_measurement'])
                                <div style="font-size: 9px; color: #555;">({{ $item['variant_measurement'] }})</div>
                            @endif
                        </td>
                        <td class="text-right">{{ $item['quantity'] }}</td>
                        <td class="text-right">{{ $currency }}{{ number_format($item['sub_total'], 2) }}</td>
                    </tr>
                    @php $storeTotal += $item['sub_total']; @endphp
                @endforeach
            </tbody>
            <tfoot>
                <tr>
                    <td colspan="2" class="text-right italic">Store Subtotal:</td>
                    <td class="text-right bold">{{ $currency }}{{ number_format($storeTotal, 2) }}</td>
                </tr>
            </tfoot>
        </table>
    @endforeach

    @if(count($combo_items) > 0)
        <div class="section-title">Combo Packs</div>
        <table class="item-table">
            <tbody>
                @foreach($combo_items as $combo)
                    <tr>
                        <td width="75%">
                            <div class="bold">{{ $combo['combo_name'] }}</div>
                            @foreach($combo['products'] as $cp)
                                <div style="font-size: 9px; margin-left: 10px;">- {{ $cp['product_name'] }} x {{ $cp['quantity'] }}</div>
                            @endforeach
                        </td>
                        <td width="25%" class="text-right bold">
                            {{ $currency }}{{ number_format($combo['sub_total'], 2) }}
                        </td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    @endif

    <div class="divider"></div>

    <div class="section-title">Billing Summary</div>
    
    @if($billingSummary)
        <div class="row">
            <span class="label">Items Subtotal:</span>
            <span class="value">{{ $currency }}{{ number_format($billingSummary['items_mrp'] ?? $order->total, 2) }}</span>
        </div>
        
        @if(($billingSummary['combo_mrp'] ?? 0) != 0)
        <div class="row">
            <span class="label">Combos Subtotal:</span>
            <span class="value">{{ $currency }}{{ number_format($billingSummary['combo_mrp'], 2) }}</span>
        </div>
        @endif

        @if(($billingSummary['discount'] ?? 0) != 0)
        <div class="row">
            <span class="label">Discount:</span>
            <span class="value">- {{ $currency }}{{ number_format($billingSummary['discount'], 2) }}</span>
        </div>
        @endif

        @if(($billingSummary['delivery_charge'] ?? 0) != 0)
        <div class="row">
            <span class="label">Delivery Charge:</span>
            <span class="value">{{ $currency }}{{ number_format($billingSummary['delivery_charge'], 2) }}</span>
        </div>
        @endif

        @if(($billingSummary['delivery_tip'] ?? 0) != 0)
        <div class="row">
            <span class="label">Delivery Tip:</span>
            <span class="value">{{ $currency }}{{ number_format($billingSummary['delivery_tip'], 2) }}</span>
        </div>
        @endif

        @if(($billingSummary['rain_surcharge'] ?? 0) != 0)
        <div class="row">
            <span class="label">Rain Surcharge:</span>
            <span class="value">{{ $currency }}{{ number_format($billingSummary['rain_surcharge'], 2) }}</span>
        </div>
        @endif

        @php
            $multiOrderVal = $billingSummary['multi_order_charges'] ?? $billingSummary['multi_order_charge'] ?? 0;
        @endphp
        @if($multiOrderVal != 0)
        <div class="row">
            <span class="label">Multi Order Charge:</span>
            <span class="value">{{ $currency }}{{ number_format($multiOrderVal, 2) }}</span>
        </div>
        @endif

        @if(($billingSummary['gst_charges'] ?? 0) != 0)
        <div class="row">
            <span class="label">GST/Taxes:</span>
            <span class="value">{{ $currency }}{{ number_format($billingSummary['gst_charges'], 2) }}</span>
        </div>
        @endif

        @if(($billingSummary['additional_charges'] ?? 0) != 0)
        <div class="row">
            <span class="label">Additional Charges:</span>
            <span class="value">{{ $currency }}{{ number_format($billingSummary['additional_charges'], 2) }}</span>
        </div>
        @endif

        @if(($billingSummary['promocode_discount'] ?? 0) != 0)
        <div class="row">
            <span class="label">Promo Discount:</span>
            <span class="value">- {{ $currency }}{{ number_format($billingSummary['promocode_discount'], 2) }}</span>
        </div>
        @endif

        @if(($billingSummary['claimable_milestone_amount'] ?? 0) != 0)
        <div class="row">
            <span class="label">Milestone Reward:</span>
            <span class="value">- {{ $currency }}{{ number_format($billingSummary['claimable_milestone_amount'], 2) }}</span>
        </div>
        @endif

        @php
            $walletVal = $billingSummary['wallet_deduction'] ?? $billingSummary['wallet_used'] ?? 0;
        @endphp
        @if($walletVal != 0)
        <div class="row">
            <span class="label">Wallet Used:</span>
            <span class="value">- {{ $currency }}{{ number_format($walletVal, 2) }}</span>
        </div>
        @endif

        <div class="double-divider"></div>
        <div class="row bold" style="font-size: 14px;">
            <span class="label">TOTAL AMOUNT:</span>
            <span class="value">{{ $currency }}{{ number_format($billingSummary['to_be_paid'] ?? $order->remaining_final, 2) }}</span>
        </div>
    @else
        {{-- Fallback billing summary --}}
        <div class="row">
            <span class="label">Subtotal:</span>
            <span class="value">{{ $currency }}{{ number_format($order->total, 2) }}</span>
        </div>
        <div class="row">
            <span class="label">Delivery Charge:</span>
            <span class="value">{{ $currency }}{{ number_format($order->delivery_charge, 2) }}</span>
        </div>
        <div class="row">
            <span class="label">Discount:</span>
            <span class="value">- {{ $currency }}{{ number_format(($order->total * ($order->discount / 100)), 2) }}</span>
        </div>
        <div class="row">
            <span class="label">Promo Discount:</span>
            <span class="value">- {{ $currency }}{{ number_format($order->promo_discount, 2) }}</span>
        </div>
        <div class="row">
            <span class="label">Wallet Used:</span>
            <span class="value">- {{ $currency }}{{ number_format($order->wallet_balance, 2) }}</span>
        </div>
        <div class="double-divider"></div>
        <div class="row bold" style="font-size: 14px;">
            <span class="label">TOTAL AMOUNT:</span>
            <span class="value">{{ $currency }}{{ number_format($order->remaining_final, 2) }}</span>
        </div>
    @endif

    @if($deliveryInstructions)
        <div class="divider"></div>
        <div class="section-title">Delivery Instructions</div>
        <div style="font-style: italic;">{{ $deliveryInstructions }}</div>
    @endif

    <div class="footer">
        <div class="divider"></div>
        <p>Thank you for choosing {{ $appName }}!</p>
        <p>For support: {{ $supportNumber }} | {{ $supportEmail }}</p>
        <p>Visit us at: www.zenfoo.in</p>
    </div>
</body>
</html>
