<?php

/**
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 Morris Jobke <hey@morrisjobke.de>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/**
 * This code extracts the code comments out of ownCloud's config/config.sample.php and creates a RST document
 */


require 'vendor/autoload.php';

// tag which invokes to copy a config description to the current position
$COPY_TAG = 'see';
// file which should be parsed
$CONFIG_SAMPLE_FILE = 'config/config.sample.php';
// file to put output in
$OUTPUT_FILE = 'sample_config.rst';

// read file
$docBlock = file_get_contents($CONFIG_SAMPLE_FILE);

// trim everything before this (including itself)
$start = '$CONFIG = array(';
$docBlock = substr($docBlock, strpos($docBlock, $start) + strlen($start));

// trim the end of the config variable
$end = ');';
$docBlock = substr($docBlock, 0, strrpos($docBlock, $end));

// split on '/**'
$blocks = explode('/**', $docBlock);

// output that gets written to the file
$output = '';
// array that holds all RST representations of all config options to copy them
$lookup = array();

foreach($blocks as $block) {
    if(trim($block) === '') {
        continue;
    }
    $block = '/**' . $block;
    $parts = explode(' */', $block);
    $id = null;
    $doc = '';
    $code = '';
    // there should be exactly two parts after the split - otherwise there are some mistakes in the parsed block
    if(count($parts) !== 2) {
        echo '<h3>Uncommon part count!</h3><pre>';
        print_r($parts);
        echo '</pre>';
    } else {
        $doc = $parts[0] . ' */';
        $code = $parts[1];
    }

    // this checks if there is a config option below the comment (should be one if there is a config option or none if
    // the comment is just a heading of the next section
    preg_match('!^\'([^\']*)\'!m', $block, $matches);
    if(!in_array(count($matches), array(0, 2))) {
        echo 'Uncommon matches count<pre>';
        print_r($matches);
        echo '</pre>';
    }

    // if there are two matches a config option was found -> set it as ID
    if(count($matches) === 2) {
        $id = $matches[1];
    }

    // parse the doc block
    $phpdoc = new \phpDocumentor\Reflection\DocBlock($doc);

    // check for tagged elements to replace the tag with the actual config description
    $references = $phpdoc->getTagsByName($COPY_TAG);
    if(!empty($references)) {
        foreach($references as $reference) {
            $name = $reference->getContent();
            if(array_key_exists($name, $lookup)) {
                // append the element at the current position
                $output .= $lookup[$name];
            }
        }
    }

    $RSTRepresentation = '';

    // generate RST output
    if(is_null($id)) {
        // print heading - no
        $heading = $phpdoc->getShortDescription();
        $RSTRepresentation .= $heading . "\n";
        $RSTRepresentation .= str_repeat('-', strlen($heading)) . "\n\n";
        $longDescription = $phpdoc->getLongDescription();
        if(trim($longDescription) !== '') {
            $RSTRepresentation .= $longDescription . "\n\n";
            $RSTRepresentation .= "\n----\n\n";
        }
    } else {
        // print description
        $RSTRepresentation .= $phpdoc->getText();
        // empty line
        $RSTRepresentation .= "\n\n";
        // mark as literal (code block)
        $RSTRepresentation .= "::\n\n";
        // trim whitespace
        $code =  trim($code);
        // intend every line by an tab - also trim whitespace (for example: empty lines at the end)
        foreach(explode("\n", trim($code)) as $line) {
            $RSTRepresentation .= "\t" . $line . "\n";
        }
        $RSTRepresentation .= "\n";

        $lookup[$id] = $RSTRepresentation;
    }

    $output .= $RSTRepresentation;
}

// write content to file
file_put_contents($OUTPUT_FILE, $output);