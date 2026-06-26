<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponses;
use App\Http\Controllers\Api\Concerns\ResolvesPatientAccess;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreMemoryRequest;
use App\Models\Memory;
use App\Models\Reminder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class MemoryController extends Controller
{
    use ResolvesPatientAccess, ApiResponses;

    public function store(StoreMemoryRequest $request)
    {
        $caregiver = $this->requireCaregiver();
        $patientId = $this->resolvePatientId($request);

        $photoPath = null;
        if ($request->hasFile('photo')) {
            $photoPath = $request->file('photo')->store('memories', 'public');
        }

        $memory = Memory::create([
            'patient_id'   => $patientId,
            'caregiver_id' => $caregiver->caregiver_id,
            'title'        => $request->input('title', 'Memory'),
            'description'  => $request->description,
            'photo_path'   => $photoPath,
            'image_url'    => $photoPath ? Storage::url($photoPath) : null,
            'memory_date'  => now(),
        ]);

        Reminder::create([
            'patient_id'   => $patientId,
            'caregiver_id' => $caregiver->caregiver_id,
            'type'         => 'memory',
            'title'        => $memory->title,
            'description'  => $memory->description,
            'photo_path'   => $photoPath ? Storage::url($photoPath) : null,
            'reference_id' => $memory->memory_id,
            'remind_at'    => now(),
        ]);

        return $this->success(['memory' => $memory], 'Memory saved.', 201);
    }

    public function index(Request $request, $id)
    {
        $patientId = (int) $id;

        if ($this->isPatient()) {
            $patient = $this->patientRecord();
            if (!$patient || (int) $patient->patient_id !== $patientId) {
                return $this->error('Unauthorized', 403);
            }
        } elseif ($this->isCaregiver()) {
            $this->resolvePatientId($request->merge(['patient_id' => $patientId]));
        } else {
            return $this->error('Unauthorized', 403);
        }

        $memories = Memory::where('patient_id', $patientId)
            ->orderByDesc('memory_id')
            ->get()
            ->map(function (Memory $m) {
                $m->photo_url = $m->photo_path
                    ? (str_starts_with($m->photo_path, 'http') ? $m->photo_path : Storage::url($m->photo_path))
                    : $m->image_url;
                return $m;
            });

        return $this->success(['memories' => $memories]);
    }
}
