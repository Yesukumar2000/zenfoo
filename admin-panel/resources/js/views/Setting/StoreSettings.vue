<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>{{ __('store_settings') }}</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item">
                                    <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                                </li>
                                <li class="breadcrumb-item active" aria-current="page">{{ __('store_settings') }}</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <!-- Loading State -->
            <div class="text-center py-5" v-if="isLoading">
                <b-spinner class="align-middle"></b-spinner>
                <strong class="ms-2">Loading settings...</strong>
            </div>

            <section class="section" v-else>
                <div class="row">
                    <!-- Support Settings -->
                    <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Support Settings</h4>
                            </div>
                            <div class="card-body">
                                <!-- Global support contacts are now set per app below, so the
                                     shared pair is no longer editable here. The stored values stay
                                     in place as the fallback for SMS templates and the web config.
                                <div class="form-group">
                                    <label for="support_number">Support Phone Number</label>
                                    <input type="text" class="form-control" id="support_number" v-model="settings.support_number" placeholder="Enter support phone number">
                                </div>
                                <div class="form-group">
                                    <label for="support_email">Support Email</label>
                                    <input type="email" class="form-control" id="support_email" v-model="settings.support_email" placeholder="Enter support email">
                                </div>

                                <hr class="my-4">
                                -->
                                <h6 class="mb-1">Per-App Contacts</h6>
                                <p class="text-muted small mb-3">Set the help desk phone and email each app should show.</p>

                                <div v-for="app in supportApps" :key="app.key" class="mb-3">
                                    <label class="form-label fw-semibold">{{ app.label }}</label>
                                    <div class="row g-2">
                                        <div class="col-6">
                                            <input type="text" class="form-control" :id="'support_number_' + app.key" v-model="settings['support_number_' + app.key]" placeholder="Phone (optional)">
                                        </div>
                                        <div class="col-6">
                                            <input type="email" class="form-control" :id="'support_email_' + app.key" v-model="settings['support_email_' + app.key]" placeholder="Email (optional)">
                                        </div>
                                    </div>
                                </div>

                                <button class="btn btn-primary" @click="saveSection('support')" :disabled="saving.support">
                                    <span v-if="saving.support"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Google Maps Settings -->
                    <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Google Maps Settings</h4>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label for="google_map_api_key">Google Maps API Key</label>
                                    <input type="text" class="form-control" id="google_map_api_key" v-model="settings.google_map_api_key" placeholder="Enter Google Maps API Key">
                                    <!-- <small class="text-muted">This will update all 3 Google API key fields</small> -->
                                </div>
                                <button class="btn btn-primary" @click="saveSection('google_maps')" :disabled="saving.google_maps">
                                    <span v-if="saving.google_maps"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- AWS S3 Storage Settings -->
                    <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Media Storage Settings</h4>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label for="storage_driver">Storage Driver</label>
                                    <select class="form-control form-select" id="storage_driver" v-model="settings.storage_driver">
                                        <option value="s3">AWS S3 (Cloud)</option>
                                        <option value="local">Local Server (storage/app/public/uploads)</option>
                                    </select>
                                    <small class="text-muted">
                                        Choose where uploaded media is stored. Switch to "Local Server" to bypass AWS while S3 is unavailable.
                                    </small>
                                </div>
                                <div class="alert alert-info" v-if="settings.storage_driver !== 'local'">
                                    <i class="fa fa-info-circle me-1"></i>
                                    All uploaded files (images, videos, documents) are stored on AWS S3. Configure your S3 bucket credentials below.
                                </div>
                             
                                <div class="form-group" v-if="settings.storage_driver !== 'local'">
                                    <label for="aws_access_key_id">Access Key ID</label>
                                    <input type="text" class="form-control" id="aws_access_key_id" v-model="settings.aws_access_key_id" placeholder="Enter AWS Access Key ID">
                                </div>
                                <div class="form-group" v-if="settings.storage_driver !== 'local'">
                                    <label for="aws_secret_access_key">Secret Access Key</label>
                                    <div class="input-group">
                                        <input :type="showAwsSecret ? 'text' : 'password'" class="form-control" id="aws_secret_access_key" v-model="settings.aws_secret_access_key" placeholder="Enter AWS Secret Access Key">
                                        <button class="btn btn-outline-secondary" type="button" @click="showAwsSecret = !showAwsSecret">
                                            <i :class="showAwsSecret ? 'fa fa-eye-slash' : 'fa fa-eye'"></i>
                                        </button>
                                    </div>
                                </div>
                                <div class="form-group" v-if="settings.storage_driver !== 'local'">
                                    <label for="aws_default_region">Region</label>
                                    <input type="text" class="form-control" id="aws_default_region" v-model="settings.aws_default_region" placeholder="e.g., us-east-1, ap-south-1">
                                </div>
                                <div class="form-group" v-if="settings.storage_driver !== 'local'">
                                    <label for="aws_bucket">Bucket Name</label>
                                    <input type="text" class="form-control" id="aws_bucket" v-model="settings.aws_bucket" placeholder="Enter S3 bucket name">
                                </div>
                                <button class="btn btn-primary me-2" @click="saveSection('aws_s3')" :disabled="saving.aws_s3">
                                    <span v-if="saving.aws_s3"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                                <button class="btn btn-outline-success" @click="testS3Connection" :disabled="testingS3" v-if="settings.storage_driver !== 'local'">
                                    <span v-if="testingS3"><i class="fa fa-spinner fa-spin me-1"></i>Testing...</span>
                                    <span v-else><i class="fa fa-cloud-upload me-1"></i>Test S3 Connection</span>
                                </button>
                                <div v-if="s3TestResult && settings.storage_driver !== 'local'" class="mt-2">
                                    <div :class="s3TestResult.success ? 'alert alert-success' : 'alert alert-danger'" class="py-2 px-3 mb-0">
                                        <small>{{ s3TestResult.message }}</small>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Razorpay Settings - Commented for now -->
                    <!-- <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Razorpay Settings</h4>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label for="razorpay_key">Razorpay Key ID</label>
                                    <input type="text" class="form-control" id="razorpay_key" v-model="settings.razorpay_key" placeholder="rzp_test_xxx or rzp_live_xxx">
                                </div>
                                <div class="form-group">
                                    <label for="razorpay_secret_key">Razorpay Secret Key</label>
                                    <div class="input-group">
                                        <input :type="showRazorpaySecret ? 'text' : 'password'" class="form-control" id="razorpay_secret_key" v-model="settings.razorpay_secret_key" placeholder="Enter Razorpay Secret Key">
                                        <button class="btn btn-outline-secondary" type="button" @click="showRazorpaySecret = !showRazorpaySecret">
                                            <i :class="showRazorpaySecret ? 'fa fa-eye-slash' : 'fa fa-eye'"></i>
                                        </button>
                                    </div>
                                </div>
                                <button class="btn btn-primary" @click="saveSection('razorpay')" :disabled="saving.razorpay">
                                    <span v-if="saving.razorpay"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div> -->

                    <!-- PhonePe Settings - Commented for now -->
                    <!-- <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">PhonePe Settings</h4>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label for="phonepay_merchant_id">Merchant ID</label>
                                    <input type="text" class="form-control" id="phonepay_merchant_id" v-model="settings.phonepay_merchant_id" placeholder="Enter Merchant ID">
                                </div>
                                <div class="form-group">
                                    <label for="phonepay_client_id">Client ID</label>
                                    <input type="text" class="form-control" id="phonepay_client_id" v-model="settings.phonepay_client_id" placeholder="Enter Client ID">
                                </div>
                                <div class="form-group">
                                    <label for="phonepay_client_secret">Client Secret</label>
                                    <div class="input-group">
                                        <input :type="showPhonePeSecret ? 'text' : 'password'" class="form-control" id="phonepay_client_secret" v-model="settings.phonepay_client_secret" placeholder="Enter Client Secret">
                                        <button class="btn btn-outline-secondary" type="button" @click="showPhonePeSecret = !showPhonePeSecret">
                                            <i :class="showPhonePeSecret ? 'fa fa-eye-slash' : 'fa fa-eye'"></i>
                                        </button>
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label for="phonepay_client_version">Client Version</label>
                                    <input type="text" class="form-control" id="phonepay_client_version" v-model="settings.phonepay_client_version" placeholder="Enter Client Version (e.g., 1)">
                                </div>
                                <div class="form-group">
                                    <label for="phonepay_payment_endpoint_url">Payment Endpoint URL <small>(Optional)</small></label>
                                    <input type="text" class="form-control" id="phonepay_payment_endpoint_url" v-model="settings.phonepay_payment_endpoint_url" placeholder="Enter Payment Endpoint URL">
                                </div>
                                <button class="btn btn-primary" @click="saveSection('phonepe')" :disabled="saving.phonepe">
                                    <span v-if="saving.phonepe"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div> -->


                    <!-- Paytm Settings -->
                    <div class="col-12 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Paytm Settings</h4>
                            </div>
                            <div class="card-body">
                                <div class="row">
                                    <!-- Test Credentials -->
                                    <div class="col-md-6">
                                        <h5 class="text-primary mb-3"><i class="fa fa-flask me-2"></i>Test/Staging Credentials</h5>
                                        <div class="form-group">
                                            <label for="paytm_test_merchant_id">Test Merchant ID (MID)</label>
                                            <input type="text" class="form-control" id="paytm_test_merchant_id" v-model="settings.paytm_test_merchant_id" placeholder="Enter Test Merchant ID">
                                        </div>
                                        <div class="form-group">
                                            <label for="paytm_test_merchant_key">Test Merchant Key</label>
                                            <div class="input-group">
                                                <input :type="showPaytmTestKey ? 'text' : 'password'" class="form-control" id="paytm_test_merchant_key" v-model="settings.paytm_test_merchant_key" placeholder="Enter Test Merchant Key">
                                                <button class="btn btn-outline-secondary" type="button" @click="showPaytmTestKey = !showPaytmTestKey">
                                                    <i :class="showPaytmTestKey ? 'fa fa-eye-slash' : 'fa fa-eye'"></i>
                                                </button>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <label for="paytm_test_website">Test Website Name</label>
                                            <input type="text" class="form-control" id="paytm_test_website" v-model="settings.paytm_test_website" placeholder="e.g., WEBSTAGING">
                                        </div>
                                        <div class="form-group">
                                            <label for="paytm_test_industry_type">Test Industry Type</label>
                                            <input type="text" class="form-control" id="paytm_test_industry_type" v-model="settings.paytm_test_industry_type" placeholder="e.g., Retail">
                                        </div>
                                        <div class="form-group">
                                            <label for="paytm_test_channel_id">Test Channel ID</label>
                                            <input type="text" class="form-control" id="paytm_test_channel_id" v-model="settings.paytm_test_channel_id" placeholder="e.g., WEB">
                                            <small class="text-muted">WEB for website, WAP for mobile</small>
                                        </div>
                                    </div>

                                    <!-- Live Credentials -->
                                    <div class="col-md-6">
                                        <h5 class="text-success mb-3"><i class="fa fa-globe me-2"></i>Live/Production Credentials</h5>
                                        <div class="form-group">
                                            <label for="paytm_live_merchant_id">Live Merchant ID (MID)</label>
                                            <input type="text" class="form-control" id="paytm_live_merchant_id" v-model="settings.paytm_live_merchant_id" placeholder="Enter Live Merchant ID">
                                        </div>
                                        <div class="form-group">
                                            <label for="paytm_live_merchant_key">Live Merchant Key</label>
                                            <div class="input-group">
                                                <input :type="showPaytmLiveKey ? 'text' : 'password'" class="form-control" id="paytm_live_merchant_key" v-model="settings.paytm_live_merchant_key" placeholder="Enter Live Merchant Key">
                                                <button class="btn btn-outline-secondary" type="button" @click="showPaytmLiveKey = !showPaytmLiveKey">
                                                    <i :class="showPaytmLiveKey ? 'fa fa-eye-slash' : 'fa fa-eye'"></i>
                                                </button>
                                            </div>
                                        </div>
                                        <div class="form-group">
                                            <label for="paytm_live_website">Live Website Name</label>
                                            <input type="text" class="form-control" id="paytm_live_website" v-model="settings.paytm_live_website" placeholder="e.g., DEFAULT">
                                        </div>
                                        <div class="form-group">
                                            <label for="paytm_live_industry_type">Live Industry Type</label>
                                            <input type="text" class="form-control" id="paytm_live_industry_type" v-model="settings.paytm_live_industry_type" placeholder="e.g., Retail">
                                        </div>
                                        <div class="form-group">
                                            <label for="paytm_live_channel_id">Live Channel ID</label>
                                            <input type="text" class="form-control" id="paytm_live_channel_id" v-model="settings.paytm_live_channel_id" placeholder="e.g., WEB">
                                            <small class="text-muted">WEB for website, WAP for mobile</small>
                                        </div>
                                    </div>
                                </div>

                                <!-- Environment Selection -->
                                <div class="row mt-3">
                                    <div class="col-md-12">
                                        <div class="form-group">
                                            <label for="paytm_environment">Paytm Environment</label>
                                            <select class="form-control form-select" id="paytm_environment" v-model="settings.paytm_environment">
                                                <option value="test">Test/Staging (https://securegw-stage.paytm.in)</option>
                                                <option value="live">Live/Production (https://securegw.paytm.in)</option>
                                            </select>
                                            <small class="text-warning">⚠️ Select which environment to use for Paytm transactions</small>
                                        </div>
                                    </div>
                                </div>

                                <button class="btn btn-primary mt-2" @click="saveSection('paytm')" :disabled="saving.paytm">
                                    <span v-if="saving.paytm"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Multi-Order Bonus -->
                    <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Multi-Order Bonus</h4>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label for="multi_order_bonus">Bonus Amount ({{ $currency }})</label>
                                    <input type="number" class="form-control" id="multi_order_bonus" v-model="settings.multi_order_bonus" placeholder="Enter bonus amount">
                                    <small class="text-muted">Bonus given to delivery boy for multi-order deliveries</small>
                                </div>
                                <button class="btn btn-primary" @click="saveSection('multi_order')" :disabled="saving.multi_order">
                                    <span v-if="saving.multi_order"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Referral Program Settings -->
                    <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Referral Program Settings</h4>
                            </div>
                            <div class="card-body">
                                <h6 class="text-uppercase text-muted mb-3">Customer (Refer &amp; Earn)</h6>
                                <div class="form-group">
                                    <label for="referral_credit_first_order">Referral Credit on Friend's First Order ({{ $currency }})</label>
                                    <input type="number" class="form-control" id="referral_credit_first_order" v-model="settings.referral_credit_first_order" placeholder="Enter bonus amount" min="0" step="0.01">
                                    <small class="text-muted">Wallet credit given to the referrer once their invited friend's first order is delivered. Set to 0 to turn customer Refer &amp; Earn off.</small>
                                </div>
                                <div class="form-group">
                                    <label for="referral_min_order_amount">Minimum Order Amount for Referral ({{ $currency }})</label>
                                    <input type="number" class="form-control" id="referral_min_order_amount" v-model="settings.referral_min_order_amount" placeholder="Enter minimum order amount" min="0" step="0.01">
                                    <small class="text-muted">The friend's first order must reach this total for the referrer to earn the bonus</small>
                                </div>
                                <div class="form-group">
                                    <label for="max_refer_earn_amount">Lifetime Referral Earning Cap ({{ $currency }})</label>
                                    <input type="number" class="form-control" id="max_refer_earn_amount" v-model="settings.max_refer_earn_amount" placeholder="Enter cap amount" min="0" step="0.01">
                                    <small class="text-muted">Maximum a single customer can earn from referrals in total. Leave 0 for unlimited.</small>
                                </div>

                                <hr>
                                <h6 class="text-uppercase text-muted mb-3">Driver</h6>
                                <div class="form-group">
                                    <label for="referral_driver_order_count">Required Orders for Referral Bonus</label>
                                    <input type="number" class="form-control" id="referral_driver_order_count" v-model="settings.referral_driver_order_count" placeholder="Enter number of orders" min="1">
                                    <small class="text-muted">Number of orders a referred driver must complete before referring driver earns bonus</small>
                                </div>
                                <div class="form-group">
                                    <label for="referral_driver_amount">Referral Bonus Amount ({{ $currency }})</label>
                                    <input type="number" class="form-control" id="referral_driver_amount" v-model="settings.referral_driver_amount" placeholder="Enter bonus amount" min="0" step="0.01">
                                    <small class="text-muted">Bonus amount given to driver who referred another driver</small>
                                </div>
                                <button class="btn btn-primary" @click="saveSection('referral_program')" :disabled="saving.referral_program">
                                    <span v-if="saving.referral_program"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- App Store Links -->
                    <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">App Store Links</h4>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label for="playstore_url">Play Store URL (Android)</label>
                                    <input type="url" class="form-control" id="playstore_url" v-model="settings.playstore_url" placeholder="https://play.google.com/store/apps/details?id=com.zenfoo.customer">
                                    <small class="text-muted">Used in the Refer &amp; Earn invite message, Share App, and the force-update prompt</small>
                                </div>
                                <div class="form-group">
                                    <label for="appstore_url">App Store URL (iOS)</label>
                                    <input type="url" class="form-control" id="appstore_url" v-model="settings.appstore_url" placeholder="https://apps.apple.com/app/id...">
                                    <small class="text-muted">Same, for iOS customers. Leave blank until the iOS app is published.</small>
                                </div>
                                <button class="btn btn-primary" @click="saveSection('app_store_links')" :disabled="saving.app_store_links">
                                    <span v-if="saving.app_store_links"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Rain Surcharge -->
                    <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Rain Surcharge</h4>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label for="rain_surcharge_amount">Rain Surcharge Amount ({{ $currency }})</label>
                                    <input type="number" class="form-control" id="rain_surcharge_amount" v-model="settings.rain_surcharge_amount" placeholder="Enter rain surcharge amount" min="0" step="0.01">
                                    <small class="text-muted">Extra charge applied to orders during rainy weather</small>
                                </div>
                                <button class="btn btn-primary" @click="saveSection('rain_surcharge')" :disabled="saving.rain_surcharge">
                                    <span v-if="saving.rain_surcharge"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Max Hand Cash Limit (Feature not implemented) -->
                    <!--
                    <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Hand Cash Limit</h4>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label for="max_hand_cash_limit">Max Hand Cash Limit ({{ $currency }})</label>
                                    <input type="number" class="form-control" id="max_hand_cash_limit" v-model="settings.max_hand_cash_limit" placeholder="Enter max hand cash limit" min="0" step="1">
                                    <small class="text-muted">Delivery boys with unsettled hand cash above this limit won't receive new orders</small>
                                </div>
                                <button class="btn btn-primary" @click="saveSection('hand_cash_limit')" :disabled="saving.hand_cash_limit">
                                    <span v-if="saving.hand_cash_limit"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>
                    -->

                    <!-- Emergency Contacts -->
                    <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Emergency Contacts</h4>
                            </div>
                            <div class="card-body">
                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="emergency_zenfoo_phone">Zenfoo Emergency Phone</label>
                                            <input type="text" class="form-control" id="emergency_zenfoo_phone" v-model="settings.emergency_zenfoo_phone" placeholder="Enter phone">
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="emergency_zenfoo_email">Zenfoo Emergency Email</label>
                                            <input type="email" class="form-control" id="emergency_zenfoo_email" v-model="settings.emergency_zenfoo_email" placeholder="Enter email">
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="emergency_police_phone">Police Phone</label>
                                            <input type="text" class="form-control" id="emergency_police_phone" v-model="settings.emergency_police_phone" placeholder="e.g., 100">
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="emergency_ambulance_phone">Ambulance Phone</label>
                                            <input type="text" class="form-control" id="emergency_ambulance_phone" v-model="settings.emergency_ambulance_phone" placeholder="e.g., 108">
                                        </div>
                                    </div>
                                </div>
                                <button class="btn btn-primary" @click="saveSection('emergency')" :disabled="saving.emergency">
                                    <span v-if="saving.emergency"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Admin Payment Details (for Driver Manual Payments) -->
                    <div class="col-12 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Admin Payment Details (for Driver Manual Payments)</h4>
                            </div>
                            <div class="card-body">
                                <div class="alert alert-info">
                                    <i class="fa fa-info-circle me-1"></i>
                                    <strong>Manual Payment System:</strong> Drivers can pay admin for COD settlements via UPI or bank transfer. Configure your payment details below.
                                    <br>Drivers will see these details in their app and can submit payment proof for admin approval.
                                </div>

                                <!-- Deposit Method Toggles -->
                                <div class="mb-4">
                                    <label class="fw-bold mb-1 d-block">Deposit Methods <span class="text-muted">(shown to drivers)</span></label>
                                    <small class="text-muted d-block mb-3">Turn each deposit option on/off. At least one method must stay enabled.</small>
                                    <div class="row g-3">
                                        <div class="col-md-4">
                                            <div class="deposit-method-card" :class="{ 'is-active': settings.deposit_method_bank == 1 }">
                                                <div class="deposit-method-card__icon"><i class="fa fa-university"></i></div>
                                                <div class="deposit-method-card__body">
                                                    <span class="deposit-method-card__title">Bank Deposit</span>
                                                    <small class="text-muted">CDM / ATM</small>
                                                </div>
                                                <div class="form-check form-switch m-0">
                                                    <input class="form-check-input" id="deposit_method_bank" type="checkbox" true-value="1" false-value="0" v-model="settings.deposit_method_bank">
                                                </div>
                                            </div>
                                        </div>
                                        <div class="col-md-4">
                                            <div class="deposit-method-card" :class="{ 'is-active': settings.deposit_method_upi == 1 }">
                                                <div class="deposit-method-card__icon"><i class="fa fa-mobile"></i></div>
                                                <div class="deposit-method-card__body">
                                                    <span class="deposit-method-card__title">UPI Transfer</span>
                                                    <small class="text-muted">Pay to UPI ID</small>
                                                </div>
                                                <div class="form-check form-switch m-0">
                                                    <input class="form-check-input" id="deposit_method_upi" type="checkbox" true-value="1" false-value="0" v-model="settings.deposit_method_upi">
                                                </div>
                                            </div>
                                        </div>
                                        <div class="col-md-4">
                                            <div class="deposit-method-card" :class="{ 'is-active': settings.deposit_method_qr == 1 }">
                                                <div class="deposit-method-card__icon"><i class="fa fa-qrcode"></i></div>
                                                <div class="deposit-method-card__body">
                                                    <span class="deposit-method-card__title">Zenfoo QR</span>
                                                    <small class="text-muted">Pay to Zenfoo QR</small>
                                                </div>
                                                <div class="form-check form-switch m-0">
                                                    <input class="form-check-input" id="deposit_method_qr" type="checkbox" true-value="1" false-value="0" v-model="settings.deposit_method_qr">
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- Zenfoo QR Image -->
                                <div class="row mb-3" v-if="settings.deposit_method_qr == 1">
                                    <div class="col-md-6">
                                        <label for="admin_qr_image" class="fw-bold mb-2"><i class="fa fa-qrcode me-1"></i>Zenfoo Payment QR Image</label>
                                        <div class="qr-upload-box">
                                            <div v-if="settings.admin_qr_image" class="qr-upload-box__preview">
                                                <img :src="settings.admin_qr_image" alt="Zenfoo QR" class="qr-upload-box__img">
                                                <div class="mt-2">
                                                    <span class="badge bg-success"><i class="fa fa-check me-1"></i>QR uploaded</span>
                                                    <a :href="settings.admin_qr_image" target="_blank" class="ms-2 small">View full size</a>
                                                </div>
                                            </div>
                                            <div v-else class="qr-upload-box__placeholder">
                                                <i class="fa fa-cloud-upload"></i>
                                                <span>No QR uploaded yet</span>
                                            </div>
                                            <input type="file" class="form-control mt-3" id="admin_qr_image" @change="handleAdminQrUpload" accept="image/*" ref="adminQrInput">
                                            <small class="text-muted d-block mt-2">Drivers scan this QR with their UPI app, pay, then upload the payment screenshot.</small>
                                        </div>
                                    </div>
                                </div>

                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="admin_upi_id">Admin UPI ID</label>
                                            <input type="text" class="form-control" id="admin_upi_id" v-model="settings.admin_upi_id" placeholder="e.g., admin@paytm or admin@ybl">
                                            <small class="text-muted">Your UPI ID where drivers will send payments</small>
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="admin_bank_name">Bank Name</label>
                                            <input type="text" class="form-control" id="admin_bank_name" v-model="settings.admin_bank_name" placeholder="e.g., State Bank of India">
                                            <small class="text-muted">Your bank name for NEFT/RTGS/IMPS transfers</small>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <div class="form-group">
                                            <label for="admin_bank_account_number">Bank Account Number</label>
                                            <input type="text" class="form-control" id="admin_bank_account_number" v-model="settings.admin_bank_account_number" placeholder="e.g., 1234567890">
                                            <small class="text-muted">Your bank account number</small>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <div class="form-group">
                                            <label for="admin_bank_ifsc_code">Bank IFSC Code</label>
                                            <input type="text" class="form-control" id="admin_bank_ifsc_code" v-model="settings.admin_bank_ifsc_code" placeholder="e.g., SBIN0001234">
                                            <small class="text-muted">11-character IFSC code of your bank branch</small>
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <div class="form-group">
                                            <label for="admin_bank_account_holder_name">Account Holder Name</label>
                                            <input type="text" class="form-control" id="admin_bank_account_holder_name" v-model="settings.admin_bank_account_holder_name" placeholder="e.g., Admin Name">
                                            <small class="text-muted">Name as per bank account</small>
                                        </div>
                                    </div>
                                </div>
                                <div class="mt-3" style="background: none; color: #000;">
                                    <i class="fa fa-info-circle me-1"></i>
                                    <strong>Note:</strong> Keep this information accurate and up-to-date. Drivers will use these details to make manual payments for settling COD cash.
                                </div>
                                <button class="btn btn-primary" @click="saveSection('admin_payment_details')" :disabled="saving.admin_payment_details">
                                    <span v-if="saving.admin_payment_details"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Not Getting Orders Help -->
                    <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Not Getting Orders Help</h4>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label for="not_getting_orders_video">Help Video</label>
                                    <input type="file" class="form-control" id="not_getting_orders_video" @change="handleVideoUpload" accept="video/*" ref="videoInput">
                                    <small class="text-muted">Upload a help video for delivery boys</small>
                                    <div v-if="settings.not_getting_orders_video" class="mt-2">
                                        <span class="badge bg-success">Video uploaded</span>
                                        <a :href="settings.not_getting_orders_video" target="_blank" class="ms-2">View Video</a>
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label for="not_getting_orders_title">Help Title</label>
                                    <input type="text" class="form-control" id="not_getting_orders_title" v-model="settings.not_getting_orders_title" placeholder="Enter help title">
                                </div>
                                <div class="form-group">
                                    <label for="not_getting_orders_steps">Help Steps (JSON Array)</label>
                                    <textarea class="form-control" id="not_getting_orders_steps" v-model="settings.not_getting_orders_steps" rows="4" placeholder='[{"step_number":1,"title":"Step 1"},{"step_number":2,"title":"Step 2"}]'></textarea>
                                    <small class="text-muted">Enter steps as JSON array</small>
                                </div>
                                <button class="btn btn-primary" @click="saveSection('not_getting_orders')" :disabled="saving.not_getting_orders">
                                    <span v-if="saving.not_getting_orders"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- App Media (Videos & Images) -->
                    <div class="col-12 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">App Media (Videos & Images)</h4>
                            </div>
                            <div class="card-body">
                                <div class="row">
                                    <!-- Bike Moving Animation -->
                                    <div class="col-md-4">
                                        <div class="form-group">
                                            <label for="bike_moving_animation">Bike Moving Animation</label>
                                            <input type="file" class="form-control" id="bike_moving_animation" @change="handleBikeAnimationUpload" accept="video/*" ref="bikeVideoInput">
                                            <small class="text-muted">Upload animation for bike movement on map</small>
                                            <div v-if="settings.bike_moving_animation" class="mt-2">
                                                <span class="badge bg-success">Video uploaded</span>
                                                <a :href="settings.bike_moving_animation" target="_blank" class="ms-2">View Video</a>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- Customer Login Products Animation -->
                                    <div class="col-md-4">
                                        <div class="form-group">
                                            <label for="customer_login_products_animation">Customer Login Products Animation</label>
                                            <input type="file" class="form-control" id="customer_login_products_animation" @change="handleCustomerLoginAnimationUpload" accept="video/*" ref="customerLoginVideoInput">
                                            <small class="text-muted">Upload animation for customer login screen</small>
                                            <div v-if="settings.customer_login_products_animation" class="mt-2">
                                                <span class="badge bg-success">Video uploaded</span>
                                                <a :href="settings.customer_login_products_animation" target="_blank" class="ms-2">View Video</a>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- All Stores Image -->
                                    <div class="col-md-4">
                                        <div class="form-group">
                                            <label for="all_stores_img">All Stores Image</label>
                                            <input type="file" class="form-control" id="all_stores_img" @change="handleAllStoresImgUpload" accept="image/*" ref="allStoresImgInput">
                                            <small class="text-muted">Upload image for home screen "All Stores" section</small>
                                            <div v-if="settings.all_stores_img" class="mt-2">
                                                <img :src="settings.all_stores_img" alt="All Stores" style="max-width: 100%; max-height: 150px;" class="mb-2 rounded">
                                                <br>
                                                <span class="badge bg-success">Image uploaded</span>
                                                <a :href="settings.all_stores_img" target="_blank" class="ms-2">View Image</a>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- Explore Logo Icon -->
                                    <div class="col-md-4">
                                        <div class="form-group">
                                            <label for="explore_logo_icon">Explore Logo Icon</label>
                                            <input type="file" class="form-control" id="explore_logo_icon" @change="handleExploreLogoUpload" accept="image/*,video/*" ref="exploreLogoInput">
                                            <small class="text-muted">Upload logo icon for Explore section (supports images, GIF, and videos)</small>
                                            <div v-if="settings.explore_logo_icon" class="mt-2">
                                                <img :src="settings.explore_logo_icon" alt="Explore Logo" style="max-width: 100%; max-height: 150px;" class="mb-2 rounded">
                                                <br>
                                                <span class="badge bg-success">Media uploaded</span>
                                                <a :href="settings.explore_logo_icon" target="_blank" class="ms-2">View Media</a>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <button class="btn btn-primary mt-2" @click="saveSection('app_media')" :disabled="saving.app_media">
                                    <span v-if="saving.app_media"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save Media</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Store Placeholder Images -->
                    <div class="col-12 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Store Placeholder Images</h4>
                            </div>
                            <div class="card-body">
                                <div class="alert alert-info">
                                    <i class="fa fa-info-circle me-1"></i>
                                    These images are shown in the customer app when a product has no image, based on which store the product belongs to.
                                </div>
                                <div class="row">
                                    <!-- Food Store -->
                                    <div class="col-md-4 mb-3">
                                        <div class="form-group">
                                            <label for="store_placeholder_img_food">Food Store</label>
                                            <input type="file" class="form-control" id="store_placeholder_img_food" @change="handlePlaceholderUpload('food', $event)" accept="image/*" ref="placeholderFoodInput">
                                            <small class="text-muted">Placeholder for food store products</small>
                                            <div v-if="settings.store_placeholder_img_food" class="mt-2">
                                                <img :src="settings.store_placeholder_img_food" alt="Food Placeholder" style="max-width: 100%; max-height: 120px; object-fit: contain;" class="mb-1 rounded border">
                                                <br>
                                                <span class="badge bg-success">Uploaded</span>
                                                <a :href="settings.store_placeholder_img_food" target="_blank" class="ms-2 small">View</a>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- Vegetables & Fruits -->
                                    <div class="col-md-4 mb-3">
                                        <div class="form-group">
                                            <label for="store_placeholder_img_veg">Vegetables & Fruits</label>
                                            <input type="file" class="form-control" id="store_placeholder_img_veg" @change="handlePlaceholderUpload('veg', $event)" accept="image/*" ref="placeholderVegInput">
                                            <small class="text-muted">Placeholder for vegetable & fruit products</small>
                                            <div v-if="settings.store_placeholder_img_veg" class="mt-2">
                                                <img :src="settings.store_placeholder_img_veg" alt="Veg Placeholder" style="max-width: 100%; max-height: 120px; object-fit: contain;" class="mb-1 rounded border">
                                                <br>
                                                <span class="badge bg-success">Uploaded</span>
                                                <a :href="settings.store_placeholder_img_veg" target="_blank" class="ms-2 small">View</a>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- Grocery & Kitchen -->
                                    <div class="col-md-4 mb-3">
                                        <div class="form-group">
                                            <label for="store_placeholder_img_grocery">Grocery & Kitchen</label>
                                            <input type="file" class="form-control" id="store_placeholder_img_grocery" @change="handlePlaceholderUpload('grocery', $event)" accept="image/*" ref="placeholderGroceryInput">
                                            <small class="text-muted">Placeholder for grocery & kitchen products</small>
                                            <div v-if="settings.store_placeholder_img_grocery" class="mt-2">
                                                <img :src="settings.store_placeholder_img_grocery" alt="Grocery Placeholder" style="max-width: 100%; max-height: 120px; object-fit: contain;" class="mb-1 rounded border">
                                                <br>
                                                <span class="badge bg-success">Uploaded</span>
                                                <a :href="settings.store_placeholder_img_grocery" target="_blank" class="ms-2 small">View</a>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- Chicken & Meat -->
                                    <div class="col-md-4 mb-3">
                                        <div class="form-group">
                                            <label for="store_placeholder_img_meat">Chicken & Meat</label>
                                            <input type="file" class="form-control" id="store_placeholder_img_meat" @change="handlePlaceholderUpload('meat', $event)" accept="image/*" ref="placeholderMeatInput">
                                            <small class="text-muted">Placeholder for chicken & meat products (is_meat = 1)</small>
                                            <div v-if="settings.store_placeholder_img_meat" class="mt-2">
                                                <img :src="settings.store_placeholder_img_meat" alt="Meat Placeholder" style="max-width: 100%; max-height: 120px; object-fit: contain;" class="mb-1 rounded border">
                                                <br>
                                                <span class="badge bg-success">Uploaded</span>
                                                <a :href="settings.store_placeholder_img_meat" target="_blank" class="ms-2 small">View</a>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- Super Mart -->
                                    <div class="col-md-4 mb-3">
                                        <div class="form-group">
                                            <label for="store_placeholder_img_supermart">Super Mart</label>
                                            <input type="file" class="form-control" id="store_placeholder_img_supermart" @change="handlePlaceholderUpload('supermart', $event)" accept="image/*" ref="placeholderSupermartInput">
                                            <small class="text-muted">Placeholder for Super Mart products</small>
                                            <div v-if="settings.store_placeholder_img_supermart" class="mt-2">
                                                <img :src="settings.store_placeholder_img_supermart" alt="Supermart Placeholder" style="max-width: 100%; max-height: 120px; object-fit: contain;" class="mb-1 rounded border">
                                                <br>
                                                <span class="badge bg-success">Uploaded</span>
                                                <a :href="settings.store_placeholder_img_supermart" target="_blank" class="ms-2 small">View</a>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <button class="btn btn-primary mt-2" @click="saveSection('store_placeholders')" :disabled="saving.store_placeholders">
                                    <span v-if="saving.store_placeholders"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save Placeholder Images</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Seller App Login Background -->
                    <div class="col-12 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Seller App Login Background</h4>
                            </div>
                            <div class="card-body">
                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="seller_app_login_bg">Login Screen Background</label>
                                            <input type="file" class="form-control" id="seller_app_login_bg" @change="handleSellerLoginBgUpload" accept="image/*,video/mp4,video/webm,.gif" ref="sellerLoginBgInput">
                                            <small class="text-muted">Upload background image, video or GIF for seller app login screen</small>
                                        </div>
                                    </div>
                                    <div class="col-md-6" v-if="settings.seller_app_login_bg">
                                        <div class="mt-2">
                                            <video v-if="settings.seller_app_login_bg.match(/\.(mp4|webm)$/i)" :src="settings.seller_app_login_bg" controls style="max-width: 100%; max-height: 200px;" class="rounded"></video>
                                            <img v-else :src="settings.seller_app_login_bg" alt="Seller Login BG" style="max-width: 100%; max-height: 200px;" class="rounded">
                                            <br>
                                            <span class="badge bg-success mt-1">Media uploaded</span>
                                            <a :href="settings.seller_app_login_bg" target="_blank" class="ms-2">View</a>
                                        </div>
                                    </div>
                                </div>
                                <button class="btn btn-primary mt-2" @click="saveSection('seller_login_bg')" :disabled="saving.seller_login_bg">
                                    <span v-if="saving.seller_login_bg"><i class="fa fa-spinner fa-spin me-1"></i>Uploading & Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Driver Proximity Radius -->
                    <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Driver Proximity Radius</h4>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label for="driver_proximity_radius">Proximity Radius (meters)</label>
                                    <input type="number" class="form-control" id="driver_proximity_radius" v-model="settings.driver_proximity_radius" placeholder="e.g., 100" min="10" step="1">
                                    <small class="text-muted">Maximum distance (in meters) the driver must be within to confirm arrival at seller or customer location. Default: 100 meters.</small>
                                </div>
                                <button class="btn btn-primary" @click="saveSection('driver_proximity')" :disabled="saving.driver_proximity">
                                    <span v-if="saving.driver_proximity"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Vendor Waiting Charges -->
                    <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Vendor Waiting Charges</h4>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label for="vendor_wait_grace_minutes">Grace Minutes (free)</label>
                                    <input type="number" class="form-control" id="vendor_wait_grace_minutes" v-model="settings.vendor_wait_grace_minutes" placeholder="e.g., 5" min="0" step="1">
                                    <small class="text-muted">Free minutes the driver waits at the vendor before charges start. Clock starts from the later of driver arrival OR vendor's first promised ready time. Default: 5.</small>
                                </div>
                                <div class="form-group mt-2">
                                    <label for="vendor_wait_charge_per_minute">Charge per Minute (&#8377;)</label>
                                    <input type="number" class="form-control" id="vendor_wait_charge_per_minute" v-model="settings.vendor_wait_charge_per_minute" placeholder="e.g., 2" min="0" step="0.01">
                                    <small class="text-muted">Amount deducted from the vendor (and paid to the driver) for every minute waited beyond the grace period. Default: &#8377;2.</small>
                                </div>
                                <div class="form-group mt-2">
                                    <label for="vendor_wait_charge_cap">Max Charge per Order (&#8377;)</label>
                                    <input type="number" class="form-control" id="vendor_wait_charge_cap" v-model="settings.vendor_wait_charge_cap" placeholder="e.g., 50" min="0" step="0.01">
                                    <small class="text-muted">Upper limit on the waiting charge for one order. Set to 0 to disable the cap. Default: &#8377;50.</small>
                                </div>
                                <button class="btn btn-primary mt-2" @click="saveSection('vendor_wait_charge')" :disabled="saving.vendor_wait_charge">
                                    <span v-if="saving.vendor_wait_charge"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Tiered Driver Dispatch (Nearest-First) -->
                    <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Driver Dispatch (Nearest-First)</h4>
                            </div>
                            <div class="card-body">
                                <p class="text-muted small">
                                    New orders are offered to the nearest ring of drivers first. If no one
                                    accepts within the offer timeout, the search radius widens one tier step
                                    at a time (e.g. 1 km → 2 km → 3 km) up to the max radius.
                                </p>
                                <div class="form-group">
                                    <label for="dispatch_max_radius_km">Max Search Radius (km)</label>
                                    <input type="number" class="form-control" id="dispatch_max_radius_km" v-model="settings.dispatch_max_radius_km" placeholder="e.g., 5" min="0.1" step="0.1">
                                    <small class="text-muted">Outer limit — orders are never offered to drivers beyond this distance. Default: 5 km.</small>
                                </div>
                                <div class="form-group">
                                    <label for="dispatch_tier_step_km">Tier Step (km)</label>
                                    <input type="number" class="form-control" id="dispatch_tier_step_km" v-model="settings.dispatch_tier_step_km" placeholder="e.g., 1" min="0.1" step="0.1">
                                    <small class="text-muted">How much the radius grows each time it expands (1 km → 2 km → 3 km). Must be ≤ max radius. Default: 1 km.</small>
                                </div>
                                <div class="form-group">
                                    <label for="dispatch_offer_timeout_sec">Offer Timeout (seconds)</label>
                                    <input type="number" class="form-control" id="dispatch_offer_timeout_sec" v-model="settings.dispatch_offer_timeout_sec" placeholder="e.g., 25" min="5" step="1">
                                    <small class="text-muted">How long each ring of drivers has to accept before the radius widens. Default: 25 seconds.</small>
                                </div>
                                <button class="btn btn-primary" @click="saveSection('dispatch')" :disabled="saving.dispatch">
                                    <span v-if="saving.dispatch"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Delivery Charge Configuration -->
                    <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Delivery Charge Configuration</h4>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label for="free_delivery_order_amount">Free Delivery Order Amount ({{ $currency }})</label>
                                    <input type="number" class="form-control" id="free_delivery_order_amount" v-model="settings.free_delivery_order_amount" placeholder="e.g., 500" min="0" step="1">
                                    <small class="text-muted">Orders above this amount get free delivery. Set to 0 to disable free delivery.</small>
                                </div>
                                <div class="form-group">
                                    <label for="delivery_charge_below_1km">Delivery Charge for Distance < 1 KM ({{ $currency }})</label>
                                    <input type="number" class="form-control" id="delivery_charge_below_1km" v-model="settings.delivery_charge_below_1km" placeholder="e.g., 20" min="0" step="1">
                                    <small class="text-muted">Minimum charge for deliveries less than 1 kilometer</small>
                                </div>
                                <div class="form-group">
                                    <label for="delivery_charge_1_to_2km">Delivery Charge for Distance 1-2 KM ({{ $currency }})</label>
                                    <input type="number" class="form-control" id="delivery_charge_1_to_2km" v-model="settings.delivery_charge_1_to_2km" placeholder="e.g., 25" min="0" step="1">
                                    <small class="text-muted">Fixed charge for deliveries between 1 and 2 kilometers</small>
                                </div>
                                <div class="alert alert-info mt-2">
                                    <i class="fa fa-info-circle me-1"></i>
                                    <strong>Note:</strong> For distances > 2 KM, the system will use the per-kilometer charge from city settings.
                                </div>
                                <button class="btn btn-primary" @click="saveSection('delivery_charges')" :disabled="saving.delivery_charges">
                                    <span v-if="saving.delivery_charges"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Payment Method Settings - Commented for now (only Paytm is used) -->
                    <!-- <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Payment Method Settings</h4>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label for="payment_method_name">Default Payment Method</label>
                                    <select class="form-control form-select" id="payment_method_name" v-model="settings.payment_method_name">
                                        <option value="razorpay">Razorpay</option>
                                        <option value="phonepe">PhonePe</option>
                                        <option value="paytm">Paytm</option>
                                    </select>
                                    <small class="text-muted">Select default payment gateway for hand cash settlement</small>
                                </div>
                                <div class="form-group">
                                    <label for="skip_payment_verification">Skip Payment Verification</label>
                                    <select class="form-control form-select" id="skip_payment_verification" v-model="settings.skip_payment_verification">
                                        <option value="true">Yes (Testing Mode)</option>
                                        <option value="false">No (Production Mode)</option>
                                    </select>
                                    <small class="text-danger">Enable only for testing! Disable in production.</small>
                                </div>
                                <button class="btn btn-primary" @click="saveSection('payment_settings')" :disabled="saving.payment_settings">
                                    <span v-if="saving.payment_settings"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div> -->

                    <!-- City Zone Filter -->
                    <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">City Zone Filter</h4>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label for="city_zone_filter_enabled">Enable City Zone Filtering</label>
                                    <select class="form-control form-select" id="city_zone_filter_enabled" v-model="settings.city_zone_filter_enabled">
                                        <option value="1">Enabled</option>
                                        <option value="0">Disabled</option>
                                    </select>
                                    <small class="text-muted">When enabled, customers will only see sellers within their city zone. If no zone matches, they will see "We are not available in your area" with available zones list.</small>
                                </div>
                                <button class="btn btn-primary" @click="saveSection('city_zone_filter')" :disabled="saving.city_zone_filter">
                                    <span v-if="saving.city_zone_filter"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Preorder Settings -->
                    <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Preorder Settings</h4>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label for="preorder_enabled">Enable Preorder</label>
                                    <select class="form-control form-select" id="preorder_enabled" v-model="settings.preorder_enabled">
                                        <option value="1">Enabled</option>
                                        <option value="0">Disabled</option>
                                    </select>
                                    <small class="text-muted">
                                        Enable or disable the preorder feature for customers.
                                    </small>
                                </div>

                                <div class="form-group">
                                    <label for="preorder_cutoff_day">Preorder Cutoff Day</label>
                                    <select class="form-control form-select" id="preorder_cutoff_day" v-model="settings.preorder_cutoff_day">
                                        <option value="1">Monday</option>
                                        <option value="2">Tuesday</option>
                                        <option value="3">Wednesday</option>
                                        <option value="4">Thursday</option>
                                        <option value="5">Friday</option>
                                    </select>
                                    <small class="text-muted">
                                        The day of the week when preorders should stop accepting new orders.
                                    </small>
                                </div>

                                <div class="form-group">
                                    <label for="preorder_cutoff_time">Preorder Cutoff Time</label>
                                    <input
                                        type="time"
                                        class="form-control"
                                        id="preorder_cutoff_time"
                                        v-model="settings.preorder_cutoff_time"
                                    />
                                    <small class="text-muted">
                                        The time when preorders should stop accepting new orders on the cutoff day.
                                        <strong class="text-warning">Must be before Friday 6:30 AM</strong> (process time).
                                    </small>
                                </div>

                                <div class="alert alert-info mt-3" role="alert">
                                    <i class="fa fa-info-circle me-1"></i>
                                    <strong>Preorder Window:</strong> Saturday 1:00 AM until the configured cutoff day and time.<br>
                                    <strong>Process Time:</strong> All preorders are processed on <span class="text-primary">Friday 6:30 AM</span> (fixed).<br>
                                    <strong>Cutoff Constraint:</strong> Cutoff must be before Friday 6:30 AM to allow processing time.<br>
                                    <strong>Note:</strong> Only products from Zenfoo stores (admin-managed) can be preordered.
                                </div>

                                <button class="btn btn-primary" @click="saveSection('preorder')" :disabled="saving.preorder">
                                    <span v-if="saving.preorder"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Store Hours -->
                    <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Store Hours</h4>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label for="store_opening_time">Store Opening Time</label>
                                    <input
                                        type="time"
                                        class="form-control"
                                        id="store_opening_time"
                                        v-model="settings.store_opening_time"
                                        placeholder="e.g., 09:00"
                                    />
                                    <small class="text-muted">Set the store opening time</small>
                                </div>
                                <div class="form-group">
                                    <label for="store_closing_time">Store Closing Time</label>
                                    <input
                                        type="time"
                                        class="form-control"
                                        id="store_closing_time"
                                        v-model="settings.store_closing_time"
                                        placeholder="e.g., 21:00"
                                    />
                                    <small class="text-muted">Set the store closing time</small>
                                </div>
                                <button class="btn btn-primary" @click="saveSection('store_hours')" :disabled="saving.store_hours">
                                    <span v-if="saving.store_hours"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Payment Gateway Fees & Customer GST -->
                    <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Payment Gateway Fees & Customer GST</h4>
                            </div>
                            <div class="card-body">
                                <div class="form-group">
                                    <label for="payment_gateway_fees">Payment Gateway Fees (%)</label>
                                    <input
                                        type="number"
                                        class="form-control"
                                        id="payment_gateway_fees"
                                        v-model="settings.payment_gateway_fees"
                                        placeholder="e.g., 2.00"
                                        min="0"
                                        step="0.01"
                                    />
                                    <small class="text-muted">Percentage fee charged by the payment gateway on each transaction</small>
                                </div>
                                <div class="form-group">
                                    <label for="customer_gst">Customer GST (%)</label>
                                    <input
                                        type="number"
                                        class="form-control"
                                        id="customer_gst"
                                        v-model="settings.customer_gst"
                                        placeholder="e.g., 5.00"
                                        min="0"
                                        step="0.01"
                                    />
                                    <small class="text-muted">GST percentage applied to customer orders</small>
                                </div>
                                <button class="btn btn-primary" @click="saveSection('fees_gst')" :disabled="saving.fees_gst">
                                    <span v-if="saving.fees_gst"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Vendor GST Configurations -->
                    <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Vendor GST Configurations</h4>
                            </div>
                            <div class="card-body">
                                <div class="alert alert-info">
                                    <i class="fa fa-info-circle me-1"></i>
                                    GST percentages applied per vendor category. Used while calculating vendor payouts and invoices.
                                </div>
                                <div class="form-group">
                                    <label for="vendor_gst_vegetables_fruits">Vegetables &amp; Fruits Vendor GST (%)</label>
                                    <input
                                        type="number"
                                        class="form-control"
                                        id="vendor_gst_vegetables_fruits"
                                        v-model="settings.vendor_gst_vegetables_fruits"
                                        placeholder="e.g., 2.00"
                                        min="0"
                                        step="0.01"
                                    />
                                    <small class="text-muted">GST % charged to vegetables &amp; fruits vendors</small>
                                </div>
                                <div class="form-group">
                                    <label for="vendor_gst_chicken_meat">Chicken &amp; Meat Vendor GST (%)</label>
                                    <input
                                        type="number"
                                        class="form-control"
                                        id="vendor_gst_chicken_meat"
                                        v-model="settings.vendor_gst_chicken_meat"
                                        placeholder="e.g., 5.00"
                                        min="0"
                                        step="0.01"
                                    />
                                    <small class="text-muted">GST % charged to chicken &amp; meat vendors</small>
                                </div>
                                <div class="form-group">
                                    <label for="vendor_gst_food">Food Vendor GST (%)</label>
                                    <input
                                        type="number"
                                        class="form-control"
                                        id="vendor_gst_food"
                                        v-model="settings.vendor_gst_food"
                                        placeholder="e.g., 5.00"
                                        min="0"
                                        step="0.01"
                                    />
                                    <small class="text-muted">GST % charged to food vendors</small>
                                </div>
                                <div class="form-group">
                                    <label for="vendor_gst_super_mart">Super Mart Vendor GST (%)</label>
                                    <input
                                        type="number"
                                        class="form-control"
                                        id="vendor_gst_super_mart"
                                        v-model="settings.vendor_gst_super_mart"
                                        placeholder="e.g., 5.00"
                                        min="0"
                                        step="0.01"
                                    />
                                    <small class="text-muted">GST % charged to super mart vendors</small>
                                </div>
                                <button class="btn btn-primary" @click="saveSection('vendor_gst')" :disabled="saving.vendor_gst">
                                    <span v-if="saving.vendor_gst"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Vendor Commission Configurations -->
                    <div class="col-6 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Vendor Commission Configurations</h4>
                            </div>
                            <div class="card-body">
                                <div class="alert alert-info">
                                    <i class="fa fa-info-circle me-1"></i>
                                    Commission percentages applied per vendor category. Used while calculating vendor payouts and invoices.
                                </div>
                                <div class="form-group">
                                    <label for="vendor_commission_vegetables_fruits">Vegetables &amp; Fruits Vendor Commission (%)</label>
                                    <input
                                        type="number"
                                        class="form-control"
                                        id="vendor_commission_vegetables_fruits"
                                        v-model="settings.vendor_commission_vegetables_fruits"
                                        placeholder="e.g., 5.00"
                                        min="0"
                                        step="0.01"
                                    />
                                    <small class="text-muted">Commission % charged to vegetables &amp; fruits vendors</small>
                                </div>
                                <div class="form-group">
                                    <label for="vendor_commission_chicken_meat">Chicken &amp; Meat Vendor Commission (%)</label>
                                    <input
                                        type="number"
                                        class="form-control"
                                        id="vendor_commission_chicken_meat"
                                        v-model="settings.vendor_commission_chicken_meat"
                                        placeholder="e.g., 10.00"
                                        min="0"
                                        step="0.01"
                                    />
                                    <small class="text-muted">Commission % charged to chicken &amp; meat vendors</small>
                                </div>
                                <div class="form-group">
                                    <label for="vendor_commission_food">Food Vendor Commission (%)</label>
                                    <input
                                        type="number"
                                        class="form-control"
                                        id="vendor_commission_food"
                                        v-model="settings.vendor_commission_food"
                                        placeholder="e.g., 15.00"
                                        min="0"
                                        step="0.01"
                                    />
                                    <small class="text-muted">Commission % charged to food vendors</small>
                                </div>
                                <div class="form-group">
                                    <label for="vendor_commission_super_mart">Super Mart Vendor Commission (%)</label>
                                    <input
                                        type="number"
                                        class="form-control"
                                        id="vendor_commission_super_mart"
                                        v-model="settings.vendor_commission_super_mart"
                                        placeholder="e.g., 8.00"
                                        min="0"
                                        step="0.01"
                                    />
                                    <small class="text-muted">Commission % charged to super mart vendors</small>
                                </div>
                                <button class="btn btn-primary" @click="saveSection('vendor_commission')" :disabled="saving.vendor_commission">
                                    <span v-if="saving.vendor_commission"><i class="fa fa-spinner fa-spin me-1"></i>Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Seller Agreement: Zenfo Stamp -->
                    <div class="col-12 mb-4">
                        <div class="card h-100">
                            <div class="card-header">
                                <h4 class="card-title">Seller Agreement</h4>
                            </div>
                            <div class="card-body">
                                <div class="alert alert-info">
                                    <i class="fa fa-info-circle me-1"></i>
                                    Upload the Zenfo stamp image to render inside the "FOR ZENFO" block of every signed seller agreement PDF in place of the blank "Authorized Signature" line.
                                </div>
                                <div class="form-group">
                                    <label for="agreement_zenfo_stamp">Zenfo Stamp Image</label>
                                    <input type="file" class="form-control" id="agreement_zenfo_stamp" @change="handleZenfoStampUpload" accept="image/png,image/jpeg,image/jpg" ref="zenfoStampInput">
                                    <small class="text-muted">Recommended: transparent PNG, ~300x150 px</small>
                                </div>
                                <div v-if="settings.agreement_zenfo_stamp" class="mt-3">
                                    <img :src="settings.agreement_zenfo_stamp" alt="Zenfo Stamp" style="max-width: 100%; max-height: 150px;" class="rounded bg-white p-2 border">
                                    <br>
                                    <span class="badge bg-success mt-2">Stamp uploaded</span>
                                    <a :href="settings.agreement_zenfo_stamp" target="_blank" class="ms-2">View</a>
                                </div>
                                <button class="btn btn-primary mt-3" @click="saveSection('seller_agreement')" :disabled="saving.seller_agreement">
                                    <span v-if="saving.seller_agreement"><i class="fa fa-spinner fa-spin me-1"></i>Uploading & Saving...</span>
                                    <span v-else><i class="fa fa-save me-1"></i>Save Stamp</span>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </section>
        </div>
    </div>
</template>

<script>
export default {
    name: 'StoreSettings',
    data() {
        return {
            isLoading: true,
            settings: {},
            // Per-app support contact overrides. Blank fields fall back to the
            // global support number/email, both here and in the API.
            supportApps: [
                { key: 'customer', label: 'Customer App' },
                { key: 'seller', label: 'Seller App' },
                { key: 'driver', label: 'Driver App' },
            ],
            showRazorpaySecret: false,
            showPhonePeSecret: false,
            showPaytmTestKey: false,
            showPaytmLiveKey: false,
            showAwsSecret: false,
            saving: {
                support: false,
                google_maps: false,
                razorpay: false,
                phonepe: false,
                paytm: false,
                merchant_upi: false,
                multi_order: false,
                referral_program: false,
                app_store_links: false,
                rain_surcharge: false,
                hand_cash_limit: false,
                emergency: false,
                admin_payment_details: false,
                not_getting_orders: false,
                app_media: false,
                delivery_charges: false,
                payment_settings: false,
                city_zone_filter: false,
                preorder: false,
                store_hours: false,
                fees_gst: false,
                vendor_gst: false,
                driver_proximity: false,
                vendor_wait_charge: false,
                dispatch: false,
                aws_s3: false,
                seller_login_bg: false,
                store_placeholders: false,
                seller_agreement: false,
                vendor_commission: false
            },
            testingS3: false,
            s3TestResult: null,
            videoFile: null,
            bikeAnimationFile: null,
            customerLoginAnimationFile: null,
            allStoresImgFile: null,
            adminQrFile: null,
            exploreLogoFile: null,
            sellerLoginBgFile: null,
            zenfoStampFile: null,
            placeholderFiles: {
                food: null,
                veg: null,
                grocery: null,
                meat: null,
                supermart: null
            }
        };
    },
    mounted() {
        this.loadSettings();
    },
    methods: {
        loadSettings() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/settings')
                .then((response) => {
                    this.isLoading = false;
                    if (response.data.status === 1) {
                        this.settings = response.data.data.settings_map || {};
                        if (!this.settings.storage_driver) {
                            this.settings.storage_driver = 's3';
                        }
                        // Deposit-method toggle defaults (bank & upi on, qr off).
                        // Use $set: keys missing from the API response are added to an
                        // already-observed object, so plain assignment would be non-reactive
                        // (the switch would flip but is-active/v-if bindings wouldn't update).
                        if (this.settings.deposit_method_bank == null) this.$set(this.settings, 'deposit_method_bank', '1');
                        if (this.settings.deposit_method_upi == null) this.$set(this.settings, 'deposit_method_upi', '1');
                        if (this.settings.deposit_method_qr == null) this.$set(this.settings, 'deposit_method_qr', '0');
                        if (this.settings.admin_qr_image == null) this.$set(this.settings, 'admin_qr_image', '');
                        // Customer refer & earn: same $set reason — these rows may not
                        // exist yet, and without $set the inputs bind non-reactively.
                        if (this.settings.referral_credit_first_order == null) this.$set(this.settings, 'referral_credit_first_order', '0');
                        if (this.settings.referral_min_order_amount == null) this.$set(this.settings, 'referral_min_order_amount', '0');
                        if (this.settings.max_refer_earn_amount == null) this.$set(this.settings, 'max_refer_earn_amount', '0');
                        // Store links: unset rows leave the app sharing a broken invite URL.
                        if (this.settings.playstore_url == null) this.$set(this.settings, 'playstore_url', '');
                        if (this.settings.appstore_url == null) this.$set(this.settings, 'appstore_url', '');
                        // Per-app support overrides: same $set reason as above — these rows
                        // may not exist in the settings table yet on an existing install.
                        this.supportApps.forEach((app) => {
                            if (this.settings['support_number_' + app.key] == null) this.$set(this.settings, 'support_number_' + app.key, '');
                            if (this.settings['support_email_' + app.key] == null) this.$set(this.settings, 'support_email_' + app.key, '');
                        });
                    }
                })
                .catch((error) => {
                    this.isLoading = false;
                    this.$toast.error('Failed to load settings');
                    console.error(error);
                });
        },

        handleVideoUpload(event) {
            this.videoFile = event.target.files[0];
        },

        handleBikeAnimationUpload(event) {
            this.bikeAnimationFile = event.target.files[0];
        },

        handleCustomerLoginAnimationUpload(event) {
            this.customerLoginAnimationFile = event.target.files[0];
        },

        handleAllStoresImgUpload(event) {
            this.allStoresImgFile = event.target.files[0];
        },

        handleAdminQrUpload(event) {
            this.adminQrFile = event.target.files[0];
        },

        handleExploreLogoUpload(event) {
            this.exploreLogoFile = event.target.files[0];
        },

        handleSellerLoginBgUpload(event) {
            this.sellerLoginBgFile = event.target.files[0];
        },

        handleZenfoStampUpload(event) {
            this.zenfoStampFile = event.target.files[0];
        },

        handlePlaceholderUpload(type, event) {
            this.placeholderFiles[type] = event.target.files[0];
        },

        async saveSection(section) {
            this.saving[section] = true;
            let settingsToSave = {};

            switch(section) {
                case 'support':
                    // Only the per-app rows are editable now. The global
                    // support_number/support_email rows are left untouched so the
                    // SMS and web fallbacks keep the value they already have.
                    settingsToSave = {};
                    this.supportApps.forEach((app) => {
                        settingsToSave['support_number_' + app.key] = this.settings['support_number_' + app.key] || '';
                        settingsToSave['support_email_' + app.key] = this.settings['support_email_' + app.key] || '';
                    });
                    break;

                case 'google_maps':
                    // Update all 3 Google API key fields with the same value
                    settingsToSave = {
                        google_place_api_key: this.settings.google_map_api_key,
                        google_map_api_key: this.settings.google_map_api_key,
                        googleMapApiKey: this.settings.google_map_api_key
                    };
                    break;

                case 'razorpay':
                    settingsToSave = {
                        razorpay_key: this.settings.razorpay_key,
                        razorpay_secret_key: this.settings.razorpay_secret_key
                    };
                    break;

                case 'phonepe':
                    settingsToSave = {
                        phonepay_merchant_id: this.settings.phonepay_merchant_id,
                        phonepay_client_id: this.settings.phonepay_client_id,
                        phonepay_client_secret: this.settings.phonepay_client_secret,
                        phonepay_client_version: this.settings.phonepay_client_version,
                        phonepay_payment_endpoint_url: this.settings.phonepay_payment_endpoint_url
                    };
                    break;

                case 'merchant_upi':
                    // Validate merchant UPI ID
                    if (!this.settings.merchant_upi_id || !this.settings.business_name) {
                        this.$toast.error('Merchant UPI ID and Business Name are required');
                        this.saving[section] = false;
                        return;
                    }
                    settingsToSave = {
                        merchant_upi_id: this.settings.merchant_upi_id,
                        business_name: this.settings.business_name
                    };
                    break;

                case 'paytm':
                    settingsToSave = {
                        paytm_test_merchant_id: this.settings.paytm_test_merchant_id,
                        paytm_test_merchant_key: this.settings.paytm_test_merchant_key,
                        paytm_test_website: this.settings.paytm_test_website,
                        paytm_test_industry_type: this.settings.paytm_test_industry_type,
                        paytm_test_channel_id: this.settings.paytm_test_channel_id,
                        paytm_live_merchant_id: this.settings.paytm_live_merchant_id,
                        paytm_live_merchant_key: this.settings.paytm_live_merchant_key,
                        paytm_live_website: this.settings.paytm_live_website,
                        paytm_live_industry_type: this.settings.paytm_live_industry_type,
                        paytm_live_channel_id: this.settings.paytm_live_channel_id,
                        paytm_environment: this.settings.paytm_environment
                    };
                    break;

                case 'multi_order':
                    settingsToSave = {
                        multi_order_bonus: this.settings.multi_order_bonus
                    };
                    break;

                case 'referral_program':
                    settingsToSave = {
                        // Customer refer & earn — these two drive the actual payout
                        // (CommonHelper::creditReferralFirstOrderBonus).
                        referral_credit_first_order: this.settings.referral_credit_first_order,
                        referral_min_order_amount: this.settings.referral_min_order_amount,
                        max_refer_earn_amount: this.settings.max_refer_earn_amount,
                        referral_driver_order_count: this.settings.referral_driver_order_count,
                        referral_driver_amount: this.settings.referral_driver_amount
                    };
                    break;

                case 'app_store_links':
                    settingsToSave = {
                        playstore_url: this.settings.playstore_url || '',
                        appstore_url: this.settings.appstore_url || ''
                    };
                    break;

                case 'rain_surcharge':
                    settingsToSave = {
                        rain_surcharge_amount: this.settings.rain_surcharge_amount
                    };
                    break;

                case 'hand_cash_limit':
                    settingsToSave = {
                        max_hand_cash_limit: this.settings.max_hand_cash_limit
                    };
                    break;

                case 'emergency':
                    settingsToSave = {
                        emergency_zenfoo_phone: this.settings.emergency_zenfoo_phone,
                        emergency_zenfoo_email: this.settings.emergency_zenfoo_email,
                        emergency_police_phone: this.settings.emergency_police_phone,
                        emergency_ambulance_phone: this.settings.emergency_ambulance_phone
                    };
                    break;

                case 'admin_payment_details':
                    // At least one deposit method must stay enabled.
                    if (this.settings.deposit_method_bank != 1 &&
                        this.settings.deposit_method_upi != 1 &&
                        this.settings.deposit_method_qr != 1) {
                        this.saving[section] = false;
                        this.$toast.error('Enable at least one deposit method');
                        return;
                    }
                    // Zenfoo QR is enabled but no QR image is set or being uploaded.
                    if (this.settings.deposit_method_qr == 1 && !this.adminQrFile && !this.settings.admin_qr_image) {
                        this.saving[section] = false;
                        this.$toast.error('Please upload a Zenfoo QR image to enable the QR method');
                        return;
                    }
                    // Upload QR image first if a new one was selected.
                    if (this.adminQrFile) {
                        try {
                            const qrUrl = await this.uploadImage(this.adminQrFile, 'admin_qr_image');
                            this.settings.admin_qr_image = qrUrl;
                            this.adminQrFile = null;
                        } catch (error) {
                            this.saving[section] = false;
                            this.$toast.error('Failed to upload QR image');
                            return;
                        }
                    }
                    settingsToSave = {
                        admin_upi_id: this.settings.admin_upi_id,
                        admin_bank_name: this.settings.admin_bank_name,
                        admin_bank_account_number: this.settings.admin_bank_account_number,
                        admin_bank_ifsc_code: this.settings.admin_bank_ifsc_code,
                        admin_bank_account_holder_name: this.settings.admin_bank_account_holder_name,
                        deposit_method_bank: this.settings.deposit_method_bank ?? '1',
                        deposit_method_upi: this.settings.deposit_method_upi ?? '1',
                        deposit_method_qr: this.settings.deposit_method_qr ?? '0',
                        admin_qr_image: this.settings.admin_qr_image ?? ''
                    };
                    break;

                case 'not_getting_orders':
                    // Upload video first if selected
                    if (this.videoFile) {
                        try {
                            const videoUrl = await this.uploadVideo();
                            this.settings.not_getting_orders_video = videoUrl;
                        } catch (error) {
                            this.saving[section] = false;
                            this.$toast.error('Failed to upload video');
                            return;
                        }
                    }
                    settingsToSave = {
                        not_getting_orders_video: this.settings.not_getting_orders_video,
                        not_getting_orders_title: this.settings.not_getting_orders_title,
                        not_getting_orders_steps: this.settings.not_getting_orders_steps
                    };
                    break;

                case 'app_media':
                    // Upload bike animation if selected
                    if (this.bikeAnimationFile) {
                        try {
                            const bikeUrl = await this.uploadAnimationVideo(this.bikeAnimationFile, 'bike_moving_animation');
                            this.settings.bike_moving_animation = bikeUrl;
                        } catch (error) {
                            this.saving[section] = false;
                            this.$toast.error('Failed to upload bike animation video');
                            return;
                        }
                    }
                    // Upload customer login animation if selected
                    if (this.customerLoginAnimationFile) {
                        try {
                            const customerLoginUrl = await this.uploadAnimationVideo(this.customerLoginAnimationFile, 'customer_login_products_animation');
                            this.settings.customer_login_products_animation = customerLoginUrl;
                        } catch (error) {
                            this.saving[section] = false;
                            this.$toast.error('Failed to upload customer login animation video');
                            return;
                        }
                    }
                    // Upload all stores image if selected
                    if (this.allStoresImgFile) {
                        try {
                            const allStoresImgUrl = await this.uploadImage(this.allStoresImgFile, 'all_stores_img');
                            this.settings.all_stores_img = allStoresImgUrl;
                        } catch (error) {
                            this.saving[section] = false;
                            this.$toast.error('Failed to upload all stores image');
                            return;
                        }
                    }
                    // Upload explore logo if selected (supports images and videos)
                    if (this.exploreLogoFile) {
                        try {
                            const exploreLogoUrl = await this.uploadMedia(this.exploreLogoFile, 'explore_logo_icon');
                            this.settings.explore_logo_icon = exploreLogoUrl;
                        } catch (error) {
                            this.saving[section] = false;
                            this.$toast.error('Failed to upload explore logo icon');
                            return;
                        }
                    }
                    settingsToSave = {
                        bike_moving_animation: this.settings.bike_moving_animation,
                        customer_login_products_animation: this.settings.customer_login_products_animation,
                        all_stores_img: this.settings.all_stores_img,
                        explore_logo_icon: this.settings.explore_logo_icon
                    };
                    break;

                case 'seller_login_bg':
                    if (this.sellerLoginBgFile) {
                        try {
                            const sellerBgUrl = await this.uploadMedia(this.sellerLoginBgFile, 'seller_app_login_bg');
                            this.settings.seller_app_login_bg = sellerBgUrl;
                        } catch (error) {
                            this.saving[section] = false;
                            this.$toast.error('Failed to upload seller login background');
                            return;
                        }
                    }
                    if (!this.settings.seller_app_login_bg) {
                        this.saving[section] = false;
                        this.$toast.error('Please select a file to upload');
                        return;
                    }
                    settingsToSave = {
                        seller_app_login_bg: this.settings.seller_app_login_bg
                    };
                    break;

                case 'seller_agreement':
                    if (this.zenfoStampFile) {
                        try {
                            const stampUrl = await this.uploadImage(this.zenfoStampFile, 'agreement_zenfo_stamp');
                            this.settings.agreement_zenfo_stamp = stampUrl;
                        } catch (error) {
                            this.saving[section] = false;
                            this.$toast.error('Failed to upload Zenfo stamp');
                            return;
                        }
                    }
                    if (!this.settings.agreement_zenfo_stamp) {
                        this.saving[section] = false;
                        this.$toast.error('Please select a stamp image to upload');
                        return;
                    }
                    settingsToSave = {
                        agreement_zenfo_stamp: this.settings.agreement_zenfo_stamp
                    };
                    break;

                case 'delivery_charges':
                    settingsToSave = {
                        free_delivery_order_amount: this.settings.free_delivery_order_amount,
                        delivery_charge_below_1km: this.settings.delivery_charge_below_1km,
                        delivery_charge_1_to_2km: this.settings.delivery_charge_1_to_2km
                    };
                    break;

                case 'payment_settings':
                    settingsToSave = {
                        payment_method_name: this.settings.payment_method_name,
                        skip_payment_verification: this.settings.skip_payment_verification
                    };
                    break;

                case 'city_zone_filter':
                    settingsToSave = {
                        city_zone_filter_enabled: this.settings.city_zone_filter_enabled
                    };
                    break;

                case 'preorder':
                    // Validate cutoff time must be before Friday 6:30 AM (process time)
                    const cutoffDay = parseInt(this.settings.preorder_cutoff_day);
                    const cutoffTime = this.settings.preorder_cutoff_time;

                    // Cutoff day cannot be Saturday (6) - preorders start Saturday 1:00 AM
                    if (cutoffDay === 6) {
                        this.saving[section] = false;
                        this.$toast.error('Cutoff day cannot be Saturday. Preorders start on Saturday 1:00 AM.');
                        return;
                    }

                    // If cutoff day is Friday (5), time must be before 06:30 (process time)
                    if (cutoffDay === 5 && cutoffTime >= '06:30') {
                        this.saving[section] = false;
                        this.$toast.error('Cutoff time on Friday must be before 6:30 AM (process time is Friday 6:30 AM)');
                        return;
                    }

                    settingsToSave = {
                        preorder_enabled: this.settings.preorder_enabled,
                        preorder_cutoff_day: this.settings.preorder_cutoff_day,
                        preorder_cutoff_time: this.settings.preorder_cutoff_time
                    };
                    break;

                case 'store_hours':
                    settingsToSave = {
                        store_opening_time: this.settings.store_opening_time,
                        store_closing_time: this.settings.store_closing_time
                    };
                    break;

                case 'fees_gst':
                    settingsToSave = {
                        payment_gateway_fees: this.settings.payment_gateway_fees,
                        customer_gst: this.settings.customer_gst
                    };
                    break;

                case 'vendor_gst':
                    settingsToSave = {
                        vendor_gst_vegetables_fruits: this.settings.vendor_gst_vegetables_fruits,
                        vendor_gst_chicken_meat: this.settings.vendor_gst_chicken_meat,
                        vendor_gst_food: this.settings.vendor_gst_food,
                        vendor_gst_super_mart: this.settings.vendor_gst_super_mart
                    };
                    break;

                case 'vendor_commission':
                    settingsToSave = {
                        vendor_commission_vegetables_fruits: this.settings.vendor_commission_vegetables_fruits,
                        vendor_commission_chicken_meat: this.settings.vendor_commission_chicken_meat,
                        vendor_commission_food: this.settings.vendor_commission_food,
                        vendor_commission_super_mart: this.settings.vendor_commission_super_mart
                    };
                    break;

                case 'driver_proximity':
                    settingsToSave = {
                        driver_proximity_radius: this.settings.driver_proximity_radius
                    };
                    break;

                case 'vendor_wait_charge':
                    settingsToSave = {
                        vendor_wait_grace_minutes: this.settings.vendor_wait_grace_minutes,
                        vendor_wait_charge_per_minute: this.settings.vendor_wait_charge_per_minute,
                        vendor_wait_charge_cap: this.settings.vendor_wait_charge_cap
                    };
                    break;

                case 'dispatch':
                    const maxRadius = parseFloat(this.settings.dispatch_max_radius_km);
                    const tierStep = parseFloat(this.settings.dispatch_tier_step_km);
                    const offerTimeout = parseInt(this.settings.dispatch_offer_timeout_sec);

                    if (!(maxRadius > 0) || !(tierStep > 0) || !(offerTimeout > 0)) {
                        this.saving[section] = false;
                        this.$toast.error('Max radius, tier step and offer timeout must all be greater than 0.');
                        return;
                    }
                    if (tierStep > maxRadius) {
                        this.saving[section] = false;
                        this.$toast.error('Tier step (km) cannot be larger than the max radius (km).');
                        return;
                    }

                    settingsToSave = {
                        dispatch_max_radius_km: this.settings.dispatch_max_radius_km,
                        dispatch_tier_step_km: this.settings.dispatch_tier_step_km,
                        dispatch_offer_timeout_sec: this.settings.dispatch_offer_timeout_sec
                    };
                    break;

                case 'aws_s3':
                    settingsToSave = {
                        storage_driver: this.settings.storage_driver || 's3',
                        aws_access_key_id: this.settings.aws_access_key_id,
                        aws_secret_access_key: this.settings.aws_secret_access_key,
                        aws_default_region: this.settings.aws_default_region,
                        aws_bucket: this.settings.aws_bucket
                    };
                    break;

                case 'store_placeholders':
                    const storeTypes = ['food', 'veg', 'grocery', 'meat', 'supermart'];
                    for (const type of storeTypes) {
                        if (this.placeholderFiles[type]) {
                            try {
                                const url = await this.uploadImage(this.placeholderFiles[type], `store_placeholder_img_${type}`);
                                this.settings[`store_placeholder_img_${type}`] = url;
                                this.placeholderFiles[type] = null;
                                const refName = `placeholder${type.charAt(0).toUpperCase() + type.slice(1)}Input`;
                                if (this.$refs[refName]) this.$refs[refName].value = '';
                            } catch (error) {
                                this.saving[section] = false;
                                this.$toast.error(`Failed to upload ${type} placeholder image`);
                                return;
                            }
                        }
                    }
                    settingsToSave = {
                        store_placeholder_img_food: this.settings.store_placeholder_img_food,
                        store_placeholder_img_veg: this.settings.store_placeholder_img_veg,
                        store_placeholder_img_grocery: this.settings.store_placeholder_img_grocery,
                        store_placeholder_img_meat: this.settings.store_placeholder_img_meat,
                        store_placeholder_img_supermart: this.settings.store_placeholder_img_supermart
                    };
                    break;
            }

            axios.post(this.$apiUrl + '/settings/bulk-update', { settings: settingsToSave })
                .then((response) => {
                    this.saving[section] = false;
                    if (response.data.status === 1) {
                        this.$toast.success('Settings saved successfully');
                        this.videoFile = null;
                        if (this.$refs.videoInput) {
                            this.$refs.videoInput.value = '';
                        }
                    } else {
                        this.$toast.error('Failed to save settings');
                    }
                })
                .catch((error) => {
                    this.saving[section] = false;
                    this.$toast.error('Failed to save settings');
                    console.error(error);
                });
        },

        async uploadVideo() {
            const formData = new FormData();
            formData.append('file', this.videoFile);
            formData.append('type', 'not_getting_orders_video');

            const response = await axios.post(this.$apiUrl + '/settings/upload-video', formData, {
                headers: {
                    'Content-Type': 'multipart/form-data'
                }
            });

            if (response.data.status === 1) {
                return response.data.data.url;
            } else {
                throw new Error('Upload failed');
            }
        },

        async uploadAnimationVideo(file, type) {
            const formData = new FormData();
            formData.append('file', file);
            formData.append('type', type);

            const response = await axios.post(this.$apiUrl + '/settings/upload-video', formData, {
                headers: {
                    'Content-Type': 'multipart/form-data'
                }
            });

            if (response.data.status === 1) {
                return response.data.data.url;
            } else {
                throw new Error('Upload failed');
            }
        },

        async uploadImage(file, type) {
            const formData = new FormData();
            formData.append('file', file);
            formData.append('type', type);

            const response = await axios.post(this.$apiUrl + '/settings/upload-image', formData, {
                headers: {
                    'Content-Type': 'multipart/form-data'
                }
            });

            if (response.data.status === 1) {
                return response.data.data.url;
            } else {
                throw new Error('Upload failed');
            }
        },

        testS3Connection() {
            this.testingS3 = true;
            this.s3TestResult = null;

            axios.post(this.$apiUrl + '/settings/test-s3')
                .then((response) => {
                    this.testingS3 = false;
                    if (response.data.status === 1) {
                        this.s3TestResult = {
                            success: true,
                            message: response.data.message + ' (Bucket: ' + response.data.data.bucket + ', Region: ' + response.data.data.region + ')'
                        };
                    } else {
                        this.s3TestResult = {
                            success: false,
                            message: response.data.message || 'S3 test failed'
                        };
                    }
                })
                .catch((error) => {
                    this.testingS3 = false;
                    const msg = error.response?.data?.message || error.message || 'Connection failed';
                    this.s3TestResult = {
                        success: false,
                        message: msg
                    };
                });
        },

        async uploadMedia(file, type) {
            const formData = new FormData();
            formData.append('file', file);
            formData.append('type', type);

            const response = await axios.post(this.$apiUrl + '/settings/upload-media', formData, {
                headers: {
                    'Content-Type': 'multipart/form-data'
                }
            });

            if (response.data.status === 1) {
                return response.data.data.url;
            } else {
                throw new Error('Upload failed');
            }
        }
    }
};
</script>

<style scoped>
/* Minimal styling - let theme handle light/dark mode */
.card {
    height: 100%;
}

.card-header h5 {
    margin: 0;
    font-size: 1rem;
}

.form-group {
    margin-bottom: 1rem;
}

/* Deposit method toggle cards */
.deposit-method-card {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.85rem 1rem;
    border: 1px solid #e3e3e3;
    border-radius: 0.6rem;
    background: #fafafa;
    transition: border-color 0.2s ease, box-shadow 0.2s ease, background 0.2s ease;
    height: 100%;
}

.deposit-method-card.is-active {
    border-color: #4caf50;
    background: #f3faf3;
    box-shadow: 0 0 0 1px rgba(76, 175, 80, 0.25);
}

.deposit-method-card__icon {
    flex: 0 0 auto;
    width: 38px;
    height: 38px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
    background: #eceff1;
    color: #607d8b;
    font-size: 1.05rem;
}

.deposit-method-card.is-active .deposit-method-card__icon {
    background: #4caf50;
    color: #fff;
}

.deposit-method-card__body {
    flex: 1 1 auto;
    display: flex;
    flex-direction: column;
    line-height: 1.2;
}

.deposit-method-card__title {
    font-weight: 600;
}

.deposit-method-card .form-check-input {
    cursor: pointer;
}

/* Zenfoo QR upload box */
.qr-upload-box {
    border: 1px dashed #c5c5c5;
    border-radius: 0.6rem;
    padding: 1rem;
    background: #fafafa;
}

.qr-upload-box__preview {
    text-align: center;
}

.qr-upload-box__img {
    max-width: 100%;
    max-height: 220px;
    border-radius: 0.5rem;
    border: 1px solid #e3e3e3;
    background: #fff;
    padding: 6px;
}

.qr-upload-box__placeholder {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 0.4rem;
    padding: 1.5rem 0;
    color: #9e9e9e;
}

.qr-upload-box__placeholder i {
    font-size: 1.8rem;
}
</style>