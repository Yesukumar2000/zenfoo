<?php

namespace App\Notifications;

use App\Helpers\CommonHelper;
use App\Models\Admin;
use App\Models\AdminToken;
use App\Models\Seller;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\Log;

class SellerRegistrationNotification extends Notification
{
    use Queueable;

    public $sellerId;
    public $type;

    /**
     * Create a new notification instance.
     *
     * @return void
     */
    public function __construct($sellerId, $type = 'seller_registration')
    {
        $this->sellerId = $sellerId;
        $this->type = $type;
    }

    /**
     * Get the notification's delivery channels.
     *
     * @param  mixed  $notifiable
     * @return array
     */
    public function via($notifiable)
    {
        return ['database'];
    }

    /**
     * Get the array representation of the notification.
     *
     * @param  mixed  $notifiable
     * @return array
     */
    public function toArray($notifiable)
    {
        $seller = Seller::find($this->sellerId);

        if (!$seller) {
            return [];
        }

        // Determine the message based on type
        $title = '';
        $text = '';

        if ($this->type == 'seller_registration') {
            $title = "Registration Successful!";
            $text = "Your registration for " . $seller->store_name . " has been submitted successfully. Your account is pending approval.";
        } elseif ($this->type == 'seller_approved') {
            $title = "Registration Approved!";
            $text = "Congratulations! Your seller account " . $seller->store_name . " has been approved. You can now start selling.";
        } elseif ($this->type == 'seller_rejected') {
            $title = "Registration Rejected";
            $text = "Unfortunately, your seller registration for " . $seller->store_name . " has been rejected. Please contact support for more details.";
        } elseif ($this->type == 'seller_activated') {
            $title = "Account Activated!";
            $text = "Your seller account " . $seller->store_name . " has been activated successfully.";
        } elseif ($this->type == 'seller_deactivated') {
            $title = "Account Deactivated";
            $text = "Your seller account " . $seller->store_name . " has been deactivated. Please contact support for assistance.";
        }

        // Get admin tokens for FCM notification
        $adminTokens = AdminToken::where('user_id', $notifiable->id)
            ->get()
            ->pluck('fcm_token', 'platform')
            ->toArray();

        Log::info("Seller Notification - Admin ID: ", [$notifiable->id]);
        Log::info("Seller Notification - Admin Tokens: ", [$adminTokens]);

        // Send FCM notification
        if (count($adminTokens) > 0) {
            CommonHelper::sendNotification($adminTokens, $title, $text, $this->type);
        }

        return [
            'type' => $this->type,
            'seller_id' => $seller->id,
            'seller_name' => $seller->name,
            'store_name' => $seller->store_name,
            'status' => $seller->status,
            'title' => $title,
            'text' => $text,
        ];
    }
}
