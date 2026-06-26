<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PatientLocation extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'patient_id',
        'lat',
        'lng',
        'recorded_at',
    ];

    protected $casts = [
        'recorded_at' => 'datetime',
    ];
}
