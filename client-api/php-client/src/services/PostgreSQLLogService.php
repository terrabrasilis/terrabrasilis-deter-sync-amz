<?php
namespace Services;

use DAO\PostgreSQL;
use ValueObjects\LogTable;
use Configuration\ServiceConfiguration;

/**
 *
 * @abstract Provide up level methods to maintain log into PostgreSQL log table.
 *          
 * @since May of 2017
 *       
 * @author andre
 *        
 */
class PostgreSQLLogService extends PostgreSQLService {

	/**
	 * Verify if log table exists and create then if not.
	 *
	 * @param string $error, allow read the error message.
	 * @return boolean, true on success or false otherwise.
	 */
	public function createLogTable(&$error) {
		$config = ServiceConfiguration::defines();
		
		if( empty ( $config ) ) {
			$error = "Missing the metadata tables configuration.";
			return false;
		}
		
		$tableName = $config["SCHEMA"].".".$config["LOG_TABLE"];
		return $this->createTable($tableName, LogTable::getSQLToCreateTableStore(), $error);
	}

	/**
	 * Write log on table log.
	 * @param integer $state, 0 on error and 1 on success.
	 * @param string $detail, The description about error. 
	 * @param string $rawFile, The name of the file raw data, but if error is in data download, this can be empty.
	 * @return boolean, true on success or false otherwise.
	 */
	public function writeLog($state, $detail, $rawFile) {
		$error = "";
				
		if( ($state!==0 && $state!==1) || empty($detail)) {
			$error = "Input data is missing.";
			$this->writeErrorLog($error);
			return false;
		}
		
		if(!$this->pg) {
			$error = "No database connect.";
			$this->writeErrorLog($error);
			return false;
		}
		
		if(!$this->start()) {
			$error = "Begin command has failed.";
			$this->writeErrorLog($error);
			return false;
		}
		if(!$this->createLogTable($error)) {
			$error .= "\nCreate the log table was failed.";
			if($this->stop(false)){// rollback
				$error .= "\nRollback command has failed.";
			}
			$this->writeErrorLog($error);
			return false;
		}
		
		$log = new LogTable();
		$log->setValues(array("state"=>$state, "detail"=>$detail, "rawFile"=>$rawFile));
		$sql=$log->toSQLInsert();
		
		if(!$this->pg->execQueryScript($sql)) {
			$error .= "\nInsert log on table was failed.";
			if($this->stop(false)){// rollback
				$error .= "\nRollback command has failed.";
			}
			$this->writeErrorLog($error);
			return false;
		}
		if($this->stop(true)){// commit
			$error .= "\nCommit command has failed.";
			$this->writeErrorLog($error);
			return false;
		}
		return true;
	}
	
	/**
	 * Read the last state from log table.
	 *
	 * @param string $error, allow read the error message.
	 * @return boolean, true on success or false otherwise.
	 */
	public function readLastStateFromLogTable(&$error) {
		$config = ServiceConfiguration::defines();
	
		if( empty ( $config ) ) {
			$error = "Missing the metadata tables configuration.";
			return false;
		}
		
		$log = new LogTable();
		$sql=$log->getSQLToReadLastStatus();
	
		$tableName = $config["SCHEMA"].".".$config["LOG_TABLE"];
		return $this->execSQL($tableName, $sql, $error);
	}
}