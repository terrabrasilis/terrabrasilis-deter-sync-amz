<?php
/**
 * @filesource TestreadSateFromLogService.php
 * 
 * @abstract This test is a simulation of the service use to read the last state of the ingestion process.
 * 
 * @author André Carvalho
 * 
 * @version 2017.07.06
 */
require_once __DIR__ . '/../vendor/autoload.php';

error_reporting(E_ALL & ~E_NOTICE);

use Services\PostgreSQLLogService;
use Services\PostgreSQLDataService;
use DAO\GeneralLog;

$log = new GeneralLog();// to write more detailed log in file.
$pgLogService = new PostgreSQLLogService();
$pgDataService = new PostgreSQLDataService();

if(get_class($log)!=='DAO\\GeneralLog') {
	// disable logs in file
	$log=false;
}

if(get_class($pgLogService)!=='Services\\PostgreSQLLogService') {
	// Abort the process because we don't access the database server to write log.
	if($log) $log->writeErrorLog("Abort the process because we don't access the database server to write log.");
	exit();
}

if(get_class($pgDataService)!=='Services\\PostgreSQLDataService') {
	// Abort the process because we don't access the database server to write data.
	if($log) $log->writeErrorLog("Abort the process because we don't access the database server to write data.");
	exit();
}

$error = "";// Used to get the error description from PostgreSQLService methods calls.

$maxDate = $pgDataService->readMaxDate($error);
if(!$maxDate) {
	if($log) $log->writeErrorLog($error . "\nFailure on read the max date from data table.");
}else {
	print_r($maxDate);
}

$lastState = $pgLogService->readLastStateFromLogTable($error);
if(!$lastState) {
	if($log) $log->writeErrorLog($error . "\nFailure on read the last state from log table.");
}else {
	print_r($lastState);
}

echo "\r\nfinish!!";