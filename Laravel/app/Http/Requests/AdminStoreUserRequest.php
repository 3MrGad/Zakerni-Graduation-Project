<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AdminStoreUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $type = $this->input('type', 'patient');

        $rules = [
            'type' => 'required|in:patient,caregiver,admin',
            'Fname'    => 'required|string|max:255',
            'Lname' => 'nullable|string|max:255',
            'Email'    => 'required|email|unique:users,email',
            'password' => 'required|string|min:6|',
            //'password' => 'required|string|min:6|confirmed',
        ];

        if ($type === 'caregiver') {
            $rules['phone'] = 'nullable|string|max:20';
            $rules['patient_code'] = 'nullable|uuid|exists:patients,patient_code';
            $rules['PatientID'] = 'nullable|integer|exists:patients,patient_id';
        }

        return $rules;
    }
}
