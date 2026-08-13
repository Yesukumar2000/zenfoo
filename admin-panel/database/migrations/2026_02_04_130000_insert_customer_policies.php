<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $privacyPolicy = <<<'HTML'
<h2>Privacy Policy</h2>
<p><strong>Last Updated:</strong> February 2026</p>

<h3>1. Introduction</h3>
<p>This Privacy Policy explains how Zenfoo collects, uses, discloses, and safeguards your information when you use our application and services. Please read this privacy policy carefully.</p>

<h3>2. Information We Collect</h3>
<h4>2.1 Personal Information</h4>
<ul>
    <li>Full name and contact details</li>
    <li>Phone number and email address</li>
    <li>Delivery addresses</li>
    <li>Payment information</li>
    <li>Profile photograph (optional)</li>
</ul>

<h4>2.2 Location Information</h4>
<ul>
    <li>Delivery location for order fulfillment</li>
    <li>Location data to show nearby restaurants and stores</li>
</ul>

<h4>2.3 Device Information</h4>
<ul>
    <li>Device type, operating system, and unique device identifiers</li>
    <li>Mobile network information</li>
    <li>App usage data and preferences</li>
</ul>

<h4>2.4 Order Information</h4>
<ul>
    <li>Order history and preferences</li>
    <li>Payment transaction records</li>
    <li>Reviews and ratings provided</li>
</ul>

<h3>3. How We Use Your Information</h3>
<ul>
    <li>To process and deliver your orders</li>
    <li>To process payments securely</li>
    <li>To communicate order updates and notifications</li>
    <li>To personalize your experience and show relevant recommendations</li>
    <li>To improve our services and user experience</li>
    <li>To provide customer support</li>
    <li>To send promotional offers (with your consent)</li>
    <li>To comply with legal obligations</li>
</ul>

<h3>4. Information Sharing</h3>
<p>We may share your information with:</p>
<ul>
    <li>Restaurants and stores to fulfill your orders</li>
    <li>Delivery partners (name, address, phone for delivery)</li>
    <li>Payment processors for secure transactions</li>
    <li>Law enforcement when legally required</li>
    <li>Service providers who assist in our operations</li>
</ul>

<h3>5. Data Security</h3>
<p>We implement appropriate technical and organizational security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.</p>

<h3>6. Data Retention</h3>
<p>We retain your personal information for as long as your account is active or as needed to provide services. We may retain certain information as required by law or for legitimate business purposes.</p>

<h3>7. Your Rights</h3>
<p>You have the right to:</p>
<ul>
    <li>Access your personal information</li>
    <li>Request correction of inaccurate data</li>
    <li>Request deletion of your account and data</li>
    <li>Opt-out of marketing communications</li>
    <li>Withdraw consent for data processing</li>
</ul>

<h3>8. Cookies and Tracking</h3>
<p>We use cookies and similar technologies to enhance your experience, analyze usage, and deliver personalized content. You can manage cookie preferences through your device settings.</p>

<h3>9. Children's Privacy</h3>
<p>Our services are not intended for children under 13 years of age. We do not knowingly collect personal information from children.</p>

<h3>10. Contact Us</h3>
<p>For any privacy-related concerns or queries, please contact us:</p>
<p><strong>Phone:</strong> 9999009090</p>
<p><strong>Email:</strong> support@zenfoo.in</p>
<p><strong>Address:</strong> Kurnool</p>

<h3>11. Changes to This Policy</h3>
<p>We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.</p>
HTML;

        $termsConditions = <<<'HTML'
<h2>Terms and Conditions</h2>
<p><strong>Last Updated:</strong> February 2026</p>

<h3>1. Agreement to Terms</h3>
<p>By accessing or using the Zenfoo application, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our services.</p>

<h3>2. Eligibility</h3>
<p>To use our services, you must:</p>
<ul>
    <li>Be at least 18 years of age or have parental consent</li>
    <li>Provide accurate and complete registration information</li>
    <li>Maintain the security of your account credentials</li>
