<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

class AddAboutContactToSettingsTable extends Migration
{
    public function up()
    {
        $aboutUs = <<<'HTML'
<h2>About Zenfoo</h2>
<p>Welcome to <strong>Zenfoo</strong> — your one-stop platform for ultra-fast grocery delivery and food ordering, delivered straight to your door in minutes.</p>

<h3>Who We Are</h3>
<p>Founded with a simple mission — to make everyday essentials and restaurant-quality food accessible to everyone, instantly — Zenfoo combines the speed of quick commerce with the variety of a food delivery platform. Whether you need fresh vegetables, household staples, or a hot meal from your favourite local restaurant, Zenfoo has you covered.</p>

<h3>What We Do</h3>
<ul>
    <li><strong>Grocery &amp; Essentials Delivery:</strong> Order from thousands of products including fresh produce, dairy, snacks, beverages, personal care, and more — delivered in under 10 minutes.</li>
    <li><strong>Food Ordering:</strong> Browse menus from top-rated restaurants and cloud kitchens near you and get hot food delivered fast.</li>
    <li><strong>Multi-Store Support:</strong> Shop across multiple stores and categories in a single order.</li>
    <li><strong>Real-Time Tracking:</strong> Track your delivery boy live on the map from the moment your order is picked up.</li>
</ul>

<h3>Our Mission</h3>
<p>To be the most reliable and fastest delivery platform in every city we operate in — saving our customers time, effort, and money every single day.</p>

<h3>Our Values</h3>
<ul>
    <li><strong>Speed:</strong> We obsess over delivery times so you don't have to wait.</li>
    <li><strong>Quality:</strong> We partner only with trusted sellers and verified restaurants.</li>
    <li><strong>Transparency:</strong> No hidden charges. What you see is what you pay.</li>
    <li><strong>Community:</strong> We support local businesses, sellers, and delivery partners.</li>
</ul>

<h3>Our Network</h3>
<p>Zenfoo currently operates across multiple cities with a growing fleet of delivery partners, hundreds of seller stores, and thousands of listed products — and we are expanding rapidly.</p>

<p>Thank you for choosing Zenfoo. We are committed to making your life easier, one delivery at a time.</p>
HTML;

        $contactUs = <<<'HTML'
<h2>Contact Us</h2>
<p>We would love to hear from you! Whether you have a question about your order, want to partner with us, or just want to say hello — our team is here to help.</p>

<h3>Customer Support</h3>
<ul>
    <li><strong>Email:</strong> support@zenfoo.com</li>
    <li><strong>Phone:</strong> +91 98765 43210</li>
    <li><strong>Support Hours:</strong> Monday – Sunday, 8:00 AM – 11:00 PM IST</li>
</ul>

<h3>Business &amp; Partnership Enquiries</h3>
<ul>
    <li><strong>Email:</strong> partners@zenfoo.com</li>
    <li><strong>Phone:</strong> +91 98765 43211</li>
</ul>

<h3>Seller Onboarding</h3>
<p>Want to list your store or restaurant on Zenfoo? Get in touch with our seller success team.</p>
<ul>
    <li><strong>Email:</strong> sellers@zenfoo.com</li>
    <li><strong>Phone:</strong> +91 98765 43212</li>
</ul>

<h3>Registered Office</h3>
<p>
    Zenfoo Technologies Pvt. Ltd.<br>
    4th Floor, Tower B, Cyber Hub,<br>
    Gurugram, Haryana – 122002,<br>
    India
</p>

<h3>Follow Us</h3>
<ul>
    <li><strong>Instagram:</strong> @zenfoo.official</li>
    <li><strong>Twitter / X:</strong> @zenfoo</li>
    <li><strong>Facebook:</strong> facebook.com/zenfoo</li>
    <li><strong>LinkedIn:</strong> linkedin.com/company/zenfoo</li>
</ul>

<p>For order-related issues, please use the <strong>Help</strong> section in the Zenfoo app for the fastest resolution. Our in-app support team typically responds within minutes.</p>
HTML;

        DB::table('settings')->insert([
            ['variable' => 'about_us',   'value' => trim($aboutUs)],
            ['variable' => 'contact_us', 'value' => trim($contactUs)],
        ]);
    }

    public function down()
    {
        DB::table('settings')->whereIn('variable', ['about_us', 'contact_us'])->delete();
    }
}
