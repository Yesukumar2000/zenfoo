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
<h2>Privacy Policy for Sellers/Vendors</h2>
<p><strong>Last Updated:</strong> February 2026</p>

<h3>1. Introduction</h3>
<p>This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our seller/vendor application and services. Please read this privacy policy carefully.</p>

<h3>2. Information We Collect</h3>
<h4>2.1 Business Information</h4>
<ul>
    <li>Business name and registration details</li>
    <li>Owner/Manager name and contact details</li>
    <li>Phone number and email address</li>
    <li>Business address and location</li>
    <li>GSTIN and other tax-related documents</li>
    <li>FSSAI license (for food businesses)</li>
    <li>Bank account information for payment processing</li>
    <li>Store photographs and logo</li>
</ul>

<h4>2.2 Operational Information</h4>
<ul>
    <li>Product/Menu listings and pricing</li>
    <li>Order history and transaction records</li>
    <li>Inventory and stock information</li>
    <li>Business hours and availability</li>
</ul>

<h4>2.3 Device Information</h4>
<ul>
    <li>Device type, operating system, and unique device identifiers</li>
    <li>Mobile network information</li>
    <li>App usage data and performance metrics</li>
</ul>

<h3>3. How We Use Your Information</h3>
<ul>
    <li>To facilitate order management and processing</li>
    <li>To process payments and settlements</li>
    <li>To verify your business identity and eligibility</li>
    <li>To communicate important updates and notifications</li>
    <li>To display your business to customers on the platform</li>
    <li>To improve our services and user experience</li>
    <li>To ensure safety and security of all users</li>
    <li>To comply with legal obligations</li>
</ul>

<h3>4. Information Sharing</h3>
<p>We may share your information with:</p>
<ul>
    <li>Customers (business name, address, product listings, ratings)</li>
    <li>Delivery partners for order fulfillment</li>
    <li>Payment processors for settlements</li>
    <li>Law enforcement when legally required</li>
    <li>Service providers who assist in our operations</li>
</ul>

<h3>5. Data Security</h3>
<p>We implement appropriate technical and organizational security measures to protect your business information against unauthorized access, alteration, disclosure, or destruction.</p>

<h3>6. Data Retention</h3>
<p>We retain your business information for as long as your account is active or as needed to provide services. We may retain certain information as required by law or for legitimate business purposes.</p>

<h3>7. Your Rights</h3>
<p>You have the right to:</p>
<ul>
    <li>Access your business information</li>
    <li>Request correction of inaccurate data</li>
    <li>Request deletion of your data (subject to legal requirements)</li>
    <li>Opt-out of marketing communications</li>
</ul>

<h3>8. Contact Us</h3>
<p>For any privacy-related concerns or queries, please contact us:</p>
<p><strong>Phone:</strong> 9999009090</p>
<p><strong>Address:</strong> Kurnool</p>

<h3>9. Changes to This Policy</h3>
<p>We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.</p>
HTML;

        $termsConditions = <<<'HTML'
<h2>Terms and Conditions for Sellers/Vendors</h2>
<p><strong>Last Updated:</strong> February 2026</p>

<h3>1. Agreement to Terms</h3>
<p>By registering as a seller/vendor and using our platform, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our services.</p>

<h3>2. Eligibility Requirements</h3>
<p>To become a seller/vendor, you must:</p>
<ul>
    <li>Be a legally registered business entity</li>
    <li>Have valid business registration documents</li>
    <li>Possess valid GSTIN (if applicable)</li>
    <li>Have FSSAI license (for food businesses)</li>
    <li>Have a valid bank account for settlements</li>
    <li>Pass our verification process</li>
    <li>Have a smartphone or device capable of running our application</li>
</ul>

<h3>3. Seller/Vendor Responsibilities</h3>
<h4>3.1 Product/Service Quality</h4>
<ul>
    <li>Maintain high quality standards for all products/services</li>
    <li>Ensure accurate product descriptions and images</li>
    <li>Maintain proper hygiene and food safety standards (for food businesses)</li>
    <li>Use fresh and quality ingredients</li>
    <li>Ensure proper packaging for delivery</li>
</ul>

