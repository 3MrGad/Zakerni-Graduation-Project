<?php

namespace App\Http\Middleware;

use App\Models\Admin;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdmin
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user instanceof Admin) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Admin access required.',
            ], 403);
        }

        return $next($request);
    }
}
