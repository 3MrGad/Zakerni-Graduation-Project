<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; background: #FFF8F0; padding: 24px; }
        .card { max-width: 520px; margin: 0 auto; background: #fff; border-radius: 12px; padding: 28px; border: 1px solid #E8A87C55; }
        h1 { color: #E8A87C; font-size: 22px; }
        .token { background: #FFF3E6; padding: 12px; border-radius: 8px; font-family: monospace; word-break: break-all; }
        .footer { color: #888; font-size: 12px; margin-top: 24px; }
    </style>
</head>
<body>
    <div class="card">
        <h1>Patient password reset</h1>
        <p>Hello {{ $name }},</p>
        <p>You requested a password reset for your Zakerni patient account. Use the token below in the app’s reset screen.</p>
        <p><strong>Reset token:</strong></p>
        <p class="token">{{ $token }}</p>
        <p>Account email: <strong>{{ $email }}</strong></p>
        <p class="footer">If you did not request this, you can ignore this email. This token expires in 60 minutes.</p>
    </div>
</body>
</html>