<h4>3.2 Order Management</h4>
<ul>
    <li>Accept orders only when able to fulfill them</li>
    <li>Prepare orders promptly and accurately</li>
    <li>Maintain accurate inventory and availability status</li>
    <li>Update menu/product listings regularly</li>
    <li>Notify customers of any delays or issues</li>
    <li>Handle customer complaints professionally</li>
</ul>

<h4>3.3 Pricing and Payments</h4>
<ul>
    <li>Set fair and competitive prices</li>
    <li>Maintain price consistency with in-store prices (if applicable)</li>
    <li>Accept platform-approved payment methods</li>
    <li>Provide accurate billing information</li>
</ul>

<h4>3.4 App Usage</h4>
<ul>
    <li>Keep the app active during business hours</li>
    <li>Update availability and business hours accurately</li>
    <li>Respond to orders within the specified time limit</li>
    <li>Do not share your account credentials with unauthorized persons</li>
</ul>

<h3>4. Prohibited Activities</h3>
<p>The following activities are strictly prohibited:</p>
<ul>
    <li>Selling counterfeit, illegal, or prohibited items</li>
    <li>Misrepresenting product quality or descriptions</li>
    <li>Price manipulation or unfair pricing practices</li>
    <li>Selling expired or substandard products</li>
    <li>Harassment or inappropriate behavior towards customers or delivery partners</li>
    <li>Providing false business information or documents</li>
    <li>Using the platform for fraudulent activities</li>
    <li>Directly contacting customers for off-platform transactions</li>
</ul>

<h3>5. Commission and Settlements</h3>
<ul>
    <li>Platform commission will be deducted as per the agreed rate</li>
    <li>Settlements are processed according to the payment schedule</li>
    <li>All applicable taxes are your responsibility</li>
    <li>Disputed payments must be reported within 7 days</li>
    <li>We reserve the right to hold settlements in case of disputes or violations</li>
</ul>

<h3>6. Ratings and Reviews</h3>
<ul>
    <li>Customer ratings and reviews will be displayed on your profile</li>
    <li>Maintain good ratings to stay active on the platform</li>
    <li>Do not incentivize customers for fake positive reviews</li>
    <li>Address negative feedback constructively</li>
</ul>

<h3>7. Account Suspension and Termination</h3>
<p>We reserve the right to suspend or terminate your account for:</p>
<ul>
    <li>Violation of these Terms and Conditions</li>
    <li>Poor product quality or service</li>
    <li>Low ratings or excessive customer complaints</li>
    <li>Fraudulent activities</li>
    <li>Failure to meet eligibility requirements</li>
    <li>Non-compliance with food safety regulations</li>
</ul>

<h3>8. Dispute Resolution</h3>
<p>Any disputes arising from these terms shall be resolved through:</p>
<ul>
    <li>First, through our internal grievance mechanism</li>
    <li>If unresolved, through mediation</li>
    <li>Finally, through the courts of Kurnool Judiciary</li>
</ul>

<h3>9. Modifications to Terms</h3>
<p>We reserve the right to modify these Terms and Conditions at any time. Continued use of our services after modifications constitutes acceptance of the updated terms.</p>

<h3>10. Contact Information</h3>
<p>For any questions or concerns regarding these terms, please contact us:</p>
<p><strong>Phone:</strong> 9999009090</p>
<p><strong>Address:</strong> Kurnool</p>

<h3>11. Governing Law</h3>
<p>These Terms and Conditions shall be governed by and construed in accordance with the laws of India, and any disputes shall be subject to the exclusive jurisdiction of the courts in Kurnool Judiciary.</p>
HTML;

        // Insert or update privacy policy
        DB::table('settings')->updateOrInsert(
            ['variable' => 'privacy_policy_seller'],
            ['value' => $privacyPolicy]
        );

        // Insert or update terms and conditions
        DB::table('settings')->updateOrInsert(
            ['variable' => 'terms_conditions_seller'],
            ['value' => $termsConditions]
        );
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('settings')->where('variable', 'privacy_policy_seller')->delete();
        DB::table('settings')->where('variable', 'terms_conditions_seller')->delete();
    }
};
