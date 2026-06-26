<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('todo_categories', function (Blueprint $table) {
            $table->id('category_id');
            $table->unsignedBigInteger('patient_id');
            $table->string('name', 100);
            $table->string('color', 7)->default('#3B82F6');
            $table->string('icon', 50)->nullable();
            $table->timestamps();

            $table->foreign('patient_id')
                  ->references('patient_id')->on('patients')
                  ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('todo_categories');
    }
};