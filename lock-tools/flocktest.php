<?php

//***** CHANGE THESE *****//

// Domain slash "remote.php"
$owncloud_remote = 'oc_master.vmt/remote.php';

// ownCloud authentication details
$username = 'admin';
$password = 'password';

// How many files to attempt uploading
$files_appearing = 2;

// How many times to run the whole sequence
$passes = 1;

// How many times to try each file at a time
$attempts_per_pass = 2;

// Number of curl requests to execute simultaneously
$window = 4;

// Name of directory to create for test files
$testdir = '/flocktest';



//***** DON'T CHANGE THESE *****//

ini_set('display_errors',1);
error_reporting(-1);

// RollingCurl

/*
Authored by Josh Fraser (www.joshfraser.com)
Released under Apache License 2.0

Maintained by Alexander Makarov, http://rmcreative.ru/

$Id$
*/

/**
 * Class that represent a single curl request
 */
class RollingCurlRequest {
	public $url = false;
	public $method = 'GET';
	public $post_data = null;
	public $headers = null;
	public $options = null;

	/**
	 * @param string $url
	 * @param string $method
	 * @param  $post_data
	 * @param  $headers
	 * @param  $options
	 * @return void
	 */
	function __construct($url, $method = "GET", $post_data = null, $headers = null, $options = null) {
		$this->url = $url;
		$this->method = $method;
		$this->post_data = $post_data;
		$this->headers = $headers;
		$this->options = $options;
	}

	/**
	 * @return void
	 */
	public function __destruct() {
		unset($this->url, $this->method, $this->post_data, $this->headers, $this->options);
	}
}

/**
 * RollingCurl custom exception
 */
class RollingCurlException extends Exception {
}

/**
 * Class that holds a rolling queue of curl requests.
 *
 * @throws RollingCurlException
 */
class RollingCurl {
	/**
	 * @var int
	 *
	 * Window size is the max number of simultaneous connections allowed.
	 *
	 * REMEMBER TO RESPECT THE SERVERS:
	 * Sending too many requests at one time can easily be perceived
	 * as a DOS attack. Increase this window_size if you are making requests
	 * to multiple servers or have permission from the receving server admins.
	 */
	private $window_size = 5;

	/**
	 * @var float
	 *
	 * Timeout is the timeout used for curl_multi_select.
	 */
	private $timeout = 10;

	/**
	 * @var string|array
	 *
	 * Callback function to be applied to each result.
	 */
	private $callback;

	/**
	 * @var array
	 *
	 * Set your base options that you want to be used with EVERY request.
	 */
	protected $options = array(
		CURLOPT_SSL_VERIFYPEER => 0,
		CURLOPT_RETURNTRANSFER => 1,
		CURLOPT_CONNECTTIMEOUT => 30,
		CURLOPT_TIMEOUT => 30
	);

	/**
	 * @var array
	 */
	private $headers = array();

	/**
	 * @var Request[]
	 *
	 * The request queue
	 */
	private $requests = array();

	/**
	 * @var RequestMap[]
	 *
	 * Maps handles to request indexes
	 */
	private $requestMap = array();

	/**
	 * @param  $callback
	 * Callback function to be applied to each result.
	 *
	 * Can be specified as 'my_callback_function'
	 * or array($object, 'my_callback_method').
	 *
	 * Function should take three parameters: $response, $info, $request.
	 * $response is response body, $info is additional curl info.
	 * $request is the original request
	 *
	 * @return void
	 */
	function __construct($callback = null) {
		$this->callback = $callback;
	}

	/**
	 * @param string $name
	 * @return mixed
	 */
	public function __get($name) {
		return (isset($this->{$name})) ? $this->{$name} : null;
	}

	/**
	 * @param string $name
	 * @param mixed $value
	 * @return bool
	 */
	public function __set($name, $value) {
		// append the base options & headers
		if ($name == "options" || $name == "headers") {
			$this->{$name} = $value + $this->{$name};
		} else {
			$this->{$name} = $value;
		}
		return true;
	}

