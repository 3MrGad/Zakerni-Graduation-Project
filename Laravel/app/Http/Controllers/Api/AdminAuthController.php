<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponses;
use App\Http\Controllers\Controller;
use App\Http\Requests\AdminLoginRequest;
use App\Models\Admin;
use Illuminate\Support\Facades\Hash;

class AdminAuthController extends Controller
{
    use ApiResponses;

    public function login(AdminLoginRequest $request)
    {
        $admin = Admin::where('username', $request->username)->first();

        if (!$admin || !Hash::check($request->password, $admin->password)) {
            return $this->error('Invalid admin credentials.', 401);
        }

        $admin->tokens()->delete();
        $token = $admin->createToken('admin_token', ['*'], now()->addDays(7))->plainTextToken;

        return $this->success([
            'token' => $token,
            'admin' => [
                'id'       => $admin->id,
                'username' => $admin->username,
                'role'     => $admin->role,
            ],
        ], 'Admin login successful.');
    }
}
