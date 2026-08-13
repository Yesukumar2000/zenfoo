<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

class SeedDefaultFaqs extends Migration
{
    public function up()
    {
        $faqs = [

            // ── Customer ──────────────────────────────────────────────────
            [
                'role'     => 'customer',
                'question' => 'How do I place an order?',
                'answer'   => 'Open the app, browse products or search for what you need, add items to your cart, and proceed to checkout. Select your delivery address and preferred payment method, then confirm your order. You will receive a confirmation notification once the order is placed.',
                'status'   => 1,
            ],
            [
                'role'     => 'customer',
                'question' => 'How can I track my order?',
                'answer'   => 'Once your order is confirmed and picked up by a delivery partner, you can track it in real time from the "My Orders" section. Tap on the active order to see the live location of the delivery partner on the map along with an estimated arrival time.',
                'status'   => 1,
            ],
            [
                'role'     => 'customer',
                'question' => 'What payment methods are accepted?',
                'answer'   => 'We accept UPI, credit/debit cards, net banking, digital wallets, and cash on delivery (COD). Available payment options may vary based on your location and the store you are ordering from.',
                'status'   => 1,
            ],
            [
                'role'     => 'customer',
                'question' => 'How do I cancel my order or request a refund?',
                'answer'   => 'You can cancel an order from the "My Orders" section before it is picked up by the delivery partner. Once cancelled, any online payment will be refunded to your original payment method within 5–7 business days. If the order has already been picked up, please contact support for assistance.',
                'status'   => 1,
            ],
            [
                'role'     => 'customer',
                'question' => 'What should I do if I received a wrong or damaged item?',
                'answer'   => 'We apologize for the inconvenience. Please report the issue within 24 hours of delivery through "My Orders" → select the order → "Report an Issue". Our support team will review your request and arrange a replacement or refund as applicable.',
                'status'   => 1,
            ],

            // ── Seller ────────────────────────────────────────────────────
            [
                'role'     => 'seller',
                'question' => 'How do I register my store on the platform?',
                'answer'   => 'Download the Seller app and sign up with your business details including store name, GSTIN, address, and bank account information. Once your documents are verified by the admin team (usually within 24–48 hours), your store will go live and you can start adding products.',
                'status'   => 1,
            ],
            [
                'role'     => 'seller',
                'question' => 'How do I add or update my product listings?',
                'answer'   => 'Go to the "Products" section in the Seller app, tap "Add Product", fill in the product name, category, price, stock quantity, and upload clear images. To update an existing product, find it in your product list and tap "Edit". Changes go live immediately after saving.',
                'status'   => 1,
            ],
            [
                'role'     => 'seller',
                'question' => 'How and when will I receive my payouts?',
                'answer'   => 'Payouts are processed every week directly to your registered bank account. You can view your earnings, pending settlements, and transaction history in the "Earnings" section of the Seller app.',
                'status'   => 1,
            ],
            [
                'role'     => 'seller',
                'question' => 'How do I manage incoming orders?',
                'answer'   => 'You will receive a push notification for every new order. Open the Seller app, go to "Orders", and accept or reject the order within the allowed time window. Once accepted, prepare the items and mark the order as "Ready for Pickup" so a delivery partner can collect it.',
                'status'   => 1,
            ],

            // ── Driver ────────────────────────────────────────────────────
            [
                'role'     => 'driver',
                'question' => 'How do I sign up as a delivery partner?',
                'answer'   => 'Download the Delivery Partner app and register with your name, mobile number, vehicle details, and identity documents (Aadhaar/PAN and driving licence). After admin verification, your account will be activated and you can start accepting delivery requests.',
                'status'   => 1,
            ],
            [
                'role'     => 'driver',
                'question' => 'How are delivery assignments given to me?',
                'answer'   => 'Delivery requests are automatically assigned based on your proximity to the store and your current availability status. Make sure you are marked "Online" in the app to receive requests. You can accept or reject a request; repeated rejections may affect your acceptance rate.',
                'status'   => 1,
            ],
            [
                'role'     => 'driver',
                'question' => 'How do I calculate and track my earnings?',
                'answer'   => 'Your earnings are calculated per delivery and may include a base delivery fee plus incentives for peak hours or high-demand zones. You can view your daily, weekly, and monthly earnings breakdown in the "Earnings" tab of the Delivery Partner app.',
                'status'   => 1,
            ],
            [
                'role'     => 'driver',
                'question' => 'When and how do I get paid?',
                'answer'   => 'Earnings are settled weekly directly to your registered bank account. Ensure your bank details are up to date in the Profile section to avoid payout delays.',
                'status'   => 1,
            ],
            [
                'role'     => 'driver',
                'question' => 'What should I do if I face an issue during a delivery?',
                'answer'   => 'For any issue during delivery — such as customer unavailability, wrong address, or damaged product — use the in-app "Help" option on the active order screen. You can also call or chat with the customer directly through the app. If unresolved, escalate via the Support section.',
                'status'   => 1,
            ],

        ];

        DB::table('faqs')->insert($faqs);
    }

    public function down()
    {
        $questions = [
            'How do I place an order?',
            'How can I track my order?',
            'What payment methods are accepted?',
            'How do I cancel my order or request a refund?',
            'What should I do if I received a wrong or damaged item?',
            'How do I register my store on the platform?',
            'How do I add or update my product listings?',
            'How and when will I receive my payouts?',
            'How do I manage incoming orders?',
            'How do I sign up as a delivery partner?',
            'How are delivery assignments given to me?',
            'How do I calculate and track my earnings?',
            'When and how do I get paid?',
            'What should I do if I face an issue during a delivery?',
        ];

        DB::table('faqs')->whereIn('question', $questions)->delete();
    }
}
