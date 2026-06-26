<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MedicationLog extends Model
{
    protected $table = 'medication_logs';
    protected $primaryKey = 'log_id';
    public $timestamps = true;

    protected $fillable = [
        'schedule_id', 'medication_id', 'patient_id', 'scheduled_at', 'taken_at', 'status', 'confirmed',
    ];

    protected $casts = [
        'scheduled_at' => 'datetime',
        'taken_at'     => 'datetime',
        'confirmed'    => 'boolean',
    ];

    public function schedule()
    {
        return $this->belongsTo(MedicationSchedule::class, 'schedule_id', 'schedule_id');
    }

    public function patient()
    {
        return $this->belongsTo(Patient::class, 'patient_id', 'patient_id');
    }

    public function medication()
    {
        return $this->belongsTo(Medication::class, 'medication_id', 'med_id');
    }
}