</ul>

<h3>3. Account Registration</h3>
<ul>
    <li>You must provide accurate, current, and complete information</li>
    <li>You are responsible for maintaining account confidentiality</li>
    <li>You are responsible for all activities under your account</li>
    <li>Notify us immediately of any unauthorized account use</li>
</ul>

<h3>4. Ordering and Payment</h3>
<ul>
    <li>All orders are subject to availability and confirmation</li>
    <li>Prices are subject to change without notice</li>
    <li>Payment must be made through approved payment methods</li>
    <li>You agree to pay all charges incurred under your account</li>
    <li>We reserve the right to refuse or cancel orders</li>
</ul>

<h3>5. Delivery</h3>
<ul>
    <li>Delivery times are estimates and not guaranteed</li>
    <li>You must provide accurate delivery address and contact information</li>
    <li>Someone must be available to receive the order at the delivery address</li>
    <li>Additional delivery charges may apply based on location and distance</li>
</ul>

<h3>6. User Conduct</h3>
<p>You agree not to:</p>
<ul>
    <li>Use the service for any unlawful purpose</li>
    <li>Harass, abuse, or harm delivery partners or restaurant staff</li>
    <li>Provide false or misleading information</li>
    <li>Attempt to gain unauthorized access to our systems</li>
    <li>Use automated systems to access the service</li>
    <li>Interfere with the proper functioning of the service</li>
</ul>

<h3>7. Intellectual Property</h3>
<p>All content, trademarks, and intellectual property on the platform belong to Zenfoo or its licensors. You may not copy, modify, or distribute any content without permission.</p>

<h3>8. Limitation of Liability</h3>
<ul>
    <li>We are not liable for any indirect, incidental, or consequential damages</li>
    <li>Our liability is limited to the amount paid for the specific order</li>
    <li>We are not responsible for third-party actions or content</li>
</ul>

<h3>9. Dispute Resolution</h3>
<p>Any disputes arising from these terms shall be resolved through:</p>
<ul>
    <li>First, through our customer support</li>
    <li>If unresolved, through mediation</li>
    <li>Finally, through the courts of Kurnool Judiciary</li>
</ul>

<h3>10. Modifications to Terms</h3>
<p>We reserve the right to modify these Terms and Conditions at any time. Continued use of our services after modifications constitutes acceptance of the updated terms.</p>

<h3>11. Contact Information</h3>
<p>For any questions or concerns, please contact us:</p>
<p><strong>Phone:</strong> 9999009090</p>
<p><strong>Email:</strong> support@zenfoo.in</p>
<p><strong>Address:</strong> Kurnool</p>

<h3>12. Governing Law</h3>
<p>These Terms and Conditions shall be governed by and construed in accordance with the laws of India, and any disputes shall be subject to the exclusive jurisdiction of the courts in Kurnool Judiciary.</p>
HTML;

        $cancellationPolicy = <<<'HTML'
<h2>Cancellation Policy</h2>
<p><strong>Last Updated:</strong> February 2026</p>

<h3>1. Order Cancellation by Customer</h3>
<h4>1.1 Before Order Confirmation</h4>
<p>You can cancel your order free of charge before the restaurant/store confirms it.</p>

<h4>1.2 After Order Confirmation</h4>
<ul>
    <li><strong>Before Preparation Starts:</strong> Full refund will be processed</li>
    <li><strong>During Preparation:</strong> Partial refund may be applicable based on preparation stage</li>
    <li><strong>After Dispatch:</strong> No cancellation allowed once the order is out for delivery</li>
</ul>

<h3>2. Order Cancellation by Restaurant/Store</h3>
<p>The restaurant/store may cancel your order due to:</p>
<ul>
    <li>Item unavailability</li>
    <li>Incorrect pricing displayed</li>
    <li>Inability to deliver to your location</li>
    <li>Store closure or operational issues</li>
</ul>
<p>In such cases, a full refund will be processed automatically.</p>

