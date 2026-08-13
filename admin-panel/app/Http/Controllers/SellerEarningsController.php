<?php

namespace App\Http\Controllers;

use App\Models\Seller;
use App\Models\SellerWalletTransaction;
use App\Helpers\CommonHelper;
use Illuminate\Http\Request;
use Carbon\Carbon;

class SellerEarningsController extends Controller
{
    /**
     * Get seller earnings data grouped by time periods
     */
    public function getSellerEarnings(Request $request)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = Seller::where('admin_id', $admin->id)->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        // Get optional status filter
        $statusFilter = $request->input('status'); // 'delivered', 'cancelled', 'returned', etc.

        // Get earnings data for each period
        $todayData = $this->getTodayEarnings($seller->id, $statusFilter);
        $weeklyData = $this->getWeeklyEarnings($seller->id, $statusFilter);
        $monthlyData = $this->getMonthlyEarnings($seller->id, $statusFilter);
        $yearlyData = $this->getYearlyEarnings($seller->id, $statusFilter);
        $totalData = $this->getTotalEarnings($seller->id, $statusFilter);

        return response()->json([
            'status' => 1,
            'message' => 'Seller earnings fetched successfully',
            'data' => [
                'today' => $todayData ?? null,
                'weekly' => $weeklyData,
                'monthly' => $monthlyData,
                'yearly' => $yearlyData,
                'total' => $totalData,
            ]
        ]);
    }

    /**
     * Get today's earnings (from start of today to now)
     */
    private function getTodayEarnings($sellerId, $statusFilter = null)
    {
        $now = Carbon::now();
        $startOfDay = $now->copy()->startOfDay();

        $transactions = $this->getTransactionsForPeriod($sellerId, $startOfDay, $now, $statusFilter);
        $totalAmount = $transactions->sum('amount');

        return [
            [
                'date_range' => $now->format('d M Y'),
                'total_amount' => (float) $totalAmount,
                'transactions' => $transactions->toArray(),
            ]
        ];
    }

    /**
     * Get weekly earnings from seller registration to current date
     */
    private function getWeeklyEarnings($sellerId, $statusFilter = null)
    {
        $earnings = [];
        $seller = Seller::find($sellerId);

        if (!$seller) {
            return [];
        }

        $sellerCreatedDate = Carbon::parse($seller->created_at);
        $now = Carbon::now();

        // Start from current week and go backwards to seller creation week
        $currentWeekEnd = $now->copy();
        $currentWeekStart = $now->copy()->startOfWeek();

        // Continue while the week end is after or equal to seller creation date
        while ($currentWeekEnd->gte($sellerCreatedDate)) {
            $transactions = $this->getTransactionsForPeriod($sellerId, $currentWeekStart, $currentWeekEnd, $statusFilter);
            $totalAmount = $transactions->sum('amount');

            $earnings[] = [
                'date_range' => $currentWeekStart->format('d M Y') . ' - ' . $currentWeekEnd->format('d M Y'),
                'total_amount' => (float) $totalAmount,
                'transactions' => $transactions->toArray(),
            ];

            // Move to previous week
            $currentWeekEnd = $currentWeekStart->copy()->subDay();
            $currentWeekStart = $currentWeekEnd->copy()->startOfWeek();
        }

        return $earnings;
    }

    /**
     * Get monthly earnings from seller registration to current date
     */
    private function getMonthlyEarnings($sellerId, $statusFilter = null)
    {
        $earnings = [];
        $seller = Seller::find($sellerId);

        if (!$seller) {
            return [];
        }

        $sellerCreatedDate = Carbon::parse($seller->created_at);
        $now = Carbon::now();

        // Start from current month and go backwards to seller creation month
        $currentMonthEnd = $now->copy();
        $currentMonthStart = $now->copy()->startOfMonth();

        // Continue while the month end is after or equal to seller creation date
        while ($currentMonthEnd->gte($sellerCreatedDate)) {
            $transactions = $this->getTransactionsForPeriod($sellerId, $currentMonthStart, $currentMonthEnd, $statusFilter);
            $totalAmount = $transactions->sum('amount');

            $earnings[] = [
                'date_range' => $currentMonthStart->format('M Y'),
                'total_amount' => (float) $totalAmount,
                'transactions' => $transactions->toArray(),
            ];

            // Move to previous month
            $currentMonthEnd = $currentMonthStart->copy()->subDay();
            $currentMonthStart = $currentMonthEnd->copy()->startOfMonth();
        }

        return $earnings;
    }

    /**
     * Get yearly earnings from seller registration to current date
     */
    private function getYearlyEarnings($sellerId, $statusFilter = null)
    {
        $earnings = [];
        $seller = Seller::find($sellerId);

        if (!$seller) {
            return [];
        }

        $sellerCreatedDate = Carbon::parse($seller->created_at);
        $now = Carbon::now();

        // Start from current year and go backwards to seller creation year
        $currentYear = $now->year;
        $sellerCreationYear = $sellerCreatedDate->year;

        for ($year = $currentYear; $year >= $sellerCreationYear; $year--) {
            $yearStart = Carbon::create($year, 1, 1)->startOfYear();
            $yearEnd = Carbon::create($year, 12, 31)->endOfYear();

            // Adjust start date if it's the seller's creation year
            if ($year == $sellerCreationYear) {
                $yearStart = $sellerCreatedDate;
            }

            // Adjust end date if it's the current year
            if ($year == $currentYear) {
                $yearEnd = $now;
            }

            $transactions = $this->getTransactionsForPeriod($sellerId, $yearStart, $yearEnd, $statusFilter);
            $totalAmount = $transactions->sum('amount');

            $earnings[] = [
                'date_range' => (string) $year,
                'total_amount' => (float) $totalAmount,
                'transactions' => $transactions->toArray(),
            ];
        }

        return $earnings;
    }

    /**
     * Get total earnings (all time from seller registration, grouped by year)
     */
    private function getTotalEarnings($sellerId, $statusFilter = null)
    {
        $earnings = [];
        $seller = Seller::find($sellerId);

        if (!$seller) {
            return [];
        }

        $sellerCreatedDate = Carbon::parse($seller->created_at);
        $now = Carbon::now();

        $startYear = $sellerCreatedDate->year;
        $currentYear = $now->year;

        for ($year = $currentYear; $year >= $startYear; $year--) {
            $yearStart = Carbon::create($year, 1, 1)->startOfYear();
            $yearEnd = Carbon::create($year, 12, 31)->endOfYear();

            // Adjust start date if it's the seller's creation year
            if ($year == $startYear) {
                $yearStart = $sellerCreatedDate;
            }

            // Adjust end date if it's the current year
            if ($year == $currentYear) {
                $yearEnd = $now;
            }

            $transactions = $this->getTransactionsForPeriod($sellerId, $yearStart, $yearEnd, $statusFilter);
            $totalAmount = $transactions->sum('amount');

            // Include all years from seller registration, even if no earnings
            $earnings[] = [
                'date_range' => (string) $year,
                'total_amount' => (float) $totalAmount,
                'transactions' => $transactions->toArray(),
            ];
        }

        return $earnings;
    }

    /**
     * Get transactions for a specific time period from seller_wallet_transactions table
     */
    private function getTransactionsForPeriod($sellerId, $startDate, $endDate, $statusFilter = null)
    {
        // Map status filter to status ID
        $statusMap = [
            // 'payment_pending' => 1,
            'received' => 2,
            'processed' => 3,
            'shipped' => 4,
            'out_for_delivery' => 5,
            'delivered' => 6,
            'completed' => 6, // Alias for delivered
            'cancelled' => 7,
            'returned' => 8,
        ];

        // Get wallet transactions for this seller within the date range
        $query = SellerWalletTransaction::where('seller_id', $sellerId)
            ->whereIn('type', [SellerWalletTransaction::TYPE_ORDER_COMMISSION])
            ->whereBetween('created_at', [$startDate, $endDate])
            ->with(['order']);

        // Apply status filter if provided
        if ($statusFilter && isset($statusMap[$statusFilter])) {
            $filterStatusId = $statusMap[$statusFilter];
            $query->whereHas('order', function($q) use ($filterStatusId) {
                $q->where('active_status', $filterStatusId);
            });
        }

        $walletTransactions = $query->orderBy('created_at', 'desc')->get();

        // Group by order_id and calculate totals
        $transactions = $walletTransactions->groupBy('order_id')->map(function($items, $orderId) {
            $firstItem = $items->first();
            $order = $firstItem->order;

            if (!$order) {
                return null; // Skip if order not found
            }

            // Calculate total amount from wallet transactions (already commission-deducted)
            $totalAmount = $items->sum('amount');

            // Get order status
            $statusId = (int) $order->active_status;
            $statusName = $this->getStatusName($statusId);
            $statusColor = $this->getStatusColor($statusId);

            // Build products array from products_json in wallet transactions
            $products = [];
            foreach ($items as $transaction) {
                $productsJson = $transaction->products_json;
                if (!empty($productsJson) && is_array($productsJson)) {
                    foreach ($productsJson as $p) {
                        // Get measurement from product variant
                        $weight = '';
                        $variantId = $p['product_variant_id'] ?? null;
                        if ($variantId) {
                            $variant = \App\Models\ProductVariant::with('stockUnit')->find($variantId);
                            if ($variant) {
                                $weight = $variant->measurement . ' ' . ($variant->stockUnit->short_code ?? '');
                            }
                        }

                        $products[] = [
                            'name' => $p['product_name'] ?? 'Unknown Product',
                            'quantity' => ($p['quantity'] ?? 1) . 'X',
                            'weight' => trim($weight),
                            'price' => number_format($p['total_amount'] ?? 0, 2),
                            'earned_amount' => number_format($p['seller_amount'] ?? 0, 2),
                        ];
                    }
                }
            }

            // Build settlement_info from transaction data
            $totalProductAmount = 0;
            $totalCommission = 0;
            $totalGst = 0;
            $totalPaymentGatewayFees = 0;
            $totalVendorWaitCharge = 0;
            $gstPercentage = 0;
            $commissionPercentage = 0;
            $isPaid = false;

            foreach ($items as $transaction) {
                $totalCommission += floatval($transaction->admin_commission ?? 0);
                $gstPercentage = floatval($transaction->gst_percentage ?? 0);
                $totalPaymentGatewayFees += floatval($transaction->payment_gateway_fees ?? 0);
                $totalVendorWaitCharge += floatval($transaction->vendor_wait_charge ?? 0);
                $isPaid = $isPaid || (bool) $transaction->is_paid_to_seller;

                $productsData = $transaction->products_json;
                if (!empty($productsData) && is_array($productsData)) {
                    foreach ($productsData as $p) {
                        $totalProductAmount += floatval($p['total_amount'] ?? 0);
                        $totalGst += floatval($p['gst'] ?? 0);
                    }
                }
            }

            // Derive the commission percentage from the actually-deducted
            // commission against the actual product total. This always
            // matches what the customer paid on this specific order even
            // if the admin has since changed the Vendor Commission
            // Configurations rate, and avoids the stale-label issue where
            // the legacy $seller->commission column drifts from the
            // category-resolved rate that the settlement service used.
            $commissionPercentage = $totalProductAmount > 0
                ? round(($totalCommission / $totalProductAmount) * 100, 2)
                : 0;

            // Get configured payment gateway fees percentage for label display
            $paymentGatewayFeesPercent = floatval(
                \DB::table('settings')->where('variable', 'payment_gateway_fees')->value('value') ?? 0
            );

            $settlementInfo = [
                ['label' => 'Total Product Amount', 'value' => round($totalProductAmount, 2)],
                ['label' => 'Admin Commission (' . round($commissionPercentage, 2) . '%)', 'value' => round($totalCommission, 2)],
                ['label' => 'GST (' . round($gstPercentage, 2) . '%)', 'value' => round($totalGst, 2)],
                ['label' => 'Payment Gateway Fees (' . round($paymentGatewayFeesPercent, 2) . '%)', 'value' => round($totalPaymentGatewayFees, 2)],
            ];

            if ($totalVendorWaitCharge > 0) {
                $settlementInfo[] = [
                    'label' => 'Waiting Charge (paid to driver)',
                    'value' => round($totalVendorWaitCharge, 2),
                ];
            }

            $settlementInfo[] = ['label' => 'Net Seller Amount', 'value' => round((float) $totalAmount, 2)];
            $settlementInfo[] = ['label' => 'Payment Status', 'value' => $isPaid ? 'Paid' : 'Pending'];

            return [
                'order_id' => (string) $orderId,
                'date' => $order->created_at->format('d M Y'),
                'amount' => (float) $totalAmount,
                'order_details' => [
                    'id' => '#' . $orderId,
                    'status' => $statusName,
                    'status_color' => $statusColor,
                    'products' => $products,
                    'total_amount' => number_format($totalAmount, 2),
                ],
                'settlement_info' => $settlementInfo,
            ];
        })->filter()->values();

        return $transactions;
    }

    /**
     * Get status name from status ID
     */
    private function getStatusName($statusId)
    {
        $statusNames = [
            1 => 'Payment Pending',
            2 => 'Received',
            3 => 'Processed',
            4 => 'Shipped',
            5 => 'Out for Delivery',
            6 => 'Delivered',
            7 => 'Cancelled',
            8 => 'Returned',
        ];

        return $statusNames[$statusId] ?? 'Unknown';
    }

    /**
     * Get status color from status ID
     */
    private function getStatusColor($statusId)
    {
        $statusColors = [
            1 => 'orange',
            2 => 'blue',
            3 => 'purple',
            4 => 'cyan',
            5 => 'indigo',
            6 => 'green',
            7 => 'red',
            8 => 'amber',
        ];

        return $statusColors[$statusId] ?? 'gray';
    }
}
