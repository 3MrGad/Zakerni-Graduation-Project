<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponses;
use App\Http\Controllers\Controller;
use App\Http\Requests\AdminStoreUserRequest;
use App\Http\Requests\AdminUpdateUserRequest;
use App\Models\Caregiver;
use App\Models\Patient;
use App\Models\User;
use App\Support\PatientPayload;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AdminController extends Controller
{
    use ApiResponses;

   public function index()
{
    $patients = Patient::with('user')->get()->map(function ($p) {

        return [

            'id' => $p->patient_id,

            'name' => $p->name,

            'email' => $p->user->email ?? '',

            'role' => 'patient',

        ];

    });

    $caregivers = Caregiver::with('user')->get()->map(function ($c) {

        return [

            'id' => $c->caregiver_id,

            'name' => $c->name,

            'email' => $c->user->email ?? '',

            'role' => 'caregiver',

        ];

    });

    $admins = User::where('role', 'admin')->get()->map(function ($u) {

        return [

            'id' => $u->id,

            'name' => $u->name,

            'email' => $u->email,

            'role' => 'admin',

        ];

    });

    return response()->json([

        'users' => $patients
            ->concat($caregivers)
            ->concat($admins)
            ->values()

    ]);

}

    public function storeUser(AdminStoreUserRequest $request)
{
    dd($request->all());
    $data = $request->validated();

    $user = User::create([
        'name' => trim($data['Fname'] . ' ' . $data['Lname']),
        'email' => $data['Email'],
        'password' => Hash::make($data['password']),
        'role' => $data['type'],
    ]);


    // ===== Patient =====
    if ($data['type'] === 'patient') {

        Patient::create([
            'user_id' => $user->id,
            'name' => $user->name,
            'patient_code' => (string) Str::uuid(),
        ]);

        return response()->json([
            'message' => 'Patient created successfully',
            'user' => $user,
        ], 201);
    }


    // ===== Caregiver =====
    elseif ($data['type'] === 'caregiver') {

        Caregiver::create([
            'user_id' => $user->id,
            'name' => $user->name,
            'email' => $data['Email'],
            'phone' => $data['phone'] ?? null,
            'linked_patient_id' => null,
        ]);

        return response()->json([
            'message' => 'Caregiver created successfully',
            'user' => $user,
        ], 201);
    }


    // ===== Admin =====
    elseif ($data['type'] === 'admin') {

        return response()->json([
            'message' => 'Admin created successfully',
            'user' => $user,
        ], 201);
    }


    // ===== Invalid Type =====
    return response()->json([
        'message' => 'Invalid user type',
    ], 400);
}

    public function updateUser(AdminUpdateUserRequest $request, $type, $id)
    {   if ($type === 'admin') {

    $admin = User::where('role', 'admin')
                 ->where('id', $id)
                 ->firstOrFail();

    if ($request->filled('name')) {
        $admin->name = $request->name;
    }

    if ($request->filled('email')) {
        $admin->email = $request->email;
    }

    if ($request->filled('password')) {
        $admin->password = Hash::make($request->password);
    }

    $admin->save();

    return response()->json([
        'message' => 'Admin updated successfully',
        'user' => $admin,
    ]);
}
        if ($type === 'patient') {
            $patient = Patient::findOrFail($id);
            if ($request->filled('name')) {
                $patient->name = $request->name;
            }
            if ($request->filled('age')) {
                $patient->age = $request->age;
            }
            $patient->save();

            if ($patient->user && $request->filled('email')) {
                $patient->user->update(['email' => $request->email, 'name' => $request->name ?? $patient->user->name]);
            }

            return $this->success(['patient' => $patient->fresh()]);
        }

        if ($type === 'caregiver') {
            $caregiver = Caregiver::findOrFail($id);
            if ($request->filled('name')) {
                $caregiver->name = $request->name;
            }
            if ($request->filled('phone')) {
                $caregiver->phone = $request->phone;
            }
            $caregiver->save();

            if ($caregiver->user && $request->filled('email')) {
                $caregiver->user->update(['email' => $request->email, 'name' => $request->name ?? $caregiver->user->name]);
                $caregiver->email = $request->email;
                $caregiver->save();
            }

            return $this->success(['caregiver' => $caregiver->fresh()]);
        }

        return $this->error('Invalid user type.', 422);
    }

    public function destroyUser($type, $id)
{
    // ===== Patient =====
    if ($type === 'patient') {

        $patient = Patient::findOrFail($id);

        $userId = $patient->user_id;

        $patient->delete();

        if ($userId) {
            User::where('id', $userId)->delete();
        }

        return response()->json([
            'message' => 'Patient deleted successfully'
        ]);
        
    }

    // ===== Caregiver =====
    if ($type === 'caregiver') {

        $caregiver = Caregiver::findOrFail($id);

        $userId = $caregiver->user_id;

        $caregiver->delete();

        if ($userId) {
            User::where('id', $userId)->delete();
        }

        return response()->json([
            'message' => 'Caregiver deleted successfully'
        ]);
    }

    // ===== Admin =====
    if ($type === 'admin') {

        $admin = User::where('role', 'admin')
                     ->where('id', $id)
                     ->firstOrFail();

        $admin->delete();

        return response()->json([
            'message' => 'Admin deleted successfully'
        ]);
    }

    return response()->json([
        'message' => 'Invalid user type'
    ], 400);
}
}