<h3>3. Order Cancellation by Zenfoo</h3>
<p>We may cancel orders in the following situations:</p>
<ul>
    <li>Suspected fraudulent activity</li>
    <li>Delivery address is unserviceable</li>
    <li>No delivery partner available</li>
    <li>Technical errors in order processing</li>
</ul>
<p>Full refund will be processed for cancellations initiated by Zenfoo.</p>

<h3>4. How to Cancel an Order</h3>
<ul>
    <li>Go to "My Orders" in the app</li>
    <li>Select the order you wish to cancel</li>
    <li>Click on "Cancel Order" button</li>
    <li>Select the reason for cancellation</li>
    <li>Confirm the cancellation</li>
</ul>

<h3>5. Refund Processing</h3>
<ul>
    <li>Refunds for online payments will be credited to the original payment method within 5-7 business days</li>
    <li>Wallet refunds are processed instantly</li>
    <li>Cash on Delivery orders do not require refund processing</li>
</ul>

<h3>6. Non-Refundable Situations</h3>
<ul>
    <li>Orders cancelled after dispatch</li>
    <li>Incorrect address provided by customer</li>
    <li>Customer unavailable at delivery location</li>
    <li>Repeated cancellations may result in account restrictions</li>
</ul>

<h3>7. Contact Us</h3>
<p>For cancellation assistance, please contact:</p>
<p><strong>Phone:</strong> 9999009090</p>
<p><strong>Email:</strong> support@zenfoo.in</p>
HTML;

        $returnsExchangesPolicy = <<<'HTML'
<h2>Returns and Exchanges Policy</h2>
<p><strong>Last Updated:</strong> February 2026</p>

<h3>1. General Policy</h3>
<p>Due to the perishable nature of food items, we do not accept returns or exchanges for food orders. However, we are committed to ensuring your satisfaction.</p>

<h3>2. Eligible Situations for Refund/Replacement</h3>
<h4>2.1 Food Orders</h4>
<ul>
    <li>Wrong item delivered</li>
    <li>Missing items from the order</li>
    <li>Quality issues (spoiled, stale, or contaminated food)</li>
    <li>Significant difference from item description</li>
    <li>Damaged packaging affecting food quality</li>
</ul>

<h4>2.2 Grocery/Store Orders</h4>
<ul>
    <li>Damaged or defective products</li>
    <li>Expired products</li>
    <li>Wrong item delivered</li>
    <li>Missing items from the order</li>
</ul>

<h3>3. How to Report an Issue</h3>
<ul>
    <li>Report within 24 hours of delivery</li>
    <li>Go to "My Orders" and select the order</li>
    <li>Click on "Report Issue" or "Help"</li>
    <li>Select the issue type and provide details</li>
    <li>Upload photos as evidence (required for quality issues)</li>
</ul>

<h3>4. Resolution Options</h3>
<p>Based on the issue, we may offer:</p>
<ul>
    <li><strong>Full Refund:</strong> For complete order issues</li>
    <li><strong>Partial Refund:</strong> For missing or incorrect items</li>
    <li><strong>Replacement:</strong> Subject to availability and restaurant/store consent</li>
    <li><strong>Zenfoo Credits:</strong> For future orders</li>
</ul>

<h3>5. Non-Eligible Situations</h3>
<ul>
    <li>Change of mind after delivery</li>
    <li>Taste preferences not met</li>
    <li>Issues reported after 24 hours</li>
    <li>Partially consumed items</li>
    <li>Issues not supported by evidence</li>
</ul>

<h3>6. Refund Timeline</h3>
<ul>
    <li>Wallet credits: Instant</li>
    <li>Original payment method: 5-7 business days</li>
</ul>

<h3>7. Contact Us</h3>
<p>For returns and exchange queries, please contact:</p>
<p><strong>Phone:</strong> 9999009090</p>
<p><strong>Email:</strong> support@zenfoo.in</p>
HTML;

        $shippingPolicy = <<<'HTML'
