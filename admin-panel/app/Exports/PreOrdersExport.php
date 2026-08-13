<?php

namespace App\Exports;

use App\Models\Order;
use Carbon\Carbon;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;
use Illuminate\Http\Request;

class PreOrdersExport implements FromCollection, WithHeadings, WithMapping, WithStyles
{
    protected $request;

    public function __construct(Request $request)
    {
        $this->request = $request;
    }

    public function collection()
    {
        $startDate = $this->request->input('startDate') ? Carbon::parse($this->request->input('startDate'))->startOfDay() : null;
        $endDate = $this->request->input('endDate') ? Carbon::parse($this->request->input('endDate'))->endOfDay() : null;
        $search = $this->request->input('search', '');

        $orders = Order::select(
            'orders.id',
            'orders.mobile',
            'orders.total',
            'orders.delivery_charge',
            'orders.wallet_balance',
            'orders.final_total',
            'orders.payment_method',
            'orders.active_status',
            'orders.preorder_placed_at',
            'orders.preorder_process_date',
            'users.name as user_name'
        )
        ->leftJoin('users', 'orders.user_id', '=', 'users.id')
        ->where('orders.is_preorder', 1);

        // Apply filters
        if ($startDate && $endDate) {
            $orders = $orders->whereBetween('orders.preorder_placed_at', [$startDate, $endDate]);
        }

        if ($this->request->has('status') && $this->request->status != "") {
            $orders = $orders->where('orders.active_status', $this->request->status);
        }

        if ($this->request->has('store_id') && $this->request->store_id != "") {
            $storeId = $this->request->store_id;
            $orders = $orders->whereIn('orders.id', function($query) use ($storeId) {
                $query->select('order_id')
                    ->from('order_seller_status_tracking')
                    ->where('store_id', $storeId);
            });
        }

        if ($search) {
            $orders = $orders->where(function($query) use ($search) {
                $query->where('orders.id', 'like', "%{$search}%")
                    ->orWhere('orders.mobile', 'like', "%{$search}%")
                    ->orWhere('users.name', 'like', "%{$search}%");
            });
        }

        return $orders->orderBy('orders.id', 'DESC')->get();
    }

    public function headings(): array
    {
        return [
            'Order ID',
            'Customer Name',
            'Mobile',
            'Subtotal',
            'Delivery Charge',
            'Wallet Used',
            'Final Total',
            'Payment Method',
            'Status',
            'Placed At',
            'Process Date'
        ];
    }

    public function map($order): array
    {
        $statusMap = [
            12 => 'Preorder Pending',
            2 => 'Processed',
            3 => 'In Progress',
            5 => 'Out For Delivery',
            6 => 'Delivered'
        ];

        return [
            $order->id,
            $order->user_name ?: 'Guest',
            $order->mobile,
            '₹' . number_format($order->total, 2),
            '₹' . number_format($order->delivery_charge, 2),
            '₹' . number_format($order->wallet_balance, 2),
            '₹' . number_format($order->final_total, 2),
            $order->payment_method,
            $statusMap[$order->active_status] ?? 'Status ' . $order->active_status,
            $order->preorder_placed_at ? Carbon::parse($order->preorder_placed_at)->format('d M Y, h:i A') : 'N/A',
            $order->preorder_process_date ? Carbon::parse($order->preorder_process_date)->format('d M Y, h:i A') : 'N/A'
        ];
    }

    public function styles(Worksheet $sheet)
    {
        return [
            1 => ['font' => ['bold' => true]],
        ];
    }
}