<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddProductsJsonToSellerWalletTransactionsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('seller_wallet_transactions', function (Blueprint $table) {
            // Add products_json column to store product details for the order
            // Structure: [{"product_id": 1, "product_name": "...", "quantity": 2, "amount": 100, "total_amount": 200, "source": "order_item|combo_item"}, ...]
            if (!Schema::hasColumn('seller_wallet_transactions', 'products_json')) {
                $table->json('products_json')->nullable()->after('item_name');
            }
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('seller_wallet_transactions', function (Blueprint $table) {
            if (Schema::hasColumn('seller_wallet_transactions', 'products_json')) {
                $table->dropColumn('products_json');
            }
        });
    }
}
