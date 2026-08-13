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
        // Gigs table - defines work periods (morning, afternoon, evening, night)
        Schema::create('gigs', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // Morning, Afternoon, Evening, Night
            $table->string('display_name'); // Display name for app
            $table->time('start_time'); // e.g., 06:00:00
            $table->time('end_time'); // e.g., 13:00:00
            $table->integer('duration_hours'); // Auto-calculated duration
            $table->decimal('base_earnings', 10, 2)->default(0); // Base pay for this gig
            $table->tinyInteger('status')->default(1); // 1=Active, 0=Inactive
            $table->timestamps();
        });

        // Gig slots - specific date-time slots for each gig
        Schema::create('gig_slots', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('gig_id');
            $table->date('slot_date');
            $table->time('start_time');
            $table->time('end_time');
            $table->integer('max_bookings')->default(50); // Max delivery boys for this slot
            $table->integer('current_bookings')->default(0);
            $table->tinyInteger('status')->default(1); // 1=Available, 0=Full/Closed
            $table->timestamps();

            $table->foreign('gig_id')->references('id')->on('gigs')->onDelete('cascade');
            $table->index(['slot_date', 'gig_id']);
        });

        // Delivery boy gig bookings
        Schema::create('delivery_boy_gig_bookings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('delivery_boy_id');
            $table->unsignedBigInteger('gig_slot_id');
            $table->enum('booking_status', ['booked', 'active', 'completed', 'cancelled', 'no_show'])->default('booked');
            $table->datetime('booked_at');
            $table->datetime('started_at')->nullable();
            $table->datetime('ended_at')->nullable();
            $table->decimal('earnings', 10, 2)->default(0);
            $table->integer('orders_completed')->default(0);
            $table->integer('orders_cancelled')->default(0);
            $table->decimal('distance_km', 10, 2)->default(0);
            $table->text('cancellation_reason')->nullable();
            $table->timestamps();

            $table->foreign('delivery_boy_id')->references('id')->on('delivery_boys')->onDelete('cascade');
            $table->foreign('gig_slot_id')->references('id')->on('gig_slots')->onDelete('cascade');
            $table->unique(['delivery_boy_id', 'gig_slot_id'], 'db_gig_booking_unique');
        });

        // Daily tracking for delivery boys
        Schema::create('delivery_boy_daily_tracking', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('delivery_boy_id');
            $table->date('tracking_date');
            $table->enum('online_status', ['offline', 'online', 'busy'])->default('offline');
            $table->datetime('first_login_at')->nullable();
            $table->datetime('last_activity_at')->nullable();
            $table->integer('total_login_minutes')->default(0);
            $table->decimal('total_earnings', 10, 2)->default(0);
            $table->decimal('total_distance_km', 10, 2)->default(0);
            $table->integer('gigs_completed')->default(0);
            $table->integer('orders_delivered')->default(0);
            $table->integer('orders_cancelled')->default(0);
            $table->timestamps();

            $table->foreign('delivery_boy_id')->references('id')->on('delivery_boys')->onDelete('cascade');
            $table->unique(['delivery_boy_id', 'tracking_date'], 'db_daily_tracking_unique');
        });

        // Session tracking for login/logout times
        Schema::create('delivery_boy_sessions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('delivery_boy_id');
            $table->unsignedBigInteger('gig_booking_id')->nullable();
            $table->datetime('login_at');
            $table->datetime('logout_at')->nullable();
            $table->integer('duration_minutes')->default(0);
            $table->decimal('latitude_start', 10, 8)->nullable();
            $table->decimal('longitude_start', 11, 8)->nullable();
            $table->decimal('latitude_end', 10, 8)->nullable();
            $table->decimal('longitude_end', 11, 8)->nullable();
            $table->timestamps();

            $table->foreign('delivery_boy_id')->references('id')->on('delivery_boys')->onDelete('cascade');
            $table->foreign('gig_booking_id')->references('id')->on('delivery_boy_gig_bookings')->onDelete('set null');
        });

        // Incentive Offers table (renamed to avoid conflict with existing offers table)
        Schema::create('incentive_offers', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // Sankranthi Offer, Diwali Bonus, etc.
            $table->string('banner_image')->nullable();
            $table->text('description');
            $table->datetime('start_date');
            $table->datetime('end_date');
            $table->tinyInteger('status')->default(1);

            // Conditions
            $table->integer('min_gigs_required')->default(0); // Min gigs to complete
            $table->integer('max_gigs_skip')->default(0); // Max gigs that can be skipped
            $table->integer('max_orders_cancel')->default(0); // Max orders that can be cancelled
            $table->boolean('login_mandatory')->default(true); // Must login in booked slots
            $table->json('eligible_gig_ids')->nullable(); // Which gigs are eligible

            $table->timestamps();
        });

        // Incentive offer tiers - earnings milestones and rewards
        Schema::create('incentive_offer_tiers', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('incentive_offer_id');
            $table->decimal('earnings_target', 10, 2); // e.g., 500, 1000, 2000
            $table->decimal('incentive_amount', 10, 2); // e.g., 100, 210, 500
            $table->string('tier_name')->nullable(); // Bronze, Silver, Gold
            $table->integer('order_number')->default(0); // For sorting
            $table->timestamps();

            $table->foreign('incentive_offer_id')->references('id')->on('incentive_offers')->onDelete('cascade');
        });

        // Track delivery boy progress in incentive offers
        Schema::create('delivery_boy_incentive_progress', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('delivery_boy_id');
            $table->unsignedBigInteger('incentive_offer_id');
            $table->decimal('current_earnings', 10, 2)->default(0);
            $table->integer('gigs_completed')->default(0);
            $table->integer('gigs_skipped')->default(0);
            $table->integer('orders_cancelled')->default(0);
            $table->boolean('login_compliance')->default(true);
            $table->boolean('is_eligible')->default(true);
            $table->decimal('incentive_earned', 10, 2)->default(0);
            $table->enum('status', ['active', 'completed', 'failed'])->default('active');
            $table->timestamps();

            $table->foreign('delivery_boy_id')->references('id')->on('delivery_boys')->onDelete('cascade');
            $table->foreign('incentive_offer_id')->references('id')->on('incentive_offers')->onDelete('cascade');
            $table->unique(['delivery_boy_id', 'incentive_offer_id'], 'db_incentive_progress_unique');
        });

        // Location tracking history
        Schema::create('delivery_boy_location_history', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('delivery_boy_id');
            $table->unsignedBigInteger('session_id')->nullable();
            $table->decimal('latitude', 10, 8);
            $table->decimal('longitude', 11, 8);
            $table->decimal('distance_from_last_km', 10, 2)->default(0);
            $table->datetime('tracked_at');
            $table->timestamps();

            $table->foreign('delivery_boy_id')->references('id')->on('delivery_boys')->onDelete('cascade');
            $table->foreign('session_id')->references('id')->on('delivery_boy_sessions')->onDelete('set null');
            $table->index(['delivery_boy_id', 'tracked_at']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('delivery_boy_location_history');
        Schema::dropIfExists('delivery_boy_incentive_progress');
        Schema::dropIfExists('incentive_offer_tiers');
        Schema::dropIfExists('incentive_offers');
        Schema::dropIfExists('delivery_boy_sessions');
        Schema::dropIfExists('delivery_boy_daily_tracking');
        Schema::dropIfExists('delivery_boy_gig_bookings');
        Schema::dropIfExists('gig_slots');
        Schema::dropIfExists('gigs');
    }
};
