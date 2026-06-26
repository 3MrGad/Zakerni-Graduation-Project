<?php

namespace App\Support;

use App\Models\Patient;

class PatientPayload
{
    public static function format(Patient $patient): array
    {
        return array_merge($patient->toArray(), [
            'patient_code' => $patient->patient_code,
            'patient_id'   => $patient->patient_id,
        ]);
    }
}
