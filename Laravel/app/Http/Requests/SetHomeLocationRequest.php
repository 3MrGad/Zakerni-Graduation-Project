<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SetHomeLocationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'lat'                     => 'nullable|numeric|between:-90,90',
            'lng'                     => 'nullable|numeric|between:-180,180',
            'home_lat'                => 'nullable|numeric|between:-90,90',
            'home_lng'                => 'nullable|numeric|between:-180,180',
            'geofence_radius_meters'  => 'nullable|integer|min:50|max:1000',
        ];
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($v) {
            if (!$this->filled('lat') && !$this->filled('home_lat')) {
                $v->errors()->add('lat', 'Latitude is required.');
            }
            if (!$this->filled('lng') && !$this->filled('home_lng')) {
                $v->errors()->add('lng', 'Longitude is required.');
            }
        });
    }

    public function latValue(): float
    {
        return (float) ($this->input('lat') ?? $this->input('home_lat'));
    }

    public function lngValue(): float
    {
        return (float) ($this->input('lng') ?? $this->input('home_lng'));
    }
}
