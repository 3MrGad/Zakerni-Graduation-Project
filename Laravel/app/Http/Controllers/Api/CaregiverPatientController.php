<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ResolvesPatientAccess;
use App\Http\Controllers\Controller;
use App\Models\Patient;
use Illuminate\Http\Request;

class CaregiverPatientController extends Controller
{
    use ResolvesPatientAccess;

    public function linkPatient(Request $request)
    {
        $caregiver = $this->requireCaregiver();

        $request->validate([
            'patient_id' => 'required|integer|exists:patients,patient_id',
        ]);

        $patient = Patient::findOrFail($request->patient_id);

        if ($patient->caregiver_id && (int) $patient->caregiver_id !== (int) $caregiver->caregiver_id) {
            return response()->json([
                'status'  => false,
                'message' => 'This patient is already linked to another caregiver',
            ], 409);
        }

        $patient->caregiver_id = $caregiver->caregiver_id;
        $patient->save();

        return response()->json([
            'status'  => true,
            'message' => 'Patient linked successfully',
            'data'    => $patient,
        ]);
    }
}
