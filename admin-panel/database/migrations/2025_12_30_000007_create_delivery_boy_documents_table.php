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
        Schema::create('delivery_boy_documents', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('delivery_boy_id');

            // Driving License
            $table->string('driving_license_number', 50)->nullable();
            $table->string('driving_license_front_path')->nullable();
            $table->string('driving_license_back_path')->nullable();
            $table->enum('driving_license_status', ['not_uploaded', 'pending_verification', 'verified', 'rejected'])->default('not_uploaded');

            // RC (Registration Certificate)
            $table->string('rc_number', 50)->nullable();
            $table->string('rc_front_path')->nullable();
            $table->string('rc_back_path')->nullable();
            $table->enum('rc_status', ['not_uploaded', 'pending_verification', 'verified', 'rejected'])->default('not_uploaded');

            // Aadhar
            $table->string('aadhar_number', 12)->nullable();
            $table->string('aadhar_front_path')->nullable();
            $table->string('aadhar_back_path')->nullable();
            $table->enum('aadhar_status', ['not_uploaded', 'pending_verification', 'verified', 'rejected'])->default('not_uploaded');

            // PAN
            $table->string('pan_number', 10)->nullable();
            $table->string('pan_front_path')->nullable();
            $table->string('pan_back_path')->nullable();
            $table->enum('pan_status', ['not_uploaded', 'pending_verification', 'verified', 'rejected'])->default('not_uploaded');

            // Bank Details
            $table->string('bank_name', 100)->nullable();
            $table->string('account_holder_name', 100)->nullable();
            $table->string('account_number', 50)->nullable();
            $table->string('ifsc_code', 11)->nullable();
            $table->string('bank_passbook_image_path')->nullable();
            $table->enum('bank_details_status', ['not_uploaded', 'pending_verification', 'verified', 'rejected'])->default('not_uploaded');

            $table->timestamps();

            $table->foreign('delivery_boy_id')->references('id')->on('delivery_boys')->onDelete('cascade');
            $table->unique('delivery_boy_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('delivery_boy_documents');
    }
};
