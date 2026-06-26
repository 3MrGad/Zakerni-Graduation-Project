<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponses;
use App\Http\Controllers\Controller;
use App\Http\Requests\RegisterCaregiverRequest;
use App\Http\Requests\RegisterPatientRequest;
use App\Models\Caregiver;
use App\Models\Patient;
use App\Models\User;
use App\Support\PatientPayload;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    use ApiResponses;

    public function registerPatient(RegisterPatientRequest $request)
    {
        $data = $request->validated();

        $user = User::create([
            'name'     => trim($data['Fname'] . ' ' . $data['Lname']),
            'email'    => $data['Email'],
            'password' => Hash::make($data['password']),
            'role'     => 'patient',
        ]);

        $patient = Patient::create([
            'user_id'           => $user->id,
            'name'              => trim($data['Fname'] . ' ' . $data['Lname']),
            'gender'            => $data['Gender'] ?? null,
            'medical_condition' => $data['medical_condition'] ?? null,
            'age'               => $data['age'] ?? null,
            'allergies'         => $data['allergies'] ?? null,
            'device_id'         => $data['device_id'] ?? null,
            'patient_code'      => (string) Str::uuid(),
        ]);

        $tokenResult = $user->createToken('auth_token', ['*'], now()->addDay());

        return $this->success([
            'token'        => $tokenResult->plainTextToken,
            'expires_at'   => $tokenResult->accessToken->expires_at?->toIso8601String(),
            'user'         => [
                'id'    => $user->id,
                'name'  => $user->name,
                'email' => $user->email,
                'role'  => $user->role,
            ],
            'patient'      => PatientPayload::format($patient),
            'patient_code' => $patient->patient_code,
            'patient_id'   => $patient->patient_id,
        ], 'Patient registered successfully', 201);
    }

    public function registerCaregiver(RegisterCaregiverRequest $request)
    {
        $data = $request->validated();

        $patient = Patient::where('patient_code', $data['patient_code'])->first();

        if (!$patient) {
            return $this->error('Patient ID not found', 404);
        }

        $user = User::create([
            'name'     => trim($data['Fname'] . ' ' . $data['Lname']),
            'email'    => $data['Email'],
            'password' => Hash::make($data['password']),
            'role'     => 'caregiver',
        ]);

        $caregiver = Caregiver::create([
            'user_id'           => $user->id,
            'name'              => trim($data['Fname'] . ' ' . $data['Lname']),
            'phone'             => $data['phone'] ?? null,
            'email'             => $data['Email'],
            'linked_patient_id' => $patient->patient_id,
        ]);

        $patient->update(['caregiver_id' => $caregiver->caregiver_id]);

        $tokenResult = $user->createToken('auth_token', ['*'], now()->addDay());

        return $this->success([
            'token'        => $tokenResult->plainTextToken,
            'expires_at'   => $tokenResult->accessToken->expires_at?->toIso8601String(),
            'user'         => [
                'id'    => $user->id,
                'name'  => $user->name,
                'email' => $user->email,
                'role'  => $user->role,
            ],
            'caregiver'    => $caregiver,
            'patient'      => PatientPayload::format($patient->fresh()),
            'patient_code' => $patient->patient_code,
            'patient_id'   => $patient->patient_id,
        ], 'Caregiver registered successfully', 201);
    }

    public function login(Request $request)
    {
        $request->validate([
            'Email'       => 'required|email',
            'password'    => 'required|string',
            'remember_me' => 'nullable|boolean',
        ]);

        $user = User::where('email', $request->Email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return $this->error('Invalid credentials', 401);
        }

        $user->tokens()->delete();

        $remember  = $request->boolean('remember_me');
        $expiresAt = $remember ? now()->addDays(60) : now()->addDay();
        $tokenResult = $user->createToken('auth_token', ['*'], $expiresAt);

        if ($request->filled('fcm_token')) {
            $user->update(['fcm_token' => $request->fcm_token]);
        }

        $roleData = null;
        $patientCode = null;

        if ($user->role === 'patient') {
            $roleData = Patient::where('user_id', $user->id)->first();
            $patientCode = $roleData?->patient_code;
        } elseif ($user->role === 'caregiver') {
            $roleData = Caregiver::where('user_id', $user->id)->first();
        }

        $payload = [
            'token'       => $tokenResult->plainTextToken,
            'expires_at'  => $expiresAt->toIso8601String(),
            'remember_me' => $remember,
            'user'        => [
                'id'    => $user->id,
                'name'  => $user->name,
                'role'  => $user->role,
                'email' => $user->email,
            ],
            'data'        => $roleData,
        ];

        if ($roleData instanceof Patient) {
            $payload['data'] = PatientPayload::format($roleData);
            $payload['patient_code'] = $roleData->patient_code;
        }

        return $this->success($payload, 'Login successful');
    }

    public function logout(Request $request)
    {
        $request->user()->tokens()->delete();

        return $this->success(null, 'Logged out');
    }
}
