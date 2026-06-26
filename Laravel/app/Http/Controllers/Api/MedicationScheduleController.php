<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ResolvesPatientAccess;
use App\Http\Controllers\Controller;
use App\Models\MedicationSchedule;
use App\Jobs\SendMedicineReminderJob;
use Illuminate\Http\Request;

class MedicationScheduleController extends Controller
{
    use ResolvesPatientAccess;

    public function index(Request $request)
    {
        $patientId = $this->resolvePatientId($request);
        $schedules = MedicationSchedule::with('medication')
            ->where('patient_id', $patientId)
            ->where('is_active', true)
            ->get();

        return response()->json(['status' => true, 'data' => $schedules]);
    }

    public function store(Request $request)
    {
        $this->requireCaregiver();
        $patientId = $this->resolvePatientId($request);

        $request->validate([
            'patient_id'              => 'nullable|integer|exists:patients,patient_id',
            'med_id'                  => 'required|exists:medication,med_id',
            'scheduled_time'          => 'required|date_format:H:i',
            'reminder_minutes_before' => 'integer|min:5|max:120',
        ]);

        $schedule = MedicationSchedule::create([
            'med_id'                  => $request->med_id,
            'patient_id'              => $patientId,
            'scheduled_time'          => $request->scheduled_time,
            'reminder_minutes_before' => $request->reminder_minutes_before ?? 30,
            'is_active'               => true,
        ]);

        $fireAt = now()->setTimeFromTimeString($schedule->scheduled_time)
            ->subMinutes($schedule->reminder_minutes_before);

        if ($fireAt->isFuture()) {
            SendMedicineReminderJob::dispatch($schedule)->delay($fireAt);
        }

        return response()->json(['status' => true, 'data' => $schedule->load('medication')], 201);
    }

    public function show(Request $request, $id)
    {
        $patientId = $this->resolvePatientId($request);
        $schedule = MedicationSchedule::with(['medication', 'logs'])
            ->where('patient_id', $patientId)
            ->findOrFail($id);

        return response()->json(['status' => true, 'data' => $schedule]);
    }

    public function update(Request $request, $id)
    {
        $this->requireCaregiver();
        $patientId = $this->resolvePatientId($request);

        $schedule = MedicationSchedule::where('patient_id', $patientId)->findOrFail($id);
        $request->validate([
            'scheduled_time'          => 'sometimes|date_format:H:i',
            'reminder_minutes_before' => 'sometimes|integer|min:5|max:120',
            'is_active'               => 'sometimes|boolean',
        ]);

        $schedule->update($request->only(['scheduled_time', 'reminder_minutes_before', 'is_active']));

        return response()->json(['status' => true, 'data' => $schedule]);
    }

    public function destroy(Request $request, $id)
    {
        $this->requireCaregiver();
        $patientId = $this->resolvePatientId($request);

        $schedule = MedicationSchedule::where('patient_id', $patientId)->findOrFail($id);
        $schedule->update(['is_active' => false]);

        return response()->json(['status' => true, 'message' => 'Schedule deactivated']);
    }
}
