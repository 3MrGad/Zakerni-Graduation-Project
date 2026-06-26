<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TodoCategory;
use Illuminate\Http\Request;

class TodoCategoryController extends Controller
{
    private function patientId()
    {
        return auth()->user()->patient->patient_id;
    }

    public function index()
    {
        $categories = TodoCategory::withCount('todos')
            ->where('patient_id', $this->patientId())->get();
        return response()->json(['status' => true, 'data' => $categories]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name'  => 'required|string|max:100',
            'color' => 'nullable|string|max:7',
            'icon'  => 'nullable|string|max:50',
        ]);

        $category = TodoCategory::create([
            'patient_id' => $this->patientId(),
            'name'       => $request->name,
            'color'      => $request->color ?? '#3B82F6',
            'icon'       => $request->icon,
        ]);

        return response()->json(['status' => true, 'data' => $category], 201);
    }

    public function show($id)
    {
        $category = TodoCategory::with('todos')
            ->where('patient_id', $this->patientId())->findOrFail($id);
        return response()->json(['status' => true, 'data' => $category]);
    }

    public function update(Request $request, $id)
    {
        $category = TodoCategory::where('patient_id', $this->patientId())->findOrFail($id);
        $request->validate([
            'name'  => 'sometimes|string|max:100',
            'color' => 'sometimes|string|max:7',
            'icon'  => 'sometimes|string|max:50',
        ]);
        $category->update($request->only(['name', 'color', 'icon']));
        return response()->json(['status' => true, 'data' => $category]);
    }

    public function destroy($id)
    {
        $category = TodoCategory::where('patient_id', $this->patientId())->findOrFail($id);
        $category->delete();
        return response()->json(['status' => true, 'message' => 'Category deleted']);
    }
}