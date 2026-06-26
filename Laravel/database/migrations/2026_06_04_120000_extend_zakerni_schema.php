<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('patients', function (Blueprint $table) {
            if (!Schema::hasColumn('patients', 'date_of_birth')) {
                $table->date('date_of_birth')->nullable()->after('age');
            }
            if (!Schema::hasColumn('patients', 'diagnosis_date')) {
                $table->date('diagnosis_date')->nullable()->after('medical_condition');
            }
            if (!Schema::hasColumn('patients', 'emergency_contact')) {
                $table->string('emergency_contact', 255)->nullable();
            }
            if (!Schema::hasColumn('patients', 'emergency_contact_2')) {
                $table->string('emergency_contact_2', 255)->nullable();
            }
            if (!Schema::hasColumn('patients', 'about')) {
                $table->text('about')->nullable();
            }
            if (!Schema::hasColumn('patients', 'likes')) {
                $table->text('likes')->nullable();
            }
            if (!Schema::hasColumn('patients', 'dislikes')) {
                $table->text('dislikes')->nullable();
            }
            if (!Schema::hasColumn('patients', 'chronic_diseases')) {
                $table->string('chronic_diseases', 255)->nullable();
            }
        });

        Schema::table('caregivers', function (Blueprint $table) {
            if (!Schema::hasColumn('caregivers', 'linked_patient_id')) {
                $table->unsignedBigInteger('linked_patient_id')->nullable()->after('email');
            }
            if (!Schema::hasColumn('caregivers', 'home_lat')) {
                $table->decimal('home_lat', 10, 8)->nullable();
            }
            if (!Schema::hasColumn('caregivers', 'home_lng')) {
                $table->decimal('home_lng', 11, 8)->nullable();
            }
            if (!Schema::hasColumn('caregivers', 'geofence_radius_meters')) {
                $table->unsignedInteger('geofence_radius_meters')->default(200);
            }
        });

        Schema::table('medication', function (Blueprint $table) {
            if (!Schema::hasColumn('medication', 'is_taken')) {
                $table->boolean('is_taken')->default(false);
            }
            if (!Schema::hasColumn('medication', 'taken_at')) {
                $table->timestamp('taken_at')->nullable();
            }
        });

        try {
            Schema::table('medication', function (Blueprint $table) {
                $table->unique(['patient_id', 'med_name'], 'medication_patient_name_unique');
            });
        } catch (\Throwable $e) {
            // Index may already exist
        }

        Schema::table('todos', function (Blueprint $table) {
            if (!Schema::hasColumn('todos', 'created_by')) {
                $table->enum('created_by', ['patient', 'caregiver'])->default('caregiver')->after('patient_id');
            }
        });

        Schema::table('memories', function (Blueprint $table) {
            if (!Schema::hasColumn('memories', 'caregiver_id')) {
                $table->unsignedBigInteger('caregiver_id')->nullable()->after('patient_id');
            }
            if (!Schema::hasColumn('memories', 'photo_path')) {
                $table->string('photo_path', 500)->nullable()->after('image_url');
            }
        });

        if (!Schema::hasTable('how_to_notes')) {
            Schema::create('how_to_notes', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('caregiver_id');
                $table->unsignedBigInteger('patient_id');
                $table->string('title');
                $table->text('content');
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('reminders')) {
            Schema::create('reminders', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('patient_id');
                $table->unsignedBigInteger('caregiver_id')->nullable();
                $table->string('type', 50)->default('general');
                $table->string('title')->nullable();
                $table->text('description')->nullable();
                $table->string('photo_path', 500)->nullable();
                $table->unsignedBigInteger('reference_id')->nullable();
                $table->timestamp('remind_at')->nullable();
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('admins')) {
            Schema::create('admins', function (Blueprint $table) {
                $table->id();
                $table->string('username')->unique();
                $table->string('password');
                $table->string('role')->default('admin');
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('patient_locations')) {
            Schema::create('patient_locations', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('patient_id');
                $table->decimal('lat', 10, 8);
                $table->decimal('lng', 11, 8);
                $table->timestamp('recorded_at')->useCurrent();
                $table->index(['patient_id', 'recorded_at']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('patient_locations');
        Schema::dropIfExists('reminders');
        Schema::dropIfExists('how_to_notes');
        Schema::dropIfExists('admins');

        Schema::table('memories', function (Blueprint $table) {
            if (Schema::hasColumn('memories', 'caregiver_id')) {
                $table->dropColumn('caregiver_id');
            }
            if (Schema::hasColumn('memories', 'photo_path')) {
                $table->dropColumn('photo_path');
            }
        });

        Schema::table('todos', function (Blueprint $table) {
            if (Schema::hasColumn('todos', 'created_by')) {
                $table->dropColumn('created_by');
            }
        });

        Schema::table('medication', function (Blueprint $table) {
            try {
                $table->dropUnique('medication_patient_name_unique');
            } catch (\Throwable $e) {
            }
            if (Schema::hasColumn('medication', 'is_taken')) {
                $table->dropColumn('is_taken');
            }
            if (Schema::hasColumn('medication', 'taken_at')) {
                $table->dropColumn('taken_at');
            }
        });

        Schema::table('caregivers', function (Blueprint $table) {
            foreach (['linked_patient_id', 'home_lat', 'home_lng', 'geofence_radius_meters'] as $col) {
                if (Schema::hasColumn('caregivers', $col)) {
                    $table->dropColumn($col);
                }
            }
        });

        Schema::table('patients', function (Blueprint $table) {
            foreach (['date_of_birth', 'diagnosis_date', 'emergency_contact', 'emergency_contact_2', 'about', 'likes', 'dislikes', 'chronic_diseases'] as $col) {
                if (Schema::hasColumn('patients', $col)) {
                    $table->dropColumn($col);
                }
            }
        });
    }
};
