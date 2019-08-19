<?php
require_once __DIR__ . '/../vendor/autoload.php';
// set_time_limit(0) or die("Falhou ao configurar time limit.");// 5 min
// ini_set('memory_limit', -1) or die("Falhou ao configurar memory limit");

use ValueObjects\DeterbTableStore;
use Services\PostgreSQLService;
/* 
$data = file_get_contents ("/home/dados/workspace-php5/deter-b-sync-data-client/rawData/all-DETERB.json");

echo "STRLEN=".strlen($data);

$json=json_decode($data, true, 2);
$data = null;
echo "|".$json;
echo "|";
print_r($json);
echo "|";
exit();
 */
$error = "";
if(!PostgreSQLService::createTable($error)) {
	echo $error;
}else {
	echo "continue...";
	/* if(!PostgreSQLService::pushData($data, $error)) {
		echo $error;
	} */
}

echo "\r\nfinish!!";

/*
$fp = fopen('the100-DETERB.sql', 'a');
fwrite($fp, $SQL);
fclose($fp);
*/

/*
function MyJSONPrint($data) {
	$fp = fopen('the100-DETERB.sql', 'a');
	foreach ($data as $key => $value) {
		if (!is_array($value)) {
			$str = $key . '=>' . $value . '\n';
			fwrite($fp, $str);
		} else {
			MyJSONPrint($data[$key]);
		}
	}
	fclose($fp);
	return;
}

if(isset($json)) {
	MyJSONPrint($json);
}
*/