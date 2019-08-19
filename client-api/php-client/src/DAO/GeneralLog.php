<?php
/**
 * @filesource GeneralLog.php
 *
 * @abstract It is used to write general log file.
 *
 * @author André Carvalho
 *
 * @version 2017.05.15
 */
namespace DAO;

use Log\Log;

/**
 * @abstract Prepares one directory to write one log file.
 */
class GeneralLog extends Log {
	
	private $logDir,
			$logEnable,
			$logger;
	
	function __construct($dirName="general") {
		
		$this->logEnable=true;
		
		$this->logDir= __DIR__ . "/../../log/".$dirName;
		
		if ( !is_dir($this->logDir) ) {
			if(!mkdir($this->logDir, 0777, true)) {
				// Failed to create log folder. Disabling log!
				$this->logEnable=false;
			}
		}
		
		if($this->logEnable) {
			$this->logger = new Log($this->logDir);
		}
	}
	
	public function writeWarningLog($msg="") {
		if(!$this->logEnable) {
			return false;
		}
		if(!empty($msg)) {
			$this->logger->log_warn($msg);
		}
	}
	
	public function writeErrorLog($msg="") {
		if(!$this->logEnable) {
			return false;
		}
		if(!empty($msg)) {
			$this->logger->log_error($msg);
		}
	}
}