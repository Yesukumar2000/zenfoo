<?php

namespace App\Console\Commands;

use App\Helpers\CommonHelper;
use Database\Seeders\DemoWorld\DemoWorld;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class BackfillOrderNumbers extends Command
{
    protected $signature = 'orders:backfill-numbers
                            {--apply : Actually write the order numbers; without this the command only reports}
                            {--chunk=500 : How many orders to process per batch}';

    protected $description = 'Stamp the customer facing order number (ZF-0001) onto existing orders and their line items';

    public function handle()
    {
        $apply = (bool) $this->option('apply');
        $chunk = max(1, (int) $this->option('chunk'));

        $orders = 0;
        $items = 0;
        $comboItems = 0;
        $alreadyCorrect = 0;
        $demoSkipped = 0;
        $samples = [];

        // Soft deleted orders are included on purpose: their items still show up in
        // invoices and refund history, so they need a number too.
        DB::table('orders')->select('id', 'orders_id')->orderBy('id')
            ->chunkById($chunk, function ($batch) use ($apply, &$orders, &$items, &$comboItems, &$alreadyCorrect, &$demoSkipped, &$samples) {
                foreach ($batch as $order) {
                    // Demo world orders are found and torn down by their ZFDEMO marker
                    // (see DemoWorld::MARKER). Renumbering them would orphan the demo
                    // data because the cleanup query would no longer match it.
                    if ($order->orders_id !== null && stripos($order->orders_id, DemoWorld::MARKER) === 0) {
                        $demoSkipped++;
                        continue;
                    }

                    $number = CommonHelper::formatOrderNumber($order->id);

                    if ($order->orders_id === $number) {
                        $alreadyCorrect++;
                        continue;
                    }

                    if (count($samples) < 5) {
                        $samples[] = [$order->id, $order->orders_id ?? '(null)', $number];
                    }

                    if ($apply) {
                        DB::table('orders')->where('id', $order->id)->update(['orders_id' => $number]);
                        $items += DB::table('order_items')->where('order_id', $order->id)
                            ->update(['orders_id' => $number]);
                        $comboItems += DB::table('order_combo_items')->where('order_id', $order->id)
                            ->update(['orders_id' => $number]);
                    }

                    $orders++;
                }
            });

        if ($samples) {
            $this->table(['Order id', 'Old orders_id', 'New orders_id'], $samples);
        }

        $this->info("Orders needing a number : {$orders}");
        $this->info("Orders already correct  : {$alreadyCorrect}");
        $this->info("Demo orders left alone  : {$demoSkipped}");

        if ($apply) {
            $this->info("Line items updated      : {$items}");
            $this->info("Combo items updated     : {$comboItems}");
            $this->info('Backfill applied.');
        } else {
            $this->warn('Dry run - nothing was written. Re-run with --apply to commit.');
        }

        return 0;
    }
}
