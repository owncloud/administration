<?php
/**
 * ownCloud setup wizard
 *
 * @author Frank Karlitschek
 * @copyright 2012 Frank Karlitschek frank@owncloud.org
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
 
 
/**
 * @brief Setup class with a few helper functions
 *
 */ 
class oc_setup {
	
 
	/**
	* @brief Checks if all the ownCloud dependencies are installed
	* @return string with error messages
	*/ 
	static public function checkdependencies() {
		$error='';
		
		// do we have PHP 4.3 or newer?
		if(floatval(phpversion())<5.3){
			$error.='PHP 5.3 is required. Please ask your server administrator to update PHP to version 5.3 or higher. PHP 5.2 is no longer supported by ownCloud and the PHP community.';
		}
		
		// do we have the zip module?
		if(!class_exists('ZipArchive')){
			$error.='PHP module zip not installed. Please ask your server administrator to install the module.';
		}
		
		// do we have write permission?
		if(!is_writable('.')) {
			$error.='Can\'t write to the current directory. Please fix this by giving the webserver user write access to the directory.';
                }
		
		return($error);
	}

 
	/**
	* @brief Performs the ownCloud install. 
	* @return string with error messages
	*/ 
	static public function install() {	
			$error='';
		
			// downloading latest release
			$error.=oc_setup::getfile('http://owncloud.org/releases/owncloud-latest.zip','oc.zip');
			
			// unpacking into owncloud folder
			$zip = new ZipArchive;
			$res = $zip->open('oc.zip');
			if ($res==true) {
				$zip->extractTo('.');
				$zip->close();
			} else {
				$error.='unzip of owncloud source file failed.<br />';
			}

			// deleting tar file
			$result=@unlink('oc.zip');
			if($result==false) $error.='deleting of oc.zip failed.<br />';
			return($error);
	}

	 
	/**
	* @brief Downloads a file and stores it in the local filesystem
	* @param url $url
	* @param path $path	
	* @return string with error messages
	*/ 
	static public function getfile($url,$path) {
		$error='';

		$newfname = $path;
		$file = @fopen ($url, 'rb');
		if ($file) {
			$newf = fopen ($newfname, 'wb');

			if ($newf)
			while(!feof($file)) {
				fwrite($newf, fread($file, 1024*8 ), 1024*8 );
			}
		}else{
			$error.='download of ownCloud source file failed.<br />';	
		}
		if ($file) fclose($file);
		if (isset($newf) and $newf) fclose($newf);
		
		return($error);
	}
 
  
	/**
	* @brief Shows the html header of the setup page
	*/ 
	static public function showheader(){
		echo('
		<!DOCTYPE html>
		<html>	
			<head>	
				<title>ownCloud Setup</title>
				<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
				<link rel="stylesheet" href="http://owncloud.org/setupwizard/styles.css" type="text/css" media="screen" />
			</head>

			<body id="body-login">
		');
	}

 
	/**
	* @brief Shows the html footer of the setup page
	*/ 
	static public function showfooter(){
		echo('
		<footer><p class="info"><a href="http://owncloud.org/">ownCloud</a> &ndash; web services under your control</p></footer>
		</body>
		</html>	
		');
	}
	
	 
	/**
	* @brief Shows the html content part of the setup page
	* @param title $title	
	* @param content $content
	* @param nextpage $nextpage
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
		
		if($nextpage<>'') echo('<input type="submit" id="submit" class="login" style="margin-right:100px;" value="Next" />');

		echo('
		</form>
		</div>
		
		');
	}


	/**
	* @brief Shows the wecome screen of the setup wizard
	*/ 
	static public function showwelcome(){
		$txt='Welcome to the ownCloud Setup Wizard.<br />This wizard will check the ownCloud dependencies, download the newest version of ownCloud and install it in a few simple steps';
		oc_setup::showcontent('Setup Wizard',$txt,1);
	}


	/**
	* @brief Shows the check dependencies screen
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
	* @brief Shows the install screen
	*/ 
	static public function showinstall(){
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
	* @brief Shows the redirect screen
	*/ 
	static public function showredirect(){
		// delete own file
		@unlink($_SERVER['SCRIPT_FILENAME']);
		
		// redirect to ownCloud
		header("Location: owncloud");	
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


?>