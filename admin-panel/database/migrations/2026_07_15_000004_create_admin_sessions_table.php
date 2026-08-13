<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateAdminSessionsTable extends Migration
{
    public function up()
    {
        if (!Schema::hasTable('admin_sessions')) {
            Schema::create('admin_sessions', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->unsignedBigInteger('admin_id');
                $table->string('session_id')->nullable();
                $table->string('ip_address', 45)->nullable();
                $table->string('user_agent')->nullable();
                $table->string('device')->nullable();
                $table->string('platform')->nullable();
                $table->string('location')->nullable();
                $table->tinyInteger('is_current')->default(0);
                $table->timestamp('last_activity')->nullable();
                $table->timestamps();

                $table->index('admin_id');
                $table->index('last_activity');
            });
        }
    }

    public function down()
    {
        Schema::dropIfExists('admin_sessions');
    }
}
