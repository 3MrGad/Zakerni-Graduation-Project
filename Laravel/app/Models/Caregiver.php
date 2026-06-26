<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Caregiver extends Model
{
    protected $table = 'caregivers';
    protected $primaryKey = 'caregiver_id';
    public $timestamps = true; // your DB has created_at + updated_at

    protected $fillable = [
        'user_id', 'name', 'phone', 'email', 'doctor_id',
        'linked_patient_id', 'home_lat', 'home_lng', 'geofence_radius_meters',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'id');
    }

    public function patients()
    {
        return $this->hasMany(Patient::class, 'caregiver_id', 'caregiver_id');
    }
}