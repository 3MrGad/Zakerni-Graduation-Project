<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Reminder extends Model
{
    protected $fillable = [
        'patient_id',
        'caregiver_id',
        'type',
        'title',
        'description',
        'photo_path',
        'reference_id',
        'remind_at',
    ];
}
