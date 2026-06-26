<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RegisterPatientRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'Fname'             => 'required|string|max:255',
            'Lname'             => 'required|string|max:255',
            'Email'             => 'required|email|unique:users,email',
            'password'          => 'required|string|min:6|confirmed',
            'Gender'            => 'nullable|string|in:male,female',
            'medical_condition' => 'nullable|string|max:255',
            'age'               => 'nullable|integer',
            'allergies'         => 'nullable|string|max:255',
            'device_id'         => 'nullable|string|max:50',
        ];
    }
}