	/**
	 * Add a request to the request queue
	 *
	 * @param Request $request
	 * @return bool
	 */
	public function add($request) {
		$this->requests[] = $request;
		return true;
	}

	public function clear() {
		$this->requests = array();
		return true;
	}

	/**
	 * Create new Request and add it to the request queue
	 *
	 * @param string $url
	 * @param string $method
	 * @param  $post_data
	 * @param  $headers
	 * @param  $options
	 * @return bool
	 */
	public function request($url, $method = "GET", $post_data = null, $headers = null, $options = null) {
		$this->requests[] = new RollingCurlRequest($url, $method, $post_data, $headers, $options);
		return true;
	}

	/**
	 * Perform GET request
	 *
	 * @param string $url
	 * @param  $headers
	 * @param  $options
	 * @return bool
	 */
	public function get($url, $headers = null, $options = null) {
		return $this->request($url, "GET", null, $headers, $options);
	}

	/**
	 * Perform POST request
	 *
	 * @param string $url
	 * @param  $post_data
	 * @param  $headers
	 * @param  $options
	 * @return bool
	 */
	public function post($url, $post_data = null, $headers = null, $options = null) {
		return $this->request($url, "POST", $post_data, $headers, $options);
	}

	/**
	 * Perform PUT request
	 *
	 * @param string $url
	 * @param  $post_data
	 * @param  $headers
	 * @param  $options
	 * @return bool
	 */
	public function put($url, $file_data, $headers = null, $options = null) {
		return $this->request($url, "PUT", $file_data, $headers, $options);
	}

	/**
	 * Execute processing
	 *
	 * @param int $window_size Max number of simultaneous connections
	 * @return string|bool
	 */
	public function execute($window_size = null) {
		// rolling curl window must always be greater than 1
		if (sizeof($this->requests) == 1 || $window_size == 1) {
			$out = null;
			while(sizeof($this->requests) > 0) {
				$out = $this->single_curl();
			}
			return $out;
		} else {
			// start the rolling curl. window_size is the max number of simultaneous connections
			return $this->rolling_curl($window_size);
		}
	}

	/**
	 * Performs a single curl request
	 *
	 * @access private
	 * @return string
	 */
	private function single_curl() {
		$ch = curl_init();
		$request = array_shift($this->requests);
		$request->time_in = microtime(true);
		$options = $this->get_options($request);
		curl_setopt_array($ch, $options);
		$output = curl_exec($ch);
		$info = curl_getinfo($ch);

		// it's not neccesary to set a callback for one-off requests
		if ($this->callback) {
			$request->time_out = microtime(true);
			$callback = $this->callback;
			if (is_callable($this->callback)) {
				call_user_func($callback, $output, $info, $request);
			}
		}
		else
			return $output;
		return true;
	}

