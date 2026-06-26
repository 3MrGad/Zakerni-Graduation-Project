<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponses;
use App\Http\Controllers\Controller;
use App\Http\Requests\ForgotPasswordRequest;
use App\Http\Requests\ResetPasswordRequest;
use App\Mail\CaregiverPasswordResetMail;
use App\Mail\PatientPasswordResetMail;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Password;

class PasswordResetController extends Controller
{
    use ApiResponses;

    public function caregiverForgot(ForgotPasswordRequest $request)
    {
        return $this->sendResetLink($request->validated()['email'], 'caregiver');
    }

    public function patientForgot(ForgotPasswordRequest $request)
    {
        return $this->sendResetLink($request->validated()['email'], 'patient');
    }

    public function caregiverReset(ResetPasswordRequest $request)
    {
        return $this->resetPassword($request->validated(), 'caregiver');
    }

    public function patientReset(ResetPasswordRequest $request)
    {
        return $this->resetPassword($request->validated(), 'patient');
    }

    private function sendResetLink(string $email, string $role)
    {
        $user = User::where('email', $email)->where('role', $role)->first();

        if (!$user) {
            return $this->success(null, 'If that email exists, a reset link has been sent.');
        }

        $token = Password::broker()->createToken($user);

        $mailable = $role === 'caregiver'
            ? new CaregiverPasswordResetMail($user, $token)
            : new PatientPasswordResetMail($user, $token);

        Mail::to($user->email)->send($mailable);

        return $this->success(null, 'Password reset link sent to your email.');
    }

    private function resetPassword(array $data, string $role)
    {
        $user = User::where('email', $data['email'])->where('role', $role)->first();

        if (!$user) {
            return $this->error('Invalid reset request.', 422);
        }

        $status = Password::broker()->reset(
            [
                'email'    => $data['email'],
                'password' => $data['password'],
                'token'    => $data['token'],
            ],
            function (User $u, string $password) {
                $u->forceFill(['password' => Hash::make($password)])->save();
            }
        );

        if ($status !== Password::PASSWORD_RESET) {
            return $this->error(__($status), 422);
        }

        return $this->success(null, 'Password has been reset successfully.');
    }
}
