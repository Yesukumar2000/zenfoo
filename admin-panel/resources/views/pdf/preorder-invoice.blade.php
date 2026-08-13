<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Pre Order Invoice - #{{ $order->id }}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'DejaVu Sans', sans-serif;
            font-size: 12px;
            color: #333;
            padding: 30px;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 3px solid #3498db;
        }
        .header h1 {
            font-size: 32px;
            color: #2c3e50;
            margin-bottom: 5px;
        }
        .header .subtitle {
            font-size: 16px;
            color: #7f8c8d;
            font-weight: bold;
        }
        .invoice-info {
            display: table;
            width: 100%;
            margin-bottom: 30px;
        }
        .invoice-info-left {
            display: table-cell;
            width: 50%;
            vertical-align: top;
        }
        .invoice-info-right {
            display: table-cell;
            width: 50%;
            vertical-align: top;
            text-align: right;
        }
        .info-section {
            margin-bottom: 15px;
        }
        .info-section h3 {
            font-size: 14px;
            color: #3498db;
            margin-bottom: 8px;
            text-transform: uppercase;
        }
        .info-section p {
            margin-bottom: 4px;
            line-height: 1.5;
        }
        .order-items {
            margin-top: 30px;
        }
        .order-items h3 {
            font-size: 16px;
            color: #2c3e50;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 2px solid #3498db;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
        }
        thead {
            background-color: #34495e;
            color: white;
        }
        th {
            padding: 12px 10px;
            text-align: left;
            font-size: 11px;
            font-weight: bold;
        }
        td {
            padding: 12px 10px;
            border-bottom: 1px solid #ecf0f1;
        }
        tbody tr:hover {
            background-color: #f8f9fa;
        }
        .text-right {
            text-align: right;
        }
        .text-center {
            text-align: center;
        }
        .totals {
            margin-top: 30px;
            float: right;
            width: 300px;
        }
        .totals-row {
            display: table;
            width: 100%;
            padding: 8px 0;
            border-bottom: 1px solid #ecf0f1;
        }
        .totals-row.grand-total {
            border-top: 2px solid #2c3e50;
            border-bottom: 2px solid #2c3e50;
            font-size: 16px;
            font-weight: bold;
            padding: 12px 0;
            background-color: #ecf0f1;
            margin-top: 5px;
        }
        .totals-label {
            display: table-cell;
            width: 60%;
        }
        .totals-value {
            display: table-cell;
            width: 40%;
            text-align: right;
        }
        .footer {
            clear: both;
            margin-top: 50px;
            padding-top: 20px;
            border-top: 2px solid #ecf0f1;
            text-align: center;
            color: #7f8c8d;
        }
        .footer p {
            margin-bottom: 5px;
        }
        .badge {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: bold;
        }
        .badge-warning {
            background-color: #fff3cd;
            color: #856404;
        }
        .badge-success {
            background-color: #d4edda;
            color: #155724;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>ZENFOO</h1>
        <p class="subtitle">PRE ORDER INVOICE</p>
    </div>

    <div class="invoice-info">
        <div class="invoice-info-left">
            <div class="info-section">
                <h3>Order Information</h3>
                <p><strong>Order ID:</strong> #{{ $order->id }}</p>
                <p><strong>Order Type:</strong> Pre Order</p>
                <p><strong>Status:</strong>
                    @if($order->active_status == 12)
                        <span class="badge badge-warning">Preorder Pending</span>
                    @else
                        <span class="badge badge-success">Processed</span>
                    @endif
                </p>
                <p><strong>Payment Method:</strong> {{ $order->payment_method }}</p>
            </div>

            <div class="info-section">
                <h3>Customer Details</h3>
                <p><strong>Name:</strong> {{ $order->user ? $order->user->name : 'Guest' }}</p>
                <p><strong>Mobile:</strong> {{ $order->mobile }}</p>
            </div>
        </div>

        <div class="invoice-info-right">
            <div class="info-section">
                <h3>Dates</h3>
                <p><strong>Placed At:</strong></p>
                <p>{{ $order->preorder_placed_at_formatted }}</p>
                <p style="margin-top: 10px;"><strong>Process Date:</strong></p>
                <p>{{ $order->preorder_process_date_formatted }}</p>
            </div>
        </div>
    </div>

    <div class="order-items">
        <h3>Order Items</h3>
        <table>
            <thead>
                <tr>
                    <th style="width: 50%">Product</th>
                    <th class="text-center" style="width: 15%">Quantity</th>
                    <th class="text-right" style="width: 17.5%">Unit Price</th>
                    <th class="text-right" style="width: 17.5%">Subtotal</th>
                </tr>
            </thead>
            <tbody>
                @if($order->items && count($order->items) > 0)
                    @foreach($order->items as $item)
                        <tr>
                            <td>{{ $item->name ?? $item->product_name }}</td>
                            <td class="text-center">{{ $item->quantity }}</td>
                            <td class="text-right">₹{{ number_format($item->price, 2) }}</td>
                            <td class="text-right"><strong>₹{{ number_format($item->sub_total, 2) }}</strong></td>
                        </tr>
                    @endforeach
                @else
                    <tr>
                        <td colspan="4" class="text-center">No items found</td>
                    </tr>
                @endif
            </tbody>
        </table>
    </div>

    <div class="totals">
        <div class="totals-row">
            <span class="totals-label">Subtotal:</span>
            <span class="totals-value">₹{{ number_format($order->total ?? 0, 2) }}</span>
        </div>
        <div class="totals-row">
            <span class="totals-label">Delivery Charge:</span>
            <span class="totals-value">₹{{ number_format($order->delivery_charge ?? 0, 2) }}</span>
        </div>
        @if($order->wallet_balance && $order->wallet_balance > 0)
            <div class="totals-row">
                <span class="totals-label">Wallet Used:</span>
                <span class="totals-value">-₹{{ number_format($order->wallet_balance, 2) }}</span>
            </div>
        @endif
        <div class="totals-row grand-total">
            <span class="totals-label">GRAND TOTAL:</span>
            <span class="totals-value">₹{{ number_format($order->final_total ?? 0, 2) }}</span>
        </div>
    </div>

    <div class="footer">
        <p><strong>Thank you for your order!</strong></p>
        <p>This is a pre-order invoice. Your order will be processed on the scheduled date.</p>
        <p style="margin-top: 15px; font-size: 10px;">&copy; {{ date('Y') }} Zenfoo. All rights reserved.</p>
    </div>
</body>
</html>