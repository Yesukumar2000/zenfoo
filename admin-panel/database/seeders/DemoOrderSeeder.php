<?php

namespace Database\Seeders;

use App\Models\OrderStatusList;
use Database\Seeders\DemoWorld\DemoWorld;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * 90 days of order history for the demo customers.
 *
 * Every order is built from REAL catalogue rows (products + product_variants),
 * so the line items, prices and images on an order detail screen are the same
 * ones the customer app would show. Nothing is invented that the catalogue
 * doesn't already contain.
 *
 * What it produces per order:
 *   orders                     header, address snapshot, totals, status
 *   order_items                one row per variant, seller_id carried through
 *   transactions               a payment row for anything not COD
 *   wallet_transactions        refund rows for cancelled prepaid orders
 *   delivery_boy_transactions  the driver's earning on delivered orders
 *   product_ratings            reviews on ~35% of delivered orders
 *
 * Volume is weighted towards recent days and towards evening slots, so the
 * dashboard's "orders over time" and "peak hours" charts have a believable
 * shape instead of a flat line.
 *
 * Identified by orders_id LIKE 'ZFDEMO%'.
 */
class DemoOrderSeeder extends Seeder
{
    /**
     * Status mix across the 90 days, as weights out of 100.
     *
     * A method rather than a const because OrderStatusList exposes its ids as
     * static properties, which PHP won't evaluate in a constant expression.
     */
    private function statusMix(): array
    {
        return [
            OrderStatusList::$delivered      => 74,
            OrderStatusList::$cancelled      => 9,
            OrderStatusList::$returned       => 3,
            OrderStatusList::$outForDelivery => 5,
            OrderStatusList::$shipped        => 4,
            OrderStatusList::$processed      => 3,
            OrderStatusList::$received       => 2,
        ];
    }

    /** Must match App\Models\Transaction::$paymentType* — the app matches on these strings. */
    private const PAYMENT_METHODS = ['COD', 'COD', 'Razorpay', 'Paytm', 'Phonepe', 'Wallet'];

