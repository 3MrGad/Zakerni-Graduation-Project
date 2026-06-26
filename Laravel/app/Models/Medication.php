<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Medication extends Model
{
    protected $table = 'medication';
    protected $primaryKey = 'med_id';
    public $timestamps = false; // only has created_at, no updated_at

    protected $fillable = [
        'patient_id', 'med_name', 'dosage', 'frequency', 'reason', 'is_taken', 'taken_at',
    ];

    protected $casts = [
        'is_taken' => 'boolean',
        'taken_at' => 'datetime',
    ];

    public function patient()
    {
        return $this->belongsTo(Patient::class, 'patient_id', 'patient_id');
    }

    public function schedules()
    {
        return $this->hasMany(MedicationSchedule::class, 'med_id', 'med_id');
    }
}