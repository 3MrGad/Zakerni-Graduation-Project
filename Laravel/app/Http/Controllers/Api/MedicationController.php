<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ResolvesPatientAccess;
use App\Http\Controllers\Controller;
use App\Models\Medication;
use App\Models\MedicationLog;
use App\Models\MedicationSchedule;
use App\Jobs\SendMedicineReminderJob;
use Illuminate\Http\Request;

class MedicationController extends Controller
{
    use ResolvesPatientAccess;

    public function index(Request $request)
    {
        $patientId = $this->resolvePatientId($request);
        $meds = Medication::where('patient_id', $patientId)->get();

        return response()->json(['status' => true, 'data' => $meds]);
    }

    public function store(Request $request)
    {
        $this->requireCaregiver();

        $request->validate([
            'patient_id'     => 'nullable|integer|exists:patients,patient_id',
            'med_name'       => 'required|string|max:100',
            'dosage'         => 'nullable|string|max:50',
            'frequency'      => 'nullable|string|max:50',
            'reason'         => 'nullable|string|max:255',
            'scheduled_time' => 'nullable|date_format:H:i',
        ]);

        $patientId = $this->resolvePatientId($request);

        $exists = Medication::where('patient_id', $patientId)
            ->where('med_name', $request->med_name)
            ->exists();

        if ($exists) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Medicine already exists',
            ], 409);
        }

        $med = Medication::create([
            'patient_id' => $patientId,
            'med_name'   => $request->med_name,
            'dosage'     => $request->dosage,
            'frequency'  => $request->frequency,
            'reason'     => $request->reason,
        ]);

        if ($request->filled('scheduled_time')) {
            $schedule = MedicationSchedule::create([
                'med_id'                  => $med->med_id,
                'patient_id'              => $patientId,
                'scheduled_time'          => $request->scheduled_time,
                'reminder_minutes_before' => $request->input('reminder_minutes_before', 30),
                'is_active'               => true,
            ]);

            $fireAt = now()->setTimeFromTimeString($schedule->scheduled_time)
                ->subMinutes($schedule->reminder_minutes_before);

            if ($fireAt->isFuture()) {
                SendMedicineReminderJob::dispatch($schedule)->delay($fireAt);
            }
        }

        return response()->json(['status' => true, 'data' => $med], 201);
    }

    public function show(Request $request, $id)
    {
        $patientId = $this->resolvePatientId($request);
        $med = Medication::where('patient_id', $patientId)->findOrFail($id);

        return response()->json(['status' => true, 'data' => $med]);
    }

    public function update(Request $request, $id)
    {
        $this->requireCaregiver();
        $patientId = $this->resolvePatientId($request);

        $med = Medication::where('patient_id', $patientId)->findOrFail($id);
        $request->validate([
            'med_name'  => 'sometimes|string|max:100',
            'dosage'    => 'sometimes|string|max:50',
            'frequency' => 'sometimes|string|max:50',
            'reason'    => 'sometimes|string|max:255',
        ]);
        $med->update($request->only(['med_name', 'dosage', 'frequency', 'reason']));

        return response()->json(['status' => true, 'data' => $med]);
    }

    public function destroy(Request $request, $id)
    {
        $this->requireCaregiver();
        $patientId = $this->resolvePatientId($request);

        $med = Medication::where('patient_id', $patientId)->findOrFail($id);
        $med->delete();

        return response()->json(['status' => true, 'message' => 'Medication deleted']);
    }

    public function markTaken(Request $request, $id)
    {
        $patientId = $this->resolvePatientId($request);

        $med = Medication::where('patient_id', $patientId)->findOrFail($id);

        if ($med->is_taken) {
            return response()->json([
                'status'  => 'success',
                'message' => 'Already marked as taken.',
                'data'    => $med,
            ]);
        }

        $med->update([
            'is_taken' => true,
            'taken_at' => now(),
        ]);

        MedicationLog::create([
            'medication_id' => $med->med_id,
            'patient_id'    => $patientId,
            'taken_at'      => now(),
            'confirmed'     => false,
            'status'        => 'taken',
            'scheduled_at'  => now(),
        ]);

        return response()->json([
            'status'  => 'success',
            'message' => 'Medication marked as taken.',
            'data'    => $med->fresh(),
        ]);
    }
}
