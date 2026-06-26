<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('patients', function (Blueprint $table) {
            $table->id('patient_id');
            $table->integer('user_id')->nullable();
            $table->string('name', 100)->nullable();
            $table->string('gender', 20)->nullable();
            $table->string('medical_condition', 255)->nullable();
            $table->integer('age')->nullable();
            $table->string('allergies', 255)->nullable();
            $table->string('device_id', 50)->nullable();
            $table->integer('caregiver_id')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate();
        });

        Schema::create('caregivers', function (Blueprint $table) {
            $table->id('caregiver_id');
            $table->integer('user_id')->nullable();
            $table->string('name', 100)->nullable();
            $table->string('phone', 20)->nullable();
            $table->string('email', 100)->nullable();
            $table->integer('doctor_id')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate();
        });

        Schema::create('doctors', function (Blueprint $table) {
            $table->id('doctor_id');
            $table->string('name', 100)->nullable();
            $table->string('specialty', 100)->nullable();
            $table->string('phone', 20)->nullable();
            $table->string('email', 100)->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('chatbot_interactions', function (Blueprint $table) {
            $table->id('chat_id');
            $table->integer('patient_id')->nullable();
            $table->enum('sender', ['patient', 'bot'])->nullable();
            $table->text('message')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('medication', function (Blueprint $table) {
            $table->id('med_id');
            $table->integer('patient_id')->nullable();
            $table->string('med_name', 100)->nullable();
            $table->string('dosage', 50)->nullable();
            $table->string('frequency', 50)->nullable();
            $table->string('reason', 255)->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('appointment', function (Blueprint $table) {
            $table->id('appointment_id');
            $table->integer('patient_id')->nullable();
            $table->integer('doctor_id')->nullable();
            $table->dateTime('appointment_date')->nullable();
            $table->string('type', 100)->nullable();
            $table->string('status', 50)->nullable();
            $table->text('notes')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('memories', function (Blueprint $table) {
            $table->id('memory_id');
            $table->integer('patient_id')->nullable();
            $table->string('title', 255)->nullable();
            $table->text('description')->nullable();
            $table->string('image_url', 255)->nullable();
            $table->dateTime('memory_date')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('activities', function (Blueprint $table) {
            $table->id('activity_id');
            $table->integer('patient_id')->nullable();
            $table->string('activity_name', 100)->nullable();
            $table->text('steps')->nullable();
            $table->string('category', 50)->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('gps_tracking', function (Blueprint $table) {
            $table->id('tracking_id');
            $table->integer('patient_id')->nullable();
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->timestamp('recorded_at')->useCurrent();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('gps_tracking');
        Schema::dropIfExists('activities');
        Schema::dropIfExists('memories');
        Schema::dropIfExists('appointment');
        Schema::dropIfExists('medication');
        Schema::dropIfExists('chatbot_interactions');
        Schema::dropIfExists('doctors');
        Schema::dropIfExists('caregivers');
        Schema::dropIfExists('patients');
    }
};
