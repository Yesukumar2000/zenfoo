<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateAppPagesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('app_pages', function (Blueprint $table) {
            $table->id();
            $table->string('page_type')->unique(); // terms, privacy, about, contact
            $table->string('title');
            $table->longText('content'); // HTML content
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // Insert default pages
        DB::table('app_pages')->insert([
            [
                'page_type' => 'terms',
                'title' => 'Terms and Conditions',
                'content' => '<h1>Terms and Conditions</h1><p>Welcome to our platform. Please read these terms carefully.</p>',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'page_type' => 'privacy',
                'title' => 'Privacy Policy',
                'content' => '<h1>Privacy Policy</h1><p>Your privacy is important to us. This policy outlines how we collect and use your data.</p>',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'page_type' => 'about',
                'title' => 'About Us',
                'content' => '<h1>About Us</h1><p>Learn more about our company and mission.</p>',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('app_pages');
    }
}
