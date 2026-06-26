<?php

namespace App\Support;

class FirebaseCredentials
{
    public static function path(): ?string
    {
        $project = config('firebase.default', 'app');

        return config("firebase.projects.{$project}.credentials")
            ?: env('FIREBASE_CREDENTIALS')
            ?: env('GOOGLE_APPLICATION_CREDENTIALS');
    }
}
