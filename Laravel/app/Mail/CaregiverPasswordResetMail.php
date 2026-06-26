<?php

namespace App\Mail;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class CaregiverPasswordResetMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public User $user,
        public string $token,
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Zakerni — Caregiver Password Reset',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.caregiver-reset-password',
            with: [
                'name'  => $this->user->name,
                'token' => $this->token,
                'email' => $this->user->email,
            ],
        );
    }
}
