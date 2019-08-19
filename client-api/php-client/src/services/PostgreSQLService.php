<?php
namespace Services;

use DAO\PostgreSQL;
use DAO\GeneralLog;
use Configuration\ServiceConfiguration;

/**
 *
 * @abstract Provide up level methods to maintain data into PostgreSQL table.
 *          
 * @since May of 2017
 *       
 * @author andre
 *        
 */
class PostgreSQLService {
	
	protected $pg, $log;
	
	function __construct() {
		$this->pg = new PostgreSQL();
		if(!$this->pg->isConnected()) {
			$this->pg = null;
		}
		$this->log = new GeneralLog("pg_service");
	}
	
	function __destruct() {
		if($this->pg) {
			$this->pg->closeConnection();
		}
		$this->log->__destruct();
	}
	
	/**
	 * Write log info about pg service.
	 * @param string $msg, the message about the fail.
	 */
	protected function writeErrorLog($msg="") {
		if(!empty($msg)) {
			$this->log->writeErrorLog($msg);
		}
	}
	
	/**
	 * Start process
	 * @return boolean, true in success or false otherwise.
	 */
	protected function start() {
		return $this->pg->begin();
	}
	
	/**
	 * Finish process
	 * @param boolean $status, true to commit or false to rollback
	 * @return boolean, true in success or false otherwise.
	 */
	protected function stop($status) {
		if($status) {
			return $this->pg->commit();
		}else{
			return $this->pg->rollback();
		}
		//return ( ($status)?($this->pg->commit()):($this->pg->rollback()) );
	}
	
	/**
	 * Execute one query over database and read the result.
	 *
	 * @param string $tableName, the name of table to use in query string for test if it exists.
	 * @param string $sql, the query to execute.
	 * @param string $error, allow read the error message.
	 * 
	 * @return array|false, The result in array format or false otherwise. 
	 */
	protected function execSQL($tableName, $sql, &$error) {
		if(!$this->pg) {
			$error = "No database connect.";
			return false;
		}
		
		if( !$this->tableExists($tableName, $error) ) {
			$error = "Log table doesn't exist.";
			return false;
		}

		$statement = $this->pg->select($sql);
		if($statement!==false && get_class($statement) === "PDOStatement") {
			$result = $statement->fetchAll();
			return $result;
		}
		return false;
	}
	
	/**
	 * Test if one table exists.
	 * 
	 * @param string $error, allow read the error message.
	 * @param string $tableName, the name of one table.
	 */
	protected function tableExists($tableName, &$error) {
		if(!$this->pg) {
			$error = "No database connect.";
			return false;
		}
		
		$query = "SELECT EXISTS (SELECT 1 FROM (SELECT table_schema || '.' || table_name as col FROM information_schema.tables) as tb WHERE tb.col = '".$tableName."');";
		$tableExists = $this->pg->select($query);
		if(get_class($tableExists) === "PDOStatement") {
			$result = $tableExists->fetchAll();
			return $result[0]['exists'];
		}
		return false;
	}
	
	/**
	 * Verify if table exists and create then if not.
	 *
	 * @param string $tableName, the name of one table.
	 * @param string $sql, the query to create one table.
	 * @param string $error, allow read the error message.
	 * @return boolean, true on success or false otherwise.
	 */
	protected function createTable($tableName, $sql, &$error) {
		if(!$this->pg) {
			$error = "No database connect.";
			return false;
		}
		
		if( !$this->tableExists($tableName, $error) ) {
			// table doesn't exist. Create then.
			
			if(!$this->pg->execQueryScript($sql)) {
				$error = "Do not was created database table: (".$tableName.")";
				return false;
			}
		}
		return true;
	}

	/**
	 * Drop one table from database.
	 *
	 * @param string $tableName, the name of one table.
	 * @param string $sql, the query to remove one table.
	 * @param string $error, allow read the error message.
	 * @return boolean, true on success or false otherwise.
	 */
	protected function dropTable($tableName, $sql, &$error) {
		if(!$this->pg) {
			$error = "No database connect.";
			return false;
		}
	
		if( $this->tableExists($tableName, $error) ) {
			// Table exists, so remove it.
			$exec = $this->pg->execQueryScript($sql);
			if( $exec===false ) {
				$error = "Failure on DROP database table (".$tableName.").";
				return false;
			}
		}
		return true;
	}
	
	/**
	 * Exec query without response result.
	 *
	 * @param string $tableName, the name of one table.
	 * @param string $sql, the query.
	 * @param string $error, allow read the error message.
	 * @return boolean, true on success or false otherwise.
	 */
	protected function execQueryNoResult($tableName, $sql, &$error) {
		if(!$this->pg) {
			$error = "No database connect.";
			return false;
		}
	
		if( $this->tableExists($tableName, $error) ) {
			// Table exists, so remove it.
			$exec = $this->pg->execQueryScript($sql);
			if( $exec===false ) {
				$error = "Failure on exec query over table (".$tableName.").";
				return false;
			}
		}
		return true;
	}
}