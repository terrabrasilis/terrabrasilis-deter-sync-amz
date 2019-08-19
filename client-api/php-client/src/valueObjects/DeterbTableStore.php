<?php

namespace ValueObjects;

use ValueObjects\DeterbTupleStore;
use Configuration\ServiceConfiguration;

/**
 * Used to represent one package data to apply in DETERB table.
 * The package is a set of DeterbTupleStore.
 * 
 * It is compounds of 3 sets of tuples, insert, update and delete in SQL format.
 * 
 * May of 2017
 *
 * @author andre
 *
 */
class DeterbTableStore {

	private $insertTuples, $updateTuples, $deleteTuples;
	
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
	
	function __construct($jsonResponse=null) {
		if(isset($jsonResponse)) {
			$json = json_decode($jsonResponse, true);
			if(!is_null($json)) {
				$this->insertTuples = ( isset($json["inserts"])?($json["inserts"]):(null) );
				$this->updateTuples = ( isset($json["updates"])?($json["updates"]):(null) );
				$this->deleteTuples = ( isset($json["deletes"])?($json["deletes"]):(null) );
			}
		}
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
		$config["SCHEMA"] . "." . $config["DATA_TABLE"] .
		" ( ".
		"gid serial NOT NULL, ".
		"classname character varying(254), ".
		"quadrant character varying(5), ".
		"orbitpoint character varying(10), ".
		"date date, ".
		"date_audit date, ".
		"lot character varying(254), ".
		"sensor character varying(10), ".
		"satellite character varying(13), ".
		"areatotalkm double precision, ".
		"areamunkm double precision, ".
		"areauckm double precision, ".
		"county character varying(254), ".
		"uf character varying(2), ".
		"uc character varying(254), ".
		"geom geometry, ".
		"origin_gid integer, ".
		"CONSTRAINT " . $config["DATA_TABLE"] . "_pk PRIMARY KEY (gid) ".
		") ".
		"WITH ( ".
		"OIDS=FALSE ".
		"); ".
		"ALTER TABLE ".
		$config["SCHEMA"] . "." . $config["DATA_TABLE"] .
		" OWNER TO ".$postgres["user"]."; ".
		"CREATE INDEX " . $config["DATA_TABLE"] . "_geom_index ".
		"ON ".
		$config["SCHEMA"] . "." . $config["DATA_TABLE"] .
		" USING gist ".
		"(geom);";
		
		return $sql;
	}
	
	/**
	 * Makes a SQL script to insert rows on table.
	 * @param integer $numRows, allow read the number of rows that will be inserted.
	 * @return <boolean, string>, The SQL script to insert rows or false otherwise.
	 */
	public function toSQLInsert(&$numRows) {
		$sql=false;
		$numRows=0;
		$index=count($this->insertTuples);
		if(is_array($this->insertTuples) && $index>0) {
			for ($i = 0; $i < $index; $i++) {
				$numRows++;
				$tuple = new DeterbTupleStore($this->insertTuples[$i]);
				$sql .= $tuple->toSQLInsert() . ";";
			}
		}
		return $sql;
	}
	
	/**
	 * Makes a SQL script to update rows from table.
	 * @param integer $numRows, allow read the number of rows that will be updated.
	 * @return <boolean, string>, The SQL script to update rows or false otherwise.
	 */
	public function toSQLUpdate(&$numRows) {
		$sql=false;
		$numRows=0;
		if(isset($this->updateTuples) && $this->updateTuples->length) {
			$index = $this->updateTuples->length;
			for ($i = 0; $i < $index; $i++) {
				$numRows++;
				$tuple = new DeterbTupleStore($this->updateTuples[$i]);
				$sql .= $tuple->toSQLUpdate() . ";";
			}
		}
		return $sql;
	}
	
	/**
	 * Makes a SQL script to delete rows from table.
	 * @param integer $numRows, allow read the number of ids that will be removed.
	 * @return <boolean, string>, The SQL script to delete rows or false otherwise.
	 */
	public function toSQLDelete(&$numRows) {
		$sql=false;
		$numRows=0;
		if(isset($this->deleteTuples) && $this->deleteTuples->length) {
			$index = $this->deleteTuples->length;
			for ($i = 0; $i < $index; $i++) {
				$numRows++;
				$tuple = new DeterbTupleStore($this->deleteTuples[$i]);
				$sql .= $tuple->toSQLDelete() . ";";
			}
		}
		return $sql;
	}
	
	/**
	 * Makes a SQL script to read the next day of the max auditing date from table.
	 * @return <boolean, string>, The SQL script to read value or false otherwise.
	 */
	public static function getSQL2ReadMaxAuditDateFromData() {
		$config = ServiceConfiguration::defines();
		$sql="";

		$sql="SELECT MAX(date_audit) + 1 FROM " .
			$config["SCHEMA"] . "." . $config["DATA_TABLE"] . " WHERE date_audit is not null";
		
		return $sql;
	}

	/**
	 * Makes a SQL script to read max image date from table.
	 * @return <boolean, string>, The SQL script to read value or false otherwise.
	 */
	public static function getSQL2ReadMaxDateFromData() {
		$config = ServiceConfiguration::defines();
		$sql="";

		$sql="SELECT MAX(date) FROM " .
			$config["SCHEMA"] . "." . $config["DATA_TABLE"] . " WHERE date_audit is not null";
		
		return $sql;
	}
}
