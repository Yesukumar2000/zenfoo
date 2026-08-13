<?php

namespace App\Console\Commands;

use App\Models\CustomerClaimedMilestone;
use App\Models\UserOrderReward;
use App\Services\UserOfferClaimService;
use Illuminate\Console\Command;

class BackfillLoyaltyRewards extends Command
{
    protected $signature = 'loyalty:backfill-rewards {--apply : Actually credit the wallets; without this the command only reports}';

    protected $description = 'Credit loyalty milestones that were marked claimed but never paid into the wallet';

    public function handle()
    {
        $apply = (bool) $this->option('apply');

        $milestones = UserOrderReward::all()->keyBy('id');
        $claims = CustomerClaimedMilestone::orderBy('customer_id')->orderBy('id')->get();

        $rows = [];
        $totalOwed = 0.0;
        $skipped = 0;

        foreach ($claims as $claim) {
            $milestone = $milestones->get($claim->milestone_id);
            if (!$milestone) {
                $skipped++;
                continue;
            }

            // creditMilestoneToWallet is the single source of truth for whether
            // this was already paid, so a re-run cannot double-credit.
            if ($apply) {
                $credited = UserOfferClaimService::creditMilestoneToWallet(
                    $claim->customer_id,
                    $milestone,
                    $claim->used_in_order_id
                );
                if (!$credited) {
                    $skipped++;
                    continue;
                }
            }

            $rows[] = [$claim->customer_id, $claim->milestone_id, $milestone->order_count, $claim->reward_amount];
            $totalOwed += (float) $claim->reward_amount;
        }

        if ($rows) {
            $this->table(['customer_id', 'milestone_id', 'order_count', 'amount'], $rows);
        }

        $verb = $apply ? 'Credited' : 'Would credit';
        $this->info("{$verb} " . count($rows) . " reward(s) totalling {$totalOwed}. Skipped: {$skipped}.");

        if (!$apply) {
            $this->warn('Dry run — nothing was written. Re-run with --apply to credit these wallets.');
        }

        return 0;
    }
}
