<?php
/**
 * ownCloud setup wizard
 *
 * @author Frank Karlitschek
 * @copyright 2012 Frank Karlitschek frank@owncloud.org
 * @author Lukas Reschke
 * @copyright 2013-2015 Lukas Reschke lukas@owncloud.com
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
 */
class Setup {

	private static $requirements = array(
		array(
			'classes' => array(
				'ZipArchive' => 'zip',
				'DOMDocument' => 'dom',
				'XMLWriter' => 'XMLWriter'
			),
			'functions' => array(
				'xml_parser_create' => 'libxml',
				'mb_detect_encoding' => 'mb multibyte',
				'ctype_digit' => 'ctype',
				'json_encode' => 'JSON',
				'gd_info' => 'GD',
				'gzencode' => 'zlib',
				'iconv' => 'iconv',
				'simplexml_load_string' => 'SimpleXML',
				'hash' => 'HASH Message Digest Framework',
				'curl_init' => 'curl',
			),
			'defined' => array(
				'PDO::ATTR_DRIVER_NAME' => 'PDO'
			),
		)
	);


	/**
	* Checks if all the ownCloud dependencies are installed
	* @return string with error messages
	*/
	static public function checkDependencies() {
		$error = '';
		$missingDependencies = array();

		// do we have PHP 5.4.0 or newer?
		if(version_compare(PHP_VERSION, '5.4.0', '<')) {
			$error.='PHP 5.4.0 is required. Please ask your server administrator to update PHP to version 5.4.0 or higher.<br/>';
		}

		// running oC on windows is unsupported since 8.1
		if(substr(PHP_OS, 0, 3) === "WIN") {
			$error.='ownCloud Server does not support Microsoft Windows.<br/>';
		}

		foreach (self::$requirements[0]['classes'] as $class => $module) {
			if (!class_exists($class)) {
				$missingDependencies[] = array($module);
			}
		}
		foreach (self::$requirements[0]['functions'] as $function => $module) {
			if (!function_exists($function)) {
				$missingDependencies[] = array($module);
			}
		}
		foreach (self::$requirements[0]['defined'] as $defined => $module) {
			if (!defined($defined)) {
				$missingDependencies[] = array($module);
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

		return($error);
	}


	/**
	* Check the cURL version
	* @return bool status of CURLOPT_CERTINFO implementation
	*/
	static public function isCertInfoAvailable() {
		$curlDetails =  curl_version();
		return version_compare($curlDetails['version'], '7.19.1') != -1;
	}

	/**
	* Performs the ownCloud install.
	* @return string with error messages
	*/
	static public function install() {
		$error = '';
		$directory = $_GET['directory'];

		// Test if folder already exists
		if(file_exists('./'.$directory.'/status.php')) {
			return 'The selected folder seems to already contain a ownCloud installation. - You cannot use this script to update existing installations.';
		}

		// downloading latest release
		if (!file_exists('oc.zip')) {
			$error .= Setup::getFile('https://download.owncloud.org/download/community/owncloud-latest.zip','oc.zip');
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
	static public function getFile($url,$path) {
		$error='';

		$fp = fopen ($path, 'w+');
		$ch = curl_init($url);
		curl_setopt($ch, CURLOPT_TIMEOUT, 0);
		curl_setopt($ch, CURLOPT_FILE, $fp);
		curl_setopt($ch, CURLOPT_USERAGENT, $_SERVER['HTTP_USER_AGENT']);
		if (Setup::isCertInfoAvailable()){
			curl_setopt($ch, CURLOPT_CERTINFO, TRUE);
		}
		curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, TRUE);
		$data=curl_exec($ch);
		$curlError=curl_error($ch);
		curl_close($ch);
		fclose($fp);

		if($data==false){
			$error.='download of ownCloud source file failed.<br />'.$curlError;
		}
		return($error.$curlError);

	}


	/**
	* Shows the html header of the setup page
	*/
	static public function showHeader() {
		echo('
		<!DOCTYPE html>
		<html>
			<head>
				<title>ownCloud Setup</title>
				<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
				<link rel="icon" type="image/png" href="https://owncloud.org/setupwizard/favicon.png" />
				<link rel="stylesheet" href="https://owncloud.org/setupwizard/styles.css" type="text/css" media="screen" />
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
	static public function showFooter() {
		echo('
		<footer><p class="info"><a href="https://owncloud.org/">ownCloud</a> &ndash; web services under your control</p></footer>
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
	static public function showContent($title, $content, $nextpage=''){
		echo('
		<script>
			var validateForm = function(){
				if (typeof urlNotExists === "undefined"){
					return true;
				}
				urlNotExists(
					window.location.href, 
					function(){
						window.location.assign(document.forms["install"]["directory"].value);
					}
				);
				return false;
			}
		</script>
		<div id="login">
			<header><div id="header">
				<img src="https://owncloud.org/setupwizard/logo.png" alt="ownCloud" />
			</div></header><br />
			<p style="text-align:center; font-size:28px; color:#444; font-weight:bold;">'.$title.'</p><br />
			<p style="text-align:center; font-size:13px; color:#666; font-weight:bold; ">'.$content.'</p>
			<form method="get" name="install" onsubmit="return validateForm();">
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
	 * JS function to check if user deleted this script
	 * N.B. We can't reload the page to check this with PHP:
	 * once script is deleted we end up with 404
	 */
	static public function showJsValidation(){
		echo '
		<script>
			var urlNotExists = function(url, callback){
				var xhr = new XMLHttpRequest();
				xhr.open(\'HEAD\', encodeURI(url));
				xhr.onload = function() {
					if (xhr.status === 404){
						callback();
					}
				};
				xhr.send();
			};
		</script>
		';
	}


	/**
	* Shows the welcome screen of the setup wizard
	*/
	static public function showWelcome() {
		$txt='Welcome to the ownCloud Setup Wizard.<br />This wizard will check the ownCloud dependencies, download the newest version of ownCloud and install it in a few simple steps.';
		Setup::showContent('Setup Wizard',$txt,1);
	}


	/**
	* Shows the check dependencies screen
	*/
	static public function showCheckDependencies() {
		$error=Setup::checkDependencies();
		if($error=='') {
			$txt='All ownCloud dependencies found';
			Setup::showContent('Dependency check',$txt,2);
		}else{
			$txt='Dependencies not found.<br />'.$error;
			Setup::showContent('Dependency check',$txt);
		}
	}


	/**
	* Shows the install screen
	*/
	static public function showInstall() {
		$error=Setup::install();

		if($error=='') {
			$txt='ownCloud is now installed';
			Setup::showContent('Success',$txt,3);
		}else{
			$txt='ownCloud is NOT installed<br />'.$error;
			Setup::showContent('Error',$txt);
		}
	}

	/**
	 * Shows the redirect screen
	 */
	static public function showRedirect() {
		// delete own file
		@unlink(__FILE__);
		clearstatcache();
		if (file_exists(__FILE__)){
			Setup::showJsValidation();
			Setup::showContent(
				'Warning',
				'Failed to remove installer script. Please remove ' . __FILE__ . ' manually',
				3
			);
		} else {
			// redirect to ownCloud
			header("Location: " . $_GET['directory']);
		}
	}

}


// read the step get variable
$step = isset($_GET['step']) ? $_GET['step'] : 0;

// show the header
Setup::showHeader();

// show the right step
if     ($step==0) Setup::showWelcome();
elseif ($step==1) Setup::showCheckDependencies();
elseif ($step==2) Setup::showInstall();
elseif ($step==3) Setup::showRedirect();
else  echo('Internal error. Please try again.');

// show the footer
Setup::showFooter();
