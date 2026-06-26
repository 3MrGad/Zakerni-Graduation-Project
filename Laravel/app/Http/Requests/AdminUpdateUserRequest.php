<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AdminUpdateUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name'  => 'sometimes|string|max:255',
            'email' => 'sometimes|email',
            'phone' => 'sometimes|nullable|string|max:20',
            'age'   => 'sometimes|nullable|integer',
        ];
    }
}
