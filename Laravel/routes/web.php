<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'status' => 'OK',
        'message' => 'Laravel backend is running',
    ]);
});