    public function run(): void
    {
        $customers = DB::table('users')
            ->where('email', 'LIKE', '%@' . DemoWorld::EMAIL_DOMAIN)
            ->get(['id', 'name', 'mobile', 'balance']);

        if ($customers->isEmpty()) {
            $this->command->error('No demo customers found. Run DemoCustomerSeeder first.');
            return;
        }

        $drivers = DB::table('delivery_boys')
            ->where('remark', 'LIKE', DemoWorld::MARKER . '%')
            ->where('status', 1)
            ->pluck('id')->all();

        // Variants joined to their product, so an order line knows its seller
        // and can show a real name. Only in-stock, active products qualify.
        $variants = DB::table('product_variants as v')
            ->join('products as p', 'p.id', '=', 'v.product_id')
            ->whereNull('p.deleted_at')
            ->whereNull('v.deleted_at')
            ->where('p.status', 1)
            ->where('v.price', '>', 0)
            ->select([
                'v.id as variant_id', 'v.type as variant_type', 'v.price', 'v.discounted_price',
                'v.measurement', 'p.id as product_id', 'p.name as product_name',
                'p.seller_id', 'p.store_id', 'p.tax as tax_percent',
            ])
            ->limit(4000)
            ->get();

        if ($variants->isEmpty()) {
            $this->command->error('No sellable product variants found. Seed the catalogue first '
                . '(php artisan db:seed --class=QuickCommerceCatalogSeeder).');
            return;
        }

        // Grouped by seller: a single order should not span five vendors.
        $bySeller = $variants->groupBy(fn ($v) => (int) ($v->seller_id ?: 0))
            ->filter(fn ($g) => $g->count() >= 3);

        if ($bySeller->isEmpty()) {
            $this->command->error('No seller has 3+ variants — cannot build realistic baskets.');
            return;
        }

        $sellerIds = $bySeller->keys()->all();

        // Weight the basket source towards the demo vendors so their seller
        // dashboards, payouts and order lists aren't empty. Real sellers stay
        // in the pool — a demo where every order belongs to a seeded shop looks
        // as wrong as one where none do.
        $demoSellerIds = DB::table('sellers')
            ->where('email', 'LIKE', '%@' . DemoWorld::EMAIL_DOMAIN)
            ->pluck('id')->map(fn ($i) => (int) $i)->all();

        $demoWithStock = array_values(array_intersect($sellerIds, $demoSellerIds));
        if ($demoWithStock) {
            $this->command->line('  ' . count($demoWithStock) . ' demo vendor(s) have stock — ~60% of orders will go to them.');
        }

        $addressByUser = DB::table('user_addresses')
            ->whereIn('user_id', $customers->pluck('id'))
            ->get()->groupBy('user_id');

        $counts = ['orders' => 0, 'items' => 0, 'ratings' => 0, 'skipped' => 0];
        $ratedPairs = [];   // "product|user" — the unique index on product_ratings

        for ($n = 1; $n <= DemoWorld::N_ORDERS; $n++) {
            $key = "order|$n";

            $ordersId = DemoWorld::MARKER . str_pad((string) $n, 6, '0', STR_PAD_LEFT);
            if (DB::table('orders')->where('orders_id', $ordersId)->exists()) {
                $counts['skipped']++;
                continue;
            }

            $customer = $customers[DemoWorld::seedOf($key . '|cust') % $customers->count()];
            $addresses = $addressByUser[$customer->id] ?? collect();
            if ($addresses->isEmpty()) {
                $counts['skipped']++;
                continue;
            }
            $address = $addresses[DemoWorld::seedOf($key . '|addr') % $addresses->count()];

            $placedAt = $this->placedAt($key);
            $pickFrom = ($demoWithStock && DemoWorld::chance($key . '|demoSeller', 60))
                ? $demoWithStock
                : $sellerIds;
            $sellerId = $pickFrom[DemoWorld::seedOf($key . '|seller') % count($pickFrom)];
            $pool = $bySeller[$sellerId];

            $status = $this->status($key);
            $paymentMethod = DemoWorld::pick($key . '|pay', self::PAYMENT_METHODS);

            // Anything still moving must be recent — nothing sits "Shipped" for
            // two months, and a stale in-flight order looks like a bug on the
            // dashboard rather than demo data.
            if (!in_array($status, [OrderStatusList::$delivered, OrderStatusList::$cancelled, OrderStatusList::$returned], true)
                && $placedAt->lt(now()->subDays(2))) {
                $status = OrderStatusList::$delivered;
            }

            // ── basket ───────────────────────────────────────────────────
            $lineCount = DemoWorld::intFor($key . '|lines', 1, 7);
            $lines = [];
            $subTotal = 0.0;
            $taxTotal = 0.0;

            for ($l = 0; $l < $lineCount; $l++) {
                $v = $pool[(DemoWorld::seedOf($key . "|v$l") + $l * 7) % $pool->count()];
                if (isset($lines[$v->variant_id])) {
                    continue;
                }

                $qty = DemoWorld::intFor($key . "|q$l", 1, 3);
                $unit = (float) ($v->discounted_price > 0 ? $v->discounted_price : $v->price);
                $mrp = (float) $v->price;
                $lineTotal = round($unit * $qty, 2);
                $taxPct = (float) ($v->tax_percent ?? 0);
                $lineTax = round($lineTotal * $taxPct / 100, 2);

                $lines[$v->variant_id] = [
                    'variant'   => $v,
                    'qty'       => $qty,
                    'unit'      => $unit,
                    'mrp'       => $mrp,
                    'sub_total' => $lineTotal,
                    'tax'       => $lineTax,
                    'tax_pct'   => $taxPct,
                    'discount'  => round(max(0, $mrp - $unit) * $qty, 2),
                ];

                $subTotal += $lineTotal;
                $taxTotal += $lineTax;
            }

            if (!$lines) {
                $counts['skipped']++;
                continue;
            }

            // ── money ────────────────────────────────────────────────────
            $deliveryCharge = $subTotal >= 299 ? 0.0 : (float) DemoWorld::pick($key . '|dc', [19, 25, 29, 35]);
            $promoDiscount = 0.0;
            $promoCode = null;
            if (DemoWorld::chance($key . '|promo', 22) && $subTotal > 200) {
                // Must match DemoMerchandisingSeeder::PROMOS — all ZF-prefixed,
                // which is also how --purge finds them.
                $promoCode = DemoWorld::pick($key . '|pc', ['ZFWELCOME', 'ZF50OFF', 'ZFFRESH20', 'ZFWEEKEND15']);
                $promoDiscount = round(min(100, $subTotal * DemoWorld::intFor($key . '|pd', 5, 20) / 100), 2);
            }

            $walletUsed = 0.0;
            if ($paymentMethod === 'Wallet' && $customer->balance > 0) {
                $walletUsed = round(min((float) $customer->balance, $subTotal), 2);
            }

            $finalTotal = round(max(0, $subTotal + $taxTotal + $deliveryCharge - $promoDiscount - $walletUsed), 2);

            $driverId = null;
            if ($drivers && in_array($status, [
                OrderStatusList::$delivered, OrderStatusList::$outForDelivery,
                OrderStatusList::$shipped, OrderStatusList::$returned,
            ], true)) {
                $driverId = $drivers[DemoWorld::seedOf($key . '|drv') % count($drivers)];
            }

            $deliveredAt = (clone $placedAt)->addMinutes(DemoWorld::intFor($key . '|eta', 12, 65));
            $statusHistory = $this->statusHistory($status, $placedAt, $deliveredAt);

            DB::transaction(function () use (
                $key, $ordersId, $customer, $address, $placedAt, $deliveredAt, $status, $statusHistory,
                $paymentMethod, $lines, $subTotal, $taxTotal, $deliveryCharge, $promoCode,
                $promoDiscount, $walletUsed, $finalTotal, $driverId, $sellerId,
                &$counts, &$ratedPairs
            ) {
                $order = [
                    'user_id'         => $customer->id,
                    'delivery_boy_id' => $driverId,
                    'orders_id'       => $ordersId,
                    'otp'             => DemoWorld::intFor($key . '|otp', 1000, 9999),
                    'mobile'          => $customer->mobile,
                    'order_note'      => DemoWorld::chance($key . '|note', 18)
                        ? DemoWorld::pick($key . '|noteTxt', [
                            'Please ring the bell twice.',
                            'Leave at the door.',
                            'Call before arriving, gate is locked.',
                            'No onions in the packing please.',
                            'Hand over to security if not home.',
                        ]) : null,
                    'total'           => round($subTotal, 2),
                    'delivery_charge' => $deliveryCharge,
                    'tax_amount'      => round($taxTotal, 2),
                    'tax_percentage'  => 0,
                    'wallet_balance'  => $walletUsed,
                    'discount'        => 0,
                    'promo_code'      => $promoCode,
                    'promo_discount'  => $promoDiscount,
                    'final_total'     => $finalTotal,
                    'payment_method'  => $paymentMethod,
                    'address'         => trim(($address->address ?? '') . ', ' . ($address->area ?? '') . ', '
                                          . ($address->city ?? '') . ' - ' . ($address->pincode ?? '')),
                    'latitude'        => (string) ($address->latitude ?? ''),
                    'longitude'       => (string) ($address->longitude ?? ''),
                    'delivery_time'   => $deliveredAt->format('d-m-Y h:i A'),
                    'status'          => json_encode($statusHistory),
                    'active_status'   => $status,
                    'order_from'      => DemoWorld::chance($key . '|from', 88) ? 1 : 2, // 1 android, 2 ios
                    'address_id'      => $address->id ?? 0,
                    'created_at'      => $placedAt,
                    'updated_at'      => $status === OrderStatusList::$delivered ? $deliveredAt : $placedAt,
                ];

                $codCollected = $paymentMethod === 'COD' && $status === OrderStatusList::$delivered;

                $optional = [
                    'delivery_pin'    => (string) DemoWorld::intFor($key . '|pin', 1000, 9999),
                    'seller_count'    => 1,
                    'order_type'      => 'doorstep',
                    // tinyint(1) FLAG, not an amount — the collected value lives
                    // on delivery_boy_transactions / the driver's cash ledger.
                    'cash_collected'    => $codCollected ? 1 : 0,
                    'cash_collected_at' => $codCollected ? $deliveredAt : null,
                    'estimated_time_of_delivery' => DemoWorld::intFor($key . '|eta2', 10, 30),
                    'delivered_at_time'          => $status === OrderStatusList::$delivered ? $deliveredAt : null,
                    'driver_accepted_at_time'    => $driverId ? (clone $placedAt)->addMinutes(2) : null,
                    'driver_arrived_at_cus_locn' => $status === OrderStatusList::$delivered
                        ? (clone $deliveredAt)->subMinutes(3) : null,
                ];
                foreach ($optional as $col => $val) {
                    if (Schema::hasColumn('orders', $col)) {
                        $order[$col] = $val;
                    }
                }

                $orderId = DB::table('orders')->insertGetId($order);

                // ── line items ───────────────────────────────────────────
                foreach ($lines as $line) {
                    $v = $line['variant'];
                    DB::table('order_items')->insert([
                        'user_id'            => $customer->id,
                        'order_id'           => $orderId,
                        'orders_id'          => $ordersId,
                        'product_name'       => $v->product_name,
                        'variant_name'       => $v->variant_type,
                        'product_variant_id' => $v->variant_id,
                        'delivery_boy_id'    => $driverId ?: 0,
                        'quantity'           => $line['qty'],
                        'price'              => $line['mrp'],
                        'discounted_price'   => $line['unit'],
                        'tax_amount'         => $line['tax'],
                        'tax_percentage'     => $line['tax_pct'],
                        'discount'           => $line['discount'],
                        'sub_total'          => $line['sub_total'],
                        'status'             => json_encode($statusHistory),
                        'active_status'      => $status,
                        'seller_id'          => (int) ($v->seller_id ?: $sellerId),
                        'is_credited'        => $status === OrderStatusList::$delivered ? 1 : 0,
                        'created_at'         => $placedAt,
                        'updated_at'         => $placedAt,
                    ]);
                    $counts['items']++;
                }

                // ── payment ──────────────────────────────────────────────
                if ($paymentMethod !== 'COD') {
                    $refunded = $status === OrderStatusList::$cancelled;

                    DB::table('transactions')->insert([
                        'user_id'          => $customer->id,
                        'order_id'         => (string) $orderId,
                        // Live rows carry the gateway name as-is ('Razorpay'), not lowercased.
                        'type'             => $paymentMethod,
                        'txn_id'           => DemoWorld::MARKER . 'TXN' . strtoupper(substr(md5($key), 0, 12)),
                        'amount'           => $finalTotal,
                        'status'           => 'success',
                        'is_refunded'      => $refunded ? 1 : 0,
                        'refund_amount'    => $refunded ? $finalTotal : null,
                        'refunded_at'      => $refunded ? (clone $placedAt)->addMinutes(20) : null,
                        'message'          => DemoWorld::MARKER . ' demo payment',
                        'transaction_date' => $placedAt,
                        'created_at'       => $placedAt,
                        'updated_at'       => $placedAt,
                    ]);

                    // Prepaid cancellations refund to the wallet, matching the
                    // live policy (refund to wallet, not back to the gateway).
                    if ($refunded) {
                        $refundAt = (clone $placedAt)->addMinutes(20);
                        DB::table('wallet_transactions')->insert([
                            'order_id'         => $orderId,
                            'user_id'          => $customer->id,
                            'type'             => 'credit',
                            'amount'           => $finalTotal,
                            'payment_type'     => 'refund',
                            'transaction_date' => $refundAt,
                            'message'          => DemoWorld::MARKER . " refund for cancelled order {$ordersId}",
                            'status'           => '1',
                            'created_at'       => $refundAt,
                            'updated_at'       => $refundAt,
                        ]);
                    }
                }

                // ── driver earning ───────────────────────────────────────
                if ($driverId && $status === OrderStatusList::$delivered) {
                    // The driver's earning columns are what the earnings and
                    // settlement screens read — a bare `amount` leaves them at 0.
                    $driverDeliveryCharge = $deliveryCharge > 0 ? $deliveryCharge : 20.0;
                    $bonus = (float) DemoWorld::intFor($key . '|bonus', 0, 15);
                    $earnings = round($driverDeliveryCharge + $bonus, 2);
                    // On COD the driver holds the customer's cash; on prepaid there
                    // is nothing to hand over, so admin_cash is zero.
                    $collected = $paymentMethod === 'COD' ? $finalTotal : 0.0;

                    DB::table('delivery_boy_transactions')->insert([
                        'user_id'          => $customer->id,
                        'order_id'         => $orderId,
                        'delivery_boy_id'  => $driverId,
                        'type'             => 'credit',
                        'amount'           => $collected,
                        'delivery_charge'  => $driverDeliveryCharge,
                        'bonus_amount'     => $bonus,
                        'driver_earnings'  => $earnings,
                        'admin_cash'       => round(max(0, $collected - $earnings), 2),
                        'is_hand_cash'     => $paymentMethod === 'COD' ? 1 : 0,
                        'settled_with_admin' => DemoWorld::chance($key . '|settled', 70) ? 1 : 0,
                        'status'           => 'success',
                        'message'          => DemoWorld::MARKER . " delivery earning for {$ordersId}",
                        'transaction_date' => $deliveredAt,
                        'created_at'       => $deliveredAt,
                        'updated_at'       => $deliveredAt,
                    ]);
                }

                // ── reviews ──────────────────────────────────────────────
                if ($status === OrderStatusList::$delivered && DemoWorld::chance($key . '|rated', 35)) {
                    $line = reset($lines);
                    $pair = $line['variant']->product_id . '|' . $customer->id;

                    if (!isset($ratedPairs[$pair])) {
                        $rate = DemoWorld::pick($key . '|rate', [5, 5, 5, 4, 4, 4, 3, 2]);
                        DB::table('product_ratings')->insertOrIgnore([
                            'product_id' => $line['variant']->product_id,
                            'user_id'    => $customer->id,
                            // Admin filters and the store rating rollup read these.
                            'seller_id'  => (int) ($line['variant']->seller_id ?: 0),
                            'store_id'   => (int) ($line['variant']->store_id ?: 0),
                            'order_id'   => $orderId,
                            'is_combo'   => 0,
                            'rate'       => $rate,
                            'review'     => $this->review($key, $rate),
                            'status'     => 1,
                            'created_at' => (clone $deliveredAt)->addHours(DemoWorld::intFor($key . '|rh', 1, 40)),
                            'updated_at' => $deliveredAt,
                        ]);
                        $ratedPairs[$pair] = true;
                        $counts['ratings']++;
                    }
                }

                $counts['orders']++;
            });
        }

        $this->command->info("Orders: {$counts['orders']} created, {$counts['items']} line items, "
            . "{$counts['ratings']} reviews, {$counts['skipped']} skipped.");
    }

