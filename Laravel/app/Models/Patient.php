<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Patient extends Model
{
    use HasFactory;

    protected $table = 'patients';
    protected $primaryKey = 'patient_id';
    public $incrementing = true;
    protected $keyType = 'int';

    protected $fillable = [
        'user_id',
        'name',
        'patient_code',
        'profile_photo',
        'gender',
        'medical_condition',
        'age',
        'allergies',
        'device_id',
        'caregiver_id',
        'date_of_birth',
        'diagnosis_date',
        'emergency_contact',
        'emergency_contact_2',
        'about',
        'likes',
        'dislikes',
        'chronic_diseases',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
