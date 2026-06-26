<?php
namespace App\Jobs;

use App\Models\MedicationLog;
use App\Models\Patient;
use App\Models\Caregiver;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use App\Support\FirebaseCredentials;
use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;

class AlertCaregiverJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public int $logId) {}

    public function handle(): void
    {
        $log = MedicationLog::find($this->logId);

        // If patient already took it, do nothing
        if (!$log || $log->status !== 'pending') return;

        $log->update(['status' => 'missed']);

        $patient   = Patient::find($log->patient_id);
        $caregiver = Caregiver::find($patient->caregiver_id);

        if (!$caregiver) return;

        $fcmToken = $caregiver->user->fcm_token ?? null;
        if (!$fcmToken) return;

        $this->sendPush(
            $fcmToken,
            'Missed Medicine Alert',
            $patient->name . ' did not take ' .
            $log->schedule->medication->med_name . ' on time.'
        );
    }

    private function sendPush(string $token, string $title, string $body): void
    {
        try {
            $credentials = FirebaseCredentials::path();
            if (!$credentials) {
                return;
            }

            $messaging = (new Factory)
                ->withServiceAccount($credentials)
                ->createMessaging();

            $message = CloudMessage::withTarget('token', $token)
                ->withNotification(['title' => $title, 'body' => $body]);

            $messaging->send($message);
        } catch (\Throwable $e) {
            \Log::error('FCM caregiver alert error: ' . $e->getMessage());
        }
    }
}