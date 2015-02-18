<?php
/**
 * ownCloud setup wizard
 *
 * @author Frank Karlitschek
 * @copyright 2012 Frank Karlitschek frank@owncloud.org
 * @author Lukas Reschke
 * @copyright 2013-2014 Lukas Reschke lukas@owncloud.com
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU AFFERO GENERAL PUBLIC LICENSE
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU AFFERO GENERAL PUBLIC LICENSE for more details.
 *
 * You should have received a copy of the GNU Affero General Public
 * License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

/**
 * Please copy this file into your webserver root and open it with a browser. The setup wizard checks the dependency, downloads the newest ownCloud version, unpacks it and redirects to the ownCloud first run wizard.
 */


// init
ob_start(); 
error_reporting(E_ERROR | E_WARNING | E_PARSE | E_NOTICE);
ini_set('display_errors', 1);
@set_time_limit(0);
 
/**
 * Setup class with a few helper functions
 *
 */ 
class oc_setup {

	private static $requirements = array(
		'classes' => array(
			'ZipArchive' => 'zip',
			'DOMDocument' => 'dom',
		),
		'functions' => array(
			'xml_parser_create' => 'libxml',
			'mb_detect_encoding' => 'mb multibyte',
			'ctype_digit' => 'ctype',
			'json_encode' => 'JSON',
			'gd_info' => 'GD',
			'gzencode' => 'zlib',
			'iconv' => 'iconv',
			'simplexml_load_string' => 'SimpleXML'
		),
		'defined' => array(
			'PDO::ATTR_DRIVER_NAME' => 'PDO'
		)
	);
 
	/**
	* Checks if all the ownCloud dependencies are installed
	* @return string with error messages
	*/ 
	static public function checkdependencies() {
		$error = '';
		$missingDependencies = array();;

		// do we have PHP 5.3.3 or newer?
		if(version_compare(PHP_VERSION, '5.3.3', '<')) {
			$error.='PHP 5.3.3 is required. Please ask your server administrator to update PHP to version 5.3.3 or higher.<br/>';
		}

		foreach(self::$requirements as $type => $requirements) {
			foreach($requirements as $requirement => $module) {
				if($type === 'classes') {
					if(!class_exists($requirement)){
						$missingDependencies[] = array($module);
					}
				}
				if($type === 'functions') {
					if(!function_exists($requirement)){
						$missingDependencies[] = array($module);
					}
				}
				if($type === 'defined') {
					if(!defined($requirement)){
						$missingDependencies[] = array($module);
					}
				}
			}
		}

		if(!empty($missingDependencies)) {
			$error .= 'The following PHP modules are required to use ownCloud:<br/>';
		}
		foreach($missingDependencies as $missingDependency) {
			$error .= '<li>'.$missingDependency[0].'</li>';
		}
		if(!empty($missingDependencies)) {
			$error .= '</ul><p style="text-align:center">Please contact your server administrator to install the missing modules.</p>';
		}

		// do we have write permission?
		if(!is_writable('.')) {
			$error.='Can\'t write to the current directory. Please fix this by giving the webserver user write access to the directory.<br/>';
		}

		// is safe_mode enabled?
		if(ini_get('safe_mode')) {
			$error.='PHP Safe Mode is enabled. ownCloud requires that it is disabled to work properly.<br/>';
		}
		
		return($error);
	}


	/**
	* Check the cURL version
	* @return bool status of CURLOPT_CERTINFO implementation
	*/ 
	static public function iscertinfoavailable(){
		$curlDetails =  curl_version();
		return version_compare($curlDetails['version'], '7.19.1') != -1;
	}


 
	/**
	* Performs the ownCloud install.
	* @return string with error messages
	*/ 
	static public function install() {	
		$error='';
		$directory = $_GET['directory'];

		// Test if folder already exists
		if(file_exists('./'.$directory.'/status.php')) {
			return 'The selected folder seems to already contain a ownCloud installation. - You cannot use this script to update existing installations.';
		}

		// downloading latest release
		if (!file_exists('oc.zip')) {
			$error.=oc_setup::getfile('https://download.owncloud.org/download/community/owncloud-latest.zip','oc.zip');
		}

		// unpacking into owncloud folder
		$zip = new ZipArchive;
		$res = $zip->open('oc.zip');
		if ($res==true) {
			// Extract it to the tmp dir
			$owncloud_tmp_dir = 'tmp-owncloud'.time();
			$zip->extractTo($owncloud_tmp_dir);
			$zip->close();

			// Move it to the folder
			if ($_GET['directory'] === '.') {
				foreach (array_diff(scandir($owncloud_tmp_dir.'/owncloud'), array('..', '.')) as $item) {
					rename($owncloud_tmp_dir.'/owncloud/'.$item, './'.$item);
				}
				rmdir($owncloud_tmp_dir.'/owncloud');
			} else {
				rename($owncloud_tmp_dir.'/owncloud', './'.$directory);
			}
			// Delete the tmp folder
			rmdir($owncloud_tmp_dir);
		} else {
			$error.='unzip of owncloud source file failed.<br />';
		}

		// deleting zip file
		$result=@unlink('oc.zip');
		if($result==false) $error.='deleting of oc.zip failed.<br />';
		return($error);
	}

	 
	/**
	* Downloads a file and stores it in the local filesystem
	* @param string $url
	* @param string$path
	* @return string with error messages
	*/ 
	static public function getfile($url,$path) {
		$error='';

		$fp = fopen ($path, 'w+');
		$ch = curl_init($url); 
		curl_setopt($ch, CURLOPT_TIMEOUT, 0);
		curl_setopt($ch, CURLOPT_FILE, $fp); 
		curl_setopt($ch, CURLOPT_USERAGENT, $_SERVER['HTTP_USER_AGENT']);
		if (oc_setup::iscertinfoavailable()){
			curl_setopt($ch, CURLOPT_CERTINFO, TRUE); 
		}
		curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, TRUE); 
		$data=curl_exec($ch);
		$curlerror=curl_error($ch);
		curl_close($ch);
		fclose($fp);
 