	/**
	 * Performs multiple curl requests
	 *
	 * @access private
	 * @throws RollingCurlException
	 * @param int $window_size Max number of simultaneous connections
	 * @return bool
	 */
	private function rolling_curl($window_size = null) {
		if ($window_size)
			$this->window_size = $window_size;

		// make sure the rolling window isn't greater than the # of urls
		if (sizeof($this->requests) < $this->window_size)
			$this->window_size = sizeof($this->requests);

		if ($this->window_size < 2) {
			throw new RollingCurlException("Window size must be greater than 1");
		}

		$master = curl_multi_init();

		$start_time = microtime(true);
		// start the first batch of requests
		for ($i = 0; $i < $this->window_size; $i++) {
			$ch = curl_init();

			$this->requests[$i]->time_in = $start_time;
			$options = $this->get_options($this->requests[$i]);

			curl_setopt_array($ch, $options);
			curl_multi_add_handle($master, $ch);

			// Add to our request Maps
			$key = (string) $ch;
			$this->requestMap[$key] = $i;
		}

		do {
			while (($execrun = curl_multi_exec($master, $running)) == CURLM_CALL_MULTI_PERFORM) ;
			if ($execrun != CURLM_OK)
				break;
			// a request was just completed -- find out which one
			while ($done = curl_multi_info_read($master)) {

				// get the info and content returned on the request
				$info = curl_getinfo($done['handle']);
				$output = curl_multi_getcontent($done['handle']);

				// send the return values to the callback function.
				$callback = $this->callback;
				if (is_callable($callback)) {
					$key = (string) $done['handle'];
					$request = $this->requests[$this->requestMap[$key]];
					$request->time_out = microtime(true);
					unset($this->requestMap[$key]);
					call_user_func($callback, $output, $info, $request);
				}

				// start a new request (it's important to do this before removing the old one)
				if ($i < sizeof($this->requests) && isset($this->requests[$i]) && $i < count($this->requests)) {
					$ch = curl_init();
					$this->requests[$i]->time_in = microtime(true);
					$options = $this->get_options($this->requests[$i]);
					curl_setopt_array($ch, $options);
					curl_multi_add_handle($master, $ch);

					// Add to our request Maps
					$key = (string) $ch;
					$this->requestMap[$key] = $i;
					$i++;
				}

				// remove the curl handle that just completed
				curl_multi_remove_handle($master, $done['handle']);

			}

			// Block for data in / output; error handling is done by curl_multi_exec
			if ($running)
				curl_multi_select($master, $this->timeout);

		} while ($running);
		curl_multi_close($master);
		return true;
	}


	/**
	 * Helper function to set up a new request by setting the appropriate options
	 *
	 * @access private
	 * @param Request $request
	 * @return array
	 */
	private function get_options($request) {
		// options for this entire curl object
		$options = $this->__get('options');
		if (ini_get('safe_mode') == 'Off' || !ini_get('safe_mode')) {
			$options[CURLOPT_FOLLOWLOCATION] = 1;
			$options[CURLOPT_MAXREDIRS] = 5;
		}
		$headers = $this->__get('headers');

		// append custom options for this specific request
		if ($request->options) {
			$options = $request->options + $options;
		}

		// set the request URL
		$options[CURLOPT_URL] = $request->url;

		// posting data w/ this request?
		switch($request->method) {
			case 'GET':
				$options[CURLOPT_HTTPGET] = 1;
				break;
			case 'POST':
				$options[CURLOPT_POST] = 1;
				if ($request->post_data) {
					$options[CURLOPT_POSTFIELDS] = $request->post_data;
				}
				break;
			case 'PUT':
				$options[CURLOPT_PUT] = 1;
				if ($request->post_data) {
					$fh = fopen($request->post_data, 'r');
					fseek($fh, 0, SEEK_END);
					$filesize = ftell($fh);
					fseek($fh, 0, SEEK_SET);
					$options[CURLOPT_INFILE] = $fh;
					$options[CURLOPT_INFILESIZE] = $filesize;
				}
				break;
			default:
				$options[CURLOPT_CUSTOMREQUEST] = $request->method;
		}
		if ($headers) {
			$options[CURLOPT_HEADER] = 0;
			$options[CURLOPT_HTTPHEADER] = $headers;
		}

		return $options;
	}

	/**
	 * @return void
	 */
	public function __destruct() {
		unset($this->window_size, $this->callback, $this->options, $this->headers, $this->requests);
	}
}

function randpng($number) {
	static $fnames = array();

	if($number == 0) {
		foreach($fnames as $name) {
			unlink($name);
		}
		return;
	}

	if(!isset($fnames[$number])) {
		$Width = 853;
		$Height = 640;

		$Image = imagecreate($Width, $Height);
		for($z = 0; $z < 30; $z++) {
			$Red = mt_rand(0,255);
			$Green = mt_rand(0,255);
			$Blue = mt_rand(0,255);
			$Colour = imagecolorallocate ($Image, $Red , $Green, $Blue);
			imagerectangle($Image, mt_rand(0, $Width), mt_rand(0, $Height), mt_rand(0, $Width), mt_rand(0, $Height), $Colour);
		}
		$tmp = tempnam(sys_get_temp_dir(), 'ft_');
		$fnames[$number] = $tmp;
		imagepng($Image, $fnames[$number], 0);
	}
	return $fnames[$number];
}

