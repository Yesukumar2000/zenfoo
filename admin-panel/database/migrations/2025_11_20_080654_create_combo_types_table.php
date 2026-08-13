<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateComboTypesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // test
        Schema::create('combo_types', function (Blueprint $table) {
            $table->id(); // AUTO_INCREMENT primary key
            $table->string('name_of_type')->nullable(); // varchar(255)
            $table->timestamp('created_at')->useCurrent(); // default current_timestamp()
            $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate(); 
            // matches "ON UPDATE CURRENT_TIMESTAMP()"
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('combo_types');
    }
}
