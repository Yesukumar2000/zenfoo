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
<h2>Privacy Policy for Delivery Partners</h2>
<p><strong>Last Updated:</strong> January 2026</p>

<h3>1. Introduction</h3>
<p>This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our delivery partner application and services. Please read this privacy policy carefully.</p>

<h3>2. Information We Collect</h3>
<h4>2.1 Personal Information</h4>
<ul>
    <li>Full name and contact details</li>
    <li>Phone number and email address</li>
    <li>Government-issued identification documents</li>
    <li>Vehicle registration and license details</li>
    <li>Bank account information for payment processing</li>
    <li>Profile photograph</li>
</ul>

<h4>2.2 Location Information</h4>
<ul>
    <li>Real-time GPS location during active deliveries</li>
    <li>Location history for completed deliveries</li>
    <li>Route information and navigation data</li>
</ul>

<h4>2.3 Device Information</h4>
<ul>
    <li>Device type, operating system, and unique device identifiers</li>
    <li>Mobile network information</li>
    <li>App usage data and performance metrics</li>
</ul>

<h3>3. How We Use Your Information</h3>
<ul>
    <li>To facilitate delivery operations and order management</li>
    <li>To process payments and earnings</li>
    <li>To verify your identity and eligibility</li>
    <li>To communicate important updates and notifications</li>
    <li>To improve our services and user experience</li>
    <li>To ensure safety and security of all users</li>
    <li>To comply with legal obligations</li>
</ul>

<h3>4. Information Sharing</h3>
<p>We may share your information with:</p>
<ul>
    <li>Customers (limited to name and delivery status)</li>
    <li>Restaurant/store partners for order coordination</li>
    <li>Payment processors for earnings disbursement</li>
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
<h2>Terms and Conditions for Delivery Partners</h2>
<p><strong>Last Updated:</strong> January 2026</p>

<h3>1. Agreement to Terms</h3>
<p>By registering as a delivery partner and using our platform, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our services.</p>

<h3>2. Eligibility Requirements</h3>
<p>To become a delivery partner, you must:</p>
<ul>
    <li>Be at least 18 years of age</li>
    <li>Possess a valid government-issued identification</li>
    <li>Have a valid driving license appropriate for your vehicle</li>
    <li>Own or have legal access to a delivery vehicle</li>
    <li>Have valid vehicle registration and insurance</li>
    <li>Pass our background verification process</li>
    <li>Have a smartphone capable of running our application</li>
</ul>

<h3>3. Delivery Partner Responsibilities</h3>
<h4>3.1 General Conduct</h4>
<ul>
    <li>Maintain professional behavior with customers and restaurant partners</li>
    <li>Follow all traffic rules and regulations</li>
    <li>Keep your vehicle clean and well-maintained</li>
    <li>Wear appropriate attire while on duty</li>
    <li>Handle food and packages with care</li>
</ul>

<h4>3.2 Order Handling</h4>
<ul>
    <li>Accept orders only when available to fulfill them</li>
    <li>Pick up orders promptly from the designated location</li>
    <li>Verify order contents before leaving the pickup point</li>
    <li>Deliver orders within the estimated time frame</li>
    <li>Handle cash payments honestly and accurately</li>
    <li>Report any issues immediately through the app</li>
</ul>

<h4>3.3 App Usage</h4>
<ul>
    <li>Keep the app active and GPS enabled during duty hours</li>
    <li>Update your availability status accurately</li>
    <li>Respond to orders within the specified time limit</li>
    <li>Do not share your account credentials with others</li>
</ul>

<h3>4. Prohibited Activities</h3>
<p>The following activities are strictly prohibited:</p>
<ul>
    <li>Delivering under the influence of alcohol or drugs</li>
    <li>Using the platform for illegal activities</li>
    <li>Tampering with or consuming customer orders</li>
    <li>Harassment or inappropriate behavior towards customers or partners</li>
    <li>Providing false information or documents</li>
    <li>Using unauthorized third-party apps or tools</li>
    <li>Sharing customer information with unauthorized parties</li>
</ul>

<h3>5. Earnings and Payments</h3>
<ul>
    <li>Earnings are calculated based on completed deliveries and applicable incentives</li>
    <li>Payments are processed according to the payment schedule specified in the app</li>
    <li>All applicable taxes are your responsibility</li>
    <li>Disputed payments must be reported within 7 days</li>
    <li>We reserve the right to deduct amounts for damages or violations</li>
</ul>

<h3>6. Insurance and Liability</h3>
<ul>
    <li>You are responsible for maintaining adequate vehicle insurance</li>
    <li>We are not liable for accidents or injuries occurring during deliveries</li>
    <li>You are responsible for any traffic violations or fines incurred</li>
    <li>Damage to customer orders due to negligence is your responsibility</li>
</ul>

<h3>7. Account Suspension and Termination</h3>
<p>We reserve the right to suspend or terminate your account for:</p>
<ul>
    <li>Violation of these Terms and Conditions</li>
    <li>Poor performance or low ratings</li>
    <li>Fraudulent activities</li>
    <li>Customer complaints</li>
    <li>Failure to meet eligibility requirements</li>
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
            ['variable' => 'privacy_policy_delivery_boy'],
            ['value' => $privacyPolicy]
        );

        // Insert or update terms and conditions
        DB::table('settings')->updateOrInsert(
            ['variable' => 'terms_conditions_delivery_boy'],
            ['value' => $termsConditions]
        );
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('settings')->where('variable', 'privacy_policy_delivery_boy')->delete();
        DB::table('settings')->where('variable', 'terms_conditions_delivery_boy')->delete();
    }
};
