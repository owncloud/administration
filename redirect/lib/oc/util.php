<?php

class OC_Util {

	public static function sanitizeHTML(&$value) {
		if (is_array($value)) {
			array_walk_recursive($value, 'OC_Util::sanitizeHTML');
		} else {
		//Specify encoding for PHP<5.4
		$value = htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
		}
		return $value;
	}

}