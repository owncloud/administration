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