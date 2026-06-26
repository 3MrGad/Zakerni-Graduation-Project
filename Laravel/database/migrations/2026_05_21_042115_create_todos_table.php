<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('todos', function (Blueprint $table) {
            $table->id('todo_id');
            $table->unsignedBigInteger('patient_id');
            $table->unsignedBigInteger('category_id')->nullable();
            $table->string('title');
            $table->text('description')->nullable();
            $table->enum('priority', ['low', 'medium', 'high'])->default('medium');
            $table->dateTime('due_date')->nullable();
            $table->boolean('is_completed')->default(false);
            $table->dateTime('completed_at')->nullable();
            $table->timestamps();

            $table->foreign('patient_id')
                  ->references('patient_id')->on('patients')
                  ->onDelete('cascade');

            $table->foreign('category_id')
                  ->references('category_id')->on('todo_categories')
                  ->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('todos');
    }
};