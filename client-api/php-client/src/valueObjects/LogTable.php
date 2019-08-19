<?php
/**
 * @filesource LogTable.php
 * 
 * @abstract Provides the table model to store the sync history infos.
 * 
 * @author Andre Carvalho
 * @version 15.05.2017
 */
namespace ValueObjects;

use Configuration\ServiceConfiguration;
use DateTime;
use DateTimeZone;

/**
 * Used to register the informations about the sync process over DETERB service.
 */
class LogTable {

	private $date,// The run date
			$state,// The final state of process {1==sucess or 0==fail}
			$detail,// Details over process that was run
			$rawFile;// The raw file name read from service

	public function __get($property) {
		if (property_exists($this, $property)) {
			return $this->$property;
		}
	}

	public function __set($property, $value) {
		if (property_exists($this, $property)) {
			$this->$property = $value;
		}

		return $this;
	}

	function __construct() {
		$dt = new DateTime();
		$dt->setTimeZone(new DateTimeZone('America/Sao_Paulo'));
		$this->date = $dt->format('Y-m-d H:i:s');
		$this->state=0;
		$this->detail="";
		$this->rawFile="";
	}
	
	/**
	 * Set infos to write log in table
	 * @param array $param, An array with 3 indices/values: ["state"]=valToState, ["detail"]=valToDetail and ["rawFile"]=valToRawFile
	 */
	public function setValues($param) {
		$this->state=$param["state"];
		$this->detail=$param["detail"];
		$this->rawFile=$param["rawFile"];
	}

	/**
	 * Makes the SQL script to create the table.
	 * @return string, The SQL script to create table on database.
	 */
	public static function getSQLToCreateTableStore() {
		$config = ServiceConfiguration::defines();
		$postgres = ServiceConfiguration::postgresql();
		$sql="";
		$sql="CREATE TABLE " .
				$config["SCHEMA"] . "." . $config["LOG_TABLE"] .
				" ( ".
				"log_id serial NOT NULL, ".
				"state integer, ".
				"detail text, ".
				"raw_file character varying(255), ".
				"date date, ".
				"CONSTRAINT " . $config["LOG_TABLE"] . "_pk PRIMARY KEY (log_id) ".
				") ".
				"WITH ( ".
				"OIDS=FALSE ".
				"); ".
				"ALTER TABLE ".
				$config["SCHEMA"] . "." . $config["LOG_TABLE"] .
				" OWNER TO ".$postgres["user"].";";

		return $sql;
	}
	
	/**
	 * Makes the SQL script for read the last state using a filter by max date.
	 * @return string, The SQL script to read one value from log table.
	 */
	public static function getSQLToReadLastStatus() {
		$config = ServiceConfiguration::defines();
		$sql="";
		$sql =	"SELECT t2.state, t2.detail, t2.date FROM ( " .
				"SELECT max(date) as date FROM ".
				$config["SCHEMA"] . "." . $config["LOG_TABLE"] . " ) as t1, " .
				$config["SCHEMA"] . "." . $config["LOG_TABLE"] . " as t2 " .
				"WHERE t2.date=t1.date ";
		return $sql;
	}

	/**
	 * Makes a SQL script to insert row on table.
	 * @return boolean or string, The SQL script to insert row or false otherwise.
	 */
	public function toSQLInsert() {
		$sql=false;
		if(isset($this->detail) && isset($this->state) && isset($this->rawFile) ) {
			$config = ServiceConfiguration::defines();
			$sql = "INSERT INTO " . $config["SCHEMA"] . "." . $config["LOG_TABLE"] . "(state,detail,raw_file,date) ".
			"VALUES(".$this->state.",'".$this->detail."','".$this->rawFile."','".$this->date."');";
		}
		return $sql;
	}

}