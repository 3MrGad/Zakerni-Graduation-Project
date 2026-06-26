<?php
try{
    $pdo=new PDO('mysql:host=127.0.0.1;port=3306;','root','');
    $stmt=$pdo->query('SHOW DATABASES');
    $dbs=$stmt->fetchAll(PDO::FETCH_COLUMN);
    echo "DATABASES:\n".implode("\n",$dbs)."\n";
    if(in_array('alzheimers_system_part2',$dbs)){
        echo "FOUND DB alzheimers_system_part2\n";
        $pdo->query('use alzheimers_system_part2');
        $stmt=$pdo->query('SHOW TABLES');
        $tables=$stmt->fetchAll(PDO::FETCH_COLUMN);
        echo "TABLES:\n".implode("\n",$tables)."\n";
    } else {
        echo "DB NOT FOUND\n";
    }
}catch(Exception $e){
    echo 'ERR:'.$e->getMessage()."\n";
}
