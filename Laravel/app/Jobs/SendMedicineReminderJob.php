<?php
namespace App\Jobs;

use App\Models\MedicationLog;
use App\Models\MedicationSchedule;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use App\Support\FirebaseCredentials;
use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;

class SendMedicineReminderJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public MedicationSchedule $schedule) {}

    public function handle(): void
    {
        if (!$this->schedule->is_active) return;

        $scheduledAt = now()->setTimeFromTimeString($this->schedule->scheduled_time);

        // Avoid duplicate logs for same schedule+day
        $exists = MedicationLog::where('schedule_id', $this->schedule->schedule_id)
            ->whereDate('scheduled_at', today())->exists();
        if ($exists) return;

        $log = MedicationLog::create([
            'schedule_id'  => $this->schedule->schedule_id,
            'patient_id'   => $this->schedule->patient_id,
            'scheduled_at' => $scheduledAt,
            'status'       => 'pending',
        ]);

        // Push to patient
        $fcmToken = $this->schedule->patient->user->fcm_token;
        if ($fcmToken) {
            $this->sendPush(
                $fcmToken,
                'Medicine Reminder',
                'Time to take: ' . $this->schedule->medication->med_name .
                ' (' . $this->schedule->medication->dosage . ')'
            );
        }

        // Dispatch caregiver alert after grace period
        AlertCaregiverJob::dispatch($log->log_id)
            ->delay(now()->addMinutes(60));
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
            \Log::error('FCM error: ' . $e->getMessage());
        }
    }
}