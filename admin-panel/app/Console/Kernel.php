<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;
use App\Jobs\SendCartNotification; // Ensure this import is correct
use App\Console\Commands\SendCartNotificationCommand;


class Kernel extends ConsoleKernel
{
    protected $commands = [
        SendCartNotificationCommand::class,
    ];
    /**
     * Define the application's command schedule.
     *
     * @param  \Illuminate\Console\Scheduling\Schedule  $schedule
     * @return void
     */
    protected function schedule(Schedule $schedule)
    {
        $schedule->command('cart:notification')->everyMinute();
        $schedule->command('queue:work --once')->everyMinute();

        // Safety net: re-scan delivered, eligible, uncredited first orders and
        // dispatch referral-bonus jobs for any missed by the inline path.
        $schedule->command('referral:process-bonuses')->hourly();

        // Process preorders every Friday at 6:30 AM IST
        $schedule->command('preorders:process')
            ->weeklyOn(5, '6:30') // 5 = Friday
            ->timezone('Asia/Kolkata');
    }

    /**
     * Register the commands for the application.
     *
     * @return void
     */
    protected function commands()
    {
        $this->load(__DIR__.'/Commands');

        require base_path('routes/console.php');
    }
}