<h2>Shipping and Delivery Policy</h2>
<p><strong>Last Updated:</strong> February 2026</p>

<h3>1. Delivery Areas</h3>
<p>We currently deliver to select areas within our serviceable locations. Enter your delivery address to check if we deliver to your area.</p>

<h3>2. Delivery Hours</h3>
<ul>
    <li>Delivery hours vary by restaurant/store</li>
    <li>Check individual store timings on their page</li>
    <li>Late-night delivery available from select partners</li>
</ul>

<h3>3. Delivery Time</h3>
<ul>
    <li>Estimated delivery time is shown at checkout</li>
    <li>Delivery times are estimates and may vary based on:</li>
    <ul>
        <li>Restaurant/store preparation time</li>
        <li>Distance from the outlet</li>
        <li>Traffic and weather conditions</li>
        <li>Order volume during peak hours</li>
    </ul>
    <li>You will receive real-time updates on your order status</li>
</ul>

<h3>4. Delivery Charges</h3>
<ul>
    <li>Delivery charges vary based on distance and order value</li>
    <li>Free delivery may be available on orders above a certain value</li>
    <li>Delivery charges are displayed at checkout before payment</li>
    <li>Surge charges may apply during peak hours or bad weather</li>
</ul>

<h3>5. Contactless Delivery</h3>
<p>We offer contactless delivery option:</p>
<ul>
    <li>Select "Leave at door" during checkout</li>
    <li>Add specific delivery instructions if needed</li>
    <li>Delivery partner will place the order at your door and notify you</li>
</ul>

<h3>6. Delivery Instructions</h3>
<p>You can add delivery instructions such as:</p>
<ul>
    <li>Landmark details</li>
    <li>Alternate contact number</li>
    <li>Specific drop-off location</li>
    <li>Gate/security instructions</li>
</ul>

<h3>7. Failed Delivery</h3>
<p>Delivery may fail if:</p>
<ul>
    <li>Incorrect address provided</li>
    <li>Customer unreachable after multiple attempts</li>
    <li>Customer not available at delivery location</li>
    <li>Unsafe delivery conditions</li>
</ul>
<p>In case of failed delivery due to customer unavailability, refund/cancellation policy applies.</p>

<h3>8. Order Tracking</h3>
<ul>
    <li>Track your order in real-time through the app</li>
    <li>Receive notifications for order status updates</li>
    <li>Contact delivery partner directly through the app</li>
</ul>

<h3>9. Contact Us</h3>
<p>For delivery-related queries, please contact:</p>
<p><strong>Phone:</strong> 9999009090</p>
<p><strong>Email:</strong> support@zenfoo.in</p>
HTML;

        // Insert or update privacy policy
        DB::table('settings')->updateOrInsert(
            ['variable' => 'privacy_policy'],
            ['value' => $privacyPolicy]
        );

        // Insert or update terms and conditions
        DB::table('settings')->updateOrInsert(
            ['variable' => 'terms_conditions'],
            ['value' => $termsConditions]
        );

        // Insert or update cancellation policy
        DB::table('settings')->updateOrInsert(
            ['variable' => 'cancellation_policy'],
            ['value' => $cancellationPolicy]
        );

        // Insert or update returns and exchanges policy
        DB::table('settings')->updateOrInsert(
            ['variable' => 'returns_and_exchanges_policy'],
            ['value' => $returnsExchangesPolicy]
        );

        // Insert or update shipping policy
        DB::table('settings')->updateOrInsert(
            ['variable' => 'shipping_policy'],
            ['value' => $shippingPolicy]
        );
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('settings')->where('variable', 'privacy_policy')->delete();
        DB::table('settings')->where('variable', 'terms_conditions')->delete();
        DB::table('settings')->where('variable', 'cancellation_policy')->delete();
        DB::table('settings')->where('variable', 'returns_and_exchanges_policy')->delete();
        DB::table('settings')->where('variable', 'shipping_policy')->delete();
    }
};
