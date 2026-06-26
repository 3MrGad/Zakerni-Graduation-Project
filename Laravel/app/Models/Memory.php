<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Memory extends Model
{
    protected $table = 'memories';
    protected $primaryKey = 'memory_id';
    public $timestamps = false;

    protected $fillable = [
        'patient_id',
        'caregiver_id',
        'title',
        'description',
        'image_url',
        'photo_path',
        'memory_date',
    ];

    public function patient()
    {
        return $this->belongsTo(Patient::class, 'patient_id', 'patient_id');
    }
}
