<?php

require 'vendor/autoload.php';

$docblock = <<<DOCBLOCK
/**
 * This is a short description.
 *
 * This is a *long* description.
 *
 * @return void
 */
DOCBLOCK;

$phpdoc = new \phpDocumentor\Reflection\DocBlock($docblock);
