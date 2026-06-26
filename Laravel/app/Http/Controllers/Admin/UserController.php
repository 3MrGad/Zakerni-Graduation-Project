<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;

class UserController extends Controller
{
    // GET all users
    public function index()
    {
        return response()->json(User::all());
    }

    // ADD user
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'email' => 'required|email|unique:users',
            'role' => 'required'
        ]);

        $user = User::create($request->all());

        return response()->json($user);
    }

    // UPDATE user
    public function update(Request $request, $id)
    {
        $user = User::findOrFail($id);

        $user->update($request->all());

        return response()->json($user);
    }

    // DELETE user
    public function destroy($id)
    {
        User::destroy($id);

        return response()->json(['message' => 'User deleted']);
    }
}