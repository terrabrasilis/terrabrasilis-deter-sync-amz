<?php

namespace ValueObjects;

use ValueObjects\Geometry;
use Configuration\ServiceConfiguration;

/**
 * Used to represent one tuple in DETERB table.
 * The goal is transform a JSON object into SQL script.
 * 
 * The table have this attributes:
 * 
 *   gid bigint NOT NULL,
 *   fake_point geometry,
 *   classname character varying(254),
 *   areatotalkm numeric,
 *   areamunkm double precision,
 *   areauckm double precision,
 *   data date,
 *   uf character varying(2),
 *   county text,
 *   uc character varying,
 *   satelite character varying(13),
 *   sensor character varying(10),
 *   lote character varying(254),
 *   orbiponto character varying(10),
 *   quadrante character varying(5),
 *   geometries geometry,
 * 
 * May of 2017
 *
 * @author andre
 *
 */
class DeterbTupleStore {

	private $gid,$classname,$areatotalkm,$areamunkm,$areauckm,$date,$uf,$county,$uc,$satellite,$sensor,$lot,$orbitpoint,$quadrant,$geometry;
	
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
			$record=$jsonResponse;
			$this->gid = $record["gid"];
			$this->classname = $record["classname"];
			$this->areatotalkm = $record["areatotalkm"];
			$this->areamunkm = $record["areamunkm"];
			$this->areauckm = $record["areauckm"];
			$this->date = $record["date"];
			$this->uf = $record["uf"];
			$this->county = $record["county"];
			$this->uc = $record["uc"];
			$this->satellite = $record["satellite"];
			$this->sensor = $record["sensor"];
			$this->lot = $record["lot"];
			$this->orbitpoint = $record["orbitpoint"];
			$this->quadrant = $record["quadrant"];
			$this->geometry = new Geometry($record["geometries"]);
		}
	}
	
	public function toSQLInsert() {
		$conf = ServiceConfiguration::defines();
		$sql = "INSERT INTO public.".$conf["DATA_TABLE"]."(".
	           		"gid, classname, areatotalkm, areamunkm, areauckm, ".
	           		"date, uf, county, uc, satellite, sensor, lot, orbitpoint, quadrant, ".
	           		"geom) ".
				"VALUES (".
						$this->gid.",".
						"'".$this->classname."',".
						$this->areatotalkm.",".
						$this->areamunkm.",".
						$this->areauckm.",".
						"'".$this->date."',".// TODO: adjust the dtae format to works fine on postgresql
						"'".$this->uf."',".
						"'".$this->county."',".
						"'".$this->uc."',".
						"'".$this->satellite."',".
						"'".$this->sensor."',".
						"'".$this->lot."',".
						"'".$this->orbitpoint."',".
						"'".$this->quadrant."',".
						$this->geometry->toPostgisSQLFragment().
						")";
		
		return $sql;
	}

	public function toSQLUpdate() {
		$conf = ServiceConfiguration::defines();
		$sql = "UPDATE public.".$conf["DATA_TABLE"]." SET ".
				"gid, classname, areatotalkm, areamunkm, areauckm, ".
				"date, uf, county, uc, satellite, sensor, lot, orbitpoint, quadrant, ".
				"geom) ".
				"classname='".$this->classname."',".
				"areatotalkm=".$this->areatotalkm.",".
				"areamunkm=".$this->areamunkm.",".
				"areauckm=".$this->areauckm.",".
				"date='".$this->date."',".// TODO: adjust the dtae format to works fine on postgresql
				"uf='".$this->uf."',".
				"county='".$this->county."',".
				"uc='".$this->uc."',".
				"satellite='".$this->satellite."',".
				"sensor='".$this->sensor."',".
				"lot='".$this->lot."',".
				"orbitpoint='".$this->orbitpoint."',".
				"quadrant='".$this->quadrant."',".
				"geom=".$this->geometry->toPostgisSQLFragment()." ".
				"WHERE gid=".$this->gid;
	
		return $sql;
	}
	
	public function toSQLDelete() {
		$conf = ServiceConfiguration::defines();
		$sql = "DELETE FROM public.".$conf["DATA_TABLE"]." ".
				"WHERE gid=".$this->gid;
	
		return $sql;
	}
	
}