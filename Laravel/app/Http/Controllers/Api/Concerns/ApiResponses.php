<?php

namespace App\Http\Controllers\Api\Concerns;

use Illuminate\Http\JsonResponse;

trait ApiResponses
{
    protected function success(mixed $data = null, string $message = 'OK', int $code = 200): JsonResponse
    {
        return response()->json([
            'status'  => 'success',
            'data'    => $data,
            'message' => $message,
        ], $code);
    }

    protected function error(string $message, int $code = 400, mixed $data = null): JsonResponse
    {
        return response()->json([
            'status'  => 'error',
            'data'    => $data,
            'message' => $message,
        ], $code);
    }
}