		if($data==false){
			$error.='download of ownCloud source file failed.<br />'.$curlerror;	
		}
		return($error.$curlerror);

	}
 
  
	/**
	* Shows the html header of the setup page
	*/ 
	static public function showheader(){
		echo('
		<!DOCTYPE html>
		<html>	
			<head>	
				<title>ownCloud Setup</title>
				<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
				<link rel="icon" type="image/png" href="http://owncloud.org/setupwizard/favicon.png" />
				<link rel="stylesheet" href="http://owncloud.org/setupwizard/styles.css" type="text/css" media="screen" />
				<style type="text/css">
				body {
					text-align:center;
					font-size:13px;
					color:#666;
					font-weight:bold;
				}
				</style>
			</head>

			<body id="body-login">
		');
	}

 
	/**
	* Shows the html footer of the setup page
	*/ 
	static public function showfooter(){
		echo('
		<footer><p class="info"><a href="http://owncloud.org/">ownCloud</a> &ndash; web services under your control</p></footer>
		</body>
		</html>	
		');
	}
	
	 
	/**
	* Shows the html content part of the setup page
	* @param string $title
	* @param string $content
	* @param string $nextpage
	*/ 
	static public function showcontent($title,$content,$nextpage=''){
		echo('
		<div id="login">
			<header><div id="header">
				<img src="http://owncloud.org/setupwizard/logo.png" alt="ownCloud" />
			</div></header><br />
			<p style="text-align:center; font-size:28px; color:#444; font-weight:bold;">'.$title.'</p><br />
			<p style="text-align:center; font-size:13px; color:#666; font-weight:bold; ">'.$content.'</p>
			<form method="get">
				<input type="hidden" name="step" value="'.$nextpage.'" />
		');

		if($nextpage === 2) {
			echo ('<p style="padding-left:0.5em; padding-right:0.5em">Enter a single "." to install in the current directory, or enter a subdirectory to install to:</p>
				<input type="text" style="margin-left:0; margin-right:0" name="directory" value="owncloud" required="required" />');
		}
		if($nextpage === 3) {
			echo ('<input type="hidden" value="'.$_GET['directory'].'" name="directory" />');
		}

		if($nextpage<>'') echo('<input type="submit" id="submit" class="login" style="margin-right:100px;" value="Next" />');

		echo('
		</form>
		</div>
		
		');
	}


	/**
	* Shows the welcome screen of the setup wizard
	*/ 
	static public function showwelcome(){
		$txt='Welcome to the ownCloud Setup Wizard.<br />This wizard will check the ownCloud dependencies, download the newest version of ownCloud and install it in a few simple steps.';
		oc_setup::showcontent('Setup Wizard',$txt,1);
	}


	/**
	* Shows the check dependencies screen
	*/ 
	static public function showcheckdependencies(){
		$error=oc_setup::checkdependencies();
		if($error=='') {
			$txt='All ownCloud dependencies found';
			oc_setup::showcontent('Dependency check',$txt,2);
		}else{
			$txt='Dependencies not found.<br />'.$error;
			oc_setup::showcontent('Dependency check',$txt);
		}
	}


	/**
	* Shows the install screen
	*/ 
	static public function showinstall() {
		$error=oc_setup::install();
	
		if($error=='') {
			$txt='ownCloud is now installed';
			oc_setup::showcontent('Success',$txt,3);
		}else{
			$txt='ownCloud is NOT installed<br />'.$error;
			oc_setup::showcontent('Error',$txt);
		}
	}


	/**
	* Shows the redirect screen
	*/ 
	static public function showredirect(){
		// delete own file
		@unlink($_SERVER['SCRIPT_FILENAME']);
		
		// redirect to ownCloud
		header("Location: ".$_GET['directory']);	
	}
	
}


// read the step get variable
if(isset($_GET['step'])) $step=$_GET['step']; else $step=0;

// show the header
oc_setup::showheader();

// show the right step
if     ($step==0) oc_setup::showwelcome();
elseif ($step==1) oc_setup::showcheckdependencies();
elseif ($step==2) oc_setup::showinstall();
elseif ($step==3) oc_setup::showredirect();
else  echo('Internal error. Please try again.'); 

// show the footer
oc_setup::showfooter();
