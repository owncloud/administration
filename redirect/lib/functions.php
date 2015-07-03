<?php
/**
 * ownCloud
 *
 * This file is licensed under the Affero General Public License version 3 or
 * later. See the COPYING-AGPL file.
 *
 * @author Jörn Friedrich Dreyer <jfd@butonic.de>
 * @copyright Jörn Friedrich Dreyer 2015
 */

function vendor_script($app, $file = null) {
	//ignored, manually specify css & js paths
}
function script($app, $file = null) {
	//ignored, manually specify css & js paths
}

function vendor_style($app, $file = null) {
	//ignored, manually specify css & js paths
}
function style($app, $file = null) {
	//ignored, manually specify css & js paths
}

function image_path($app, $file) {
	switch ($file) {
		case 'favicon.png':
			return 'img/favicon.png';
		case 'favicon-touch.png':
			return 'img/favicon-touch.png';
		case 'actions/password.svg':
			return 'img/actions/password.svg';
		case 'actions/user.svg':
			return 'img/actions/user.svg';
		case 'loading-dark.gif':
			return 'img/loading-dark.gif';

		default:
			return 'FIXME';
	}
}


/**
 * Prints a sanitized string
 * @param string|array $string the string which will be escaped and printed
 */
function p($string) {
	print(OC_Util::sanitizeHTML($string));
}

/**
 * Prints an unsanitized string - usage of this function may result into XSS.
 * Consider using p() instead.
 * @param string|array $string the string which will be printed as it is
 */
function print_unescaped($string) {
	print($string);
}
