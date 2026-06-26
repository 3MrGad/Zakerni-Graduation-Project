<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreMemoryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'patient_id'  => 'nullable|integer|exists:patients,patient_id',
            'description' => 'required|string|max:2000',
            'photo'       => 'nullable|image|max:5120',
            'title'       => 'nullable|string|max:255',
        ];
    }
}
