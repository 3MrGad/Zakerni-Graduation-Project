<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreHowToNoteRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'patient_id' => 'nullable|integer|exists:patients,patient_id',
            'title'      => 'required|string|max:255',
            'content'    => 'required|string',
        ];
    }
}
