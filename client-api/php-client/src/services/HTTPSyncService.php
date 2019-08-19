<?php
namespace Services;

use LibCurl\LibCurl;
use DAO\GeneralLog;
use Configuration\ServiceConfiguration;
use ValueObjects\DeterbTupleStore;
use DateTime;
use DateTimeZone;

/**
 * @abstract Allow to communicate with HTTP Sync Service via API to read data.
 * 
 * @uses By default the log is writen on local directory /log/sync_service.
 * 
 * @since May of 2017
 * 
 * @author andre
 *
 */
class HTTPSyncService {
	
	protected $hashKey = null;
	protected $curl = null;
	protected $logger = null;
	
	function __construct() {
		
		$logDir = "sync_service";
		$this->logger = new GeneralLog($logDir);
		
		$this->curl = new LibCurl();
		$this->doAuthentication();
	}
	
	function __destruct() {
		$this->curl->close();
	}
	
	/**
	 * Write more detailed log info provided from CURL class.
	 * @param string $msg, the message about the fail.
	 */	
	private function writeErrorLog($msg="") {
		if(!empty($msg)) {
			$this->logger->writeErrorLog($msg);
		}
		if ($this->curl->error) {
			$this->logger->writeErrorLog("ErrorCode:".$this->curl->errorCode);
			$this->logger->writeErrorLog("ErrorMsg:".$this->curl->errorMessage);
		}
	}
	
	/**
	 * Do authentication and store hash key to this session in memory.
	 */
	private function doAuthentication() {
		$config = ServiceConfiguration::syncservice();
		if (empty ( $config )) {
			$this->writeErrorLog("Missing sync service configuration.");
			return false;
		}
		
		$host = $config["host"].'login/'.$config["user"].'/'.$config["pass"];
		$this->curl->get($host);
		
		$this->hashKey = $this->curl->response->hashKey;
		if ($this->curl->error || $this->curl->httpStatusCode!==200 ) {
			$this->hashKey = null;
			$this->writeErrorLog();
			return false;
		}
	}
	
	/**
	 * Load all geometries from service for insert the initial population into local table.
	 * The tipical url is: http://<URL_BASE>/allgeometries?hashKey=<auth_key>
	 * @return DeterbTableStore or false: Return the DeterbTableStore instance or false otherwise.
	 */
	public function getAllGeometries() {
		
		if(!$this->hashKey) {
			$this->writeErrorLog("The hash key is undefined.");
			return false;
		}
		
		$config = ServiceConfiguration::syncservice();
		
		if (empty ( $config )) {
			$this->writeErrorLog("Missing sync service configuration.");
			return false;
		}
		
		$URL = $config["host"].'allgeometries?hashKey='.$this->hashKey;
		//$this->curl->resetCurl();
		$this->curl->get($URL);
		
		if ($this->curl->error) {
			$this->writeErrorLog();
			return false;
		}
		
		$tableStore=false;
		
		if($this->curl->responseHeaders['Status-Line']=="HTTP/1.1 200 OK" && $this->curl->responseHeaders['Content-Type']=="application/json") {
			$jsonResponse = $this->curl->response;
			if(isset($jsonResponse->inserts) || isset($jsonResponse->updates) || isset($jsonResponse->deletes)) {
				$tableStore = new DeterbTableStore($jsonResponse);
			}else {
				$this->writeErrorLog("No data on remote table store.");
				return false;
			}
		}else {
			$this->writeErrorLog("Failure of response test on getAllGeometries.");
			return false;
		}
		
		return $tableStore;
	}
	
