<?php
namespace DAO;

use LibCurl\LibCurl;
use Configuration\ServiceConfiguration;
use PDO;

/**
 * @abstract Allow to connect and run SQL scripts over PostgreSQL service using the PDO driver.
 * 
 * @since January of 2017
 * 
 * @author andre
 *
 */
class PostgreSQL {
	
	protected $conn = NULL;
	protected $logger = NULL;
	
	/**
	 * @abstract The default constructor makes a connection to database and create a logfile instance.
	 */
	function __construct() {

		$this->logger = new GeneralLog("postgres");
		
		$config = ServiceConfiguration::postgresql();
		if( empty ( $config ) ) {
			$this->logger->writeErrorLog("Missing default PostgreSQL configuration.");
		}else {
			if( $this->hasDriverPDOPostgreSQL() ) {
						//pgsql:host=localhost;port=5432;dbname=testdb;user=bruce;password=mypass
				$dsn = "pgsql:host=" . $config["host"] . ";port=" . $config["port"] . ";dbname=" .
						$config["dbname"] . ";user=" . $config["user"] . ";password=" . $config["pass"];
				
				try {
					$this->conn = new PDO($dsn);
					$this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
					// $this->conn->setAttribute(PDO::ATTR_EMULATE_PREPARES, true);
				} catch (\PDOException $e) {
					$this->writeErrorLog("The PDO driver return exception: " . $e->getMessage());
				} catch (Exception $e) {
					$this->writeErrorLog("Generic exception returned: " . $e->getMessage());
				}
				
			}else {
				$this->writeErrorLog("The PDO driver to PostgreSQL is not present.");
			}
		}
	}
	
	function __destruct() {
		$this->closeConnection();
		$this->logger->__destruct();
	}

	/**
	 * Write more detailed log info provided from PostgreSQL driver.
	 * @param string $msg, the message about the fail.
	 */
	private function writeErrorLog($msg="") {
		if(!empty($msg)) {
			$this->logger->writeErrorLog($msg);
		}
		if($this->conn && $this->conn->errorCode()) {
			$this->logger->writeErrorLog("ERROR_CODE:" . $this->conn->errorCode());
			$this->logger->writeErrorLog("ERROR_INFO:" . print_r($this->conn->errorInfo(),true));
		}
	}
	
	private function hasDriverPDOPostgreSQL() {
		
		$dr=PDO::getAvailableDrivers();
		
		if(in_array("pgsql", $dr, true) ){
			return true;
		}else {
			return false;
		}
	}
	
	public function begin() {
		if(!$this->conn->beginTransaction()) {
			$this->writeErrorLog("Fail to BEGIN transaction.");
			return false;
		}
		return true;
	}
	
	public function commit() {
		if($this->conn->commit()===false) {
			$this->writeErrorLog("Fail to COMMIT transaction.");
			return false;
		}
		return true;
	}
	
	public function rollback() {
		if($this->conn->rollBack()===false) {
			$this->writeErrorLog("Fail to ROLLBACK transaction.");
			return false;
		}
		return true;
	}
	
	public function isConnected() {
		return ($this->conn !== NULL );
	}
	
	public function closeConnection() {
		$this->conn = NULL;
	}
	
	/**
	 * Execute one query with select statement and return the result.
	 * @param string $query, The query to execute.
	 * @return returns a PDOStatement object, or false on failure.
	 */
	public function select($query) {
		$exec=false;
		
		if(empty($query)) {
			$this->logger->writeErrorLog("Missing query.");
			return false;
		}
		
		try {
			$exec=$this->conn->query($query);
		} catch (\PDOException $e) {
			$this->writeErrorLog("The PDO driver return exception: " . $e->getMessage());
		} catch (\Exception $e) {
			$this->writeErrorLog("Fail on execute SELECT query. Exception returned: " . $e->getMessage());
		}
		
		if($exec!==false) {
			return $exec;
		}else {
			$this->writeErrorLog("Fail on execute SELECT query.");
			return false;
		}
	}
	
	/**
	 * Execute a set of the query statements. 
	 * 
	 * @param string $query, the query script to execute.
	 * @param integer $affectedRows, affected lines expected. (DISABLED)
	 * @return boolean, true on success or false otherwise.
	 */
	public function execQueryScript($query){ //, $affectedRows) {
		$exec=false;
		
		try {
			if(empty($query)) {
				$this->writeErrorLog("Query script is empty.");
				return false;
			}
			
			$exec=$this->conn->exec($query);
			
		} catch (\PDOException $e) {
			$this->writeErrorLog("The PDO driver return exception: " . $e->getMessage());
			return false;
		} catch (\Exception $e) {
			$this->writeErrorLog("General failure. See exception returned: " . $e->getMessage());
			return false;
		}
		
		if($exec===false) {
			$this->writeErrorLog("Fail on execute script.");
			return false;
		}
		
		return true;
	}

}