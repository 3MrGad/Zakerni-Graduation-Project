<?php

namespace App\Http\Controllers\Api\Concerns;

use App\Models\Caregiver;
use App\Models\Patient;
use Illuminate\Http\Request;

trait ResolvesPatientAccess
{
    protected function authUser()
    {
        return auth()->user();
    }

    protected function isCaregiver(): bool
    {
        return $this->authUser()?->role === 'caregiver';
    }

    protected function isPatient(): bool
    {
        return $this->authUser()?->role === 'patient';
    }

    protected function caregiverRecord(): ?Caregiver
    {
        if (!$this->isCaregiver()) {
            return null;
        }

        return Caregiver::where('user_id', $this->authUser()->id)->first();
    }

    protected function patientRecord(): ?Patient
    {
        if (!$this->isPatient()) {
            return null;
        }

        return Patient::where('user_id', $this->authUser()->id)->first();
    }

    protected function resolvePatientId(Request $request): int
    {
        if ($this->isPatient()) {
            $patient = $this->patientRecord();
            if (!$patient) {
                abort(response()->json(['status' => false, 'message' => 'Patient profile not found'], 404));
            }

            return (int) $patient->patient_id;
        }

        if ($this->isCaregiver()) {
            $caregiver = $this->caregiverRecord();
            if (!$caregiver) {
                abort(response()->json(['status' => false, 'message' => 'Caregiver profile not found'], 404));
            }

            $patientId = $request->input('patient_id') ?? $request->query('patient_id');

            if (!$patientId && $caregiver->linked_patient_id) {
                return (int) $caregiver->linked_patient_id;
            }

            if (!$patientId) {
                $first = Patient::where('caregiver_id', $caregiver->caregiver_id)->first();
                if (!$first) {
                    abort(response()->json([
                        'status'  => 'error',
                        'message' => 'No patient linked. Link a patient first or pass patient_id.',
                    ], 422));
                }

                return (int) $first->patient_id;
            }

            $patient = Patient::where('patient_id', $patientId)
                ->where(function ($q) use ($caregiver) {
                    $q->where('caregiver_id', $caregiver->caregiver_id)
                      ->orWhere('patient_id', $caregiver->linked_patient_id);
                })
                ->first();

            if (!$patient) {
                abort(response()->json([
                    'status'  => false,
                    'message' => 'Patient not found or not assigned to you',
                ], 403));
            }

            return (int) $patient->patient_id;
        }

        abort(response()->json(['status' => false, 'message' => 'Unauthorized role'], 403));
    }

    protected function requireCaregiver(): Caregiver
    {
        if (!$this->isCaregiver()) {
            abort(response()->json(['status' => false, 'message' => 'Only caregivers can perform this action'], 403));
        }

        $caregiver = $this->caregiverRecord();
        if (!$caregiver) {
            abort(response()->json(['status' => false, 'message' => 'Caregiver profile not found'], 404));
        }

        return $caregiver;
    }

    protected function requirePatient(): Patient
    {
        if (!$this->isPatient()) {
            abort(response()->json(['status' => false, 'message' => 'Only patients can perform this action'], 403));
        }

        $patient = $this->patientRecord();
        if (!$patient) {
            abort(response()->json(['status' => false, 'message' => 'Patient profile not found'], 404));
        }

        return $patient;
    }
}
