<?php
/**
 * @filesource TestAllGeometriesFromScript.php
 * 
 * @abstract This test is a simulation of the use service to load one script with all data from remote database table and write this data over local database table.
 * 
 * @author André Carvalho
 * 
 * @version 2017.05.12
 */
require_once __DIR__ . '/../vendor/autoload.php';

error_reporting(E_ALL & ~E_NOTICE);

use Services\PostgreSQLDataService;
use Services\PostgreSQLLogService;
use Services\HTTPSyncService;
use DAO\GeneralLog;

$log = new GeneralLog();// to write more detailed log in file.
$pgDataService = new PostgreSQLDataService();
$pgLogService = new PostgreSQLLogService();

if(get_class($log)!=='DAO\\GeneralLog') {
	// disable logs in file
	$log=false;
}

if(get_class($pgDataService)!=='Services\\PostgreSQLDataService') {
	// Abort the process because we don't access the database server to write data.
	if($log) $log->writeErrorLog("Abort the process because we don't access the database server to write data.");
	exit();
}

if(get_class($pgLogService)!=='Services\\PostgreSQLLogService') {
	// Abort the process because we don't access the database server to write log.
	if($log) $log->writeErrorLog("Abort the process because we don't access the database server to write log.");
	exit();
}

$error = "";// Used to get the error description from PostgreSQLService methods calls.

$RAWFILE = "/home/dados/workspace-php5/deter-b-sync-data-client/rawData/17-05-2017_all_data.sql";// The directory path and filename to write the raw data during download.

//$syncService = new HTTPSyncService();
//$RAWFILE = $syncService->downloadAllGeometries();

if($RAWFILE===false) {
	$error = "Failure on download data.";
	if($log) $log->writeErrorLog($error);
	if(!$pgLogService->writeLog(0, $error, $RAWFILE)) {
		if($log) $log->writeErrorLog("Failure on write the error on log table.");
	}
	exit();
}

// Load all data from file to memory
$data = file_get_contents( $RAWFILE );

if($data===false) {
	$error = "Fail to load all data from file to memory.";
	if(!$pgLogService->writeLog(0, $error, $RAWFILE)) {
		if($log) $log->writeErrorLog($error . "\nFailure on write the error on log table.");
	}
	exit();
}

if(!$pgDataService->renewDataTable($data, $error)) {
	if(!$pgLogService->writeLog(0, $error, $RAWFILE)) {
		if($log) $log->writeErrorLog($error . "\nFailure on write the error on log table.");
	}
	exit();
}

$pgLogService->writeLog(1, "Success", $RAWFILE);
echo "\r\nfinish!!";