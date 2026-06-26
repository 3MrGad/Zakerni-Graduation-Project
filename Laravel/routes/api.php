<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\PasswordResetController;
use App\Http\Controllers\Api\PatientInfoController;
use App\Http\Controllers\Api\PatientAccountInfoController;
use App\Http\Controllers\Api\MemoryController;
use App\Http\Controllers\Api\HowToNoteController;
use App\Http\Controllers\Api\ReminderController;
use App\Http\Controllers\Api\AdminAuthController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\DeviceTokenController;
use App\Http\Controllers\Api\MedicationController;
use App\Http\Controllers\Api\MedicationScheduleController;
use App\Http\Controllers\Api\MedicationLogController;
use App\Http\Controllers\Api\TodoController;
use App\Http\Controllers\Api\TodoCategoryController;
use App\Http\Controllers\Api\GpsController;
use App\Http\Controllers\Api\CaregiverPatientController;
use App\Http\Middleware\CorsMiddleware;
use App\Http\Controllers\Admin\UserController;
use App\Http\Controllers\FeatureController;
use App\Http\Controllers\ActivityLogController;


Route::options('/{any}', fn () => response()->json([], 200))->where('any', '.*');

Route::middleware([CorsMiddleware::class])->group(function () {

    // ─── Public ────────────────────────────────────────────────────────────
    Route::post('/register/patient',   [AuthController::class, 'registerPatient']);
    Route::post('/register/caregiver', [AuthController::class, 'registerCaregiver']);
    Route::post('/login',              [AuthController::class, 'login']);

    Route::post('/caregiver/forgot-password', [PasswordResetController::class, 'caregiverForgot']);
    Route::post('/patient/forgot-password',   [PasswordResetController::class, 'patientForgot']);
    Route::post('/caregiver/reset-password',  [PasswordResetController::class, 'caregiverReset']);
    Route::post('/patient/reset-password',    [PasswordResetController::class, 'patientReset']);

    Route::post('/admin/login', [AdminAuthController::class, 'login']);

    // ─── Protected (users: patient / caregiver) ─────────────────────────────
    Route::middleware('auth:sanctum')->group(function () {

        Route::post('/logout',       [AuthController::class, 'logout']);
        Route::post('/device-token', [DeviceTokenController::class, 'update']);

        // ── Patient account info (patient role) ─────────────────────────────
        Route::get('patient/info',  [PatientAccountInfoController::class, 'show']);
        Route::post('patient/info', [PatientAccountInfoController::class, 'store']);
        Route::put('patient/info',  [PatientAccountInfoController::class, 'update']);

        // ── Patient info (caregiver manages linked patient) ───────────────────
        Route::get('patient-info',  [PatientInfoController::class, 'show']);
        Route::post('patient-info', [PatientInfoController::class, 'store']);
        Route::put('patient-info',  [PatientInfoController::class, 'update']);

        Route::post('caregiver/link-patient', [CaregiverPatientController::class, 'linkPatient']);

        // ── Memories ────────────────────────────────────────────────────────
        Route::post('memories', [MemoryController::class, 'store']);
        Route::post('caregiver/memories', [MemoryController::class, 'store']);
        Route::get('patient/{id}/memories', [MemoryController::class, 'index']);

        // ── How-to notes ────────────────────────────────────────────────────
        Route::post('caregiver/how-to-notes', [HowToNoteController::class, 'store']);
        Route::get('patient/how-to-notes', [HowToNoteController::class, 'indexForAuthenticatedPatient']);
        Route::get('patient/{id}/how-to-notes', [HowToNoteController::class, 'indexForPatient']);

        // ── Reminders feed (includes memories) ──────────────────────────────
        Route::get('reminders', [ReminderController::class, 'index']);
        Route::get('patient/reminders', [ReminderController::class, 'index']);

        // ── Medications ─────────────────────────────────────────────────────
        Route::get('patient/medications', [MedicationController::class, 'index']);
        Route::post('caregiver/medications', [MedicationController::class, 'store']);
        Route::post('patient/medications/{id}/take', [MedicationController::class, 'markTaken']);
        Route::apiResource('medications', MedicationController::class);
        Route::patch('medications/{id}/take', [MedicationController::class, 'markTaken']);

        Route::apiResource('medication-schedules', MedicationScheduleController::class);
        Route::get('caregiver/medication-logs', [MedicationLogController::class, 'index']);
        Route::get('medication-logs', [MedicationLogController::class, 'index']);
        Route::post('medication-logs/{id}/take', [MedicationLogController::class, 'markTaken']);
        Route::post('medication-logs/{id}/miss', [MedicationLogController::class, 'markMissed']);

        // ── To-do / tasks ───────────────────────────────────────────────────
        Route::apiResource('todo-categories', TodoCategoryController::class);
        Route::apiResource('todos', TodoController::class);
        Route::post('patient/tasks', [TodoController::class, 'storePatientTask']);
        Route::get('patient/tasks', [TodoController::class, 'indexPatientTasks']);
        Route::patch('patient/tasks/{id}/done', [TodoController::class, 'markDone']);
        Route::get('caregiver/patient-tasks', [TodoController::class, 'indexCaregiverTasks']);
        Route::post('tasks', [TodoController::class, 'store']);
        Route::post('todos/{id}/complete', [TodoController::class, 'complete']);
        Route::post('todos/{id}/uncomplete', [TodoController::class, 'uncomplete']);

        // ── GPS tracking ────────────────────────────────────────────────────
        Route::post('gps/location', [GpsController::class, 'updateLocation']);
        Route::post('patient/location', [GpsController::class, 'patientUpdateLocation']);
        Route::post('patient/update-location', [GpsController::class, 'patientUpdateLocation']);

        Route::get('gps/patients', [GpsController::class, 'getMyPatients']);
        Route::get('gps/patients/{patientId}/location', [GpsController::class, 'getPatientLocation']);
        Route::get('gps/patients/{patientId}/history', [GpsController::class, 'getLocationHistory']);

        Route::post('caregiver/set-home', [GpsController::class, 'setHomeLocation']);
        Route::post('caregiver/set-home-location', [GpsController::class, 'setHomeLocation']);
        Route::post('caregiver/set-geofence', [GpsController::class, 'setGeofence']);
        Route::get('caregiver/patient-location', [GpsController::class, 'caregiverPatientLocation']);
    });

    // ─── Admin (Sanctum token on Admin model) ───────────────────────────────
     Route::middleware(['', ''])->prefix('admin')->group(function () {
        Route::get('users', [AdminController::class, 'index']);
        Route::post('users', [AdminController::class, 'storeUser']);
        Route::put('users/{type}/{id}', [AdminController::class, 'updateUser']);
        Route::delete('users/{type}/{id}', [AdminController::class, 'destroyUser']);
        Route::get('/users', [AdminController::class, 'index']);
    });


    
//Route::delete('/users/{id}', [UserController::class, 'destroy']);

Route::get('/features', [FeatureController::class, 'index']);
Route::put('/features/{id}', [FeatureController::class, 'update']);

//Route::get('/logs', [ActivityLogController::class, 'index']);

});