<?php
/**
 * @filesource index.php
 * 
 * @abstract It is used to load one script with all data from remote database table and write this data over local database table.
 * 
 * @author André Carvalho
 * 
 * @version 2017.05.15
 */

require_once __DIR__ . '/vendor/autoload.php';
date_default_timezone_set('America/Sao_Paulo');
ini_set('memory_limit','-1');
error_reporting(E_ALL & ~E_NOTICE);

use Services\PostgreSQLDataService;
use Services\PostgreSQLLogService;
use Services\HTTPSyncService;
use DAO\GeneralLog;

$log = new GeneralLog();// to write more detailed log in file.
$pgDataService = new PostgreSQLDataService();
$pgLogService = new PostgreSQLLogService();

/*
A text file to store the last PRODES reference date read in the configuration table.
It is used if the reading fails in the configuration table.
*/
$fileWithLastValidDate=__DIR__."/rawData/lastprodesdate";

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

$RAWFILE = "";// The directory path and filename to write the raw data during download.

// Read the end_date of the PRODES reference date from config table
// Used to renew all data into current table
$last_date = $pgDataService->readLastProdesDate($error);

if($last_date===false || count($last_date)!=1) {
	// table not found or database is off
	if($log) $log->writeErrorLog($error);
	// reading the file because the database failed
	$last_date = file_get_contents($fileWithLastValidDate);
}else{
	$last_date = $last_date[0][0];
	// writing to the file for use when loading is failed
	file_put_contents($fileWithLastValidDate, $last_date);
}

$syncService = new HTTPSyncService();
$RAWFILE = $syncService->downloadLastGeometries($last_date);

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

// if(!$pgDataService->appendNewData($data, $error)) {
// 	if(!$pgLogService->writeLog(0, $error, $RAWFILE)) {
// 		if($log) $log->writeErrorLog($error . "\nFailure on write the error on log table.");
// 	}
// 	exit();
// }

$pgLogService->writeLog(1, "Success", $RAWFILE);