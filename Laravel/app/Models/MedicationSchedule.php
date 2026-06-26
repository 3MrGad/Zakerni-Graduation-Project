<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MedicationSchedule extends Model
{
    protected $table = 'medication_schedules';
    protected $primaryKey = 'schedule_id';
    public $timestamps = true;

    protected $fillable = [
        'med_id', 'patient_id', 'scheduled_time',
        'reminder_minutes_before', 'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function medication()
    {
        return $this->belongsTo(Medication::class, 'med_id', 'med_id');
    }

    public function patient()
    {
        return $this->belongsTo(Patient::class, 'patient_id', 'patient_id');
    }

    public function logs()
    {
        return $this->hasMany(MedicationLog::class, 'schedule_id', 'schedule_id');
    }
}