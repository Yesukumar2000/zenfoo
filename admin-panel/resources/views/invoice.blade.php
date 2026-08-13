@php
    $appName = \App\Models\Setting::get_value('app_name');
    if($appName == "" || $appName == null){
        $appName = "eGrocer";
    }

    $supportEmail = \App\Models\Setting::get_value('support_email');
    if($supportEmail == "" || $supportEmail == null){
        $supportEmail = "";
    }
    $supportNumber = \App\Models\Setting::get_value('support_number');
    if($supportNumber == "" || $supportNumber == null){
        $supportNumber = "";
    }
    $logo = \App\Models\Setting::get_value('logo');
    $currency = \App\Models\Setting::get_value('currency') ?? '$';
@endphp

@if(\Request::route()->getName() == "customerInvoice")
<html>
    <head>
        <title>Invoice Order - {{ $appName }}</title>
        <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700&display=swap" rel="stylesheet">
        <link rel="stylesheet" href="{{ asset('assets/css/bootstrap.css')}}">
        <link rel="stylesheet" href="{{ asset('assets/css/custom/common.css') }}">
        <style>
            body {
                font-family: 'Nunito', sans-serif;
            }
        </style>
    </head>
    <body>
@endif
<style>
    address {
        margin-bottom: 1px;
        font-style: normal;
        line-height: 1.42857143;
    }
    p {
        margin: 0 0 0px;
    }
    .invoice {
        position: relative;
        background: #fff;
        border: 1px solid #f4f4f4;
        padding: 20px;
        margin: 10px 25px
    }
    .well {
        min-height: 20px;
        padding: 19px;
        margin-bottom: 20px;
        background-color: #f5f5f5;
        border: 1px solid #e3e3e3;
        border-radius: 4px;
        -webkit-box-shadow: inset 0 1px 1px rgba(0, 0, 0, .05);
        box-shadow: inset 0 1px 1px rgba(0, 0, 0, .05)
    }

    @media only screen and (max-width: 600px) {
        .invoice {
            padding: 0px !important;
            margin: 0px  !important;
        }
    }
