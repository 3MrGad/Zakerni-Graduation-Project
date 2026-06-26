<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('medication_logs', function (Blueprint $table) {
            $table->id('log_id');
            $table->unsignedBigInteger('schedule_id');
            $table->unsignedBigInteger('patient_id');
            $table->dateTime('scheduled_at');
            $table->dateTime('taken_at')->nullable();
            $table->enum('status', ['pending', 'taken', 'missed'])->default('pending');
            $table->timestamps();

            $table->foreign('schedule_id')
                  ->references('schedule_id')->on('medication_schedules')
                  ->onDelete('cascade');

            $table->foreign('patient_id')
                  ->references('patient_id')->on('patients')
                  ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('medication_logs');
    }
};