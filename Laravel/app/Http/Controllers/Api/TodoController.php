<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponses;
use App\Http\Controllers\Api\Concerns\ResolvesPatientAccess;
use App\Http\Controllers\Controller;
use App\Models\Todo;
use Illuminate\Http\Request;

class TodoController extends Controller
{
    use ResolvesPatientAccess, ApiResponses;

    public function index(Request $request)
    {
        $patientId = $this->resolvePatientId($request);
        $query = Todo::with('category')->where('patient_id', $patientId);

        if ($request->filled('category_id')) {
            $query->where('category_id', $request->category_id);
        }
        if ($request->filled('is_completed')) {
            $query->where('is_completed', (bool) $request->is_completed);
        }
        if ($request->filled('priority')) {
            $query->where('priority', $request->priority);
        }

        return response()->json(['status' => true, 'data' => $query->orderBy('due_date')->get()]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'patient_id'  => 'nullable|integer|exists:patients,patient_id',
            'title'       => 'required|string|max:255',
            'description' => 'nullable|string',
            'category_id' => 'nullable|exists:todo_categories,category_id',
            'priority'    => 'nullable|in:low,medium,high',
            'due_date'    => 'nullable|date',
            'created_by'  => 'nullable|in:patient,caregiver',
        ]);

        $createdBy = $request->input('created_by');

        if ($this->isPatient()) {
            $this->requirePatient();
            $createdBy = 'patient';
        } else {
            $this->requireCaregiver();
            $createdBy = $createdBy ?? 'caregiver';
        }

        $patientId = $this->resolvePatientId($request);

        $todo = Todo::create([
            'patient_id'   => $patientId,
            'category_id'  => $request->category_id,
            'title'        => $request->title,
            'description'  => $request->description,
            'priority'     => $request->priority ?? 'medium',
            'due_date'     => $request->due_date,
            'is_completed' => false,
            'created_by'   => $createdBy,
        ]);

        return response()->json(['status' => true, 'data' => $todo->load('category')], 201);
    }

    public function show(Request $request, $id)
    {
        $patientId = $this->resolvePatientId($request);
        $todo = Todo::with('category')
            ->where('patient_id', $patientId)
            ->findOrFail($id);

        return response()->json(['status' => true, 'data' => $todo]);
    }

    public function update(Request $request, $id)
    {
        $this->requireCaregiver();
        $patientId = $this->resolvePatientId($request);

        $todo = Todo::where('patient_id', $patientId)->findOrFail($id);
        $request->validate([
            'title'       => 'sometimes|string|max:255',
            'description' => 'sometimes|string',
            'category_id' => 'sometimes|nullable|exists:todo_categories,category_id',
            'priority'    => 'sometimes|in:low,medium,high',
            'due_date'    => 'sometimes|nullable|date',
        ]);
        $todo->update($request->only(['title', 'description', 'category_id', 'priority', 'due_date']));

        return response()->json(['status' => true, 'data' => $todo]);
    }

    public function destroy(Request $request, $id)
    {
        $this->requireCaregiver();
        $patientId = $this->resolvePatientId($request);

        $todo = Todo::where('patient_id', $patientId)->findOrFail($id);
        $todo->delete();

        return response()->json(['status' => true, 'message' => 'Todo deleted']);
    }

    public function complete($id)
    {
        $patient = $this->requirePatient();
        $todo = Todo::where('patient_id', $patient->patient_id)->findOrFail($id);
        $todo->update(['is_completed' => true, 'completed_at' => now()]);

        return response()->json(['status' => true, 'message' => 'Marked complete', 'data' => $todo]);
    }

    public function uncomplete($id)
    {
        $patient = $this->requirePatient();
        $todo = Todo::where('patient_id', $patient->patient_id)->findOrFail($id);
        $todo->update(['is_completed' => false, 'completed_at' => null]);

        return response()->json(['status' => true, 'data' => $todo]);
    }

    public function storePatientTask(Request $request)
{
    $request->validate([
        'title' => 'required|string|max:255',
        'description' => 'nullable|string',
    ]);

    $patient = $this->requirePatient();

    $todo = Todo::create([
        'patient_id'   => $patient->patient_id,
        'title'        => $request->title,
        'description'  => $request->description,
        'priority'     => 'medium',
        'is_completed' => false,
        'created_by'   => 'patient',
    ]);

    return $this->success(
        ['task' => $this->formatTask($todo)],
        'Task created.',
        201
    );
}

    public function indexPatientTasks()
    {
        $patient = $this->requirePatient();
        $tasks = Todo::where('patient_id', $patient->patient_id)
            ->orderByDesc('created_at')
            ->get()
            ->map(fn ($t) => $this->formatTask($t));

        return $this->success(['tasks' => $tasks]);
    }

    public function indexCaregiverTasks(Request $request)
    {
        $this->requireCaregiver();
        $patientId = $this->resolvePatientId($request);

        $tasks = Todo::where('patient_id', $patientId)
            ->orderByDesc('created_at')
            ->get()
            ->map(fn ($t) => $this->formatTask($t));

        return $this->success(['tasks' => $tasks]);
    }

    public function markDone($id)
    {
        $patient = $this->requirePatient();
        $todo = Todo::where('patient_id', $patient->patient_id)->findOrFail($id);
        $todo->update(['is_completed' => true, 'completed_at' => now()]);

        return $this->success(['task' => $this->formatTask($todo->fresh())], 'Task marked done.');
    }

    private function formatTask(Todo $todo): array
    {
        return [
            'id'          => $todo->todo_id,
            'title'       => $todo->title,
            'is_done'     => $todo->is_completed,
            'created_by'  => $todo->created_by ?? 'caregiver',
            'created_at'  => $todo->created_at,
            'updated_at'  => $todo->updated_at,
        ];
    }
}
