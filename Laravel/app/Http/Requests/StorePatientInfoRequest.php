<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StorePatientInfoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'patient_id'         => 'nullable|integer|exists:patients,patient_id',
            'name'               => 'required|string|max:100',
            'age'                => 'nullable|integer|min:0|max:150',
            'date_of_birth'      => 'nullable|date',
            'diagnosis_date'     => 'nullable|date',
            'medical_condition'  => 'nullable|string|max:255',
            'chronic_diseases'   => 'nullable|string|max:255',
            'emergency_contact'  => 'nullable|string|max:255',
            'emergency_contact_2' => 'nullable|string|max:255',
            'about'              => 'nullable|string',
            'likes'              => 'nullable|string',
            'dislikes'           => 'nullable|string',
            'allergies'          => 'nullable|string|max:255',
            'gender'             => 'nullable|string|max:20',
        ];
    }
}
