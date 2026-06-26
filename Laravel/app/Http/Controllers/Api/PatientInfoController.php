<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponses;
use App\Http\Controllers\Api\Concerns\ResolvesPatientAccess;
use App\Http\Controllers\Controller;
use App\Http\Requests\StorePatientInfoRequest;
use App\Models\Patient;
use App\Support\PatientPayload;

class PatientInfoController extends Controller
{
    use ResolvesPatientAccess, ApiResponses;

    public function store(StorePatientInfoRequest $request)
    {
        $this->requireCaregiver();
        $patientId = $this->resolvePatientId($request);

        $patient = Patient::findOrFail($patientId);
        $patient->fill($this->mapFields($request->validated()));
        $patient->save();

        return $this->success(
            ['patient' => PatientPayload::format($patient->fresh())],
            'Patient information saved.',
            201
        );
    }

    public function update(StorePatientInfoRequest $request)
    {
        return $this->store($request);
    }

    public function show()
    {
        $patientId = $this->resolvePatientId(request());
        $patient = Patient::findOrFail($patientId);

        return $this->success([
            'patient' => PatientPayload::format($patient),
        ]);
    }

    private function mapFields(array $data): array
    {
        return array_filter([
            'name'               => $data['name'] ?? null,
            'age'                => $data['age'] ?? null,
            'date_of_birth'      => $data['date_of_birth'] ?? null,
            'diagnosis_date'     => $data['diagnosis_date'] ?? null,
            'medical_condition'  => $data['medical_condition'] ?? null,
            'chronic_diseases'   => $data['chronic_diseases'] ?? null,
            'emergency_contact'  => $data['emergency_contact'] ?? null,
            'emergency_contact_2' => $data['emergency_contact_2'] ?? null,
            'about'              => $data['about'] ?? null,
            'likes'              => $data['likes'] ?? null,
            'dislikes'           => $data['dislikes'] ?? null,
            'allergies'          => $data['allergies'] ?? null,
            'gender'             => $data['gender'] ?? null,
        ], fn ($v) => $v !== null);
    }
}
