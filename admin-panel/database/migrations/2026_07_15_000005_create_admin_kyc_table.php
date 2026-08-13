<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateAdminKycTable extends Migration
{
    public function up()
    {
        if (!Schema::hasTable('admin_kyc')) {
            Schema::create('admin_kyc', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('admin_id');
                $table->string('document_type')->nullable();
                $table->string('document_number')->nullable();
                $table->string('document_file')->nullable();
                $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
                $table->text('remarks')->nullable();
                $table->unsignedBigInteger('verified_by')->nullable();
                $table->timestamp('verified_at')->nullable();
                $table->timestamps();

                $table->index('admin_id');
                $table->index('status');
            });
        }
    }

    public function down()
    {
        Schema::dropIfExists('admin_kyc');
    }
}
