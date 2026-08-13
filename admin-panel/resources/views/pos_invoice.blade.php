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
    $currency = \App\Models\Setting::get_value('currency') ?? '$';
@endphp

<html>
    <head>
        <title>POS Invoice - {{ $appName }}</title>
        <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700&display=swap" rel="stylesheet">
        <link rel="stylesheet" href="{{ asset('assets/css/bootstrap.css')}}">
        <link rel="stylesheet" href="{{ asset('assets/css/custom/common.css') }}">
        <style>
            body {
                font-family: 'Nunito', sans-serif;
            }
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
            
            @media print {
                .no-print {
                    display: none;
                }
                .invoice {
                    border: none;
                    padding: 10px;
                    margin: 0;
                }
            }

            /* For iframe mode */
            .in-iframe .invoice {
                margin: 0;
                padding: 10px;
                border: none;
            }
        </style>
    </head>
    <body>
        <div class="container-fluid">
            <section class="invoice" id="printMe">
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
                    </div>
                    <div class="invoice-col">
                        Customer Details
                        <address>
                            <strong>{{ $order->user_name ?? "Cash Sale" }}</strong>
                        </address>
                        @if(isset($order->user_email))
                        <address>
                            Email: {{ $order->user_email }}<br>
                        </address>
                        @endif
                        @if(isset($order->mobile))
                        <address>
                            Mobile: {{ $order->mobile }}<br>
                        </address>
                        @endif
                    </div>
                </div>
                <hr>
                <div class="row">
                    <div class="col-md-12">
                        <div class="well">
                            {{-- <div class="row"><strong>Items: {{ count($order_items) }}</strong></div> --}}
                            <div class="d-flex justify-content-between align-items-center">
                                <div class="col-md-4">
                                    <p>Sold By</p>
                                    <strong>{{ $order->store_name ?? 'Store' }}</strong>
                                    @if(isset($order->seller_email))
                                    <p>Email: {{ $order->seller_email }}</p>
                                    @endif
                                    @if(isset($order->seller_mobile))
                                    <p>Mobile No. : {{ $order->seller_mobile }}</p>
                                    @endif
                                </div>
                                <div class="invoice-col">
                                    Invoice
                                   <address>
                                       <b>No : </b>#{{ $order->id }}
                                   </address>
                                   <address>
                                       <b>Date: </b>{{ \Carbon\Carbon::parse($order->created_at)->format('d-m-y h:i A') }}
                                   </address>
                               </div>
                            </div>
                            <hr>
                            <div class="row">
                                <p class="h6">Product Details:</p>
                                <div class="row">
                                    <div class="col-xs-12 table-responsive">
                                        <table class="table table-bordered">
                                            <thead class="text-center">
                                            <tr>
                                                <th>Sr No.</th>
                                                <th>Name</th>
                                                <th>Unit</th>
                                                <th>Price</th>
                                                <th>Qty</th>
                                                <th>SubTotal ({{ $currency }})</th>
                                            </tr>
                                            </thead>
                                            <tbody class="text-center">
                                            @php
                                                $total_quantity = 0;
                                                $total_sub_total = 0;
                                            @endphp
                                            @foreach($order_items as $index => $item)
                                                <tr>
                                                    <td>{{ $index+1 }}</td>
                                                    <td>{{ $item->product_name }}</td>
                                                    <td>{{ $item->variant_name }}</td>
                                                    <td>{{ $currency }} {{ $item->unit_price }}</td>
                                                    <td>{{ $item->quantity }}</td>
                                                    <td>{{ $currency }} {{ $item->total_price }}</td>
                                                    @php
                                                        $total_quantity += $item->quantity;
                                                        $total_sub_total += $item->total_price;
                                                    @endphp
                                                </tr>
                                            @endforeach
                                            </tbody>
                                            <tfoot class="text-center">
                                            <tr>
                                                <th colspan="4">Total</th>
                                                <td>{{ $total_quantity }}</td>
                                                <td>{{ $currency }} {{ $total_sub_total }}</td>
                                            </tr>
                                            </tfoot>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="d-flex justify-content-between">
                    <p><b>Payment Method : </b> {{ strtoupper($order->payment_method . " payment") }}</p>
                    <div class="table-responsive">
                        <table class="table">
                            <tbody>
                                <tr>
                                    <th>Subtotal ({{ $currency }})</th>
                                    <td>{{ $total_sub_total }}</td>
                                </tr>
                                
                                @if($order->discount_amount > 0 || $order->discount_percentage > 0)
                                <tr>
                                    <th>Discount ({{ $currency }}) 
                                    @if($order->discount_percentage > 0)
                                        ({{ $order->discount_percentage }}%)
                                    @endif
                                    </th>
                                    <td>{{ '- '. $order->discount_amount }}</td>
                                </tr>
                                @endif
                                
                                @if(isset($additional_charges) && count($additional_charges) > 0)
                                    @foreach($additional_charges as $charge)
                                    <tr>
                                        <th>{{ $charge->charge_name }} ({{ $currency }})</th>
                                        <td>{{ $charge->amount }}</td>
                                    </tr>
                                    @endforeach
                                @endif
                                
                                <tr>
                                    <th>Final Total ({{ $currency }})</th>
                                    <td>{{ $order->total_amount }}</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
                
                <hr class="my-4">
                <div class="text-center">
                    <p>Thank you for your purchase!</p>
                </div>
            </section>
        </div>
        
        <script>
            // Print function for manual printing
            function printInvoice() {
                window.print();
            }
        </script>
    </body>
</html> 