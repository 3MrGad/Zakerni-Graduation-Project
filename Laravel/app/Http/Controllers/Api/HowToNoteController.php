<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponses;
use App\Http\Controllers\Api\Concerns\ResolvesPatientAccess;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreHowToNoteRequest;
use App\Models\HowToNote;
use Illuminate\Http\Request;

class HowToNoteController extends Controller
{
    use ResolvesPatientAccess, ApiResponses;

    public function store(StoreHowToNoteRequest $request)
    {
        $caregiver = $this->requireCaregiver();
        $patientId = $this->resolvePatientId($request);

        $note = HowToNote::create([
            'caregiver_id' => $caregiver->caregiver_id,
            'patient_id'   => $patientId,
            'title'        => $request->title,
            'content'      => $request->content,
        ]);

        return $this->success(['note' => $note], 'How-to note saved.', 201);
    }

    public function indexForPatient(Request $request, $id)
    {
        $patientId = (int) $id;

        if ($this->isPatient()) {
            $patient = $this->patientRecord();
            if (!$patient || (int) $patient->patient_id !== $patientId) {
                return $this->error('Unauthorized', 403);
            }
        } elseif ($this->isCaregiver()) {
            $request->merge(['patient_id' => $patientId]);
            $this->resolvePatientId($request);
        } else {
            return $this->error('Unauthorized', 403);
        }

        $notes = HowToNote::where('patient_id', $patientId)
            ->orderByDesc('created_at')
            ->get();

        return $this->success(['notes' => $notes]);
    }

    public function indexForAuthenticatedPatient()
    {
        $patient = $this->requirePatient();
        $notes = HowToNote::where('patient_id', $patient->patient_id)
            ->orderByDesc('created_at')
            ->get();

        return $this->success(['notes' => $notes]);
    }
}
