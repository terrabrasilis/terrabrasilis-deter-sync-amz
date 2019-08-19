<?php

namespace ValueObjects;

use Configuration\ServiceConfiguration;

/**
 * Used to represents the polygons of one registry of the DETER-B detections.
 *
 * Uses the GeoJSON pattern.
 * - https://tools.ietf.org/html/rfc7946
 * - http://geojson.org/
 * 
 * Uses the PostGIS GeoJSON support.
 *  - https://postgis.net/docs/ST_GeomFromGeoJSON.html
 *
 * May of 2017
 *
 * @author andre
 *
 */
class Geometry {

	private $polygon;

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
		if(isset($jsonResponse) && ($jsonResponse["type"]==="Polygon" || $jsonResponse["type"]==="MultiPolygon") ) {
			$this->polygon = json_encode($jsonResponse);
		}
	}

	public function toPostgisSQLFragment() {
		$conf = ServiceConfiguration::defines();
		$sql = "ST_SetSRID(ST_GeomFromGeoJSON('".$this->polygon."'), ".$conf["SRID"].")";
		return $sql;
	}

}