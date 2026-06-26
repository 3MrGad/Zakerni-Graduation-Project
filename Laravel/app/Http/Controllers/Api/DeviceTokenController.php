<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class DeviceTokenController extends Controller
{
    public function update(Request $request)
    {
        $request->validate(['fcm_token' => 'required|string']);
        $request->user()->update(['fcm_token' => $request->fcm_token]);
        return response()->json(['status' => true, 'message' => 'FCM token saved']);
    }
}