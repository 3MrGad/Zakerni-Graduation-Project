<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class PatientAccountInfoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name'              => 'nullable|string|max:100',
            'date_of_birth'     => 'nullable|date',
            'emergency_contact' => 'nullable|string|max:255',
            'profile_photo'     => 'nullable|image|max:5120',
        ];
    }
}
