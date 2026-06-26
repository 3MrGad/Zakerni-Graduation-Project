<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('medication_schedules', function (Blueprint $table) {
            $table->id('schedule_id');
            $table->unsignedBigInteger('med_id');
            $table->unsignedBigInteger('patient_id');
            $table->time('scheduled_time');
            $table->integer('reminder_minutes_before')->default(30);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->foreign('med_id')
                  ->references('med_id')->on('medication')
                  ->onDelete('cascade');

            $table->foreign('patient_id')
                  ->references('patient_id')->on('patients')
                  ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('medication_schedules');
    }
};