	/**
	 * Load all geometries in SQL script format as from service for insert into local table.
	 * The tipical url is: http://<URL_BASE>/allgeometries?hashKey=<auth_key>
	 * @return string or false: Return the name of read file or false otherwise.
	 */
	public function downloadAllGeometries() {
		
		if(!$this->hashKey) {
			$this->writeErrorLog("The hash key is undefined.");
			return false;
		}
		
		$config = ServiceConfiguration::syncservice();
		
		if (empty ( $config )) {
			$this->writeErrorLog("Missing sync service configuration.");
			return false;
		}
	
		$URL = $config["host"].'allgeometries/'.$this->hashKey;

		
		// USE TEST URL
		//$URL = 'http://200.18.85.235/detertool/allgeometries/f80220b6c3a6da4a2e3bc527d8a856ca';
		//$URL = 'http://localhost/html/sleep.php';
		//$this->curl->resetCurl(); // TODO: see if this is necessary...
		
		// This is the file where we save the information
		$dt = new DateTime();
		$dt->setTimeZone(new DateTimeZone('America/Sao_Paulo'));
		$baseFileName = $dt->format('d-m-Y') . "_all_data";
		$tmpFile = __DIR__ . '/../../tmp/'.$baseFileName.'.tmp';
		
		$fp = fopen( $tmpFile, 'w+');
		if($fp===false) {
			$this->writeErrorLog("Fail on open the temporary file.");
			return false;
		}
		
		// sets curl option to save response directly to a file
		@$this->curl->setOption(CURLOPT_HEADER, 0);
		// $this->curl->setOption(CURLOPT_TIMEOUT, $config["timeout"]);
		$this->curl->setOption(CURLOPT_CONNECTTIMEOUT, $config["timeout"]);
		$this->curl->setOption(CURLOPT_FOLLOWLOCATION, true);
		$this->curl->setOption(CURLOPT_FILE, $fp);// write curl response to file
		
		$this->curl->get($URL);
		$sucess = (!$this->curl->error && $this->curl->response===true && $this->curl->httpStatusCode===200);
		
		$MAX_REPEAT = $config["max_times"];// Used to control the number of times we call the service when one error is find.
		while(!$sucess && $MAX_REPEAT>0) {
			$this->curl->get($URL);
			$sucess = (!$this->curl->error && $this->curl->response===true && $this->curl->httpStatusCode===200);
			$this->writeErrorLog("Repeat time:".$MAX_REPEAT);
			$MAX_REPEAT--;
		}

		if($sucess) {
			// move temporary file to rawData directory
			$finalFile = __DIR__ . '/../../rawData/' . $baseFileName . '.sql';
			
			if(rename($tmpFile, $finalFile)===false) {
				$this->writeErrorLog("Failure on move temporary file to work directory.");
				fclose($fp);
				unlink($tmpFile);
				return false;
			}
			
			fclose($fp);
			return $finalFile;
		}else {
			$this->writeErrorLog("Failure of response from downloadAllGeometries call.");
			fclose($fp);
			unlink($tmpFile);
			return false;
		}
	}
	
	/**
	 * Load last geometries from a reference date, in SQL script format as from service for insert into local table.
	 * The tipical url is: http://<URL_BASE>/downloadLastGeometries/<auth_key>/<last_date>
	 * @return string or false: Return the name of read file or false otherwise.
	 */
	public function downloadLastGeometries($last_date) {
	
		if(!$this->hashKey) {
			$this->writeErrorLog("The hash key is undefined.");
			return false;
		}
	
		$config = ServiceConfiguration::syncservice();
	
		if (empty ( $config )) {
			$this->writeErrorLog("Missing sync service configuration.");
			return false;
		}
	
		$URL = $config["host"].'getdata/'.$this->hashKey.'/'.$last_date;
		
		// This is the file where we save the information
		$dt = new DateTime();
		$dt->setTimeZone(new DateTimeZone('America/Sao_Paulo'));
		$baseFileName = $dt->format('d-m-Y') . "_portion_data";
		$tmpFile = __DIR__ . '/../../tmp/'.$baseFileName.'.tmp';
		
		$fp = fopen( $tmpFile, 'w+');
		if($fp===false) {
			$this->writeErrorLog("Fail on open the temporary file.");
			return false;
		}
		
		// sets curl option to save response directly to a file
		@$this->curl->setOption(CURLOPT_HEADER, 0);
		$this->curl->setOption(CURLOPT_CONNECTTIMEOUT, $config["timeout"]);
		$this->curl->setOption(CURLOPT_FOLLOWLOCATION, true);
		$this->curl->setOption(CURLOPT_FILE, $fp);// write curl response to file
		
		$this->curl->get($URL);
		$sucess = (!$this->curl->error && $this->curl->response===true && $this->curl->httpStatusCode===200);
		
		$MAX_REPEAT = $config["max_times"];// Used to control the number of times we call the service when one error is find.
		while(!$sucess && $MAX_REPEAT>0) {
			$this->curl->get($URL);
			$sucess = (!$this->curl->error && $this->curl->response===true && $this->curl->httpStatusCode===200);
			$this->writeErrorLog("Repeat time:".$MAX_REPEAT);
			$MAX_REPEAT--;
		}
		
		if($sucess) {
			// move temporary file to rawData directory
			$finalFile = __DIR__ . '/../../rawData/' . $baseFileName . '.sql';
				
			if(rename($tmpFile, $finalFile)===false) {
				$this->writeErrorLog("Failure on move temporary file to work directory.");
				fclose($fp);
				unlink($tmpFile);
				return false;
			}
				
			fclose($fp);
			return $finalFile;
		}else {
			$this->writeErrorLog("Failure of response from downloadLastGeometries call.");
			fclose($fp);
			unlink($tmpFile);
			return false;
		}
	}
	
}
