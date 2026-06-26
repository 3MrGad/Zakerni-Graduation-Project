<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponses;
use App\Http\Controllers\Api\Concerns\ResolvesPatientAccess;
use App\Http\Controllers\Controller;
use App\Models\Reminder;
use Illuminate\Http\Request;

class ReminderController extends Controller
{
    use ResolvesPatientAccess, ApiResponses;

    public function index(Request $request)
    {
        $patientId = $this->resolvePatientId($request);

        $reminders = Reminder::where('patient_id', $patientId)
            ->orderByDesc('created_at')
            ->get();

        return $this->success(['reminders' => $reminders]);
    }
}
