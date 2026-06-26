<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('patients', function (Blueprint $table) {
            if (!Schema::hasColumn('patients', 'patient_code')) {
                $table->uuid('patient_code')->nullable()->unique()->after('patient_id');
            }
            if (!Schema::hasColumn('patients', 'profile_photo')) {
                $table->string('profile_photo', 500)->nullable();
            }
        });

        $patients = DB::table('patients')->whereNull('patient_code')->get(['patient_id']);
        foreach ($patients as $patient) {
            DB::table('patients')
                ->where('patient_id', $patient->patient_id)
                ->update(['patient_code' => (string) Str::uuid()]);
        }

        if (Schema::hasColumn('patients', 'patient_code')) {
            try {
                Schema::table('patients', function (Blueprint $table) {
                    $table->uuid('patient_code')->nullable(false)->change();
                });
            } catch (\Throwable $e) {
                // SQLite / older MySQL may not support change(); column stays nullable with unique values
            }
        }

        Schema::table('medication_logs', function (Blueprint $table) {
            if (!Schema::hasColumn('medication_logs', 'medication_id')) {
                $table->unsignedBigInteger('medication_id')->nullable()->after('log_id');
            }
            if (!Schema::hasColumn('medication_logs', 'confirmed')) {
                $table->boolean('confirmed')->default(false)->after('taken_at');
            }
        });

        try {
            Schema::table('medication_logs', function (Blueprint $table) {
                $table->unsignedBigInteger('schedule_id')->nullable()->change();
            });
        } catch (\Throwable $e) {
            // schedule_id may already be nullable
        }
    }

    public function down(): void
    {
        Schema::table('medication_logs', function (Blueprint $table) {
            if (Schema::hasColumn('medication_logs', 'medication_id')) {
                $table->dropColumn('medication_id');
            }
            if (Schema::hasColumn('medication_logs', 'confirmed')) {
                $table->dropColumn('confirmed');
            }
        });

        Schema::table('patients', function (Blueprint $table) {
            if (Schema::hasColumn('patients', 'patient_code')) {
                $table->dropColumn('patient_code');
            }
            if (Schema::hasColumn('patients', 'profile_photo')) {
                $table->dropColumn('profile_photo');
            }
        });
    }
};