$stats = array();
$curl = new RollingCurl(function($response, $info, $request) use(&$stats) {
	$messages = array(
		// [Informational 1xx]
		100=>'100 Continue',
		101=>'101 Switching Protocols',
		// [Successful 2xx]
		200=>'200 OK',
		201=>'201 Created',
		202=>'202 Accepted',
		203=>'203 Non-Authoritative Information',
		204=>'204 No Content',
		205=>'205 Reset Content',
		206=>'206 Partial Content',
		// [Redirection 3xx]
		300=>'300 Multiple Choices',
		301=>'301 Moved Permanently',
		302=>'302 Found',
		303=>'303 See Other',
		304=>'304 Not Modified',
		305=>'305 Use Proxy',
		306=>'306 (Unused)',
		307=>'307 Temporary Redirect',
		// [Client Error 4xx]
		400=>'400 Bad Request',
		401=>'401 Unauthorized',
		402=>'402 Payment Required',
		403=>'403 Forbidden',
		404=>'404 Not Found',
		405=>'405 Method Not Allowed',
		406=>'406 Not Acceptable',
		407=>'407 Proxy Authentication Required',
		408=>'408 Request Timeout',
		409=>'409 Conflict',
		410=>'410 Gone',
		411=>'411 Length Required',
		412=>'412 Precondition Failed',
		413=>'413 Request Entity Too Large',
		414=>'414 Request-URI Too Long',
		415=>'415 Unsupported Media Type',
		416=>'416 Requested Range Not Satisfiable',
		417=>'417 Expectation Failed',
		// [Server Error 5xx]
		500=>'500 Internal Server Error',
		501=>'501 Not Implemented',
		502=>'502 Bad Gateway',
		503=>'503 Service Unavailable',
		504=>'504 Gateway Timeout',
		505=>'505 HTTP Version Not Supported'
	);

	$output = '';
	switch($request->method) {
		case 'PUT':
			$output .= "Index: {$request->index}  Pass: {$request->pass}  Attempt: {$request->attempt}\n";
			$output .= "Original filename: " . basename($request->post_data) . "\n";
			break;
		case 'MKCOL':
			preg_match('#webdav(/.+)$#', $request->url, $matches);
			$output .= "Creating directory: " . $matches[1] . "\n";
			break;
		case 'DELETE':
			preg_match('#webdav(/.+)$#', $request->url, $matches);
			$output .= "Deleting: " . $matches[1] . "\n";
			break;
	}
	$output .= "Response Code: " . $messages[intval($info['http_code'])] . "\n";
	$stats[] = array(
		'message' => $output,
		'in' => $request->time_in,
		'out' => $request->time_out,
		'response' => print_r($response,1),
		'code' => $info['http_code'],
		'index' => isset($request->index) ? $request->index : -1,
	);
	echo ".";
});

// Empty the log
file_put_contents(__DIR__ . '/data/owncloud.log', '{"reqId": "--", "url": "--", "method": "--", "app":"flocktest","message":"Emptied log.","level":0,"time":"' . date('Y-m-dTH:i:s\+\0\0\:\0\0') . '"}' . "\n");

// Delete then create the flocktest directory at the root
$curl->add(new RollingCurlRequest('http://' . $username . ':' . $password . '@' . $owncloud_remote . '/webdav' . $testdir, 'DELETE'));
$curl->add(new RollingCurlRequest('http://' . $username . ':' . $password . '@' . $owncloud_remote . '/webdav' . $testdir, 'MKCOL'));
$curl->execute(1);

