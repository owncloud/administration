<?php

$autoloaderDirectory = dirname(dirname(__DIR__));
require_once $autoloaderDirectory . '/vendor/autoload.php';

// Check for  PHPUnit lower than 6.0 first
if (!class_exists('\PHPUnit_Framework_TestCase')) {
	class PHPUnit_Framework_TestCase extends \PHPUnit\Framework\TestCase {
	}
}
