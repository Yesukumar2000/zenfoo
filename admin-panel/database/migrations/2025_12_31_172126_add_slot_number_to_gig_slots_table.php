<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('gig_slots', function (Blueprint $table) {
            $table->integer('slot_number')->default(1)->after('gig_id');
            $table->string('slot_name')->nullable()->after('slot_number');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('gig_slots', function (Blueprint $table) {
            $table->dropColumn(['slot_number', 'slot_name']);
        });
    }
};
