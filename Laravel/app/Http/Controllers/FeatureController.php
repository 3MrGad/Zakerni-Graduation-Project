<?php

namespace App\Http\Controllers;
use App\Models\Feature;
use Illuminate\Http\Request;

class FeatureController extends Controller
{
    public function index()
    {
        return Feature::all();
    }

    public function update(Request $request, $id)
    {
        $feature = Feature::findOrFail($id);
        $feature->update([
            'is_enabled' => $request->is_enabled
        ]);

        return $feature;
    }
}
