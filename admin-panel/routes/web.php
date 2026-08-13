<?php

use App\Helpers\CommonHelper;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Crypt;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/', function () {
    return view('welcome');
});


Route::get('/clear', function () {

    // \Artisan::call('cache:clear', ['--force' => true, '--no-interaction' => true]); // ok
    \Artisan::call('cache:clear'); // ok
    $data['cache'] = Artisan::output();

    // \Artisan::call('config:clear', ['--force' => true, '--no-interaction' => true]); // ok
    \Artisan::call('config:clear'); // ok
    $data['config'] = Artisan::output();

    // \Artisan::call('route:clear', ['--force' => true, '--no-interaction' => true]); // ok
    \Artisan::call('route:clear'); // ok
    $data['route'] = Artisan::output();

    // \Artisan::call('view:clear', ['--force' => true, '--no-interaction' => true]); // ok
    \Artisan::call('view:clear'); // ok
    $data['view'] = Artisan::output();


     return \App\Helpers\CommonHelper::responseSuccessWithData('Cache cleared successfully!',$data);
});
//Auto update , than migration check
Route::get('/migration', function () {

    // Run the database migration with force and no-interaction options
    \Artisan::call('migrate', ['--force' => true, '--no-interaction' => true]);
    \Artisan::call('db:seed', [
        '--class' => 'PermissionCategoriesSeeder',
        '--force' => true,
        '--no-interaction' => true,
    ]);
    \Artisan::call('db:seed', [
        '--class' => 'PermissionSeeder',
        '--force' => true,
        '--no-interaction' => true,
    ]);
    \Artisan::call('db:seed', [
        '--class' => 'OrderStatusList',
        '--force' => true,
        '--no-interaction' => true,
    ]);

     return redirect('/system_updater');
});
// Route::get('/specific-migration', function () {
//         \Artisan::call('migrate', [
//             '--path' => 'database/migrations/2025_08_13_000000_create_api_call_tracking_table.php',
//             '--force' => true,
//             '--no-interaction' => true,
//         ]);

//         return \Artisan::output();
//     });
Route::get('/supported_language', function () {

    $command = 'php artisan db:seed --class=SupportedLanguageSeeder';
    $output = [];
    $returnValue = 0;

    exec($command, $output, $returnValue);

    if ($returnValue !== 0) {
        $output['exec_error'] = "Error executing command: " . implode("\n", $output);

        try {
            \Artisan::call('db:seed', [
                '--class' => 'SupportedLanguageSeeder',
            ]);

            $message = \Artisan::output();
            $output['artisan_success'] = $message. " by Artisan methods.";

        } catch (Exception $e) {
            $output['exception'] = $e->getMessage();
        }

    } else {
        $output['exec_success'] = "Command executed successfully. by exec methods.";
    }

    return \App\Helpers\CommonHelper::responseSuccessWithData('Supported languages added successfully!',$output);

});

Route::get('/linkstorage', function () {
    Artisan::call('storage:link');

    return Artisan::output();
});

Route::get('/generate_key', function () {
    Artisan::call('key:generate');
    // echo 'Encryption key generated!';
    return Artisan::output();
});

Route::get('/migrate', function () {
    Artisan::call('migrate');
    return Artisan::output();
});


Route::get('/get_path', function () {
    echo __DIR__;
});

Route::get('pos/invoice/{id}', [App\Http\Controllers\API\SellerPosController::class, 'showInvoice'])->name('pos.invoice');

Route::get('/order_invoice/{order_id}', function ($order_id) {
    $data = CommonHelper::getOrderDetails($order_id);
    if(!$data["order"]){
        return CommonHelper::responseError("Order Not found!");
    }
    $invoice = view('invoiceMpdf', $data)->render();
    echo $invoice;
});

Route::get('get-google-key', function () {
    return response()->json(['key' => \App\Models\Setting::get_value('google_place_api_key')]);
});



