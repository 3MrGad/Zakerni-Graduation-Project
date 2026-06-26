<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponses;
use App\Http\Controllers\Controller;
use App\Http\Requests\SetGeofenceRequest;
use App\Http\Requests\SetHomeLocationRequest;
use App\Http\Requests\UpdatePatientLocationRequest;
use App\Models\Patient;
use App\Models\Caregiver;
use App\Models\PatientLocation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Support\FirebaseCredentials;
use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;

class GpsController extends Controller
{
    use ApiResponses;

    public function patientUpdateLocation(UpdatePatientLocationRequest $request)
    {
        return $this->updateLocation($request->merge([
            'latitude'  => $request->lat,
            'longitude' => $request->lng,
        ]));
    }

    // Patient sends their location
    public function updateLocation(Request $request)
    {
        $request->validate([
            'latitude'  => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        $user    = $request->user();
        $patient = Patient::where('user_id', $user->id)->first();

        if (!$patient) {
            return response()->json(['status' => false, 'message' => 'Patient not found'], 404);
        }

        DB::table('gps_tracking')->insert([
            'patient_id'  => $patient->patient_id,
            'latitude'    => $request->latitude,
            'longitude'   => $request->longitude,
            'recorded_at' => now(),
        ]);

        PatientLocation::create([
            'patient_id'  => $patient->patient_id,
            'lat'         => $request->latitude,
            'lng'         => $request->longitude,
            'recorded_at' => now(),
        ]);

        $caregiver = $patient->caregiver_id
            ? Caregiver::find($patient->caregiver_id)
            : null;

        $homeLat = $caregiver?->home_lat ?? $request->home_lat ?? null;
        $homeLng = $caregiver?->home_lng ?? $request->home_lng ?? null;
        $radius  = $caregiver?->geofence_radius_meters ?? 200;

        if ($homeLat && $homeLng) {
            $distance = $this->haversineDistance(
                $homeLat, $homeLng,
                $request->latitude, $request->longitude
            );

            if ($distance > $radius) {
                $this->notifyCaregiver($patient, $request->latitude, $request->longitude, $distance);
            }
        }

        return response()->json([
            'status'  => true,
            'message' => 'Location updated',
            'data'    => [
                'patient_id' => $patient->patient_id,
                'latitude'   => $request->latitude,
                'longitude'  => $request->longitude,
                'timestamp'  => now(),
            ],
        ]);
    }

    public function caregiverPatientLocation(Request $request)
    {
        $user      = $request->user();
        $caregiver = Caregiver::where('user_id', $user->id)->first();

        if (!$caregiver) {
            return $this->error('Caregiver not found', 404);
        }

        $patientId = $caregiver->linked_patient_id
            ?: Patient::where('caregiver_id', $caregiver->caregiver_id)->value('patient_id');

        if (!$patientId) {
            return $this->error('No linked patient', 404);
        }

        return $this->getPatientLocation($request, $patientId);
    }

    public function setGeofence(SetGeofenceRequest $request)
    {
        $user      = $request->user();
        $caregiver = Caregiver::where('user_id', $user->id)->first();

        if (!$caregiver) {
            return $this->error('Caregiver not found', 404);
        }

        $caregiver->geofence_radius_meters = $request->radius_meters;
        $caregiver->save();

        return $this->success([
            'geofence_radius_meters' => $caregiver->geofence_radius_meters,
        ], 'Geofence radius saved.');
    }

    public function setHomeLocation(SetHomeLocationRequest $request)
    {
        $user      = $request->user();
        $caregiver = Caregiver::where('user_id', $user->id)->first();

        if (!$caregiver) {
            return $this->error('Caregiver not found', 404);
        }

        $caregiver->home_lat = $request->latValue();
        $caregiver->home_lng = $request->lngValue();
        if ($request->filled('geofence_radius_meters')) {
            $caregiver->geofence_radius_meters = $request->geofence_radius_meters;
        }
        $caregiver->save();

        return $this->success([
            'home_lat'               => $caregiver->home_lat,
            'home_lng'               => $caregiver->home_lng,
            'geofence_radius_meters' => $caregiver->geofence_radius_meters,
        ], 'Home location saved.');
    }

    // Caregiver gets the latest patient location
    public function getPatientLocation(Request $request, $patientId)
    {
        $user      = $request->user();
        $caregiver = Caregiver::where('user_id', $user->id)->first();

        if (!$caregiver) {
            return response()->json(['status' => false, 'message' => 'Caregiver not found'], 404);
        }

        // Make sure this caregiver is assigned to this patient
        $patient = Patient::where('patient_id', $patientId)
            ->where('caregiver_id', $caregiver->caregiver_id)
            ->first();

        if (!$patient) {
            return response()->json(['status' => false, 'message' => 'Patient not found or not assigned to you'], 404);
        }

        $latest = PatientLocation::where('patient_id', $patientId)
            ->orderByDesc('recorded_at')
            ->first();

        if (!$latest) {
            $latest = DB::table('gps_tracking')
                ->where('patient_id', $patientId)
                ->orderByDesc('recorded_at')
                ->first();
        }

        if (!$latest) {
            return response()->json(['status' => false, 'message' => 'No location data yet'], 404);
        }

        $caregiver = Caregiver::find($patient->caregiver_id);
        $lat = $latest->lat ?? $latest->latitude;
        $lng = $latest->lng ?? $latest->longitude;
        $recordedAt = $latest->recorded_at;

        $outsideGeofence = false;
        $distance = null;
        if ($caregiver && $caregiver->home_lat && $caregiver->home_lng) {
            $distance = $this->haversineDistance(
                $caregiver->home_lat,
                $caregiver->home_lng,
                $lat,
                $lng
            );
            $outsideGeofence = $distance > ($caregiver->geofence_radius_meters ?? 200);
        }

        return response()->json([
            'status' => true,
            'data'   => [
                'patient_name'        => $patient->name,
                'patient_id'          => $patient->patient_id,
                'latitude'            => $lat,
                'longitude'           => $lng,
                'lat'                 => $lat,
                'lng'                 => $lng,
                'recorded_at'         => $recordedAt,
                'home_lat'            => $caregiver?->home_lat,
                'home_lng'            => $caregiver?->home_lng,
                'geofence_radius_meters' => $caregiver?->geofence_radius_meters ?? 200,
                'distance_meters'     => $distance ? round($distance) : null,
                'is_outside_geofence' => $outsideGeofence,
                'outside_geofence'    => $outsideGeofence,
            ],
        ]);
    }

    // Caregiver gets location history for their patient
    public function getLocationHistory(Request $request, $patientId)
    {
        $user      = $request->user();
        $caregiver = Caregiver::where('user_id', $user->id)->first();

        if (!$caregiver) {
            return response()->json(['status' => false, 'message' => 'Caregiver not found'], 404);
        }

        $patient = Patient::where('patient_id', $patientId)
            ->where('caregiver_id', $caregiver->caregiver_id)
            ->first();

        if (!$patient) {
            return response()->json(['status' => false, 'message' => 'Patient not found'], 404);
        }

        $history = DB::table('gps_tracking')
            ->where('patient_id', $patientId)
            ->orderByDesc('recorded_at')
            ->limit(50)
            ->get();

        return response()->json(['status' => true, 'data' => $history]);
    }

    // Caregiver gets all their patients
    public function getMyPatients(Request $request)
    {
        $user      = $request->user();
        $caregiver = Caregiver::where('user_id', $user->id)->first();

        if (!$caregiver) {
            return response()->json(['status' => false, 'message' => 'Caregiver not found'], 404);
        }

        $patients = Patient::where('caregiver_id', $caregiver->caregiver_id)->get();

        return response()->json(['status' => true, 'data' => $patients]);
    }

    // Calculate distance in meters between two GPS points (Haversine formula)
    private function haversineDistance($lat1, $lng1, $lat2, $lng2): float
    {
        $earthRadius = 6371000; // meters
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);

        $a = sin($dLat / 2) * sin($dLat / 2)
           + cos(deg2rad($lat1)) * cos(deg2rad($lat2))
           * sin($dLng / 2) * sin($dLng / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        return $earthRadius * $c;
    }

    // Send FCM push notification to caregiver
    private function notifyCaregiver(Patient $patient, float $lat, float $lng, float $distance): void
    {
        $caregiver = Caregiver::find($patient->caregiver_id);
        if (!$caregiver) return;

        $fcmToken = $caregiver->user->fcm_token ?? null;
        if (!$fcmToken) return;

        try {
            $credentials = FirebaseCredentials::path();
            if (!$credentials) {
                return;
            }

            $messaging = (new Factory)
                ->withServiceAccount($credentials)
                ->createMessaging();

            $message = CloudMessage::withTarget('token', $fcmToken)
                ->withNotification([
                    'title' => '🚨 Patient Left Safe Zone!',
                    'body'  => $patient->name . ' is ' . round($distance) . 'm away from home. Lat: ' . round($lat, 4) . ', Lng: ' . round($lng, 4),
                ])
                ->withData([
                    'type'       => 'gps_alert',
                    'patient_id' => (string) $patient->patient_id,
                    'latitude'   => (string) $lat,
                    'longitude'  => (string) $lng,
                    'distance'   => (string) round($distance),
                ]);

            $messaging->send($message);
        } catch (\Throwable $e) {
            \Log::error('GPS FCM alert error: ' . $e->getMessage());
        }
    }
}
