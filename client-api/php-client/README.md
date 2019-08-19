# Client API - deter-b-sync-data-client

Using the PHP with cURL over DETER-B service API to create a client that synchronize data.
Additionally, we implement one script to check status of synchronize process and send email to admin.

**Full run environment was build in Docker. See env-php directory.**

## About dependencies

- This project is organized using Composer and the used version is [1.3.1](https://getcomposer.org/download/1.3.1/composer.phar)
- Other technique used is the [PSR-4 autoload spec](http://www.php-fig.org/psr/psr-4/).
	- If a new path do registered on composer.json in autoload property, use this command [#php composer.phar dumpautoload -o] to update the composer autoload file.

## Installation (tested in Linux - Ubuntu 14.04)

The expected environment to deployment is composed for:
- PHP 5

  Install curl module on php.
  ```
  apt-get install php5-curl
  ```

  Install the PDO driver for postgres on php.
  ```
  apt-get install php-pgsql
  ```
  
  Install ssmtp. If you use the script of state check (optional)
  ```
  apt-get install ssmtp
  ```
  
  Install the php composer on root directory of the project.
  ```
  wget https://getcomposer.org/download/1.3.2/composer.phar
  ```

### Installing dependecies from composer.json
 - To install the defined dependencies for project, just run the install command.
 
  ```
  php composer.phar install
  ```

### Prepare environment to run
- Provide a simple way to build the environment to run this client.
	- Create necessary directories such as: tmp, config, log and rawData
	- Create the config file as template

  ```
  php install/install.php
  ```
- After that, open the template configuration file "~config/ServiceConfiguration.php" and change it to your environment values.

### Run manually
- Just call the script on command line

```
php index.php
```

### Automatize as a task
- Run using the cron.

With root:
```
crontab -e
```

Example of the crontab fragment:
```
# Tasks to syncronize and check state of the last syncronize for DETER-B project
45 23 * * * /usr/bin/php /your/instalation/path/index.php
10 0 * * * /usr/bin/php /your/instalation/path/checkStatus.php
```

To Reloading configuration files for periodic command scheduler cron:
```
service cron reload
```

### Configure your send mail properties (optional)
- If you want to send emails after run the script to check status you should prepare your environment.

 Open and change this files:
 ```
 nano /etc/ssmtp/ssmtp.conf
 nano /etc/ssmtp/revaliases
 ```
 *If you don't know to make it you may use an external information to make this.
 Ex.: https://help.ubuntu.com/community/EmailAlerts
