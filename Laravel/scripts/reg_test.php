<?php
// Simple HTTP POST to Laravel API register endpoint
$url = 'http://127.0.0.1:8000/api/register/patient';
$data = [
    'Fname' => 'Test'.time(),
    'Lname' => 'User',
    'Email' => 'test'.time().'@example.com',
    'password' => 'secret123',
    'password_confirmation' => 'secret123'
];
$options = [
    'http' => [
        'header'  => "Content-type: application/json\r\n",
        'method'  => 'POST',
        'content' => json_encode($data),
        'ignore_errors' => true,
    ],
];
$context  = stream_context_create($options);
$result = file_get_contents($url, false, $context);
echo "HTTP response:\n" . $result . "\n";
foreach ($http_response_header as $h) {
    echo $h . "\n";
}
