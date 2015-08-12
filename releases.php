<?php

require_once 'vendor/autoload.php';

$COLOR_GRAY = "\033[0;37m";
$COLOR_RED = "\033[0;31m";
$NO_COLOR = "\033[0m";
$STRIKE_THROUGH = "\033[9m";

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
$paginator = new Github\ResultPager($client);

$config = json_decode(file_get_contents('config.json'));
$repositories = [];

$updateDueDate = [];

$SHOW_MILESTONE = true;
$SHOW_LABEL = true;

foreach($config->repos as $repo) {
	$repositories[$repo] = [
		'milestones' => [],
		'labels' => [],
	];

	print('Repo ' . $config->org . '/' . $repo . PHP_EOL);
	if($SHOW_MILESTONE) print("  Milestones" . PHP_EOL);
	$milestones = $client->api('issue')->milestones()->all($config->org, $repo);
	uasort($milestones, 'milestoneSort');
	foreach($milestones as $milestone) {
		$repositories[$repo]['milestones'][$milestone['title']] = $milestone;

		if($SHOW_MILESTONE) print("    ");
		if($milestone['open_issues'] !== 0) {
			if($SHOW_MILESTONE) print($milestone['title'] . ' ' . $milestone['open_issues']);
		} else {
			if($SHOW_MILESTONE) print($COLOR_GRAY. $milestone['title']);
		}
		if(property_exists($config->dueDates, $milestone['title']) &&
			$milestone['due_on'] !== $config->dueDates->$milestone['title'] . 'T04:00:00Z') {
			if($SHOW_MILESTONE) print($COLOR_RED . ' update due date');
			$updateDueDate[] = [
				'org' => $config->org,
				'repo' => $repo,
				'number' => $milestone['number'],
				'milestone' => $milestone['title'],
				'state' => $milestone['state'],
				'title' => $milestone['title'],
				'description' => $milestone['description'],
				'oldDueDate' => $milestone['due_on'],
				'newDueDate' => $config->dueDates->$milestone['title'] . 'T04:00:00Z',
			];
		}
		if($SHOW_MILESTONE) print($NO_COLOR . PHP_EOL);

	}

	if(in_array($repo, $config->skipLabels)) {
		continue;
	}
	if($SHOW_LABEL) print("  Labels" . PHP_EOL);
	$labels = $paginator->fetchAll($client->api('issues')->labels(), 'all', [$config->org, $repo]);
	uasort($labels, 'labelSort');
	foreach($labels as $label) {
		if($label['name'][1] === '.') {
			$repositories[$repo]['labels'][$label['name']] = null;

			if(strpos($label['name'], '-current') === false) {
				if($SHOW_LABEL) print($COLOR_GRAY);
			}
			if($SHOW_LABEL) print("    " . $label['name']);
			$repositories[$repo]['labels'][$label['name']] = [
				'color' => $label['color']
			];
			if(strpos($label['name'], '-current') !== false) {
				$issues = $client->api('issue')->all($config->org, $repo, ['labels' => $label['name']]);
				$openCount = count($issues);
				if($SHOW_LABEL) print(' ' . $openCount);
				$issues = $client->api('issue')->all($config->org, $repo, ['labels' => $label['name'], 'state' => 'closed']);
				$closedCount = count($issues);
				if($SHOW_LABEL) print(' ' . $closedCount);
				$repositories[$repo]['labels'][$label['name']] = [
					'color' => $label['color'],
					'open' => $openCount,
					'closed' => $closedCount,
				];
			}
			if($SHOW_LABEL) print($NO_COLOR . PHP_EOL);
		}
	}
}

$response = $client->getHttpClient()->get("rate_limit");
print(\Github\HttpClient\Message\ResponseMediator::getContent($response)['rate']['remaining'] . PHP_EOL);

foreach($repositories as $name => $repository) {
	foreach($repository['milestones'] as $milestone => $info) {
		if(array_key_exists($milestone, $config->renameMilestones)) {
			print($COLOR_RED . $config->org . '/' . $name . ': rename milestone ' . $milestone . ' -> ' . $config->renameMilestones->$milestone . $NO_COLOR . PHP_EOL);
			$data = [
				"title" => $config->renameMilestones->$milestone,
				"state" => $info['state'],
				"description" => $info['description'] ,
				"due_on" => $info['due_on']
			];
			if(array_key_exists($config->renameMilestones->$milestone, $config->dueDates)) {
				$newName = $config->renameMilestones->$milestone;
				$data['due_on'] = $config->dueDates->$newName . 'T04:00:00Z';
			}
			if(strpos($config->renameMilestones->$milestone, '-') === false && $info['open_issues'] === 0) {
				$data['state'] = 'closed';
			}
			continue;
			// TODO ask for the update
			$client->api('issue')->milestones()->update($config->org, $name, $info['number'], $data);
		}
	}

	foreach($config->addMilestones as $milestone) {
		if(!array_key_exists($milestone, $repository['milestones'])) {
			print($COLOR_RED . $config->org . '/' . $name . ': add milestone ' . $milestone . $NO_COLOR . PHP_EOL);
			$data = [
				"title" => $milestone
			];
			if(array_key_exists($milestone, $config->dueDates)) {
				$data['due_on'] = $config->dueDates->$milestone . 'T04:00:00Z';
			}
			continue;
			// TODO ask for the update
			$client->api('issue')->milestones()->create($config->org, $name, $data);

		}
	}

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

	foreach($repository['labels'] as $label => $info) {
		if(array_key_exists($label, $config->renameLabels)) {
			print($COLOR_RED . $config->org . '/' . $name . ': rename label ' . $label . ' -> ' . $config->renameLabels->$label . $NO_COLOR . PHP_EOL);
			continue;
			// TODO ask for the update
			$client->api('issue')->labels()->update($config->org, $name, $label, $config->renameLabels->$label, $info['color']);
		}
	}

	foreach($config->addLabels as $label) {
		if(!array_key_exists($label, $repository['labels'])) {
			print($COLOR_RED . $config->org . '/' . $name . ': add label ' . $label . $NO_COLOR . PHP_EOL);
			continue;
			// TODO ask for the update
			$client->api('issue')->labels()->create($config->org, $name, [ 'name' => $label, 'color' => '996633' ]);

		}
	}
}

if(count($updateDueDate)) {
	print('Following due dates need to be updated:' . PHP_EOL);

	foreach($updateDueDate as $date) {
		print($COLOR_RED . $date['org'] . '/' . $date['repo'] . ' ' . $date['title'] . ' from ' . $date['oldDueDate'] . ' to ' . $date['newDueDate'] . $NO_COLOR . PHP_EOL);
		continue;
		// TODO ask for the update
		$client->api('issue')->milestones()->update($date['org'], $date['repo'], $date['number'], [
			'title' => $date['title'],
			'state' => $date['state'],
			'description' => $date['description'],
			'due_on' => $date['newDueDate']
		]);
	}
}
