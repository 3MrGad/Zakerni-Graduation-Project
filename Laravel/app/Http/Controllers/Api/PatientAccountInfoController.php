<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponses;
use App\Http\Controllers\Api\Concerns\ResolvesPatientAccess;
use App\Http\Controllers\Controller;
use App\Http\Requests\PatientAccountInfoRequest;
use App\Models\Patient;
use App\Support\PatientPayload;
class PatientAccountInfoController extends Controller
{
    use ApiResponses, ResolvesPatientAccess;

    public function show()
    {
        $patient = $this->requirePatient();

        return $this->success(['patient' => PatientPayload::format($patient)]);
    }

    public function store(PatientAccountInfoRequest $request)
    {
        return $this->save($request);
    }

    public function update(PatientAccountInfoRequest $request)
    {
        return $this->save($request);
    }

    private function save(PatientAccountInfoRequest $request)
    {
        $patient = $this->requirePatient();
        $data    = $request->validated();

        if ($request->hasFile('profile_photo')) {
            $path = $request->file('profile_photo')->store('patients/photos', 'public');
            $data['profile_photo'] = $path;
        }

        $patient->fill(array_filter([
            'name'              => $data['name'] ?? null,
            'date_of_birth'     => $data['date_of_birth'] ?? null,
            'emergency_contact' => $data['emergency_contact'] ?? null,
            'profile_photo'     => $data['profile_photo'] ?? null,
        ], fn ($v) => $v !== null));

        $patient->save();

        return $this->success(
            ['patient' => PatientPayload::format($patient->fresh())],
            'Patient information saved.'
        );
    }
}