Route::post('save_token', [App\Http\Controllers\Controller::class, 'updateToken'])->name('fcmToken');
Route::post('log_notification_click', [App\Http\Controllers\Controller::class, 'logNotificationClick'])->name('logNotificationClick')->withoutMiddleware([\App\Http\Middleware\VerifyCsrfToken::class]);

Route::get('test', [App\Http\Controllers\Controller::class, 'test']);
Route::get('database_backup_download', [App\Http\Controllers\DatabaseBackupController::class, 'download_db_backup'])->name('database_backup_download.download_db_backup');

Route::get('logs', [\Rap2hpoutre\LaravelLogViewer\LogViewerController::class, 'index']);
Route::get('deploy', [\App\Http\Controllers\Controller::class, 'deploy']);

Route::get('/cicd/test', function () {
    return response()->json(['version' => config('app.version', '31')]);
});

Route::view('mail_theame','mail');

// Customer Policies (grouped with /customer prefix)
Route::prefix('customer')->group(function () {
    Route::get('privacy-policy', [\App\Http\Controllers\API\PrivacyPolicyApiController::class, 'printPrivacyPolicy']);
    Route::get('terms-conditions', [\App\Http\Controllers\API\PrivacyPolicyApiController::class, 'printTermsConditions']);
    Route::get('returns-and-exchanges-policy', [\App\Http\Controllers\API\PrivacyPolicyApiController::class, 'printReturnsAndExchangesPolicy']);
    Route::get('shipping-policy', [\App\Http\Controllers\API\PrivacyPolicyApiController::class, 'printShippingPolicy']);
    Route::get('cancellation-policy', [\App\Http\Controllers\API\PrivacyPolicyApiController::class, 'printCancellationPolicy']);
    Route::get('about-us', [\App\Http\Controllers\API\AboutContactApiController::class, 'printAboutUs']);
    Route::get('contact-us', [\App\Http\Controllers\API\AboutContactApiController::class, 'printContactUs']);
});

Route::get('delivery-boy-privacy-policy', [\App\Http\Controllers\API\PrivacyPolicyDeliveryBoyApiController::class, 'printPrivacyPolicy']);
Route::get('delivery-boy-terms-conditions', [\App\Http\Controllers\API\PrivacyPolicyDeliveryBoyApiController::class, 'printTermsConditions']);

// Vendor (Seller) Policies — public, branded pages (grouped with /vendor prefix, mirrors /customer)
Route::prefix('vendor')->group(function () {
    Route::get('privacy-policy', [\App\Http\Controllers\API\PrivacyPolicySellerApiController::class, 'printPrivacyPolicy']);
    Route::get('terms-conditions', [\App\Http\Controllers\API\PrivacyPolicySellerApiController::class, 'printTermsConditions']);
});

// Legacy aliases (used by the vendor app's WebView) — keep working
Route::get('seller-privacy-policy', [\App\Http\Controllers\API\PrivacyPolicySellerApiController::class, 'printPrivacyPolicy']);
Route::get('seller-terms-conditions', [\App\Http\Controllers\API\PrivacyPolicySellerApiController::class, 'printTermsConditions']);

Route::get('manager-privacy-policy', [\App\Http\Controllers\API\PrivacyPolicyManagerAppApiController::class, 'printPrivacyPolicy']);
Route::get('manager-terms-conditions', [\App\Http\Controllers\API\PrivacyPolicyManagerAppApiController::class, 'printTermsConditions']);

Route::get('manager-terms-conditions', [\App\Http\Controllers\API\PrivacyPolicyManagerAppApiController::class, 'printTermsConditions']);

//Webhook
Route::post('midtrans/callback', [\App\Http\Controllers\MidtransController::class, 'midtransWebhook']);
Route::post('webhook/stripe', [\App\Http\Controllers\StripeController::class, 'stripeWebhook']);
Route::get('phonepe/callback', [\App\Http\Controllers\PhonepeController::class, 'phonepeWebhook'])->name('phonepe.callback');
Route::post('phonepe/redirect', [\App\Http\Controllers\PhonepeController::class, 'phonepeRedirect'])->name('phonepe.redirect');

