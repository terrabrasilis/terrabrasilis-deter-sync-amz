<?php
namespace LibCurl;

use EdwardStock\Curl\Curl;

class LibCurl extends Curl {
	
	private $user;
	private $pass;
	
	public function put($url, $data = []) {
		$this->data = $data;
		$this->setOption(CURLOPT_URL, $url);
		$this->setOption(CURLOPT_CUSTOMREQUEST, 'PUT');
		$this->setOption(CURLOPT_POSTFIELDS, $this->postFields($data));
	
		return $this->exec();
	}
	
	private function postFields($data) {
		if (is_array($data)) {
			if (helpers\ArrayHelper::isMultidimensional($data)) {
				$data = helpers\HttpHelper::httpBuildMultiQuery($data);
			} else {
				foreach ($data as $key => $value) {
					// Fix "Notice: Array to string conversion" when $value in
					// curl_setopt($ch, CURLOPT_POSTFIELDS, $value) is an array
					// that contains an empty array.
					if (is_array($value) && empty($value)) {
						$data[$key] = '';
						// Fix "curl_setopt(): The usage of the @filename API for
						// file uploading is deprecated. Please use the CURLFile
						// class instead".
					} elseif (is_string($value) && strpos($value, '@') === 0) {
						if (class_exists('CURLFile')) {
							$data[$key] = new \CURLFile(substr($value, 1));
						}
					}
				}
			}
		}
	
		return $data;
	}
	
	public function resetCurl() {
		$this->curl = curl_init();
		$this->setUserAgent('PHP-Curl-Class/1.0 (extended from INPE)');
		$this->setOption(CURLINFO_HEADER_OUT, true);
		$this->setOption(CURLOPT_HEADER, true);
		$this->setOption(CURLOPT_RETURNTRANSFER, true);
		if(isset($this->user) && isset($this->pass)) {
			$this->setOption(CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
			$this->setOption(CURLOPT_USERPWD, $this->user . ':' . $this->pass);
		}
	}
	
	public function setBasicAuthentication($username, $password) {
		$this->user=$username;
		$this->pass=$password;
	}
}