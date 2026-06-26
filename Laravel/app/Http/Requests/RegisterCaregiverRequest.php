<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RegisterCaregiverRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'Fname'        => 'required|string|max:255',
            'Lname'        => 'required|string|max:255',
            'Email'        => 'required|email|unique:users,email',
            'password'     => 'required|string|min:6|confirmed',
            'phone'        => 'nullable|string|max:20',
            'patient_code' => 'required|uuid',
            'PatientID'    => 'prohibited',
        ];
    }
}
