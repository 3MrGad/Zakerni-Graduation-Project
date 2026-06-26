<?php
namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;

    protected $table = 'users';
    public $timestamps = true;

    protected $fillable = [
        'name', 'email', 'password', 'role', 'fcm_token',
    ];

    protected $hidden = ['password', 'remember_token'];

    public function patient()
    {
        return $this->hasOne(Patient::class, 'user_id', 'id');
    }

    public function caregiver()
    {
        return $this->hasOne(Caregiver::class, 'user_id', 'id');
    }
}