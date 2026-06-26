<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponses;
use App\Http\Controllers\Api\Concerns\ResolvesPatientAccess;
use App\Http\Controllers\Controller;
use App\Models\MedicationLog;
use App\Models\Patient;
use Illuminate\Http\Request;
class MedicationLogController extends Controller
{
    use ResolvesPatientAccess, ApiResponses;

    public function index(Request $request)
    {
        if ($this->isPatient()) {
            $patientId = $this->requirePatient()->patient_id;
        } else {
            $this->requireCaregiver();
            $patientId = $this->resolvePatientId($request);
        }

        if ($this->isCaregiver()) {
            return $this->caregiverChecklist($patientId);
        }

        $query = MedicationLog::with('schedule.medication', 'medication')
            ->where('patient_id', $patientId);

        if ($request->filled('date')) {
            $query->whereDate('scheduled_at', $request->date);
        } else {
            $query->whereDate('scheduled_at', today());
        }

        return response()->json(['status' => 'success', 'data' => $query->get()]);
    }

    private function caregiverChecklist(int $patientId)
    {
        $patient = Patient::find($patientId);

        $logs = MedicationLog::query()
            ->where('patient_id', $patientId)
            ->whereNotNull('medication_id')
            ->orderByDesc('taken_at')
            ->limit(100)
            ->get()
            ->map(function (MedicationLog $log) use ($patient) {
                $med = $log->medication;

                return [
                    'id'           => $log->log_id,
                    'medication_id'=> $log->medication_id,
                    'medicine_name'=> $med?->med_name,
                    'taken_at'     => $log->taken_at,
                    'confirmed'    => $log->confirmed,
                    'patient_name' => $patient?->name,
                ];
            });

        return $this->success(['logs' => $logs]);
    }

    public function markTaken($id)
    {
        $patientId = $this->requirePatient()->patient_id;
        $log = MedicationLog::where('patient_id', $patientId)->findOrFail($id);
        $log->update(['status' => 'taken', 'taken_at' => now()]);

        return response()->json(['status' => 'success', 'message' => 'Marked as taken', 'data' => $log]);
    }

    public function markMissed($id)
    {
        $patientId = $this->requirePatient()->patient_id;
        $log = MedicationLog::where('patient_id', $patientId)->findOrFail($id);
        $log->update(['status' => 'missed']);

        return response()->json(['status' => 'success', 'message' => 'Marked as missed', 'data' => $log]);
    }
}
