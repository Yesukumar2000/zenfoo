<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateDepartmentsTable extends Migration
{
    public function up()
    {
        if (!Schema::hasTable('departments')) {
            Schema::create('departments', function (Blueprint $table) {
                $table->bigIncrements('id');
                $table->string('name');
                $table->string('color', 20)->nullable();
                $table->text('description')->nullable();
                $table->tinyInteger('status')->default(1)->comment('1 => Active, 0 => Inactive');
                $table->timestamps();
            });
        }
    }

    public function down()
    {
        Schema::dropIfExists('departments');
    }
}
