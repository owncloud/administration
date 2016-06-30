# ownCloud config.sample.php to RST converter

This script creates a RST file from the comments inside of config.sample.php.

## Requirements

Install the dependencies with `composer`:

	composer update

## How to use

Just call following in your ownCloud core repo:

	php path/to/convert.php

This will create a file `sample_config.rst` which was generated from `config/config.sample.php`

## Supported feature set

Currently this relies on following

 * all comments need to start with `/**` and end with ` */` - each on their own line
 * add a `@see CONFIG_INDEX` to copy a previously described config option also to this line
 * everything between the ` */` and the next `/**` will be treated as the config option

## Options to set

You can set following options:

The tag which invokes to copy a config description to the current position

	$COPY_TAG = 'see';

The file which should be parsed

	$CONFIG_SAMPLE_FILE = 'config/config.sample.php';

The file to put output in

	$OUTPUT_FILE = 'sample_config.rst';

## License

The MIT License (MIT)

Copyright (c) 2014 Morris Jobke <hey@morrisjobke.de>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.