</style>
<section class="invoice " id="printMe">

    <div class="d-flex justify-content-between align-items-center flex-wrap">
        <h5 class="page-header">{{ $appName }}</h5>
        <h5 class="page-header">Mo. {{ $supportNumber }}</h5>
    </div>
    <hr>
    <div class="d-flex justify-content-between align-items-center flex-wrap">
        <div class="invoice-col">
            From
            <address>
                <strong>{{ $appName }}</strong>
            </address>
            <address>
                Email: {{ $supportEmail }}<br>
            </address>
            <address>
                Customer Care : {{ $supportNumber }}
            </address>
            @if($order->order_type == 'doorstep')
            <address>
                Delivery By: {{ $order->delivery_boy_name ?? "" }}
            </address>
            @endif
        </div>
        <div class="invoice-col">
            @if($order->order_type == 'doorstep')
            Shipping Address
            @else
            Customer Details
            @endif
            <address>
                <strong>{{ $order->user_name ?? "" }}</strong>
            </address>
            @if($order->order_type == 'doorstep')
            <address>
                {{ $order->order_address ?? "" }}<br>
            </address>
            @endif
            <address>
                <strong>{{ $order->order_mobile }} / {{ $order->alternate_mobile }} </strong><br>
            </address>
            <address>
                <strong>{{ $order->user_email }}</strong><br>
            </address>
        </div>
        <div class=" invoice-col">
            Retail Invoice
            <address>
                <b>No : </b>#{{ $order->order_item_id }}
            </address>
            <address>
                <b>Date: </b>{{ \Carbon\Carbon::parse($order->orders_created_at)->format('d-m-y h:i A') }}
            </address>
        </div>
    </div>
    <hr>
    <div class="row">
        <div class="col-md-12">
            <div class="well">
                <div class="row"><strong>Items: {{ count($order_items) }}@if(isset($combo_items) && count($combo_items) > 0) | Combos: {{ count($combo_items) }}@endif</strong></div>
                <div class="d-flex justify-content-between align-items-center">
                    <div class="col-md-4">
                        <p>Sold By</p>
                        <strong>{{ $order->store_name }}</strong>
                        <p>Name: {{ $order->seller_name }}</p>
                        <p>Email: {{ $order->seller_email }}</p>
                        <p>Mobile No. : {{ $order->seller_mobile }}</p>
                    </div>
                    @if($order->order_type == 'doorstep')
                    <div class="col-md-3">
                        <strong>
                            <p>Pan Number : {{ $order->pan_number }}</p>
                            <p>{{ $order->tax_name }} : {{ $order->tax_number }}</p>
                        </strong>
                        @if($order->delivery_boy_name)
                            <p>Delivery By : {{ $order->delivery_boy_name ?? "" }}</p>
                        @else
                            <p>Delivery By : Not Assigned</p>
                        @endif
                    </div>
                    @else
                    <div class="col-md-3">
                        <strong>
                            <p>Pickup Store: {{ $order->seller_name ?? "" }}</p>
                        </strong>
                        <p>Pickup Address: 
                            @php
                                $pickupAddress = $order->pickup_address ?? [];
                                if (is_string($pickupAddress)) {
                                    $pickupAddress = json_decode($pickupAddress, true) ?? [];
                                }
                                if (is_array($pickupAddress) && !empty($pickupAddress['pickup_store_address'])) {
                                    echo $pickupAddress['pickup_store_address'];
                                } else {
                                    echo 'Not specified';
                                }
                            @endphp
                        </p>
                        <p>Pickup Store Timings: 
                            @php
                                $pickupAddress = $order->pickup_address ?? [];
                                if (is_string($pickupAddress)) {
                                    $pickupAddress = json_decode($pickupAddress, true) ?? [];
                                }
                                if (is_array($pickupAddress) && !empty($pickupAddress['opening_time']) && !empty($pickupAddress['closing_time'])) {
                                    echo $pickupAddress['opening_time'] . ' - ' . $pickupAddress['closing_time'];
                                } else {
                                    echo 'Not specified';
                                }
                            @endphp
                        </p>
                    </div>
                    @endif
                </div>
                <hr>
                <div class="row">
                    <p class="h6 ">Product Details:</p>
                    <div class="row">
                        <div class="col-xs-12 table-responsive">
                            <table class="table table-responsive">
                                <thead class="text-center">
                                <tr>
                                    <th>Sr No.</th>
                                    <th>Name</th>
                                    <th>Unit</th>
                                    <th>Price</th>
                                    <th>Tax {{ $currency }} (%)</th>
                                    <th>Qty</th>
                                    <th>SubTotal ( {{ $currency }} )</th>
                                </tr>
                                </thead>
                                <tbody class="text-center">
                                @php
                                    $total_tax_amount = 0;
                                    $total_quantity = 0;
                                    $total_sub_total = 0;
                                @endphp
                                @foreach($order_items as $index => $item)
                                    <tr>
                                        <td>{{ $index+1 }}<br></td>
                                        <td>{{ $item->product_name }}<br></td>
                                        <td>{{ $item->variant_name }}<br></td>
                                        <td>{{ ($item->discounted_price != 0 && $item->discounted_price != "") ? $item->discounted_price : $item->price }}</td>
                                        <td>{{ $item->tax_amount. "  (" .$item->tax_percentage."%)" }}<br></td>
                                        <td>{{ $item->quantity }}<br></td>
                                        <td>{{ $item->sub_total }}<br></td>
                                        @php
                                            $total_tax_amount = $total_tax_amount + $item->tax_amount;
                                            $total_quantity = $total_quantity + $item->quantity;
                                            $total_sub_total = $total_sub_total + $item->sub_total;
                                        @endphp
                                    </tr>
                                @endforeach
                                </tbody>
                                <tfoot class="text-center">
                                <tr>
                                    <th></th>
                                    <th></th>
                                    <th></th>
                                    <th>Total</th>
                                    <td>{{ $total_tax_amount }}<br></td>
                                    <td>{{ $total_quantity }}<br></td>
                                    <td>{{ $total_sub_total }}<br></td>
                                </tr>
                                </tfoot>
                            </table>
                        </div>
                    </div>

                    @if(isset($combo_items) && count($combo_items) > 0)
                    <hr>
                    <div class="row mt-3">
                        <p class="h6">Combo Details:</p>
                        <div class="row">
                            <div class="col-xs-12 table-responsive">
                                <table class="table table-responsive">
                                    <thead class="text-center">
                                    <tr>
                                        <th>Sr No.</th>
                                        <th>Combo Name</th>
                                        <th>Products</th>
                                        <th>MRP ({{ $currency }})</th>
                                        <th>Selling Price ({{ $currency }})</th>
                                        <th>Discount %</th>
                                        <th>SubTotal ({{ $currency }})</th>
                                    </tr>
                                    </thead>
                                    <tbody class="text-center">
                                    @php
                                        $combo_total = 0;
                                    @endphp
                                    @foreach($combo_items as $combo_index => $combo_item)
                                        <tr>
                                            <td>{{ $combo_index + 1 }}<br></td>
                                            <td>{{ $combo_item->combo_name }}<br></td>
                                            <td>
                                                @php
                                                    $products = is_string($combo_item->products)
                                                        ? json_decode($combo_item->products, true)
                                                        : $combo_item->products;
                                                    if (is_array($products)) {
                                                        echo count($products) . ' items';
                                                    }
                                                @endphp
                                            </td>
                                            <td>{{ number_format($combo_item->total_actual_price, 2) }}</td>
                                            <td>{{ number_format($combo_item->total_products_price, 2) }}</td>
                                            <td>{{ number_format($combo_item->discount_percentage, 2) }}%<br></td>
                                            <td>{{ number_format($combo_item->sub_total, 2) }}<br></td>
                                            @php
                                                $combo_total += $combo_item->sub_total;
                                            @endphp
                                        </tr>
                                    @endforeach
                                    </tbody>
                                    <tfoot class="text-center">
                                    <tr>
                                        <th></th>
                                        <th></th>
                                        <th></th>
                                        <th></th>
                                        <th></th>
                                        <th>Total</th>
                                        <td>{{ number_format($combo_total, 2) }}<br></td>
                                    </tr>
                                    </tfoot>
                                </table>
                            </div>
                        </div>
                    </div>
                    @endif
                </div>
            </div>
        </div>
    </div>
    <div class="d-flex justify-content-between">
        <p><b>Payment Method : </b> {{ strtoupper($order->payment_method) }}</p>
        <!--accepted payments column
        <div class="col-xs-6 col-xs-offset-6">
        <p class="lead">Payment Date: </p>-->
        <div class="table-responsive">
            <table>
                <tbody>
                    <tr>
                        <th>Total Order Price ({{ $currency }})</th>
                        <td>{{ $order->remaining_total }}</td>
                    </tr>
                    @if($order->order_type == 'doorstep')
                    <tr>
                        <th>Delivery Charge ({{ $currency }})</th>
                        <td>{{ $order->delivery_charge }}</td>
                    </tr>
                    @endif
                    @if(!empty($order->additional_charges) && is_array($order->additional_charges) && count($order->additional_charges) > 0)
                        @foreach($order->additional_charges as $charge)
                            <tr>
                                <th>{{ $charge['title'] ?? 'Additional Charge' }} ({{ $currency }})</th>
                                <td>{{ floatval($charge['amount'] ?? 0) }}</td>
                            </tr>
                        @endforeach
                    @endif
                    <tr>
                        <th>Discount {{ $currency }} (%)</th>
                        @php
                            $discount_in_rupees = 0;
                            if ( $order->discount > 0) {
                                $discounted_amount = $order->remaining_total * $order->discount / 100;
                                $final_total = $order->remaining_total - $discounted_amount;
                                $discount_in_rupees = $order->remaining_total - $final_total;
                            }
                        @endphp
                        <td>{{ '- ' . $discount_in_rupees . ' (' . $order->discount . '%)'}}</td>
                    </tr>
                    <tr>
                        <th>Promo ({{ $order->promo_code }}) Discount ({{ $currency }})</th>
                        <td>{{ '- ' . $order->promo_discount }}</td>
                    </tr>
                    <tr>
                        <th>Wallet Used ({{ $currency }})</th>
                        <td>{{ '- ' . $order->wallet_balance }}</td>
                    </tr>
                    <tr>
                        <th>Final Total ({{ $currency }})</th>
                        <td>{{ '= ' . $order->remaining_final}}</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</section>
@if(\Request::route()->getName() == "customerInvoice")
    </body>
</html>
@endif