for($y = 1; $y <= $passes; $y++) {
	// Create files in the flocktest directory
	for($x = 1; $x <= $files_appearing; $x++) {
		for($z = 1; $z <= $attempts_per_pass; $z++) {
			$request = new RollingCurlRequest('http://' . $username . ':' . $password . '@' . $owncloud_remote . '/webdav' . $testdir . '/sample_' . $x . '.png', 'PUT', randpng($x), null, null);
			$request->attempt = $z;
			$request->pass = $y;
			$request->index = $x;
			$curl->add($request);
		}
	}
}

// Execute the curl queue $window at a time
$curl->execute($window);

// Reduce the timing to an execution/return order number
$timing = array();
foreach($stats as $stat) {
	$timing[] = $stat['in'];
	$timing[] = $stat['out'];
}
$timing = array_unique($timing);
sort($timing);
$timing = array_flip(array_map(function($e){return (string)$e;}, $timing));

// Output the stat results
echo "\n";
$hasproblem = false;
foreach($stats as $idstat => $stat) {
	echo "==============================\n";
	echo "Stat Entry #{$idstat}\n";
	$problem = '';
	$stat['in'] = (string)$stat['in'];
	$stat['out'] = (string)$stat['out'];
	if($stat['code'] >= 200 && $stat['code'] < 300) {
		foreach($stats as $ids2 => $s2) {
			if($idstat == $ids2) continue;
			if($stat['index'] != $s2['index']) continue;
			if($s2['code'] < 200 || $s2['code'] >= 300) continue;
			$s2['in'] = (string)$s2['in'];
			$s2['out'] = (string)$s2['out'];
			if(
				($timing[$stat['in']] >= $timing[$s2['in']] && $timing[$stat['in']] <= $timing[$s2['out']]) ||
				($timing[$stat['out']] <= $timing[$s2['out']] && $timing[$stat['out']] >= $timing[$s2['in']])
			) {
				$problem .= "\tComparing to stat entry #{$ids2}:\n";
				$problem .= "\t#{$ids2} in: {$timing[$s2['in']]}  #{$ids2} out: {$timing[$s2['out']]}\n";
			}
		}
	}
	echo $stat['message'];
	echo "Order in: {$timing[$stat['in']]}  Order out: {$timing[$stat['out']]}\n";
	//echo "Time in: {$stat['in']}  Time out: {$stat['out']}\n";
	echo $stat['response'];
	if($problem) {
		echo "\nTHERE MAY BE A PROBLEM WITH THIS RESPONSE!\n";
		echo $problem;
		$hasproblem = true;
	}
}

$results = array();
$verify = new RollingCurl(function($response, $info, $request) use(&$results) {
	$png = file_get_contents(randpng($request->index));
	if($response == $png) {
		$results[$request->index] = 'pass';
	}
	elseif(strpos($response, 'Integrity constraint violation') !== false) {
		$result = "retry\n";
	}
	else {
		$result = "fail\n";
		if($response[0] == '<') {
			$result .= "\t\tReceived: " . $response . "...\n";
		}
		else {
			$result .= "\t\tReceived: " . base64_encode(substr($response, 0, 50)) . "...\n";
		}
		$result .= "\t\tSent: " . base64_encode(substr($png, 0, 50)) . "...\n";
		$results[$request->index] = $result;
	}
});

for($x = 1; $x <= $files_appearing; $x++) {
	$results[$x] = 'unknown';
	$request = new RollingCurlRequest('http://' . $username . ':' . $password . '@' . $owncloud_remote . '/webdav' . $testdir . '/sample_' . $x . '.png', 'GET');
	$request->index = $x;
	$verify->add($request);
}

$verify->execute($window);

echo "\nVerification:\n";
foreach($results as $idx => $result) {
	echo "\t$idx: $result\n";
	if($result != 'pass') {
		$hasproblem = true;
	}
}

if($hasproblem) {
	echo "\nREVIEW THE RESULTS ABOVE FOR A POTENTIAL PROBLEM.\n";
}
else {
	echo "\nNO OBVIOUS PROBLEMS DETECTED.\n";
}


// Clean up temp images
randpng(0);
