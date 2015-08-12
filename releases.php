<?php

require_once 'vendor/autoload.php';

$COLOR_GRAY = "\033[0;37m";
$COLOR_RED = "\033[0;31m";
$NO_COLOR = "\033[0m";

$client = new \Github\Client(
	new \Github\HttpClient\CachedHttpClient([
		'cache_dir' => '/tmp/github-api-cache'
	])
);

if(!file_exists('credentials.json')) {
	print 'Please create the file credentials.json and provide your apikey.' . PHP_EOL;
	print '  cp credentials.dist.json credentials.json' . PHP_EOL;
	exit(1);
}

function milestoneSort($a, $b) {
	return strnatcasecmp($a['title'], $b['title']);
}
function labelSort($a, $b) {
	return strnatcasecmp($a['name'], $b['name']);
}

$authentication = json_decode(file_get_contents('credentials.json'));

$client->authenticate($authentication->apikey, Github\Client::AUTH_URL_TOKEN);
$paginator  = new Github\ResultPager($client);

$config = json_decode(file_get_contents('config.json'));
$repositories = [];
foreach($config->repos as $repo) {
	$repositories[$repo] = [
		'milestones' => [],
		'labels' => [],
	];

	print('Repo ' . $config->org . '/' . $repo . PHP_EOL);
	print("  Milestones" . PHP_EOL);
	$milestones = $client->api('issue')->milestones()->all($config->org, $repo);
	uasort($milestones, 'milestoneSort');
	foreach($milestones as $milestone) {
		$repositories[$repo]['milestones'][$milestone['title']] = $milestone['open_issues'];

		print("    ");
		if($milestone['open_issues'] !== 0) {
			print($milestone['title'] . ' ' . $milestone['open_issues']);
		} else {
			print($COLOR_GRAY. $milestone['title']);
		}
		print($NO_COLOR . PHP_EOL);
	}

	if(in_array($repo, $config->skipLabels)) {
		continue;
	}
	print("  Labels" . PHP_EOL);
	$labels = $paginator->fetchAll($client->api('issues')->labels(), 'all', [$config->org, $repo]);
	uasort($labels, 'labelSort');
	foreach($labels as $label) {
		if($label['name'][1] === '.') {
			$repositories[$repo]['labels'][$label['name']] = null;

			if(strpos($label['name'], '-current') === false && strpos($label['name'], '-next') === false ) {
				print($COLOR_GRAY);
			}
			print("    " . $label['name']);
			if(strpos($label['name'], '-current') !== false) {
				$issues = $client->api('issue')->all($config->org, $repo, ['labels' => $label['name']]);
				$count = count($issues);
				print(' ' . $count);
				$repositories[$repo]['labels'][$label['name']] = $count;
			}
			print($NO_COLOR . PHP_EOL);
		}
	}
}

$response = $client->getHttpClient()->get("rate_limit");
print(\Github\HttpClient\Message\ResponseMediator::getContent($response)['rate']['remaining'] . PHP_EOL);

foreach($repositories as $name => $repository) {
	if(in_array($name, $config->skipLabels)) {
		continue;
	}
	if(!array_key_exists('6.0.9', $repository['labels'])) {
		print($COLOR_RED . '6.0.9 missing in ' . $config->org . '/' . $name . $NO_COLOR . PHP_EOL);
	}
	if(!array_key_exists('7.0.7', $repository['labels'])) {
		print($COLOR_RED . '7.0.7 missing in ' . $config->org . '/' . $name . $NO_COLOR . PHP_EOL);
	}
	if(!array_key_exists('8.0.5', $repository['labels'])) {
		print($COLOR_RED . '8.0.5 missing in ' . $config->org . '/' . $name . $NO_COLOR . PHP_EOL);
	}
}
