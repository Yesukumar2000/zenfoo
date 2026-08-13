<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Pre Orders List - {{ $date }}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'DejaVu Sans', sans-serif;
            font-size: 10px;
            color: #333;
            padding: 20px;
        }
        .header {
            text-align: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #333;
        }
        .header h1 {
            font-size: 24px;
            color: #2c3e50;
            margin-bottom: 5px;
        }
        .header p {
            font-size: 12px;
            color: #7f8c8d;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        thead {
            background-color: #34495e;
            color: white;
        }
        th {
            padding: 8px 5px;
            text-align: left;
            font-size: 9px;
            font-weight: bold;
        }
        td {
            padding: 8px 5px;
            border-bottom: 1px solid #ddd;
            font-size: 9px;
        }
        tbody tr:nth-child(even) {
            background-color: #f8f9fa;
        }
        .text-right {
            text-align: right;
        }
        .text-center {
            text-align: center;
        }
        .status-badge {
            padding: 3px 6px;
            border-radius: 3px;
            font-size: 8px;
            font-weight: bold;
        }
        .status-pending {
            background-color: #fff3cd;
            color: #856404;
        }
        .status-processed {
            background-color: #d4edda;
            color: #155724;
        }
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 9px;
            color: #7f8c8d;
            padding-top: 10px;
            border-top: 1px solid #ddd;
        }
        .summary {
            margin-top: 20px;
            padding: 15px;
            background-color: #ecf0f1;
            border-radius: 5px;
        }
        .summary-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 8px;
            font-size: 11px;
        }
        .summary-row strong {
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>ZENFOO - PRE ORDERS</h1>
        <p>Generated on {{ $date }}</p>
    </div>

    <table>
        <thead>
            <tr>
                <th>Order ID</th>
                <th>Customer</th>
                <th>Mobile</th>
                <th class="text-right">Amount</th>
                <th>Payment</th>
                <th>Placed At</th>
                <th>Process Date</th>
                <th class="text-center">Status</th>
            </tr>
        </thead>
        <tbody>
            @php
                $totalAmount = 0;
            @endphp
            @foreach($orders as $order)
                @php
                    $totalAmount += $order->final_total;
                @endphp
                <tr>
                    <td><strong>#{{ $order->id }}</strong></td>
                    <td>{{ $order->user_name ?: 'Guest' }}</td>
                    <td>{{ $order->mobile }}</td>
                    <td class="text-right"><strong>₹{{ number_format($order->final_total, 2) }}</strong></td>
                    <td>{{ $order->payment_method }}</td>
                    <td>{{ $order->preorder_placed_at_formatted }}</td>
                    <td>{{ $order->preorder_process_date_formatted }}</td>
                    <td class="text-center">
                        @if($order->active_status == 12)
                            <span class="status-badge status-pending">Pending</span>
                        @else
                            <span class="status-badge status-processed">Processed</span>
                        @endif
                    </td>
                </tr>
            @endforeach
        </tbody>
    </table>

    <div class="summary">
        <div class="summary-row">
            <span>Total Orders:</span>
            <strong>{{ count($orders) }}</strong>
        </div>
        <div class="summary-row">
            <span>Total Amount:</span>
            <strong>₹{{ number_format($totalAmount, 2) }}</strong>
        </div>
        <div class="summary-row">
            <span>Average Order Value:</span>
            <strong>₹{{ count($orders) > 0 ? number_format($totalAmount / count($orders), 2) : '0.00' }}</strong>
        </div>
    </div>

    <div class="footer">
        <p>This is a computer-generated document. No signature is required.</p>
        <p>&copy; {{ date('Y') }} Zenfoo. All rights reserved.</p>
    </div>
</body>
</html>