    /**
     * Order timestamp, weighted so recent weeks are busier than old ones and
     * evenings are busier than mornings — otherwise every chart is a flat line.
     */
    private function placedAt(string $key)
    {
        // Squaring the unit interval pushes the mass towards day 0 (today).
        $u = DemoWorld::floatFor($key . '|day', 0, 1);
        $daysAgo = (int) floor(($u ** 2) * DemoWorld::DAYS_BACK);

        $hour = DemoWorld::pick($key . '|hour', [
            8, 9, 10, 11, 11, 12, 12, 13, 17, 18, 18, 19, 19, 19, 20, 20, 20, 21, 21, 22,
        ]);

        $at = now()->subDays($daysAgo)
            ->setTime($hour, DemoWorld::intFor($key . '|min', 0, 59), DemoWorld::intFor($key . '|sec', 0, 59));

        // setTime() can push a same-day order past the current hour — e.g. the
        // 21:00 slot when it is 19:00 — which shows up on the dashboard as an
        // order placed in the future. Nudge those back a day.
        return $at->isFuture() ? $at->subDay() : $at;
    }

    /** Weighted pick from statusMix(). */
    private function status(string $key): int
    {
        $roll = DemoWorld::seedOf($key . '|status') % 100;
        $acc = 0;
        foreach ($this->statusMix() as $status => $weight) {
            $acc += $weight;
            if ($roll < $acc) {
                return (int) $status;
            }
        }

        return OrderStatusList::$delivered;
    }