Route::post('cashfree/callback', [\App\Http\Controllers\CashfreeController::class, 'cashfreeWebhook'])->name('cashfree.callback');
Route::get('cashfree/redirect', [\App\Http\Controllers\CashfreeController::class, 'cashfreeRedirect'])->name('cashfree.redirect');

Route::post('paytabs/callback', [\App\Http\Controllers\PaytabsController::class, 'paytabsWebhook'])->name('paytabs.callback');
Route::match(['get', 'post'], 'paytabs/redirect', [\App\Http\Controllers\PaytabsController::class, 'paytabsRedirect'])->name('paytabs.redirect');

//for localization in vuejs
Route::post('api/change_language', [\App\Http\Controllers\Controller::class, 'doLanguageChange'])->name('change_language');

Route::get('/js/lang', function() {

    $lang = config('app.locale');
    $lang = $lang ?? 'en';
    $file = Cache::rememberForever('lang.js', function () {
        $lang = config('app.locale');
        $lang = $lang ?? 'en';

        return file_get_contents(resource_path('lang/' . $lang . '.json'));
    });
    header('Content-Type: text/javascript');
    echo('window.i18n = ' . $file);
    exit();
})->name('assets.lang')->withoutMiddleware('auth:sanctum');


Route::get('firebase-messaging-sw.js', [\App\Http\Controllers\API\FirebaseApiController::class, 'firebaseMessagingJsCode'])->name('assets.firebase-messaging-sw');

// Deep linking routes for app navigation
Route::get('app/{module}/{screen}', [\App\Http\Controllers\DeepLinkController::class, 'handleDeepLink'])->name('app.deeplink');
Route::get('zenfoo-app-links.json', [\App\Http\Controllers\DeepLinkController::class, 'getAppLinksConfig'])->name('app.links-config');

// Admin Manual Payment Routes
Route::group(['prefix' => 'admin/manual-payments', 'middleware' => 'auth'], function () {
    Route::get('/', [\App\Http\Controllers\Admin\ManualPaymentController::class, 'index'])->name('admin.manual-payments.index');
    Route::get('{id}', [\App\Http\Controllers\Admin\ManualPaymentController::class, 'show'])->name('admin.manual-payments.show');
    Route::post('{id}/approve', [\App\Http\Controllers\Admin\ManualPaymentController::class, 'approve'])->name('admin.manual-payments.approve');
    Route::post('{id}/reject', [\App\Http\Controllers\Admin\ManualPaymentController::class, 'reject'])->name('admin.manual-payments.reject');
});

Route::group(['prefix' => 'admin/delivery-boys', 'middleware' => 'auth'], function () {
    Route::get('{deliveryBoyId}/manual-reduction', [\App\Http\Controllers\Admin\ManualPaymentController::class, 'showManualReductionForm'])->name('admin.manual-payments.manual-reduction');
    Route::post('{deliveryBoyId}/manually-reduce-hand-cash', [\App\Http\Controllers\Admin\ManualPaymentController::class, 'manuallyReduceHandCash'])->name('admin.manual-payments.reduce-hand-cash');
});

// Dummy account/data deletion request page
Route::get('delete', function () {
    return view('delete_request');
})->name('delete.request');

Route::get('product/{slug}', function ($slug) {
    $appScheme = "zenfoo://product/" . urlencode($slug);
    $playStoreUrl = "https://play.google.com/store/apps/details?id=com.zenfoo.customer";
    return view('product_deeplink', compact('slug', 'appScheme', 'playStoreUrl'));
});

Route::get('{all}', function () {
    return view('welcome');
})->where('all', '^(?!customer[^-]).*$');


Route::group(['prefix' => 'seller_registration_helper'], function () {
    Route::get('/', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'index'])->name('seller_registration_helper.index');
    Route::post('save', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'store'])->name('seller_registration_helper.save');
    Route::get('show/{id}', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'show'])->name('seller_registration_helper.show');
    Route::post('update/{id}', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'update'])->name('seller_registration_helper.update');
    Route::post('delete/{id}', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'destroy'])->name('seller_registration_helper.delete');
});