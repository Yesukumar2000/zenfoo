<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateAdminLoginLogsTable extends Migration
{
    public function up()
    {
        if (!Schema::hasTable('admin_login_logs')) {
            Schema::create('admin_login_logs', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('admin_id')->nullable();
                $table->string('email')->nullable();
                $table->string('ip_address', 45)->nullable();
                $table->string('user_agent')->nullable();
                $table->string('device')->nullable();
                $table->string('location')->nullable();
                $table->tinyInteger('is_success')->default(1)->comment('1 => success, 0 => failed');
                $table->timestamps();

                $table->index('admin_id');
                $table->index('is_success');
                $table->index('created_at');
            });
        }
    }

    public function down()
    {
        Schema::dropIfExists('admin_login_logs');
    }
}
