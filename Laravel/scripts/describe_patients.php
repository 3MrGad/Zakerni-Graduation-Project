<?php
try{
    $pdo=new PDO('mysql:host=127.0.0.1;port=3306;dbname=alzheimers_system_part2','root','');
    $stmt=$pdo->query('DESCRIBE patients');
    $cols=$stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach($cols as $c){ echo $c['Field'].' '.$c['Type'].' '.$c['Key'].'\n'; }
}catch(Exception $e){ echo 'ERR:'.$e->getMessage().'\n'; }
