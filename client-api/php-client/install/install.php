<?php
/**
 * Provide a simple way to build the environment to run this client.
 * - Create necessary directories such as: tmp, config, log and rawData
 * - Create the config file as template
 */

$directories = array("config", "log", "rawData", "tmp");

foreach ($directories as $dir) {
	$d=__DIR__ . "/../" . $dir;
	if(!is_dir($d)) {
		if(mkdir($d)===false) {
			echo "The installation was failed in create the directory ".$d;
			echo "Maybe is missing permissions.";
			exit();
		}
	}
}

$configTemplate = "<?php\n".
"// ServiceConfiguration.php\n".
"namespace Configuration;\n".
"\n".
"class ServiceConfiguration {\n".
"	\n".
"	public static function syncservice() {\n".
"		\$config = array (\n".
"				'host' => '".$_ENV["SYNC_SERVICE_HOST"]."',\n".
"				'user' => '".file_get_contents($_ENV["SYNC_SERVICE_USER_FILE"])."',\n".
"				'pass' => '".file_get_contents($_ENV["SYNC_SERVICE_PASS_FILE"])."',\n".
"				'max_times' => 5,// The maximum number of times that client attempt to connect with service.\n".
"				'timeout' => 60// Time waiting the service response (wait 60 seconds before send timeout signal).\n".
"		);\n".
"		return \$config;\n".
"	}\n".
"	\n".
"	public static function postgresql() {\n".
"		\$config = array (\n".
"				'host' => '".$_ENV["POSTGRES_HOST"]."',\n".
"				'user' => '".file_get_contents($_ENV["POSTGRES_USER_FILE"])."',\n".
"				'pass' => '".file_get_contents($_ENV["POSTGRES_PASS_FILE"])."',\n".
"				'dbname' => 'DETER-B',\n".
"				'port' => 5432\n".
"		);\n".
"		return \$config;\n".
"	}\n".
"	\n".
"	public static function defines() {\n".
"		\$config = array (\n".
"				'SRID' => 4674,// (SIRGAS 2000)\n".
"				'SCHEMA' => 'terrabrasilis',\n".
"				'DATA_TABLE' => 'deter_table',\n".
"				'LOG_TABLE' => 'deterb_sync_log'\n".
"		);\n".
"		return \$config;\n".
"	}\n".
"	\n".
"	public static function ssmtp() {\n".
"		\$config = array (\n".
"				'TO' => '".$_ENV["MAIL_TO"]."',\n".
"				'FROM' => '".file_get_contents($_ENV["SMTP_GOOGLE_MAIL_USER_FILE"])."'\n".
"		);\n".
"		return \$config;\n".
"	}\n".
"}\n".
"\n";

$configFileName = __DIR__ . "/../config/ServiceConfiguration.php";
$handle = fopen($configFileName, 'w');
if($handle===false) {
	echo "The file creator was fail when attempt create the configuration file.";
	exit();
}
fwrite($handle, $configTemplate);
fclose($handle);