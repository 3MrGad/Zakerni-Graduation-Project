<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SetGeofenceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'radius_meters' => 'required|integer|min:50|max:1000',
        ];
    }
}
