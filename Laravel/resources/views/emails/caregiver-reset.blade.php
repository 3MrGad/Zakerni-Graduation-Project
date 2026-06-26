<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; background: #f0faf8; padding: 24px; }
        .card { max-width: 520px; margin: 0 auto; background: #fff; border-radius: 12px; padding: 28px; border: 1px solid #1A7A6E33; }
        h1 { color: #1A7A6E; font-size: 22px; }
        .token { background: #E8F5F3; padding: 12px; border-radius: 8px; font-family: monospace; word-break: break-all; }
        .footer { color: #888; font-size: 12px; margin-top: 24px; }
    </style>
</head>
<body>
    <div class="card">
        <h1>Caregiver password reset</h1>
        <p>Hello {{ $name }},</p>
        <p>You requested a password reset for your Zakerni caregiver account. Use the token below in the app’s reset screen, or reset via your configured frontend URL.</p>
        <p><strong>Reset token:</strong></p>
        <p class="token">{{ $token }}</p>
        <p>Account email: <strong>{{ $email }}</strong></p>
        <p class="footer">If you did not request this, you can ignore this email. This token expires in 60 minutes.</p>
    </div>
</body>
</html>