    /**
     * The full status trail, in the exact shape OrderApiController writes it:
     * a list of [status_id, "d-m-Y h:i:sa"] pairs, oldest first.
     *
     * A real order accumulates one entry per transition, which is what the
     * customer app's tracking timeline renders — a single-entry array would
     * make every delivered order look like it teleported.
     */
    private function statusHistory(int $status, $placedAt, $deliveredAt): array
    {
        $fmt = fn ($t) => $t->format('d-m-Y h:i:sa');

        // The happy path, with plausible gaps between steps.
        $path = [
            [OrderStatusList::$received,       (clone $placedAt)],
            [OrderStatusList::$processed,      (clone $placedAt)->addMinutes(4)],
            [OrderStatusList::$shipped,        (clone $placedAt)->addMinutes(9)],
            [OrderStatusList::$outForDelivery, (clone $placedAt)->addMinutes(14)],
            [OrderStatusList::$delivered,      (clone $deliveredAt)],
        ];

        $trail = [];
        foreach ($path as [$stage, $at]) {
            $trail[] = [$stage, $fmt($at)];
            if ($stage === $status) {
                return $trail;
            }
        }

        // Cancelled / returned branch off the trail rather than continuing it.
        if ($status === OrderStatusList::$cancelled) {
            return [
                [OrderStatusList::$received,  $fmt($placedAt)],
                [OrderStatusList::$processed, $fmt((clone $placedAt)->addMinutes(4))],
                [OrderStatusList::$cancelled, $fmt((clone $placedAt)->addMinutes(11))],
            ];
        }

        if ($status === OrderStatusList::$returned) {
            $trail[] = [OrderStatusList::$returned, $fmt((clone $deliveredAt)->addHours(6))];
        }

        return $trail;
    }

    private function review(string $key, int $rate): string
    {
        $pools = [
            5 => [
                'Delivered in under 15 minutes, everything was fresh.',
                'Packing was neat and nothing was leaking. Will order again.',
                'Exactly what was shown in the app. Good quality.',
                'Best price I found for this pack size.',
            ],
            4 => [
                'Good quality, delivery was slightly late.',
                'Fresh, though one item was close to expiry.',
                'Happy with it overall.',
            ],
            3 => [
                'Average. The pack was a bit dented.',
                'Okay for the price, nothing special.',
            ],
            2 => [
                'Item was not as fresh as expected.',
                'Packaging was damaged on arrival.',
            ],
        ];

        $pool = $pools[$rate] ?? $pools[4];

        return DemoWorld::pick($key . '|rev', $pool);
    }
}
