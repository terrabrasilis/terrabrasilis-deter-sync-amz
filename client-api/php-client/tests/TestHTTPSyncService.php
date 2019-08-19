<?php
/**
 * @filesource TestHTTPSyncService.php
 * 
 * @abstract This test is a simulation of the use service to load one script with all data from remote database table and write this data over local database table.
 * 
 * @author André Carvalho
 * 
 * @version 2017.05.12
 */

require_once __DIR__ . '/../vendor/autoload.php';

use Services\HTTPSyncService;

$service = new HTTPSyncService();

$fileData = $service->downloadAllGeometries();

if($fileData===false) {
	echo "Failure on download data.";
}else {
	echo "file size:".filesize($fileData)."\n";
	echo $fileData;
}