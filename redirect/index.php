<?php

$theme = '';


set_include_path(get_include_path().':'.__DIR__.'/lib:'.__DIR__.'/templates');
include 'functions.php';
include 'oc/util.php';
include 'ocp/util.php';
include 'l10n.php';
include 'defaults.php';


$l = new L10N();

$_ = [
	'cssfiles' => ['css/styles.css','css/header.css','css/mobile.css','css/icons.css','css/fonts.css','css/fixes.css','css/apps.css'],
	'jsfiles' => ['js/redirect.js'],
	'bodyid' => 'body-login',
	'language' => 'de_de',
	'requesttoken' => '',
	'headers' => '',
	'messages' => [],
	'username' => '',
	'user_autofocus' => '',
	'rememberLoginAllowed' => '',
];

if ($theme) {
	$themedCssFiles = [];
	foreach ($_['cssfiles'] as $cssfile) {
		if (file_exists("themes/$theme/core/$cssfile")) {
			$themedCssFiles[] = "themes/$theme/core/$cssfile";
		}
	}
	$_['cssfiles'] = array_merge($_['cssfiles'], $themedCssFiles);
}

ob_start();
include 'login.php';
$content = ob_get_contents();
ob_end_clean();

$_['content'] = $content;


$theme = new \OC_Defaults($theme);

include 'layout.guest.php';
