<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class HowToNote extends Model
{
    protected $table = 'how_to_notes';

    protected $fillable = [
        'caregiver_id',
        'patient_id',
        'title',
        'content',
    ];
}
