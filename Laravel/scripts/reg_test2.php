<?php
$url = 'http://127.0.0.1:8000/api/register/patient';
$data = [
    'Fname' => 'Test'.time(),
    'Lname' => 'User',
    'Email' => 'test'.time().'@example.com',
    'password' => 'secret123',
    'password_confirmation' => 'secret123'
];
$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
$response = curl_exec($ch);
$info = curl_getinfo($ch);
if(curl_errno($ch)){
    $err = curl_error($ch);
} else {
    $err = null;
}
curl_close($ch);
$out = "RESPONSE:\n".print_r($info, true)."\nBODY:\n".$response."\nERROR:\n".$err;
file_put_contents('storage/logs/reg_test_output.txt', $out);
echo "WROTE storage/logs/reg_test_output.txt\n";
